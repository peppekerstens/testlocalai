using System.Reflection;
using System.Security.Claims;
using ModelContextProtocol.Server;
using Xunit;

namespace Bench.McpIdentity;

public class IdentityToolTests
{
    [Fact]
    public void ReturnsClaimValueWhenNameIdentifierPresent()
    {
        var principal = new ClaimsPrincipal(new ClaimsIdentity(
            new[] { new Claim(ClaimTypes.NameIdentifier, "test-user-123") }, "dev"));

        var result = IdentityTool.GetIdentity(principal);

        Assert.Equal("identity=test-user-123", result);
    }

    [Fact]
    public void ReturnsAnonymousWhenNoIdentitiesAttached()
    {
        var principal = new ClaimsPrincipal();

        var result = IdentityTool.GetIdentity(principal);

        Assert.Equal("identity=anonymous", result);
    }

    [Fact]
    public void ReturnsAnonymousWhenIdentityHasNoNameIdentifierClaim()
    {
        var principal = new ClaimsPrincipal(new ClaimsIdentity(
            new[] { new Claim(ClaimTypes.Role, "admin") }, "dev"));

        var result = IdentityTool.GetIdentity(principal);

        Assert.Equal("identity=anonymous", result);
    }

    [Fact]
    public void GetIdentityMethodIsStatic()
    {
        var method = typeof(IdentityTool).GetMethod(
            "GetIdentity", BindingFlags.Public | BindingFlags.Static);

        Assert.NotNull(method);
    }

    [Fact]
    public void ClassCarriesMcpServerToolTypeAttribute()
    {
        var attr = typeof(IdentityTool).GetCustomAttribute<McpServerToolTypeAttribute>();

        Assert.NotNull(attr);
    }

    [Fact]
    public void GetIdentityMethodCarriesMcpServerToolAttribute()
    {
        var method = typeof(IdentityTool).GetMethod(
            "GetIdentity", BindingFlags.Public | BindingFlags.Static);

        var attr = method?.GetCustomAttribute<McpServerToolAttribute>();

        Assert.NotNull(attr);
    }
}
