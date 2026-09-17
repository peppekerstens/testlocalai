using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

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

public sealed class BatchProcessor
{
    public async Task<IReadOnlyList<BatchResult<TResult>>> ProcessAsync<TItem, TResult>(
        IEnumerable<TItem> items,
        Func<TItem, CancellationToken, Task<TResult>> operation,
        CancellationToken cancellationToken = default)
    {
        if (items == null || operation == null)
            throw new ArgumentNullException(null, "items and operation must not be null");

        var itemList = items.ToList();
        var tasks = new List<Task<BatchResult<TResult>>>();

        foreach (var item in itemList)
        {
            tasks.Add(async () =>
            {
                try
                {
                    var result = await operation(item, cancellationToken);
                    return BatchResult<TResult>.Success(result);
                }
                catch (Exception ex)
                {
                    return BatchResult<TResult>.Failure(ex);
                }
            });
        }

        var results = await Task.WhenAll(tasks);
        return results.ToList();
    }
}
