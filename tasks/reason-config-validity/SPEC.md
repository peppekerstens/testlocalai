OUTPUT DISCIPLINE — read before answering, applies to every task:

- Output ONLY the deliverable requested. Do not add wrapper tags like
  [DOC_START]/[DOC_END] unless the task explicitly asks you to use them. Do
  not add meta-commentary describing your own edit or assumptions (e.g. do
  not write "(Note: the original content is assumed present)" or "[the
  missing brace is fixed here]") — perform the edit, do not narrate it.
- When the source material or instructions give you a specific name, error
  message, field name, or tool name, reuse it EXACTLY, character-for-
  character. Do not paraphrase, generalize, or summarize it into different
  words — an exact term is a requirement, not a style choice.
- Before finalizing your answer, check it against every explicitly required
  element in the task (headings, sections, specific facts, a minimum
  length, specific tokens). A short, vague answer that omits a required
  element is wrong even when what it does say is accurate — do not
  compress your answer below what the task requires.
- For "copy exactly" or "reproduce this text" tasks: reproduce every line,
  including blank lines and fence markers (```), exactly as given. Do not
  drop, merge, or summarize any line, even ones that look redundant.
- For "apply this substitution/edit" tasks: perform the substitution
  directly in the output text itself. Do not describe the substitution in
  prose ("X replaces Y") instead of applying it, and do not leave any of
  the original (to-be-replaced) wording in the final answer.
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
