#!/usr/bin/env bash
# The quality-loop orchestrator (AGENTS.md's "The quality loop"),
# scripted end to end. This is the piece that used to be "a capable
# model reads AGENTS.md prose and decides what to run next" - almost
# all of that was actually orchestration glue (run a script, branch on
# its exit code), not judgment. This script IS that glue. Only two
# narrow call-outs remain, both to `claude -p` for now:
#
#   bucket 2 (narrow classifier - CONTINUE/GATE_OUT on Tier 1's
#     gate-on-run-2 rule): structured JSON, one enum field. Cheap,
#     bounded, mechanically validatable - the first candidate to hand
#     to a small local model once that's tested (see
#     docs/QUALITY-LOOP-WORKFLOW.md).
#   bucket 3 (generative - Findings/Suggested-next-steps text, steering
#     override authoring): structured JSON with a content field. Higher
#     quality risk (a bad override burns a real budget slot), stays on
#     a capable model for longer.
#
# Every call to `claude` runs with `--tools ""` (no file/bash access -
# this script does ALL file I/O itself and pastes exactly what's needed
# into the prompt) and `--json-schema` (a guaranteed field to extract,
# not fragile text-boundary parsing) - same reasoning as report_parse.py
# scoping its regex to one section: don't trust free-text parsing when
# a structural guarantee is available instead.
#
# NOT automated by this script (deliberately, for now): Phase 0
# (pre-flight infra research), and the Research phase's EXTERNAL half
# (web search, model card lookup) - that genuinely needs real tool
# access this script's claude calls deliberately don't have (--tools
# ""), so it stays manual. The Research phase's CROSS-MODEL half (read
# every other tested model's history.md/README.md for this role's
# diagnosed idioms, extract transferable candidates) IS automated -
# see cross_model_research() - since it needs only file reads this
# script already does itself, not a tool call. Also not automated:
# Tier 2's generalist search, the Performance run, and the Final
# report's qualitative frontier-LLM comparison - these stay
# manual/Claude-Code-driven. This script stops cleanly and says so once
# Tier 1 -> gate -> Confirm settles; it never silently claims to have
# done a phase it skipped.
#
# Usage: bash bench/loop.sh [--verbose] <model> <role> [max_rounds] [backend] [port]
#   --verbose: also enables bash's own command trace (`set -x`) into the
#              log file (and terminal) - shows every command actually
#              run, including full claude invocations. Can appear
#              anywhere in the argument list.
#
# Every run always writes a full transcript to
# bench/logs/loop.sh-<UTC start timestamp>.log regardless of --verbose
# (stdout+stderr of this script AND everything it calls, via `exec >
# >(tee ...)` - the standard bash idiom for "capture everything, still
# show it live"). --verbose only controls how much low-level command
# detail is ALSO included, via bash's native `set -x` tracer rather
# than a hand-rolled print-more function.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCH_DIR="$(cd "$SELF_DIR/.." && pwd)"
cd "$ORCH_DIR"

VERBOSE=0
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--verbose" ]; then
    VERBOSE=1
  else
    ARGS+=("$arg")
  fi
done
set -- "${ARGS[@]}"

LOG_DIR="$ORCH_DIR/bench/logs"
mkdir -p "$LOG_DIR"
START_TS="$(date -u +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/loop.sh-$START_TS-$$.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[loop.sh] full trace: $LOG_FILE"

if [ "$VERBOSE" -eq 1 ]; then
  export PS4='+ $(date -u +%H:%M:%S) ${BASH_SOURCE##*/}:${LINENO}:${FUNCNAME[0]:-main}: '
  set -x
fi

MODEL="${1:?usage: loop.sh [--verbose] <model> <role> [max_rounds] [backend] [port]}"
ROLE="${2:?usage: loop.sh [--verbose] <model> <role> [max_rounds] [backend] [port]}"
MAX_ROUNDS="${3:-4}"
BACKEND="${4:-llamacpp}"
PORT="${5:-8080}"

MODEL_DIR_NAME="$(echo "$MODEL" | tr ':' '-')"
MODEL_DIR="$ORCH_DIR/models/$MODEL_DIR_NAME"
REPORTS_DIR="$MODEL_DIR/reports"
OVERRIDES_DIR="$MODEL_DIR/task-overrides"
GATED_FILE="$OVERRIDES_DIR/.gated-$ROLE"
TMP_DIR="$ORCH_DIR/bench/tmp"
CLAUDE_TMP="$TMP_DIR/loop-claude"
mkdir -p "$REPORTS_DIR" "$OVERRIDES_DIR" "$CLAUDE_TMP"

log() { echo "[loop.sh] $*"; }

