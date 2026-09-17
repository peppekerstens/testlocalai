ROLE: You are a careful document editor. Copy the document below exactly,
then apply the three FIND→REPLACE edits inside it. Do not rephrase anything
outside the edits. Do not comment.

The document begins at the [DOC_START] marker and ends at the [DOC_END]
marker. The markers are delimiters ONLY — never copy them into the output.

[DOC_START]

## Error behavior (applies to all tools)

Tool handlers do not catch errors themselves. Handler exceptions are caught
by the MCP SDK (`@modelcontextprotocol/sdk`,
`node_modules/@modelcontextprotocol/sdk/dist/esm/server/mcp.js`, method
`createToolError`), which returns:

```json
{ "content": [{ "type": "text", "text": "<message>" }], "isError": true }
```

Two sources of error text:

- **Invalid input** (e.g. `companyId` not a number): the SDK throws before
  the handler runs, message shaped
  `Input validation error: Invalid arguments for tool <name>: <zod detail>`.
- **Handler-thrown errors**: currently only `ConnectWiseClient`
  (`src/connectwise/client.ts`) throws, with message
  `ConnectWise API error: <status> <statusText>` for any non-2xx ConnectWise
  response, or a raw network error (e.g. `fetch failed`) if ConnectWise is
  unreachable.

[DOC_END]

Apply exactly these three edits, nothing else:

EDIT 1 — find these three exact lines:
by the MCP SDK (`@modelcontextprotocol/sdk`,
`node_modules/@modelcontextprotocol/sdk/dist/esm/server/mcp.js`, method
`createToolError`), which returns:
and replace them with this one exact line:
by the MCP SDK (the C# SDK `ModelContextProtocol`; error mapping per the Task 0.3 cheat sheet), which returns:

EDIT 2 — find these two exact lines:
  the handler runs, message shaped
  `Input validation error: Invalid arguments for tool <name>: <zod detail>`.
and replace them with these two exact lines:
  the handler runs; the C# SDK's own input-validation error text is used —
  do not reproduce the TS SDK wording (plan §7 #1).

EDIT 3 — find this exact text:
a raw network error (e.g. `fetch failed`)
and replace it with this exact text:
a raw network error (an `HttpRequestException`)

EDIT 1 WARNING. EDIT 1 replaces the WHOLE text between the parentheses,
backticks included. The old backticks after "(" and before ")" are part of
the old text. Remove them. Do not put the new text inside them.

WRONG (old backticks kept):
by the MCP SDK (`the C# SDK `ModelContextProtocol`; error mapping per the Task 0.3 cheat sheet`), which returns:

RIGHT:
by the MCP SDK (the C# SDK `ModelContextProtocol`; error mapping per the Task 0.3 cheat sheet), which returns:

Before you print, check silently:
- The output contains "(the C# SDK" with no backtick between "(" and "the".
- The output contains "cheat sheet)," with no backtick between "sheet" and ")".
- The output does not contain "@modelcontextprotocol", "mcp.js", "createToolError", "zod detail", or "fetch failed".

OUTPUT FORMAT (strict):
- Output ONLY the full document with the three edits applied.
- The output is one continuous document — the old strings must be GONE from
  it; do NOT list the edits after the document.
- No code fences around the document, no headings you add, no "Here is"
  text, no [DOC_START]/[DOC_END].
- Do not print the checks, the WRONG line, or the RIGHT line.
- Print the document exactly once.
