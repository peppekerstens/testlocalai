REQUIRED-FACT REMINDER — read before answering:

Two specific facts are the ones most often dropped from this summary.
Before finishing, check your draft contains BOTH, using these words:
- The exact phrase "ConnectWise MCP server" (not just "the server" or
  "this project").
- The fact that the official SDK is the reference implementation (say
  so explicitly, do not just imply it).
ROLE: You are a documentation subagent (documenter role). Below is source
material explaining a real architecture decision. Write a SHORT summary of
it — do not copy sentences verbatim, compress into your own words, and stay
strictly within the length limit. Preserve every key fact; invent nothing
the source doesn't say.

SOURCE MATERIAL (docs/ARCHITECTURE.md, "Language and SDK choice"):

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

LENGTH LIMIT: at most 90 words, at most 4 sentences. Count before you
answer — going over the limit is a failure even if every fact is correct.

FACT CHECKLIST — your summary MUST contain all FOUR of these, no exceptions.
A summary that is well-written but drops one of the four to save words is
WRONG, exactly as wrong as one that goes over the word limit. Before you
answer, count: does your draft hit all 4?
1. The language choice: TypeScript/Node, not Python.
2. The MCP SDK reference implementation is TypeScript (or: the official
   SDK is TypeScript).
3. OAuth as a reason the choice paid off (the TypeScript SDK has OAuth
   support Python's didn't).
4. Existing/prior ConnectWise MCP servers are ALSO TypeScript/Node — this
   is a separate fact from #2 (the official SDK) and is dropped more often
   than the others; do not let the length limit push it out.

Must NOT invent frameworks, libraries, or reasons not in the source (e.g.
do not mention Django, Flask, gRPC, or performance/speed — none of that is
in the source material).

OUTPUT: the summary only, nothing else — no heading, no preamble like
"Here is a summary:".
