## Facts (docs/TOOL_CONTRACTS.md, "Known gaps")

**Contact phone numbers and ticket note/description free text are never
obfuscated.** This is the server's current, documented, real behavior —
not a hypothetical. The project's own sensitivity list (which names, address,
email) doesn't explicitly name phone numbers or note bodies, so this may be
intentional scope-narrowing rather than an oversight — it's flagged as an
open question, not yet decided either way.

**Option A — obfuscate them too:** add contact phone numbers and ticket
note/description text to the obfuscation rules, same treatment as names/
addresses/emails.

**Option B — leave them as documented passthrough:** keep the current
behavior, formally confirming it as an intentional, narrower scope (only
name/address/email are obfuscated) rather than a gap to close.
