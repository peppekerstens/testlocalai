using Xunit;

namespace Bench.Task6;

public class RedactorTests
{
    [Fact]
    public void RedactsEmailsAndPhones()
    {
        var redactor = new Redactor();
        var rules = new List<PatternRule>
        {
            new() { Name = "email", Regex = @"\b[\w.+-]+@[\w-]+\.[\w.]+\b", Replacement = "[EMAIL]" },
            new() { Name = "phone", Regex = @"\b\d{3}-\d{3}-\d{4}\b", Replacement = "[PHONE]" }
        };

        var result = redactor.Redact("Contact alice@example.com or 555-123-4567.", rules);

        Assert.Equal("Contact [EMAIL] or [PHONE].", result);
    }

    [Fact]
    public void SkipsInvalidRegexRuleButAppliesOthers()
    {
        var redactor = new Redactor();
        var rules = new List<PatternRule>
        {
            new() { Name = "bad", Regex = "[", Replacement = "X" },
            new() { Name = "email", Regex = @"\b[\w.+-]+@[\w-]+\.[\w.]+\b", Replacement = "[EMAIL]" }
        };

        var result = redactor.Redact("Hi alice@example.com", rules);

        Assert.Equal("Hi [EMAIL]", result);
    }

    [Fact]
    public void RulesChainInOrder_EachOnPreviousResult()
    {
        // Rule 1 turns "cat" into "dog"; rule 2 turns "dog" into "fish". If
        // rules ran in the wrong order, or each ran against the ORIGINAL
        // input instead of the previous rule's output, the result would be
        // "dog" (or unchanged), never "fish".
        var redactor = new Redactor();
        var rules = new List<PatternRule>
        {
            new() { Name = "r1", Regex = "cat", Replacement = "dog" },
            new() { Name = "r2", Regex = "dog", Replacement = "fish" },
        };

        var result = redactor.Redact("I have a cat", rules);

        Assert.Equal("I have a fish", result);
    }

    [Fact]
    public void EmptyInputReturnsEmpty()
    {
        var redactor = new Redactor();
        Assert.Equal("", redactor.Redact("", new List<PatternRule>()));
    }

    [Fact]
    public void NoRulesLeavesInputUnchanged()
    {
        var redactor = new Redactor();
        Assert.Equal("plain text", redactor.Redact("plain text", new List<PatternRule>()));
    }
}
