#!/usr/bin/env bash
# Bench runner: dispatch a task's SPEC (+ optional rules), verify the output
# against a task-local verdict, and write a report.
#
# Two task kinds, auto-detected:
#   code tasks — dir has a harness/ build marker. Output's first fenced code
#     block (language auto-detected from the marker) is transcribed into
#     harness/src, then built+tested. Two languages supported so far:
#       - C#: harness/*.csproj present -> ```csharp fence, `dotnet test`.
#       - Python: harness/requirements.txt present -> ```python fence,
#         `pytest` (harness/src/ put on PYTHONPATH so tests can import it
#         directly; requirements.txt must list pytest itself).
#     Adding a third language: extend detect_harness_lang() below with its
#     marker file, fence tag, and build+test+verdict-parse logic — nothing
#     elsewhere in this script is language-specific.
#   doc tasks  — dir has a verify.sh. The whole output text is the deliverable;
#     verdict comes from verify.sh <output> (doc-fidelity assertions).
#
# Usage:
#   bench.sh <task-dir> <round> <src-file> [--rules <lang>|--legacy]   (code task)
#   bench.sh <task-dir> <round> [--rules <lang>|--legacy]              (doc task)
#   task-dir : directory under tasks/ (e.g. code-csharp-config, doc-adapt)
#   round    : round label used in the report filename (e.g. a, b, c, r1)
#   src-file : (code tasks) the single source file to produce
#              (e.g. ObfuscationConfig.cs, obfuscation_config.py)
#   --rules <lang> : prepend models/<model>/rules/<lang>-rules.md to the
#              prompt (default lang: the task's own detected harness
#              language — csharp or python). SPEC.md and <lang>-rules.md
#              are always the current validated-best for that model+task —
#              see "Best-first presentation" in the root README. Rules are
#              per-model steering, not a generic cross-model ruleset — they
#              live under the model that earned them.
#   --legacy : prepend the superseded rules/history/<lang>-rules-verbose.md
#              AND use the task's history/SPEC-verbose.md, instead of the
#              current best pair — for iteration-history comparison runs
#              only, not for production dispatch.
#
# Model is set by BENCH_MODEL (default qwen2.5-coder:1.5b). Reports land in
# models/<model>/reports/round-<round>-<task-basename>.md — model-scoped,
# not a shared bench/reports/ (findings are always for one specific model,
# see AGENTS.md). Prompt/output round history lands in
# tasks/<task>/rounds/. For an aggregated, enriched, multi-task
# report with token deltas vs a previous run, see bench/report.sh instead —
# this script writes one raw per-task verdict per call, same as always.

set -euo pipefail

BENCH_DIR="$(cd "$(dirname "$0")" && pwd)"
ORCH_DIR="$(cd "$BENCH_DIR/.." && pwd)"
TASKS_DIR="$ORCH_DIR/tasks"
MODEL="${BENCH_MODEL:-qwen2.5-coder:1.5b}"
MODEL_DIR="$ORCH_DIR/models/$(echo "$MODEL" | tr ':' '-')"
REPORTS_DIR="$MODEL_DIR/reports"

TASK_DIR="$1"
ROUND="$2"
MODE="${4:-}"
SRC_NAME="${3:-}"

SPEC_FILE="$TASKS_DIR/$TASK_DIR/SPEC.md"
LEGACY_SPEC_FILE="$TASKS_DIR/$TASK_DIR/history/SPEC-verbose.md"
DOC_VERIFY="$TASKS_DIR/$TASK_DIR/verify.sh"
SRC_DIR="$TASKS_DIR/$TASK_DIR/harness/src"
HARNESS_DIR="$TASKS_DIR/$TASK_DIR/harness"
CSPROJ="$(find "$HARNESS_DIR" -maxdepth 1 -name '*.csproj' 2>/dev/null | head -1 || true)"
PY_REQS="$HARNESS_DIR/requirements.txt"
ROUNDS_DIR="$TASKS_DIR/$TASK_DIR/rounds"
OUT_FILE="$ROUNDS_DIR/out-${ROUND}.txt"
PROMPT_FILE="$ROUNDS_DIR/prompt-${ROUND}.txt"
REPORT_DIR="$REPORTS_DIR"
REPORT_FILE="$REPORT_DIR/round-$ROUND-$(basename "$TASK_DIR").md"

DOC_MODE=0
[ -f "$DOC_VERIFY" ] && DOC_MODE=1

# Harness language auto-detection (code tasks only) — add a new marker/case
# here to support a third language; nothing else in this script needs to
# know which language a given task is.
HARNESS_LANG=""
FENCE_LANG=""
if [ -n "$CSPROJ" ]; then
  HARNESS_LANG="csharp"
  FENCE_LANG="csharp"
