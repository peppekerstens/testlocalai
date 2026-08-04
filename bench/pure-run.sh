#!/usr/bin/env bash
# Pure self-test runner. Treats each task like an unknown-LLM evaluation:
#   - control: verify.sh <expected.md>   must PASS (test accepts ground truth)
#   - control: verify.sh <empty>         must FAIL (test rejects garbage)
#   - model run: dispatch SPEC.md (or a per-model override, see below) as
#     prompt -> verify.sh <output>
# Prints ONLY verdicts and token counts; never file contents.
#
# Per-model steering: tasks/<task>/SPEC.md is always the bare, canonical,
# model-agnostic task definition — never edit it to steer one model, it is
# shared across every model this runner is ever invoked with. If
# models/<model-dir>/task-overrides/<task>.md exists, it is dispatched
# instead of the bare SPEC for that task+model only (model-dir = the model
# tag with ':' replaced by '-', matching every other models/<dir>/ path in
# this project). This mirrors bench.sh's existing --rules mechanism for
# code tasks (models/<model>/rules/<lang>-rules.md, composed at dispatch
# time, SPEC.md never mutated) — added here 2026-08-02 after a session
# discovered doc-task steering had been silently overwriting the shared
# SPEC.md instead, contaminating the next model's "bare" baseline with the
# previous model's steering. See AGENTS.md's "Per-model doc-task steering"
# rule.
#
# Per-model, per-task grammar steering: if
# models/<model-dir>/grammars/<task>.gbnf exists, it's passed to dispatch.sh
# as DISPATCH_GRAMMAR_FILE for that task+model only — a structural
# constraint on the decoder (guaranteed valid shape), not a prompt-text
# suggestion. Same isolation rule as task-overrides/ above: never a shared,
# cross-model default.
#
# Usage: bash bench/pure-run.sh [model] [--test <tracks>] [task...]
#   model   : qwen2.5-coder:1.5b | deepseek-r1:1.5b | ... (default deepseek-r1:1.5b)
#   --test  : select whole track(s) by name, comma-separated:
#               docs    - all tasks/doc-*     (document editing/reproduction)
#               reason  - all tasks/reason-*  (reasoning about docs/config/behavior)
#               tool    - all tasks/tool-*    (MCP tool/argument selection)
#               extract - all tasks/extract-* (structured extraction/classification)
#               review  - all tasks/review-*  (C# code review/bug-finding)
#               code    - all tasks/code-*    (compile+test harness — see below)
#             e.g. --test docs runs ONLY the doc-* tasks, --test docs,reason
#             runs both. Mutually exclusive with an explicit task list below —
#             pass one or the other.
#   tasks   : explicit task names, space-separated (only used when --test is
#             not given). Default with neither --test nor tasks given:
#             docs+reason only (18 tasks) — a real default kept for backward
#             compatibility, NOT "every track available"; pass --test
#             explicitly for tool/extract/review or any other combination.
#
# code-* tasks need an actual compile+test harness, not just
# dispatch+verify.sh — that logic already exists in bench.sh (transcribe
# fenced block, dotnet test/pytest, parse verdict), so --test code calls
# bench.sh per task (one bench.sh call per task, round label
# "pure-<this invocation's timestamp>" so repeat pure-run.sh calls never
# overwrite each other's bench.sh reports) and normalizes its "## VERDICT:
# PASS/BUILD FAIL/TEST FAIL/UNKNOWN" into the same "RESULT task=...
# model_run=PASS|FAIL ..." line every other task kind emits below —
# report.sh's parser only ever reads that line shape, so nothing
# downstream (report.sh, report_parse.py, tier2-gate.sh, confirm.sh,
# report-check.sh) needed to change. Steering for code tasks is per-
# LANGUAGE (models/<model-dir>/rules/<lang>-rules.md, bench.sh's existing
# --rules mechanism), not per-task like doc/reason overrides — a real,
# intentional difference (see history.md's "specialists don't generalize"
# finding: code steering already found two-recipes-per-language beats
# one-file-per-task), not a gap.
#
# Per-task exclusion from a language's rules file: if
# models/<model-dir>/rules/<lang>-rules-exclude.txt exists, any task name
# listed there (one per line) dispatches bare even when <lang>-rules.md
# exists. Real, not hypothetical: qwen2.5-coder-1.5b's own history.md
# documents that its "extended" C# task family (code-csharp-stats,
# -equality, -events, -repository, -batch, -workflow) build-fails under
# --rules from hallucinated using-statements the rules file's canonical-
# API examples trigger, while the "original" family needs --rules to
# pass — two recipes for two families, exactly the kind of per-model
# finding this file's own steering-difference note above already expects.
# Found by this project's own loop.sh diagnosing a real dispatch bug via
# its automated Findings-writing (2026-08-04) — the two-recipe split was
# already documented in history.md but not enforced here until this fix.
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
CODE_TASKS="$(cd "$SELF_DIR/../tasks" && ls -d code-*/ 2>/dev/null | sed 's#/$##' | xargs)"
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
      code) TASKS="$TASKS $CODE_TASKS" ;;
      *) echo "ERROR: unknown --test track '$track' (expected: docs, reason, tool, extract, review, code)" >&2; exit 2 ;;
    esac
  done
  TASKS="$(echo "$TASKS" | xargs)"
