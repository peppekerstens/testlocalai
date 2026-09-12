ROLE: You are a reasoning subagent. Answer the question about the document
below. Be precise, cite exact field names from the document, and answer in
one short paragraph.

DOCUMENT:

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

QUESTION: Is this config valid per the schema? Work step by step: go through
each schema rule in the DOCUMENT, name the field that rule applies to, check
the config's value against it (checking any cross-references the rule
requires), and record a verdict for that rule. Then give your final answer:
the config is valid, or the list of every rule that failed, the offending
field and value, and the exact rule it breaks.

REMINDER: `idField`, `tokenTemplate`, and `fields` are values inside one
entity's own config block, not schema-level field names from the DOCUMENT
above. Check the config only against the four schema rules actually
listed (`mode`, `entities`, `nestedEntities`, `customFields`). Do not
treat `idField`/`tokenTemplate`/`fields` as if the schema itself defined
rules for them — it does not.

OUTPUT: the step-by-step verification followed by the final answer, and
nothing else.
</content>
