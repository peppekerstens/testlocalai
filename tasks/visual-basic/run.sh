#!/usr/bin/env bash
# Standalone dispatch + verify for this one visual-* task. bench/dispatch.sh
# has no image-passing path yet (confirmed in
# models/lfm2.5-vl-450m/README.md step 5 — real, non-trivial plumbing, not
# done project-wide) — this script exists to prove the visual role end to
# end for at least one model+task pair without waiting on that plumbing.
#
# Uses qwen3.8-27b-gsq-rco on gaming-b650, NOT the lfm2.5-vl-450m scaffold
# in models/lfm2.5-vl-450m/ (that model is still undownloaded — see that
# file). gaming-b650's GSQ-RCO llama-server already has a real, tested
# mmproj (vision projector) wired in — see
# ai-stack/gaming-b650-llamacpp/README.md.
#
# Usage: ./run.sh [host:port] [model-alias]
#   defaults match the parallel-context GSQ-RCO service documented in
#   ai-stack/gaming-b650-llamacpp/README.md's "Parallel-context test tier"
#   section — that service is NOT running by default (it and the primary
#   qwen3.8-27b Q6_K service cannot both fit on this GPU at once, see that
#   README), so start it first:
#     ssh gaming-b650 sudo systemctl start llama-chat-gsq-rco.service
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

HOSTPORT="${1:-192.168.2.186:11500}"
MODEL="${2:-qwen3.8-27b-gsq-rco}"
URL="http://${HOSTPORT}/v1/chat/completions"
OUT="out.txt"

IMG_B64=$(base64 -w0 fixture.png)

BODY=$(python3 - "$MODEL" "$IMG_B64" <<'PY'
import json, sys
model, img_b64 = sys.argv[1], sys.argv[2]
spec = open("SPEC.md", encoding="utf-8").read()
body = {
    "model": model,
    "messages": [{
        "role": "user",
        "content": [
            {"type": "text", "text": spec},
            {"type": "image_url", "image_url": {"url": f"data:image/png;base64,{img_b64}"}},
        ],
    }],
    "temperature": 0.2,
    "max_tokens": 512,
    "reasoning_effort": "low",
}
print(json.dumps(body))
PY
)

echo "-> dispatching to $URL (model=$MODEL)"
RESPONSE=$(curl -s -m 120 "$URL" -H 'Content-Type: application/json' -d "$BODY")

python3 - "$RESPONSE" "$OUT" <<'PY'
import json, sys
resp, out_path = sys.argv[1], sys.argv[2]
data = json.loads(resp)
if "choices" not in data:
    sys.stderr.write(f"ERROR: unexpected response: {resp[:500]}\n")
    sys.exit(1)
msg = data["choices"][0]["message"]
content = (msg.get("content") or "").strip()
with open(out_path, "w", encoding="utf-8") as f:
    f.write(content)
timings = data.get("timings") or {}
tokens = {
    "prompt_tokens": data.get("usage", {}).get("prompt_tokens"),
    "completion_tokens": data.get("usage", {}).get("completion_tokens"),
    "finish_reason": data["choices"][0].get("finish_reason"),
    "prompt_tokens_per_second": timings.get("prompt_per_second"),
    "predicted_tokens_per_second": timings.get("predicted_per_second"),
}
with open(out_path + ".tokens.json", "w", encoding="utf-8") as f:
    json.dump(tokens, f, indent=2)
print(f"-> wrote {out_path}")
print(json.dumps(tokens, indent=2))
PY

echo "-> verifying"
bash verify.sh "$OUT"
