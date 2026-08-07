# Spec 0006 — Add a model selector to the Sequencer device (generator parity)

Status: COMPLETE
Priority: 6
Depends on: nothing new. Mirrors the generator's model selector (shipped) and the
fitted-panel discipline from 0005.

## Context
The Chord **Generator** device exposes a model selector in Presentation
(`obj-model-menu`: a `umenu` with items `markov, rnn, lstm`) wired to the shared
bridge, so a performer can switch between the trained backends live. The
**Sequencer** device (`max/chord_sequencer_device.maxpat`) has **no model
selector** — it auto-plays the chain but is stuck on whatever model the service
last had. Add the same selector for parity.

This is a **Max-patch wiring change only.** The shared bridge already has the
`model` handler (`Max.addHandler("model", … sendOsc("/control/model", name))`)
and already emits `/status/model → outlet ["model", <name>]`; **`markov_osc.js`
is NOT touched**, and the generator patch is NOT touched. The OSC protocol is
unchanged (v3 already defines `/control/model` + `/status/model`).

Reference implementation to mirror, from `max/chord_generator_device.maxpat`:
- `obj-model-menu` `umenu` items `["markov", ",", "rnn", ",", "lstm"]`, `presentation:1`
- patchlines `obj-model-menu → obj-prepend-model (prepend model) → obj-node`
- `obj-route` carries a `model` outlet → `obj-model-display` (a `message` readout)

Current sequencer wiring facts:
- Shared node object is `obj-node` (`node.script markov_osc.js`).
- `obj-route` text is `route status output error chord notes stop playoff rhythmname`
  — it has **no `model` outlet yet**, so the `/status/model` confirmation is
  currently dropped. It must gain one to drive the readout.
- Free Presentation space: the right-hand column around **x ≈ 396–500, y ≈ 42–130**
  is open (the panel currently extends to ~496×230).

## Requirements
1. A `umenu` model selector (items `markov, rnn, lstm`) in the Sequencer's
   Presentation, with a `model` label, wired `→ prepend model → obj-node`.
2. An "active model" readout `message` in Presentation, driven by a **new `model`
   outlet on `obj-route`** (so the panel reflects the backend-confirmed model, not
   just the menu pick).
3. Panel still fits the M4L width: every `presentation:1` box has `x + w ≤ 640`
   (keep it compact — ideally within ~500–520, using the free right column).
   No interactive-control overlap.
4. **No protocol / bridge / generator change:** `markov_osc.js`,
   `max/chord_generator_device.maxpat`, and `python/src` are byte-for-byte
   unchanged by this spec.

## Tasks
- Edit `max/chord_sequencer_device.maxpat` (Presentation + patching):
  - Add `obj-seq-model-menu` (`umenu`, `items ["markov", ",", "rnn", ",", "lstm"]`,
    `parameter_enable 0`) in Presentation in the free right column (e.g.
    `presentation_rect ≈ [396, 60, 100, 22]`), plus an `obj-seq-model-label`
    comment ("model") above it.
  - Add `obj-seq-prepend-model` (`newobj`, `prepend model`), patching-only, and
    patchlines `obj-seq-model-menu → obj-seq-prepend-model → obj-node` (mirror the
    generator's middle-outlet → prepend → node path).
  - Add `obj-seq-model-disp` (`message`, `set $1`) in Presentation (e.g.
    `[396, 106, 100, 20]`) + an "active model" label.
  - **Extend `obj-route`:** append `model` to the END of its match args
    (`route … rhythmname model`) so existing outlet indices stay stable; bump
    `numoutlets`/`outlettype` to match; wire the new `model` outlet →
    `obj-seq-model-disp`. Re-index only if an existing line targeted the old
    unmatched (right-most) outlet.
  - Keep the JSON valid and Max-loadable (well-formed boxes/lines, unique ids).
- Rebuild: `cd max && node build_amxd.js chord_sequencer_device.maxpat "Chord Sequencer Device.amxd" mmmm`.

## Acceptance Criteria
(Verify structurally by parsing the maxpat JSON — a short `node`/`python` script
that loads `max/chord_sequencer_device.maxpat` and checks boxes/lines, as in
0003/0005. Show the script and its passing output.)
- [x] **Selector present:** `obj-seq-model-menu` is a `umenu` with items
      `markov, rnn, lstm` and `presentation:1`.
- [x] **Wired to the bridge:** `obj-seq-model-menu[1] → obj-seq-prepend-model
      (prepend model) → obj-node[0]` (mirrors the generator's middle-outlet path).
- [x] **Confirmation readout:** `obj-route` text is `…rhythmname model`;
      `numoutlets` = 10 = 9 matches + 1; the new `model` outlet (index 8) wires to
      `obj-seq-model-disp`, a `message` with `presentation:1`.
- [x] **Fits + no overlap:** max right edge **496** (`≤ 640`, placed in the free
      right column); pairwise interactive-overlap check returned empty.
- [x] **No collateral change:** `git diff` for `max/markov_osc.js`,
      `max/chord_generator_device.maxpat`, and `python/src` are all empty; only
      `max/chord_sequencer_device.maxpat` (+ its rebuilt `.amxd`) changed.
- [x] `node build_amxd.js chord_sequencer_device.maxpat "Chord Sequencer Device.amxd" mmmm`
      succeeds — `params: Rhythm, Major, Minor, Seventh` (117 boxes, 97 lines).
- [x] `cd max && npm test` exits 0 (466 + 22) and
      `cd python && /opt/anaconda3/bin/python3 -m pytest -q` passes (85 passed, 0 skipped).
- [x] Committed on `ralph/build`; branch pushed.

## Not in scope / human-only
- **Ableton check** — actually switching model from the sequencer panel and
  hearing the engine change is a human hop; do NOT gate DONE on it, note it in
  `ralph/ralph_history.txt`.
- No new OSC addresses, no bridge logic, no sequencer transport/phrase changes.
- Adding session/temperature controls to the sequencer panel — separate future
  spec if wanted.

Print `<promise>DONE</promise>` only when every headless checkbox is verified.
