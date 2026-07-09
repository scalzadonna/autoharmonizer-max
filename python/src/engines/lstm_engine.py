"""JazzNet ChordLSTM chord engine."""

from __future__ import annotations

import json
import logging
import random
from pathlib import Path

from ..chord_simplifier import ChordSimplifier
from ..config import DEFAULT_FALLBACK
from .base import SampleResult
from .jazznet_checkpoint import load_checkpoint_state
from .jazznet_inference import predict_next_index
from .jazznet_models import ChordLSTM
from .jazznet_vocab import JazzNetVocab, load_vocab

logger = logging.getLogger(__name__)


class LstmEngine:
    name = "lstm"

    def __init__(
        self,
        jazznet_dir: Path,
        *,
        epoch: int = 35,
        fallback: str = DEFAULT_FALLBACK,
        seed: int | None = None,
    ) -> None:
        self._jazznet_dir = jazznet_dir
        self._epoch = epoch
        self._fallback = fallback
        self._rng = random.Random(seed)
        self._torch_rng = random.Random(seed)
        self._simplifier = ChordSimplifier()
        self._vocab: JazzNetVocab | None = None
        self._model: ChordLSTM | None = None
        self._device = None

    def _ensure_loaded(self) -> None:
        if self._model is not None:
            return

        import torch

        chords_path = self._jazznet_dir / "chords.json"
        if not chords_path.is_file():
            raise FileNotFoundError(f"JazzNet vocab not found: {chords_path}")

        checkpoint = (
            self._jazznet_dir / "checkpoints" / "lstm" / f"ChordLSTM-epoch{self._epoch}.pt"
        )
        if not checkpoint.is_file():
            raise FileNotFoundError(f"LSTM checkpoint not found: {checkpoint}")

        meta_path = self._jazznet_dir / "metadata.json"
        if meta_path.is_file():
            meta = json.loads(meta_path.read_text())
            hparams = meta.get("hyperparameters", {})
        else:
            hparams = {}

        self._vocab = load_vocab(chords_path)
        embedding_dim = hparams.get("embedding_dim", 48)
        hidden_dim = hparams.get("hidden_dim", 128)
        n_layers = hparams.get("n_layers", 2)
        dropout = hparams.get("dropout", 0.3)

        self._device = torch.device("cpu")
        model = ChordLSTM(
            self._vocab.vocab_size,
            embedding_dim,
            hidden_dim,
            self._vocab.vocab_size,
            n_layers,
            dropout=dropout,
            padding_idx=0,
        )
        state = load_checkpoint_state(checkpoint, self._device)
        model.load_state_dict(state)
        model.eval()
        model.to(self._device)
        self._model = model
        logger.info("loaded LSTM checkpoint epoch=%s from %s", self._epoch, checkpoint)

    def _resolve_chord(self, chord: str) -> tuple[int | None, str | None]:
        assert self._vocab is not None
        idx = self._vocab.chord_index(chord)
        if idx is not None:
            return idx, chord

        simplified = self._simplifier.simplify_chord(chord)
        if simplified == "Invalid/No Chord":
            return None, None

        idx = self._vocab.chord_index(simplified)
        if idx is not None:
            return idx, simplified
        return None, None

    def sample(self, raw_input: str) -> SampleResult:
        chord = raw_input.strip()
        if not chord:
            return SampleResult(
                output=None,
                probability=None,
                candidates=0,
                fallback_used=False,
                error="empty chord input",
            )

        try:
            self._ensure_loaded()
        except (FileNotFoundError, ImportError) as exc:
            return SampleResult(
                output=None,
                probability=None,
                candidates=0,
                fallback_used=True,
                error=f"LSTM engine unavailable: {exc}",
            )

        assert self._vocab is not None and self._model is not None

        idx, mapped = self._resolve_chord(chord)
        if idx is None:
            return self._apply_fallback(chord)

        context = [self._vocab.bos_idx, idx]
        try:
            next_idx, prob = predict_next_index(
                self._model,
                context,
                vocab=self._vocab,
                rnn=False,
                rng=self._torch_rng,
            )
        except ValueError as exc:
            return SampleResult(
                output=None,
                probability=None,
                candidates=0,
                fallback_used=True,
                error=str(exc),
            )

        output = self._vocab.index_chord(next_idx)
        if output is None or output in {"pad", "<BOS>", "<EOS>"}:
            return self._apply_fallback(chord)

        return SampleResult(
            output=output,
            probability=prob,
            candidates=self._vocab.vocab_size,
            fallback_used=False,
        )

    def _apply_fallback(self, chord: str) -> SampleResult:
        error = f"unknown chord: {chord}"
        policy = self._fallback

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
            assert self._vocab is not None
            for idx, label in sorted(self._vocab.idx_to_chord.items()):
                if label not in {"pad", "<BOS>", "<EOS>"}:
                    return SampleResult(
                        output=label,
                        probability=None,
                        candidates=0,
                        fallback_used=True,
                        error=error,
                    )
        if policy == "random_source":
            assert self._vocab is not None
            choices = [
                label
                for label in self._vocab.chord_to_idx
                if label not in {"pad", "<BOS>", "<EOS>"}
            ]
            return SampleResult(
                output=self._rng.choice(choices),
                probability=None,
                candidates=len(choices),
                fallback_used=True,
                error=error,
            )

        raise ValueError(f"Unsupported fallback policy: {policy}")
