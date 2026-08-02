using System.Net;
using System.Text.Json.Nodes;
using Xunit;

namespace Bench.Task3;

public sealed class StubHandler : HttpMessageHandler
{
    public HttpRequestMessage? Request { get; private set; }
    public Func<HttpRequestMessage, CancellationToken, HttpResponseMessage> OnSend =
        (_, _) => new HttpResponseMessage(HttpStatusCode.OK);

    protected override Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request, CancellationToken cancellationToken)
    {
        Request = request;
        cancellationToken.ThrowIfCancellationRequested();
        return Task.FromResult(OnSend(request, cancellationToken));
    }
}

public class CwClientTests
{
    [Fact]
    public async Task GetAsyncReturnsParsedJson()
    {
        var handler = new StubHandler
        {
            OnSend = (_, _) => new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("{\"id\": 7, \"name\": \"acme\"}")
            }
        };
        using var http = new HttpClient(handler) { BaseAddress = new Uri("https://api.example.com") };
        var client = new CwClient(http);

        JsonNode? node = await client.GetAsync("/companies");

        Assert.NotNull(node);
        Assert.Equal(7, node!["id"]!.GetValue<int>());
        Assert.Equal("acme", node["name"]!.GetValue<string>());
        Assert.Equal(HttpMethod.Get, handler.Request!.Method);
        Assert.Equal("/companies", handler.Request.RequestUri!.AbsolutePath);
    }

    [Fact]
    public async Task GetAsyncReturnsNullForNoContent()
    {
        var handler = new StubHandler
        {
            OnSend = (_, _) => new HttpResponseMessage(HttpStatusCode.NoContent)
        };
        using var http = new HttpClient(handler) { BaseAddress = new Uri("https://api.example.com") };
        var client = new CwClient(http);

        JsonNode? node = await client.GetAsync("/companies");

        Assert.Null(node);
    }

    [Fact]
    public async Task GetAsyncReturnsNullForEmptyOkBody()
    {
        var handler = new StubHandler
        {
            OnSend = (_, _) => new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("")
            }
        };
        using var http = new HttpClient(handler) { BaseAddress = new Uri("https://api.example.com") };
        var client = new CwClient(http);

        JsonNode? node = await client.GetAsync("/companies");

        Assert.Null(node);
    }

    [Fact]
    public async Task GetAsyncThrowsOnNonSuccess()
    {
        var handler = new StubHandler
        {
            OnSend = (_, _) => new HttpResponseMessage(HttpStatusCode.NotFound)
        };
        using var http = new HttpClient(handler) { BaseAddress = new Uri("https://api.example.com") };
        var client = new CwClient(http);

        await Assert.ThrowsAsync<HttpRequestException>(() => client.GetAsync("/companies"));
    }

    [Fact]
    public async Task GetAsyncHonorsCancellation()
    {
        var handler = new StubHandler
        {
            OnSend = (_, _) => new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent("{\"a\": 1}")
            }
        };
        using var http = new HttpClient(handler) { BaseAddress = new Uri("https://api.example.com") };
        var client = new CwClient(http);
        using var cts = new CancellationTokenSource();
        cts.Cancel();

        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => client.GetAsync("/companies", cts.Token));
    }
}
