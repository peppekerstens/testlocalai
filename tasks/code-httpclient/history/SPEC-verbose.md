ROLE: You are a coding subagent. Implement exactly the task below.
You are Qwen 2.5 Coder 1.5B: be conservative, prefer simple correct code,
do not add anything not requested.

TASK: Implement an async HTTP client method that returns a JsonNode.

FILES TO CREATE: exactly ONE file: `CwClient.cs`
Its namespace MUST be: `Bench.Task3`

Implement this type exactly:

Your file MUST start with these EXACT using lines, in this order:
```csharp
using System.Net;
using System.Net.Http;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;
```
(`System` and `System.Text.Json` are implicitly available; do not import
single types — `CancellationToken` is a type in `System.Threading`, never
write `using System.Threading.CancellationToken;`.)

```csharp
namespace Bench.Task3;

public sealed class CwClient
{
    private readonly HttpClient _http;

    public CwClient(HttpClient httpClient)
    {
        _http = httpClient;
    }

    public async Task<System.Text.Json.Nodes.JsonNode?> GetAsync(
        string path, CancellationToken cancellationToken = default)
    {
        // implement per the behavior contract
    }
}
```

BEHAVIOR CONTRACT (must hold exactly):
1. Perform a GET request for `path`. `path` is relative to the client's
   BaseAddress (e.g. "/companies"). Pass `cancellationToken` through to
   the HttpClient call.
2. If the response status is 204 No Content (or the body is empty),
   return null.
3. If the response status is NOT a 2xx success status, throw
   `HttpRequestException` (use `response.EnsureSuccessStatusCode()`).
4. Otherwise read the body text and parse it with
   `System.Text.Json.Nodes.JsonNode.Parse(body)` and return the node.
   Return null if the body is empty or whitespace.
5. If the caller's cancellation token is canceled, the call must throw
   (the HttpClient will throw OperationCanceledException when the token
   is passed through).

Use EXACTLY this method body shape (do not add extra throw statements,
do not pass `response` to an exception constructor — the second argument
of `HttpRequestException` must be an `Exception`, not an
`HttpResponseMessage`):

```csharp
using var response = await _http.GetAsync(path, cancellationToken);
if (response.StatusCode == HttpStatusCode.NoContent)
    return null;
response.EnsureSuccessStatusCode();
var body = await response.Content.ReadAsStringAsync(cancellationToken);
if (string.IsNullOrWhiteSpace(body))
    return null;
return JsonNode.Parse(body);
```
(`HttpStatusCode` is `System.Net.HttpStatusCode`; add the appropriate
using if needed.)

DO NOT use `GetFromJsonAsync<T>` returning objects; the return type must
be `JsonNode?` exactly.

OUTPUT FORMAT: output ONLY the complete contents of the single file
`CwClient.cs` inside one fenced code block starting with
```csharp and ending with ```. No explanations, no other text.
