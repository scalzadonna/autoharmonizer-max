"""Suite verifying RNN/LSTM models respond across diverse chord inputs.

Run the full neural suite:
    python -m pytest tests/test_neural_models_suite.py -v

Requires JazzNet checkpoints (see scripts/fetch_jazznet_assets.py).
"""

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
from src.engines.base import SampleResult
from src.engines.jazznet_vocab import JazzNetVocab
from src.engines.lstm_engine import LstmEngine
from src.engines.registry import EngineRegistry
from src.engines.rnn_engine import RnnEngine
from src.osc_service import ChordOscService

import sys
from pathlib import Path

_TESTS_DIR = Path(__file__).resolve().parent
if str(_TESTS_DIR) not in sys.path:
    sys.path.insert(0, str(_TESTS_DIR))

from neural_helpers import (  # noqa: E402
    CSV_PATH,
    JAZZNET_AVAILABLE,
    JAZZNET_DIR,
    NEURAL_TEST_CHORDS,
    SPECIAL_TOKENS,
)

pytestmark = [
    pytest.mark.skipif(
        not JAZZNET_AVAILABLE,
        reason="JazzNet assets missing; run: python scripts/fetch_jazznet_assets.py",
    ),
    pytest.mark.neural,
]


def _assert_valid_response(
    result: SampleResult,
    vocab: JazzNetVocab,
    input_chord: str,
) -> str:
    assert result.output is not None, f"no output for input {input_chord!r}"
    assert result.fallback_used is False, f"unexpected fallback for {input_chord!r}: {result.error}"
    assert result.error is None, f"unexpected error for {input_chord!r}: {result.error}"
    assert result.output not in SPECIAL_TOKENS
    assert result.output in vocab.chord_to_idx, (
        f"output {result.output!r} not in JazzNet vocab for input {input_chord!r}"
    )
    assert result.probability is not None
    assert 0.0 < result.probability <= 1.0
    assert result.candidates > 0
    return result.output


# --- Per-chord parametrized engine tests -------------------------------------


@pytest.mark.parametrize("input_chord", NEURAL_TEST_CHORDS)
def test_rnn_responds_to_chord(rnn_engine: RnnEngine, jazznet_vocab: JazzNetVocab, input_chord: str):
    output = _assert_valid_response(rnn_engine.sample(input_chord), jazznet_vocab, input_chord)
    assert ":" in output


@pytest.mark.parametrize("input_chord", NEURAL_TEST_CHORDS)
def test_lstm_responds_to_chord(lstm_engine: LstmEngine, jazznet_vocab: JazzNetVocab, input_chord: str):
    output = _assert_valid_response(lstm_engine.sample(input_chord), jazznet_vocab, input_chord)
    assert ":" in output


# --- Aggregate behavior across the chord set ---------------------------------


def test_rnn_produces_varied_outputs_across_chords(
    rnn_engine: RnnEngine,
    neural_test_chords: list[str],
):
    outputs = [rnn_engine.sample(c).output for c in neural_test_chords]
    assert all(o is not None for o in outputs)
    assert len(set(outputs)) >= 3, f"RNN outputs too uniform: {set(outputs)}"


def test_lstm_produces_varied_outputs_across_chords(
    lstm_engine: LstmEngine,
    neural_test_chords: list[str],
):
    outputs = [lstm_engine.sample(c).output for c in neural_test_chords]
    assert all(o is not None for o in outputs)
    assert len(set(outputs)) >= 3, f"LSTM outputs too uniform: {set(outputs)}"


def test_rnn_maps_different_inputs_to_distinct_responses(
    rnn_engine: RnnEngine,
    neural_test_chords: list[str],
):
    """Each input gets a valid reply; collectively outputs span multiple chord symbols."""
    outputs = {chord: rnn_engine.sample(chord).output for chord in neural_test_chords}
    assert len(outputs) == len(neural_test_chords)
    assert len(set(outputs.values())) >= 8, (
        f"RNN collapsed to too few distinct outputs: {set(outputs.values())}"
    )


def test_lstm_maps_different_inputs_to_distinct_responses(
    lstm_engine: LstmEngine,
    neural_test_chords: list[str],
):
    outputs = {chord: lstm_engine.sample(chord).output for chord in neural_test_chords}
    assert len(outputs) == len(neural_test_chords)
    assert len(set(outputs.values())) >= 8, (
        f"LSTM collapsed to too few distinct outputs: {set(outputs.values())}"
    )


