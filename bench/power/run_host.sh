#!/usr/bin/env bash
# Usage: RUN_DIR=... run_host.sh SSH_ALIAS IP MODEL MODE [MODE...]
# One idle baseline, then one mixed set (gen + prefill alternating) per reasoning mode, hard stop at SET_S.
set -u
SCRIPTS=$(cd "$(dirname "$0")" && pwd)
H=$1; IP=$2; MODEL=$3; shift 3; MODES="$*"
OUT=${RUN_DIR:?}; mkdir -p "$OUT"
PW=$(grep -oP '^HOMELAB_PEPPE_SUDO_PASSWORD=\K.*' ~/.env | tr -d "\"'")
SET_S=120; COOL_S=10; IDLE_S=40
PH=$OUT/phases.jsonl; : > "$PH"
mark() { printf '{"phase":"%s","event":"%s","ts":%s}\n' "$1" "$2" "$(date +%s.%N)" >> "$PH"; }

scp -q $SCRIPTS/sampler.py $SCRIPTS/start_sampler.sh "$H:/tmp/"
echo "$PW" | ssh "$H" "sudo -S -p '' bash /tmp/start_sampler.sh"
ssh "$H" 'nproc; lscpu | grep "Model name"; uname -r' > "$OUT/host.txt"
curl -s "http://$IP:11434/props" | python3 -c 'import json,sys; d=json.load(sys.stdin); d.pop("chat_template",None); print(json.dumps(d,indent=1))' > "$OUT/props.json"
sleep 3

mark idle start; sleep $IDLE_S; mark idle end
for M in $MODES; do
  mark "$M" start
  python3 $SCRIPTS/loadgen.py "$IP" "$MODEL" "$M" $SET_S "$OUT/$M.jsonl"
  mark "$M" end
  sleep $COOL_S
done

echo "$PW" | ssh "$H" "sudo -S -p '' pkill -f 'python3 /tmp/[s]ampler.py'"
sleep 2; scp -q "$H:/tmp/power.csv" "$OUT/power.csv"
echo "DONE $H $(basename $OUT) $(date -Is)"
