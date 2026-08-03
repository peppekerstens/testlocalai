using Xunit;

namespace Bench.Events;

public class TicketStatusNotifierTests
{
    [Fact]
    public void Publish_NoSubscribers_DoesNotThrow()
    {
        var notifier = new TicketStatusNotifier();
        var ex = Record.Exception(() => notifier.Publish("t1", "Open", "Closed"));
        Assert.Null(ex);
    }

    [Fact]
    public void Publish_InvokesAllSubscribers_InOrder_WithCorrectArgs()
    {
        var notifier = new TicketStatusNotifier();
        var calls = new List<string>();
        notifier.StatusChanged += (id, oldS, newS) => calls.Add($"A:{id}:{oldS}:{newS}");
        notifier.StatusChanged += (id, oldS, newS) => calls.Add($"B:{id}:{oldS}:{newS}");

        notifier.Publish("t1", "Open", "Closed");

        Assert.Equal(["A:t1:Open:Closed", "B:t1:Open:Closed"], calls);
    }

    [Fact]
    public void Publish_OneHandlerThrows_OtherHandlersStillRun()
    {
        var notifier = new TicketStatusNotifier();
        var calls = new List<string>();
        notifier.StatusChanged += (id, oldS, newS) => calls.Add("first");
        notifier.StatusChanged += (id, oldS, newS) => throw new InvalidOperationException("boom");
        notifier.StatusChanged += (id, oldS, newS) => calls.Add("third");

        Assert.Throws<AggregateException>(() => notifier.Publish("t1", "Open", "Closed"));

        Assert.Equal(["first", "third"], calls);
    }

    [Fact]
    public void Publish_HandlerThrows_AggregateExceptionWrapsIt()
    {
        var notifier = new TicketStatusNotifier();
        notifier.StatusChanged += (id, oldS, newS) => throw new InvalidOperationException("boom");

        var ex = Assert.Throws<AggregateException>(() => notifier.Publish("t1", "Open", "Closed"));
        Assert.Single(ex.InnerExceptions);
        Assert.IsType<InvalidOperationException>(ex.InnerExceptions[0]);
    }

    [Fact]
    public void Publish_MultipleHandlersThrow_AllCapturedInAggregateException()
    {
        var notifier = new TicketStatusNotifier();
        notifier.StatusChanged += (id, oldS, newS) => throw new InvalidOperationException("first");
        notifier.StatusChanged += (id, oldS, newS) => throw new ArgumentException("second");

        var ex = Assert.Throws<AggregateException>(() => notifier.Publish("t1", "Open", "Closed"));
        Assert.Equal(2, ex.InnerExceptions.Count);
    }

    [Fact]
    public void Unsubscribe_RemovedHandler_IsNotInvoked()
    {
        var notifier = new TicketStatusNotifier();
        var calls = new List<string>();
        void Handler(string id, string oldS, string newS) => calls.Add("handler");

        notifier.StatusChanged += Handler;
        notifier.StatusChanged -= Handler;
        notifier.Publish("t1", "Open", "Closed");

        Assert.Empty(calls);
    }
}
