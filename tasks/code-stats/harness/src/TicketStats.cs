using System;
using System.Collections.Generic;
using System.Linq;

namespace Bench.Stats;

public sealed record Ticket(string Status, int Priority);

public sealed class TicketStatsAggregator
{
    public Dictionary<string, int> CountByStatus(IEnumerable<Ticket> tickets)
    {
        if (tickets is null) throw new ArgumentNullException(nameof(tickets));
        return tickets
            .GroupBy(t => t.Status)
            .ToDictionary(g => g.Key, g => g.Count());
    }

    public double AverageOpenPriority(IEnumerable<Ticket> tickets)
    {
        if (tickets is null) throw new ArgumentNullException(nameof(tickets));
        var open = tickets.Where(t => t.Status == "Open").ToList();
        return open.Count == 0 ? 0.0 : open.Average(t => t.Priority);
    }

    public List<string> TopStatuses(IEnumerable<Ticket> tickets, int n)
    {
        if (tickets is null) throw new ArgumentNullException(nameof(tickets));
        if (n == 0) return new List<string>();
        return tickets
            .GroupBy(t => t.Status)
            .OrderByDescending(g => g.Count())
            .ThenBy(g => g.Key, StringComparer.Ordinal)
            .Take(n)
            .Select(g => g.Key)
            .ToList();
    }
}
