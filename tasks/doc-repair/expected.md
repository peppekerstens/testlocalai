## Top level

```yaml
mode: consistent | session-random   # required
entities: { ... }                    # required, may be empty map
nestedEntities: { ... }               # optional, defaults to {}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `mode` | enum: `"consistent"` \| `"session-random"` | yes | Any other string fails validation at startup |
| `entities` | map of string → EntityRule | yes | Key is the entity type name |
| `nestedEntities` | map of string → string | no (default `{}`) | value must be a key that exists in `entities` |
| `customFields` | CustomFieldsRule | no | Omit to disable |
