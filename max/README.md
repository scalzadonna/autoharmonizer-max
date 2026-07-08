# Chord Markov Max Device (protocol v1) — triad sonification

Standalone Max/MSP patch that sends chord symbols to the Python Markov OSC
service, **displays the sampled reply, parses it into MIDI, and plays it** as a
**major or minor triad** through an Ableton instrument placed after the device.

Uses **Node for Max** (`node.script` + `node-osc`) — **CNMAT externals are not required**.

## Signal flow

```
user enters chord → Max → Node → Python(Markov) → returns chord symbol
  → Node displays it, parses it, voices it as a MAJOR/MINOR TRIAD
  → Node emits a MIDI note list → makenote → flush → midiformat → midiout
  → Ableton instrument after the device makes sound
```

**Project constraint:** only **major or minor triads** are sonified. The parser
still fully understands the returned symbol (`Cmaj7`, `E:hdim7`, `Dm7b5`, …) and
`chord` still shows that full symbol; the `notes` are the reduced triad. The
third decides quality (major 3rd → major triad, minor 3rd → minor triad, no
third → major). Toggle with the **triads only** switch in the patch.

## Requirements

- Max 8+ with Node for Max (included in standard Max 8 installs)
- Python service running locally (see below)
- One-time npm install from inside the patch (see Quick start)

## Quick start

### 1. Start Python

From the repo root:

```bash
cd python
python3 -m pip install -r requirements.txt
python3 -m src.main
```

### 2. Open the patch

Open `chord_markov_device.maxpat` in Max.

### 3. Install npm dependencies (first time only)

Click **npm install** in the patch. Wait until the Max console shows npm finished (may take ~30 seconds).

Alternatively, from a terminal:

```bash
cd max
npm install
```

### 4. Ping and send

1. Click **ping** — status should show `ready` when Python replies.
2. Enter a chord (e.g. `G:7`) in the text box and press **Enter** (or click **send**).
3. The sampled next chord appears in **output** and **predicted chord**, the
   voiced triad appears in **MIDI notes**, and the chord plays through the
   instrument after this device.

Click **reload** to reload the CSV without restarting Python.

### 5. Test the parser without Python

The **TEST PARSER** section (message boxes `testparse Cmaj7`, `testparse Dm7`,
`testparse N.C.`, and a text box) parses, voices, and plays a chord **directly**,
bypassing the Markov/Python path — useful for checking MIDI output on its own.
This never replaces the real Markov path.

## Chord parsing (`chord_parser.js`)

A dependency-free module (also runnable under plain `node`). It normalizes the
symbol (`♭`→`b`, `♯`→`#`, strips quotes/whitespace/newlines), parses the root +
quality (jazz notation *and* colon-dataset notation `C:maj7`), builds pitch
classes from interval patterns, and voices the chord.

- **Voicing:** close-position triad in the C3–C5 register; a slash bass (e.g.
  `Cmaj7/G`) is placed one octave below the triad.
- **Voice leading:** an optional nearest-voicing mode keeps successive triads
  close together (deterministic, register-bounded).
- **No chord:** `N.C.` / `NC` / `no_chord` → silence (emits `stop`, no notes).
- **Errors:** unknown symbols emit `error <code> <symbol>` and **no** MIDI.

Run the parser tests: `npm test` (from this folder).

## Default ports

| Role | Host | Port |
|---|---|---|
| Python listen | `127.0.0.1` | `9000` |
| Max listen | `127.0.0.1` | `9001` |

Ports are set in `markov_osc.js`. Change them there if you use non-default Python ports.

## Controls

| UI | Action |
|---|---|
| **npm install** | Runs `script npm install` to fetch `node-osc` (first time only) |
| **ping** | Sends `/control/ping` |
| **send** / **Enter** | Sends `/chord/input` with the text field value |
| **reload** | Sends `/control/reload` |
| status | Shows `ready` or `waiting` |
| output | Last `/chord/output` chord symbol (raw, for the rest of the system) |
| predicted chord | Normalized returned symbol (e.g. `Cmaj7`) |
| MIDI notes | Voiced triad note list (e.g. `48 52 55`) |
| velocity / duration ms | `makenote` note velocity (default 90) and length (default 1000 ms) |
| register center | Voicing register centre sent to Node (default 60 ≈ C4) |
| voice leading | Nearest-voicing on/off (default ON in Node) |
| triads only | Reduce to major/minor triad on/off (default ON in Node) |
| panic | All notes off |

## Node → Max message protocol

`markov_osc.js` emits these to the `route` object (backward-compatible):

| Message | Meaning |
|---|---|
| `status <word>` | `ready` / `waiting` |
| `output <symbol>` | raw Markov reply (unchanged — feeds `out s`) |
| `error <code> [detail]` | passthrough / parser error (e.g. `error unsupported_modifier C7add#15`) |
| `chord <symbol>` | normalized returned symbol for display |
| `notes <midi ...>` | playable triad MIDI note list |
| `stop` | silence held notes (N.C. / panic) |

The OSC protocol to/from **Python is unchanged (v1)**.

## Sequencer device (`Chord Markov Sequencer.amxd`)

A separate device with a **usable Max for Live presentation UI** that **plays
along the Markov chain automatically** for a set length, using harmonic-rhythm
templates.

How it works: each chord slot plays the current chord (as a triad) and feeds it
back into `/chord/input`; the Markov reply becomes the **next** slot's chord
(output → input). The device runs on **its own quarter-note clock** — an
ms-based `metro` driven by the **tempo (BPM)** control — so it plays as soon as
you press **PLAY**, with **no need to start Live's transport**. Chords change at
the template's slot onsets and sustain until the next; after the set number of
bars it stops and flushes all notes.

