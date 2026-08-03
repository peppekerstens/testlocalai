ROLE: You are a coding subagent. Implement exactly the task below.
You are Qwen 2.5 Coder 1.5B: be conservative, prefer simple correct code,
do not add anything not requested.

TASK: Implement a dependency-injected tool that reads tickets from an
injected store. The store is resolved from DI, never created manually.

FILES TO CREATE: exactly ONE file: `TicketTool.cs`
Its namespace MUST be: `Bench.Task5`

The file must contain ALL of these, exactly as specified.

The file MUST start with this EXACT using line as its first line:
```csharp
using Microsoft.Extensions.DependencyInjection;
```

Then the namespace and types:

```csharp
namespace Bench.Task5;

public interface ITicketStore
{
    Task<string?> GetTicketAsync(int id);
}

public sealed class InMemoryTicketStore : ITicketStore
{
    public Task<string?> GetTicketAsync(int id)
    {
        // id 1 -> "Ticket 1"; id 2 -> "Ticket 2"; any other id -> null
    }
}
```

Use EXACTLY this shape inside GetTicketAsync (the null branch needs an
explicit generic — `Task.FromResult(null)` does NOT compile):

```csharp
public Task<string?> GetTicketAsync(int id)
{
    if (id == 1) return Task.FromResult("Ticket 1");
    if (id == 2) return Task.FromResult("Ticket 2");
    return Task.FromResult<string?>(null);
}
```

Then implement:
1. A `TicketTool` class with a constructor that takes
   `ITicketStore store` and stores it in a private readonly field. The
   tool has ONE method:
   ```csharp
   public string? GetTicket(int id)
   {
       // returns store.GetTicketAsync(id) result, synchronously;
       // never creates an ITicketStore itself
   }
   ```
2. A static extension class:
   ```csharp
   public static class TicketServiceCollectionExtensions
   {
       public static IServiceCollection AddTicketTool(this IServiceCollection services)
       {
           // register InMemoryTicketStore as ITicketStore (singleton)
           // register TicketTool (singleton)
           return services;
       }
   }
   ```
   Use `Microsoft.Extensions.DependencyInjection` (the package is already
   referenced; add the correct `using` at the top).

BEHAVIOR CONTRACT:
1. `GetTicket(1)` returns a non-null string containing the character "1".
2. `GetTicket(999)` returns null.
3. `TicketTool` must obtain its store via constructor injection only.

OUTPUT FORMAT: output ONLY the complete contents of the single file
`TicketTool.cs` inside one fenced code block starting with
```csharp and ending with ```. No explanations, no other text.
