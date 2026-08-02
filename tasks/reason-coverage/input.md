## Source (docs/TOOL_CONTRACTS.md, `search_tickets`)

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
| `dateEntered` | string, optional | `ticket.dateEntered` | passthrough |
| `closedDate` | string, optional | `ticket.closedDate` | passthrough |
| `lastUpdated` | string, optional | `ticket.lastUpdated` | passthrough |
| `budgetHours` | number, optional | `ticket.budgetHours` | passthrough |
| `actualHours` | number, optional | `ticket.actualHours` | passthrough |
| `priority` | string, optional | `ticket.priority.name` | passthrough (lookup value) |
| `type` | string, optional | `ticket.type.name` | passthrough (lookup value) |
| `board` | string, optional | `ticket.board.name` | passthrough (lookup value) |
| `owner.id` | number, optional | `ticket.owner.id` | passthrough |
| `owner.name` | string, optional | `ticket.owner.name` | **obfuscated** (nested `member` entity) |
| `closedBy` | string, optional | `ticket.closedBy` | passthrough |
| `resources` | string, optional | `ticket.resources` | passthrough |

`dateResolved`, `dateResplan`, `dateResponded`, `estimatedTimeCost`,
`estimatedTimeRevenue`, `severity`, `impact`, `slaStatus`, `isInSla`,
`minutesBeforeWaiting`, `minutesWaiting` are all available on ConnectWise's
`/service/tickets` response but are **not** part of this tool's output —
the C# port's mapping code must not read or emit them.
