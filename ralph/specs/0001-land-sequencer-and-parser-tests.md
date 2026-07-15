# Spec 0001 — Land the Chord Sequencer device + parser unit tests

Status: COMPLETE
Priority: 1

## Context
The Chord Sequencer device was folded onto the v3 line but is currently
**uncommitted** on the default branch (`max-markov`). Working-tree files:
- `max/markov_osc.js`                   (modified — unified generator + sequencer bridge)
- `max/README.md`                       (modified — sequencer section)
- `max/chord_sequencer_device.maxpat`   (new)
- `max/Chord Sequencer Device.amxd`     (new)
- `data/harmonic_templates.csv`         (new — reference data)

The Ralph harness itself (`ralph/`) and a `.gitignore` change (`ralph/logs/`) are
also uncommitted; land them too so the tree ends clean (see Tasks).

The repo has no automated test for `chord_parser.js`. A self-contained one exists
on branch `max-markov-2` at `max/chord_parser.test.js` (61 assertions, no
framework, run via `node chord_parser.test.js`). The repo's `chord_parser.js` is
a **superset** of the `max-markov-2` version, so the tests should port cleanly —
but verify, and fix (do not weaken) any assertion that relied on
`max-markov-2`-only behavior.

## Requirements
1. Land the uncommitted Sequencer work on a dedicated branch off `max-markov`.
2. Add `chord_parser` unit-test coverage to the repo with a one-command runner.
3. All tests green; the generator device stays untouched.

## Tasks
- Switch to `ralph/build` (create it off `max-markov` if it doesn't exist yet;
  never commit to `max-markov` directly).
- Commit the five working-tree files above (clear message + Co-Authored-By).
- Port `max/chord_parser.test.js` from branch `max-markov-2` into `max/`, running
  it against the REPO's current `chord_parser.js`. Fix any breakage without
  weakening real assertions.
- Ensure `max/package.json` has `"scripts": { "test": "node chord_parser.test.js" }`.
- Confirm the shared bridge is intact: `node --check max/markov_osc.js`, and an
  equivalent headless check that the generator path still sonifies immediately
  (a stubbed `max-api`/`node-osc` harness is acceptable).
- Commit the Ralph harness (`ralph/`) and the `.gitignore` change as a SEPARATE
  commit on the same branch (do this last, after marking this spec COMPLETE), so
  the working tree ends clean. `ralph/logs/` stays gitignored.

## Acceptance Criteria
- [x] Current branch is `ralph/build` (`git rev-parse --abbrev-ref HEAD`).
- [x] `git status --porcelain` is clean — all five files committed.
- [x] `cd max && npm test` exits 0; report the passed/failed assertion counts.
- [x] `node --check max/markov_osc.js` passes.
- [x] `cd max && node build_amxd.js chord_sequencer_device.maxpat "Chord Sequencer Device.amxd" mmmm`
      succeeds and reports `params: Rhythm, Major, Minor, Seventh`.
- [x] Generator patch untouched: `git diff max-markov -- max/chord_generator_device.maxpat`
      is empty.
- [x] Branch `ralph/build` pushed to `origin`.

## Not in scope / human-only
- Confirming the device makes sound in Ableton (audio hop — not headlessly
  verifiable; a human must check). Do not gate DONE on it.

Print `<promise>DONE</promise>` only when every checkbox above is verified.
