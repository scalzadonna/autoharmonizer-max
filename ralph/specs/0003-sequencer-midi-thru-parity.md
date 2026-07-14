# Spec 0003 — Gated MIDI thru on the sequencer (generator parity)

Status: TODO
Priority: 3
Depends on: 0001 (sequencer maxpat on `ralph/build`); do 0002 first so the engine
is regression-guarded before touching the device.

## Context
The generator device has a **gated `midiin -> midiout` passthrough** (a "thru"
toggle, default on) so a played note is heard alongside the generated harmony.
The sequencer device (`max/chord_sequencer_device.maxpat`) has **no `midiin` and
no thru**, so you cannot play along with it. Add the same gated passthrough for
parity. This is a **pure Max-patch wiring change** — `markov_osc.js` is NOT
touched (do not add a seed-from-MIDI path here; thru only).

Mirror the reference implementation already in
`max/chord_generator_device.maxpat`: `midiin -> thru-gate (gate) -> midiout`, with
a `thru` toggle feeding the gate's control inlet, defaulted on via `loadmess 1`.

## Requirements
1. Add a gated `midiin -> midiout` passthrough to the sequencer patch.
2. A `thru` toggle (default ON) enables/disables it, exposed in Presentation.
3. No change to `markov_osc.js`; generator patch untouched; device still builds.

## Tasks
- Edit `max/chord_sequencer_device.maxpat`: add `midiin`, a `gate` (thru-gate),
  and route `midiin -> gate -> midiout` (reuse the existing `midiout`). Add a
  `thru` toggle whose output feeds the gate's left (control) inlet, with
  `loadmess 1` so it defaults ON. Place the toggle + a "thru" label in
  Presentation near the other controls.
- Keep the JSON valid and Max-loadable (well-formed boxes/lines, unique ids).
- Rebuild: `cd max && node build_amxd.js chord_sequencer_device.maxpat "Chord Sequencer Device.amxd" mmmm`.

## Acceptance Criteria
(Verify structurally by parsing the maxpat JSON — e.g. a short `node`/`python`
script that loads `max/chord_sequencer_device.maxpat` and checks the boxes/lines.)
- [ ] The patch contains at least one `midiin` and one `midiout`, with patchlines
      `midiin -> gate` and `gate -> midiout` (the thru chain).
- [ ] A `toggle` feeds the gate's control inlet (inlet 0) and is defaulted ON via
      a `loadmess 1` (or `live.toggle` with init 1); the toggle is in Presentation
      with a visible "thru" label.
- [ ] `git diff max-markov -- max/markov_osc.js` shows NO change from this spec
      beyond what 0001/0002 committed (thru is patch-only).
- [ ] Generator patch untouched: `git diff max-markov -- max/chord_generator_device.maxpat`
      is empty.
- [ ] `node build_amxd.js chord_sequencer_device.maxpat "Chord Sequencer Device.amxd" mmmm`
      succeeds and still reports `params: Rhythm, Major, Minor, Seventh`.
- [ ] `cd max && npm test` still exits 0 (no regression).
- [ ] Committed on `ralph/build`; branch pushed.

## Not in scope / human-only
- Confirming you actually HEAR the dry played note alongside the sequence in
  Ableton (audio hop — human check). Do not gate DONE on it; note it in history.

Print `<promise>DONE</promise>` only when every headless checkbox is verified.
