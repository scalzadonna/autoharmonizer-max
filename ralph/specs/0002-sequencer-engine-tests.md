# Spec 0002 — Committed unit tests for the sequencer engine

Status: COMPLETE
Priority: 2
Depends on: 0001 (needs the unified `markov_osc.js` on `ralph/build`).

## Context
`markov_osc.js` is now shared by both devices and carries the sequencer engine
(templates, rhythm density sweep, on-beat hold, `player` clock) alongside the v3
protocol. That merge was validated once during development but has **no committed
regression test**. Lock the behavior in so future edits can't silently break the
generator or the sequencer.

The engine can be tested headlessly by stubbing `max-api` and `node-osc` (they
only exist inside Max at runtime), loading the real `markov_osc.js`, capturing
its `Max.addHandler` handlers + `Max.outlet` calls + OSC client sends, and
driving them. `chord_parser.js` runs for real (pure JS).

## Requirements
1. Add a committed, self-contained test for the sequencer engine, no external
   framework, exiting non-zero on any failure.
2. `npm test` runs it alongside the parser tests, all green.

## Tasks
- Create `max/markov_osc.test.js`:
  - Override module resolution so `require("max-api")` returns a stub
    (`addHandler`/`outlet`/`post`) and `require("node-osc")` returns stub
    `Client` (records `.send(...)`) + `Server` (captures the `message` callback).
  - `require` the real `max/markov_osc.js`; boot it via the `init` handler.
- Assert at minimum:
  - **Generator-immediate**: a `/chord/output` reply while NOT playing emits
    `["notes", …]` immediately (3-note triad) and `["output", …]`.
  - **Sequencer-hold**: after `play 1`, a `/chord/output` reply emits NO `notes`
    (held); the next `beat` (an onset) emits the triad.
  - **Density gating**: over 8 beats, `rhythm 1` (four_quarters) sonifies every
    beat (8); `rhythm 0` (static_2bar) sonifies ≤ 2 — and dense > sparse.
  - **Rhythm dial mapping**: `rhythm 0` → `["rhythmname","static_2bar"]`,
    `rhythm 1` → `["rhythmname","four_quarters"]`.
  - **Downbeat-quantized sweep**: a `rhythm` change queued mid-bar does NOT alter
    onsets until the next `beat` where `beat % 4 === 0`.
  - **v3 protocol intact**: `spice 0.7` → client send `/control/spice 0.7`;
    `model rnn` → `/control/model rnn`; `reset_session` → `/control/session reset`.
- Update `max/package.json`:
  `"test": "node chord_parser.test.js && node markov_osc.test.js"`.

## Acceptance Criteria
- [x] `max/markov_osc.test.js` exists, self-contained (stubs `max-api`+`node-osc`,
      no external test framework), exits non-zero on failure.
- [x] `node --check max/markov_osc.test.js` passes.
- [x] `cd max && npm test` runs BOTH suites and exits 0; report the counts.
- [x] The engine test covers all six behaviors listed above.
- [x] Committed on `ralph/build`; branch pushed.

Print `<promise>DONE</promise>` only when every checkbox is verified.
