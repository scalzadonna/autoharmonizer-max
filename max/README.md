# Chord Generator Max Device (protocol v2)

Standalone Max/MSP patch that sends chord symbols to the Python chord service and displays the sampled reply. Supports three backends: **markov**, **rnn**, and **lstm**.

Uses **Node for Max** (`node.script` + `node-osc`) — **CNMAT externals are not required**.

**Colleague testing guide:** [docs/TESTING.md](../docs/TESTING.md)

## Requirements

- Max 8+ with Node for Max (included in standard Max 8 installs)
- Python 3.9+ service running locally (see [docs/TESTING.md](../docs/TESTING.md))
- JazzNet checkpoints fetched if using **rnn** or **lstm** (see below)
- One-time npm install from inside the patch

## Quick start

### 1. Python setup

From the repo root:

```bash
cd python
python3 -m pip install -r requirements.txt
python3 scripts/fetch_jazznet_assets.py --branch train --epoch 35   # for RNN/LSTM
python3 -m src.main
```

### 2. Open the patch

Open `chord_generator_device.maxpat` in Max.

### 3. Install npm dependencies (first time only)

Click **npm install** in the patch, or:

```bash
cd max
npm install
```

### 4. Ping, pick model, send

1. Click **ping** — **status** should show `ready`.
2. Select a **model** from the menu: `markov`, `rnn`, or `lstm`.
3. **active model** should match your selection (after `/status/model` from Python).
4. Select a **chord** from the menu (default: `C:maj7`), then click **send** — the next chord appears in **output**.
5. Click **reload** to reload the Markov CSV without restarting Python.
6. After updating `markov_osc.js`, click **restart js**.

## Default ports

| Role | Host | Port |
|---|---|---|
| Python listen | `127.0.0.1` | `9000` |
| Max listen | `127.0.0.1` | `9001` |

Ports are set in `markov_osc.js`. Change them there if you use non-default Python ports.

## Controls

| UI | Action |
|---|---|
| **model** (umenu) | Sends `/control/model` with `markov`, `rnn`, or `lstm` |
| **npm install** | Runs `script npm install` to fetch `node-osc` (first time only) |
| **ping** | Sends `/control/ping` |
| **chord** (umenu) | Select input chord (default `C:maj7`) |
| **send** | Sends `/chord/input` with the selected chord |
| **reload** | Sends `/control/reload` (Markov CSV only) |
| **restart js** | Restarts the Node bridge after JS edits |
| status | Shows `ready` or `waiting` |
| active model | Last `/status/model` from Python |
| output | Last `/chord/output` chord symbol |
| error | Last `/error` or `reply timeout` (1500 ms) |

## Model switcher notes

- Default model on Python startup is **markov** unless you set `CHORD_MODEL=lstm` (etc.) before launch.
- First selection of **rnn** or **lstm** triggers checkpoint load in Python (~2–5 s). Wait for **active model** to update before sending chords.
- RNN/LSTM may return the same chord as the input when `--neural-temperature 1.0 --no-neural-exclude-input` is set; defaults avoid this.

## Files in this folder

| File | Purpose |
|---|---|
| `chord_generator_device.maxpat` | Max UI with model switcher + Node bridge |
| `markov_osc.js` | Node-for-Max OSC client/server (v2) |
| `package.json` | npm dependency on `node-osc` |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `node-osc missing` error | Click **npm install** and wait for it to finish |
| Status stays `waiting` | Start Python (`python3 -m src.main` from `python/`) |
| `reply timeout` | Python not running; or RNN/LSTM still loading — wait and retry |
| Model menu does nothing | Check Python logs for `failed to load rnn/lstm`; re-run fetch script |
| `node.script` errors on load | Confirm Node for Max is enabled in Max 8 |

Verify without Max:

```bash
cd python
python3 -m pytest -q
python3 scripts/osc_smoke_test.py --spawn-service
```

Full colleague checklist: [docs/TESTING.md](../docs/TESTING.md)

## OSC addresses

See [PLAN.md](../PLAN.md) and [docs/osc_contract.md](../docs/osc_contract.md).
