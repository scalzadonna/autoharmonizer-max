# Chord Generator Max Device (protocol v3)

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
5. For **rnn** / **lstm**, session mode is **auto** by default — send several chords and watch **session step** increment. Use **reset session** to clear hidden state.
6. Turn **Rhythm** above 0 to auto-advance the chain hands-free; turn **Spice** up for rarer, more surprising chords (down for safe/common). Both are macro-mappable.
7. Click **reload** to reload the Markov CSV without restarting Python.
8. After updating `markov_osc.js`, click **restart js**.

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
| **session** (umenu) | Sends `/control/session` with `auto`, `stateless`, or `session` |
| **reset session** | Sends `/control/session reset` |
| **npm install** | Runs `script npm install` to fetch `node-osc` (first time only) |
| **ping** | Sends `/control/ping` |
| **chord** (umenu) | Select input chord (default `C:maj7`) |
| **send** | Sends `/chord/input` with the selected chord |
| **reload** | Sends `/control/reload` (Markov CSV only) |
| **restart js** | Restarts the Node bridge after JS edits |
| **Rhythm** (live.dial) | Auto-advance: `0` = off (manual). Above `0` runs an in-patch metro (~2000 ms → 250 ms) that feeds each generated chord back as the next input, walking the chain hands-free. Macro-mappable. |
| **Spice** (live.dial) | Sends `/control/spice` (`0`–`1`, `0.5` neutral). Live sampling adventurousness for Markov **and** neural: higher = rarer/surprising chords, lower = safe/common. Macro-mappable. |
| **vel** / **dur** (number) | `makenote` velocity (default 90) and note length in ms (default 1000) for the emitted MIDI. |
| **panic** | All notes off (flushes any held notes). |
| **seed from MIDI in** (toggle, default **on**) | When on, a note played into the track seeds the chain (its pitch class → a major-triad root); the generated chord sounds. |
| **thru** (toggle, default **on**) | Parallel `midiin → midiout` passthrough — your played notes also reach the instrument, so you hear the dry note **plus** the generated harmony. Turn off for replace-mode (generated triad only). |
| status | Shows `ready` or `waiting` |
| active model | Last `/status/model` from Python |
| session | Last `/status/session` (mode + step) |
| output | Last `/chord/output` chord symbol |
| error | Last `/error` or `reply timeout` (1500 ms) |

## Model switcher notes

- Default model on Python startup is **markov** unless you set `CHORD_MODEL=lstm` (etc.) before launch.
- First selection of **rnn** or **lstm** triggers checkpoint load in Python (~2–5 s). Wait for **active model** to update before sending chords.
- RNN/LSTM use **session mode by default** (`auto`): hidden state accumulates across sends; model output is auto-fed. Set session menu to **stateless** for single-step behavior.
- RNN/LSTM may return the same chord as the input when `--neural-temperature 1.0 --no-neural-exclude-input --session-mode stateless` is set; defaults avoid this.

## MIDI output

The device **plays MIDI**. When a chord comes back from Python, `markov_osc.js`
voices it with `chord_parser.js` (a close-position **major/minor triad** in the
C3–C5 register, with nearest-voicing so successive chords stay close) and emits a
`notes` list. The patch turns that into `makenote → flush → midiformat → midiout`,
so the triad plays through the **instrument placed after this device** on the
track. `N.C.` emits `stop` (silence); the previous chord is flushed before each
new one so notes don't pile up.

Trigger a chord by clicking **send** (or the chord menu), by turning **Rhythm**
up (hands-free auto-advance), or by **playing a note** into the track (seeds the
chain — see the toggle above). The **thru** toggle (default **on**) adds a
parallel `midiin → midiout` passthrough, so played notes sound **alongside** the
generated harmony; turn it off to have the generated triad **replace** your notes
(pure-generator mode).

> Node → Max messages driving this: `notes <midi…>` (play), `stop` (silence).
> These are internal patch messages, not part of the OSC contract with Python.

## Presentation panel & Max for Live device

The patch **opens in Presentation** as a compact **760×330** panel sized for
Ableton's device strip: chord / model / session menus, the transport buttons,
the **Rhythm** and **Spice** dials, a bottom **MIDI** strip (vel / dur / panic /
seed-from-MIDI-in), and the status / active-model / session / output / error
readouts. Switch to **Patching** view (⌘E) to see the wiring.

`Chord Generator Device.amxd` is the same patch wrapped as a **Max MIDI Effect**
(device type `mmmm`). Drop it on a MIDI track; **Rhythm** and **Spice** are
registered parameters, so they appear on the device's macro strip and are
MIDI-mappable.

**Keep the device next to its scripts.** The `.amxd` loads `markov_osc.js`
(which requires `chord_parser.js` and `node_modules/node-osc`) by relative path,
so it must live in this `max/` folder — or **freeze** it in the Max editor
(snowflake button) to embed the scripts for portability. This device is **not**
self-contained until frozen.

Regenerate the `.amxd` after editing the patch:

```bash
cd max
node build_amxd.js   # wraps chord_generator_device.maxpat -> Chord Generator Device.amxd
```

> Ableton caches an `.amxd` when you add it and does not reload after a rebuild
> — **delete the device from the track and drag the fresh one back in**.

## Files in this folder

| File | Purpose |
|---|---|
| `chord_generator_device.maxpat` | Max UI (Presentation panel) with model/session switcher, Rhythm/Spice dials + Node bridge |
| `Chord Generator Device.amxd` | Max for Live MIDI-Effect device (wraps the patch; Rhythm/Spice exposed as parameters) |
| `markov_osc.js` | Node-for-Max OSC client/server (v3) + chord voicing / MIDI-note emission |
| `chord_parser.js` | Pure-JS chord-symbol parser + triad voicing engine (used by `markov_osc.js`) |
| `build_amxd.js` | Wraps the `.maxpat` into the `.amxd` device (arg 3 = device type) |
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
