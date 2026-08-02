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
