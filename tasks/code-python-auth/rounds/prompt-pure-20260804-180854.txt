TASK: auth resolver, EXACT signature. Python equivalent of the C# `code-csharp-auth` task — same contract, expressed idiomatically in Python.
FILE: one file `auth_resolver.py`.

File MUST contain ONLY this function, no class, no imports:
```python
def resolve_user(require_auth: bool, x_dev_user: str | None) -> str:
    # implement per the behavior contract
    ...
```

BEHAVIOR (must hold exactly):
1. `x_dev_user` is not `None` and, after stripping whitespace, is not empty -> return it EXACTLY as given (do not strip it before returning; only use the stripped version to test for emptiness). (Whitespace-only counts as absent.)
2. Otherwise, `require_auth` is `True` -> raise `PermissionError` (the builtin; do not define a custom exception class, do not import anything).
3. Otherwise -> return the literal string `"anonymous"`.

RECOMMENDED SHAPE (use exactly; check whitespace FIRST, require_auth SECOND, anonymous LAST):
```python
def resolve_user(require_auth: bool, x_dev_user: str | None) -> str:
    if x_dev_user is not None and x_dev_user.strip():
        return x_dev_user
    if require_auth:
        raise PermissionError()
    return "anonymous"
```

THAT IS ALL. No headers, no tokens, no other input. Do not invent any. Implement only the three rules above. Do not add a `if __name__ == "__main__":` block or any other code — the file must contain only the one function.

OUTPUT: ONLY complete `auth_resolver.py` in one fenced ```python block. No explanations, no other text.
