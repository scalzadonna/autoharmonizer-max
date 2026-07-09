"""Single-step next-chord inference for JazzNet models."""

from __future__ import annotations

import torch
import torch.nn as nn
import torch.nn.functional as F

from .jazznet_vocab import JazzNetVocab

SPECIAL_TOKENS = {"pad", "<BOS>", "<EOS>"}


def predict_next_index(
    model: nn.Module,
    context_indices: list[int],
    *,
    vocab: JazzNetVocab,
    rnn: bool = False,
    generator: torch.Generator | None = None,
    max_resample: int = 10,
) -> tuple[int, float]:
    device = next(model.parameters()).device
    input_seq = torch.LongTensor([context_indices]).to(device)

    with torch.no_grad():
        if rnn:
            output, _ = model(input_seq)
        else:
            length = torch.tensor([len(context_indices)]).to("cpu")
            output, _ = model(input_seq, length)

        probabilities = F.softmax(output[0][-1], dim=0)

    for _ in range(max_resample):
        if generator is not None:
            next_token = torch.multinomial(probabilities, 1, generator=generator).item()
        else:
            next_token = torch.multinomial(probabilities, 1).item()
        if not vocab.is_special(next_token):
            return next_token, float(probabilities[next_token].item())

    # Fallback to argmax among non-special tokens
    probs = probabilities.clone()
    for idx in (vocab.pad_idx, vocab.bos_idx, vocab.eos_idx):
        probs[idx] = 0.0
    if probs.sum() <= 0:
        raise ValueError("no valid next token in model output")
    next_token = int(torch.argmax(probs).item())
    return next_token, float(probabilities[next_token].item())
