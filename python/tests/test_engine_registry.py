"""Tests for engine registry and model switching."""

from __future__ import annotations

from pathlib import Path

import pytest

from src.engines.registry import EngineRegistry

REPO_ROOT = Path(__file__).resolve().parents[2]
CSV_PATH = REPO_ROOT / "data" / "markov_openbook.csv"
JAZZNET_DIR = REPO_ROOT / "data" / "jazznet"


@pytest.fixture
def registry():
    reg = EngineRegistry(
        csv_path=CSV_PATH,
        jazznet_dir=JAZZNET_DIR,
        jazznet_epoch=35,
        fallback="echo_input",
        seed=42,
        neural_temperature=1.5,
        neural_exclude_input=True,
        initial_model="markov",
    )
    reg.load_markov()
    return reg


def test_markov_sample(registry):
    result = registry.sample("G:7")
    assert result.output is not None
    assert registry.active_name == "markov"


def test_invalid_model_rejected(registry):
    ok, err = registry.set_model("transformer")
    assert ok is False
    assert err is not None
    assert registry.active_name == "markov"


@pytest.mark.skipif(
    not (JAZZNET_DIR / "checkpoints" / "lstm" / "ChordLSTM-epoch35.pt").is_file(),
    reason="JazzNet checkpoints not fetched",
)
def test_switch_to_lstm(registry):
    ok, err = registry.set_model("lstm")
    assert ok is True, err
    assert registry.active_name == "lstm"
    result = registry.sample("G:7")
    assert result.output is not None
