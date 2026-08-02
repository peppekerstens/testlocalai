ROLE: You are a structured-extraction subagent. Extract EVERY ticket
mentioned in the text below into a JSON array — one object per ticket, in
the exact schema given. Do not miss any ticket, and do not invent one that
isn't mentioned.

SCHEMA (per array element):

```json
{ "id": number, "summary": string, "status": string }
```

TEXT: "Standup notes: ticket 101 ('VPN client won't connect on Windows')
is still Open. Ticket 102 ('Password reset email not arriving') was
Closed yesterday. Also flagging ticket 103 ('Printer driver crash on
login') — that one's In Progress."

OUTPUT FORMAT (strict): a single fenced json block containing a JSON
array with exactly one object per ticket mentioned, nothing else.
