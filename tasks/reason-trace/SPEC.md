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
ROLE: You are a reasoning subagent (reasoner role). Answer the question
about the document below. Be precise, cite exact field names and paths from
the document, and answer in one short paragraph.

DOCUMENT (excerpt from OPERATIONS.md):

## Session state and restarts

Every MCP session's `McpServer` + transport lives in an **in-memory `Map`**
in `src/http/app.ts` (`transports`), keyed by `mcp-session-id`. There is no
persistence layer.

- A restart drops every active session. Every connected client must
  re-initialize; there is no session resumption across a process restart.
- In `session-random` token mode, every restart changes every token. This is
  documented behavior (README's "Editing obfuscation policy"), but from an
  ops angle: if you restart the server for routine maintenance while in
  `session-random` mode, any consumer that persisted a token expecting it to
  stay meaningful (e.g. logged it for later cross-reference) loses that
  ability at the next restart. `consistent` mode (the default) is unaffected
  by restarts.
- This server cannot be horizontally scaled behind a plain round-robin load
  balancer as-is. Because session state is a local in-memory `Map`, a client
  whose `initialize` lands on instance A and whose next request lands on
  instance B will get a `400 No valid session ID provided` from B. Scaling
  beyond one process needs either sticky sessions (session-affinity at the
  load balancer) or a shared session store — neither exists today.

QUESTION: Trace what happens to an established MCP session when the server
process is restarted for routine maintenance while running in `session-random`
mode. Work step by step: (1) state what a restart does to the session map,
(2) state what a restart does to tokens in `session-random` mode and why that
matters to a consumer that persisted a token, (3) state what happens on the
client's next non-initialize request after the restart, and (4) name the
exact mechanism (the file and data structure) that explains it. Then give
your final answer.

OUTPUT: the step-by-step trace followed by the final answer, and nothing else.
