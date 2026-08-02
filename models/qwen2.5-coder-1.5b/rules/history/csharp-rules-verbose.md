C# CODING RULES — apply every one of these to your solution:

1. EXACT SIGNATURE. Implement precisely the types, method names, parameters,
   return types, and namespaces given in the task. Do not add overloads,
   parameters, extra methods, extra classes, or extra files.
2. EXACT CONTRACT. Implement the behavior contract verbatim. Do not invent
   behavior, headers, environment variables, or features the task did not
   mention. Nothing more, nothing less.
3. NULLABILITY. Honor `?` on types. A `string?`/`JsonNode?` return means
   null IS a valid result path; never throw instead of returning null.
4. THREAD SAFETY. Shared mutable state (caches, counters, collections used
   from many threads) MUST use System.Collections.Concurrent types and/or
   `lock(...)`. Never a plain `Dictionary`/`List` without synchronization.
5. ERROR HANDLING. Throw the exact exception type the task names. Do not
   catch and swallow exceptions unless the task explicitly says to skip.
6. ASYNC. Use `async`/`await`; never `.Result`, never `.Wait()`, never
   `GetAwaiter().GetResult()`. Always pass a `CancellationToken` through.
7. RETURN THE PRECISE TYPE. If a task says "returns JsonNode" then return
   `JsonNode?`, not `object`, not `dynamic`, not `string`.
8. DI. A service given in a constructor must come from injection. Never
   `new` up a service that should be injected; never `new` inside a method
   when a field exists.
9. SIMPLICITY. Shortest correct implementation that satisfies the contract.
   No refactoring, no unused usings, no extra feature creep, no comments
   unless asked.
10. NO EXTRA INPUTS. If the signature has N parameters, read only those.
    Do not reach for Environment variables, HttpContext, headers, or
    globals that the signature does not expose.
11. COMPLETE FILE. The output must contain EVERY type, class, and method
    the task asks for — including the ones it only names in passing. Do not
    truncate the answer; emit the whole file even if it is long. Never end
    the fenced block before every requested type is present.
12. IMPORT EVERY NAMESPACE. For every type you reference, add its `using`
    (e.g. `System.Text.RegularExpressions` for Regex,
    `System.Text.Json` for JsonException,
    `YamlDotNet.Serialization.NamingConventions` for
    CamelCaseNamingConvention, `System.Text.Json.Nodes` for JsonNode).
    Missing usings are a build error — check each referenced type has its
    import at the top of the file.
13. CANONICAL APIs. Use the exact, real API names and overloads:
    - Remove from a `ConcurrentDictionary` with `TryRemove(key, out _)`.
    - `Task.FromResult<string?>(null)` for a nullable null result.
    - `new HttpRequestException(message, innerException)` — the second
      argument must be an `Exception`, never an HttpResponseMessage.
    - `HttpClient.GetAsync(path, cancellationToken)`.
    When in doubt, use the API exactly as written in the task's example.
14. TRACE EVERY BRANCH. Walk your code line by line against each bullet of
    the behavior contract. Pay special attention to success paths (200, 204,
    NoContent), empty/null/whitespace inputs, and the "otherwise" fallbacks
    of every conditional. If a contract bullet is not covered by your
    branches, add it.
15. USING ONLY NAMESPACES. A `using` directive names a NAMESPACE, never a
    single type. Never write `using System.Threading.CancellationToken;`.
    CancellationToken lives in `System.Threading`, which is already
    imported implicitly — do not import it again.
16. USING ONLY WHAT THE TASK NEEDS. Import ONLY the namespaces for the
    libraries THIS task actually uses. Never import a namespace for a
    library the task does not use (no DI unless the task mentions
    IServiceCollection, no YamlDotNet unless the task mentions YAML, no
    regex unless the task uses Regex, no JsonNode unless the task uses it).
    Importing a package the project does not reference is a build error.

Follow the OUTPUT FORMAT exactly: one fenced code block, nothing else.
