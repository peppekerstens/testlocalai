ROLE: You are a coding subagent. Implement exactly the task below.
You are Qwen 2.5 Coder 1.5B: be conservative, prefer simple correct code,
do not add anything not requested.

TASK: Implement a text redactor that applies regex rules.

FILES TO CREATE: exactly ONE file: `Redactor.cs`
Its namespace MUST be: `Bench.Task6`

The file must contain ALL of these types, exactly as specified.

Your file MUST start with this EXACT using line as its first line:
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

BEHAVIOR CONTRACT (must hold exactly):
1. For each rule, replace every match of `rule.Regex` in the current text
   with `rule.Replacement`, using `System.Text.RegularExpressions.Regex.Replace`.
   Apply rules IN ORDER, each rule working on the result of the previous.
2. If a rule's `Regex` is invalid (Regex.Replace throws
   `ArgumentException`), SKIP that rule and continue with the next. Never
   let a bad rule abort the whole operation.
3. Empty input returns an empty string. An empty rules list leaves the
   input unchanged.

EXAMPLE (must reproduce): with rules
`email = @"\b[\w.+-]+@[\w-]+\.[\w.]+\b" -> "[EMAIL]"` and
`phone = @"\b\d{3}-\d{3}-\d{4}\b" -> "[PHONE]"`,
`Redact("Contact alice@example.com or 555-123-4567.", rules)`
returns `"Contact [EMAIL] or [PHONE]."`.

OUTPUT FORMAT: output ONLY the complete contents of the single file
`Redactor.cs` inside one fenced code block starting with
```csharp and ending with ```. No explanations, no other text.
