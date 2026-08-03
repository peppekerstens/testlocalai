TASK: DI tool reading tickets from injected store. Store resolved from DI, never created manually.
FILE: one file `TicketTool.cs`. Namespace: `Bench.Task5`.

File MUST contain ALL of these, exactly as specified.

File MUST start with this EXACT using line as its first line:
```csharp
using Microsoft.Extensions.DependencyInjection;
```
NO other using lines. This task uses no YamlDotNet, no Regex, no Json, no Http — do not import them.

Then namespace and types:
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

Use EXACTLY this shape inside GetTicketAsync (null branch needs explicit generic — `Task.FromResult(null)` does NOT compile):
```csharp
public Task<string?> GetTicketAsync(int id)
{
    if (id == 1) return Task.FromResult("Ticket 1");
    if (id == 2) return Task.FromResult("Ticket 2");
    return Task.FromResult<string?>(null);
}
```

Then implement:
1. `TicketTool` class, constructor takes `ITicketStore store`, stores in private readonly field. ONE method:
   ```csharp
   public string? GetTicket(int id)
   {
       // returns store.GetTicketAsync(id) result, synchronously;
       // never creates an ITicketStore itself
   }
   ```
2. Static extension class:
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
   Use `Microsoft.Extensions.DependencyInjection` (package already referenced; add correct `using` at top).

BEHAVIOR:
1. `GetTicket(1)` returns non-null string containing char "1".
2. `GetTicket(999)` returns null.
3. `TicketTool` obtains store via constructor injection only.

OUTPUT: ONLY complete `TicketTool.cs` in one fenced ```csharp block. No explanations, no other text.
