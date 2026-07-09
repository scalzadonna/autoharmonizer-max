"""Registry for Markov / RNN / LSTM chord engines."""

from __future__ import annotations

import logging
import threading
from pathlib import Path

from ..config import DEFAULT_MODEL, DEFAULT_SESSION_MODE, MODEL_NAMES, SESSION_MODES
from ..csv_loader import TransitionTable, load_transition_table
from .base import ChordEngine, SampleResult
from .lstm_engine import LstmEngine
from .markov_engine import MarkovEngine
from .rnn_engine import RnnEngine

logger = logging.getLogger(__name__)


class EngineRegistry:
    def __init__(
        self,
        *,
        csv_path: Path,
        jazznet_dir: Path,
        jazznet_epoch: int,
        fallback: str,
        seed: int | None,
        neural_temperature: float,
        neural_exclude_input: bool,
        session_mode: str = DEFAULT_SESSION_MODE,
        session_max_steps: int,
        session_auto_feed: bool,
        initial_model: str = DEFAULT_MODEL,
    ) -> None:
        self._csv_path = csv_path
        self._jazznet_dir = jazznet_dir
        self._jazznet_epoch = jazznet_epoch
        self._fallback = fallback
        self._seed = seed
        self._neural_temperature = neural_temperature
        self._neural_exclude_input = neural_exclude_input
        self._session_mode = session_mode if session_mode in SESSION_MODES else DEFAULT_SESSION_MODE
        self._session_max_steps = session_max_steps
        self._session_auto_feed = session_auto_feed
        self._adventure = 0.5
        self._lock = threading.Lock()
        self._table: TransitionTable | None = None
        self._markov: MarkovEngine | None = None
        self._rnn: RnnEngine | None = None
        self._lstm: LstmEngine | None = None
        self._active_name = initial_model if initial_model in MODEL_NAMES else DEFAULT_MODEL

    @property
    def active_name(self) -> str:
        with self._lock:
            return self._active_name

    @property
    def session_mode(self) -> str:
        with self._lock:
            return self._session_mode

    def session_status(self) -> tuple[str, int]:
        """Return effective session label and current step count."""
        with self._lock:
            name = self._active_name
            mode = self._session_mode

        if not self._effective_session(name, mode):
            return "stateless", 0

        engine = self._engine_for(name)
        if isinstance(engine, (RnnEngine, LstmEngine)):
            return "session", engine.session.step
        return "session", 0

    def session_history(self) -> str:
        with self._lock:
            name = self._active_name
        if name == "rnn" and self._rnn is not None:
            return self._rnn.session.history_display()
        if name == "lstm" and self._lstm is not None:
            return self._lstm.session.history_display()
        return ""

    def _effective_session(self, model_name: str, session_mode: str) -> bool:
        if model_name == "markov":
            return False
        if session_mode == "stateless":
            return False
        return True

    def load_markov(self) -> TransitionTable:
        table = load_transition_table(self._csv_path)
        engine = MarkovEngine(table, fallback=self._fallback, seed=self._seed)
        with self._lock:
            self._table = table
            self._markov = engine
        stats = table.stats
        logger.info(
            "Loaded CSV: rows=%s sources=%s merged=%s normalizations=%s path=%s",
            stats.raw_rows,
            stats.source_count,
            stats.duplicates_merged,
            stats.normalizations,
            self._csv_path,
        )
        return table

    def _get_rnn(self) -> RnnEngine:
        if self._rnn is None:
            self._rnn = RnnEngine(
                self._jazznet_dir,
                epoch=self._jazznet_epoch,
                fallback=self._fallback,
                seed=self._seed,
                temperature=self._neural_temperature,
                exclude_input=self._neural_exclude_input,
                session_max_steps=self._session_max_steps,
                session_auto_feed=self._session_auto_feed,
            )
        return self._rnn

    def _get_lstm(self) -> LstmEngine:
        if self._lstm is None:
            self._lstm = LstmEngine(
                self._jazznet_dir,
                epoch=self._jazznet_epoch,
                fallback=self._fallback,
                seed=self._seed,
                temperature=self._neural_temperature,
                exclude_input=self._neural_exclude_input,
                session_max_steps=self._session_max_steps,
                session_auto_feed=self._session_auto_feed,
            )
        return self._lstm

    def _engine_for(self, name: str) -> ChordEngine:
        if name == "markov":
            if self._markov is None:
                raise RuntimeError("Markov engine not loaded")
            return self._markov
        if name == "rnn":
            return self._get_rnn()
        if name == "lstm":
            return self._get_lstm()
        raise ValueError(f"Unknown model: {name}")

    def reset_session(self) -> None:
        if self._rnn is not None:
            self._rnn.reset_session()
        if self._lstm is not None:
            self._lstm.reset_session()
        logger.info("neural session reset")

    def set_session_mode(self, mode: str) -> tuple[bool, str | None]:
        normalized = mode.strip().lower()
        if normalized == "reset":
            self.reset_session()
            return True, None
        if normalized not in SESSION_MODES:
            return False, f"invalid session mode: {mode}"
        with self._lock:
            self._session_mode = normalized
        if normalized == "stateless":
            self.reset_session()
        logger.info("session mode set to %s", normalized)
        return True, None

    def set_model(self, name: str) -> tuple[bool, str | None]:
        if name not in MODEL_NAMES:
            return False, f"invalid model: {name}"

        with self._lock:
            previous = self._active_name
            self._active_name = name

        try:
            if name == "rnn":
                self._get_rnn()._ensure_loaded()  # noqa: SLF001
            elif name == "lstm":
                self._get_lstm()._ensure_loaded()  # noqa: SLF001
        except Exception as exc:
            with self._lock:
                self._active_name = previous
            return False, f"failed to load {name}: {exc}"

        self.reset_session()
        logger.info("active model set to %s", name)
        return True, None

    def set_adventure(self, value: float) -> tuple[bool, str | None]:
        """Set the 'spice' / adventurousness (0-1) as a live sampling temperature.

        0.5 is neutral (temperature 1.0). Higher values flatten the distribution
        toward rarer, surprising chords; lower values sharpen toward safe, common
        ones. Applies to Markov and to any loaded/future neural engine.
        """
        try:
            v = float(value)
        except (TypeError, ValueError):
            return False, f"invalid spice value: {value!r}"

        v = max(0.0, min(1.0, v))
        # Centered map: 0 -> 1/sqrt(3) (safe), 0.5 -> 1.0 (neutral), 1 -> sqrt(3) (wild).
        temperature = 3.0 ** (v - 0.5)

        with self._lock:
            self._adventure = v
            self._neural_temperature = temperature
            markov, rnn, lstm = self._markov, self._rnn, self._lstm

        for engine in (markov, rnn, lstm):
            if engine is not None:
                engine.set_temperature(temperature)

        logger.info("spice=%.3f -> temperature=%.3f", v, temperature)
        return True, None

    def sample(self, raw_input: str) -> SampleResult:
        with self._lock:
            name = self._active_name
            mode = self._session_mode
        session = self._effective_session(name, mode)
        return self._engine_for(name).sample(raw_input, session=session)

    def reload_markov(self) -> None:
        self.load_markov()

    def preload_neural(self, name: str) -> tuple[bool, str | None]:
        return self.set_model(name)
