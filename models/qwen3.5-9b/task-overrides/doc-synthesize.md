REQUIRED-ELEMENT REMINDER — read before answering:

Your answer must include a fenced JSON code block (starting with
` ```json ` and ending with ` ``` `), not JSON described in prose or
embedded inline in a sentence. Check for this specific fenced block
before finishing — an answer with the right content but no fenced
JSON block is still wrong.

The string `zod` must NOT appear anywhere in your output — it refers
to a TypeScript-only library not present in the C# port. Check your
draft specifically for this string before finishing.
ROLE: You are a documentation subagent (documenter role). Below is the
source material: the TypeScript server's error-behavior contract. Write a
NEW section, "Error behavior (C# port)", for the C# reimplementation,
following the fixed structure below. Do not copy any document verbatim —
synthesize a new section from the material, in C# terms.

SOURCE MATERIAL (TypeScript server, docs/TOOL_CONTRACTS.md):

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

STRUCTURE (exact):

## Error behavior (C# port)

[one sentence: who throws, who catches — C# terms, model's own words]

```json
{ "content": [{ "type": "text", "text": "<message>" }], "isError": true }
```

- **Invalid input**: [what the C# host throws before the handler runs]
- **Handler-thrown errors**: [what the C# ConnectWise client throws on
  non-2xx; what it throws when unreachable; whether there is a retry or an
  error-code taxonomy]

RULES:
- Must mention the C# error object shape `isError: true` with a `content`
  text item.
- Must mention `ConnectWise API error: <status> <statusText>` and
  `HttpRequestException` for the unreachable case.
- Must NOT mention `zod`, `fetch failed`, `@modelcontextprotocol/sdk`, or
  `node_modules`.

OUTPUT: the synthesized section, and nothing else.
