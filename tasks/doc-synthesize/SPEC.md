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
