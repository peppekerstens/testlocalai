#!/usr/bin/env bash
# Heavier-model REVIEW gate. NOT part of the normal dispatch pipeline.
# Usage: review.sh <prompt-file> <output-file>
#   prompt-file : file containing the review prompt (spec + acceptance + diff)
#   output-file : where the review verdict is written
#
# The ONLY heavier review model permitted is ornith:9b on the LAN Ollama
# (default host 192.168.2.187). Override with REVIEW_HOST / REVIEW_PORT.
# The other permitted "heavier" reviewer is the orchestrator itself (manual
# review) — that path does not use this script. NO OTHER models.
#
# Runs ONLY after critical phases (review gates). Reviews never edit code;
# they only produce a verdict.

set -euo pipefail

PROMPT_FILE="$1"
OUT_FILE="$2"

MODEL="ornith:9b"
HOST="${REVIEW_HOST:-192.168.2.187}"
PORT="${REVIEW_PORT:-11434}"
URL="http://${HOST}:${PORT}/api/generate"

PROMPT_SIZE=$(wc -c < "$PROMPT_FILE")
if [ "$PROMPT_SIZE" -gt 48000 ]; then
  echo "ERROR: review prompt too large ($PROMPT_SIZE bytes) for a 16K-context model" >&2
  exit 2
fi

python3 - "$MODEL" "$PROMPT_FILE" "$URL" <<'PY' > "$OUT_FILE"
import json, re, sys, urllib.request

model, prompt_file, url = sys.argv[1], sys.argv[2], sys.argv[3]
with open(prompt_file, encoding="utf-8") as f:
    prompt = f.read()

body = json.dumps({
    "model": model,
    "prompt": prompt,
    "stream": False,
    "options": {"temperature": 0.0, "num_ctx": 16384},
})

req = urllib.request.Request(
    url, data=body.encode(), headers={"Content-Type": "application/json"}
)
with urllib.request.urlopen(req, timeout=1800) as resp:
    data = json.load(resp)

response = data["response"]

# strip thinking blocks if any
response = re.sub(r"<think>.*?</think>", "", response, flags=re.S).strip()

sys.stdout.write(response)
PY

echo "review complete: $MODEL -> $OUT_FILE"