elif [ "$#" -gt 0 ]; then
  TASKS="$*"
else
  TASKS="$ALL_TASKS"
fi

MODEL_DIR_NAME="$(echo "$MODEL" | tr ':' '-')"
RUN_TS="$(date -u +%Y%m%d-%H%M%S)"

for t in $TASKS; do
  D="$SELF_DIR/../tasks/$t"

  case "$t" in
    code-*)
      # Compile+test tasks: bench.sh already has the real logic
      # (transcribe fenced block, dotnet test/pytest, parse verdict) -
      # call it per task and normalize its report into the same RESULT
      # line shape every other task kind emits below.
      SRC_FILE="$(find "$D/harness/src" -maxdepth 1 -type f 2>/dev/null | head -1)"
      SRC_NAME="$(basename "${SRC_FILE:-unknown}")"
      RULES_LANG=""
      if find "$D/harness" -maxdepth 1 -name '*.csproj' 2>/dev/null | grep -q .; then
        RULES_LANG="csharp"
      elif [ -f "$D/harness/requirements.txt" ]; then
        RULES_LANG="python"
      fi
      MODE_ARG=""
      EXCLUDE_FILE="$SELF_DIR/../models/$MODEL_DIR_NAME/rules/${RULES_LANG}-rules-exclude.txt"
      if [ -n "$RULES_LANG" ] && [ -f "$SELF_DIR/../models/$MODEL_DIR_NAME/rules/${RULES_LANG}-rules.md" ] \
         && ! { [ -f "$EXCLUDE_FILE" ] && grep -qxF "$t" "$EXCLUDE_FILE"; }; then
        MODE_ARG="--rules"
      fi
      ROUND_LABEL="pure-$RUN_TS"
      BENCH_MODEL="$MODEL" bash "$SELF_DIR/bench.sh" "$t" "$ROUND_LABEL" "$SRC_NAME" "$MODE_ARG" >/dev/null 2>&1
      BENCH_RC=$?
      CODE_REPORT="$SELF_DIR/../models/$MODEL_DIR_NAME/reports/round-$ROUND_LABEL-$(basename "$t").md"
      if [ "$BENCH_RC" -ne 0 ] || [ ! -f "$CODE_REPORT" ]; then
        echo "RESULT task=$t expected_ctrl=n/a empty_ctrl=n/a model_run=ERROR prompt_tok=? comp_tok=?"
        continue
      fi
      if grep -q "^## VERDICT: PASS" "$CODE_REPORT"; then RUN=PASS; else RUN=FAIL; fi
      PT="$(grep "^- Tokens:" "$CODE_REPORT" | grep -oE '[0-9]+ prompt' | grep -oE '[0-9]+' || echo '?')"
      CT="$(grep "^- Tokens:" "$CODE_REPORT" | grep -oE '[0-9]+ completion' | grep -oE '[0-9]+' || echo '?')"
      [ -z "$PT" ] && PT="?"
      [ -z "$CT" ] && CT="?"
      TRUNCATED=""
      grep -q "TRUNCATED (finish_reason=length)" "$CODE_REPORT" && TRUNCATED=" TRUNCATED-BY-CONTEXT-LIMIT(not-a-content-failure)"
      echo "RESULT task=$t expected_ctrl=n/a empty_ctrl=n/a model_run=$RUN prompt_tok=$PT comp_tok=$CT${TRUNCATED}"
      continue
      ;;
  esac

  POS="?"; NEG="?"; RUN="?"
  PT="?"; CT="?"

  # control 1: expected.md must pass
  if (cd "$D" && bash verify.sh expected.md >/dev/null 2>&1); then POS=PASS; else POS=FAIL; fi
  # control 2: empty input must fail
  : > "$TMP_DIR/.empty"
  if (cd "$D" && bash verify.sh "$TMP_DIR/.empty" >/dev/null 2>&1); then NEG=PASS; else NEG=FAIL; fi

  OVERRIDE="$SELF_DIR/../models/$MODEL_DIR_NAME/task-overrides/$t.md"
  if [ -f "$OVERRIDE" ]; then SPEC_TO_USE="$OVERRIDE"; else SPEC_TO_USE="$D/SPEC.md"; fi

  # Per-model, per-task GBNF grammar auto-resolution, mirroring the
  # task-overrides/ mechanism above: models/<model-dir>/grammars/<task>.gbnf,
  # if present, is passed to dispatch.sh as DISPATCH_GRAMMAR_FILE for this
  # task only (unset again right after, so it never leaks into later tasks
  # in the same run). See AGENTS.md / models/qwen3.5-9b/history.md for the
  # reasoning on when a grammar is an appropriate lever (structural
  # constraints only, never dictating literal answer content).
  GRAMMAR="$SELF_DIR/../models/$MODEL_DIR_NAME/grammars/$t.gbnf"
  if [ -f "$GRAMMAR" ]; then export DISPATCH_GRAMMAR_FILE="$GRAMMAR"; else unset DISPATCH_GRAMMAR_FILE || true; fi

  OUT="$TMP_DIR/out-$t.txt"
  TRUNCATED=""
  if bash "$SELF_DIR/dispatch.sh" "$MODEL" "$SPEC_TO_USE" "$OUT" >/dev/null 2>&1; then
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
