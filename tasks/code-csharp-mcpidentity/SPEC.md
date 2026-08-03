TASK: MCP tool that resolves the calling user's identity from a `ClaimsPrincipal`, using the real ModelContextProtocol SDK's per-request identity binding (not a manually-passed header/string, and not a DI-scoped service).
FILE: one file `IdentityTool.cs`. Namespace: `Bench.McpIdentity`.

File MUST start with these EXACT using lines, in order:
```csharp
using System.Security.Claims;
using ModelContextProtocol.Server;
```
(No other using lines — no `System.ComponentModel`, no `Description` import; the `Description` attribute is not required for this file.)

Then namespace and type:
```csharp
namespace Bench.McpIdentity;

[McpServerToolType]
public sealed class IdentityTool
{
    [McpServerTool]
    public static string GetIdentity(ClaimsPrincipal principal)
    {
        // implement per the behavior contract
    }
}
```

BEHAVIOR (must hold exactly):
1. Look up the claim of type `ClaimTypes.NameIdentifier` on `principal` (use `principal.FindFirst(ClaimTypes.NameIdentifier)`).
2. If that claim exists, return the literal string `"identity="` followed immediately by the claim's `Value` (e.g. a principal whose `NameIdentifier` claim value is `"test-user-123"` returns exactly `"identity=test-user-123"`).
3. If that claim does NOT exist — including a `ClaimsPrincipal` with zero identities attached — return exactly the literal string `"identity=anonymous"`. Never throw, never return null.

Use EXACTLY this method body shape:
```csharp
[McpServerTool]
public static string GetIdentity(ClaimsPrincipal principal)
{
    var value = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
    return $"identity={value ?? "anonymous"}";
}
```

DO NOT:
- Add a constructor, any field, or any other method to `IdentityTool`.
- Make `GetIdentity` an instance method — it must stay `public static`, matching how the real SDK binds `ClaimsPrincipal` as a special tool parameter type per request (an instance/DI-scoped field would NOT be re-populated per request and would silently return stale or default data — this is a real bug class, not a style preference).
- Read identity from any source other than the `ClaimsPrincipal principal` parameter (no `IHttpContextAccessor`, no environment variable, no extra parameter).
- Remove or rename the `[McpServerToolType]` / `[McpServerTool]` attributes — the real SDK requires both to expose this method as an MCP tool at all, and auto-converts the method name `GetIdentity` to the wire tool name `get_identity` (snake_case) using them.

OUTPUT: ONLY complete `IdentityTool.cs` in one fenced ```csharp block. No explanations, no other text.
