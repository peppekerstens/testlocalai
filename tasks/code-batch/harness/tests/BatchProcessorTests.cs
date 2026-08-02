using System.Diagnostics;
using Xunit;

namespace Bench.Batch;

public class BatchProcessorTests
{
    [Fact]
    public async Task ProcessAsync_AllSucceed_ReturnsSuccessResultsInOrder()
    {
        var processor = new BatchProcessor();
        var items = new List<int> { 1, 2, 3 };

        var results = await processor.ProcessAsync(items, (i, ct) => Task.FromResult(i * 10));

        Assert.Equal(3, results.Count);
        Assert.All(results, r => Assert.True(r.IsSuccess));
        Assert.Equal([10, 20, 30], results.Select(r => r.Value));
    }

    [Fact]
    public async Task ProcessAsync_SomeFail_CapturesFailureWithoutAbortingOthers()
    {
        var processor = new BatchProcessor();
        var items = new List<int> { 1, 2, 3 };

        var results = await processor.ProcessAsync<int, int>(items, (i, ct) =>
            i == 2 ? throw new InvalidOperationException("boom") : Task.FromResult(i * 10));

        Assert.Equal(3, results.Count);
        Assert.True(results[0].IsSuccess);
        Assert.Equal(10, results[0].Value);
        Assert.False(results[1].IsSuccess);
        Assert.IsType<InvalidOperationException>(results[1].Error);
        Assert.True(results[2].IsSuccess);
        Assert.Equal(30, results[2].Value);
    }

    [Fact]
    public async Task ProcessAsync_NullItems_Throws()
    {
        var processor = new BatchProcessor();
        await Assert.ThrowsAsync<ArgumentNullException>(
            () => processor.ProcessAsync<int, int>(null!, (i, ct) => Task.FromResult(i)));
    }

    [Fact]
    public async Task ProcessAsync_NullOperation_Throws()
    {
        var processor = new BatchProcessor();
        await Assert.ThrowsAsync<ArgumentNullException>(
            () => processor.ProcessAsync<int, int>([1, 2], null!));
    }

    [Fact]
    public async Task ProcessAsync_EmptyInput_ReturnsEmptyList()
    {
        var processor = new BatchProcessor();
        var results = await processor.ProcessAsync<int, int>([], (i, ct) => Task.FromResult(i));
        Assert.Empty(results);
    }

    [Fact]
    public async Task ProcessAsync_PreservesInputOrder()
    {
        var processor = new BatchProcessor();
        // Items with descending artificial delay so completion order is reversed,
        // but output order must still match input order.
        var items = new List<int> { 1, 2, 3 };

        var results = await processor.ProcessAsync(items, async (i, ct) =>
        {
            await Task.Delay((4 - i) * 30, ct);
            return i;
        });

        Assert.Equal([1, 2, 3], results.Select(r => r.Value));
    }

    [Fact]
    public async Task ProcessAsync_RunsConcurrently_NotSequentially()
    {
        var processor = new BatchProcessor();
        var items = Enumerable.Range(1, 5).ToList();
        var sw = Stopwatch.StartNew();

        await processor.ProcessAsync(items, async (i, ct) =>
        {
            await Task.Delay(100, ct);
            return i;
        });

        sw.Stop();
        // Sequential would take >= 500ms; concurrent should be well under that.
        Assert.True(sw.ElapsedMilliseconds < 350,
            $"expected concurrent execution, took {sw.ElapsedMilliseconds}ms");
    }

    [Fact]
    public async Task ProcessAsync_OperationCanceledException_CapturedAsFailure_NotRethrown()
    {
        var processor = new BatchProcessor();
        var items = new List<int> { 1 };

        var results = await processor.ProcessAsync<int, int>(items,
            (i, ct) => throw new OperationCanceledException());

        Assert.Single(results);
        Assert.False(results[0].IsSuccess);
        Assert.IsType<OperationCanceledException>(results[0].Error);
    }

    [Fact]
    public async Task ProcessAsync_PassesCancellationTokenThrough()
    {
        var processor = new BatchProcessor();
        using var cts = new CancellationTokenSource();
        CancellationToken? seen = null;

        await processor.ProcessAsync(new List<int> { 1 }, (i, ct) =>
        {
            seen = ct;
            return Task.FromResult(i);
        }, cts.Token);

        Assert.Equal(cts.Token, seen);
    }
}
