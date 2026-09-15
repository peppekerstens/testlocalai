ROLE: You are a code-review subagent. Read the C# method below and find
real bugs — do not rewrite the code, do not suggest style preferences,
only report genuine correctness bugs (something that can actually throw,
corrupt data, leak a resource, or behave wrong at runtime).

```csharp
public static class ReportExporter
{
    // Exports a company's obfuscated ticket data to a local CSV file for
    // an offline audit.
    public static void ExportToCsv(List<TicketOutput> tickets, string path)
    {
        var writer = new StreamWriter(path);
        foreach (var t in tickets)
        {
            writer.WriteLine($"{t.Id},{t.Summary}");
        }
    }
}
```

QUESTION: Is there a real bug in `ExportToCsv`? `StreamWriter` implements
`IDisposable` and buffers writes internally before they reach disk. If
there's a bug, name the exact line and explain the concrete risk. If no,
say so explicitly.

OUTPUT FORMAT (strict): a single fenced json block, nothing else:

```json
{ "bugs": [ { "line": "<the exact line of code>", "issue": "<what goes wrong and when>" } ] }
```

If there are no real bugs, use `{ "bugs": [] }`.
