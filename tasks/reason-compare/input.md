### Config validation timing (fixed; kept for context)

Originally, `CW_OBFUSCATION_CONFIG` was only read inside `createServer()`
(`src/mcp/server.ts`), which is only called on the **first client's
`initialize` request** — not at boot. That meant a bad config produced a
clean-looking startup, and then an **uncaught exception that crashed the
whole process** (not a 400/500 response) the moment the first real client
connected, taking down every other session with it.

Fixed by: (1) calling `loadObfuscationConfig` once eagerly in
`src/index.ts`, before `app.listen`, so a bad file fails the boot instead of
the first session; and (2) wrapping the `/mcp` handler in `src/http/app.ts`
in try/catch as defense in depth, so any *other* error that reaches that
handler (not just a bad config) returns a `500` instead of crashing the
process.

CANDIDATES for fixing "bad config crashes the first client":

- **A:** Load and validate `CW_OBFUSCATION_CONFIG` once at boot, before the
  server starts listening; abort startup on any validation error.
- **B:** Keep lazy loading inside `createServer()`, but wrap the `/mcp`
  handler in try/catch so the config error becomes a `500` response instead
  of a crash.
- **C:** Wrap the `/mcp` handler in try/catch, and also restart the process
  automatically when the first client connects if the config is invalid.
