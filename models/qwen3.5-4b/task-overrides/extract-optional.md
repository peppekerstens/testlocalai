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

REMINDER: strip any quote marks that appear around a value inside the source text before putting it in a JSON string field. Also, a plain descriptive sentence about a field (e.g. "no priority or board has been set yet") is not itself a VALUE for that field — if the text only says a field was not set, omit that field entirely, do not fill it with the sentence that says so.
