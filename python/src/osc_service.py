"""OSC server and client for Markov chord service."""

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
    OSC_CONTROL_PING,
    OSC_CONTROL_RELOAD,
    OSC_DEBUG_CANDIDATES,
    OSC_DEBUG_FALLBACK_USED,
    OSC_DEBUG_INPUT_ECHO,
    OSC_DEBUG_PROBABILITY,
    OSC_ERROR,
    OSC_STATUS_PONG,
    OSC_STATUS_READY,
    Settings,
)
from .csv_loader import CSVLoadError, TransitionTable, load_transition_table
from .markov_engine import MarkovEngine, SampleResult

logger = logging.getLogger(__name__)


class MarkovOscService:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._lock = threading.Lock()
        self._table: TransitionTable | None = None
        self._engine: MarkovEngine | None = None
        self._client = SimpleUDPClient(settings.max_host, settings.max_port)
        self._server: BlockingOSCUDPServer | None = None
        self._server_thread: threading.Thread | None = None

    @property
    def settings(self) -> Settings:
        return self._settings

    def load_table(self) -> TransitionTable:
        table = load_transition_table(self._settings.csv_path)
        engine = MarkovEngine(
            table,
            fallback=self._settings.fallback,
            seed=self._settings.seed,
        )
        with self._lock:
            self._table = table
            self._engine = engine
        stats = table.stats
        logger.info(
            "Loaded CSV: rows=%s sources=%s merged=%s normalizations=%s path=%s",
            stats.raw_rows,
            stats.source_count,
            stats.duplicates_merged,
            stats.normalizations,
            self._settings.csv_path,
        )
        return table

    def _get_engine(self) -> MarkovEngine:
        with self._lock:
            if self._engine is None:
                raise RuntimeError("Transition table not loaded")
            return self._engine

    def _send(self, address: str, *args: object) -> None:
        self._client.send_message(address, list(args))

    def _emit_error(self, message: str) -> None:
        logger.warning(message)
        self._send(OSC_ERROR, message)

    def _emit_debug(self, result: SampleResult, input_chord: str) -> None:
        if not self._settings.debug:
            return
        self._send(OSC_DEBUG_INPUT_ECHO, input_chord)
        self._send(OSC_DEBUG_CANDIDATES, result.candidates)
        self._send(OSC_DEBUG_FALLBACK_USED, 1 if result.fallback_used else 0)
        if result.probability is not None:
            self._send(OSC_DEBUG_PROBABILITY, float(result.probability))

    def _handle_chord_input(self, _address: str, *args: object) -> None:
        if not args:
            self._emit_error("malformed OSC payload: missing chord argument")
            return

        raw = args[0]
        if not isinstance(raw, str):
            self._emit_error("malformed OSC payload: chord must be a string")
            return

        engine = self._get_engine()
        result = engine.sample(raw)

        if result.error:
            self._emit_error(result.error)

        if result.output is None:
            return

        self._emit_debug(result, raw.strip())
        self._send(OSC_CHORD_OUTPUT, result.output)
        logger.debug("sampled %r -> %r", raw, result.output)

    def _handle_ping(self, _address: str, *_args: object) -> None:
        self._send(OSC_STATUS_PONG, 1)
        logger.debug("ping -> pong")

    def _handle_reload(self, _address: str, *_args: object) -> None:
        try:
            self.load_table()
            self._send(OSC_STATUS_READY, 1)
            logger.info("CSV reload succeeded")
        except (CSVLoadError, OSError) as exc:
            self._emit_error(f"reload failed: {exc}")
            logger.exception("CSV reload failed")

    def _build_dispatcher(self) -> Dispatcher:
        dispatcher = Dispatcher()
        dispatcher.map(OSC_CHORD_INPUT, self._handle_chord_input)
        dispatcher.map(OSC_CONTROL_PING, self._handle_ping)
        dispatcher.map(OSC_CONTROL_RELOAD, self._handle_reload)
        dispatcher.set_default_handler(self._handle_unknown)
        return dispatcher

    def _handle_unknown(self, address: str, *args: object) -> None:
        self._emit_error(f"unknown OSC address: {address}")

    def signal_ready(self) -> None:
        self._send(OSC_STATUS_READY, 1)
        logger.info("sent /status/ready")

    def start(self) -> None:
        self.load_table()
        dispatcher = self._build_dispatcher()
        self._server = BlockingOSCUDPServer(
            (self._settings.host, self._settings.port),
            dispatcher,
        )
        logger.info(
            "OSC server listening on %s:%s -> Max at %s:%s",
            self._settings.host,
            self._settings.port,
            self._settings.max_host,
            self._settings.max_port,
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
        self.load_table()
        dispatcher = self._build_dispatcher()
        server = BlockingOSCUDPServer(
            (self._settings.host, self._settings.port),
            dispatcher,
        )
        self._server = server
        logger.info(
            "OSC server listening on %s:%s -> Max at %s:%s",
            self._settings.host,
            self._settings.port,
            self._settings.max_host,
            self._settings.max_port,
        )
        self.signal_ready()
        if on_started:
            on_started()
        server.serve_forever()
