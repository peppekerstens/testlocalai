## Scenario

The C# MCP server port has just been built and must be verified manually.
Facts:

- Launched with `dotnet run --project src/ConnectwiseMcp`.
- Listens on `PORT` (default `3000`), MCP endpoint at `http://127.0.0.1:3000/mcp`.
- Credentials come from `.env`: `CW_COMPANY_ID`, `CW_PUBLIC_KEY`,
  `CW_PRIVATE_KEY`, `CW_CLIENT_ID`. Missing any → startup fails fast before
  binding.
- The obfuscation config (`CW_OBFUSCATION_CONFIG`) is validated at startup;
  an invalid file also fails fast before binding.
- An MCP client initializes a session with an `initialize` request; the
  server responds with a session ID in the `mcp-session-id` header.
