1. A ticket with no `company` on the ConnectWise side: `company.id` and
   `company.name` must both be absent from the output, not present as
   `null` placeholders.
2. A ticket with no `contact`: `contact.id`/`contact.name` absent, and
   likewise for `owner.id`/`owner.name` when a ticket has no assigned owner.
3. `company.name` and `contact.name` must actually come back obfuscated
   (a token, not the real ConnectWise company/contact name) when the
   underlying entity is present — verify the transformation happened, not
   just that the field exists.
4. `owner.name` must be obfuscated too (nested `member` entity) — verify
   it separately from `company.name`/`contact.name` since it goes through
   a different entity rule.
5. `status`, `priority`, `type`, and `board` must each come back as the
   human-readable string name (`ticket.status.name` etc.), never the raw
   ConnectWise numeric/code value.
6. `dateResolved`, `severity`, and `slaStatus` must NOT appear anywhere in
   the output JSON for any ticket, even though ConnectWise's own
   `/service/tickets` response includes them — verify they're actually
   absent, not just unused.
7. A company with zero tickets must return an empty JSON array `[]`, not
   `null` and not an error/exception.
