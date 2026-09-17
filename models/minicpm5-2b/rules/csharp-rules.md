# C# output rules

1. Write every line of code in full. Never write `...` in the code. The compiler rejects `...` (error CS8635). This applies to method bodies, argument lists, collection initializers, and switch arms. If a body is long, write it all.

2. Match the lambda to the delegate type of the parameter.
   - A parameter of type `Action<T>` or `Func<T, Task>` takes a lambda that does not return a value. Do not write `return someValue;` in that lambda.
   - If the lambda must give a result, the parameter must be `Func<T, TResult>` or `Func<T, Task<TResult>>`.
   - If you cannot change the parameter type, store the result in a variable or collection outside the lambda. Do not return it.
