using Xunit;

namespace Bench.Task2;

public class TokenCacheTests
{
    [Fact]
    public void SetThenGet()
    {
        var cache = new TokenCache(16);
        cache.Set("u1", "tok1");
        Assert.True(cache.TryGet("u1", out var tok));
        Assert.Equal("tok1", tok);
        Assert.False(cache.TryGet("nope", out _));
    }

    [Fact]
    public void OverwriteKeepsLatest()
    {
        var cache = new TokenCache(16);
        cache.Set("u1", "old");
        cache.Set("u1", "new");
        Assert.True(cache.TryGet("u1", out var tok));
        Assert.Equal("new", tok);
    }

    [Fact]
    public void ZeroCapacity_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new TokenCache(0));
    }

    [Fact]
    public void NegativeCapacity_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new TokenCache(-1));
    }

    [Fact]
    public void EvictsOldestWhenOverCapacity()
    {
        var cache = new TokenCache(2);
        cache.Set("a", "1");
        cache.Set("b", "2");
        cache.Set("c", "3");
        Assert.False(cache.TryGet("a", out _));
        Assert.True(cache.TryGet("b", out _));
        Assert.True(cache.TryGet("c", out _));
    }

    [Fact]
    public void ConcurrentSetsAreNotLost()
    {
        var cache = new TokenCache(8000);
        var threads = new List<Thread>();
        for (int t = 0; t < 8; t++)
        {
            int tid = t;
            threads.Add(new Thread(() =>
            {
                for (int i = 0; i < 500; i++)
                    cache.Set($"u{tid}-{i}", $"tok{tid}-{i}");
            }));
        }
        threads.ForEach(th => th.Start());
        threads.ForEach(th => th.Join());

        for (int t = 0; t < 8; t++)
            for (int i = 0; i < 500; i++)
            {
                Assert.True(cache.TryGet($"u{t}-{i}", out var tok), $"lost key u{t}-{i}");
                Assert.Equal($"tok{t}-{i}", tok);
            }
    }
}
