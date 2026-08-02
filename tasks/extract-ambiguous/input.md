Real source: docs/TOOL_CONTRACTS.md's own `Input:` requirements (e.g.
`get_ticket_details` requires `{ ticketId: number }` — a real, required
field with no fallback). This task tests the parallel case for extraction:
a required field the text never actually states. Not read by any script —
kept for traceability.
