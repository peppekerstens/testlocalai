using Microsoft.Extensions.DependencyInjection;

namespace Bench.Task5;

public interface ITicketStore
{
    Task<string?> GetTicketAsync(int id);
}

public sealed class InMemoryTicketStore : ITicketStore
{
    public Task<string?> GetTicketAsync(int id)
    {
        if (id == 1) return Task.FromResult("Ticket 1");
        if (id == 2) return Task.FromResult("Ticket 2");
        return Task.FromResult<string?>(null);
    }
}

public class TicketTool
{
    private readonly ITicketStore _store;

    public TicketTool(ITicketStore store)
    {
        _store = store;
    }

    public string? GetTicket(int id)
    {
        // returns store.GetTicketAsync(id) result, synchronously;
        // never creates an ITicketStore itself
    }
}

public static class TicketServiceCollectionExtensions
{
    public static IServiceCollection AddTicketTool(this IServiceCollection services)
    {
        // register InMemoryTicketStore as ITicketStore (singleton)
        // register TicketTool (singleton)
        return services;
    }
}
