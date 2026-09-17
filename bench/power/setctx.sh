#!/usr/bin/env bash
# Run as root on the LLM host. Usage: setctx.sh CTX   (CTX=prod removes the override)
set -eu
D=/etc/systemd/system/llama-chat.service.d; F=$D/zz-ctx-test.conf
if [ "$1" = prod ]; then
  rm -f "$F"
else
  mkdir -p "$D"
  CMD=$(systemctl cat llama-chat.service | grep '^ExecStart=/' | tail -1 | sed "s/--ctx-size [0-9]*/--ctx-size $1/")
  printf '[Service]\nExecStart=\n%s\n' "$CMD" > "$F"
fi
systemctl daemon-reload
systemctl restart llama-chat.service
