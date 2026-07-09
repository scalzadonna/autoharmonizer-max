# Testing guide (v2)

This guide is for colleagues who want to set up and verify **autoharmonizer-max** on their machine. It covers Python-only checks first, then the Max patch, for all three backends: **markov**, **rnn**, and **lstm**.

**Time estimate:** ~15 minutes first time (includes downloading JazzNet checkpoints and Python/torch install).

## What you are testing

| Backend | What it does | Requires JazzNet checkpoints? |
|---|---|---|
| `markov` | Samples next chord from CSV transition probabilities | No |
| `rnn` | JazzNet baseline RNN (epoch 35) | Yes |
| `lstm` | JazzNet ChordLSTM (epoch 35) | Yes |

All backends use the same OSC flow: send one chord in, receive one chord out.

---

## Prerequisites

| Requirement | Notes |
|---|---|
| **Python 3.9+** | Check with `python3 --version` |
| **Max 8+** | Node for Max included in standard installs |
| **Git** | To clone the repo |
| **Network** | First-time setup downloads pip packages and ~4 MB of JazzNet assets |
| **Ports 9000 / 9001** | Must be free on localhost (only one Python service at a time) |

Clone the repo and checkout the release tag if you want a known baseline:

```bash
git clone https://github.com/scalzadonna/autoharmonizer-max.git
cd autoharmonizer-max
git checkout v2.0.0   # optional but recommended
```

---

## Setup (from repo root)

Run these steps in order.

### 1. Python dependencies

```bash
cd python
python3 -m pip install -r requirements.txt
```

First install of `torch` may take a few minutes.

### 2. JazzNet checkpoints (required for RNN/LSTM)

```bash
python3 scripts/fetch_jazznet_assets.py --branch train --epoch 35
```

Verify the files exist:

```bash
ls -lh ../data/jazznet/chords.json
ls -lh ../data/jazznet/checkpoints/rnn/baselineRNN-epoch35.pt
ls -lh ../data/jazznet/checkpoints/lstm/ChordLSTM-epoch35.pt
```

Expected sizes: `chords.json` ~2 MB, RNN checkpoint ~934 KB, LSTM checkpoint ~2.9 MB.

### 3. Max npm dependencies (required for the patch)

```bash
cd ../max
npm install
```

Or click **npm install** in the Max patch after opening it.

---

## Level 1 — Automated tests (no Max)

From `python/`:

```bash
# Full suite (67 tests) — run this first
python3 -m pytest -q

# Neural-only suite (46 tests, RNN/LSTM + OSC)
python3 -m pytest tests/test_neural_models_suite.py -v
```

**Pass criteria:** all tests pass. If neural tests are skipped, you forgot step 2 (fetch JazzNet assets).

### Smoke test (Markov, no Max)

```bash
python3 scripts/osc_smoke_test.py --spawn-service
```

Expected:

```text
OK: /chord/input 'G:7' -> /chord/output 'C:maj7'
```

(Output chord may differ if seed or CSV changed; any valid chord string is fine.)

---

## Level 2 — Python service manual check

Start the service in one terminal:

```bash
cd python
python3 -m src.main
```

You should see log lines similar to:

```text
starting chord service protocol=v2
Loaded CSV: rows=905 sources=89 ...
OSC server listening on 127.0.0.1:9000 -> Max at 127.0.0.1:9001 model=markov
sent /status/ready model=markov
```

Leave this running. In another terminal, run the smoke test **without** `--spawn-service`:

```bash
cd python
python3 scripts/osc_smoke_test.py
```

### Test LSTM from the command line

With the service still running, stop it (Ctrl+C) and restart with LSTM:

```bash
CHORD_MODEL=lstm python3 -m src.main
```

First LSTM request loads the checkpoint (~2–5 s). Then run:

```bash
python3 scripts/osc_smoke_test.py
```

You should still get `OK: /chord/input 'G:7' -> /chord/output '...'`.

---

## Level 3 — Max patch manual checklist

Open [`max/chord_generator_device.maxpat`](../max/chord_generator_device.maxpat) in Max.

Ensure Python is running (`python3 -m src.main` from `python/`).

