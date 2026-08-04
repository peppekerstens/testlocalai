using System.Collections.Concurrent;
using System.Collections.Generic;

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
    {
        lock (_lock)
        {
            if (_data.TryGetValue(userId, out token))
                return true;
            return false;
        }
    }

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