elif [ -f "$PY_REQS" ]; then
  HARNESS_LANG="python"
  FENCE_LANG="python"
fi
RULES_LANG="${5:-${HARNESS_LANG:-csharp}}"

[ -f "$SPEC_FILE" ] || { echo "ERROR: $SPEC_FILE not found" >&2; exit 1; }
if [ "$DOC_MODE" -eq 1 ]; then
  if [ -n "$MODE" ]; then
    echo "WARN: doc task ignores --rules/--legacy; using bare SPEC" >&2
    MODE=""
  fi
else
  [ -n "$SRC_NAME" ] || { echo "ERROR: code task needs <src-file>" >&2; exit 1; }
  [ -n "$HARNESS_LANG" ] || { echo "ERROR: no recognized build marker (*.csproj or requirements.txt) in $TASK_DIR/harness" >&2; exit 1; }
fi
mkdir -p "$REPORT_DIR" "$ROUNDS_DIR"

# Assemble prompt: rules first if requested, then SPEC.
case "$MODE" in
  --rules)
    RULES_FILE="$MODEL_DIR/rules/${RULES_LANG}-rules.md"
    [ -f "$RULES_FILE" ] || { echo "ERROR: no rules file for language '$RULES_LANG' under $MODEL_DIR/rules: $RULES_FILE" >&2; exit 1; }
    cat "$RULES_FILE" > "$PROMPT_FILE"
    printf "\n\n--- TASK BELOW ---\n\n" >> "$PROMPT_FILE"
    cat "$SPEC_FILE" >> "$PROMPT_FILE"
    ;;
  --legacy)
    LEGACY_RULES_FILE="$MODEL_DIR/rules/history/${RULES_LANG}-rules-verbose.md"
    [ -f "$LEGACY_RULES_FILE" ] || { echo "ERROR: no legacy rules file for language '$RULES_LANG' under $MODEL_DIR/rules/history: $LEGACY_RULES_FILE" >&2; exit 1; }
    [ -f "$LEGACY_SPEC_FILE" ] || { echo "ERROR: no legacy SPEC for this task: $LEGACY_SPEC_FILE" >&2; exit 1; }
    cat "$LEGACY_RULES_FILE" > "$PROMPT_FILE"
    printf "\n\n--- TASK BELOW ---\n\n" >> "$PROMPT_FILE"
    cat "$LEGACY_SPEC_FILE" >> "$PROMPT_FILE"
    ;;
  *)
    cat "$SPEC_FILE" >> "$PROMPT_FILE"
    ;;
esac

echo "==> dispatch ($ROUND) $TASK_DIR"
DISPATCH_BACKEND="${DISPATCH_BACKEND:-llamacpp}" "$BENCH_DIR/dispatch.sh" "$MODEL" "$PROMPT_FILE" "$OUT_FILE"

# Token counts (llamacpp backend writes a sidecar; ollama needs /tokenize).
# Also surfaces context/token-limit truncation explicitly in the report —
# an empty/short output with finish_reason=length is exhaustion, not a
# model failure; don't let that get silently scored as a content bug.
TOKEN_LINE=""
if [ -f "$OUT_FILE.tokens.json" ]; then
  PTOK="$(python3 -c "import json;print(json.load(open('$OUT_FILE.tokens.json')).get('prompt_tokens','?'))" 2>/dev/null || echo '?')"
  CTOK="$(python3 -c "import json;print(json.load(open('$OUT_FILE.tokens.json')).get('completion_tokens','?'))" 2>/dev/null || echo '?')"
  TOKEN_LINE="- Tokens: $PTOK prompt / $CTOK completion"
  FINISH_REASON="$(python3 -c "import json;print(json.load(open('$OUT_FILE.tokens.json')).get('finish_reason','?'))" 2>/dev/null || echo '?')"
  RCONTENT_CHARS="$(python3 -c "import json;print(json.load(open('$OUT_FILE.tokens.json')).get('reasoning_content_chars',0))" 2>/dev/null || echo '0')"
  if [ "$FINISH_REASON" = "length" ]; then
    TOKEN_LINE="$TOKEN_LINE
- ⚠️ TRUNCATED (finish_reason=length) — context/token limit hit before generation finished. reasoning_content=${RCONTENT_CHARS} chars. If the output below is empty or short, this is context exhaustion, not a model reasoning failure — do not score it as a content bug without checking the server's context size first."
  fi
fi

# Verdict body: doc tasks run verify.sh; code tasks transcribe + build+test.
if [ "$DOC_MODE" -eq 1 ]; then
  echo "==> doc-fidelity verify"
  VERDICT_BODY="$(bash "$DOC_VERIFY" "$OUT_FILE" 2>&1 || true)"
