## Source A (docs/END_USER_GUIDE.md, "If something looks wrong")

You can also just ask the assistant to describe exactly what gets hidden —
it can call `describe_obfuscation_policy` and tell you, field by field, for
whichever tool you're curious about, always matching what the server is
actually configured to do right now.

## Source B (docs/TOOL_CONTRACTS.md, `ContactOutput` field table, `email` row)

| Field | Type | Source | Redaction |
|---|---|---|---|
| `email` | string, optional | `contact.email` | **obfuscated** → `{token}@obfuscated.invalid` |
