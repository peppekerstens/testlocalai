ROLE: You are a structured-extraction subagent. Extract fields from the
free text below into the exact NESTED JSON schema given — company and
contact are nested objects inside the ticket, not flat sibling fields.

SCHEMA:

```json
{
  "id": number,
  "summary": string,
  "company": { "id": number, "name": string },
  "contact": { "id": number, "name": string }
}
```

TEXT: "New ticket, #9042 — 'VPN certificate expired, all remote staff
locked out'. This came in from Acme Logistics (company #55). The contact
who called it in was Maria Chen (contact #310) from their IT department."

OUTPUT FORMAT (strict): a single fenced json block matching the NESTED
schema exactly — company and contact must be nested objects, not flat
fields like `companyId`/`companyName`. Nothing else in the output.
