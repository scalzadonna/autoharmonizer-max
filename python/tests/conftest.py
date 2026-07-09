"""Shared pytest fixtures for autoharmonizer-max."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

TESTS_DIR = Path(__file__).resolve().parent
if str(TESTS_DIR) not in sys.path:
    sys.path.insert(0, str(TESTS_DIR))

from neural_helpers import (  # noqa: E402
    CHORDS_JSON,
    JAZZNET_AVAILABLE,
    JAZZNET_DIR,
    LSTM_CKPT,
    NEURAL_TEST_CHORDS,
    RNN_CKPT,
)
from src.engines.jazznet_vocab import JazzNetVocab, load_vocab
from src.engines.lstm_engine import LstmEngine
from src.engines.rnn_engine import RnnEngine

requires_jazznet = pytest.mark.skipif(
    not JAZZNET_AVAILABLE,
    reason="JazzNet assets missing; run: python scripts/fetch_jazznet_assets.py",
)


@pytest.fixture(scope="module")
def jazznet_vocab() -> JazzNetVocab:
    if not CHORDS_JSON.is_file():
        pytest.skip("JazzNet chords.json not found")
    return load_vocab(CHORDS_JSON)


@pytest.fixture(scope="module")
def rnn_engine() -> RnnEngine:
    if not RNN_CKPT.is_file():
        pytest.skip("RNN checkpoint not found")
    return RnnEngine(JAZZNET_DIR, seed=42)


@pytest.fixture(scope="module")
def lstm_engine() -> LstmEngine:
    if not LSTM_CKPT.is_file():
        pytest.skip("LSTM checkpoint not found")
    return LstmEngine(JAZZNET_DIR, seed=42)


@pytest.fixture(scope="module")
def neural_test_chords(jazznet_vocab: JazzNetVocab) -> list[str]:
    missing = [c for c in NEURAL_TEST_CHORDS if c not in jazznet_vocab.chord_to_idx]
    assert not missing, f"test chord(s) not in vocab: {missing}"
    return list(NEURAL_TEST_CHORDS)
