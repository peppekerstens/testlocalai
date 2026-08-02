OUTPUT BOUNDARY — read before answering:

- Your answer ends the moment the edited document itself ends. Do not
  write anything after that point — no instructions, no edit list, no
  marker text, no explanation.
- The words "EDIT", "OUTPUT FORMAT", and any bracketed marker like
  [DOC_END] or [SCRIPT_END] must never appear anywhere in your answer.
  If you notice yourself about to write any of them, stop — you have
  already finished, delete anything after that point.
EDIT VERIFICATION — read before answering:

- After drafting your answer, check each numbered EDIT one at a time
  against what you wrote: does your output contain the REPLACE text,
  and NOT the FIND text? If any FIND text still appears anywhere in
  your draft, you are not finished — remove it and insert the REPLACE
  text in its place before submitting.
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
