# autoharmonizer-max — Ralph Constitution

Guiding rules for every autonomous iteration. **Read this before acting.**

## What this project is
A Max/MSP + Max-for-Live chord device backed by a local Python OSC service.
- **Python service** (`python/`): markov + JazzNet rnn/lstm engines, protocol
  **v3**, OSC over `127.0.0.1:9000` (Python listen) / `:9001` (Max listen).
- **Max devices** (`max/`): `chord_generator_device` (single-chord generator)
  and `chord_sequencer_device` (auto-play harmonic-rhythm sequencer). Both load
  the shared Node-for-Max bridge `markov_osc.js`, which voices chords via
  `chord_parser.js` and emits MIDI (`makenote -> midiformat -> midiout`).
- Contract: `docs/osc_contract.md`. Plan: `PLAN.md`.

## Non-negotiables
1. **Do not regress the generator device.** `markov_osc.js` is shared by both
   devices; the generator must stay behaviorally identical. Sequencer behavior is
   gated on `player.active` (the generator never sends `play`). If you touch the
   bridge, prove the generator path still sonifies immediately.
2. **Protocol is v3.** Keep Python (`config.py`, `osc_service.py`) and
   `markov_osc.js` consistent with `docs/osc_contract.md`.
3. **Tests are backpressure.** Never mark a spec DONE with a failing or skipped
   test. Python: `cd python && /opt/anaconda3/bin/python3 -m pytest -q`.
   JS parser: `cd max && npm test`.
4. **Voicing lives in `chord_parser.js`** — pure, dependency-free (no `require`
   of app modules). Keep it that way.
5. **The Ableton-audio hop is NOT headlessly verifiable.** Specs must not hinge
   on it; leave any audio criterion for a human and say so explicitly. Never
   claim audio worked.

## Environment
- **Python** with pytest + pythonosc: `/opt/anaconda3/bin/python3` (system
  `python3` may lack pytest). OSC round-trip smoke:
  `python/scripts/osc_smoke_test.py --spawn-service`.
- **Node** (nvm). npm deps in `max/node_modules` (`node-osc`). Rebuild a device:
  `cd max && node build_amxd.js <patch.maxpat> "<Name>.amxd" mmmm`.
- Ports **9000/9001** must be free before running the Python service
  (`lsof -nP -iUDP:9000` to check).

## Git / workflow
- **Never commit to the default branch `max-markov`.** All Ralph work goes on a
  single integration branch **`ralph/build`**: on the first iteration create it
  off `max-markov` (`git switch -c ralph/build`); on later iterations just
  `git switch ralph/build` and commit onto it. Specs stack as commits there, so
  each spec sees the prior specs' code in the working tree.
- Commit small; one logical change per commit; message = imperative summary line
  + a short why.
- End every commit message with:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`
- Push `ralph/build` after each spec. **Do not** open PRs, merge to `max-markov`,
  force-push, delete branches, or rewrite history unless a spec explicitly says to.

## Style
- Match surrounding code: comment density, naming, idioms. No new frameworks or
  dependencies unless a spec calls for one. Touch only what the spec needs.