# Resolve the claude binary once, don't rely on bare `claude` being on
# $PATH in every invocation context. Real failure this prevents: a
# non-interactive SSH session (e.g. `ssh host "bash -s" <<EOF`, as
# opposed to a login/interactive shell or run.sh's own explicit
# $HOME/.local/bin/claude calls) had $PATH = the OS default only, no
# ~/.local/bin - bare `claude` resolved to "command not found" (exit
# 127) on every ask_claude call, even with the OAuth token correctly
# sourced. `command -v` first (respects a correctly configured PATH,
# e.g. this project's primary host), falls back to the native
# installer's standard location otherwise.
CLAUDE_BIN="$(command -v claude 2>/dev/null || true)"
[ -z "$CLAUDE_BIN" ] && [ -x "$HOME/.local/bin/claude" ] && CLAUDE_BIN="$HOME/.local/bin/claude"
if [ -z "$CLAUDE_BIN" ]; then
  log "FATAL: claude binary not found on \$PATH or at \$HOME/.local/bin/claude - cannot make any ask_claude call."
  exit 1
fi

# Per-model mandatory dispatch-level env vars (AGENTS.md's "every
# dispatch-level tweak must be documented" rule already requires these
# be written in the model's own README Setup section in prose; this is
# the same values in a sourceable form so this script can actually
# apply them instead of relying on whoever invokes it to have exported
# them first). Real bug this prevents, not hypothetical: qwen3.5:4b's
# docs role and qwen3.5:9b's reason role both require
# DISPATCH_ENABLE_THINKING=false - missing it caused real
# context-exhaustion truncation (qwen3.5:4b: 4/9 tasks in its Phase 1
# baseline; qwen3.5:9b: the exact bug an autonomous run on the remote
# hit and self-diagnosed 2026-08-04, before this file existed).
DISPATCH_ENV_FILE="$MODEL_DIR/dispatch-env.sh"
if [ -f "$DISPATCH_ENV_FILE" ]; then
  log "sourcing required dispatch overrides: $DISPATCH_ENV_FILE"
  # shellcheck source=/dev/null
  source "$DISPATCH_ENV_FILE"
fi

# ---------------------------------------------------------------------
# ask_claude PROMPT_FILE SCHEMA_JSON OUT_JSON_FILE
# Stateless, tool-free, structured-output call. Writes the full JSON
# response (including the schema-validated "structured_output" object)
# to OUT_JSON_FILE. Caller extracts fields with python3 -c.
# ---------------------------------------------------------------------
ask_claude() {
  local prompt_file="$1" schema="$2" out_file="$3"
  local rc=0
  # Prompt goes in via stdin, never as a CLI argument - a large prompt
  # (e.g. cross_model_research's multi-model history.md dump) hit "argument
  # list too long" (E2BIG) as a literal argument; stdin has no such limit.
  "$CLAUDE_BIN" -p --tools "" --output-format json \
    --json-schema "$schema" < "$prompt_file" > "$out_file" 2>"$out_file.stderr" || rc=$?
  if [ "$rc" -ne 0 ]; then
    log "ERROR: claude call exited $rc (see $out_file.stderr)"
    return 1
  fi
  if [ ! -s "$out_file" ]; then
    log "ERROR: claude call produced no output (see $out_file.stderr)"
    return 1
  fi
  if ! python3 -c "
import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
so = d.get('structured_output')
sys.exit(1 if (d.get('is_error') or not isinstance(so, dict) or not so) else 0)
" "$out_file"; then
    log "ERROR: claude call returned is_error or no usable structured_output (see $out_file)"
    return 1
  fi
}

extract_field() {
  local json_file="$1" field="$2"
  python3 -c "
import json, sys
d = json.load(open(sys.argv[1], encoding='utf-8'))
so = d.get('structured_output', {})
print(so.get(sys.argv[2], ''))
" "$json_file" "$field"
}

commit_if_changed() {
  local message="$1"
  git add -- "models/$MODEL_DIR_NAME/" >/dev/null 2>&1
  if [ "$ROLE" = "code" ]; then
    # code-role runs also write real (tracked, not gitignored) evidence
    # under each task's own dir via bench.sh - rounds/ (prompt+output
    # history) and harness/src/ (the transcribed source each round
    # overwrites) - both need staging too, not just models/.
    git add -- tasks/code-*/rounds/ tasks/code-*/harness/src/ >/dev/null 2>&1
  fi
  if ! git diff --cached --quiet; then
    git commit -q -m "$message"
    log "committed: $message"
  fi
}

