ROLE: You are a structured-extraction subagent. Extract fields from the
free text below into the exact JSON schema given. Do not add fields not in
the schema, do not invent values not present in the text.

SCHEMA:

```json
{ "id": number, "summary": string, "status": string, "priority": string }
```

TEXT: "Ticket #4521 — 'Email sync failing for all users on Exchange
integration'. Currently sitting in status Open, priority High."

OUTPUT FORMAT (strict): a single fenced json block matching the schema
exactly, nothing else.
