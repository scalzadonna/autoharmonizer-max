"""Registry for Markov / RNN / LSTM chord engines."""

from __future__ import annotations

import logging
import threading
from pathlib import Path

from ..config import DEFAULT_MODEL, MODEL_NAMES
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
        initial_model: str = DEFAULT_MODEL,
    ) -> None:
        self._csv_path = csv_path
        self._jazznet_dir = jazznet_dir
        self._jazznet_epoch = jazznet_epoch
        self._fallback = fallback
        self._seed = seed
        self._neural_temperature = neural_temperature
        self._neural_exclude_input = neural_exclude_input
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

        logger.info("active model set to %s", name)
        return True, None

    def sample(self, raw_input: str) -> SampleResult:
        with self._lock:
            name = self._active_name
        return self._engine_for(name).sample(raw_input)

    def reload_markov(self) -> None:
        self.load_markov()

    def preload_neural(self, name: str) -> tuple[bool, str | None]:
        return self.set_model(name)
