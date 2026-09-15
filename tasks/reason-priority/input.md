SEVERITY CRITERIA (use these exactly, do not invent your own scale):
- Critical: affects ALL clients/companies, no workaround exists, and causes
  real data exposure or data corruption.
- High: affects MULTIPLE companies or breaks a core capability, but a
  workaround exists — or affects a single company with no workaround.
- Medium: affects a single company, and a workaround exists — or is a
  non-blocking functional bug.
- Low: cosmetic only, zero functional impact.

THREE OPEN ISSUES (reported the same morning, same server):

**Issue A** (reported by an anxious on-call engineer): "URGENT!!! search_tickets
is COMPLETELY BROKEN, throwing a 500 error, tickets are unreachable!!" —
Investigation confirms this only reproduces for company ID 77; every other
company's `search_tickets` call works normally. A workaround already exists:
`get_ticket_details` still works per-ticket for company 77's tickets, so no
data is actually unreachable, just the bulk search for that one company.

**Issue B** (reported by a QA engineer, calm, technical language, filed as a
routine ticket): "Noticed during a session-replay test: `session-random` mode
is returning the SAME obfuscated token for the same real value across two
DIFFERENT sessions. It should generate a new, unrelated token per session —
this means any client watching two different sessions could silently
correlate obfuscated values back to the same real entity, for every company
on the server, right now. No workaround — this is a property of the mode
itself, not something a caller can opt out of. Not yet publicly disclosed."

**Issue C** (reported in passing, one line): "`describe_obfuscation_policy`'s
JSON response is missing a trailing newline character at the very end of the
output — purely cosmetic, every field and value is otherwise correct."
