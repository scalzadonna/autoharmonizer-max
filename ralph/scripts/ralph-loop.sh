#!/usr/bin/env bash
# ralph-loop.sh — locally-authored Ralph Wiggum loop for autoharmonizer-max.
#
# Each iteration spawns a FRESH `claude` process (clean context) that picks the
# highest-priority incomplete spec, implements it, tests, commits, and prints
# <promise>DONE</promise> only when its acceptance criteria pass. The loop stops
# early when an iteration reports the whole backlog complete.
#
# Usage:
#   ralph/scripts/ralph-loop.sh [max_iterations]     # default 10
#
# SAFETY: this uses `--dangerously-skip-permissions` (full autonomy) and will
# COMMIT and PUSH a branch. Run it only in a sandbox / on a throwaway branch you
# trust. Ctrl-C to stop. This script was authored locally — nothing is downloaded.
set -uo pipefail

# Resolve paths from this script's own location (works from any cwd).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RALPH_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$RALPH_DIR/.." && pwd)"
cd "$REPO_ROOT"

MAX_ITERS="${1:-10}"
PROMPT_FILE="$RALPH_DIR/PROMPT.md"
LOG_DIR="$RALPH_DIR/logs"
DONE_SIGNAL="<promise>DONE</promise>"
STOP_SIGNAL="<promise>ALL_SPECS_COMPLETE</promise>"

command -v claude >/dev/null 2>&1 || { echo "ERROR: claude CLI not found on PATH"; exit 127; }
[ -f "$PROMPT_FILE" ] || { echo "ERROR: missing prompt file: $PROMPT_FILE"; exit 1; }
mkdir -p "$LOG_DIR"

TS="$(date +%Y%m%d_%H%M%S)"
SESSION_LOG="$LOG_DIR/ralph_session_${TS}.log"
PROMPT="$(cat "$PROMPT_FILE")"

echo "Ralph loop | repo=$REPO_ROOT | max_iters=$MAX_ITERS | log=$SESSION_LOG" | tee -a "$SESSION_LOG"

for ((i = 1; i <= MAX_ITERS; i++)); do
  ITER_TS="$(date +%Y%m%d_%H%M%S)"
  ITER_LOG="$LOG_DIR/ralph_iter_${i}_${ITER_TS}.log"
  echo "" | tee -a "$SESSION_LOG"
  echo "===== ITERATION $i/$MAX_ITERS  $(date) =====" | tee -a "$SESSION_LOG"

  # Fresh context each iteration: a brand-new claude process.
  claude -p "$PROMPT" --dangerously-skip-permissions 2>&1 | tee "$ITER_LOG" | tee -a "$SESSION_LOG"

  if grep -qF "$STOP_SIGNAL" "$ITER_LOG"; then
    echo ">>> Backlog complete (ALL_SPECS_COMPLETE). Stopping." | tee -a "$SESSION_LOG"
    exit 0
  elif grep -qF "$DONE_SIGNAL" "$ITER_LOG"; then
    echo ">>> Spec completed this iteration; continuing with fresh context." | tee -a "$SESSION_LOG"
  else
    echo ">>> No DONE signal (spec incomplete or blocked); retrying with fresh context." | tee -a "$SESSION_LOG"
  fi
done

echo "" | tee -a "$SESSION_LOG"
echo "Reached max iterations ($MAX_ITERS). Review ralph/ralph_history.txt and logs/." | tee -a "$SESSION_LOG"
