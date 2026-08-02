#!/usr/bin/env bash
# Restore whatever local LLM hoster state was active before session-start.sh
# ran. Always asks for confirmation before touching anything — if you're
# not done testing yet, answer no and keep going.
#
# Usage: bash bench/session-stop.sh
# Env: SESSION_DRY_RUN=1 to preview without acting.

set -euo pipefail

BENCH_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=session-lib.sh
source "$BENCH_DIR/session-lib.sh"

if [ ! -f "$SESSION_STATE_FILE" ]; then
  echo "No active session found ($SESSION_STATE_FILE missing) — nothing to restore." >&2
  exit 1
fi

echo "=== Session snapshot ==="
python3 <<PY
import json
with open("$SESSION_STATE_FILE") as f:
    s = json.load(f)
print("Started:", s["timestamp"])
print("Target:", s["target"]["model"], "via", s["target"]["backend"], "on :" + str(s["target"]["port"]))
if s.get("warmup"):
    print("Warm-up:", s["warmup"])
print("Prior llama.cpp units:")
if s["prior_llama_units"]:
    for u in s["prior_llama_units"]:
        status = "ACTIVE" if u["was_active"] else "inactive"
        print(f"  - {u['unit']} ({u['alias']} :{u['port']}) was {status}")
else:
    print("  (none found)")
print("Ollama was running before:", s["ollama_was_running"])
PY

read -r -p "Testing session complete? Stop the test model and restore previous state? [y/N] " REPLY
if [ "${REPLY,,}" != "y" ]; then
  echo "Leaving the test model running. Re-run bench/session-stop.sh when you're done."
  exit 0
fi

TARGET_BACKEND="$(python3 -c "import json; print(json.load(open('$SESSION_STATE_FILE'))['target']['backend'])")"
TARGET_UNIT="$(python3 -c "import json; print(json.load(open('$SESSION_STATE_FILE'))['target']['unit'] or '')")"

if [ "$TARGET_BACKEND" = "llamacpp" ] && [ -n "$TARGET_UNIT" ]; then
  run_cmd "stop $TARGET_UNIT (test model)" -- systemctl --user stop "$TARGET_UNIT"
elif [ "$TARGET_BACKEND" = "ollama" ]; then
  run_cmd "stop ollama (test model)" -- pkill -TERM -x ollama || true
  sleep 1
fi

# --- restore prior llama.cpp units that were active before ---
while IFS= read -r unit; do
  [ -z "$unit" ] && continue
  run_cmd "restore $unit" -- systemctl --user start "$unit"
done < <(python3 -c "
import json
s = json.load(open('$SESSION_STATE_FILE'))
for u in s['prior_llama_units']:
    if u['was_active']:
        print(u['unit'])
")

# --- restore ollama, best-effort (no service definition on this host) ---
OLLAMA_WAS_RUNNING="$(python3 -c "import json; print(1 if json.load(open('$SESSION_STATE_FILE'))['ollama_was_running'] else 0)")"
if [ "$OLLAMA_WAS_RUNNING" = "1" ]; then
  run_cmd "restore ollama (best-effort — no service definition on this host)" \
    -- bash -c 'nohup ollama serve >/dev/null 2>&1 & disown'
fi

if [ "$DRY_RUN" != "1" ]; then
  mv "$SESSION_STATE_FILE" "$SESSION_STATE_FILE.last"
  echo "==> previous state restored; session record archived to $SESSION_STATE_FILE.last"
else
  echo "==> DRY-RUN: state file left in place"
fi
