## Source material (docs/ARCHITECTURE.md, "Language and SDK choice")

This server is TypeScript/Node, not Python or one of ConnectWise's other
SDK-supported languages. Two things drove that, at two different points in
the project:

- Every existing ConnectWise MCP server investigated up front — wyre-technology's,
  jasondsmith72's, the various npm packages — is TypeScript/Node. So is the
  official `@modelcontextprotocol/sdk` this project depends on directly,
  which is the most actively maintained reference implementation of the MCP
  spec.
- That choice paid off once the deployment/auth requirements landed: the
  article investigated while researching an auth approach describes a team
  moving off Python specifically because the MCP TypeScript SDK ships
  first-class OAuth primitives (a `ProxyOAuthServerProvider`, `mcpAuthRouter`,
  bearer-auth middleware that surfaces validated identity to tool handlers
  as `authInfo`) that the Python SDK didn't have an equivalent for at the
  time. The Entra ID/Azure prior art surveyed for this project's own
  deferred auth work is TypeScript/Node throughout as well — so staying on
  this stack means this project can draw directly on that material later
  instead of porting patterns across languages when auth is finally
  implemented.
