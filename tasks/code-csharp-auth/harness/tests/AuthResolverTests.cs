using Xunit;

namespace Bench.Task4;

public class AuthResolverTests
{
    [Fact]
    public void ReturnsDevUserWhenPresentAndAuthRequired()
    {
        var r = new AuthResolver();
        Assert.Equal("u-42", r.ResolveUser(requireAuth: true, xDevUser: "u-42"));
    }

    [Fact]
    public void ReturnsDevUserWhenPresentAndAuthNotRequired()
    {
        var r = new AuthResolver();
        Assert.Equal("u-42", r.ResolveUser(requireAuth: false, xDevUser: "u-42"));
    }

    [Fact]
    public void RejectsWhenAuthRequiredAndNoDevUser()
    {
        var r = new AuthResolver();
        Assert.Throws<UnauthorizedAccessException>(
            () => r.ResolveUser(requireAuth: true, xDevUser: null));
    }

    [Fact]
    public void RejectsWhenAuthRequiredAndWhitespaceDevUser()
    {
        var r = new AuthResolver();
        Assert.Throws<UnauthorizedAccessException>(
            () => r.ResolveUser(requireAuth: true, xDevUser: "   "));
    }

    [Fact]
    public void AnonymousWhenNoAuthRequiredAndNullDevUser()
    {
        var r = new AuthResolver();
        Assert.Equal("anonymous", r.ResolveUser(requireAuth: false, xDevUser: null));
    }

    [Fact]
    public void AnonymousWhenNoAuthRequiredAndEmptyDevUser()
    {
        var r = new AuthResolver();
        Assert.Equal("anonymous", r.ResolveUser(requireAuth: false, xDevUser: ""));
    }

    [Fact]
    public void AnonymousWhenNoAuthRequiredAndWhitespaceDevUser()
    {
        var r = new AuthResolver();
        Assert.Equal("anonymous", r.ResolveUser(requireAuth: false, xDevUser: "   "));
    }
}
