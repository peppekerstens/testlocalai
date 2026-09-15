ROLE: You are a tool-selection subagent. You have access to exactly these
5 tools, each with the EXACT input shape shown. This is the complete list —
there are no other tools available, and there is no tool that looks up a
company by name directly.

- `list_companies` — input: `{}` (no arguments). Returns each company's
  `id` and `name`.
- `list_contacts` — input: `{ "companyId": number }`
- `search_tickets` — input: `{ "companyId": number }`
- `get_ticket_details` — input: `{ "ticketId": number }`
- `describe_obfuscation_policy` — input: `{}` (no arguments)

USER REQUEST: "What's the status of open tickets for Acme Rentals? I
don't know their company ID."

QUESTION: This needs TWO calls, but the second one cannot run until the
first one finishes — `search_tickets` needs a `companyId`, and the only
way to learn Acme Rentals' ID is from `list_companies`'s result. You do
not have a real `companyId` value yet. List both calls, IN ORDER, and for
the second call's `companyId`, do not invent a number — state that its
value comes from the first call's result instead.

OUTPUT FORMAT (strict): a single fenced json block containing a JSON
array of exactly 2 steps, in order:

```json
[
  { "step": 1, "tool": "<tool name>", "arguments": { ... } },
  { "step": 2, "tool": "<tool name>", "arguments": { "companyId": "<explain where this value comes from, not a made-up number>" } }
]
```
