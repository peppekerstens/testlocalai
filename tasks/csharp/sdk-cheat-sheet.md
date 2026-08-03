# MCP SDK 2.0.0 cheat sheet (ModelContextProtocol)

Verified 2026-08-03 by actually building and running `tasks/csharp/probe/`
against a live client (`~/.dotnet/dotnet run --no-build`, tested via raw
`curl` JSON-RPC calls). Every claim below is either confirmed by that run
or explicitly marked as unverified.

## 0. Package
Packages required (both version 2.0.0 on NuGet):
- ModelContextProtocol (core SDK)
- ModelContextProtocol.AspNetCore (HTTP transport: WithHttpTransport + MapMcp)

## 1. Streamable HTTP server — endpoint path
```csharp
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddMcpServer()
    .WithHttpTransport(o => o.Stateless = false)
    .WithTools<MyTool>();
var app = builder.Build();
app.MapMcp();          // ⚠️ maps to ROOT "/", not "/mcp"
app.Run();
```
**Confirmed by direct test:** `app.MapMcp()` called with no pattern
argument maps the transport to `/` — a POST to `/mcp` returns 404, a POST
to `/` returns 200. To get a `/mcp` path (e.g. to match a convention used
elsewhere in this project), pass it explicitly: `app.MapMcp("/mcp")`. Do
not assume `/mcp` without checking how `MapMcp` was actually called.

## 2. Registering tools
A class marked `[McpServerToolType]`; static methods marked
`[McpServerTool, Description("...")]`. A string return value is
automatically wrapped in a `TextContentBlock`. Parameter descriptions use
`[Description]`.

Register with `.WithTools<MyTool>()`.

**Tool name conversion (confirmed, previously undocumented):** the SDK
auto-converts the C# PascalCase method name to snake_case for the MCP
tool name. `ReturnJson` → `return_json`, `ThrowError` → `throw_error`,
`GetIdentity` → `get_identity`. Call tools by the snake_case name, not
the C# method name — a `tools/call` using the PascalCase name returns
"Unknown tool".

## 3. Returning a JSON string / producing a tool error
Tools return a string (auto-wrapped as text content). To return JSON use
`JsonSerializer.Serialize(...)` with `WriteIndented = true` and return
that string — **confirmed**, `return_json` returned:
```json
{
  "hello": "world",
  "id": 3
}
```
as a text content block, exactly as expected.

When a tool throws, the error is reported inside `CallToolResult` with
`IsError = true` (a tool error, not a protocol error) — **confirmed**,
`throw_error` (which unconditionally throws `new Exception("probe
boom")`) returned:
```json
{"result":{"content":[{"type":"text","text":"An error occurred invoking 'throw_error'."}],"isError":true}, ...}
```
Note the thrown message text (`"probe boom"`) is NOT leaked into the
response — matches the generic-message behavior described in §7.

## 4. Per-request identity
Tool methods can accept special parameter types resolved automatically:
- `McpServer`
- `IProgress<ProgressNotificationValue>`
- `ClaimsPrincipal` — **confirmed working.** A tool
  `GetIdentity(ClaimsPrincipal principal)` correctly read the identity
  set by middleware on `context.User` for that request (returned
  `identity=test-user-123` when the middleware populated
  `ClaimTypes.NameIdentifier` from an `x-dev-user` header).

