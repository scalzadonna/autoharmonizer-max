"""Tests for JazzNet inference with real checkpoints."""

from __future__ import annotations

from pathlib import Path

import pytest

from src.engines.lstm_engine import LstmEngine
from src.engines.rnn_engine import RnnEngine

REPO_ROOT = Path(__file__).resolve().parents[2]
JAZZNET_DIR = REPO_ROOT / "data" / "jazznet"
RNN_CKPT = JAZZNET_DIR / "checkpoints" / "rnn" / "baselineRNN-epoch35.pt"
LSTM_CKPT = JAZZNET_DIR / "checkpoints" / "lstm" / "ChordLSTM-epoch35.pt"


pytestmark = pytest.mark.skipif(
    not RNN_CKPT.is_file() or not LSTM_CKPT.is_file(),
    reason="JazzNet checkpoints not fetched",
)


def test_rnn_predicts_legal_chord():
    engine = RnnEngine(JAZZNET_DIR, seed=42)
    result = engine.sample("G:7")
    assert result.output is not None
    assert result.output not in {"pad", "<BOS>", "<EOS>"}
    assert ":" in result.output


def test_lstm_predicts_legal_chord():
    engine = LstmEngine(JAZZNET_DIR, seed=42)
    result = engine.sample("G:7")
    assert result.output is not None
    assert result.output not in {"pad", "<BOS>", "<EOS>"}
    assert ":" in result.output


def test_neural_unknown_chord_echo_fallback():
    engine = LstmEngine(JAZZNET_DIR, fallback="echo_input", seed=42)
    result = engine.sample("X:???")
    assert result.fallback_used is True
    assert result.output == "X:???"
