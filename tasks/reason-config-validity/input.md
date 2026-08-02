## Schema excerpt (from CONFIG_SCHEMA.md)

- `mode`: enum `"consistent"` \| `"session-random"` — required. **Any other
  string fails validation at startup.**
- `entities`: map of string → EntityRule — required, may be empty map. Key
  is the entity type name (e.g. `company`, `contact`, `member`).
- `nestedEntities`: map of string → string — optional, defaults to `{}`.
  Key is a JSON property name as it appears in a ConnectWise response
  (e.g. `defaultContact`, `owner`, `company`); **value must be a key that
  exists in `entities`.**
- `customFields`: CustomFieldsRule — optional. Omit to disable custom-field
  exclusion entirely.

## Config to check

```yaml
mode: session-random
entities:
  company: { idField: id, tokenTemplate: "C-{value}", fields: {} }
  contact: { idField: id, tokenTemplate: "K-{value}", fields: {} }
nestedEntities:
  defaultContact: owner
customFields:
  exclude: ["password"]
```
