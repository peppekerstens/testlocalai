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

RULES FOR THIS ANSWER:

1. The schema excerpt has exactly four rules: `mode`, `entities`,
   `nestedEntities`, `customFields`. Write exactly four steps, one for each
   rule, in that order.
2. Check only what the schema excerpt says. The excerpt does not define the
   inside of an EntityRule or a CustomFieldsRule. Do not name, list, or check
   the keys inside an entity rule or inside `customFields`. For `entities`,
   name only the entity type keys.
3. For every map rule, check each key-value pair on its own line. Write:
   `<map>.<key>` = `<value>`, then the verdict.
4. When a rule has a cross-reference, write the full list of keys it refers
   to. Then say if the value is in that list.
5. In the final answer, for every failed rule, give all three items:
   - the full field path, as `<map>.<key>`
   - the offending value
   - the rule text, copied word for word from the schema excerpt, in quotes.
     Do not reword the rule.
6. Do not add a fix, a suggestion, or a summary after the final answer.
