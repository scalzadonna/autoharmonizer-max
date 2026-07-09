# Autoharmonizer Max — Chord Generator (Markov + JazzNet)

A local Max + Python system that sends one chord symbol to a Python service over OSC/UDP and receives one next chord. Three backends are available:

| Model | Source |
|---|---|
| **markov** | First-order Markov chain from CSV (default) |
| **rnn** | JazzNet baseline RNN (epoch 35) |
| **lstm** | JazzNet ChordLSTM (epoch 35) |

Chord labels (e.g. `G:7`, `C:maj7`) are treated as opaque strings; RNN/LSTM map them into a 115-chord JazzNet vocabulary when needed.

**Protocol version:** v3  
**Canonical spec:** [PLAN.md](PLAN.md)  
**Colleague testing guide:** [docs/TESTING.md](docs/TESTING.md) ← start here for setup and verification

## How it works

```
Max patch                         Python service
──────────                        ──────────────
[chord input]                     active backend (markov / rnn / lstm)
[model menu]  ──/control/model──► load engine + sample next chord
     │  /chord/input (UDP)              │
     └──────────────────────────►  weighted / neural sample
                                        │
     ◄──────────────────────────  /chord/output (UDP)
[output display]
```

- **Max** handles UI, model selection, OSC transport, status, and downstream routing.
- **Python** loads the active engine (Markov CSV or JazzNet checkpoint), samples the next chord, and replies over OSC.
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

Open [`max/chord_generator_device.maxpat`](max/chord_generator_device.maxpat) in Max.

**First time only:** click **npm install** in the patch (or run `npm install` in the `max/` folder).

1. Click **ping** — status should show `ready` when `/status/pong` is received.
2. Pick a **model** from the menu (`markov`, `rnn`, or `lstm`).
3. Pick a **chord** from the menu (default: `C:maj7`) and click **send**.
4. The sampled next chord appears in **output** (e.g. `C:maj` or `G:7`).
5. With **rnn** or **lstm**, send several chords — **session step** should increment (session is on by default).

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
| Neural temperature | `--neural-temperature` | `NEURAL_TEMPERATURE` | `1.5` |
| Exclude input chord (RNN/LSTM) | `--neural-exclude-input` / `--no-neural-exclude-input` | `NEURAL_EXCLUDE_INPUT` | on |
| Session mode | `--session-mode` | `SESSION_MODE` | `auto` |
| Session max steps | `--session-max-steps` | `SESSION_MAX_STEPS` | `64` |
| Auto-feed model output | `--session-auto-feed` / `--no-session-auto-feed` | `SESSION_AUTO_FEED` | on |

Example with LSTM backend and default neural sampling:

```bash
python3 -m src.main --model lstm
```

RNN/LSTM with **`--session-mode auto`** (default) run in **session mode**: hidden state carries across chord steps, and the model's output is auto-fed into the session. Markov always stays stateless. Force single-step (legacy) behavior with `--session-mode stateless`.

RNN/LSTM defaults use **temperature 1.5** and **exclude input chord** on the first session step so each chain tends to produce a transition rather than echoing the input. To restore the original peaked sampling:

