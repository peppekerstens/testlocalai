ROLE: You are a reasoning subagent (reasoner role). Read the output field
contract of a real tool. Then write the edge cases that the test suite of a
C# port of this tool must cover.

SOURCE (docs/TOOL_CONTRACTS.md, `search_tickets`):

**Input:** `{ companyId: number }`.

**Output:** JSON array of:

| Field | Type | Source | Redaction |
|---|---|---|---|
| `id` | number | `ticket.id` | passthrough |
| `summary` | string | `ticket.summary` | passthrough |
| `status` | string, optional | `ticket.status.name` | passthrough (lookup value) |
| `company.id` | number, optional | `ticket.company.id` | passthrough |
| `company.name` | string, optional | `ticket.company.name` | **obfuscated** (nested `company` entity) |
| `contact.id` | number, optional | `ticket.contact.id` | passthrough |
| `contact.name` | string, optional | `ticket.contact.name` | **obfuscated** (nested `contact` entity) |
| `priority` | string, optional | `ticket.priority.name` | passthrough (lookup value) |
| `type` | string, optional | `ticket.type.name` | passthrough (lookup value) |
| `board` | string, optional | `ticket.board.name` | passthrough (lookup value) |
| `owner.id` | number, optional | `ticket.owner.id` | passthrough |
| `owner.name` | string, optional | `ticket.owner.name` | **obfuscated** (nested `member` entity) |

`dateResolved`, `severity`, `slaStatus`, `estimatedTimeCost`, and several
other ConnectWise fields are available upstream but are **not** part of
this tool's output. The C# port's mapping code must not read or emit them.

TASK: Write exactly 5 numbered items, one for each rule below. Every item
must contain at least one field name in backticks, copied from the table
or from the excluded list. Write each item as one sentence about a test
input and the expected output.

Item 1 - missing nested object. Select one object: `company`, `contact`,
or `owner`. Describe a ticket that does not have this object. Name the two
fields that must then be absent from the output (for `owner`, these are
`owner.id` and `owner.name`).

Item 2 - obfuscation. Select one field: `company.name`, `contact.name`, or
`owner.name`. Give a real input value (for example "Acme Corp"). Say that
the output value must be different from the input value. Also say that the
real value must not appear anywhere in the output. A test that only checks
that the field exists is not sufficient.

Item 3 - lookup value. Select one field: `status`, `priority`, `type`, or
`board`. Give an example name (for example `status` = "In Progress").
Say that the output must be that name string, not the numeric id of the
lookup and not a nested object.

Item 4 - excluded field. Select one field: `dateResolved`, `severity`, or
`slaStatus`. Say that the upstream ConnectWise response contains it. Say
that the output must not contain this key at all, not even with a null
value.

Item 5 - empty result. Use the input `companyId`. Describe a company that
has zero tickets. Say that the output must be an empty JSON array `[]`.
Say that `null` and an error are both wrong.

EXAMPLE of one correct item (do not copy it, write your own for each rule):
1. A ticket with no `owner` object: `owner.id` and `owner.name` must both be absent from the output.

CHECK before you answer: read each of your 5 lines. Does the line contain
a field name in backticks? If a line does not, rewrite that line.

OUTPUT: the numbered list of 5 items only. Do not write a title, an
introduction, or a summary. Do not repeat these rules.
