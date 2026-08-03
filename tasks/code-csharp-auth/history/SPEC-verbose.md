ROLE: You are a coding subagent. Implement exactly the task below.
You are Qwen 2.5 Coder 1.5B: be conservative, prefer simple correct code,
do not add anything not requested.

TASK: Implement an authentication resolver with an EXACT signature.

FILES TO CREATE: exactly ONE file: `AuthResolver.cs`
Its namespace MUST be: `Bench.Task4`

Implement this type EXACTLY (the tests call this exact two-argument
method — do NOT add parameters, do NOT add overloads, do NOT read any
HTTP headers or environment variables):

```csharp
namespace Bench.Task4;

public sealed class AuthResolver
{
    public string ResolveUser(bool requireAuth, string? xDevUser)
    {
        // implement per the behavior contract
    }
}
```

BEHAVIOR CONTRACT (must hold exactly):
1. If `xDevUser` is non-null and non-whitespace, return it as-is.
   (Whitespace-only counts as absent.)
2. Otherwise, if `requireAuth` is true, throw `UnauthorizedAccessException`.
3. Otherwise return the literal string `"anonymous"`.

THAT IS ALL. There is no Authorization header, no token, no other input.
Do not invent any. Implement only the three rules above.

OUTPUT FORMAT: output ONLY the complete contents of the single file
`AuthResolver.cs` inside one fenced code block starting with
```csharp and ending with ```. No explanations, no other text.
