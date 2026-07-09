"""Tests for neural sampling options (temperature, exclude input)."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

_TESTS_DIR = Path(__file__).resolve().parent
if str(_TESTS_DIR) not in sys.path:
    sys.path.insert(0, str(_TESTS_DIR))

from neural_helpers import CHORDS_JSON, JAZZNET_AVAILABLE, JAZZNET_DIR
from src.engines.jazznet_inference import apply_sampling_distribution
from src.engines.jazznet_vocab import load_vocab
from src.engines.lstm_engine import LstmEngine
from src.engines.rnn_engine import RnnEngine

pytestmark = pytest.mark.skipif(
    not JAZZNET_AVAILABLE,
    reason="JazzNet assets missing",
)


@pytest.fixture
def vocab():
    return load_vocab(CHORDS_JSON)


def test_exclude_input_forces_different_chord():
    engine = RnnEngine(
        JAZZNET_DIR,
        seed=42,
        temperature=1.0,
        exclude_input=True,
    )
    result = engine.sample("G:7")
    assert result.output is not None
    assert result.output != "G:7"


def test_legacy_sampling_can_echo_input():
    engine = RnnEngine(
        JAZZNET_DIR,
        seed=42,
        temperature=1.0,
        exclude_input=False,
    )
    result = engine.sample("G:7")
    assert result.output == "G:7"


def test_higher_temperature_adds_variety_without_exclude():
    outputs = set()
    for seed in range(20):
        engine = LstmEngine(
            JAZZNET_DIR,
            seed=seed,
            temperature=2.0,
            exclude_input=False,
        )
        result = engine.sample("G:7")
        assert result.output is not None
        outputs.add(result.output)
    assert len(outputs) >= 2


def test_apply_sampling_distribution_masks_input(vocab):
    logits = __import__("torch").zeros(vocab.vocab_size)
    idx = vocab.chord_index("G:7")
    assert idx is not None
    logits[idx] = 10.0
    logits[vocab.chord_index("C:maj7") or 0] = 1.0

    probs = apply_sampling_distribution(
        logits,
        vocab=vocab,
        temperature=1.0,
        exclude_indices={idx},
    )
    assert probs[idx].item() == 0.0
    assert probs.sum().item() == pytest.approx(1.0)
