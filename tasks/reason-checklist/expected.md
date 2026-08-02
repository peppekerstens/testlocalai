1. Build and start the server:
   `dotnet run --project src/ConnectwiseMcp` → process stays up, no
   `Error: Missing required environment variable` printed.
2. Probe the endpoint:
   `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3000/mcp` →
   returns a non-error HTTP response, confirming the server bound the port.
3. Missing-env fail-fast:
   unset `CW_PRIVATE_KEY`, restart, `dotnet run --project src/ConnectwiseMcp` →
   exits immediately with `Missing required environment variable:
   CW_PRIVATE_KEY`, port not bound.
4. Invalid-config fail-fast:
   point `CW_OBFUSCATION_CONFIG` at a malformed file (bad regex), restart →
   exits immediately before binding the port.
5. Initialize an MCP session:
   `curl --noproxy "*" -i -X POST http://127.0.0.1:3000/mcp -H
   "Content-Type: application/json" -H "Accept: application/json,
   text/event-stream" -d '{"jsonrpc":"2.0","id":1,"method":"initialize",
   "params":{"protocolVersion":"2025-03-26","capabilities":{},
   "clientInfo":{"name":"checklist","version":"1.0"}}}'` → response contains
   a `mcp-session-id` header.
6. Session identity is preserved:
   re-send a non-initialize JSON-RPC request with the `mcp-session-id` header
   → server responds without a `No valid session ID` error.