```bash
python3 -m src.main --model lstm --neural-temperature 1.0 --no-neural-exclude-input
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

See **[docs/TESTING.md](docs/TESTING.md)** for a step-by-step colleague checklist (Python-only and Max).

Quick commands from `python/`:

```bash
python3 -m pytest -q                                      # full suite (67 tests)
python3 -m pytest tests/test_neural_models_suite.py -v    # RNN/LSTM only (46 tests)
python3 scripts/osc_smoke_test.py --spawn-service         # OSC smoke test (Markov)
```

Tests cover CSV loading, Markov sampling, RNN/LSTM inference across 13 chords, engine registry, fallback behavior, and localhost OSC round-trips.

## Repository layout

```text
autoharmonizer-max/
├── README.md
├── PLAN.md                            # Canonical spec (v1 + v2)
│
├── data/
│   ├── markov_openbook.csv            # Markov corpus
│   ├── chord_progressions_transitions.csv
│   └── jazznet/                       # RNN/LSTM (fetch via script)
│       ├── chords.json
│       ├── checkpoints/rnn|lstm/*.pt
│       └── metadata.json
│
├── docs/
│   ├── TESTING.md                     # Colleague setup & verification guide
│   └── osc_contract.md
│
├── max/
│   ├── chord_generator_device.maxpat     # UI + model switcher
│   ├── markov_osc.js
│   └── README.md
│
└── python/
    ├── requirements.txt               # python-osc, torch, pytest
    ├── src/
    │   ├── engines/                   # markov, rnn, lstm, registry
    │   ├── osc_service.py
    │   └── main.py
    ├── scripts/
    │   ├── fetch_jazznet_assets.py
    │   └── osc_smoke_test.py
    └── tests/
        ├── test_neural_models_suite.py
        └── ...
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
| [TESTING.md](docs/TESTING.md) | **Colleague guide** — setup, automated tests, Max checklist, troubleshooting |
| [osc_contract.md](docs/osc_contract.md) | OSC address quick reference |

### `max/`

| File | Purpose |
|---|---|
| `chord_generator_device.maxpat` | Max patch: chord input, **model switcher**, send/ping/reload, status/output/error |
| `markov_osc.js` | Node-for-Max bridge (v3): model + session control, 1500 ms reply timeout |
| `package.json` | Declares `node-osc` npm dependency for the bridge script |
| `README.md` | Max-specific controls, ports, and troubleshooting |

### `python/src/`

| File | Purpose |
|---|---|
| `config.py` | Parses CLI flags and env vars; defines OSC address constants and protocol version; resolves CSV paths relative to repo root |
| `csv_loader.py` | Loads and validates the transition CSV; merges duplicate rows; normalizes probabilities; builds in-memory lookup tables and a global fallback pool |
| `markov_engine.py` | Backward-compatible re-export; see `src/engines/markov_engine.py` |
| `osc_service.py` | OSC server/client; `/chord/input`, `/control/model`, ping/reload |
| `main.py` | Starts the service, configures logging, handles graceful shutdown on SIGINT/SIGTERM |

### `python/scripts/`

| File | Purpose |
|---|---|
| `osc_smoke_test.py` | Sends `/control/ping` and `/chord/input`; asserts `/chord/output` |
| `fetch_jazznet_assets.py` | Downloads RNN/LSTM checkpoints and vocab from JazzNet `train` branch |

### `python/tests/`

| File | Purpose |
|---|---|
| `test_csv_loader.py` | Tests header validation, openbook loading, duplicate merge, empty chord rejection |
| `test_markov_engine.py` | Tests known-chord sampling, unknown-chord fallback, empty input, seed determinism |
| `test_osc_flow.py` | OSC integration: ping/pong, chord output, model switch |
| `test_neural_models_suite.py` | RNN/LSTM: 13 chords × 2 models + registry + OSC |

## Troubleshooting

See [docs/TESTING.md](docs/TESTING.md#troubleshooting) for the full table. Common issues:

| Symptom | Likely cause |
|---|---|
| Max status stays `waiting` | Python service not running — start `python3 -m src.main` |
| `reply timeout` | Python stopped; or RNN/LSTM loading — wait for **active model**, retry |
| `node-osc missing` | Run `npm install` in `max/` or click **npm install** in patch |
| RNN/LSTM model switch fails | Run `python3 scripts/fetch_jazznet_assets.py` |
| Neural tests skipped in pytest | JazzNet checkpoints not downloaded |
| Garbled / no OSC reply | Run `python3 scripts/osc_smoke_test.py --spawn-service` to isolate Python |

## Further reading

- [docs/TESTING.md](docs/TESTING.md) — colleague setup and verification checklist
- [PLAN.md](PLAN.md) — full spec, build phases, and acceptance criteria
- [max/README.md](max/README.md) — Max patch controls and npm setup
- [docs/osc_contract.md](docs/osc_contract.md) — OSC address quick reference
