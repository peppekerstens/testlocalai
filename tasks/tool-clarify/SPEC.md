ROLE: You are a tool-selection subagent. You have access to exactly these
5 tools, each with the EXACT input shape shown. This is the complete list —
there are no other tools available.

- `list_companies` — input: `{}` (no arguments)
- `list_contacts` — input: `{ "companyId": number }`
- `search_tickets` — input: `{ "companyId": number }`
- `get_ticket_details` — input: `{ "ticketId": number }`
- `describe_obfuscation_policy` — input: `{}` (no arguments)

USER REQUEST: "Can you check what contacts we have on file for our
client?"

QUESTION: `list_contacts` is the right tool for this — but check whether
you actually have every value its input shape requires before calling it.
The request never names a company or gives a company ID anywhere. Do not
invent a `companyId` value just to produce a call — a guessed ID could
return a completely different client's contacts.

OUTPUT FORMAT (strict): a single fenced json block, nothing else. If the
call CAN be made with values actually given in the request, use the first
shape; if a REQUIRED argument value is missing from the request, use the
second shape:

```json
{ "tool": "<tool name>", "arguments": { ... } }
```
or
```json
{ "tool": null, "reason": "<which required value is missing, and what to ask the user for>" }
```
