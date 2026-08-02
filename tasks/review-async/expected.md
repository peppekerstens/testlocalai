```json
{ "bugs": [ { "line": "var json = _client.GetAsync($\"service/tickets?companyId={companyId}\").Result;", "issue": "Blocking on an async Task with .Result instead of awaiting it — risks a deadlock if a synchronization context is present, and even without one it ties up a thread-pool thread synchronously waiting instead of releasing it, hurting throughput under load. GetTickets should be async and await the call instead." } ] }
```
