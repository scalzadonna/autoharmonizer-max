"""Weighted Markov sampling with fallback policies."""

from __future__ import annotations

import random

from ..config import DEFAULT_FALLBACK
from ..csv_loader import TransitionTable
from .base import SampleResult


class MarkovEngine:
    name = "markov"

    def __init__(
        self,
        table: TransitionTable,
        *,
        fallback: str = DEFAULT_FALLBACK,
        seed: int | None = None,
    ) -> None:
        self._table = table
        self._fallback = fallback
        self._rng = random.Random(seed)
        self._temperature = 1.0

    def set_temperature(self, temperature: float) -> None:
        """Set sampling temperature (>1 flattens = more adventurous, <1 sharpens)."""
        self._temperature = max(0.05, float(temperature))

    def _temper(self, probs: tuple[float, ...]) -> list[float]:
        """Reshape a probability vector by temperature. Identity at 1.0."""
        t = self._temperature
        if t == 1.0:
            return list(probs)
        adjusted = [p ** (1.0 / t) for p in probs]
        total = sum(adjusted)
        if total <= 0.0:
            return list(probs)
        return [a / total for a in adjusted]

    def sample(self, raw_input: str, *, session: bool = False) -> SampleResult:
        chord = raw_input.strip()

        if not chord:
            return SampleResult(
                output=None,
                probability=None,
                candidates=0,
                fallback_used=False,
                error="empty chord input",
            )

        weights = self._table.weighted_choices_by_source.get(chord)
        if weights:
            targets, probs = zip(*weights)
            chosen = self._rng.choices(list(targets), weights=self._temper(probs), k=1)[0]
            idx = list(targets).index(chosen)
            return SampleResult(
                output=chosen,
                probability=probs[idx],
                candidates=len(weights),
                fallback_used=False,
            )

        return self._apply_fallback(chord)

    def _apply_fallback(self, chord: str) -> SampleResult:
        policy = self._fallback
        error = f"unknown chord: {chord}"

        if policy == "error_only":
            return SampleResult(
                output=None,
                probability=None,
                candidates=0,
                fallback_used=True,
                error=error,
            )

        if policy == "echo_input":
            return SampleResult(
                output=chord,
                probability=None,
                candidates=0,
                fallback_used=True,
                error=error,
            )

        if policy == "global_top":
            top_chord = self._table.global_fallback_pool[0][0]
            return SampleResult(
                output=top_chord,
                probability=None,
                candidates=0,
                fallback_used=True,
                error=error,
            )

        if policy == "random_source":
            source = self._rng.choice(list(self._table.weighted_choices_by_source.keys()))
            weights = self._table.weighted_choices_by_source[source]
            targets, probs = zip(*weights)
            chosen = self._rng.choices(list(targets), weights=list(probs), k=1)[0]
            idx = list(targets).index(chosen)
            return SampleResult(
                output=chosen,
                probability=probs[idx],
                candidates=len(weights),
                fallback_used=True,
                error=error,
            )

        raise ValueError(f"Unsupported fallback policy: {policy}")
