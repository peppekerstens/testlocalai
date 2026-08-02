Obfuscating phone numbers and note text would extend the same privacy
guarantee the rest of the system already gives names, addresses, and
emails — consistent coverage, no special-cased exception for a support
engineer to remember. But note/description text is often where the actual
technical detail of a ticket lives (what broke, what was tried), and a
phone number is frequently needed to actually act on a ticket (call the
contact back) — obfuscating both would meaningfully reduce the assistant's
usefulness for real support work, not just its access to identity data.

Recommendation: **Option B** — leave phone numbers and note text as
documented passthrough, and treat this as a confirmed, intentional scope
boundary rather than a gap to close. The project's own sensitivity list
already names exactly name/address/email as in scope; phone numbers and
free-text notes are operationally necessary data, not identity data in the
same sense, and the current behavior matches that distinction rather than
contradicting it.
