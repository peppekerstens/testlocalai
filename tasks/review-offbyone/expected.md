```json
{ "bugs": [ { "line": "for (int start = 0; start <= items.Count; start += pageSize)", "issue": "The outer loop condition is start <= items.Count instead of start < items.Count. When items.Count is exactly divisible by pageSize, start eventually equals items.Count exactly, the condition is still true, and one extra empty trailing page is added to the result." } ] }
```
