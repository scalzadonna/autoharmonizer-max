# autoharmonizer-max

A Python tool for generating chord progressions with a first-order Markov chain, and streaming them over OSC to a Max/MSP device.

Given a starting chord, the chain samples the next chord according to transition weights learned from a dataset. You can query a single next chord, generate a full progression, or stream chords in real time to Max over UDP.

## Features

- **First-order Markov chain** over chord symbols
- **CSV dataset support** — load transition weights from a file (included: `markov_openbook.csv`)
- **Built-in fallback table** — works without a CSV for quick experiments
- **CLI and Python API** — use from the terminal or import in your own code
- **OSC streaming** — send chords to Max at a configurable tempo
- **Tests** — stdlib `unittest` suite, no extra test dependencies

## Project layout

```
markov_chords.py       # Markov chain, CSV loader, OSC streaming, CLI
markov_openbook.csv    # OpenBook transition dataset (~905 transitions)
test_markov_chords.py  # Unit tests
requirements.txt       # python-osc (only needed for OSC streaming)
```

## Requirements

- Python 3.7+
- `python-osc>=1.8` — only required when using `--osc` (installed via `requirements.txt`)

The core Markov chain logic uses only the Python standard library.

## Installation

```bash
pip install -r requirements.txt
```

If you only need local generation (no OSC), you can skip this step.

## Dataset format

`markov_openbook.csv` uses this schema:

| Column        | Description                          |
|---------------|--------------------------------------|
| `chord_from`  | Current chord (e.g. `G:7`, `C:maj`)  |
| `chord_to`    | Next chord                           |
| `count`       | Raw transition count (default weight)|
| `probability` | Normalized probability             |

Example rows:

```csv
chord_from,chord_to,count,probability
G:7,C:maj,529,0.462
G:7,C:maj7,241,0.2105
G:7,D:min7,86,0.0751
```

By default, sampling uses the `count` column. Use `--weight probability` to sample from probabilities instead (both produce equivalent relative weights).

## CLI usage

### Next chord

```bash
python3 markov_chords.py "G:7" --csv markov_openbook.csv
# -> C:maj
```

### Generate a progression

```bash
python3 markov_chords.py "C:maj" --csv markov_openbook.csv -n 8 --seed 42
# -> C:maj D:7 G:maj G:maj7 E:7 A:7 F:min C:maj
```

### Built-in table (no CSV)

```bash
python3 markov_chords.py C -n 4
```

### CLI options

| Option | Default | Description |
|--------|---------|-------------|
| `chord` | — | Starting chord |
| `-n`, `--length` | `1` | Number of chords to generate |
| `--seed` | — | Random seed for reproducible output |
| `--csv` | — | Path to transitions CSV |
| `--weight` | `count` | Weight column: `count` or `probability` |
| `--osc` | off | Stream over OSC instead of printing |
| `--host` | `127.0.0.1` | OSC destination host |
| `--port` | `7400` | OSC destination port |
| `--address` | `/chord` | OSC address pattern |
| `--bpm` | `120` | Tempo (one chord per beat) |
| `--interval` | — | Seconds between chords (overrides `--bpm`) |

## Python API

```python
from markov_chords import MarkovChain, next_chord, stream_progression, make_osc_client

# One-shot with the built-in table
next_chord("G", seed=1)

# Load from CSV
chain = MarkovChain.from_csv("markov_openbook.csv", seed=1)

# Sample the next chord
chain.next_chord("G:7")  # e.g. 'C:maj'

# Generate a progression
chain.generate("C:maj", 8)

# Train on your own sequences
chain.train(["C", "G", "Am", "F", "C"])

# Stream over OSC
client = make_osc_client("127.0.0.1", 7400)
for chord in stream_progression(chain, "C:maj", 8, send=client.send_message):
    print(chord)
```

## OSC streaming to Max

Stream a progression to a Max patch listening on UDP:

```bash
python3 markov_chords.py "C:maj" --csv markov_openbook.csv \
  -n 8 --osc --host 127.0.0.1 --port 7400 --address /chord --bpm 90
```

Each chord is sent as an OSC message:

```
/chord "C:maj"
/chord "D:7"
/chord "G:maj"
...
```

### Max patch setup

A minimal receive chain:

```
[udpreceive 7400]
    |
[route /chord]
    |
(outlet — chord symbol, e.g. C:maj)
```

Make sure the port in Max matches `--port` (default `7400`).

## Behavior notes

- **Unknown start chord** — `next_chord()` and `generate()` raise `KeyError` if the chord is not in the chain.
- **Dead ends** — if a generated progression reaches a chord with no outgoing transitions, `generate()` stops early and returns the progression built so far. OSC streaming follows the same behavior.
- **Reproducibility** — pass `--seed` (CLI) or `seed=` (API) for deterministic output.
- **Training** — `train()` updates weights from an ordered list of chords without mutating the shared default table.

## Tests

```bash
python3 -m unittest test_markov_chords -v
```

The suite covers CSV loading, sampling, progression generation, dead-end handling, OSC streaming logic, and integration with `markov_openbook.csv`.

## License

See repository history for authorship and licensing details.
