#!/usr/bin/env bash
# Runs every role a model can technically attempt, via report.sh - the
# "fully test this model" entrypoint.
#
# Rule for what "technically cannot do" means, so this never turns back
# into a habit: every role except visual needs nothing more than text
# in, text out - every LLM can attempt code-emitter, tool-use, extract,
# review, documenter, and reasoner, even if it scores badly. A bad score
# is a real result, not a technical impossibility, and does not belong
# on an exclusion list. Only visual needs a capability most models
# genuinely lack - a vision-trained model plus an mmproj vision
# projector - so it is the only role skipped by default.
#
# code-emitter is included by default on purpose. Excluding it from a
# "full test" was an observed habit, not a rule - report.sh already runs
# it as role "code" through the exact same interface as every other
# role (see report.sh's own header comment).
#
# Vision capability check: models/<model-slug>/vision-capable - an
# empty marker file, presence means capable. Same one-file-no-schema
# convention templates/new-model/README.md already uses for
# ALLOWED_MODELS onboarding. No model in this repo has this marker yet -
# visual is dispatched per-model by hand today (e.g.
# tasks/visual-basic/run.sh), not through report.sh, so even a
# vision-capable model still gets a reminder here, not an automatic run.
#
# Usage: bash bench/full-test.sh <model> [backend] [port]
#   model  : an ALLOWED_MODELS entry in bench/dispatch.sh, e.g. qwen3.5:9b
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

MODEL="${1:?usage: full-test.sh <model> [backend] [port]}"
BACKEND="${2:-llamacpp}"
PORT="${3:-8080}"
SLUG="$(echo "$MODEL" | tr ':' '-')"

ROLES=(docs reason tool extract review code)

VISION_MARKER="models/$SLUG/vision-capable"
if [ -f "$VISION_MARKER" ]; then
  echo "-> $SLUG: vision-capable ($VISION_MARKER exists) - visual has no generic dispatch path yet, run its model-specific task runner by hand (e.g. tasks/visual-basic/run.sh)."
else
  echo "-> $SLUG: no $VISION_MARKER - visual is the one role this model cannot technically attempt, skipped."
fi

ERRORED=()
for role in "${ROLES[@]}"; do
  echo
  echo "======================================================================"
  echo "== $MODEL / $role"
  echo "======================================================================"
  if ! bash bench/report.sh "$MODEL" "$role" "$BACKEND" "$PORT"; then
    ERRORED+=("$role")
  fi
done

echo
echo "======================================================================"
if [ "${#ERRORED[@]}" -eq 0 ]; then
  echo "== full test of $MODEL: all ${#ROLES[@]} applicable roles ran (pass/fail counts are IN each report, not here - a role running is not the same as it passing)"
else
  echo "== full test of $MODEL: ${#ERRORED[@]} role(s) failed to even run: ${ERRORED[*]} - a real infra problem (report.sh/pure-run.sh error), not a test verdict"
fi
echo "-> next: for each role, once its README row is updated, run bench/leaderboard-sync.sh $SLUG <role-id>"
