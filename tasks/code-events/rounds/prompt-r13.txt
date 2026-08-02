TASK: multicast event notifier, one bad handler must not block the rest.
FILE: one file `TicketStatusNotifier.cs`. Namespace: `Bench.Events`.

File MUST start with this EXACT using line:
```csharp
using System;
```

WRITE the delegate FIRST, THEN the notifier class.

```csharp
namespace Bench.Events;

public delegate void StatusChangedHandler(string ticketId, string oldStatus, string newStatus);
```

AFTER the delegate, append TicketStatusNotifier with this EXACT event declaration and method signature:

```csharp
public sealed class TicketStatusNotifier
{
    public event StatusChangedHandler? StatusChanged;

    public void Publish(string ticketId, string oldStatus, string newStatus) { ... }
}
```

CLASS CHECKLIST: output MUST contain exactly these TWO members in this order: the `StatusChangedHandler` delegate, then `TicketStatusNotifier`. Do not stop early.

BEHAVIOR (must hold exactly — this is the whole point of the task):
1. Plain `StatusChanged?.Invoke(...)` is WRONG: if one subscriber throws, the built-in multicast invocation stops calling the remaining subscribers. That MUST NOT happen here.
2. In `Publish`, get the subscriber list with `StatusChanged?.GetInvocationList()`. If null (no subscribers), return immediately — no exception.
3. Cast each entry to `StatusChangedHandler` and invoke it INSIDE its own `try/catch`, in subscription order. Every subscriber MUST be invoked exactly once, even if an earlier one threw. Collect caught exceptions into a `List<Exception>`.
4. After every subscriber has run: if the collected list is non-empty, throw `new AggregateException(collectedExceptions)`. If empty, return normally (no exception).
5. Order of subscriber invocation MUST match subscription order (`+=` order) — `GetInvocationList()` already preserves this; do not reorder.

HINT: the loop body is
```csharp
var exceptions = new List<Exception>();
foreach (var d in StatusChanged?.GetInvocationList() ?? Array.Empty<Delegate>())
{
    try { ((StatusChangedHandler)d)(ticketId, oldStatus, newStatus); }
    catch (Exception ex) { exceptions.Add(ex); }
}
if (exceptions.Count > 0) throw new AggregateException(exceptions);
```

OUTPUT: ONLY complete `TicketStatusNotifier.cs` in one fenced ```csharp block. No explanations, no other text.
