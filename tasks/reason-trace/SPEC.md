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
