TASK: async batch processor, concurrent, one item's failure must not lose the others.
FILE: one file `BatchProcessor.cs`. Namespace: `Bench.Batch`.

File MUST start with this EXACT using line:
```csharp
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
```

WRITE BatchResult<T> FIRST with EXACTLY this shape, THEN BatchProcessor.

```csharp
namespace Bench.Batch;

public sealed class BatchResult<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public Exception? Error { get; }

    private BatchResult(bool isSuccess, T? value, Exception? error)
    {
        IsSuccess = isSuccess;
        Value = value;
        Error = error;
    }

    public static BatchResult<T> Success(T value) => new(true, value, null);
    public static BatchResult<T> Failure(Exception error) => new(false, default, error);
}
```

AFTER BatchResult<T>, append BatchProcessor with this EXACT method signature:

```csharp
public sealed class BatchProcessor
{
    public async Task<IReadOnlyList<BatchResult<TResult>>> ProcessAsync<TItem, TResult>(
        IEnumerable<TItem> items,
        Func<TItem, CancellationToken, Task<TResult>> operation,
        CancellationToken cancellationToken = default)
    {
        ...
    }
}
```

CLASS CHECKLIST: output MUST contain exactly these TWO types in this order: BatchResult<T>, BatchProcessor. Do not stop early.

BEHAVIOR (must hold exactly):
1. `items == null` or `operation == null` -> throw `ArgumentNullException` BEFORE starting any work.
2. Materialize `items` into a `List<TItem>` ONCE (do not enumerate the parameter more than once).
3. Run every item CONCURRENTLY — build one `Task<BatchResult<TResult>>` per item (do not `await` inside the loop that starts them) and `await Task.WhenAll(...)` on the whole array/list. Never process items one at a time sequentially.
4. Each per-item task calls `operation(item, cancellationToken)` inside its own `try/catch (Exception ex)`. On success, wrap the value with `BatchResult<TResult>.Success(value)`. On ANY exception — including `OperationCanceledException` — wrap it with `BatchResult<TResult>.Failure(ex)`. `ProcessAsync` itself must NEVER throw because one item's `operation` threw.
5. The returned list has exactly one `BatchResult` per input item, in the SAME order as the input — order must hold even though execution is concurrent (build the per-item tasks in a list indexed by input position, then `Task.WhenAll` that list; `Task.WhenAll` preserves the order of the array/list you pass it).
6. Empty `items` -> return an empty list, no exception.

HINT: shape is
```csharp
var itemList = items.ToList();
var tasks = itemList.Select(async item =>
{
    try { return BatchResult<TResult>.Success(await operation(item, cancellationToken)); }
    catch (Exception ex) { return BatchResult<TResult>.Failure(ex); }
}).ToList();
return await Task.WhenAll(tasks);
```

OUTPUT: ONLY complete `BatchProcessor.cs` in one fenced ```csharp block. No explanations, no other text.