# ---------------------------------------------------------------------
# complete_report_findings REPORT_FILE
# Bucket 3a. Fills Findings/Suggested-next-steps if report-check.sh
# says they're still templated. No-op (mechanical check only) otherwise.
# ---------------------------------------------------------------------
complete_report_findings() {
  local report_file="$1"
  if bash "$SELF_DIR/report-check.sh" "$report_file" >/dev/null 2>&1; then
    log "report already complete: $(basename "$report_file")"
    return 0
  fi

  log "filling Findings/Suggested-next-steps: $(basename "$report_file")"

  local prompt_file="$CLAUDE_TMP/findings-prompt.txt"
  {
    echo "You are completing a report per this project's exact rules. Follow them precisely, do not add extra sections."
    echo
    echo "=== AGENTS.md rules (verbatim) ==="
    sed -n '/^## Completing a report/,/^## Per-model doc-task steering/p' "$ORCH_DIR/AGENTS.md" | sed '$d'
    echo
    echo "=== Report so far (results + comparison tables) ==="
    sed '/^## Findings/,$d' "$report_file"
    echo
    if [ "$ROLE" = "code" ]; then
      echo "=== bench.sh round reports (compile/test verdict + error excerpt) for each task ==="
      for d in "$ORCH_DIR"/tasks/code-*/; do
        task="$(basename "$d")"
        latest_cr="$(ls -t "$REPORTS_DIR"/round-pure-*-"$task".md 2>/dev/null | head -1)"
        [ -f "$latest_cr" ] || continue
        echo "--- $task ($(basename "$latest_cr")) ---"
        cat "$latest_cr"
        echo
      done
    else
      echo "=== Raw output for FAIL/changed tasks ==="
      for f in "$TMP_DIR"/out-*.txt; do
        [ -f "$f" ] || continue
        echo "--- $(basename "$f") ---"
        cat "$f"
        echo
      done
    fi
    echo "=== Model's existing history.md (for idiom classification) ==="
    [ -f "$MODEL_DIR/history.md" ] && cat "$MODEL_DIR/history.md"
    echo
    echo "Return the Findings bullets (as they'd appear under '## Findings', markdown, no heading) and the Suggested next steps bullets (as they'd appear under '## Suggested next steps', markdown, no heading) as two separate fields."
  } > "$prompt_file"

  local schema='{"type":"object","properties":{"findings":{"type":"string"},"suggested_next_steps":{"type":"string"}},"required":["findings","suggested_next_steps"]}'
  local out_file="$CLAUDE_TMP/findings-result.json"
  if ! ask_claude "$prompt_file" "$schema" "$out_file"; then
    log "WARNING: could not fill Findings for $(basename "$report_file") — left templated"
    return 1
  fi

  local findings suggested
  findings="$(extract_field "$out_file" findings)"
  suggested="$(extract_field "$out_file" suggested_next_steps)"

  if [ -z "${findings// /}" ] || [ -z "${suggested// /}" ]; then
    log "WARNING: claude returned an empty findings/suggested_next_steps field — leaving report templated, not writing blank content"
    return 1
  fi

  python3 -c "
import re, sys
path, findings, suggested = sys.argv[1:4]
text = open(path, encoding='utf-8').read()
text = re.sub(
    r'(## Findings\n\n)<!--.*?-->',
    lambda m: m.group(1) + findings.strip() + '\n',
    text, count=1, flags=re.S)
text = re.sub(
    r'(## Suggested next steps\n\n)<!--.*?-->',
    lambda m: m.group(1) + suggested.strip() + '\n',
    text, count=1, flags=re.S)
open(path, 'w', encoding='utf-8').write(text)
" "$report_file" "$findings" "$suggested"

  if bash "$SELF_DIR/report-check.sh" "$report_file" >/dev/null 2>&1; then
    log "Findings/Suggested-next-steps filled and verified: $(basename "$report_file")"
  else
    log "WARNING: filled Findings but report-check.sh still flags it — needs manual review"
  fi
  bash "$SELF_DIR/report-heuristics.sh" "$report_file" | sed 's/^/[loop.sh][heuristics] /'
}

# ---------------------------------------------------------------------
# cross_model_research ROLE
# AGENTS.md's Research phase, cross-model idiom check half only
# ("always both parts, uncapped, before any steering"). The external/
# web research half is NOT automated here — it needs real tool access
# this script's claude calls deliberately don't have (--tools "") —
# that half stays manual. Bucket 3 (generative): reads every OTHER
# model that has a report for this exact role, asks Claude to extract
# candidate techniques that MIGHT transfer, and persists the result to
# models/<model-dir>/research-<role>.md so it (a) survives to inform
# every author_override/author_rules call this session, not just one,
# and (b) isn't silently lost like AGENTS.md's "name any useful
# finding so it isn't lost" rule requires. Runs once per role — skips
# if the file already exists, since the persisted file already
# captures the finding; re-run by deleting it if other models have
# since gained new relevant history.
# ---------------------------------------------------------------------
role_display_name() {
  case "$1" in
    docs) echo "Documenter" ;;
    reason) echo "Reasoner" ;;
    tool) echo "Tool-use" ;;
    extract) echo "Extract" ;;
    review) echo "Review" ;;
    code) echo "Code-emitter" ;;
    visual) echo "Visual" ;;
    *) echo "$1" ;;
  esac
}

