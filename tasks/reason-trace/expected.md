A restart drops every session from the in-memory `Map` in `src/http/app.ts`
(the `transports` map keyed by `mcp-session-id`), so the established session
ceases to exist and the client's next request carries a session ID the server
no longer recognizes. In `session-random` mode the same restart also changes
every token, so a consumer that persisted a token for later cross-reference
loses that ability — the new tokens are unrelated to the persisted ones.
Consequently, on the client's next non-initialize request the server responds
with `400 No valid session ID provided`, and the client must re-initialize to
get a new session (and, in `session-random` mode, new tokens). The mechanism
is the in-memory `transports` `Map` in `src/http/app.ts` plus per-restart
token regeneration in `session-random` mode; `consistent` mode is unaffected
by restarts.
