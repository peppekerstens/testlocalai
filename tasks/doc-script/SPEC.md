SURGICAL-EDIT DISCIPLINE — this task is a literal find-and-replace edit
on the exact text given, not a rewrite from your own knowledge:

- Copy the given document/script character-for-character as your
  starting point. Do not regenerate it from what you already know about
  similar code/docs — use the exact names, SDKs, and error text given in
  the source text below, even if a different name feels more familiar.
- For each numbered EDIT, locate the exact FIND text inside your copy
  and replace it with the exact REPLACE text given. After all edits are
  applied, none of the FIND text may remain anywhere in your output.
- The [DOC_START]/[SCRIPT_START]/[DOC_END]/[SCRIPT_END] markers exist
  only to show you where the source text begins and ends — never write
  them into your own output.
- Output nothing except the edited document/script itself: no
  commentary, no "Here is the edited version", no restating the list of
  edits after the document.
ROLE: You are a careful document editor. Copy the bash script below
byte-for-byte, then apply the two FIND→REPLACE edits inside it. The result
must remain a valid bash script that passes `bash -n`. Do not reword,
reorder, merge, or add anything outside the edits.

The script begins at the [SCRIPT_START] marker and ends at the [SCRIPT_END]
marker. The markers are delimiters ONLY — never copy them into the output.

[SCRIPT_START]

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .env ]; then
  echo "Error: .env file not found. Copy .env.example to .env and fill in your credentials."
  exit 1
fi

set -a
source .env
set +a

required_vars=("CW_COMPANY_ID" "CW_PUBLIC_KEY" "CW_PRIVATE_KEY" "CW_CLIENT_ID")
for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "Error: $var is not set in .env"
    exit 1
  fi
done

PORT="${PORT:-3000}"
SERVER_ENTRYPOINT="$SCRIPT_DIR/dist/index.js"

echo "Building..."
npm run build

echo "Starting server on port $PORT..."
LOG_FILE="$(mktemp)"
node "$SERVER_ENTRYPOINT" > "$LOG_FILE" 2>&1 &
SERVER_PID=$!

cleanup() {
  echo "Stopping server (PID: $SERVER_PID)..."
  kill "$SERVER_PID" 2>/dev/null || true
  rm -f "$LOG_FILE"
}
trap cleanup EXIT

echo "Waiting for server to start..."
BASE_URL="http://127.0.0.1:$PORT"
ready=false
for _ in $(seq 1 90); do
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "Error: server process exited before becoming ready. Log output:"
    cat "$LOG_FILE"
    exit 1
  fi
  if curl --noproxy "*" -s -m 1 -o /dev/null "$BASE_URL/mcp" 2>/dev/null; then
    ready=true
    break
  fi
  sleep 0.5
done

if [ "$ready" != "true" ]; then
  echo "Error: server did not become ready in time. Log output:"
  cat "$LOG_FILE"
  exit 1
fi

echo ""
echo "=== Initializing MCP session ==="
INIT_RESPONSE=$(curl --noproxy "*" -s -m 10 -i -X POST "$BASE_URL/mcp" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc":"2.0",
    "id":1,
    "method":"initialize",
    "params":{
      "protocolVersion":"2025-03-26",
      "capabilities":{},
      "clientInfo":{"name":"test-script","version":"1.0"}
    }
  }')

echo "Response:"
echo "$INIT_RESPONSE"
echo ""

SESSION_ID=$(echo "$INIT_RESPONSE" | grep -i "mcp-session-id:" | sed 's/.*: //' | tr -d '\r\n')

if [ -z "$SESSION_ID" ]; then
  echo "Error: Could not extract session ID from response"
  exit 1
fi

echo "Session ID: $SESSION_ID"

[SCRIPT_END]

Apply exactly these two edits, nothing else:

EDIT 1 — find this exact line:
npm run build
and replace it with:
dotnet build src/ConnectwiseMcp/ConnectwiseMcp.csproj

EDIT 2 — find these exact two lines:
SERVER_ENTRYPOINT="$SCRIPT_DIR/dist/index.js"
node "$SERVER_ENTRYPOINT" > "$LOG_FILE" 2>&1 &
and replace them with this exact one line:
dotnet run --project src/ConnectwiseMcp --no-build > "$LOG_FILE" 2>&1 &

OUTPUT FORMAT (strict):
- Output ONLY the full script with the two edits applied.
- The output is one valid bash script — the old strings must be GONE; do NOT
  list the edits after the script.
- No code fences, no commentary, no [SCRIPT_START]/[SCRIPT_END].
- Print the script exactly once.
