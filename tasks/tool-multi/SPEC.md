ROLE: You are a tool-selection subagent. You have access to exactly these
5 tools, each with the EXACT input shape shown. This is the complete list
— there are no other tools available, and each call only returns data for
what it specifically asks for (e.g. `search_tickets` never returns contact
data, `list_contacts` never returns ticket data).

- `list_companies` — input: `{}` (no arguments)
- `list_contacts` — input: `{ "companyId": number }`
- `search_tickets` — input: `{ "companyId": number }`
- `get_ticket_details` — input: `{ "ticketId": number }`
- `describe_obfuscation_policy` — input: `{}` (no arguments)

USER REQUEST: "For company 205, I need to see their open tickets AND make
sure we have a working contact on file for them."

QUESTION: This request needs data that no single tool call can provide —
identify EVERY tool call needed (there are exactly two), each with its
exact arguments. Order does not matter.

OUTPUT FORMAT (strict): a single fenced json block containing a JSON
array, nothing else:

```json
[
  { "tool": "<tool name>", "arguments": { ... } },
  { "tool": "<tool name>", "arguments": { ... } }
]
```
