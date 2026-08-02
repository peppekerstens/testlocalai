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
