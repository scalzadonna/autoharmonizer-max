# Autoharmonizer Max — Chord Generator (Markov + JazzNet)

A local Max + Python system that sends one chord symbol to a Python service over OSC/UDP and receives one next chord. Three backends are available:

| Model | Source |
|---|---|
| **markov** | First-order Markov chain from CSV (default) |
| **rnn** | JazzNet baseline RNN (epoch 35) |
| **lstm** | JazzNet ChordLSTM (epoch 35) |

Chord labels (e.g. `G:7`, `C:maj7`) are treated as opaque strings; RNN/LSTM map them into a 115-chord JazzNet vocabulary when needed.

**Protocol version:** v2  
**Canonical spec:** [PLAN.md](PLAN.md)

## How it works

```
Max patch                         Python service
──────────                        ──────────────
[chord input]                     load CSV transition table
     │  /chord/input (UDP)              │
     └──────────────────────────►  weighted sample
                                        │
     ◄──────────────────────────  /chord/output (UDP)
[output display]
```

- **Max** handles UI, OSC transport, status, and downstream routing.
- **Python** loads the CSV, validates transitions, samples the next chord, and replies over OSC.
- Communication uses **localhost UDP** on fixed ports (`9000` / `9001`).

## Requirements

| Component | Requirement |
|---|---|
| Python | 3.9+ |
| Max | Max 8+ with Node for Max (included in standard installs) |
| Max npm package | `node-osc` (installed once via patch button or `npm install` in `max/`) |
| Python packages | `python-osc`, `torch`, `pytest` (see `python/requirements.txt`) |

## Quick start

### 1. Install Python dependencies

```bash
cd python
python3 -m pip install -r requirements.txt
```

### 2. Fetch JazzNet checkpoints (required for RNN/LSTM)

```bash
cd python
python3 scripts/fetch_jazznet_assets.py --branch train --epoch 35
```

This downloads vocab and checkpoints into `data/jazznet/`.

### 3. Start the Python service

```bash
cd python
python3 -m src.main
```

You should see log output confirming the CSV loaded and the OSC server is listening on `127.0.0.1:9000`.

### 4. Open the Max patch

Open [`max/chord_markov_device.maxpat`](max/chord_markov_device.maxpat) in Max.

**First time only:** click **npm install** in the patch (or run `npm install` in the `max/` folder).

1. Click **ping** — status should show `ready` when `/status/pong` is received.
2. Pick a **model** from the menu (`markov`, `rnn`, or `lstm`).
3. Enter a chord (e.g. `G:7`) and click **send**.
4. The sampled next chord appears in **output** (e.g. `C:maj` or `C:maj7`).

### 5. Verify without Max (optional)

```bash
cd python
python3 scripts/osc_smoke_test.py --spawn-service
```

Expected output:

```text
OK: /chord/input 'G:7' -> /chord/output 'C:maj7'
```

## Configuration

Settings are passed via **CLI flags** or **environment variables** (env vars override defaults).

| Setting | CLI flag | Env var | Default |
|---|---|---|---|
| Active model | `--model` | `CHORD_MODEL` | `markov` |
| JazzNet dir | `--jazznet-dir` | `JAZZNET_DIR` | `data/jazznet` |
| JazzNet epoch | `--jazznet-epoch` | `JAZZNET_EPOCH` | `35` |
| CSV path | `--csv` | `MARKOV_CSV` | `data/markov_openbook.csv` |
| Bind host | `--host` | `MARKOV_HOST` | `127.0.0.1` |
| Listen port | `--port` | `MARKOV_PORT` | `9000` |
| Max reply host | `--max-host` | `MARKOV_MAX_HOST` | `127.0.0.1` |
| Max reply port | `--max-port` | `MARKOV_MAX_PORT` | `9001` |
| Fallback policy | `--fallback` | `MARKOV_FALLBACK` | `echo_input` |
| Debug OSC | `--debug` | `MARKOV_DEBUG` | off |
| Random seed | `--seed` | `MARKOV_SEED` | unset |

Example with LSTM backend:

```bash
CHORD_MODEL=lstm python3 -m src.main
```

Example with deterministic Markov sampling:

```bash
MARKOV_SEED=42 python3 -m src.main --csv ../data/markov_openbook.csv --debug
```

### Fallback policies

When an unknown chord is received, Python emits `/error` and applies the configured policy:

| Policy | Behavior |
|---|---|
| `echo_input` (default) | Return the input chord unchanged |
| `global_top` | Return the most frequent global target chord |
| `random_source` | Sample a random known source, then one of its outputs |
| `error_only` | Emit `/error` only; no output |

## OSC protocol (summary)

| Direction | Address | Payload |
|---|---|---|
| Max → Python | `/chord/input` | string |
| Python → Max | `/chord/output` | string |
| Python → Max | `/status/ready` | int `1` |
| Python → Max | `/error` | string |
| Max → Python | `/control/ping` | _(none)_ |
| Python → Max | `/status/pong` | int `1` |
| Max → Python | `/control/reload` | _(none)_ |
| Max → Python | `/control/model` | string (`markov`, `rnn`, `lstm`) |
| Python → Max | `/status/model` | string |

Full contract: [PLAN.md](PLAN.md) · [docs/osc_contract.md](docs/osc_contract.md)

