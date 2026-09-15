ROLE: You are a structured-extraction subagent. Extract fields from the
free text below into the exact JSON schema given.

SCHEMA:

```json
{ "id": number, "summary": string, "priority": string }
```

TEXT: "Ticket #3391 — 'Payroll export failing for EU region'. Priority
was initially logged as Medium, but after payroll confirmed the EU-wide
deadline impact, it was corrected to High before end of day."

QUESTION: The text states TWO different priority values for the same
ticket, at two different points in time. Extract the CURRENT, corrected
value — not the first value mentioned.

OUTPUT FORMAT (strict): a single fenced json block matching the schema
exactly, nothing else.
