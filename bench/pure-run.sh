#!/usr/bin/env bash
# Pure self-test runner. Treats each task like an unknown-LLM evaluation:
#   - control: verify.sh <expected.md>   must PASS (test accepts ground truth)
#   - control: verify.sh <empty>         must FAIL (test rejects garbage)
#   - model run: dispatch SPEC.md as prompt -> verify.sh <output>
# Prints ONLY verdicts and token counts; never file contents.
#
# Usage: bash bench/pure-run.sh [model] [--test <tracks>] [task...]
#   model   : qwen2.5-coder:1.5b | deepseek-r1:1.5b | ... (default deepseek-r1:1.5b)
#   --test  : select whole track(s) by name, comma-separated:
#               docs    - all tasks/doc-*     (document editing/reproduction)
#               reason  - all tasks/reason-*  (reasoning about docs/config/behavior)
#               tool    - all tasks/tool-*    (MCP tool/argument selection)
#               extract - all tasks/extract-* (structured extraction/classification)
#               review  - all tasks/review-*  (C# code review/bug-finding)
#             e.g. --test docs runs ONLY the doc-* tasks, --test docs,reason
#             runs both. Mutually exclusive with an explicit task list below —
#             pass one or the other. Does NOT cover code-* tasks — those need
#             an actual compile+test harness (see bench.sh), not just
#             dispatch+verify.sh, so they aren't part of this runner.
#   tasks   : explicit task names, space-separated (only used when --test is
#             not given). Default with neither --test nor tasks given:
#             docs+reason only (18 tasks) — a real default kept for backward
#             compatibility, NOT "every track available"; pass --test
#             explicitly for tool/extract/review or any other combination.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
export DISPATCH_BACKEND=llamacpp
export LLAMACPP_PORT="${LLAMACPP_PORT:-8080}"

TMP_DIR="$SELF_DIR/tmp"
mkdir -p "$TMP_DIR"

DOC_TASKS="doc-verbatim doc-surgical doc-adapt doc-script doc-synthesize doc-repair doc-summarize doc-crossref doc-restructure"
REASON_TASKS="reason-config-validity reason-diagnose reason-checklist reason-trace reason-consequence reason-compare reason-multihop reason-tradeoff reason-coverage"
TOOL_TASKS="tool-select tool-args tool-multi tool-none tool-error tool-policy"
EXTRACT_TASKS="extract-basic extract-optional extract-multi extract-classify extract-ambiguous extract-nested"
REVIEW_TASKS="review-null review-offbyone review-async review-concurrency review-logic review-clean"
ALL_TASKS="$DOC_TASKS $REASON_TASKS"
MODEL="${1:-deepseek-r1:1.5b}"
shift || true

if [ "${1:-}" = "--test" ]; then
  shift
  TRACKS="${1:-}"
  shift || true
  TASKS=""
  IFS=',' read -ra TRACK_LIST <<< "$TRACKS"
  for track in "${TRACK_LIST[@]}"; do
    case "$track" in
      docs) TASKS="$TASKS $DOC_TASKS" ;;
      reason) TASKS="$TASKS $REASON_TASKS" ;;
      tool) TASKS="$TASKS $TOOL_TASKS" ;;
      extract) TASKS="$TASKS $EXTRACT_TASKS" ;;
      review) TASKS="$TASKS $REVIEW_TASKS" ;;
      *) echo "ERROR: unknown --test track '$track' (expected: docs, reason, tool, extract, review)" >&2; exit 2 ;;
    esac
  done
  TASKS="$(echo "$TASKS" | xargs)"
elif [ "$#" -gt 0 ]; then
  TASKS="$*"
else
  TASKS="$ALL_TASKS"
fi

for t in $TASKS; do
  D="$SELF_DIR/../tasks/$t"
  POS="?"; NEG="?"; RUN="?"
  PT="?"; CT="?"

  # control 1: expected.md must pass
  if (cd "$D" && bash verify.sh expected.md >/dev/null 2>&1); then POS=PASS; else POS=FAIL; fi
  # control 2: empty input must fail
  : > "$TMP_DIR/.empty"
  if (cd "$D" && bash verify.sh "$TMP_DIR/.empty" >/dev/null 2>&1); then NEG=PASS; else NEG=FAIL; fi

  OUT="$TMP_DIR/out-$t.txt"
  TRUNCATED=""
  if bash "$SELF_DIR/dispatch.sh" "$MODEL" "$D/SPEC.md" "$OUT" >/dev/null 2>&1; then
    if [ -f "$OUT.tokens.json" ]; then
      PT="$(python3 -c "import json;d=json.load(open('$OUT.tokens.json'));print(d.get('prompt_tokens','?'))" 2>/dev/null || echo '?')"
      CT="$(python3 -c "import json;d=json.load(open('$OUT.tokens.json'));print(d.get('completion_tokens','?'))" 2>/dev/null || echo '?')"
      FR="$(python3 -c "import json;d=json.load(open('$OUT.tokens.json'));print(d.get('finish_reason','?'))" 2>/dev/null || echo '?')"
      [ "$FR" = "length" ] && TRUNCATED=" TRUNCATED-BY-CONTEXT-LIMIT(not-a-content-failure)"
    fi
    if (cd "$D" && bash verify.sh "$OUT" >/dev/null 2>&1); then RUN=PASS; else RUN=FAIL; fi
  else
    RUN=ERROR
  fi

  echo "RESULT task=$t expected_ctrl=$POS empty_ctrl=$NEG model_run=$RUN prompt_tok=$PT comp_tok=$CT${TRUNCATED}"
done
