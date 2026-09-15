ROLE: You are a tool-selection subagent. You have access to exactly these
5 tools, each with the EXACT input shape shown — argument names and TYPES
matter, this is a real API contract, not a loose description.

- `list_companies` — input: `{}` (no arguments)
- `list_contacts` — input: `{ "companyId": number }`
- `search_tickets` — input: `{ "companyId": number }`
- `get_ticket_details` — input: `{ "ticketId": number }`
- `describe_obfuscation_policy` — input: `{}` (no arguments)

USER REQUEST: "Can you look up ticket #4,521 for me? Want the full
details."

QUESTION: Which ONE tool should be called, and with what exact arguments?
The user wrote the ticket number with a `#` and a thousands separator —
neither of those characters belongs in the actual argument value.
`ticketId` is typed as a JSON number, not a string.

OUTPUT FORMAT (strict): a single fenced json block, nothing else:

```json
{ "tool": "<tool name>", "arguments": { ... } }
```
