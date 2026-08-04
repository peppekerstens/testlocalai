#!/usr/bin/env bash
set -uo pipefail

LOCK_FILE=~/claude-remote/run.lock
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ): another instance is already running (lock held) - exiting without doing anything." >> ~/claude-remote/status.md
  exit 0
fi

source <(grep "^export CLAUDE_CODE_OAUTH_TOKEN=" ~/.bashrc)
cd ~/github/testlocalai || exit 1

STATUS_FILE=~/claude-remote/status.md
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# top-level inbox still overrides everything, for one-off ad-hoc instructions
TOP_INBOX="$(cat ~/claude-remote/inbox.md)"

PROMPT="You are running unattended (headless, no human present) on the
remote worker machine described in docs/REMOTE-WSL2-SETUP.md. This
machine is assigned qwen3.5:9b and future 9B-and-up models; smaller
models are tested on the primary host, not here.

First, check the top-level inbox below - this ALWAYS takes priority
over everything else, including the role orchestration.

TOP-LEVEL PENDING INSTRUCTIONS:
${TOP_INBOX}

If that's just the placeholder, follow the STANDING MANDATE: read
~/claude-remote/orchestrator.md to find the current active role (roles
are worked SEQUENTIALLY, one at a time, not in parallel - only move to
the next role once the current one's roadmap Status says Closed). Then
read that role's own ~/claude-remote/roles/<role>/inbox.md (role-scoped
instructions, also take priority if non-placeholder) and
~/claude-remote/roles/<role>/roadmap.md (detailed progress so far), and
continue that role's work: full AGENTS.md quality loop (Phase 0, Phase
1 bare baseline, Tier 1 specialist steering per task, autonomous Tier 2
generalist gate, Confirm re-verification, Final report) - same rigor as
the already-closed Documenter role (models/qwen3.5-9b/README.md is the
reference example of what done looks like). This is real, standing,
pre-approved work - do not wait for further instructions to start or
continue it.

Work until a natural stopping point (a task's verdict settled, a
role's phase complete, or you're running low on useful context) - you
do not need to finish an entire role in one run. Commit and push real
progress as you go (AGENTS.md: persist after every test run). Before
finishing, ALWAYS update the active role's
~/claude-remote/roles/<role>/roadmap.md (Status line + a dated progress
note) so the next run knows exactly where to resume - mandatory, not
optional. If you closed the role this run, update
~/claude-remote/orchestrator.md's understanding is unchanged (it just
reads each role's Status), but double check the NEXT role in sequence
is what the following run should pick up.

PERFORMANCE FIGURE INTEGRITY: dispatch one task/round at a time,
never in parallel (no backgrounded/concurrent bench.sh or dispatch.sh
calls), even within your own work on a single role. This server's
tok/s numbers are part of what this project reports - concurrent
requests share GPU compute via continuous batching, which measurably
lowers each individual request's own tok/s. A clean, one-at-a-time
dispatch stream is required for every timing number to stay
trustworthy, not just a nice-to-have.

ACCURACY WARNING, learned the hard way: a prior unattended run
claimed \"verified qwen3.5:9b via curl http://localhost:11434/v1/models\"
when that port was actually not responding at all (confirmed
independently afterward) - it reused a plausible-sounding assumption
from earlier context instead of re-running the actual command. Do not
do this. Every claim you write into a roadmap/status file about what
you \"verified\" or \"confirmed\" must come from a command you actually
ran THIS turn, with its real output - not from memory, not from what
sounds right, not from an earlier run's report. If you did not
actually run it this turn, don't claim you verified it. Never skip or
weaken the Confirm re-verification step (3-run consistency check)
before reporting any specialist/generalist steering as a real
improvement - AGENTS.md added Confirm specifically because one lucky
draw looks identical to a real fix until you check.

End your work by appending a dated entry to ~/claude-remote/status.md
(top-level, don't overwrite prior entries) summarizing exactly what you
did or found this run, in 3-6 sentences, including which role you
worked on."

PROGRESS_FILE=~/claude-remote/progress.md
echo "=== run started $TS ===" > "$PROGRESS_FILE"

OUTPUT="$($HOME/.local/bin/claude -p "$PROMPT" --output-format stream-json --verbose \
  --allowedTools "Bash,Edit,Write,Read" 2>&1 \
  | tee >(python3 $HOME/claude-remote/stream_progress.py "$PROGRESS_FILE" >&2))"
EXIT=$?

FINAL_TEXT="$(echo "$OUTPUT" | tail -1 | python3 -c "
import json, sys
try:
    ev = json.loads(sys.stdin.read())
    print(ev.get('result', '(no result field - run may have errored, see progress.md)'))
except Exception as e:
    print(f'(could not parse final result: {e})')
")"

{
  echo ""
  echo "## Run $TS (exit $EXIT)"
  echo "$FINAL_TEXT"
} >> "$STATUS_FILE"

cat > ~/claude-remote/inbox.md <<'INBOX'
(no pending instructions — the autonomous run continues the sequential role orchestration in orchestrator.md)
INBOX
