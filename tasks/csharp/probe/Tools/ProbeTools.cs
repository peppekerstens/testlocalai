using System.ComponentModel;
using System.Security.Claims;
using System.Text.Json;
using System.Text.Json.Nodes;
using ModelContextProtocol.Server;

namespace Probe.Tools;

[McpServerToolType]
public sealed class ProbeTools
{
    [McpServerTool, Description("Returns a JSON string (indented)")]
    public static string ReturnJson()
    {
        var node = JsonNode.Parse("{\"hello\":\"world\",\"id\":3}");
        return JsonSerializer.Serialize(node, new JsonSerializerOptions { WriteIndented = true });
    }

    [McpServerTool, Description("Always throws to produce a tool error")]
    public static string ThrowError()
    {
        throw new Exception("probe boom");
    }

    [McpServerTool, Description("Returns the user id from ClaimsPrincipal")]
    public static string GetIdentity(ClaimsPrincipal principal)
    {
        var id = principal.FindFirst(ClaimTypes.NameIdentifier)?.Value ?? "no-claim";
        return $"identity={id}";
    }

    [McpServerTool, Description("Returns the user id from a DI scoped service")]
    public static string GetIdentityDi(ScopedIdentity identity)
    {
        return $"identity={identity.UserId}";
    }
}
