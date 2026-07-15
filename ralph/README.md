# Ralph Wiggum harness — autoharmonizer-max

Autonomous, spec-driven build loop. Each iteration is a **fresh `claude`
process** (clean context) that picks one spec, implements it, tests, commits, and
signals done. Shared state lives on disk, so context never overflows.

## Files
| File | Purpose |
|---|---|
| `CONSTITUTION.md` | Rules every iteration must obey — read first. |
| `PROMPT.md` | The operator prompt handed to each fresh agent. |
| `specs/` | One file per feature, with acceptance criteria. Lowest number = highest priority. Header flips to `Status: COMPLETE` when done. |
| `ralph_history.txt` | Running log of breakthroughs / blockers (shared memory). |
| `scripts/ralph-loop.sh` | The loop — authored locally, nothing downloaded. |
| `logs/` | Per-run + per-iteration output (gitignored). |

## Run it (in YOUR terminal, sandboxed)
```bash
ralph/scripts/ralph-loop.sh        # up to 10 iterations
ralph/scripts/ralph-loop.sh 20     # up to 20
```
Requires the `claude` CLI on PATH. The loop uses `--dangerously-skip-permissions`
(full autonomy) and will **commit and push a branch**. Ctrl-C to stop. It halts
early when the backlog is finished (`<promise>ALL_SPECS_COMPLETE</promise>`).

## Add a spec
Copy an existing file in `specs/`, bump the number, and write **specific,
testable** acceptance criteria (each a shell command or observable fact). Vague
criteria ("works correctly") make Ralph flail; concrete ones ("`npm test` exits
0") give it real backpressure.

## Project caveats (also in the Constitution)
- The **Ableton-audio hop can't be verified headlessly** — specs never depend on
  it; that check stays human.
- One Python instance drives one device; ports **9000/9001** must be free.
- `markov_osc.js` is shared by both devices — never regress the generator.
