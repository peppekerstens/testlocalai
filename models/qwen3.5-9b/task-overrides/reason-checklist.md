EXACT-PHRASE REMINDER — read before answering:

This checklist is graded by grepping your output for 5 specific literal
tokens — a checklist that covers the right idea in different words still
fails. Before finishing, verify all 5 of these exact strings appear
somewhere in your numbered steps, verbatim, not paraphrased:

1. `dotnet run` — the literal build/launch command must appear as text
   (e.g. as `dotnet run --project src/ConnectwiseMcp`), not just described
   as "build the project" or "start the server".
2. `/mcp` — the literal endpoint path, not just "the MCP endpoint".
3. `initialize` — the literal JSON-RPC method name used to start a
   session, not just "the first request" or "session start".
4. `curl` — the literal tool name used to probe the server, not "an HTTP
   client" or "a request tool".
5. `mcp-session-id` — the literal header name, not "the session header"
   or "a session identifier".

Missing even one of these 5 exact strings fails the check, regardless of
whether the step it belongs to is otherwise correct.

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
