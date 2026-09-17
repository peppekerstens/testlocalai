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

REMINDER: a code with no exception can still have a bug. Missing code is a bug too. A previous answer to this task was `{ "bugs": [] }`, and that answer was wrong.

Before you answer, do this check for every object that implements `IDisposable`:
1. Find the line that creates the object.
2. Look for a `using` statement, a `using var` declaration, or a call to `Dispose()`, `Close()`, or `Flush()` on that object.
3. If you find none, trace this case: `tickets` has 3 items. Each `WriteLine` puts text in the buffer. Then the method returns.
4. Answer two questions. How much of the text is in the file on disk after the method returns? Is the file handle still open, so that other code cannot open the file?
5. If step 2 found nothing, report the line that creates the object. In the "issue", say what data is lost and what stays open. Do not write "the writer is not disposed" only. Describe what goes wrong at runtime.