## Testing

```bash
cd python
python3 -m pytest -q
```

Tests cover CSV loading, Markov sampling, fallback behavior, and localhost OSC round-trips.

## Repository layout

```text
autoharmonizer-max/
├── README.md                          # This file
├── PLAN.md                            # Canonical implementation spec (protocol v1)
│
├── data/
│   ├── markov_openbook.csv            # Default transition corpus (~900 rows, 89 sources)
│   └── chord_progressions_transitions.csv  # Smaller corpus for smoke tests
│
├── markov_openbook.csv                # Source copy of openbook corpus (repo root)
├── chord_progressions_transitions.csv # Source copy of small corpus (repo root)
│
├── docs/
│   └── osc_contract.md                # OSC address mirror of PLAN.md
│
├── max/
│   ├── chord_markov_device.maxpat     # Standalone Max/MSP patch (UI + Node OSC bridge)
│   ├── markov_osc.js                  # Node-for-Max OSC client/server
│   ├── package.json                   # npm dependency on node-osc
│   └── README.md                      # Max-specific setup and troubleshooting
│
└── python/
    ├── requirements.txt               # python-osc, pytest
    ├── pytest.ini                     # Pytest config
    │
    ├── src/                           # Python OSC + Markov service
    │   ├── __init__.py
    │   ├── config.py                  # CLI/env parsing, OSC constants, path resolution
    │   ├── csv_loader.py              # CSV validation, duplicate merge, normalization
    │   ├── markov_engine.py           # Weighted sampling and fallback logic
    │   ├── osc_service.py             # OSC server/client, message handlers, reload
    │   └── main.py                    # Service entry point
    │
    ├── scripts/
    │   └── osc_smoke_test.py          # End-to-end OSC test without Max
    │
    └── tests/
        ├── test_csv_loader.py         # CSV schema, merge, validation tests
        ├── test_markov_engine.py      # Sampling, fallback, seed determinism
        └── test_osc_flow.py           # Localhost OSC integration tests
```

## File reference

### Root

| File | Purpose |
|---|---|
| `README.md` | Project overview, setup, and file guide |
| `PLAN.md` | Full implementation plan: architecture, OSC contract, build phases, acceptance criteria |
| `markov_openbook.csv` | Original transition data exported from the openbook corpus |
| `chord_progressions_transitions.csv` | Smaller transition set for quick testing |

### `data/`

Runtime copies of the CSV files used by the Python service. Default path: `data/markov_openbook.csv`.

CSV schema:

```text
chord_from,chord_to,count,probability
G:7,C:maj,529,0.462
G:7,C:maj7,241,0.2105
...
```

### `docs/`

| File | Purpose |
|---|---|
| `osc_contract.md` | Quick-reference mirror of the OSC addresses defined in `PLAN.md` |

### `max/`

| File | Purpose |
|---|---|
| `chord_markov_device.maxpat` | Max patch with chord input, send/ping/reload/npm buttons, status/output/error displays, and a symbol outlet |
| `markov_osc.js` | Node-for-Max bridge: sends/receives OSC to Python on ports 9000/9001, handles 500 ms reply timeout |
| `package.json` | Declares `node-osc` npm dependency for the bridge script |
| `README.md` | Max-specific controls, ports, and troubleshooting |

### `python/src/`

| File | Purpose |
|---|---|
| `config.py` | Parses CLI flags and env vars; defines OSC address constants and protocol version; resolves CSV paths relative to repo root |
| `csv_loader.py` | Loads and validates the transition CSV; merges duplicate rows; normalizes probabilities; builds in-memory lookup tables and a global fallback pool |
| `markov_engine.py` | Samples the next chord from weighted transitions; handles unknown/empty input via configurable fallback policies |
| `osc_service.py` | Runs the OSC UDP server and reply client; handles `/chord/input`, `/control/ping`, `/control/reload`; emits status, error, and optional debug messages |
| `main.py` | Starts the service, configures logging, handles graceful shutdown on SIGINT/SIGTERM |

### `python/scripts/`

| File | Purpose |
|---|---|
| `osc_smoke_test.py` | Sends `/control/ping` and `/chord/input` to a running (or spawned) service; asserts `/chord/output` is received |

### `python/tests/`

| File | Purpose |
|---|---|
| `test_csv_loader.py` | Tests header validation, openbook loading, duplicate merge, empty chord rejection |
| `test_markov_engine.py` | Tests known-chord sampling, unknown-chord fallback, empty input, seed determinism |
| `test_osc_flow.py` | In-process OSC integration tests for ping/pong, chord output, and error+echo fallback |

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| Max status stays `waiting` | Python service not running, or wrong port |
| `reply timeout` in Max | Python stopped, wrong port, or `node-osc` not installed |
| `node-osc missing` in Max | Click **npm install** in the patch, or run `npm install` in `max/` |
| Garbled / no OSC reply | Confirm Python is running; test with `python3 scripts/osc_smoke_test.py --spawn-service` |

## Further reading

- [PLAN.md](PLAN.md) — full spec, build phases, and acceptance criteria
- [max/README.md](max/README.md) — Max patch controls and setup
- [docs/osc_contract.md](docs/osc_contract.md) — OSC address quick reference
