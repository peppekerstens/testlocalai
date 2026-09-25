TASK: ticket status workflow, exhaustive transition table, 6 states.
FILE: one file `TicketWorkflow.cs`. Namespace: `Bench.Workflow`.

File MUST start with this EXACT using line:
```csharp
using System;
using System.Collections.Generic;
```

WRITE TYPES IN THIS EXACT ORDER: TicketStatus enum, Ticket class, InvalidTransitionException class, TicketWorkflow class.

```csharp
namespace Bench.Workflow;

public enum TicketStatus
{
    New,
    InProgress,
    Waiting,
    Resolved,
    Closed,
    Cancelled,
}
```

```csharp
public sealed class Ticket
{
    public required string Id { get; set; }
    public TicketStatus Status { get; set; }
}
```

```csharp
public sealed class InvalidTransitionException : Exception
{
    public TicketStatus From { get; }
    public TicketStatus To { get; }

    public InvalidTransitionException(TicketStatus from, TicketStatus to)
        : base($"Cannot transition from {from} to {to}.")
    {
        From = from;
        To = to;
    }
}
```

AFTER the three types above, append TicketWorkflow with this EXACT transition table and these EXACT method signatures — copy the table verbatim, do not add, remove, or reorder any entry:

```csharp
public sealed class TicketWorkflow
{
    private static readonly Dictionary<TicketStatus, HashSet<TicketStatus>> AllowedTransitions = new()
    {
        [TicketStatus.New] = new HashSet<TicketStatus> { TicketStatus.InProgress, TicketStatus.Cancelled },
        [TicketStatus.InProgress] = new HashSet<TicketStatus> { TicketStatus.Waiting, TicketStatus.Resolved, TicketStatus.Cancelled },
        [TicketStatus.Waiting] = new HashSet<TicketStatus> { TicketStatus.InProgress, TicketStatus.Cancelled },
        [TicketStatus.Resolved] = new HashSet<TicketStatus> { TicketStatus.Closed, TicketStatus.InProgress },
        [TicketStatus.Closed] = new HashSet<TicketStatus>(),
        [TicketStatus.Cancelled] = new HashSet<TicketStatus>(),
    };

    public bool CanTransition(TicketStatus from, TicketStatus to) { ... }
    public void Transition(Ticket ticket, TicketStatus newStatus) { ... }
}
```

CLASS CHECKLIST: output MUST contain exactly these FOUR types in this order: TicketStatus, Ticket, InvalidTransitionException, TicketWorkflow. The transition table MUST have exactly 6 entries (one per status), `Closed` and `Cancelled` MUST map to an empty set. Do not stop early — this is the longest task in the suite; every type above is required, none is optional.

BEHAVIOR (must hold exactly):
1. `CanTransition(from, to)`: `true` only if `AllowedTransitions[from]` contains `to`. A status is NEVER allowed to transition to itself (no entry contains its own key) unless explicitly listed (none are).
2. `Transition(ticket, newStatus)`: `ticket == null` -> throw `ArgumentNullException` FIRST, before checking the transition table.
3. If `!CanTransition(ticket.Status, newStatus)` -> throw `new InvalidTransitionException(ticket.Status, newStatus)`. Do NOT mutate `ticket.Status` before this check — on a rejected transition, `ticket.Status` MUST remain exactly what it was.
4. If the transition is allowed, set `ticket.Status = newStatus` and return normally.
5. `Closed` and `Cancelled` are terminal: `CanTransition` returns `false` for every possible target when `from` is `Closed` or `Cancelled`, with no exceptions.
6. `Resolved -> InProgress` (reopening a resolved ticket) IS allowed — do not treat `Resolved` as terminal.

OUTPUT: ONLY complete `TicketWorkflow.cs` in one fenced ```csharp block. No explanations, no other text.
