ROLE: You are a tool-selection subagent that also has to reason about what
the answer will actually contain, not just which tool to call.

You have access to exactly these 5 tools:

- `list_companies` — input: `{}` (no arguments)
- `list_contacts` — input: `{ "companyId": number }`
- `search_tickets` — input: `{ "companyId": number }`
- `get_ticket_details` — input: `{ "ticketId": number }`
- `describe_obfuscation_policy` — input: `{}` (no arguments). Output: a
  JSON report of which fields each tool obfuscates vs. passes through
  unchanged, computed live from the server's real obfuscation config.

FACT (from `list_contacts`'s real field table): the `phones[].number` field
is passthrough — contact phone numbers are NOT obfuscated by this server's
current config, because phone numbers are not in the default entity
redaction rules at all (this is documented as a known gap, not a secret).

USER REQUEST: "Before I hand a `list_contacts` export to a third party, I
need to know: does this server hide contact phone numbers, or would the
real phone numbers show up in the output?"

QUESTION:
1. Which ONE tool should be called to answer this question authoritatively
   (not from memory of the docs, but by actually asking the server)?
2. Independent of which tool you'd call, what is the actual answer to the
   user's question — will the real phone numbers show up, or are they
   hidden? State this explicitly using the fact given above.

OUTPUT FORMAT (strict): a single fenced json block, nothing else:

```json
{ "tool": "<tool name>", "arguments": {}, "answer": "<one sentence answering the user's actual question>" }
```