**Presentation controls:** `seed` chord + **send**, **PLAY** toggle, a **rhythm**
dropdown (the 7 templates below), **tempo (BPM)** (default 120), **length**
(bars, default 4), three **colour** `live.dial`s, a **sync** toggle, plus
`chord` / `notes` / `status` displays.

**Performable colour knobs** (`live.dial`s — registered parameters, so you can
map them to rack **macros**): each is a per-chord probability 0–100 %.

| Dial | Effect |
|---|---|
| **Major** | chance of forcing the chord to a **major** triad |
| **Minor** | chance of forcing it to a **minor** triad (Major wins ties) |
| **7th** | chance of adding a **flat-7th** (major→dom7, minor→min7) |

All three at 0 = the natural major/minor triad. The colour is applied to the
Markov-returned chord in Node (`colormajor` / `colorminor` / `color7th`
messages), so it works in real time as you turn the knobs.

**Sync toggle:** off (default) = free-running ms clock at the **BPM** knob; on =
the clock **links to Live's global transport** (a transport-locked `metro 4n`
that follows Live's tempo and plays only while the transport is running).

**Harmonic-rhythm templates** (slot onsets in beats, 4/4):

| # | name | span | chords change on beats |
|---|---|---|---|
| 1 | whole_bar | 1 bar | 0 |
| 2 | half_half | 1 bar | 0, 2 |
| 3 | four_quarters | 1 bar | 0, 1, 2, 3 |
| 4 | half_qtr_qtr | 1 bar | 0, 2, 3 |
| 5 | qtr_qtr_half | 1 bar | 0, 1, 2 |
| 6 | qtr_half_qtr | 1 bar | 0, 1, 3 |
| 7 | static_2bar | 2 bars | 0 |

**Use:** start Python; add the device to a MIDI track with an instrument after
it; type a seed chord + **send**; pick a **rhythm**, **tempo**, and **length**;
press **PLAY** (Live's transport does not need to be running). The **rhythm**
dropdown is populated on load and defaults to `four_quarters`.

> Python must be running for the chain to advance. Without it, PLAY still runs
> the clock but the seed chord simply repeats at the chosen rhythm.

Node messages: `play 1|0`, `beat` (quarter-note clock), `template <1-7>`,
`length <bars>`, `seed <chord>` in; `playoff` out (stops the clock when the
length completes).

## MIDI input from Ableton

The device also listens to the track's incoming MIDI. Play a note (keyboard or
clip) and it **seeds the Markov chain**: the note's pitch class becomes a
major-triad root symbol (e.g. C4 → `C:maj`, F#3 → `F#:maj`), which is sent to
Python exactly like a typed chord — so the sonified triad is the chord the
Markov system returns, not the raw note. Note-offs are ignored.

Chain: `midiin → midiparse → unpack → stripnote → gate → prepend notein → node`.
The **enable MIDI in** toggle (on by default) gates it; a M4L MIDI effect does
not pass raw MIDI through, so played notes are replaced by the generated triad.

## Max for Live device (`.amxd`)

`Chord Markov Device.amxd` is the same patch wrapped as a **Max MIDI Effect**
(device type `mmmm`) — drop it on a MIDI track **before an instrument** and the
generated triads play through that instrument.

**Important — keep the device next to its scripts.** The device loads
`markov_osc.js` (which requires `chord_parser.js` and `node_modules/node-osc`)
by relative path, so the `.amxd` must live in **this `max/` folder** with those
files. Two ways to deploy:

1. **In place (dev):** in Max, *Options → File Preferences* → add this `max/`
   folder to the search path, then drag `Chord Markov Device.amxd` onto a MIDI
   track. First run: click **npm install**, then **ping**.
2. **Frozen (portable):** open the device in the Max editor and click the
   **freeze** (snowflake) button. Freezing embeds `markov_osc.js`,
   `chord_parser.js` and `node_modules` into the `.amxd` so it can be moved
   anywhere. (Freezing must be done from Max — it can't be scripted.)

Regenerate the `.amxd` after editing the patch:

```bash
node build_amxd.js   # wraps chord_markov_device.maxpat -> Chord Markov Device.amxd
```

## Files in this folder

| File | Purpose |
|---|---|
| `Chord Markov Device.amxd` | Max for Live MIDI-Effect device (wraps the patch) |
| `chord_markov_device.maxpat` | Max UI: OSC bridge + displays + MIDI branch |
| `markov_osc.js` | Node-for-Max OSC client/server + voicing/sonification glue |
| `chord_parser.js` | Pure-JS chord symbol parser + triad voicing engine |
| `chord_parser.test.js` | Parser/voicing test suite (`npm test`) |
| `build_amxd.js` | Wraps the `.maxpat` into the `.amxd` device |
| `package.json` | npm dependency on `node-osc`; `test` script |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `node-osc missing` error | Click **npm install** and wait for it to finish |
| Status stays `waiting` | Start Python (`python3 -m src.main` from `python/`) |
| `reply timeout` | Python not running, wrong port, or firewall blocking localhost UDP |
| `node.script` errors on load | Confirm Node for Max is enabled in Max 8 |

Run the Python smoke test without Max:

```bash
cd python
python3 scripts/osc_smoke_test.py --spawn-service
```

## OSC addresses

See [PLAN.md](../PLAN.md) and [docs/osc_contract.md](../docs/osc_contract.md).
