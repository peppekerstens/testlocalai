using Xunit;

namespace Bench.Stats;

/// Enumerable that throws if GetEnumerator() is called more than once —
/// forces the method under test to enumerate its input exactly once.
public sealed class SingleUseEnumerable<T> : IEnumerable<T>
{
    private readonly IEnumerable<T> _source;
    private int _enumerations;

    public SingleUseEnumerable(IEnumerable<T> source) => _source = source;

    public IEnumerator<T> GetEnumerator()
    {
        if (++_enumerations > 1)
        {
            throw new InvalidOperationException("Enumerated more than once.");
        }
        return _source.GetEnumerator();
    }

    System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator() => GetEnumerator();
}

public class TicketStatsAggregatorTests
{
    private static List<Ticket> SampleTickets() =>
    [
        new("Open", 1),
        new("Open", 3),
        new("Closed", 2),
        new("Open", 5),
        new("Waiting", 2),
        new("Closed", 4),
    ];

    [Fact]
    public void CountByStatus_CountsEachStatus()
    {
        var agg = new TicketStatsAggregator();
        var counts = agg.CountByStatus(SampleTickets());
        Assert.Equal(3, counts["Open"]);
        Assert.Equal(2, counts["Closed"]);
        Assert.Equal(1, counts["Waiting"]);
        Assert.Equal(3, counts.Count);
    }

    [Fact]
    public void CountByStatus_EmptyInput_ReturnsEmptyDictionary()
    {
        var agg = new TicketStatsAggregator();
        var counts = agg.CountByStatus([]);
        Assert.Empty(counts);
    }

    [Fact]
    public void CountByStatus_NullInput_Throws()
    {
        var agg = new TicketStatsAggregator();
        Assert.Throws<ArgumentNullException>(() => agg.CountByStatus(null!));
    }

    [Fact]
    public void AverageOpenPriority_AveragesOnlyOpenTickets()
    {
        var agg = new TicketStatsAggregator();
        // Open priorities: 1, 3, 5 -> average 3.0
        Assert.Equal(3.0, agg.AverageOpenPriority(SampleTickets()));
    }

    [Fact]
    public void AverageOpenPriority_NoOpenTickets_ReturnsZero()
    {
        var agg = new TicketStatsAggregator();
        var tickets = new List<Ticket> { new("Closed", 5), new("Waiting", 2) };
        Assert.Equal(0.0, agg.AverageOpenPriority(tickets));
    }

    [Fact]
    public void AverageOpenPriority_EmptyInput_ReturnsZero()
    {
        var agg = new TicketStatsAggregator();
        Assert.Equal(0.0, agg.AverageOpenPriority([]));
    }

    [Fact]
    public void AverageOpenPriority_NullInput_Throws()
    {
        var agg = new TicketStatsAggregator();
        Assert.Throws<ArgumentNullException>(() => agg.AverageOpenPriority(null!));
    }

    [Fact]
    public void AverageOpenPriority_IsCaseSensitive_ToOpenStatus()
    {
        var agg = new TicketStatsAggregator();
        var tickets = new List<Ticket> { new("open", 10), new("OPEN", 20) };
        // Neither matches the exact "Open" status, so average is 0.
        Assert.Equal(0.0, agg.AverageOpenPriority(tickets));
    }

    [Fact]
    public void TopStatuses_OrdersByCountDescending_ThenAlphabetically()
    {
        var agg = new TicketStatsAggregator();
        var top = agg.TopStatuses(SampleTickets(), 2);
        Assert.Equal(["Open", "Closed"], top);
    }

    [Fact]
    public void TopStatuses_TieBrokenAlphabetically()
    {
        var agg = new TicketStatsAggregator();
        var tickets = new List<Ticket> { new("Zeta", 1), new("Alpha", 1), new("Beta", 1) };
        var top = agg.TopStatuses(tickets, 3);
        Assert.Equal(["Alpha", "Beta", "Zeta"], top);
    }

    [Fact]
    public void TopStatuses_NLargerThanDistinctCount_ReturnsAllDistinct()
    {
        var agg = new TicketStatsAggregator();
        var top = agg.TopStatuses(SampleTickets(), 100);
        Assert.Equal(3, top.Count);
    }

    [Fact]
    public void TopStatuses_NZero_ReturnsEmpty()
    {
        var agg = new TicketStatsAggregator();
        Assert.Empty(agg.TopStatuses(SampleTickets(), 0));
    }

    [Fact]
    public void TopStatuses_NullInput_Throws()
    {
        var agg = new TicketStatsAggregator();
        Assert.Throws<ArgumentNullException>(() => agg.TopStatuses(null!, 2));
    }

    [Fact]
    public void TopStatuses_EnumeratesInputOnlyOnce()
    {
        var agg = new TicketStatsAggregator();
        var single = new SingleUseEnumerable<Ticket>(SampleTickets());
        var top = agg.TopStatuses(single, 2);
        Assert.Equal(["Open", "Closed"], top);
    }
}
