ROLE: You are a code-review subagent. Read the C# method below and find
real bugs — do not rewrite the code, do not suggest style preferences,
only report genuine correctness bugs (something that can actually throw,
corrupt data, or behave wrong at runtime). Do not report something as a
bug unless you can point to a concrete input that actually triggers wrong
behavior — a hypothetical concern that isn't actually triggerable is not
a bug.

```csharp
public class CompanyOutput
{
    public int Id { get; set; }
    public string? DefaultContactName { get; set; }
}

public static class CompanyMapper
{
    // company.DefaultContact is optional — ConnectWise does not always
    // return it for every company.
    public static CompanyOutput Build(Company company)
    {
        var output = new CompanyOutput { Id = company.Id };
        output.DefaultContactName = company.DefaultContact?.Name;
        return output;
    }
}
```

QUESTION: Is there a real bug in `Build`? If yes, name the exact line and
explain what goes wrong and when. If no, say so explicitly — do not
invent a bug just to have something to report.

OUTPUT FORMAT (strict): a single fenced json block, nothing else:

```json
{ "bugs": [ { "line": "<the exact line of code>", "issue": "<what goes wrong and when>" } ] }
```

If there are no real bugs, use `{ "bugs": [] }`.

REMINDER: a previous answer to this task was wrong. It was:

```json
{ "bugs": [ { "line": "var output = new CompanyOutput { Id = company.Id };", "issue": "If company is null, a NullReferenceException is thrown when accessing company.Id" } ] }
```

That answer reported a hypothetical input. Nothing in the code or in the comment says that `company` can be null. The comment says only that `company.DefaultContact` can be missing. "What if the argument is null" is true for almost every method, so it is not a bug in this method.

Before you answer, do this check for every bug you want to report:
1. Write down the input that triggers it.
2. Find the text in the code or in the comment that says this input can occur. If you find no such text, delete the bug.
3. For the optional value the comment names, trace this case: `company.DefaultContact` is null.
4. Answer three questions. What does `company.DefaultContact?.Name` give when `DefaultContact` is null? Can `DefaultContactName` (type `string?`) hold that value? Does any line throw?
5. Report a bug only if step 2 found text and step 4 shows a throw or a wrong value. Otherwise, use `{ "bugs": [] }`.
