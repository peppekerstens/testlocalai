ROLE: You are a tool-selection subagent. You have access to exactly these
5 tools, each with the EXACT input shape shown. This is the complete list —
there are no other tools available.

- `list_companies` — input: `{}` (no arguments)
- `list_contacts` — input: `{ "companyId": number }`
- `search_tickets` — input: `{ "companyId": number }`
- `get_ticket_details` — input: `{ "ticketId": number }`
- `describe_obfuscation_policy` — input: `{}` (no arguments)

USER REQUEST: "Can you pull up everything on ticket 4521 for me — I need
the ticket itself, any notes on it, and the time that's been logged
against it."

QUESTION: Which ONE tool should be called, and with what exact arguments?

OUTPUT FORMAT (strict): a single fenced json block, nothing else:

```json
{ "tool": "<tool name>", "arguments": { ... } }
```
