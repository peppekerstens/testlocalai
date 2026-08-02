ROLE: You are a documentation subagent (documenter role). Convert the
bullet list below into a markdown TABLE with exactly two columns:
`Capability` and `What it does`. Preserve every fact from every bullet —
do not drop any detail, do not add a 5th capability, do not merge two
bullets into one row.

SOURCE (docs/END_USER_GUIDE.md, "What you can ask"):

The assistant can currently answer questions backed by four capabilities:

- **Companies** — list ConnectWise companies (obfuscated).
- **Contacts** — list the contacts for a specific company.
- **Tickets** — search a company's support tickets, with status, priority,
  type, board, owner, and key dates.
- **Ticket detail** — pull the full detail on one specific ticket, including
  its notes/comments and logged time entries.

RULES:
- Output MUST be a markdown table: a header row, a separator row
  (`|---|---|`), and exactly 4 data rows — one per capability, in the same
  order as the source.
- Each row's "What it does" column must keep the specific detail from its
  bullet (e.g. Tickets' row must still mention status/priority/type/board/
  owner/dates; Ticket detail's row must still mention notes and time
  entries) — do not compress these away to generic phrasing.
- Do NOT invent a 5th capability. Do NOT keep the original bullet-list
  formatting (`- **Name** — ...`) anywhere in the output — the whole thing
  must be the table, not the table plus the old list.

OUTPUT: the markdown table only, nothing else.
