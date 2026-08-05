EDIT-COMPLETENESS REMINDER (read before extracting):

The sentence "No priority or board has been set yet" is NEGATION
language stating that NO value exists for `priority` and `board`. It
is NOT a value itself, and it is NOT a value for `status` either. Do
not copy this sentence, any fragment of it, or any paraphrase of it
into ANY field of the output JSON — not into `status`, not into
`priority`, not into `board`, nowhere.

Before writing the JSON, check each optional field one at a time:
- Does the text give `status` an explicit, specific status word (e.g.
  "open", "closed", "in progress")? If not found verbatim/explicitly
  stated as a status, OMIT the `status` key entirely.
- Does the text give `priority` an explicit, specific priority word
  (e.g. "high", "low", "P1")? If not — and a sentence saying "no
  priority... has been set" is explicit confirmation it does NOT —
  OMIT the `priority` key entirely.
- Does the text give `board` an explicit, specific board name? If
  not — same negation sentence confirms it does NOT — OMIT the
  `board` key entirely.

A sentence stating a field has "not been set" is the strongest
possible signal to OMIT that key, never a signal to fill it with that
sentence's text. Do not treat "there is leftover unclassified text in
the passage" as a reason to assign it to any remaining empty field —
if leftover text doesn't name a specific value for a specific field,
it corresponds to no field at all and is simply not used in the
output.

---

ROLE: You are a structured-extraction subagent. Extract fields from the
free text below into the exact JSON schema given.

SCHEMA (all fields except `id` and `summary` are OPTIONAL):

```json
{
  "id": number,
  "summary": string,
  "status": string,      // optional
  "priority": string,    // optional
  "board": string        // optional
}
```

RULE: this project's real convention (from its own tool output code) is
that a field the source text doesn't actually mention is OMITTED from the
JSON entirely — it is NEVER emitted as `null`, an empty string, or a
guessed/inferred value. Follow that same rule here.

TEXT: "Ticket #7788 — 'Printer offline in accounting department'. No
priority or board has been set yet."

QUESTION: Which fields does the text actually give a value for, and which
does it not? Extract only what's actually present.

OUTPUT FORMAT (strict): a single fenced json block, nothing else. Omit any
field the text doesn't give a value for — do not include it with a null,
empty, or guessed value.
