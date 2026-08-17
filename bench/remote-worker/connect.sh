#!/usr/bin/env bash
# Quick SSH into the remote worker host using bench/remote-worker/.env
# (see .env.example / docs/REMOTE-WSL2-SETUP.md for setup).
#
# Usage:
#   connect.sh [wsl|win] [command...]
#
# "wsl" (default) -> WSL2's own sshd (bash shell).
# "win"           -> Windows-side sshd (cmd.exe shell).
# With a trailing command, runs it non-interactively and exits instead
# of opening an interactive session.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: $ENV_FILE not found — copy .env.example to .env and fill in your values (see docs/REMOTE-WSL2-SETUP.md)" >&2
  exit 1
fi
set -a
source "$ENV_FILE"
set +a

: "${REMOTE_WORKER_HOST:?REMOTE_WORKER_HOST not set in .env}"
: "${REMOTE_WORKER_USER:?REMOTE_WORKER_USER not set in .env}"
: "${REMOTE_WORKER_SSH_KEY:?REMOTE_WORKER_SSH_KEY not set in .env}"

TARGET="wsl"
if [[ "${1:-}" == "wsl" || "${1:-}" == "win" ]]; then
  TARGET="$1"
  shift
fi

case "$TARGET" in
  wsl) PORT="${REMOTE_WORKER_PORT_WSL:-2222}" ;;
  win) PORT="${REMOTE_WORKER_PORT_WIN:-22}" ;;
esac

# expand a leading ~ in the key path (not done by the shell inside .env)
KEY="${REMOTE_WORKER_SSH_KEY/#\~/$HOME}"

exec ssh -p "$PORT" -i "$KEY" -o StrictHostKeyChecking=accept-new \
  "${REMOTE_WORKER_USER}@${REMOTE_WORKER_HOST}" "$@"
