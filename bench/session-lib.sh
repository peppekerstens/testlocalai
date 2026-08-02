# Shared helpers for session-start.sh / session-stop.sh. Sourced, not run
# directly — no shebang, no set -e (callers control that).

SESSION_STATE_FILE="${SESSION_STATE_FILE:-$BENCH_DIR/.session-state.json}"
DRY_RUN="${SESSION_DRY_RUN:-0}"

# run_cmd <description> -- <command...>
# Executes <command...> unless SESSION_DRY_RUN=1, in which case it only
# prints what would have run. Fails the caller's script (set -e) if the
# real command fails — deliberate: don't silently continue after a
# systemctl/pkill failure on a script that manipulates real services.
run_cmd() {
  local desc="$1"
  shift
  [ "${1:-}" = "--" ] && shift
  if [ "$DRY_RUN" = "1" ]; then
    echo "DRY-RUN: $desc: $*" >&2
    return 0
  fi
  echo "==> $desc" >&2
  "$@"
}

# llama_units — list every systemd --user unit file matching llama-server*
# (not just the two documented ones), so a future per-model unit is picked
# up automatically.
llama_units() {
  systemctl --user list-unit-files --type=service --no-legend 2>/dev/null \
    | awk '{print $1}' | grep '^llama-server' || true
}

# llama_unit_info <unit> — prints "<unit> <active:0/1> <alias> <port>",
# parsed from the unit's ExecStart line (--alias / --port flags).
llama_unit_info() {
  local unit="$1"
  local active=0
  if systemctl --user is-active --quiet "$unit" 2>/dev/null; then
    active=1
  fi
  local execstart
  execstart="$(systemctl --user cat "$unit" 2>/dev/null | grep -m1 '^ExecStart=' || true)"
  local alias port
  alias="$(echo "$execstart" | grep -oP -- '--alias\s+\S+' | awk '{print $2}' || true)"
  port="$(echo "$execstart" | grep -oP -- '--port\s+\S+' | awk '{print $2}' || true)"
  echo "$unit $active ${alias:-unknown} ${port:-unknown}"
}

# ollama_running — prints 1/0
ollama_running() {
  if pgrep -x ollama >/dev/null 2>&1; then echo 1; else echo 0; fi
}

# wait_for_health <url> [timeout_s]
wait_for_health() {
  local url="$1" timeout="${2:-30}" waited=0
  while [ "$waited" -lt "$timeout" ]; do
    if curl -fsS --max-time 2 "$url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
    waited=$((waited + 1))
  done
  return 1
}
