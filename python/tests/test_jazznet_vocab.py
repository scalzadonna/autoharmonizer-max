"""Tests for JazzNet vocabulary loading."""

from __future__ import annotations

from pathlib import Path

import pytest

from src.engines.jazznet_vocab import load_vocab

REPO_ROOT = Path(__file__).resolve().parents[2]
CHORDS_PATH = REPO_ROOT / "data" / "jazznet" / "chords.json"


pytestmark = pytest.mark.skipif(
    not CHORDS_PATH.is_file(),
    reason="JazzNet assets not fetched; run scripts/fetch_jazznet_assets.py",
)


def test_vocab_size_and_special_tokens():
    vocab = load_vocab(CHORDS_PATH)
    assert vocab.vocab_size == 118
    assert vocab.bos_idx == 1
    assert vocab.eos_idx == 2
    assert vocab.pad_idx == 0


def test_common_chords_in_vocab():
    vocab = load_vocab(CHORDS_PATH)
    assert vocab.chord_index("G:7") == 111
    assert vocab.chord_index("C:maj7") == 47
