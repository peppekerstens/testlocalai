TASK: LINQ ticket-stats aggregator.
FILE: one file `TicketStats.cs`. Namespace: `Bench.Stats`.

File MUST start with this EXACT using line:
```csharp
using System;
using System.Collections.Generic;
using System.Linq;
```

WRITE record TYPE FIRST, THEN the aggregator class.

```csharp
namespace Bench.Stats;

public sealed record Ticket(string Status, int Priority);
```

AFTER Ticket, append TicketStatsAggregator with EXACTLY this shape — copy all
three method bodies verbatim, do not rewrite any of them. Each one has a
known easy mistake that only shows up on some draws, so none of them are
left to inference:

```csharp
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
```

CLASS CHECKLIST: output MUST contain exactly these TWO types in this order: Ticket, TicketStatsAggregator. Count both before closing the fenced block. Do not stop early.

BEHAVIOR (must hold exactly — the verbatim bodies above already implement all of this, this section explains why each shape is the way it is):
1. `tickets == null` on ANY of the three methods -> throw `ArgumentNullException`. Checked FIRST in every method, before enumerating.
2. Each method enumerates `tickets` EXACTLY ONCE. Never call `.Count()`, `.Any()`, or a second `foreach`/LINQ chain over the same parameter.
3. `CountByStatus`: count of tickets per exact `Status` string (case-sensitive). Empty input -> empty dictionary.
4. `AverageOpenPriority`: `.Average()` on a possibly-EMPTY filtered sequence throws `InvalidOperationException` — that is why the body materializes to `open` and checks `Count == 0` FIRST, never calling `.Average()` directly on an unchecked `.Where(...)` result.
5. `TopStatuses`: `n == 0` returns an empty list BEFORE anything else runs; the `GroupBy` shape is what makes the count-per-status correct (do not compute counts by re-scanning an already-deduplicated list, that always yields 1).

OUTPUT: ONLY complete `TicketStats.cs` in one fenced ```csharp block. No explanations, no other text.
