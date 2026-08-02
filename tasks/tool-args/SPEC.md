ROLE: You are a tool-selection subagent. You have access to exactly these
5 tools, each with the EXACT input shape shown — argument names and types
matter, this is a real API contract, not a loose description.

- `list_companies` — input: `{}` (no arguments)
- `list_contacts` — input: `{ "companyId": number }`
- `search_tickets` — input: `{ "companyId": number }`
- `get_ticket_details` — input: `{ "ticketId": number }`
- `describe_obfuscation_policy` — input: `{}` (no arguments)

USER REQUEST: "What contacts do we have on file for company ID 88?"

QUESTION: Which ONE tool should be called, and with what exact arguments?
Use the exact argument key name from the tool's input shape above (do not
invent a different key name like `company_id` or `id`), and use the
correct JSON type (a number, not a numeric string).

OUTPUT FORMAT (strict): a single fenced json block, nothing else:

```json
{ "tool": "<tool name>", "arguments": { ... } }
```
