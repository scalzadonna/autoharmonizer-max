"""Tests for Markov sampling engine."""

from pathlib import Path

import pytest

from src.csv_loader import load_transition_table
from src.markov_engine import MarkovEngine


@pytest.fixture
def engine() -> MarkovEngine:
    path = Path(__file__).resolve().parents[2] / "data" / "markov_openbook.csv"
    table = load_transition_table(path)
    return MarkovEngine(table, fallback="echo_input", seed=42)


def test_known_chord_returns_legal_target(engine: MarkovEngine):
    result = engine.sample("G:7")
    assert result.output is not None
    assert result.error is None
    assert result.fallback_used is False
    assert result.candidates > 0
    legal = {item.to for item in engine._table.transitions_by_source["G:7"]}
    assert result.output in legal


def test_unknown_chord_echo_input(engine: MarkovEngine):
    result = engine.sample("X:???")
    assert result.output == "X:???"
    assert result.fallback_used is True
    assert result.error is not None


def test_empty_input(engine: MarkovEngine):
    result = engine.sample("   ")
    assert result.output is None
    assert result.error == "empty chord input"


def test_deterministic_with_seed():
    path = Path(__file__).resolve().parents[2] / "data" / "markov_openbook.csv"
    table = load_transition_table(path)
    a = MarkovEngine(table, seed=42).sample("G:7")
    b = MarkovEngine(table, seed=42).sample("G:7")
    assert a.output == b.output


def test_error_only_fallback():
    path = Path(__file__).resolve().parents[2] / "data" / "markov_openbook.csv"
    table = load_transition_table(path)
    engine = MarkovEngine(table, fallback="error_only", seed=42)
    result = engine.sample("X:???")
    assert result.output is None
    assert result.fallback_used is True


def test_temperature_default_is_identity(engine: MarkovEngine):
    # Reshaping at temperature 1.0 must not change the RNG path (determinism).
    baseline = MarkovEngine(engine._table, fallback="echo_input", seed=42).sample("G:7")
    engine.set_temperature(1.0)
    assert engine.sample("G:7").output == baseline.output


def test_temper_sharpens_and_flattens(engine: MarkovEngine):
    probs = (0.6, 0.3, 0.1)

    engine.set_temperature(0.1)  # spice "safe" -> sharpen toward the favourite
    hot = engine._temper(probs)
    assert hot[0] > probs[0]
    assert abs(sum(hot) - 1.0) < 1e-9

    engine.set_temperature(10.0)  # spice "wild" -> flatten toward uniform
    cold = engine._temper(probs)
    assert cold[0] < probs[0]
    assert abs(sum(cold) - 1.0) < 1e-9


def test_low_temperature_reduces_output_diversity(engine: MarkovEngine):
    # Directional property: safer (low temp) yields no more variety than wild.
    source = max(
        engine._table.weighted_choices_by_source,
        key=lambda s: len(engine._table.weighted_choices_by_source[s]),
    )
    engine.set_temperature(0.1)
    safe = {engine.sample(source).output for _ in range(60)}
    engine.set_temperature(3.0)
    wild = {engine.sample(source).output for _ in range(60)}
    assert len(safe) <= len(wild)
