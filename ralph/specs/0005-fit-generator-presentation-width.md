# Spec 0005 — Fit the Generator device panel to the Max-for-Live width (page it if needed)

Status: TODO
Priority: 5
Depends on: nothing new (generator device already exists; 0001–0004 complete).

## Context
`max/chord_generator_device.maxpat` opens in Presentation, but its presentation
content runs to **x ≈ 740px**, ~100px past the practical Max-for-Live device
width (~640px), so the panel does **not** fully fit inside Ableton's device
chain — the right edge (status / model / session / output / error readouts) is
clipped in the live-performance view. The sequencer device already fits
(extent ≈ 496px), so this spec is generator-only.

The overflow comes from a handful of **over-wide display message boxes** stacked
on the right, not from too many controls:
- `obj-output`, `obj-error` — `x=400, w=340` → right edge **740**
- `obj-status`, `obj-model-display`, `obj-session-display` — `x=470, w=270` → **740**

The **model selector must stay reachable** in the fitted panel: `obj-model-menu`
(a `umenu` with items `markov , rnn , lstm`) wired `→ obj-prepend-model
(prepend model) → node.script`, with the backend's `/status/model` confirmation
arriving through `obj-route` (`route status output error model session …`) into
`obj-model-display`. This is the "access the model we trained in Python" path and
must not regress.

Prefer the **smallest** change that fits: narrow / re-wrap / re-row the wide
readouts so everything lands within the width on a single page. Add a paged
`live.tab` **only if** the controls genuinely cannot sit legibly on one page.

## Requirements
1. Every Presentation object in the generator patch fits the width: for each box
   with `presentation:1`, `presentation_rect.x + presentation_rect.w ≤ 640`.
   Keep the panel compact vertically too (target `y + h ≤ 340`).
2. The model selector stays in Presentation and stays wired end-to-end
   (`umenu` → `prepend model` → node; `route … model …` → active-model readout),
   so `/control/model` + `/status/model` still work.
3. No interactive Presentation controls overlap (umenu / live.dial / live.* /
   toggle / number / textbutton / message readouts).
4. If — and only if — a single page cannot hold the controls legibly, add a
   `live.tab` (or equivalent) page selector: its outlet drives show/hide of the
   page groups, it defaults (loadbang or `parameter_initial`) to the page holding
   the **model selector + chord selector + output**, and the switch is wired so
   exactly one page shows at a time.
5. **No protocol / behavior change.** `markov_osc.js` and the Python backend are
   untouched; the generator still sonifies immediately (it never sends `play`).
6. Sequencer device (`chord_sequencer_device.maxpat`) is not modified by this spec.

## Tasks
- Edit `max/chord_generator_device.maxpat` Presentation rects only (leave the
  patching-view wiring / patchlines intact):
  - Narrow `obj-output` / `obj-error` (w 340 → ≤ ~200) and `obj-status` /
    `obj-model-display` / `obj-session-display` (w 270 → ≤ ~150), and/or re-row
    them, so the max right edge is ≤ 640. Keep every readout legible.
  - Keep `obj-model-menu` + its "model" / "active model" labels visible.
- Only if still too tight: add a `live.tab` + show/hide wiring (e.g. `thispatcher`
  `script hide/show <scriptingname>` per box, or per-object `hidden` messages),
  giving each paged box a scripting name; default to the model-selector page.
- Rebuild: `cd max && node build_amxd.js chord_generator_device.maxpat "Chord Generator Device.amxd" mmmm`.

## Acceptance Criteria
(Verify structurally by parsing the maxpat JSON — a short `node`/`python` script
that loads `max/chord_generator_device.maxpat` and inspects boxes/lines. Show the
script and its passing output, mirroring 0002/0003.)
- [ ] **Width fits:** every box with `presentation:1` has `x + w ≤ 640`
      (report the current max right edge; it must be ≤ 640, down from 740). Panel
      height stays compact (`y + h ≤ 340` for every presentation box).
- [ ] **Model selector intact:** `obj-model-menu` is `umenu` with items
      `markov, rnn, lstm` and `presentation:1`; a patchline path
      `obj-model-menu → obj-prepend-model (prepend model) → node` exists; and
      `obj-route` still routes a `model` outlet into the active-model display.
      Prove by parsing boxes + lines.
- [ ] **No overlap:** no two interactive Presentation controls overlap by more
      than ~6px² (show the pairwise overlap check; empty result).
- [ ] **Paging (conditional):** if a `live.tab` was added, it is in Presentation,
      its outlet is wired to the page-group show/hide, and an initial selection
      shows the model-selector page. If a single page fits, state "single page —
      no tab needed" explicitly instead.
- [ ] **No protocol drift:** `git diff max-markov -- max/markov_osc.js` and
      `git diff max-markov -- python/src` show NO change from this spec.
- [ ] `node build_amxd.js chord_generator_device.maxpat "Chord Generator Device.amxd" mmmm`
      succeeds and still reports the generator's params.
- [ ] `cd max && npm test` exits 0 and
      `cd python && /opt/anaconda3/bin/python3 -m pytest -q` passes (no regressions).
- [ ] Committed on `ralph/build`; branch pushed.

## Not in scope / human-only
- **Ableton visual check** — confirming the panel actually sits fully inside the
  device slot (and that pages switch) in Live is a human hop; do NOT gate DONE on
  it, note it in `ralph/ralph_history.txt`.
- Sequencer device layout (already fits ≈ 496px) — optional later spec.
- Providing / placing the `rnn`/`lstm` `.pt` checkpoints — a separate concern;
  `markov` works today and the selector wiring is model-agnostic.

Print `<promise>DONE</promise>` only when every headless checkbox is verified.
