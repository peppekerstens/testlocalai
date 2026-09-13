using System.Security.Claims;
using ModelContextProtocol.Server;

namespace Bench.McpIdentity;

[McpServerToolType]
public sealed class IdentityTool
{
    [McpServerTool]
    public static string GetIdentity(ClaimsPrincipal principal)
    {
        var value = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return $"identity={value ?? "anonymous"}";
    }
}
