```json
{ "bugs": [ { "line": "var writer = new StreamWriter(path);", "issue": "writer is never disposed (no using/try-finally), so the file handle leaks and, since StreamWriter buffers writes internally, buffered lines may never actually reach disk before the process moves on." } ] }
```
