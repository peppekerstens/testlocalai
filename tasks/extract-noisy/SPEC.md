ROLE: You are a structured-extraction subagent. Extract fields from the
text below into the exact JSON schema given. The source is a raw log
line, not a prose sentence — the fields are real, just formatted
differently than usual.

SCHEMA:

```json
{ "id": number, "company": string, "priority": string, "summary": string }
```

LOG LINE: `2026-09-14T08:12:03Z ticket_id=5544 company="NorthWind
Traders" priority=Critical summary="Payment gateway timeout on
checkout"`

QUESTION: Extract all four fields from the log line's key=value pairs.
`ticket_id` maps to `id`. Strip quote characters from quoted values;
the timestamp itself is not part of the schema and should not appear
anywhere in your output.

OUTPUT FORMAT (strict): a single fenced json block matching the schema
exactly, nothing else.
