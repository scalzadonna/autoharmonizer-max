"""Shared constants for neural model tests."""

from __future__ import annotations

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
JAZZNET_DIR = REPO_ROOT / "data" / "jazznet"
CHORDS_JSON = JAZZNET_DIR / "chords.json"
RNN_CKPT = JAZZNET_DIR / "checkpoints" / "rnn" / "baselineRNN-epoch35.pt"
LSTM_CKPT = JAZZNET_DIR / "checkpoints" / "lstm" / "ChordLSTM-epoch35.pt"
CSV_PATH = REPO_ROOT / "data" / "markov_openbook.csv"

NEURAL_TEST_CHORDS = [
    "G:7",
    "C:maj",
    "C:maj7",
    "D:min7",
    "A:min7",
    "F:maj7",
    "E:7",
    "A:7",
    "D:7",
    "B:min7",
    "A-:7",
    "F:min7",
    "G:min7",
]

SPECIAL_TOKENS = {"pad", "<BOS>", "<EOS>"}

JAZZNET_AVAILABLE = (
    RNN_CKPT.is_file() and LSTM_CKPT.is_file() and CHORDS_JSON.is_file()
)
