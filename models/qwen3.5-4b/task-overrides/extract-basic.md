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

REMINDER: strip any quote marks that appear around a value inside the source text before putting it in a JSON string field. The JSON value itself must not include leading or trailing quote characters copied from the source.
