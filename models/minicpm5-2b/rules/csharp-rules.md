# C# output rules

1. Write every line of code in full. Never write `...` in the code. The compiler rejects `...` (error CS8635). This applies to method bodies, argument lists, collection initializers, switch arms, and long expressions. If a body or a line is long, write it all.
   - Before you give the answer, find each `...` in your code. Replace it with the real code.

2. Match the lambda to the delegate type of the parameter.
   - A parameter of type `Action<T>` or `Func<T, Task>` takes a lambda that does not return a value. Do not write `return someValue;` in that lambda (errors CS8030 and CS8031).
   - If the lambda must give a result, the parameter must be `Func<T, TResult>` or `Func<T, Task<TResult>>`.
   - If you cannot change the parameter type, store the result in a variable or collection outside the lambda. Do not return it.
   - To get results from many async calls, use `Select` and `Task.WhenAll`:

```csharp
var tasks = items.Select(async item =>
{
    var result = await ProcessAsync(item);
    return result;
});
var results = await Task.WhenAll(tasks);
```
