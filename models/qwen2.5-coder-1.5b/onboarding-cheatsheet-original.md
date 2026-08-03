<!--
Recovered 2026-08-03 from git commit 62bcb1b (the version present at this
project's original import, 953465d) after it was discovered that a later
edit on 2026-08-03 (commit 2dd9a1f, working on an unrelated csharp/
directory sanitation task) had overwritten tasks/csharp/sdk-cheat-sheet.md
in place — the same file models/qwen2.5-coder-1.5b/history.md's
"Onboarding history" section documents as this model's own verbatim
0.3a-cheatsheet onboarding output, preserved after that round's raw
prompts/outputs/logs were deliberately deleted on the premise that this
file was the durable record. That overwrite broke the "verbatim" claim;
this file restores the actual original content to this model's own
directory (the correct home for model-specific onboarding evidence) so
nothing is permanently lost. See history.md for the full incident note.
-->

# MCP SDK 2.0.0 cheat sheet (ModelContextProtocol)

## 0. Package
Packages required (both version 2.0.0 on NuGet):
- ModelContextProtocol (core SDK)
- ModelContextProtocol.AspNetCore (HTTP transport: WithHttpTransport + MapMcp)

## 1. Streamable HTTP server (POST /mcp)
```csharp
var builder = WebApplication.CreateBuilder(args);
builder.Services.AddMcpServer()
    .WithHttpTransport(o => o.Stateless = false)
    .WithTools<MyTool>();
var app = builder.Build();
app.MapMcp();          // endpoint is POST /mcp
app.Run();
```

## 2. Registering tools
A class marked [McpServerToolType]; static methods marked [McpServerTool, Description("...")]. A string return value is automatically wrapped in a TextContentBlock. Parameter descriptions use [Description].

Register with .WithTools<MyTool>().

## 3. Returning a JSON string / producing a tool error
Tools return a string (auto-wrapped as text content). To return JSON use JsonSerializer.Serialize(...) with WriteIndented = true and return that string. When a tool throws, the error is reported inside CallToolResult with IsError = true (a tool error, not a protocol error).

## 4. Per-request identity (resolved user id -> tool sessionId)
Tool methods can accept special parameter types resolved automatically:
- McpServer
- IProgress<ProgressNotificationValue>
- ClaimsPrincipal
- and any service registered through dependency injection.
Per-session configuration:
- with Stateless = false, options.ConfigureSessionOptions is an async callback invoked per session with (HttpContext, McpServerOptions, CancellationToken)
- and can replace the ToolCollection.
- Fallback if identity cannot be surfaced into a tool: IHttpContextAccessor + AsyncLocal populated by middleware (SDK-independent).

## 5. Session-id behavior
The token engine's sessionId is the RESOLVED USER ID, not the transport mcp-session-id.

Exact transport header behavior is recorded after the probe runs.

## 6. Hosting shape
ASP.NET Core minimal hosting via WebApplication; MapMcp() maps the endpoint;
PORT is taken from the PORT env var;
.WithHttpTransport configures the Streamable HTTP transport.

## 7. Error propagation
Tool errors: CallToolResult.IsError = true.
If the exception derives from McpException (excluding McpProtocolException) its message is included in the error text; other exceptions get a generic message (no internal detail leak).
Do not reproduce TypeScript SDK error wording.

## 8. Compile/run verification status
PENDING — probe project under csharp/.orchestration/probe/ verifies:
(a) the host pattern compiles and boots,
(b) JSON-string tool + throwing
tool, 
(c) per-request identity read inside a tool.
Status filled in after the probe runs.