else
  echo "==> transcribe"
  python3 - "$OUT_FILE" "$SRC_DIR" "$SRC_NAME" "$FENCE_LANG" <<'PY'
import re, sys, os, shutil
out_file, src_dir, name, fence_lang = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(out_file, encoding="utf-8") as f:
    text = f.read()
m = re.search(r"```" + re.escape(fence_lang) + r"\s*\n(.*?)```", text, re.S)
if not m:
    sys.exit(0)  # no fenced block; report will show a missing-block failure
os.makedirs(src_dir, exist_ok=True)
for f in os.listdir(src_dir):
    p = os.path.join(src_dir, f)
    # rmtree for dirs (e.g. Python's own __pycache__ from a prior round),
    # remove for files — the C# harness never nests dirs under src/, but
    # Python's import machinery always will after the first run.
    shutil.rmtree(p) if os.path.isdir(p) else os.remove(p)
with open(os.path.join(src_dir, name), "w", encoding="utf-8") as f:
    f.write(m.group(1))
print(f"transcribed {len(m.group(1))} bytes to {src_dir}/{name}")
PY

  echo "==> build+test ($HARNESS_LANG)"
  if [ "$HARNESS_LANG" = "csharp" ]; then
    export PATH="$HOME/.dotnet:$PATH"
    TEST_OUTPUT="$(dotnet test "$CSPROJ" --nologo -v q 2>&1 || true)"

    VERDICT_BODY="$( {
      if grep -qE "error CS" <<< "$TEST_OUTPUT"; then
        echo "## VERDICT: BUILD FAIL"
        echo '```'
        grep -E "error CS" <<< "$TEST_OUTPUT" | head -20
        echo '```'
      elif grep -qE "Failed:     [1-9]" <<< "$TEST_OUTPUT"; then
        echo "## VERDICT: TEST FAIL"
        { grep -E '\[FAIL\]' <<< "$TEST_OUTPUT" | head -20; } || true
      elif grep -qE "Passed!.*Failed:     0" <<< "$TEST_OUTPUT"; then
        echo "## VERDICT: PASS"
        grep -E "Passed!" <<< "$TEST_OUTPUT"
      else
        echo "## VERDICT: UNKNOWN"
        echo '```'
        echo "$TEST_OUTPUT" | tail -20
        echo '```'
      fi
    } )"
  elif [ "$HARNESS_LANG" = "python" ]; then
    TEST_OUTPUT="$(PYTHONPATH="$SRC_DIR" python3 -m pytest "$HARNESS_DIR/tests" --tb=short -q 2>&1 || true)"

    VERDICT_BODY="$( {
      if grep -qE "error(s)? during collection|^E   (Syntax|Import|Module|Name|Indentation)Error" <<< "$TEST_OUTPUT"; then
        echo "## VERDICT: BUILD FAIL"
        echo '```'
        echo "$TEST_OUTPUT" | tail -20
        echo '```'
      elif grep -qE "^[0-9]+ failed" <<< "$TEST_OUTPUT"; then
        echo "## VERDICT: TEST FAIL"
        { grep -E '^FAILED ' <<< "$TEST_OUTPUT" | head -20; } || true
      elif grep -qE "^[0-9]+ passed" <<< "$TEST_OUTPUT"; then
        echo "## VERDICT: PASS"
        grep -E "^[0-9]+ passed" <<< "$TEST_OUTPUT"
      else
        echo "## VERDICT: UNKNOWN"
        echo '```'
        echo "$TEST_OUTPUT" | tail -20
        echo '```'
      fi
    } )"
  fi
fi

{
  echo "# Bench report: $TASK_DIR (round $ROUND)"
  echo ""
  echo "- Prompt: \`$PROMPT_FILE\`"
  echo "- Model: $MODEL (temp 0.2)"
  echo "- Backend: ${DISPATCH_BACKEND:-llamacpp}"
  if [ "$DOC_MODE" -eq 1 ]; then
    echo "- Mode: doc-fidelity (verify.sh; bare SPEC)"
  else
    case "$MODE" in
      --rules) echo "- Mode: rules (${RULES_LANG}-rules.md + SPEC.md, current best)" ;;
      --legacy) echo "- Mode: legacy (history/${RULES_LANG}-rules-verbose.md + history/SPEC-verbose.md, superseded — comparison only)" ;;
      *) echo "- Mode: bare SPEC.md (current best)" ;;
    esac
  fi
  [ -n "$TOKEN_LINE" ] && echo "$TOKEN_LINE"
  echo ""
  echo "$VERDICT_BODY"
} > "$REPORT_FILE"

echo "==> report: $REPORT_FILE"