| Step | Action | Expected result |
|---|---|---|
| 1 | Click **npm install** (first time only) | Max console shows npm finished without errors |
| 2 | Click **ping** | **status** shows `ready` |
| 3 | **active model** shows `markov` | Matches Python log `model=markov` |
| 4 | Select **C:maj7** (or another chord) from menu, click **send** | **output** shows a chord (e.g. `G:7` or `C:maj`) |
| 5 | Select **rnn** in model menu | **active model** updates to `rnn` (may take a few seconds first time) |
| 6 | Click **send** with `G:7` selected | **output** updates to a valid chord |
| 7 | Select **lstm** in model menu | **active model** updates to `lstm` |
| 8 | Try `D:min7`, `A-:7`, `F:maj7` from chord menu | Each send returns a chord in **output** |
| 9 | Click **reload** | Status stays `ready`; Markov CSV reloaded |

### Chords to try

These are in the JazzNet vocabulary and used in the automated test suite:

```text
G:7   C:maj   C:maj7   D:min7   A:min7   F:maj7
E:7   A:7     D:7      B:min7   A-:7     F:min7   G:min7
```

### Expected behavior (important)

- **Markov** usually returns a *different* chord with weighted randomness (e.g. `G:7` → `C:maj` or `C:maj7`).
- **RNN/LSTM** often return the **same** chord as the input for common symbols — the model assigns ~99% probability to the input token. That is normal for these checkpoints; it still confirms the model is loaded and responding.
- First switch to **rnn** or **lstm** may take a few seconds while torch loads the checkpoint. If you see `reply timeout`, wait for **active model** to update, then send again.
- Pick chords from the **chord** menu (12 common symbols). Default selection is `C:maj7`.

---

## Level 4 — Compare backends side by side

With Python running and Max connected:

1. Set model to **markov**, send `G:7` — note **output**.
2. Set model to **rnn**, send `G:7` — note **output**.
3. Set model to **lstm**, send `G:7` — note **output**.

All three should respond without **error**. Outputs may match or differ depending on the model.

For deterministic Markov output (useful when comparing runs):

```bash
MARKOV_SEED=42 python3 -m src.main
```

---

## Troubleshooting

| Symptom | What to check |
|---|---|
| `pytest` neural tests skipped | Run `python3 scripts/fetch_jazznet_assets.py` |
| `ModuleNotFoundError: torch` | `python3 -m pip install -r requirements.txt` from `python/` |
| Max status stays `waiting` | Start Python service; click **ping** |
| `node-osc missing` | Run `npm install` in `max/` or click **npm install** in patch |
| `reply timeout` | Python not running; or first RNN/LSTM load still in progress — wait and retry |
| `failed to load lstm` / `RNN engine unavailable` | Checkpoints missing — re-run fetch script |
| Port already in use | Stop other Python service on 9000: `lsof -i :9000` |
| Unknown chord / echo on `X:???` | Expected — fallback returns input unchanged and shows **error** |
| After editing `markov_osc.js` | Click **restart js** in the patch |

### Confirm Python alone (bypass Max)

```bash
cd python
python3 scripts/osc_smoke_test.py --spawn-service
python3 -m pytest -q
```

If these pass but Max fails, the issue is in the Max/npm layer — see [max/README.md](../max/README.md).

---

## Configuration reference

Colleagues rarely need to change defaults. Full list:

| Setting | Env var | Default |
|---|---|---|
| Active model | `CHORD_MODEL` | `markov` |
| JazzNet data | `JAZZNET_DIR` | `data/jazznet` |
| Python listen port | `MARKOV_PORT` | `9000` |
| Max reply port | `MARKOV_MAX_PORT` | `9001` |
| Random seed | `MARKOV_SEED` | unset |

See [README.md](../README.md) for CLI flags and fallback policies.

---

## Further reading

| Document | Contents |
|---|---|
| [README.md](../README.md) | Project overview and configuration |
| [max/README.md](../max/README.md) | Max patch controls and npm setup |
| [PLAN.md](../PLAN.md) | Full architecture and OSC contract |
| [osc_contract.md](osc_contract.md) | OSC address quick reference |