**⚠️ Gotcha, confirmed by direct test — do NOT rely on plain DI-scoped
services as tool parameters.** A tool parameter of a custom
app-defined type (e.g. `GetIdentityDi(ScopedIdentity identity)`, where
`ScopedIdentity` is `builder.Services.AddScoped<ScopedIdentity>()`) does
**not** resolve to the request's DI-scoped instance the way a
`ClaimsPrincipal` parameter does. Even with the exact same middleware
populating both `context.User` and the scoped `ScopedIdentity.UserId` on
every request, `get_identity_di` reliably returned `identity=anonymous`
(the class's default value) instead of the request's actual user id.
The SDK does not consult `context.RequestServices` for arbitrary custom
DI types bound as tool parameters — it silently binds a
default-constructed instance rather than throwing, which makes this a
silent-failure trap, not a loud one. **Use `ClaimsPrincipal` (or
`IHttpContextAccessor` pulled from a type the SDK does recognize) for
per-request identity, not a custom DI-scoped POCO passed as a tool
parameter.**

**Session-level identity enforcement (new finding, not previously
documented anywhere):** with `Stateless = false`, the SDK tracks the
identity that initiated an MCP session and enforces it stays consistent
across that session's subsequent requests. A `tools/call` sent with a
different (or missing/defaulted) `x-dev-user` identity than the one used
at `initialize` time fails with a protocol-level error:
```json
{"error":{"code":-32000,"message":"Forbidden: The currently authenticated user does not match the user who initiated the session."}}
```
Confirmed by direct reproduction: two calls made without the
`x-dev-user` header (defaulting to `anonymous`) against a session
initialized as `test-user-123` both hit this Forbidden error; repeating
the exact same calls with the header present on every request succeeded
normally. **Practical implication: every request within one MCP session
must carry the same resolved identity, or non-`initialize` calls will be
rejected outright** — this is enforced by the SDK itself, not
something a tool author has to implement.

Per-session configuration:
- with `Stateless = false`, `options.ConfigureSessionOptions` is an
  async callback invoked per session with `(HttpContext,
  McpServerOptions, CancellationToken)`, and can replace the
  `ToolCollection`. (Unverified by this probe — not exercised.)
- Fallback if identity cannot be surfaced into a tool via
  `ClaimsPrincipal`: `IHttpContextAccessor` + `AsyncLocal` populated by
  middleware (SDK-independent). Prefer this over a plain DI-scoped POCO
  given the gotcha above — it wasn't tested here, but a
  request-accessor pattern isn't subject to the same binding gap since
  it's not passed as a tool parameter at all.

## 5. Session-id behavior
**Confirmed:** the `Mcp-Session-Id` response header returned at
`initialize` is an opaque, SDK-generated token — distinct from the
resolved user id (`x-dev-user`/`ClaimsPrincipal` identity). It must be
echoed back as the `mcp-session-id` request header on every subsequent
call in that session (both `notifications/initialized` and any
`tools/call`); omitting it does not automatically fail the request but
should not be relied upon — pass it explicitly every time.

## 6. Hosting shape
ASP.NET Core minimal hosting via `WebApplication`; `MapMcp()` maps the
endpoint (see §1 for the actual default path); `PORT` is taken from the
`PORT` env var in this probe (a project convention, not an SDK
requirement); `.WithHttpTransport` configures the Streamable HTTP
transport.

## 7. Error propagation
Tool errors: `CallToolResult.IsError = true` — **confirmed**, see §3.
If the exception derives from `McpException` (excluding
`McpProtocolException`) its message is included in the error text;
other exceptions get a generic message (no internal detail leak) —
**confirmed**: a plain `Exception("probe boom")` produced the generic
`"An error occurred invoking 'throw_error'."`, not the original message.
Do not reproduce TypeScript SDK error wording.

## 8. Compile/run verification status
**Done, 2026-08-03.** `tasks/csharp/probe/` (build: `~/.dotnet/dotnet
build`, 0 errors; run: `~/.dotnet/dotnet run --no-build`, listens on
`PORT` env var, default 4001) verified, via raw `curl` JSON-RPC calls:
(a) the host pattern compiles and boots — confirmed;
(b) JSON-string tool + throwing tool — confirmed, see §3;
(c) per-request identity read inside a tool via `ClaimsPrincipal` —
confirmed, see §4;
(d) per-request identity read via a plain DI-scoped POCO tool
parameter — tested and found NOT to work, see the gotcha in §4;
(e) endpoint path default — tested and found to be `/` not `/mcp`, see
§1;
(f) tool name casing — tested and found to auto-convert to snake_case,
see §2;
(g) session identity-consistency enforcement — tested and confirmed,
see §4.

No project task SPEC (`tasks/doc-script`, `tasks/reason-checklist`, the
only two referencing an MCP `/mcp` path) depends on the now-corrected
`/mcp`-by-default assumption: `doc-script`'s script targets the
Node/TypeScript `@modelcontextprotocol/sdk`, a different SDK entirely,
and `reason-checklist`'s C# scenario states `/mcp` as a given premise of
its fictional `ConnectwiseMcp` server, not something inferred from this
SDK's real default. No downstream fix needed.

Probe source: `tasks/csharp/probe/{Program.cs, ScopedIdentity.cs,
Tools/ProbeTools.cs, probe.csproj}`.
