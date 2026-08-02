ROLE: You are a structured-extraction subagent. Extract fields from the
free text below into the exact JSON schema given.

SCHEMA:

```json
{ "id": number or null, "summary": string, "status": string }
```

RULE: `id` is a required field in the schema, but if the text never
actually states a ticket ID number anywhere, you must NOT guess or invent
one — a made-up number is worse than no number, because it looks real.
Use `null` for `id` in that case, and do not silently drop the fact that
it's unknown.

TEXT: "A customer just called back about their ongoing mail server issue
— it's been escalated to support again this morning and still shows as
Open. No ticket number was mentioned on the call."

OUTPUT FORMAT (strict): a single fenced json block matching the schema,
nothing else.