def test_rnn_and_lstm_probability_distributions_differ(
    neural_test_chords: list[str],
):
    """RNN and LSTM are distinct models: output distributions differ for every input."""
    import torch
    import torch.nn.functional as F

    rnn = RnnEngine(JAZZNET_DIR, seed=42)
    lstm = LstmEngine(JAZZNET_DIR, seed=42)
    rnn._ensure_loaded()
    lstm._ensure_loaded()

    differing = 0
    for chord in neural_test_chords:
        assert rnn._vocab is not None and rnn._model is not None
        assert lstm._vocab is not None and lstm._model is not None
        idx = rnn._vocab.chord_index(chord)
        assert idx is not None
        context = [rnn._vocab.bos_idx, idx]
        x = torch.LongTensor([context])
        with torch.no_grad():
            rnn_out, _ = rnn._model(x)
            lstm_out, _ = lstm._model(x, torch.tensor([len(context)]))
            rnn_probs = F.softmax(rnn_out[0][-1], dim=0)
            lstm_probs = F.softmax(lstm_out[0][-1], dim=0)
        if not torch.allclose(rnn_probs, lstm_probs, atol=1e-6):
            differing += 1

    assert differing == len(neural_test_chords), (
        f"expected RNN/LSTM distributions to differ for all inputs, only {differing} differed"
    )


def test_neural_deterministic_with_seed(jazznet_vocab: JazzNetVocab, neural_test_chords: list[str]):
    for factory, name in ((RnnEngine, "rnn"), (LstmEngine, "lstm")):
        a = factory(JAZZNET_DIR, seed=99)
        b = factory(JAZZNET_DIR, seed=99)
        for chord in neural_test_chords[:5]:
            out_a = _assert_valid_response(a.sample(chord), jazznet_vocab, chord)
            out_b = _assert_valid_response(b.sample(chord), jazznet_vocab, chord)
            assert out_a == out_b, f"{name} not deterministic for {chord}"


# --- Registry integration ----------------------------------------------------


@pytest.fixture
def neural_registry() -> EngineRegistry:
    reg = EngineRegistry(
        csv_path=CSV_PATH,
        jazznet_dir=JAZZNET_DIR,
        jazznet_epoch=35,
        fallback="echo_input",
        seed=42,
        neural_temperature=1.5,
        neural_exclude_input=True,
        session_mode="auto",
        session_max_steps=64,
        session_auto_feed=True,
        initial_model="markov",
    )
    reg.load_markov()
    return reg


@pytest.mark.parametrize("model_name", ["rnn", "lstm"])
@pytest.mark.parametrize("input_chord", NEURAL_TEST_CHORDS[:6])
def test_registry_neural_models_respond(
    neural_registry: EngineRegistry,
    jazznet_vocab: JazzNetVocab,
    model_name: str,
    input_chord: str,
):
    ok, err = neural_registry.set_model(model_name)
    assert ok is True, err
    result = neural_registry.sample(input_chord)
    _assert_valid_response(result, jazznet_vocab, input_chord)


# --- OSC end-to-end for neural backends --------------------------------------


def _free_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


@pytest.fixture
def osc_neural_service():
    python_port = _free_port()
    max_port = _free_port()
    settings = Settings(
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
    service = ChordOscService(settings)
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
    deadline = time.time() + 8.0
    while time.time() < deadline and not ready.is_set():
        client.send_message("/control/ping", [])
        time.sleep(0.05)
    assert ready.wait(timeout=5.0), "OSC service did not become ready"

    yield client, received

    service.stop()
    max_server.shutdown()
    service_thread.join(timeout=3.0)
    max_thread.join(timeout=3.0)


@pytest.mark.parametrize("model_name", ["rnn", "lstm"])
def test_osc_neural_responds_to_chord_set(
    osc_neural_service,
    jazznet_vocab: JazzNetVocab,
    model_name: str,
):
    """OSC round-trip: switch model once, then verify replies for multiple inputs."""
    client, received = osc_neural_service
    before = len(received["messages"])

    client.send_message("/control/model", [model_name])
    time.sleep(2.5)

    model_msgs = [
        args[0]
        for addr, args in received["messages"][before:]
        if addr == "/status/model"
    ]
    assert model_msgs, f"no /status/model after switching to {model_name}"
    assert model_msgs[-1] == model_name

    outputs: dict[str, str] = {}
    for input_chord in NEURAL_TEST_CHORDS[:8]:
        chord_before = len(received["messages"])
        client.send_message("/chord/input", [input_chord])
        time.sleep(0.3)

        chord_outputs = [
            args[0]
            for addr, args in received["messages"][chord_before:]
            if addr == "/chord/output"
        ]
        errors = [
            args[0]
            for addr, args in received["messages"][chord_before:]
            if addr == "/error"
        ]
        assert not errors, f"OSC error for {model_name} input {input_chord}: {errors}"
        assert chord_outputs, f"no /chord/output for {model_name} input {input_chord}"
        output = chord_outputs[-1]
        assert isinstance(output, str)
        assert output in jazznet_vocab.chord_to_idx
        assert output not in SPECIAL_TOKENS
        outputs[input_chord] = output

    assert len(outputs) == 8
    assert len(set(outputs.values())) >= 2, (
        f"{model_name} returned too few distinct outputs over OSC: {set(outputs.values())}"
    )
