`mode` controls how the redaction engine generates obfuscated values, and it is
one of exactly two settings. In `consistent` mode, the redaction engine maps a
given real value to the exact same obfuscated token every time that value
appears, across every API call in a session, which means a client can safely
treat two tokens as representing the same underlying entity when correlating
results from two separate tool calls (for example, matching a company ID
returned by `list_companies` against the same company ID embedded inside a
`search_tickets` result). In `session-random` mode, the redaction engine
generates a brand-new, unrelated obfuscated token for the same real value on
every single call, even within one session, so two tokens must never be
assumed to represent the same value — cross-call correlation is not supported
in this mode, only additional privacy.
