```json
{ "bugs": [ { "line": "private readonly Dictionary<string, string> _cache = new();", "issue": "Plain Dictionary<TKey,TValue> is not thread-safe. With multiple concurrent tool calls hitting GetOrAdd at once, concurrent reads/writes can throw or corrupt the dictionary's internal state, and the ContainsKey-then-index pattern is also a check-then-act race (two threads can both see the key missing and both call factory() and write). Should use ConcurrentDictionary<string,string> (and its own GetOrAdd) instead." } ] }
```
