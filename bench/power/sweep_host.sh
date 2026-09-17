#!/usr/bin/env bash
# Usage: sweep_host.sh SSH_ALIAS IP MODEL "CTX:mode,mode CTX:mode,mode ..."
# The first CTX must be the production value. Each context: restart llama-chat, wait for health, run its modes.
set -u
H=$1; IP=$2; MODEL=$3; PLAN=$4
PROD=${PLAN%%:*}
PW=$(grep -oP '^HOMELAB_PEPPE_SUDO_PASSWORD=\K.*' ~/.env | tr -d "\"'")
BASE=${POWER_BASE:-$HOME/llm-power}
SCRIPTS=$(cd "$(dirname "$0")" && pwd)
scp -q $SCRIPTS/setctx.sh "$H:/tmp/setctx.sh"
wait_healthy() {
  for _ in $(seq 1 120); do
    [ "$(curl -s -o /dev/null -w '%{http_code}' http://$IP:11434/health)" = 200 ] && return 0; sleep 5
  done; return 1
}
for ITEM in $PLAN; do
  C=${ITEM%%:*}; MODES=${ITEM#*:}; MODES=${MODES//,/ }
  ARG=$C; [ "$C" = "$PROD" ] && ARG=prod
  echo "$(date -Is) $H ctx=$C modes=$MODES: restart"
  echo "$PW" | ssh "$H" "sudo -S -p '' bash /tmp/setctx.sh $ARG"
  if ! wait_healthy; then echo "$(date -Is) $H ctx=$C: NOT HEALTHY, skipped"; continue; fi
  N=$(curl -s http://$IP:11434/props | python3 -c "import json,sys; print(json.load(sys.stdin)['default_generation_settings']['n_ctx'])")
  echo "$(date -Is) $H ctx=$C: healthy, n_ctx per slot=$N"
  sleep 10
  RUN_DIR=$BASE/raw/$H/ctx$C $SCRIPTS/run_host.sh "$H" "$IP" "$MODEL" $MODES
done
echo "$(date -Is) $H: restore production"
echo "$PW" | ssh "$H" "sudo -S -p '' bash /tmp/setctx.sh prod"
wait_healthy && curl -s http://$IP:11434/props | python3 -c "import json,sys; print('restored n_ctx per slot', json.load(sys.stdin)['default_generation_settings']['n_ctx'])"
echo "SWEEP DONE $H $(date -Is)"
