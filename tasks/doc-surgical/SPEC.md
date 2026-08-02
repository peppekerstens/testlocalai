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

EDIT 1 — find this exact text:
(`@modelcontextprotocol/sdk`, `node_modules/@modelcontextprotocol/sdk/dist/esm/server/mcp.js`, method `createToolError`)
and replace it with this exact text:
(the C# SDK `ModelContextProtocol`; error mapping per the Task 0.3 cheat sheet)

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

OUTPUT FORMAT (strict):
- Output ONLY the full document with the three edits applied.
- The output is one continuous document — the old strings must be GONE from
  it; do NOT list the edits after the document.
- No code fences, no headings, no "Here is" text, no [DOC_START]/[DOC_END].
- Print the document exactly once.
