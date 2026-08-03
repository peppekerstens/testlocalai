TASK: auth resolver, EXACT signature.
FILE: one file `AuthResolver.cs`. Namespace: `Bench.Task4`.

Type EXACTLY (tests call this exact two-argument method — no added parameters, no overloads, no reading HTTP headers or env vars):
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

BEHAVIOR (must hold exactly):
1. `xDevUser` non-null and non-whitespace -> return it as-is. (Whitespace-only counts as absent.)
2. Otherwise, `requireAuth` true -> throw `UnauthorizedAccessException`.
3. Otherwise return literal string `"anonymous"`.

RECOMMENDED SHAPE (use exactly; check whitespace FIRST, requireAuth SECOND, anonymous LAST):
```csharp
public string ResolveUser(bool requireAuth, string? xDevUser)
{
    if (!string.IsNullOrWhiteSpace(xDevUser))
        return xDevUser;
    if (requireAuth)
        throw new UnauthorizedAccessException();
    return "anonymous";
}
```

THAT IS ALL. No Authorization header, no token, no other input. Do not invent any. Implement only the three rules above.

OUTPUT: ONLY complete `AuthResolver.cs` in one fenced ```csharp block. No explanations, no other text.
