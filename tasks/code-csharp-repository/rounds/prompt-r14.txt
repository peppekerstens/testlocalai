TASK: generic in-memory repository + factory pattern.
FILE: one file `InMemoryRepository.cs`. Namespace: `Bench.Repository`.

File MUST start with this EXACT using line:
```csharp
using System;
using System.Collections.Generic;
using System.Linq;
```

WRITE the interface FIRST, THEN InMemoryRepository<T>, THEN RepositoryFactory.

```csharp
namespace Bench.Repository;

public interface IRepository<T>
{
    void Add(string id, T item);
    T? Get(string id);
    bool Update(string id, T item);
    bool Remove(string id);
    IReadOnlyCollection<T> GetAll();
}
```

AFTER the interface, append InMemoryRepository<T> implementing it with EXACTLY these method signatures (fill in the bodies):

```csharp
public sealed class InMemoryRepository<T> : IRepository<T>
{
    private readonly Dictionary<string, T> _items = new();

    public void Add(string id, T item) { ... }
    public T? Get(string id) { ... }
    public bool Update(string id, T item) { ... }
    public bool Remove(string id) { ... }
    public IReadOnlyCollection<T> GetAll() { ... }
}
```

AFTER InMemoryRepository<T>, append RepositoryFactory with this EXACT method:

```csharp
public static class RepositoryFactory
{
    public static IRepository<T> Create<T>() => new InMemoryRepository<T>();
}
```

CLASS CHECKLIST: output MUST contain exactly these THREE types in this order: IRepository<T>, InMemoryRepository<T>, RepositoryFactory. Do not stop early.

BEHAVIOR (must hold exactly):
1. `Add`: `id == null` -> throw `ArgumentNullException`. If `id` already exists -> throw `ArgumentException` (mirrors `Dictionary<TKey,TValue>.Add`'s real behavior on a duplicate key). Otherwise store `item` under `id`.
2. `Get`: missing `id` -> return `default(T)` (i.e. `null` for reference types, `0`/`false`/etc. for value types), never throw for a missing key.
3. `Update`: missing `id` -> return `false`, do NOT throw, do NOT insert. Existing `id` -> replace the stored value, return `true`.
4. `Remove`: missing `id` -> return `false`, no throw. Existing `id` -> remove it, return `true`.
5. `GetAll`: returns a SNAPSHOT — a `List<T>` built from the current values via `.ToList()`, not a live view over `_items.Values`. A later `Add`/`Remove` MUST NOT change the size or contents of a `GetAll()` result already handed out.
6. `RepositoryFactory.Create<T>()` returns a new, independent `InMemoryRepository<T>` instance every call — never a shared/static instance.

OUTPUT: ONLY complete `InMemoryRepository.cs` in one fenced ```csharp block. No explanations, no other text.
