## nestedEntities

```yaml
nestedEntities:
  defaultContact: contact
  owner: member
  company: company
```

Applied by `redactDeep` (`src/obfuscation/redactor.ts`), which walks the
**entire** response tree recursively and asks, for every JSON property name
it encounters at any depth: *is this key present in `nestedEntities`?* If
yes, its value is treated as an instance of the named entity type (looked up
in `entities`) and redacted with that entity's `fields` rule, regardless of
how deep the key is nested. If a key is absent from this map, its value
passes through completely untouched, however deep it is nested and whatever
shape it has.

This is why the map is keyed by **JSON property name**, not by object shape
or type: ConnectWise embeds harmless lookup objects (`status`, `territory`,
`priority`, `board` — all shaped `{ id, name }`) at the same depths as real
PII (`defaultContact`, `owner` — also shaped `{ id, name }`). Only the key
name distinguishes them. A property name deliberately left out of this map
passes through even if its value happens to have an `id`/`name` shape
identical to a redactable entity.

## search_tickets output (TOOL_CONTRACTS.md)

- `owner.id` → passthrough
- `owner.name` → **obfuscated** (nested `member` entity)
