using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Bench.Task5;

public class TicketToolTests
{
    [Fact]
    public void ResolvesTicketToolFromDi()
    {
        var services = new ServiceCollection();
        services.AddTicketTool();
        using var sp = services.BuildServiceProvider();

        var tool = sp.GetRequiredService<TicketTool>();
        var store = sp.GetRequiredService<ITicketStore>();

        Assert.NotNull(tool);
        Assert.NotNull(store);
    }

    [Fact]
    public void GetTicketReturnsTextForKnownId()
    {
        var services = new ServiceCollection();
        services.AddTicketTool();
        using var sp = services.BuildServiceProvider();

        var tool = sp.GetRequiredService<TicketTool>();
        var result = tool.GetTicket(1);

        Assert.False(string.IsNullOrEmpty(result));
        Assert.Contains("1", result!);
    }

    [Fact]
    public void GetTicketReturnsNullForUnknownId()
    {
        var services = new ServiceCollection();
        services.AddTicketTool();
        using var sp = services.BuildServiceProvider();

        var tool = sp.GetRequiredService<TicketTool>();
        Assert.Null(tool.GetTicket(999));
    }

    private sealed class FakeTicketStore : ITicketStore
    {
        public Task<string?> GetTicketAsync(int id) => Task.FromResult<string?>("FAKE-" + id);
    }

    [Fact]
    public void UsesTheInjectedStore_NotAnInternallyCreatedOne()
    {
        // If TicketTool ignored its constructor parameter and created its own
        // InMemoryTicketStore internally, this would return "Ticket 1" instead
        // of the fake store's sentinel value — proving constructor injection
        // is actually honored, not just present in the signature.
        var tool = new TicketTool(new FakeTicketStore());
        Assert.Equal("FAKE-1", tool.GetTicket(1));
    }
}