cross_model_research() {
  local role="$1"
  local research_file="$MODEL_DIR/research-$role.md"
  if [ -f "$research_file" ]; then
    log "cross-model research already done for role=$role: $research_file"
    return 0
  fi

  local other_models=() d om_dir_name
  for d in "$ORCH_DIR"/models/*/; do
    om_dir_name="$(basename "$d")"
    [ "$om_dir_name" = "$MODEL_DIR_NAME" ] && continue
    ls "${d}reports/report-$role-"*.md >/dev/null 2>&1 && other_models+=("$om_dir_name")
  done

  if [ "${#other_models[@]}" -eq 0 ]; then
    log "cross-model research: no other model has a role=$role report yet — nothing to check"
    printf 'No other model had a `%s`-role report as of %s — nothing to cross-check yet. Delete this file to re-check once another model has.\n' \
      "$role" "$(date -u +%Y-%m-%d)" > "$research_file"
    return 0
  fi

  log "cross-model research: checking [${other_models[*]}] for role=$role idioms — map step, one call per model"

  # Map: one small, focused call per source model - avoids ever
  # building one giant multi-model prompt (a real 200KB prompt hit
  # "argument list too long" here before this was map-reduce; stdin
  # fixed the crash, this fixes the underlying growth-without-bound
  # problem, since per-model cost stays flat as more models get added).
  local display_name
  display_name="$(role_display_name "$role")"
  local summaries="" om om_dir prompt_file schema out_file s
  for om in "${other_models[@]}"; do
    om_dir="$ORCH_DIR/models/$om"
    prompt_file="$CLAUDE_TMP/research-map-prompt-$om-$role.txt"
    {
      echo "Extract THIS model's ($om) diagnosed idioms/fixes for its '$role' role from the material below. Be short and structured: 3-6 bullets max, each stating the failure shape, the fix/lever that worked (or didn't), and whether it was confirmed or single-draw. Skip anything not relevant to '$role'."
      echo
      echo "=== $om — README.md, '$role' role section only ==="
      # Mechanical filter, not a judgment call: the README-shape
      # scaffold guarantees a "## <Role> role: ..." heading per tested
      # role (see check-readme-shape.sh's own pattern) - extract just
      # that section, not the whole file (Setup/other-role sections
      # are noise for this purpose).
      awk -v want="## $display_name role:" '
        index($0, want) == 1 { found=1; print; next }
        found { if (/^## /) exit; print }
      ' "$om_dir/README.md" 2>/dev/null
      echo
      echo "=== $om — history.md (full — no reliable section markers to filter by, and this is usually where the real diagnosis lives) ==="
      [ -f "$om_dir/history.md" ] && cat "$om_dir/history.md"
    } > "$prompt_file"

    schema='{"type":"object","properties":{"summary":{"type":"string"}},"required":["summary"]}'
    out_file="$CLAUDE_TMP/research-map-result-$om-$role.json"
    if ask_claude "$prompt_file" "$schema" "$out_file"; then
      s="$(extract_field "$out_file" summary)"
      if [ -n "${s// /}" ]; then
        summaries="$summaries

### $om
$s"
      fi
    else
      log "WARNING: per-model research extraction failed for $om — skipping it, continuing with the rest"
    fi
  done

  if [ -z "${summaries// /}" ]; then
    log "WARNING: cross-model research got no usable per-model summaries — steering proceeds without it"
    return 1
  fi

  log "cross-model research: reduce step — combining summaries from ${#other_models[@]} model(s)"

  # Reduce: one final call over the SHORT summaries only, never the
  # raw source text again - this call's size is bounded by the number
  # of models times a few bullets each, not by how much history.md
  # content exists in total.
  local reduce_prompt="$CLAUDE_TMP/research-reduce-prompt-$role.txt"
  {
    echo "AGENTS.md's Research phase, cross-model idiom check: below are short per-model summaries of diagnosed idioms/fixes for the SAME role ($role), already extracted from each model's own history.md/README.md. Turn them into a candidate-techniques list for the model about to be steered, \`$MODEL\`. These are hypotheses, not guaranteed fixes — a technique validated on one model has backfired on another before (e.g. STE negative-transferred from deepseek-r1-1.5b to lfm2.5-1.2b-thinking, per AGENTS.md/history.md). State that caveat for every candidate and cite which model it's sourced from."
    echo
    echo "$summaries"
    echo
    echo "Return a markdown list of candidate techniques for \`$MODEL\`'s $role role: which idiom/failure shape it targets, the source model, the technique itself, and the negative-transfer caveat."
  } > "$reduce_prompt"

  local reduce_schema='{"type":"object","properties":{"candidates":{"type":"string"}},"required":["candidates"]}'
  local reduce_out="$CLAUDE_TMP/research-result-$role.json"
  if ! ask_claude "$reduce_prompt" "$reduce_schema" "$reduce_out"; then
    log "WARNING: cross-model research reduce-call failed — steering proceeds without it"
    return 1
  fi

  local candidates
  candidates="$(extract_field "$reduce_out" candidates)"
  if [ -z "${candidates// /}" ]; then
    log "WARNING: cross-model research returned empty — steering proceeds without it"
    return 1
  fi

  {
    echo "# Cross-model research: $role role, candidates for \`$MODEL\`"
    echo
    echo "Generated $(date -u +%Y-%m-%dT%H:%M:%SZ) by bench/loop.sh's Research phase (cross-model idiom check only — external/web research is NOT automated, stays manual). Map-reduce: one extraction call per source model, then one combining call."
    echo "Source models checked: ${other_models[*]}"
    echo
    echo "$candidates"
  } > "$research_file"
  log "cross-model research written: $research_file"
}

# ---------------------------------------------------------------------
# author_override TASK
# Bucket 3b. Writes models/<model-dir>/task-overrides/<task>.md.
# ---------------------------------------------------------------------
author_override() {
  local task="$1"
  log "authoring steering override: $task"

  local prompt_file="$CLAUDE_TMP/override-prompt-$task.txt"
  {
    echo "You are writing a Tier 1 per-task steering override for a small local LLM, per this project's exact convention. This file will be dispatched INSTEAD of the bare task SPEC — write it as a complete, self-contained prompt/instructions for the model under test, not a diff or a note about the change."
    echo
    echo "=== Task SPEC (bare, currently failing) ==="
    cat "$ORCH_DIR/tasks/$task/SPEC.md" 2>/dev/null
    echo
    echo "=== Raw failure output this task produced ==="
    cat "$TMP_DIR/out-$task.txt" 2>/dev/null
    echo
    echo "=== Model's history.md (check for an already-diagnosed idiom/fix pattern before inventing a new one) ==="
    [ -f "$MODEL_DIR/history.md" ] && cat "$MODEL_DIR/history.md"
    echo
    if [ -f "$MODEL_DIR/research-$ROLE.md" ]; then
      echo "=== Cross-model research (candidate techniques from other models — hypotheses, verify before trusting) ==="
      cat "$MODEL_DIR/research-$ROLE.md"
      echo
    fi
    local example
    example="$(find "$OVERRIDES_DIR" -maxdepth 1 -name '*.md' ! -name '.gated-*' 2>/dev/null | head -1)"
    if [ -n "$example" ]; then
      echo "=== Example of an existing override in this model's task-overrides/ (format reference only, different task) ==="
      cat "$example"
    fi
    echo
    echo "Return the complete override file content (what the model under test will actually be dispatched), and separately your rationale (which idiom this targets, why this lever)."
  } > "$prompt_file"

  local schema='{"type":"object","properties":{"override_content":{"type":"string"},"rationale":{"type":"string"}},"required":["override_content","rationale"]}'
  local out_file="$CLAUDE_TMP/override-result-$task.json"
  if ! ask_claude "$prompt_file" "$schema" "$out_file"; then
    log "WARNING: could not author override for $task — leaving bare"
    return 1
  fi

  local content rationale
  content="$(extract_field "$out_file" override_content)"
  rationale="$(extract_field "$out_file" rationale)"
  if [ -z "${content// /}" ]; then
    log "WARNING: claude returned an empty override_content for $task — leaving bare, not writing a blank override"
    return 1
  fi
  printf '%s\n' "$content" > "$OVERRIDES_DIR/$task.md"
  log "override written for $task — rationale: $rationale"
}

# ---------------------------------------------------------------------
# task_lang TASK — csharp or python, by harness marker. Empty if
# unrecognized. Mirrors pure-run.sh's own detection.
# ---------------------------------------------------------------------
task_lang() {
  local task="$1" d
  d="$ORCH_DIR/tasks/$task"
  if find "$d/harness" -maxdepth 1 -name '*.csproj' 2>/dev/null | grep -q .; then
    echo "csharp"
  elif [ -f "$d/harness/requirements.txt" ]; then
    echo "python"
  fi
}

# ---------------------------------------------------------------------
# author_rules LANG FAILING_TASKS...
# Bucket 3b for the code role: steering is per-LANGUAGE
# (models/<model-dir>/rules/<lang>-rules.md, bench.sh's existing
# --rules mechanism, shared across every task of that language), not
# per-task like doc/reason overrides — see pure-run.sh's --test code
# comment. Refines the existing file if one exists, rather than
# starting fresh each round.
# ---------------------------------------------------------------------
author_rules() {
  local lang="$1"; shift
  local failing_tasks="$*"
  log "authoring/refining $lang-rules.md — currently failing: $failing_tasks"

  local rules_dir="$MODEL_DIR/rules"
  mkdir -p "$rules_dir"
  local rules_file="$rules_dir/$lang-rules.md"
  local prompt_file="$CLAUDE_TMP/rules-prompt-$lang.txt"
  {
    echo "You are writing/refining a Tier 1 steering rules file for a small local LLM's $lang code-emission tasks. This file is prepended to EVERY $lang task's bare SPEC (shared across all $lang tasks, not per-task) — write general $lang-emission guidance that helps across tasks, not a fix targeted at one specific task's bug. A blanket rules block that isn't targeted has measurably HURT already-passing tasks elsewhere in this project — keep changes narrow and grounded in the actual errors below, not speculative best-practices."
    echo
    if [ -f "$rules_file" ]; then
      echo "=== Current $lang-rules.md (refine this, don't discard unless the errors below show it's actively wrong) ==="
      cat "$rules_file"
      echo
    fi
    echo "=== Currently failing $lang tasks — bench.sh verdict (compile/test error excerpt) ==="
    for t in $failing_tasks; do
      local latest_cr
      latest_cr="$(ls -t "$REPORTS_DIR"/round-pure-*-"$t".md 2>/dev/null | head -1)"
      [ -f "$latest_cr" ] || continue
      echo "--- $t ---"
      cat "$latest_cr"
      echo
    done
    echo "=== Model's history.md (check for an already-diagnosed idiom/fix pattern before inventing a new one) ==="
    [ -f "$MODEL_DIR/history.md" ] && cat "$MODEL_DIR/history.md"
    echo
    if [ -f "$MODEL_DIR/research-$ROLE.md" ]; then
      echo "=== Cross-model research (candidate techniques from other models — hypotheses, verify before trusting) ==="
      cat "$MODEL_DIR/research-$ROLE.md"
      echo
    fi
    echo "Return the complete $lang-rules.md content (what gets prepended to every $lang task's SPEC at dispatch time), and separately your rationale."
  } > "$prompt_file"

  local schema='{"type":"object","properties":{"rules_content":{"type":"string"},"rationale":{"type":"string"}},"required":["rules_content","rationale"]}'
  local out_file="$CLAUDE_TMP/rules-result-$lang.json"
  if ! ask_claude "$prompt_file" "$schema" "$out_file"; then
    log "WARNING: could not author $lang-rules.md — leaving as-is"
    return 1
  fi

  local content rationale
  content="$(extract_field "$out_file" rules_content)"
  rationale="$(extract_field "$out_file" rationale)"
  if [ -z "${content// /}" ]; then
    log "WARNING: claude returned empty rules_content for $lang — leaving as-is, not writing blank rules"
    return 1
  fi
  printf '%s\n' "$content" > "$rules_file"
  log "$lang-rules.md written — rationale: $rationale"
}

# ---------------------------------------------------------------------
# gate_decision_lang LANG BEFORE_REPORT AFTER_REPORT
# Bucket 2 for the code role: gates the shared $lang-rules.md (not a
# single task), matching author_rules' granularity.
# ---------------------------------------------------------------------
gate_decision_lang() {
  local lang="$1" before="$2" after="$3"
  local prompt_file="$CLAUDE_TMP/gate-lang-prompt-$lang.txt"
  {
    echo "AGENTS.md's Tier 1 'gate on run 2' rule, applied at the language level (the lever here is the shared $lang-rules.md, not a per-task override): after the first real steering attempt, only keep investing (up to the 4-run cap) if $lang tasks overall show SOME real partial improvement. Flat or regressed overall gets gated out — revert $lang-rules.md, stop."
    echo
    echo "=== $lang task rows — before this round's rules change ==="
    grep -E "^\| \`code-$lang" "$before" 2>/dev/null
    echo
    echo "=== $lang task rows — after this round's rules change ==="
    grep -E "^\| \`code-$lang" "$after" 2>/dev/null
    echo
    echo "Did $lang tasks overall show real partial improvement, or are they flat/regressed? Answer CONTINUE or GATE_OUT."
  } > "$prompt_file"

  local schema='{"type":"object","properties":{"decision":{"type":"string","enum":["CONTINUE","GATE_OUT"]},"reason":{"type":"string"}},"required":["decision","reason"]}'
  local out_file="$CLAUDE_TMP/gate-lang-result-$lang.json"
  if ! ask_claude "$prompt_file" "$schema" "$out_file"; then
    log "WARNING: gate decision call failed for $lang — defaulting to CONTINUE (fail open, budget cap still applies)"
    echo "CONTINUE"
    return
  fi
  local decision reason
  decision="$(extract_field "$out_file" decision)"
  reason="$(extract_field "$out_file" reason)"
  log "gate decision for $lang: $decision — $reason"
  echo "$decision"
}

# ---------------------------------------------------------------------
# gate_decision TASK BEFORE_REPORT AFTER_REPORT
# Bucket 2. Prints CONTINUE or GATE_OUT to stdout.
# ---------------------------------------------------------------------
gate_decision() {
  local task="$1" before="$2" after="$3"
  local prompt_file="$CLAUDE_TMP/gate-prompt-$task.txt"
  {
    echo "AGENTS.md's Tier 1 'gate on run 2' rule: after the first real steering attempt, only keep investing (up to the 4-run cap) in a task showing SOME real partial improvement (even short of a full PASS). A task flat or regressed after run 1 gets gated out - stop, revert to bare, move on."
    echo
    echo "Task: $task"
    echo "=== Raw output BEFORE this round's steering attempt ==="
    grep -A 3 "\`$task\`" "$before" 2>/dev/null || echo "(no prior data)"
    echo
    echo "=== Raw output AFTER this round's steering attempt ==="
    cat "$TMP_DIR/out-$task.txt" 2>/dev/null
    echo
    echo "Did this task show real partial improvement (even short of a full PASS), or is it flat/regressed? Answer CONTINUE (keep investing, up to the 4-run cap) or GATE_OUT (revert to bare, stop spending budget on it)."
  } > "$prompt_file"

  local schema='{"type":"object","properties":{"decision":{"type":"string","enum":["CONTINUE","GATE_OUT"]},"reason":{"type":"string"}},"required":["decision","reason"]}'
  local out_file="$CLAUDE_TMP/gate-result-$task.json"
  if ! ask_claude "$prompt_file" "$schema" "$out_file"; then
    log "WARNING: gate decision call failed for $task — defaulting to CONTINUE (fail open, budget cap still applies)"
    echo "CONTINUE"
    return
  fi
  local decision reason
  decision="$(extract_field "$out_file" decision)"
  reason="$(extract_field "$out_file" reason)"
  log "gate decision for $task: $decision — $reason"
  echo "$decision"
}

fail_tasks() {
  local report_file="$1"
  python3 -c "
import sys
sys.path.insert(0, '$SELF_DIR/lib')
from report_parse import parse_verdicts
v = parse_verdicts(sys.argv[1])
print('\n'.join(t for t, r in v.items() if r == 'FAIL'))
" "$report_file"
}

is_gated() {
  local task="$1"
  [ -f "$GATED_FILE" ] && grep -qxF "$task" "$GATED_FILE"
}

run_report() {
  if ! bash "$SELF_DIR/report.sh" "$MODEL" "$ROLE" "$BACKEND" "$PORT" >&2; then
    log "FATAL: report.sh failed (infra-level - service didn't come back healthy, or produced no results). Stopping, not continuing on a stale report."
    exit 1
  fi
  ls -1t "$REPORTS_DIR"/report-"$ROLE"-*.md | head -1
}

# =======================================================================
# Main — guarded so this file can be `source`d for testing individual
# functions (e.g. complete_report_findings) without triggering a real
# dispatch/report.sh/Confirm run.
# =======================================================================
if [ "${BASH_SOURCE[0]}" != "${0}" ]; then
  return 0 2>/dev/null || true
fi

log "starting: model=$MODEL role=$ROLE max_rounds=$MAX_ROUNDS"

LATEST="$(ls -1t "$REPORTS_DIR"/report-"$ROLE"-*.md 2>/dev/null | head -1)"
if [ -z "$LATEST" ]; then
  log "no prior report — Phase 1 reference run"
  LATEST="$(run_report)"
else
  log "prior work found — resuming from $(basename "$LATEST")"
fi
complete_report_findings "$LATEST"
commit_if_changed "$MODEL role=$ROLE: loop.sh Phase 1/resume report"

FAILS="$(fail_tasks "$LATEST")"
if [ -z "$FAILS" ]; then
  log "no FAIL tasks — role already passing, skipping Tier 1 (and Research, nothing to steer)"
else
  log "FAIL tasks: $(echo "$FAILS" | tr '\n' ' ')"

  log "=== Research phase (cross-model idiom check) ==="
  cross_model_research "$ROLE"
  commit_if_changed "$MODEL role=$ROLE: loop.sh Research phase (cross-model idiom check)"

  for round in $(seq 1 "$MAX_ROUNDS"); do
    ACTIVE="$(fail_tasks "$LATEST" | while read -r t; do is_gated "$t" || echo "$t"; done)"
    if [ -z "$ACTIVE" ]; then
      log "round $round: no active FAIL tasks left (all passing or gated) — stopping Tier 1"
      break
    fi
    log "=== round $round/$MAX_ROUNDS — active: $(echo "$ACTIVE" | tr '\n' ' ') ==="

    if [ "$ROLE" = "code" ]; then
      # Steering granularity for code is per-LANGUAGE (shared
      # rules file), not per-task — group active tasks and author/
      # refine one rules file per language present in this round.
      LANGS="$(for t in $ACTIVE; do task_lang "$t"; done | sort -u)"
      for lang in $LANGS; do
        [ -n "$lang" ] || continue
        LANG_TASKS="$(for t in $ACTIVE; do [ "$(task_lang "$t")" = "$lang" ] && echo "$t"; done)"
        author_rules "$lang" $LANG_TASKS
      done
    else
      while read -r t; do
        [ -z "$t" ] && continue
        [ -f "$OVERRIDES_DIR/$t.md" ] || author_override "$t"
      done <<< "$ACTIVE"
    fi

    PREV="$LATEST"
    LATEST="$(run_report)"
    complete_report_findings "$LATEST"
    commit_if_changed "$MODEL role=$ROLE: loop.sh Tier 1 round $round"

    if [ "$round" -eq 2 ]; then
      # One-time checkpoint (AGENTS.md: "gate on run 2"), not a
      # per-round re-evaluation - tasks/languages that pass this once
      # continue automatically through their remaining budget.
      STILL_FAILING="$(fail_tasks "$LATEST")"
      if [ "$ROLE" = "code" ]; then
        LANGS="$(for t in $ACTIVE; do task_lang "$t"; done | sort -u)"
        for lang in $LANGS; do
          [ -n "$lang" ] || continue
          STILL_FAILING_LANG=0
          for t in $STILL_FAILING; do [ "$(task_lang "$t")" = "$lang" ] && STILL_FAILING_LANG=1; done
          [ "$STILL_FAILING_LANG" -eq 0 ] && continue
          DECISION="$(gate_decision_lang "$lang" "$PREV" "$LATEST" | tail -1)"
          if [ "$DECISION" = "GATE_OUT" ]; then
            rm -f "$MODEL_DIR/rules/$lang-rules.md"
            for d in "$ORCH_DIR"/tasks/code-*/; do
              bn="$(basename "$d")"
              [ "$(task_lang "$bn")" = "$lang" ] && echo "$bn" >> "$GATED_FILE"
            done
            log "$lang gated out — $lang-rules.md reverted to bare"
          fi
        done
      else
        while read -r t; do
          [ -z "$t" ] && continue
          echo "$ACTIVE" | grep -qxF "$t" || continue
          echo "$STILL_FAILING" | grep -qxF "$t" || continue
          DECISION="$(gate_decision "$t" "$PREV" "$LATEST" | tail -1)"
          if [ "$DECISION" = "GATE_OUT" ]; then
            rm -f "$OVERRIDES_DIR/$t.md"
            echo "$t" >> "$GATED_FILE"
            log "$t gated out — reverted to bare"
          fi
        done <<< "$STILL_FAILING"
      fi
      commit_if_changed "$MODEL role=$ROLE: loop.sh round $round gate decisions"
    fi
  done
fi

log "=== Tier 2 gate ==="
bash "$SELF_DIR/tier2-gate.sh" "$LATEST"
GATE_EXIT=$?
if [ "$GATE_EXIT" -eq 0 ]; then
  log "GATE: GO — Tier 2 generalist search is NOT automated by this script. Run it manually/via Claude Code before Confirm, per AGENTS.md."
else
  log "GATE: SKIP — proceeding to Confirm on the Tier 1 result."
fi

log "=== Confirm ==="
bash "$SELF_DIR/confirm.sh" "$MODEL" "$ROLE" "$BACKEND" "$PORT"
commit_if_changed "$MODEL role=$ROLE: loop.sh Confirm (3 draws)"

log "=== loop.sh done ==="
log "Automated: Phase 1/resume, Tier 1 steering rounds (up to $MAX_ROUNDS), gate-on-run-2 decisions, Tier 2 gate, Confirm."
log "NOT automated — do these manually next: Tier 2 generalist search (if GATE said GO), Performance run, Final report."
