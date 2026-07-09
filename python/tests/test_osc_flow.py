"""OSC integration tests (localhost UDP)."""

from __future__ import annotations

import socket
import threading
import time
from pathlib import Path

import pytest
from pythonosc.dispatcher import Dispatcher
from pythonosc.osc_server import BlockingOSCUDPServer
from pythonosc.udp_client import SimpleUDPClient

from src.config import Settings
from src.osc_service import MarkovOscService

REPO_ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = REPO_ROOT / "data" / "markov_openbook.csv"
JAZZNET_DIR = REPO_ROOT / "data" / "jazznet"


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


def _settings(python_port: int, max_port: int) -> Settings:
    return Settings(
        csv_path=CSV_PATH,
        jazznet_dir=JAZZNET_DIR,
        jazznet_epoch=35,
        model="markov",
        host="127.0.0.1",
        port=python_port,
        max_host="127.0.0.1",
        max_port=max_port,
        fallback="echo_input",
        debug=False,
        seed=42,
        neural_temperature=1.5,
        neural_exclude_input=True,
        session_mode="auto",
        session_max_steps=64,
        session_auto_feed=True,
    )


@pytest.fixture
def osc_service():
    python_port = _free_port()
    max_port = _free_port()

    settings = _settings(python_port, max_port)
    service = MarkovOscService(settings)

    received: dict[str, list] = {"messages": []}
    ready = threading.Event()

    def handler(address: str, *args: object) -> None:
        received["messages"].append((address, args))
        if address in ("/status/ready", "/status/pong"):
            ready.set()

    dispatcher = Dispatcher()
    dispatcher.set_default_handler(handler)
    max_server = BlockingOSCUDPServer(("127.0.0.1", max_port), dispatcher)
    max_thread = threading.Thread(target=max_server.serve_forever, daemon=True)
    max_thread.start()

    service_thread = threading.Thread(target=service.run_forever, daemon=True)
    service_thread.start()

    client = SimpleUDPClient("127.0.0.1", python_port)

    deadline = time.time() + 5.0
    while time.time() < deadline and not ready.is_set():
        client.send_message("/control/ping", [])
        time.sleep(0.05)

    assert ready.wait(timeout=3.0), "service did not become ready"

    yield client, received

    service.stop()
    max_server.shutdown()
    service_thread.join(timeout=2.0)
    max_thread.join(timeout=2.0)


def test_ping_pong(osc_service):
    client, received = osc_service
    before = len(received["messages"])
    client.send_message("/control/ping", [])
    time.sleep(0.2)
    new_messages = received["messages"][before:]
    addresses = [item[0] for item in new_messages]
    assert "/status/pong" in addresses


def test_chord_input_output(osc_service):
    client, received = osc_service
    before = len(received["messages"])
    client.send_message("/chord/input", ["G:7"])
    time.sleep(0.2)

    outputs = [
        args[0]
        for addr, args in received["messages"][before:]
        if addr == "/chord/output"
    ]
    assert outputs, "expected /chord/output"
    assert isinstance(outputs[-1], str)


def test_unknown_chord_error_and_echo(osc_service):
    client, received = osc_service
    before = len(received["messages"])
    client.send_message("/chord/input", ["X:???"])
    time.sleep(0.2)

    new_messages = received["messages"][before:]
    errors = [args[0] for addr, args in new_messages if addr == "/error"]
    outputs = [args[0] for addr, args in new_messages if addr == "/chord/output"]
    assert errors
    assert outputs[-1] == "X:???"


def test_model_switch_status(osc_service):
    client, received = osc_service
    before = len(received["messages"])
    client.send_message("/control/model", ["lstm"])
    time.sleep(2.0)

    models = [args[0] for addr, args in received["messages"][before:] if addr == "/status/model"]
    if not (JAZZNET_DIR / "checkpoints" / "lstm" / "ChordLSTM-epoch35.pt").is_file():
        pytest.skip("JazzNet checkpoints not fetched")
    assert models
    assert models[-1] == "lstm"


def test_session_status_on_ping(osc_service):
    client, received = osc_service
    before = len(received["messages"])
    client.send_message("/control/ping", [])
    time.sleep(0.2)

    sessions = [
        args
        for addr, args in received["messages"][before:]
        if addr == "/status/session"
    ]
    assert sessions
    mode, step = sessions[-1]
    assert mode == "stateless"
    assert step == 0


@pytest.mark.skipif(
    not (JAZZNET_DIR / "checkpoints" / "rnn" / "baselineRNN-epoch35.pt").is_file(),
    reason="JazzNet checkpoints not fetched",
)
def test_session_mode_rnn(osc_service):
    client, received = osc_service
    client.send_message("/control/model", ["rnn"])
    time.sleep(2.0)

    before = len(received["messages"])
    client.send_message("/chord/input", ["G:7"])
    time.sleep(0.5)

    sessions = [
        args
        for addr, args in received["messages"][before:]
        if addr == "/status/session"
    ]
    assert sessions
    mode, step = sessions[-1]
    assert mode == "session"
    assert step == 1
