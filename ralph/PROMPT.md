You are ONE iteration of a Ralph Wiggum autonomous build loop for the
autoharmonizer-max project. You have a FRESH context window. All shared state
lives on disk. Do exactly one unit of progress toward the backlog, then stop.

Working directory is the repository root.

STEPS
1. Read `ralph/CONSTITUTION.md` (project rules — obey them) and the tail of
   `ralph/ralph_history.txt` (what earlier iterations learned).
2. List `ralph/specs/*.md`. Pick the HIGHEST-priority spec whose acceptance
   criteria are NOT all satisfied — lowest file number = highest priority; skip
   any spec whose header says `Status: COMPLETE`.
3. Implement the smallest coherent next step toward that spec. Prefer FINISHING
   one spec over spreading across many.
4. Verify by actually running the spec's stated test / verify commands. Fix
   failures. Do NOT fake, weaken, or skip tests to make them pass. If you are
   blocked, append a one-line blocker to `ralph/ralph_history.txt` and STOP
   WITHOUT printing any done signal.
5. Only when EVERY acceptance criterion of the chosen spec is verified green:
   - commit the work per the Constitution (branch off `max-markov`, message
     format, Co-Authored-By trailer),
   - change that spec's header to `Status: COMPLETE`,
   - append a one-line breakthrough note to `ralph/ralph_history.txt`,
   - print this EXACT line on its own:  `<promise>DONE</promise>`
6. If, after step 2, ALL specs are already `Status: COMPLETE`, print instead:
   `<promise>ALL_SPECS_COMPLETE</promise>`

HARD RULES
- One spec's criteria at a time. Never print `<promise>DONE</promise>` unless
  every criterion is actually met and every test is green (none failing/skipped).
- Keep changes minimal and in the surrounding style. Do not touch unrelated code.
- Do not regress the generator device (shared `markov_osc.js`).
- The Ableton-audio hop cannot be verified headlessly; never depend on it and
  never claim it passed. Leave such criteria unchecked with a note.
