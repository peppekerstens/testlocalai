ROLE: You are a careful document editor. Copy the document below exactly,
then apply the three FIND→REPLACE edits inside it. Do not rephrase text
outside the edits. Do not add comments.

The document begins at the [DOC_START] marker and ends at the [DOC_END]
marker. The markers are delimiters only. Do not copy the markers into the
output.

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

CRITICAL RULE — copy the EDIT 1 replacement byte-for-byte, backtick
position included:

Do not move a backtick to a new spot. Do not wrap the whole phrase in one
backtick pair when the replacement wraps only one word.

Wrong (a prior run produced this — do not repeat it):
(`the C# SDK ModelContextProtocol`; error mapping per the Task 0.3 cheat sheet)

Right (use this exact string):
(the C# SDK `ModelContextProtocol`; error mapping per the Task 0.3 cheat sheet)

The words "the", "C#", and "SDK" stay outside the backticks. Only the
single word `ModelContextProtocol` sits inside the backticks. Check this
position before you finish.

Apply exactly these three edits. Do nothing else.

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
- Output only the full document with the three edits applied.
- The output is one continuous document. The old strings must be gone
  from it. Do not list the edits after the document.
- Use no code fences, no headings, no "Here is" text, no
  [DOC_START]/[DOC_END].
- Print the document exactly once.
- Before you finish, find the text "(the C# SDK" in your output. Check
  the backtick sits directly before `ModelContextProtocol`, not directly
  after the opening parenthesis. Fix it if it sits in the wrong place.
