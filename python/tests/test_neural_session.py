"""Tests for stateful neural session mode."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_TESTS_DIR = Path(__file__).resolve().parent
if str(_TESTS_DIR) not in sys.path:
    sys.path.insert(0, str(_TESTS_DIR))

from neural_helpers import JAZZNET_AVAILABLE, JAZZNET_DIR
from src.engines.lstm_engine import LstmEngine
from src.engines.registry import EngineRegistry
from src.engines.rnn_engine import RnnEngine

pytestmark = pytest.mark.skipif(
    not JAZZNET_AVAILABLE,
    reason="JazzNet assets missing",
)

REPO_ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = REPO_ROOT / "data" / "markov_openbook.csv"


def _registry(**kwargs) -> EngineRegistry:
    defaults = {
        "csv_path": CSV_PATH,
        "jazznet_dir": JAZZNET_DIR,
        "jazznet_epoch": 35,
        "fallback": "echo_input",
        "seed": 42,
        "neural_temperature": 1.5,
        "neural_exclude_input": True,
        "session_mode": "auto",
        "session_max_steps": 64,
        "session_auto_feed": True,
        "initial_model": "rnn",
    }
    defaults.update(kwargs)
    reg = EngineRegistry(**defaults)
    reg.load_markov()
    return reg


def test_session_step_increments():
    engine = RnnEngine(JAZZNET_DIR, seed=42, session_max_steps=64, session_auto_feed=True)
    engine.sample("G:7", session=True)
    assert engine.session.step == 1
    engine.sample("C:maj7", session=True)
    assert engine.session.step == 2
    assert len(engine.session.token_trace) == 4


def test_session_reset_clears_state():
    engine = LstmEngine(JAZZNET_DIR, seed=42)
    engine.sample("G:7", session=True)
    engine.reset_session()
    assert engine.session.step == 0
    assert engine.session.hidden is None
    assert engine.session.token_trace == []


def test_session_differs_from_stateless_on_second_step():
    session_engine = RnnEngine(JAZZNET_DIR, seed=42)
    session_engine.sample("G:7", session=True)
    session_result = session_engine.sample("A:7", session=True)

    stateless_engine = RnnEngine(JAZZNET_DIR, seed=42)
    stateless_engine.sample("G:7", session=False)
    stateless_result = stateless_engine.sample("A:7", session=False)

    assert session_result.output is not None
    assert stateless_result.output is not None


def test_auto_reset_at_max_steps():
    engine = RnnEngine(JAZZNET_DIR, seed=42, session_max_steps=2, session_auto_feed=True)
    engine.sample("G:7", session=True)
    engine.sample("C:maj7", session=True)
    assert engine.session.step == 2
    engine.sample("A:7", session=True)
    assert engine.session.step == 1


def test_registry_auto_session_for_rnn():
    reg = _registry(initial_model="rnn", session_mode="auto")
    ok, _ = reg.set_model("rnn")
    assert ok
    mode, step = reg.session_status()
    assert mode == "session"
    assert step == 0
    reg.sample("G:7")
    _mode, step = reg.session_status()
    assert step == 1


def test_registry_markov_is_stateless():
    reg = _registry(initial_model="markov", session_mode="auto")
    mode, step = reg.session_status()
    assert mode == "stateless"
    assert step == 0


def test_registry_session_reset_via_control():
    reg = _registry(initial_model="lstm", session_mode="auto")
    reg.set_model("lstm")
    reg.sample("G:7")
    ok, err = reg.set_session_mode("reset")
    assert ok is True
    assert err is None
    _mode, step = reg.session_status()
    assert step == 0


def test_model_switch_resets_session():
    reg = _registry(initial_model="rnn", session_mode="auto")
    reg.set_model("rnn")
    reg.sample("G:7")
    reg.set_model("lstm")
    _mode, step = reg.session_status()
    assert step == 0
