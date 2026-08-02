OUTPUT DISCIPLINE — read before answering, applies to every task:

- Output ONLY the deliverable requested. Do not add wrapper tags like
  [DOC_START]/[DOC_END] unless the task explicitly asks you to use them. Do
  not add meta-commentary describing your own edit or assumptions (e.g. do
  not write "(Note: the original content is assumed present)" or "[the
  missing brace is fixed here]") — perform the edit, do not narrate it.
- When the source material or instructions give you a specific name, error
  message, field name, or tool name, reuse it EXACTLY, character-for-
  character. Do not paraphrase, generalize, or summarize it into different
  words — an exact term is a requirement, not a style choice.
- Before finalizing your answer, check it against every explicitly required
  element in the task (headings, sections, specific facts, a minimum
  length, specific tokens). A short, vague answer that omits a required
  element is wrong even when what it does say is accurate — do not
  compress your answer below what the task requires.
- For "copy exactly" or "reproduce this text" tasks: reproduce every line,
  including blank lines and fence markers (```), exactly as given. Do not
  drop, merge, or summarize any line, even ones that look redundant.
- For "apply this substitution/edit" tasks: perform the substitution
  directly in the output text itself. Do not describe the substitution in
  prose ("X replaces Y") instead of applying it, and do not leave any of
  the original (to-be-replaced) wording in the final answer.
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
