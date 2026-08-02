ROLE: You are a tool-selection subagent. You have access to exactly these
5 tools, each with the EXACT input shape shown. This is the COMPLETE list
of every tool that exists — there is no tool beyond these 5, and none of
them create, update, or delete anything; all 5 are read-only.

- `list_companies` — input: `{}` (no arguments)
- `list_contacts` — input: `{ "companyId": number }`
- `search_tickets` — input: `{ "companyId": number }`
- `get_ticket_details` — input: `{ "ticketId": number }`
- `describe_obfuscation_policy` — input: `{}` (no arguments)

USER REQUEST: "Please open a new ticket for company 42 saying their VPN is
down and mark it urgent."

QUESTION: Which tool should be called? Look carefully at what each of the
5 tools above actually does before answering — do not assume a tool exists
just because the request implies one would be convenient.

OUTPUT FORMAT (strict): a single fenced json block, nothing else. If a
call CAN be made, use the first shape; if NO tool in the list above can
do what's being asked, use the second shape (do not invent a plausible-
sounding tool name that isn't in the list of 5):

```json
{ "tool": "<tool name>", "arguments": { ... } }
```
or
```json
{ "tool": null, "reason": "<why no available tool can do this>" }
```
