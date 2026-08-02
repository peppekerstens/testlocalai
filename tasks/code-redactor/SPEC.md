TASK: text redactor applying regex rules.
FILE: one file `Redactor.cs`. Namespace: `Bench.Task6`.

File MUST contain ALL of these, exactly as specified.

File MUST start with this EXACT using line as its first line:
```csharp
using System.Text.RegularExpressions;
```

```csharp
namespace Bench.Task6;

public sealed class PatternRule
{
    public string Name { get; set; } = "";
    public string Regex { get; set; } = "";
    public string Replacement { get; set; } = "";
}

public sealed class Redactor
{
    public string Redact(string input, IReadOnlyList<PatternRule> rules)
    {
        // implement per the behavior contract
    }
}
```

BEHAVIOR (must hold exactly):
1. For each rule, replace every match of `rule.Regex` in current text with `rule.Replacement`, using `System.Text.RegularExpressions.Regex.Replace`. Apply rules IN ORDER, each rule working on the result of the previous.
2. Invalid `rule.Regex` (Regex.Replace throws `ArgumentException`) -> SKIP that rule and continue with next. Never let a bad rule abort the operation.
3. Empty input -> empty string. Empty rules list -> input unchanged.

EXAMPLE (must reproduce): rules
`email = @"\b[\w.+-]+@[\w-]+\.[\w.]+\b" -> "[EMAIL]"` and
`phone = @"\b\d{3}-\d{3}-\d{4}\b" -> "[PHONE]"`,
`Redact("Contact alice@example.com or 555-123-4567.", rules)`
returns `"Contact [EMAIL] or [PHONE]."`.

OUTPUT: ONLY complete `Redactor.cs` in one fenced ```csharp block. No explanations, no other text.
