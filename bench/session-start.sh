#!/usr/bin/env bash
# Prepare an exclusive, single-provider local LLM environment for a bench
# session: stop every other detected local hoster, start only the target
# model, warm it up, and snapshot prior state so session-stop.sh can
# restore it afterward.
#
# This is one-time lifecycle setup, not a per-dispatch check — bench.sh and
# pure-run.sh already verify (via dispatch.sh) that the expected model is
# loaded before every single call, so this script doesn't need to re-check
# that after starting things; it just needs to get the environment there.
#
# Usage: bash bench/session-start.sh [model] [backend]
#   model   : model tag to test (default: $BENCH_MODEL or qwen2.5-coder:1.5b)
#   backend : llamacpp (default) | ollama
#             llamacpp needs a systemd --user unit whose ExecStart has a
#             matching --alias <model>; ollama has no local service
#             definition here, so it's started best-effort via `ollama serve`.
#
# Env:
#   SESSION_DRY_RUN=1  print planned actions, change nothing
#   SESSION_WARMUP=0   skip the warm-up ping (default: on)

set -euo pipefail

BENCH_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=session-lib.sh
source "$BENCH_DIR/session-lib.sh"

MODEL="${1:-${BENCH_MODEL:-qwen2.5-coder:1.5b}}"
BACKEND="${2:-${DISPATCH_BACKEND:-llamacpp}}"
WARMUP="${SESSION_WARMUP:-1}"

if [ -f "$SESSION_STATE_FILE" ]; then
  echo "ERROR: a session is already active ($SESSION_STATE_FILE exists)." >&2
  echo "Run bench/session-stop.sh first, or rm the state file if it's stale." >&2
  exit 1
fi

echo "==> discovering current local LLM hosters"

UNIT_ROWS=()
while IFS= read -r unit; do
  [ -z "$unit" ] && continue
  UNIT_ROWS+=("$(llama_unit_info "$unit")")
done < <(llama_units)

OLLAMA_WAS_RUNNING="$(ollama_running)"

# --- resolve target ---
TARGET_UNIT=""
TARGET_PORT=""
if [ "$BACKEND" = "llamacpp" ]; then
  for row in "${UNIT_ROWS[@]:-}"; do
    [ -z "$row" ] && continue
    read -r u _active alias port <<<"$row"
    if [ "$alias" = "$MODEL" ]; then
      TARGET_UNIT="$u"
      TARGET_PORT="$port"
    fi
  done
  if [ -z "$TARGET_UNIT" ]; then
    echo "ERROR: no systemd --user unit found with --alias $MODEL." >&2
    echo "Define one first (see docs/SETUP.md §5, 'Running llama-server as a service')." >&2
    exit 1
  fi
elif [ "$BACKEND" = "ollama" ]; then
  TARGET_PORT="${OLLAMA_PORT:-11434}"
else
  echo "ERROR: unknown backend '$BACKEND' (llamacpp|ollama)" >&2
  exit 1
fi

# --- snapshot BEFORE changing anything ---
# Skipped entirely under DRY_RUN: writing the real state file here would
# make session-start.sh think a session is already active on the very
# next (non-dry-run) invocation, even though nothing was actually
# started — "preview, change nothing" has to mean the state file too.
if [ "$DRY_RUN" = "1" ]; then
  echo "DRY-RUN: would snapshot state to $SESSION_STATE_FILE" >&2
else
  {
    python3 - "$SESSION_STATE_FILE" "$MODEL" "$BACKEND" "$TARGET_UNIT" "$TARGET_PORT" "$OLLAMA_WAS_RUNNING" "${UNIT_ROWS[@]:-}" <<'PY'
import json, sys, datetime

state_file, model, backend, target_unit, target_port, ollama_was_running, *rows = sys.argv[1:]
units = []
for row in rows:
    if not row:
        continue
    u, active, alias, port = row.split()
    units.append({"unit": u, "was_active": active == "1", "alias": alias, "port": port})
state = {
    "timestamp": datetime.datetime.now().isoformat(),
    "target": {"model": model, "backend": backend, "unit": target_unit, "port": target_port},
    "prior_llama_units": units,
    "ollama_was_running": ollama_was_running == "1",
    "warmup": None,
}
with open(state_file, "w") as f:
    json.dump(state, f, indent=2)
PY
  }
  echo "==> state snapshotted to $SESSION_STATE_FILE"
fi

# --- stop everything currently active ---
for row in "${UNIT_ROWS[@]:-}"; do
  [ -z "$row" ] && continue
  read -r u active alias port <<<"$row"
  if [ "$active" = "1" ]; then
    run_cmd "stop $u (was serving $alias on :$port)" -- systemctl --user stop "$u"
  fi
done
if [ "$OLLAMA_WAS_RUNNING" = "1" ]; then
  run_cmd "stop ollama" -- pkill -TERM -x ollama || true
  sleep 1
fi

# --- start target ---
if [ "$BACKEND" = "llamacpp" ]; then
  run_cmd "start $TARGET_UNIT ($MODEL on :$TARGET_PORT)" -- systemctl --user start "$TARGET_UNIT"
  if [ "$DRY_RUN" != "1" ]; then
    wait_for_health "http://localhost:$TARGET_PORT/health" 30 \
      || {
        echo "ERROR: $TARGET_UNIT did not become healthy within 30s" >&2
        exit 1
      }
  fi
else
  run_cmd "start ollama serve" -- bash -c 'nohup ollama serve >/dev/null 2>&1 & disown'
  if [ "$DRY_RUN" != "1" ]; then
    wait_for_health "http://localhost:$TARGET_PORT/api/tags" 30 \
      || {
        echo "ERROR: ollama did not become healthy within 30s" >&2
        exit 1
      }
  fi
fi

# --- warm-up: absorbs first-call CUDA/context warmup, confirms it answers ---
if [ "$WARMUP" = "1" ] && [ "$DRY_RUN" != "1" ]; then
  echo "==> warm-up ping"
  TMP_PROMPT="$(mktemp)"
  TMP_OUT="$(mktemp)"
  echo "Reply with exactly: OK" >"$TMP_PROMPT"
  START_NS=$(date +%s%N)
  if DISPATCH_BACKEND="$BACKEND" LLAMACPP_PORT="$TARGET_PORT" OLLAMA_PORT="$TARGET_PORT" \
    bash "$BENCH_DIR/dispatch.sh" "$MODEL" "$TMP_PROMPT" "$TMP_OUT" >/dev/null; then
    END_NS=$(date +%s%N)
    LATENCY_MS=$(((END_NS - START_NS) / 1000000))
    if [ -s "$TMP_OUT" ]; then
      echo "==> warm-up OK (${LATENCY_MS}ms): $(cat "$TMP_OUT")"
      python3 - "$SESSION_STATE_FILE" "$LATENCY_MS" <<'PY'
import json, sys
path, ms = sys.argv[1], int(sys.argv[2])
with open(path) as fh:
    state = json.load(fh)
state["warmup"] = {"ok": True, "latency_ms": ms}
with open(path, "w") as fh:
    json.dump(state, fh, indent=2)
PY
    else
      echo "WARNING: warm-up returned empty output" >&2
    fi
  else
    echo "WARNING: warm-up dispatch failed" >&2
  fi
  rm -f "$TMP_PROMPT" "$TMP_OUT"
fi

echo "==> session ready: $MODEL via $BACKEND on :$TARGET_PORT"
echo "==> run bench/session-stop.sh when the testing session is done"
