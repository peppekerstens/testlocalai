EXACT-PHRASE REMINDER — read before answering:

This checklist is graded against 5 SEPARATE categories, checked
independently by scanning for different tokens. Missing even ONE whole
category fails the check, even if the other 4 are done perfectly — this
model has repeatedly dropped exactly one category per draw (a different
one each time), so treat this as the primary risk, not a formality.
Before writing your numbered list, silently confirm you have one item for
EACH of these 5, then write the list:

1. An optional nested object (company/contact/owner) entirely absent from
   a ticket — name which object and that its two fields (e.g. `owner.id`
   and `owner.name`) are both absent.
2. An obfuscated field verified as actually transformed — name one of
   `company.name`, `contact.name`, or `owner.name`.
3. A lookup-value field verified as the string name, not a raw code — name
   one of `status`, `priority`, `type`, or `board`.
4. An excluded field that must be absent from the output entirely — name
   one of `dateResolved`, `severity`, `slaStatus`, or `estimatedTimeCost`.
5. An empty result — a company with zero tickets must map to an empty
   JSON array `[]`, not `null` and not an error.

Category 5 (the empty-array case) and category 1 (an absent nested object)
are the two most often silently skipped — double-check both are present
as their own separate numbered items before finishing.

ROLE: You are a reasoning subagent (reasoner role). Below is a real tool's
output field contract. List the edge cases a C# port's test suite MUST
cover for this mapping — not a generic "test all the fields" statement,
name SPECIFIC fields and SPECIFIC failure conditions. This is an
exhaustiveness check: missing a whole category of edge case is a failure,
not just getting one wrong.

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
this tool's output — the C# port's mapping code must not read or emit them.

QUESTION: Write a numbered list (at least 5 items) of edge cases the test
suite must cover. Each item must name at least one SPECIFIC field from the
table above — no item may be generic filler like "test all fields
correctly".

WARNING — read this before answering: the categories below describe WHAT
KIND of edge case each item must be, in the abstract. They are not
sentences you can copy into your answer. If your final numbered list
still contains the words "specific field", "specific obfuscated field", or
"specific lookup-value field" without an actual field name from the table
in that same line (like `company.name` or `status`), you have copied the
category description instead of answering it, and your answer is wrong.

Categories your list must cover, each filled in with a REAL field name from
the table (example of a correctly filled-in item for category one:
"A ticket with no `owner` — `owner.id` and `owner.name` must both be
absent from the output"):

- one category about an optional nested object (company/contact/owner)
  entirely absent from a ticket — name which object and which two fields
  disappear with it;
- one category about an obfuscated field, verified to actually be
  transformed, not merely present — name the field (e.g. `company.name`)
  and what "obfuscated" concretely means for it;
- one category about a lookup-value field, verified to be the string name
  and not a raw code — name the field (`status`, `priority`, `type`, or
  `board`) and give an example value;
- one category about a field from the excluded list — name the field
  (e.g. `dateResolved`, `severity`, or `slaStatus`) and state it must be
  absent from the output entirely, even though ConnectWise's upstream
  response includes it;
- one category about an empty result — a company with zero tickets must
  map to an empty JSON array, not `null` and not an error.

OUTPUT: the numbered list only, nothing else — no restatement of these
category descriptions.
