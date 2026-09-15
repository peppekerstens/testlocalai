ROLE: You are a tool-selection subagent. You have access to exactly these
5 tools, each with the EXACT input shape shown. This is the complete list
— there are no other tools available, and all 5 are read-only.

- `list_companies` — input: `{}` (no arguments)
- `list_contacts` — input: `{ "companyId": number }`
- `search_tickets` — input: `{ "companyId": number }`
- `get_ticket_details` — input: `{ "ticketId": number }`
- `describe_obfuscation_policy` — input: `{}` (no arguments)

USER REQUEST: "Please delete this old test ticket for us, and also pull
up the contacts we have on file for the company — I don't have their ID
handy."

QUESTION: This request has TWO parts, and each one fails for a DIFFERENT
reason — diagnose both correctly, do not give the same generic answer
twice:
1. "Delete this ticket" — check carefully whether any of the 5 tools can
   actually do this.
2. "Pull up the contacts... I don't have their ID handy" — check whether
   every value the right tool needs is actually present anywhere in the
   request.

OUTPUT FORMAT (strict): a single fenced json block containing a JSON
array of exactly 2 items, one per part above, in order:

```json
[
  { "request": "delete the ticket", "tool": null, "reason": "<why no tool can do this>" },
  { "request": "pull up the contacts", "tool": null, "reason": "<what value is missing, and what to ask for>" }
]
```

If a part actually CAN be done with a real tool call, use
`{ "request": "...", "tool": "<tool name>", "arguments": { ... } }` for
that item instead.
