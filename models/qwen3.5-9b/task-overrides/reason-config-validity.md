EXACT-PHRASE REMINDER — read before answering:

This answer is graded by checking for specific exact tokens, not by meaning
alone. Two rules:

1. Your verdict must name exactly ONE broken rule: `nestedEntities.
   defaultContact` has value `owner`, but `owner` is not a key in
   `entities` — the schema requires every `nestedEntities` value to
   exist as an `entities` key. Say this using the words `owner`,
   `nestedEntities`, and `entities`.
2. Do NOT mention `idField`, `tokenTemplate`, or any `CW_` environment
   variable anywhere in your answer, even in passing, even to say they
   look fine. Those fields are valid and irrelevant to the one real
   violation — restating their names (even to clear them) is marked
   wrong. Cover `mode` and `customFields` only by saying they are valid,
   without naming their internal field values.

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

OUTPUT: the step-by-step verification followed by the final answer, and
nothing else.
