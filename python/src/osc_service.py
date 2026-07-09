"""OSC server and client for chord generator service."""

from __future__ import annotations

import logging
import threading
from typing import Callable

from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import BlockingOSCUDPServer
from pythonosc.udp_client import SimpleUDPClient

from .config import (
    OSC_CHORD_INPUT,
    OSC_CHORD_OUTPUT,
    OSC_CONTROL_MODEL,
    OSC_CONTROL_PING,
    OSC_CONTROL_RELOAD,
    OSC_CONTROL_SESSION,
    OSC_CONTROL_SPICE,
    OSC_DEBUG_CANDIDATES,
    OSC_DEBUG_FALLBACK_USED,
    OSC_DEBUG_INPUT_ECHO,
    OSC_DEBUG_MODEL,
    OSC_DEBUG_PROBABILITY,
    OSC_DEBUG_SESSION_HISTORY,
    OSC_ERROR,
    OSC_STATUS_MODEL,
    OSC_STATUS_PONG,
    OSC_STATUS_READY,
    OSC_STATUS_SESSION,
    Settings,
)
from .csv_loader import CSVLoadError
from .engines.base import SampleResult
from .engines.registry import EngineRegistry

logger = logging.getLogger(__name__)


class ChordOscService:
    """OSC bridge for Markov / RNN / LSTM chord engines."""

    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._registry = EngineRegistry(
            csv_path=settings.csv_path,
            jazznet_dir=settings.jazznet_dir,
            jazznet_epoch=settings.jazznet_epoch,
            fallback=settings.fallback,
            seed=settings.seed,
            neural_temperature=settings.neural_temperature,
            neural_exclude_input=settings.neural_exclude_input,
            session_mode=settings.session_mode,
            session_max_steps=settings.session_max_steps,
            session_auto_feed=settings.session_auto_feed,
            initial_model=settings.model,
        )
        self._client = SimpleUDPClient(settings.max_host, settings.max_port)
        self._server: BlockingOSCUDPServer | None = None
        self._server_thread: threading.Thread | None = None

    @property
    def settings(self) -> Settings:
        return self._settings

    @property
    def registry(self) -> EngineRegistry:
        return self._registry

    def load_engines(self) -> None:
        self._registry.load_markov()
        if self._settings.model in ("rnn", "lstm"):
            ok, err = self._registry.set_model(self._settings.model)
            if not ok:
                logger.warning("startup model %s not loaded: %s", self._settings.model, err)

    def _send(self, address: str, *args: object) -> None:
        self._client.send_message(address, list(args))

    def _emit_error(self, message: str) -> None:
        logger.warning(message)
        self._send(OSC_ERROR, message)

    def _emit_model_status(self) -> None:
        self._send(OSC_STATUS_MODEL, self._registry.active_name)

    def _emit_session_status(self) -> None:
        mode, step = self._registry.session_status()
        self._send(OSC_STATUS_SESSION, mode, step)

    def _emit_debug(self, result: SampleResult, input_chord: str) -> None:
        if not self._settings.debug:
            return
        self._send(OSC_DEBUG_INPUT_ECHO, input_chord)
        self._send(OSC_DEBUG_CANDIDATES, result.candidates)
        self._send(OSC_DEBUG_FALLBACK_USED, 1 if result.fallback_used else 0)
        self._send(OSC_DEBUG_MODEL, self._registry.active_name)
        if result.probability is not None:
            self._send(OSC_DEBUG_PROBABILITY, float(result.probability))
        history = self._registry.session_history()
        if history:
            self._send(OSC_DEBUG_SESSION_HISTORY, history)

    def _handle_chord_input(self, _address: str, *args: object) -> None:
        if not args:
            self._emit_error("malformed OSC payload: missing chord argument")
            return

        raw = args[0]
        if not isinstance(raw, str):
            self._emit_error("malformed OSC payload: chord must be a string")
            return

        result = self._registry.sample(raw)

        if result.error:
            self._emit_error(result.error)

        if result.output is None:
            return

        self._emit_debug(result, raw.strip())
        self._emit_session_status()
        self._send(OSC_CHORD_OUTPUT, result.output)
        logger.debug(
            "sampled model=%s session=%s %r -> %r",
            self._registry.active_name,
            self._registry.session_status()[0],
            raw,
            result.output,
        )

    def _handle_ping(self, _address: str, *_args: object) -> None:
        self._send(OSC_STATUS_PONG, 1)
        self._emit_model_status()
        self._emit_session_status()
        logger.debug("ping -> pong")

    def _handle_reload(self, _address: str, *_args: object) -> None:
        try:
            self._registry.reload_markov()
            self._send(OSC_STATUS_READY, 1)
            self._emit_model_status()
            self._emit_session_status()
            logger.info("CSV reload succeeded")
        except (CSVLoadError, OSError) as exc:
            self._emit_error(f"reload failed: {exc}")
            logger.exception("CSV reload failed")

    def _handle_model(self, _address: str, *args: object) -> None:
        if not args or not isinstance(args[0], str):
            self._emit_error("malformed OSC payload: model name must be a string")
            return

        name = args[0].strip().lower()
        ok, err = self._registry.set_model(name)
        if not ok:
            self._emit_error(err or f"failed to set model: {name}")
            return

        self._emit_model_status()
        self._emit_session_status()
        logger.info("model switched to %s via OSC", name)

    def _handle_session(self, _address: str, *args: object) -> None:
        if not args or not isinstance(args[0], str):
            self._emit_error("malformed OSC payload: session mode must be a string")
            return

        mode = args[0].strip().lower()
        ok, err = self._registry.set_session_mode(mode)
        if not ok:
            self._emit_error(err or f"failed to set session mode: {mode}")
            return

        self._emit_session_status()
        logger.info("session control: %s", mode)

    def _handle_spice(self, _address: str, *args: object) -> None:
        if not args:
            self._emit_error("malformed OSC payload: missing spice value")
            return
        try:
            value = float(args[0])
        except (TypeError, ValueError):
            self._emit_error("malformed OSC payload: spice must be a number")
            return

        ok, err = self._registry.set_adventure(value)
        if not ok:
            self._emit_error(err or "failed to set spice")
            return
        logger.debug("spice set to %s", value)

    def _build_dispatcher(self) -> Dispatcher:
        dispatcher = Dispatcher()
        dispatcher.map(OSC_CHORD_INPUT, self._handle_chord_input)
        dispatcher.map(OSC_CONTROL_PING, self._handle_ping)
        dispatcher.map(OSC_CONTROL_RELOAD, self._handle_reload)
        dispatcher.map(OSC_CONTROL_MODEL, self._handle_model)
        dispatcher.map(OSC_CONTROL_SESSION, self._handle_session)
        dispatcher.map(OSC_CONTROL_SPICE, self._handle_spice)
        dispatcher.set_default_handler(self._handle_unknown)
        return dispatcher

    def _handle_unknown(self, address: str, *args: object) -> None:
        self._emit_error(f"unknown OSC address: {address}")

    def signal_ready(self) -> None:
        self._send(OSC_STATUS_READY, 1)
        self._emit_model_status()
        self._emit_session_status()
        logger.info(
            "sent /status/ready model=%s session=%s",
            self._registry.active_name,
            self._registry.session_status()[0],
        )

    def start(self) -> None:
        self.load_engines()
        dispatcher = self._build_dispatcher()
        self._server = BlockingOSCUDPServer(
            (self._settings.host, self._settings.port),
            dispatcher,
        )
        logger.info(
            "OSC server listening on %s:%s -> Max at %s:%s model=%s session_mode=%s",
            self._settings.host,
            self._settings.port,
            self._settings.max_host,
            self._settings.max_port,
            self._registry.active_name,
            self._registry.session_mode,
        )

        self.signal_ready()

        self._server_thread = threading.Thread(
            target=self._server.serve_forever,
            name="osc-server",
            daemon=True,
        )
        self._server_thread.start()

    def stop(self) -> None:
        if self._server is not None:
            self._server.shutdown()
            self._server = None
        if self._server_thread is not None:
            self._server_thread.join(timeout=2.0)
            self._server_thread = None

    def run_forever(self, on_started: Callable[[], None] | None = None) -> None:
        self.load_engines()
        dispatcher = self._build_dispatcher()
        server = BlockingOSCUDPServer(
            (self._settings.host, self._settings.port),
            dispatcher,
        )
        self._server = server
        logger.info(
            "OSC server listening on %s:%s -> Max at %s:%s model=%s session_mode=%s",
            self._settings.host,
            self._settings.port,
            self._settings.max_host,
            self._settings.max_port,
            self._registry.active_name,
            self._registry.session_mode,
        )
        self.signal_ready()
        if on_started:
            on_started()
        server.serve_forever()


# Backward-compatible alias
MarkovOscService = ChordOscService
