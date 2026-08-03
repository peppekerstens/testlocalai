using Xunit;

namespace Bench.Workflow;

public class TicketWorkflowTests
{
    public static IEnumerable<object[]> AllowedTransitions()
    {
        yield return new object[] { TicketStatus.New, TicketStatus.InProgress };
        yield return new object[] { TicketStatus.New, TicketStatus.Cancelled };
        yield return new object[] { TicketStatus.InProgress, TicketStatus.Waiting };
        yield return new object[] { TicketStatus.InProgress, TicketStatus.Resolved };
        yield return new object[] { TicketStatus.InProgress, TicketStatus.Cancelled };
        yield return new object[] { TicketStatus.Waiting, TicketStatus.InProgress };
        yield return new object[] { TicketStatus.Waiting, TicketStatus.Cancelled };
        yield return new object[] { TicketStatus.Resolved, TicketStatus.Closed };
        yield return new object[] { TicketStatus.Resolved, TicketStatus.InProgress };
    }

    public static IEnumerable<object[]> DisallowedTransitions()
    {
        yield return new object[] { TicketStatus.New, TicketStatus.Waiting };
        yield return new object[] { TicketStatus.New, TicketStatus.Resolved };
        yield return new object[] { TicketStatus.New, TicketStatus.Closed };
        yield return new object[] { TicketStatus.New, TicketStatus.New };
        yield return new object[] { TicketStatus.InProgress, TicketStatus.Closed };
        yield return new object[] { TicketStatus.InProgress, TicketStatus.New };
        yield return new object[] { TicketStatus.InProgress, TicketStatus.InProgress };
        yield return new object[] { TicketStatus.Waiting, TicketStatus.Resolved };
        yield return new object[] { TicketStatus.Waiting, TicketStatus.Closed };
        yield return new object[] { TicketStatus.Waiting, TicketStatus.New };
        yield return new object[] { TicketStatus.Resolved, TicketStatus.Cancelled };
        yield return new object[] { TicketStatus.Resolved, TicketStatus.Waiting };
        yield return new object[] { TicketStatus.Closed, TicketStatus.InProgress };
        yield return new object[] { TicketStatus.Closed, TicketStatus.New };
        yield return new object[] { TicketStatus.Cancelled, TicketStatus.InProgress };
        yield return new object[] { TicketStatus.Cancelled, TicketStatus.New };
    }

    [Theory]
    [MemberData(nameof(AllowedTransitions))]
    public void CanTransition_AllowedPairs_ReturnsTrue(TicketStatus from, TicketStatus to)
    {
        var workflow = new TicketWorkflow();
        Assert.True(workflow.CanTransition(from, to));
    }

    [Theory]
    [MemberData(nameof(DisallowedTransitions))]
    public void CanTransition_DisallowedPairs_ReturnsFalse(TicketStatus from, TicketStatus to)
    {
        var workflow = new TicketWorkflow();
        Assert.False(workflow.CanTransition(from, to));
    }

    [Theory]
    [MemberData(nameof(AllowedTransitions))]
    public void Transition_AllowedPair_UpdatesStatus(TicketStatus from, TicketStatus to)
    {
        var workflow = new TicketWorkflow();
        var ticket = new Ticket { Id = "t1", Status = from };
        workflow.Transition(ticket, to);
        Assert.Equal(to, ticket.Status);
    }

    [Theory]
    [MemberData(nameof(DisallowedTransitions))]
    public void Transition_DisallowedPair_Throws_AndStatusUnchanged(TicketStatus from, TicketStatus to)
    {
        var workflow = new TicketWorkflow();
        var ticket = new Ticket { Id = "t1", Status = from };
        Assert.Throws<InvalidTransitionException>(() => workflow.Transition(ticket, to));
        Assert.Equal(from, ticket.Status);
    }

    [Fact]
    public void Transition_NullTicket_Throws()
    {
        var workflow = new TicketWorkflow();
        Assert.Throws<ArgumentNullException>(() => workflow.Transition(null!, TicketStatus.InProgress));
    }

    [Fact]
    public void InvalidTransitionException_ExposesFromAndTo()
    {
        var workflow = new TicketWorkflow();
        var ticket = new Ticket { Id = "t1", Status = TicketStatus.Closed };
        var ex = Assert.Throws<InvalidTransitionException>(
            () => workflow.Transition(ticket, TicketStatus.InProgress));
        Assert.Equal(TicketStatus.Closed, ex.From);
        Assert.Equal(TicketStatus.InProgress, ex.To);
    }

    [Fact]
    public void ClosedAndCancelled_AreTerminal_NoOutgoingTransitions()
    {
        var workflow = new TicketWorkflow();
        foreach (TicketStatus target in Enum.GetValues<TicketStatus>())
        {
            Assert.False(workflow.CanTransition(TicketStatus.Closed, target));
            Assert.False(workflow.CanTransition(TicketStatus.Cancelled, target));
        }
    }
}
