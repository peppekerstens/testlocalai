ROLE: You are a careful document editor. Copy the bash script below
byte-for-byte, then apply the three edits inside it. The result must remain
a valid bash script that passes `bash -n`. Do not reword, reorder, merge, or
add anything outside the edits.

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

Apply exactly these three edits, nothing else. The edits are in three
different places in the script.

EDIT 1 — REPLACE one line. Near the top, the script has:
PORT="${PORT:-3000}"
SERVER_ENTRYPOINT="$SCRIPT_DIR/dist/index.js"
After the edit, that place must be only:
PORT="${PORT:-3000}"
(The SERVER_ENTRYPOINT line is DELETED. Keep the blank line after PORT.)

EDIT 2 — REPLACE one line. The script has:
echo "Building..."
npm run build
After the edit, that place must be:
echo "Building..."
dotnet build src/ConnectwiseMcp/ConnectwiseMcp.csproj

EDIT 3 — REPLACE one line. The script has:
LOG_FILE="$(mktemp)"
node "$SERVER_ENTRYPOINT" > "$LOG_FILE" 2>&1 &
After the edit, that place must be:
LOG_FILE="$(mktemp)"
dotnet run --project src/ConnectwiseMcp --no-build > "$LOG_FILE" 2>&1 &

A previous answer made two mistakes. Do not repeat them:
- WRONG: it kept the line SERVER_ENTRYPOINT="$SCRIPT_DIR/dist/index.js".
  EDIT 1 deletes that line. It must not be in your output.
- WRONG: after the last line it printed the script again, many times.
  Print the script ONE time only.

The last line of the script is:
echo "Session ID: $SESSION_ID"
Print that line one time, then STOP. Write nothing after it.

SELF-CHECK before you answer. Your output must NOT contain any of these texts:
- dist/index.js
- SERVER_ENTRYPOINT
- npm run build
- node "
Your output must contain `#!/usr/bin/env bash` exactly one time, as line 1.

OUTPUT FORMAT (strict):
- Output ONLY the full script with the three edits applied.
- No code fences, no commentary, no [SCRIPT_START]/[SCRIPT_END].
- Do NOT list the edits after the script.
- Print the script exactly once. End at echo "Session ID: $SESSION_ID".
