ROLE: You are a classification subagent. Classify the ticket note below
into EXACTLY ONE of these 4 categories — no other label is valid, do not
invent a new one or use a synonym:

- `Critical` — a full outage affecting ALL users of a service, with no
  workaround available.
- `High` — a significant problem affecting MULTIPLE users, but a
  workaround exists or it isn't a full outage.
- `Medium` — a problem affecting a SINGLE user, or a non-blocking issue.
- `Low` — a cosmetic issue or a feature request, not a functional problem.

NOTE TEXT: "URGENT!! Email is completely broken for the entire sales
team, 12 people cannot send quotes to clients. Support confirmed everyone
else in the company is unaffected. As a stopgap, sales can use their
personal Gmail accounts to send quotes today."

QUESTION: Which ONE category applies? Read the category definitions
carefully and apply them exactly as written — do not pick a category just
because the note sounds urgent. Two details matter here: how many users
this actually affects (compare "the entire sales team" against "ALL users
of a service" in the Critical definition), and whether a workaround
actually exists (the personal-Gmail stopgap).

OUTPUT FORMAT (strict): a single fenced json block, nothing else:

```json
{ "category": "<one of: Critical, High, Medium, Low>" }
```
