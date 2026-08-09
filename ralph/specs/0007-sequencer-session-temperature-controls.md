# Spec 0007 — Surface session + temperature (Spice) controls on the Sequencer device

Status: TODO
Priority: 7
Depends on: 0006 (the sequencer's `obj-route` gained a `model` outlet; this spec
appends a `session` outlet after it). Mirrors the Generator, which already ships
both controls.

## Context
Both the **session** and **temperature** surfaces already exist end-to-end in the
v3 backend + shared bridge — the **Generator** device exposes them, the
**Sequencer** does not:

- **Session** — `/control/session` (string `auto | stateless | session | reset`) →
  `registry.set_session_mode`; `/status/session` (mode, step) comes back. The
  bridge already has `session` and `reset_session` handlers. Generator UI:
  `obj-session-menu` (umenu `auto, stateless, session`) → `obj-prepend-session
  (prepend session) → obj-node`; `obj-btn-reset-session` → `obj-msg-reset-session
  (message "reset_session") → obj-node`; readout `obj-session-display` ←
  `obj-route`'s `session` outlet.
- **Temperature == Spice** — per `docs/osc_contract.md`, `/control/spice` is the
  **live sampling temperature** (`temperature = 3 ** (value − 0.5)`) applied to
  Markov **and** the neural engines; `0.5` is neutral. The Generator surfaces it
  as `obj-dial-spice` (`live.dial`) → `obj-prepend-spice (prepend spice) →
  obj-node`. (`neural_temperature` in `config.py` is only the startup default;
  the live control is Spice. A *separate* neural-only temperature OSC is **not**
  in scope — see below.)

The Sequencer currently has **no session menu, no reset, no session readout, and
no Spice/temperature dial**. Add them for parity. Everything needed already
exists on the wire, so this is a **Max-patch-only** change.

## Requirements
1. **Session** on the Sequencer:
   - A `umenu` (items `auto, stateless, session`) wired `→ prepend session →
     obj-node`.
   - A "reset session" `textbutton` → a `reset_session` `message` → `obj-node`.
   - A session readout `message`, driven by a **new `session` outlet on
     `obj-route`** (append `session` after the existing `model` match arg).
2. **Temperature (Spice)** on the Sequencer:
   - A `live.dial` (`parameter_enable 1`) wired `→ prepend spice → obj-node`, with
     a "SPICE · temperature" label. (This is the live temperature per the contract.)
3. Panel still fits: every `presentation:1` box has `x + w ≤ 640`, no interactive
   overlap. Recommended: a **new right-hand column at x ≈ 510–636** (the sequencer
   currently ends at 496, leaving room within the M4L width).
4. **No protocol / bridge / generator / backend change:** `markov_osc.js`,
   `max/chord_generator_device.maxpat`, and `python/src` are byte-for-byte
   unchanged (all OSC + bridge handlers already exist).

## Tasks
- Edit `max/chord_sequencer_device.maxpat` (Presentation + patching), mirroring the
  generator's objects with `obj-seq-*` ids:
  - `obj-seq-session-menu` (`umenu`, items `["auto", ",", "stateless", ",",
    "session"]`) + `obj-seq-prepend-session` (`prepend session`); wire
    `menu[1] → prepend[0] → obj-node[0]`.
  - `obj-seq-btn-reset-session` (`textbutton "reset session"`) +
    `obj-seq-msg-reset-session` (`message "reset_session"`); wire
    `button[0] → msg[0] → obj-node[0]`.
  - `obj-seq-dial-spice` (`live.dial`, `parameter_enable 1`) +
    `obj-seq-prepend-spice` (`prepend spice`); wire `dial[0] → prepend[0] →
    obj-node[0]`. Add a `SPICE · temperature` comment label.
  - `obj-seq-session-disp` (`message "set stateless 0"`) + a "session" label.
  - **Extend `obj-route`:** append `session` to the END of its match args
    (`route … model session`), bump `numoutlets`/`outlettype`, and wire the new
    `session` outlet → `obj-seq-session-disp`. Existing outlets (incl. `model` at
    index 8) keep their indices; only the unused unmatched outlet shifts.
  - Place the new controls in the free right column so the panel stays `≤ 640`.
  - Keep JSON valid + Max-loadable (unique ids, well-formed boxes/lines).
- Rebuild: `cd max && node build_amxd.js chord_sequencer_device.maxpat "Chord Sequencer Device.amxd" mmmm`.

## Acceptance Criteria
(Verify structurally by parsing `max/chord_sequencer_device.maxpat` — a short
`node`/`python` script that checks boxes/lines, as in 0005/0006. Show it + output.)
- [ ] **Session menu:** a `umenu` with items `auto, stateless, session` and
      `presentation:1`; path `<menu>[1] → <prepend session> → obj-node`.
- [ ] **Reset:** a `textbutton` (Presentation) → a `message` whose text is exactly
      `reset_session` → `obj-node`.
- [ ] **Session readout:** `obj-route` text contains `session`; `numoutlets` =
      match-arg count + 1; the `session` outlet wires to a `presentation:1`
      `message` readout.
- [ ] **Spice/temperature dial:** a `live.dial` (`parameter_enable 1`,
      `presentation:1`) → `<prepend spice> → obj-node`, with a visible label.
- [ ] **Fits + no overlap:** every `presentation:1` box has `x + w ≤ 640` (report
      the max right edge); no interactive-control overlap (>6px²).
- [ ] **No collateral change:** `git diff max-markov` for `max/markov_osc.js`,
      `max/chord_generator_device.maxpat`, and `python/src` are all empty; only the
      sequencer maxpat (+ rebuilt `.amxd`) changed.
- [ ] `node build_amxd.js chord_sequencer_device.maxpat "Chord Sequencer Device.amxd" mmmm`
      succeeds and still reports the sequencer's params.
- [ ] `cd max && npm test` exits 0 and
      `cd python && /opt/anaconda3/bin/python3 -m pytest -q` passes (no regressions).
- [ ] Committed on `ralph/build`; branch pushed.

## Not in scope / human-only
- **A separate live neural-temperature OSC** decoupled from Spice — Spice already
  IS the live temperature (markov + neural). A dedicated `/control/temperature`
  would be a **backend/protocol** spec (new address + handler + registry setter +
  bridge + docs), not this UI-only one. Only do that if explicitly wanted.
- `session_max_steps` / `session_auto_feed` / `neural_exclude_input` knobs —
  currently startup-only (CLI/env); surfacing them would also need backend OSC.
- Generator device (already has session + Spice) — untouched.
- **Ableton check** — actually hearing session continuity / temperature change from
  the sequencer panel is a human hop; do NOT gate DONE on it, note in
  `ralph/ralph_history.txt`.

Print `<promise>DONE</promise>` only when every headless checkbox is verified.
