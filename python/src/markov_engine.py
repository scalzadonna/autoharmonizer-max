"""Backward-compatible re-exports for Markov engine."""

from .engines.base import SampleResult
from .engines.markov_engine import MarkovEngine

__all__ = ["MarkovEngine", "SampleResult"]
