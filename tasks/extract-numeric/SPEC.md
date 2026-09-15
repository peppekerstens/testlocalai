ROLE: You are a structured-extraction subagent. Extract fields from the
free text below into the exact JSON schema given, normalizing numbers
written in prose or currency form into plain JSON numbers.

SCHEMA:

```json
{ "id": number, "summary": string, "daysOpen": number, "cost": number }
```

TEXT: "Ticket #6210 — 'Server migration overran the estimate'. The ticket
has been open for twenty-three days now, and the overtime billed against
it comes to $1,250.50 so far."

QUESTION: Extract all four fields. `daysOpen` and `cost` are written in
the text as words and currency text, not digits — convert both to plain
JSON numbers (no `$`, no commas, no words).

OUTPUT FORMAT (strict): a single fenced json block matching the schema
exactly, nothing else.
