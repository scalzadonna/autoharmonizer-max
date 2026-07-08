"""Query a Markov chain of chord transitions.

Given a single chord (a string), sample the next chord according to
transition weights learned from example progressions.
"""

from __future__ import annotations

import argparse
import csv
import random
import time
from collections import defaultdict
from typing import Callable, Iterator


# Default transition weights: {current_chord: {next_chord: weight}}.
# Weights are relative counts; they do not need to sum to 1.
DEFAULT_TRANSITIONS: dict[str, dict[str, float]] = {
    "C": {"G": 3, "Am": 2, "F": 3, "Dm": 1, "Em": 1},
    "G": {"C": 4, "Am": 2, "Em": 1, "D": 1},
    "Am": {"F": 3, "G": 2, "C": 1, "Dm": 1},
    "F": {"C": 3, "G": 2, "Dm": 1, "Am": 1},
    "Dm": {"G": 3, "Am": 1, "F": 1},
    "Em": {"Am": 2, "C": 1, "F": 1},
    "D": {"G": 3, "Em": 1},
}


def load_transitions_csv(
    path: str,
    weight_column: str = "count",
) -> dict[str, dict[str, float]]:
    """Load transition weights from a CSV file.

    Expects columns: ``chord_from``, ``chord_to`` and a weight column
    (``count`` by default, ``probability`` also available).
    """
    transitions: dict[str, dict[str, float]] = defaultdict(dict)
    with open(path, newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        required = {"chord_from", "chord_to", weight_column}
        missing = required - set(reader.fieldnames or [])
        if missing:
            raise ValueError(
                f"CSV {path!r} is missing required column(s): {sorted(missing)}"
            )
        for row in reader:
            chord_from = row["chord_from"]
            chord_to = row["chord_to"]
            transitions[chord_from][chord_to] = float(row[weight_column])
    return dict(transitions)


class MarkovChain:
    """A first-order Markov chain over chord symbols."""

    @classmethod
    def from_csv(
        cls,
        path: str,
        weight_column: str = "count",
        seed: int | None = None,
    ) -> "MarkovChain":
        """Build a chain from a transitions CSV file."""
        return cls(load_transitions_csv(path, weight_column), seed=seed)

    def __init__(
        self,
        transitions: dict[str, dict[str, float]] | None = None,
        seed: int | None = None,
    ) -> None:
        # Copy so external mutation / training does not affect the defaults.
        source = DEFAULT_TRANSITIONS if transitions is None else transitions
        self.transitions: dict[str, dict[str, float]] = {
            chord: dict(nexts) for chord, nexts in source.items()
        }
        self._rng = random.Random(seed)

    def train(self, sequence: list[str]) -> None:
        """Update transition weights from an ordered list of chords."""
        counts = {
            chord: defaultdict(float, nexts)
            for chord, nexts in self.transitions.items()
        }
        for current, nxt in zip(sequence, sequence[1:]):
            counts.setdefault(current, defaultdict(float))[nxt] += 1
        self.transitions = {chord: dict(nexts) for chord, nexts in counts.items()}

    def next_chord(self, chord: str) -> str:
        """Return a chord sampled from the transitions of ``chord``.

        Raises KeyError if the chord is unknown to the chain.
        """
        options = self.transitions.get(chord)
        if not options:
            raise KeyError(f"No transitions known for chord: {chord!r}")
        chords = list(options.keys())
        weights = list(options.values())
        return self._rng.choices(chords, weights=weights, k=1)[0]

    def generate(self, chord: str, length: int) -> list[str]:
        """Generate a progression of up to ``length`` chords from ``chord``.

        The start chord must be known to the chain, otherwise KeyError is
        raised. If the walk later reaches a chord with no outgoing
        transitions (a dead end), generation stops early and the
        progression built so far is returned.
        """
        if chord not in self.transitions:
            raise KeyError(f"No transitions known for chord: {chord!r}")
        progression = [chord]
        current = chord
        for _ in range(length - 1):
            try:
                current = self.next_chord(current)
            except KeyError:
                break
            progression.append(current)
        return progression


def next_chord(chord: str, seed: int | None = None) -> str:
    """Convenience wrapper: sample the next chord using the default chain."""
    return MarkovChain(seed=seed).next_chord(chord)


def make_osc_client(host: str = "127.0.0.1", port: int = 7400):
    """Create an OSC UDP client for streaming chords to Max.

    ``python-osc`` is imported lazily so the rest of this module works
    without the dependency installed.
    """
    try:
        from pythonosc.udp_client import SimpleUDPClient
    except ImportError as exc:  # pragma: no cover - depends on environment
        raise ImportError(
            "python-osc is required for OSC streaming. "
            "Install it with: pip install python-osc"
        ) from exc
    return SimpleUDPClient(host, port)


def stream_progression(
    chain: "MarkovChain",
    start: str,
    length: int,
    send: Callable[[str, str], None],
    address: str = "/chord",
    interval: float = 0.5,
    sleep: Callable[[float], None] = time.sleep,
) -> Iterator[str]:
    """Generate a progression and emit each chord via ``send``.

    ``send`` is called as ``send(address, chord)`` for every chord, with
    ``interval`` seconds of wait between chords (no wait after the last).
    Each emitted chord is also yielded so callers can log or display it.
    """
    progression = chain.generate(start, length)
    last_index = len(progression) - 1
    for index, chord in enumerate(progression):
        send(address, chord)
        yield chord
        if index < last_index:
            sleep(interval)


def main() -> None:
    parser = argparse.ArgumentParser(description="Query a chord Markov chain.")
    parser.add_argument("chord", help="Starting chord, e.g. 'C' or 'Am'.")
    parser.add_argument(
        "-n",
        "--length",
        type=int,
        default=1,
        help="Number of chords to generate (default: 1, just the next chord).",
    )
    parser.add_argument("--seed", type=int, default=None, help="Random seed.")
    parser.add_argument(
        "--csv",
        dest="csv_path",
        default=None,
        help="Path to a transitions CSV (columns: chord_from, chord_to, count, "
        "probability). If omitted, a small built-in table is used.",
    )
    parser.add_argument(
        "--weight",
        default="count",
        choices=["count", "probability"],
        help="Which CSV column to use as sampling weight (default: count).",
    )
    osc = parser.add_argument_group("OSC streaming (to a Max device)")
    osc.add_argument(
        "--osc",
        action="store_true",
        help="Stream the progression over OSC/UDP instead of just printing it.",
    )
    osc.add_argument(
        "--host", default="127.0.0.1", help="OSC destination host (default: 127.0.0.1)."
    )
    osc.add_argument(
        "--port", type=int, default=7400, help="OSC destination port (default: 7400)."
    )
    osc.add_argument(
        "--address", default="/chord", help="OSC address pattern (default: /chord)."
    )
    osc.add_argument(
        "--bpm",
        type=float,
        default=120.0,
        help="Tempo in beats per minute; one chord per beat (default: 120).",
    )
    osc.add_argument(
        "--interval",
        type=float,
        default=None,
        help="Seconds between chords. Overrides --bpm when set.",
    )
    args = parser.parse_args()

    if args.csv_path:
        chain = MarkovChain.from_csv(
            args.csv_path, weight_column=args.weight, seed=args.seed
        )
    else:
        chain = MarkovChain(seed=args.seed)

    try:
        if args.osc:
            interval = args.interval if args.interval is not None else 60.0 / args.bpm
            client = make_osc_client(args.host, args.port)
            length = max(args.length, 1)
            print(
                f"Streaming {length} chord(s) to {args.host}:{args.port} "
                f"at {args.address} (every {interval:.3f}s)..."
            )
            for chord in stream_progression(
                chain,
                args.chord,
                length,
                send=client.send_message,
                address=args.address,
                interval=interval,
            ):
                print(f"  -> {chord}")
        elif args.length <= 1:
            print(chain.next_chord(args.chord))
        else:
            print(" ".join(chain.generate(args.chord, args.length)))
    except KeyError as exc:
        parser.error(str(exc))


if __name__ == "__main__":
    main()
