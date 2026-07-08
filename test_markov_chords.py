"""Tests for markov_chords."""

import os
import tempfile
import unittest

from markov_chords import (
    MarkovChain,
    load_transitions_csv,
    next_chord,
    stream_progression,
)


SAMPLE_CSV = (
    "chord_from,chord_to,count,probability\n"
    "G:7,C:maj,3,0.75\n"
    "G:7,C:maj7,1,0.25\n"
    "C:maj,G:7,2,1.0\n"
)


class LoadTransitionsCsvTests(unittest.TestCase):
    def _write_csv(self, text: str) -> str:
        handle = tempfile.NamedTemporaryFile(
            "w", suffix=".csv", delete=False, newline=""
        )
        handle.write(text)
        handle.close()
        self.addCleanup(os.unlink, handle.name)
        return handle.name

    def test_loads_counts_by_default(self):
        path = self._write_csv(SAMPLE_CSV)
        transitions = load_transitions_csv(path)
        self.assertEqual(
            transitions,
            {"G:7": {"C:maj": 3.0, "C:maj7": 1.0}, "C:maj": {"G:7": 2.0}},
        )

    def test_loads_probability_column(self):
        path = self._write_csv(SAMPLE_CSV)
        transitions = load_transitions_csv(path, weight_column="probability")
        self.assertEqual(transitions["G:7"], {"C:maj": 0.75, "C:maj7": 0.25})

    def test_missing_column_raises(self):
        path = self._write_csv("chord_from,chord_to\nG:7,C:maj\n")
        with self.assertRaises(ValueError):
            load_transitions_csv(path)


class MarkovChainTests(unittest.TestCase):
    def _chain(self, seed=None) -> MarkovChain:
        transitions = {
            "G:7": {"C:maj": 3, "C:maj7": 1},
            "C:maj": {"G:7": 2},
            "C:maj7": {"G:7": 1},
        }
        return MarkovChain(transitions, seed=seed)

    def test_next_chord_returns_valid_option(self):
        chain = self._chain(seed=0)
        self.assertIn(chain.next_chord("G:7"), {"C:maj", "C:maj7"})

    def test_next_chord_is_deterministic_with_seed(self):
        first = self._chain(seed=123).next_chord("G:7")
        second = self._chain(seed=123).next_chord("G:7")
        self.assertEqual(first, second)

    def test_unknown_chord_raises_keyerror(self):
        with self.assertRaises(KeyError):
            self._chain(seed=0).next_chord("X:min")

    def test_generate_length_and_start(self):
        chain = self._chain(seed=1)
        progression = chain.generate("C:maj", 4)
        self.assertEqual(len(progression), 4)
        self.assertEqual(progression[0], "C:maj")

    def test_weights_bias_sampling(self):
        # C:maj is 3x as likely as C:maj7 after G:7.
        chain = self._chain(seed=7)
        draws = [chain.next_chord("G:7") for _ in range(2000)]
        c_maj = draws.count("C:maj")
        self.assertGreater(c_maj, draws.count("C:maj7"))

    def test_generate_stops_early_on_dead_end(self):
        # "Z" has no outgoing transitions, so the walk ends after reaching it.
        chain = MarkovChain({"A": {"Z": 1}}, seed=0)
        self.assertEqual(chain.generate("A", 5), ["A", "Z"])

    def test_generate_raises_on_unknown_start_chord(self):
        # An unknown *start* chord still raises immediately.
        chain = MarkovChain({"A": {"Z": 1}}, seed=0)
        with self.assertRaises(KeyError):
            chain.generate("Q", 3)

    def test_defaults_are_not_mutated_by_training(self):
        chain = MarkovChain(seed=0)
        original = dict(chain.transitions.get("C", {}))
        chain.train(["C", "C", "C"])
        other = MarkovChain(seed=0)
        self.assertEqual(other.transitions.get("C", {}), original)

    def test_train_adds_new_transitions(self):
        chain = MarkovChain({}, seed=0)
        chain.train(["A", "B", "A", "B"])
        self.assertEqual(chain.transitions["A"], {"B": 2.0})
        self.assertEqual(chain.transitions["B"], {"A": 1.0})


class ConvenienceAndCsvIntegrationTests(unittest.TestCase):
    def test_module_level_next_chord(self):
        # 'C' exists in the built-in default table.
        self.assertIsInstance(next_chord("C", seed=0), str)

    def test_from_csv_roundtrip(self):
        handle = tempfile.NamedTemporaryFile(
            "w", suffix=".csv", delete=False, newline=""
        )
        handle.write(SAMPLE_CSV)
        handle.close()
        self.addCleanup(os.unlink, handle.name)

        chain = MarkovChain.from_csv(handle.name, seed=0)
        self.assertEqual(chain.next_chord("C:maj"), "G:7")

    @unittest.skipUnless(
        os.path.exists("markov_openbook.csv"), "dataset file not present"
    )
    def test_real_dataset_loads_and_samples(self):
        chain = MarkovChain.from_csv("markov_openbook.csv", seed=0)
        self.assertGreater(len(chain.transitions), 0)
        start = next(iter(chain.transitions))
        self.assertIn(chain.next_chord(start), chain.transitions[start])


class StreamProgressionTests(unittest.TestCase):
    def _chain(self, seed=0) -> MarkovChain:
        return MarkovChain({"A": {"B": 1}, "B": {"A": 1}}, seed=seed)

    def test_sends_each_chord_with_address(self):
        sent = []
        sleeps = []
        emitted = list(
            stream_progression(
                self._chain(),
                "A",
                4,
                send=lambda addr, chord: sent.append((addr, chord)),
                address="/chord",
                interval=0.25,
                sleep=sleeps.append,
            )
        )
        self.assertEqual(emitted, ["A", "B", "A", "B"])
        self.assertEqual(sent, [("/chord", c) for c in emitted])

    def test_waits_between_chords_but_not_after_last(self):
        sleeps = []
        list(
            stream_progression(
                self._chain(),
                "A",
                3,
                send=lambda addr, chord: None,
                interval=0.5,
                sleep=sleeps.append,
            )
        )
        # 3 chords -> 2 gaps.
        self.assertEqual(sleeps, [0.5, 0.5])

    def test_stops_early_on_dead_end(self):
        sent = []
        chain = MarkovChain({"A": {"Z": 1}}, seed=0)
        emitted = list(
            stream_progression(
                chain,
                "A",
                5,
                send=lambda addr, chord: sent.append(chord),
                sleep=lambda _: None,
            )
        )
        self.assertEqual(emitted, ["A", "Z"])


if __name__ == "__main__":
    unittest.main()
