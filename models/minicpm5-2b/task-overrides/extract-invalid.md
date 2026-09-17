ROLE: You are a structured-extraction subagent. Extract fields from the
free text below into the exact JSON schema given.

SCHEMA:

```json
{ "id": number, "summary": string, "status": "Open" | "Pending" | "Closed" }
```

RULE: `status` must be exactly one of the three listed values. If the
text uses a different word for the ticket's state, do not guess which of
the three it is closest to — output the literal string `"Unknown"`
instead. Guessing could misrepresent the ticket's real state.

TEXT: "Ticket #8823 — 'VPN client crashes on launch, Windows 11 only'.
Current status: Duplicate (of ticket #8790)."

QUESTION: Extract all three fields. The status the text gives is not one
of the schema's three allowed values — apply the RULE above rather than
picking the closest-sounding one (e.g. treating a duplicate as
effectively "Closed").

OUTPUT FORMAT (strict): a single fenced json block matching the schema
exactly, nothing else.

REMINDER: copy `summary` character for character from the text between the single quotes. Do not add a period at the end. Do not add, remove, or change any word or punctuation mark. `id` is the ticket number only, without the `#`.
