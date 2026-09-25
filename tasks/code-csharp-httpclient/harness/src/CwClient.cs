using System.Net;
using System.Net.Http;
using System.Text.Json.Nodes;
using System.Threading;
using System.Threading.Tasks;

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
        using var response = await _http.GetAsync(path, cancellationToken);
        if (response.StatusCode == HttpStatusCode.NoContent)
            return null;
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        if (string.IsNullOrWhiteSpace(body))
            return null;
        return JsonNode.Parse(body);
    }
}
