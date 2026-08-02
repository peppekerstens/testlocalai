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
ROLE: You are a reasoning subagent. Write a manual verification checklist
for the scenario below. Output 4-6 numbered steps. Each step is exactly two
lines: the action (a command to run) and the expected result. Use only
C#/.NET and standard shell tools.

SCENARIO:

- The C# MCP server has just been built and must be verified manually.
- Launched with `dotnet run --project src/ConnectwiseMcp`.
- Listens on `PORT` (default `3000`), MCP endpoint at `http://127.0.0.1:3000/mcp`.
- Credentials come from `.env`: `CW_COMPANY_ID`, `CW_PUBLIC_KEY`,
  `CW_PRIVATE_KEY`, `CW_CLIENT_ID`. Missing any → startup fails fast before
  binding.
- The obfuscation config (`CW_OBFUSCATION_CONFIG`) is validated at startup;
  an invalid file also fails fast before binding.
- An MCP client initializes a session with an `initialize` request; the
  server responds with a session ID in the `mcp-session-id` header.

RULES:
- Use only .NET tools (`dotnet`) and `curl` — never `npm`, `node`, or `tsc`.
- Verify fail-fast behavior: a missing env var and an invalid config must
  each abort startup before the port is bound.
- Verify the server responds on `/mcp` and that an `initialize` request
  returns a `mcp-session-id` header.
- Each step numbered (`1.` … `6.`), action on the first line, expected
  result on the next line.
- **At most 6 steps.** Skip redundant checks.

OUTPUT: the checklist, and nothing else.
