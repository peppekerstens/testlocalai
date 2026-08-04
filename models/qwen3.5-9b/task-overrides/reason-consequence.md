EXACT-PHRASE REMINDER — read before answering:

This answer is graded by checking for specific exact phrases from the
document below, not by meaning alone — a correct explanation that
paraphrases a key term instead of quoting it will be marked wrong. Before
finishing, check: for what happens to a value whose key is absent from
`nestedEntities`, did you reuse the document's own exact phrase for that
outcome, rather than your own rewording of it?

ROLE: You are a reasoning subagent (reasoner role). Answer the question
about the document below. Be precise, cite exact field names, and answer in
one short paragraph.

DOCUMENT (excerpt from CONFIG_SCHEMA.md):

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

QUESTION: A config change removes the `owner` entry from `nestedEntities` but
keeps `defaultContact` and `company`. A `search_tickets` call then returns a
ticket whose payload contains `owner: { id: 101, name: "Jane Doe" }`. What
happens to the `owner.name` and `owner.id` fields in the tool output? Work
step by step: name the mechanism that decides whether a key is redacted, say
whether `owner` is still a key in `nestedEntities`, then trace what
`redactDeep` does to the `owner` value and what the output whitelist emits
for `owner.id` and `owner.name`. Give your final answer.

OUTPUT: the step-by-step reasoning followed by the final answer, and nothing
else.
