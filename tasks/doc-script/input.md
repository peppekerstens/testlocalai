## `test-manual.sh` — excerpt (TypeScript/Node original)

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables from .env
if [ ! -f .env ]; then
  echo "Error: .env file not found. Copy .env.example to .env and fill in your credentials."
  exit 1
fi

# Source .env file (export all variables)
set -a
source .env
set +a

# Check required variables
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

# Extract session ID from headers
SESSION_ID=$(echo "$INIT_RESPONSE" | grep -i "mcp-session-id:" | sed 's/.*: //' | tr -d '\r\n')

if [ -z "$SESSION_ID" ]; then
  echo "Error: Could not extract session ID from response"
  exit 1
fi

echo "Session ID: $SESSION_ID"
