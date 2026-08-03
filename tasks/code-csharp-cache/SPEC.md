TASK: thread-safe token cache, capacity-based eviction.
FILE: one file `TokenCache.cs`. Namespace: `Bench.Task2`.

File MUST start with these EXACT using lines, in order:
```csharp
using System.Collections.Concurrent;
using System.Collections.Generic;
```

Implement EXACTLY this class (complete, verbatim):
```csharp
namespace Bench.Task2;

public sealed class TokenCache
{
    private readonly ConcurrentDictionary<string, string> _data = new();
    private readonly List<string> _order = new();
    private readonly int _capacity;
    private readonly object _lock = new();

    public TokenCache(int capacity)
    {
        if (capacity <= 0) throw new ArgumentOutOfRangeException(nameof(capacity));
        _capacity = capacity;
    }

    public bool TryGet(string userId, out string? token)
        => _data.TryGetValue(userId, out token);

    public void Set(string userId, string token)
    {
        lock (_lock)
        {
            if (_data.Count >= _capacity && !_data.ContainsKey(userId))
            {
                var oldest = _order[0];
                _order.RemoveAt(0);
                _data.TryRemove(oldest, out _);   // NOT _data.Remove(oldest)
            }
            _data[userId] = token;
            if (!_order.Contains(userId)) _order.Add(userId);
        }
    }
}
```

BEHAVIOR (must hold exactly):
1. `Set` stores; `TryGet` returns. Overwrite existing key keeps only newest value.
2. When distinct stored keys would exceed `capacity`, evict oldest-stored key (the one Set FIRST among current entries) so cache never holds more than `capacity` distinct keys.
3. `TryGet` on missing key returns false.
4. MUST be safe for concurrent use: many threads call `Set` and `TryGet` at the same time, no data loss, no exceptions.

Do NOT call `.Remove(key)` on ConcurrentDictionary — that overload does not exist. Use `TryRemove` as above.

OUTPUT: ONLY complete `TokenCache.cs` in one fenced ```csharp block. No explanations, no other text.
