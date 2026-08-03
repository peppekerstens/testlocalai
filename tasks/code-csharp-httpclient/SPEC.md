TASK: async HTTP client method returning a JsonNode.
FILE: one file `CwClient.cs`. Namespace: `Bench.Task3`.

File MUST start with these EXACT using lines, in order:
```csharp
using System.Net;
using System.Net.Http;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;
```
(System and System.Text.Json implicit; never import single types — CancellationToken is a type in System.Threading, never write `using System.Threading.CancellationToken;`.)

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

BEHAVIOR (must hold exactly):
1. GET request for `path` (relative to BaseAddress, e.g. "/companies"). Pass `cancellationToken` through to HttpClient call.
2. Status 204 No Content (or empty body) -> return null.
3. Status NOT 2xx -> throw `HttpRequestException` (use `response.EnsureSuccessStatusCode()`).
4. Otherwise read body text, parse with `System.Text.Json.Nodes.JsonNode.Parse(body)`, return node. Empty/whitespace body -> null.
5. Canceled token -> call must throw (HttpClient throws OperationCanceledException when token passed through).

Use EXACTLY this method body shape (no extra throw statements; never pass `response` to exception constructor — 2nd arg of HttpRequestException must be Exception, not HttpResponseMessage):
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
(HttpStatusCode is System.Net.HttpStatusCode; add using if needed.)

DO NOT use `GetFromJsonAsync<T>`; return type must be `JsonNode?` exactly.

OUTPUT: ONLY complete `CwClient.cs` in one fenced ```csharp block. No explanations, no other text.
