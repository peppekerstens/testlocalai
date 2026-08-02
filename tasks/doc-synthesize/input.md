## Source material (TypeScript server, docs/TOOL_CONTRACTS.md)

- Every tool returns its payload as a single MCP content item:
  `{ content: [{ type: "text", text: "<JSON>" }] }`.
- Tool handlers do not catch errors themselves. Handler exceptions are
  caught by the MCP SDK, which returns
  `{ "content": [{ "type": "text", "text": "<message>" }], "isError": true }`.
- Invalid input (e.g. `companyId` not a number) → the SDK throws before the
  handler runs, message shaped
  `Input validation error: Invalid arguments for tool <name>: <zod detail>`.
- Handler-thrown errors: only the ConnectWise client throws, with message
  `ConnectWise API error: <status> <statusText>` for any non-2xx ConnectWise
  response, or a raw network error (e.g. `fetch failed`) if ConnectWise is
  unreachable. No retry, no error-code taxonomy.
