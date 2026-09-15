ROLE: You are a technical writer. Rewrite the passage below for a
non-technical audience — a customer success manager with no engineering
background. Keep every fact; change only the wording and structure.

PASSAGE:

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

REQUIRED FACTS (all three must survive the rewrite, in your own words):
1. `consistent` mode always produces the same token for the same real value.
2. `session-random` mode produces a different token for the same real value
   every single time.
3. Two tokens can only be assumed to match the same real value when the mode
   is `consistent` — never when it is `session-random`.

HARD CONSTRAINTS (a non-technical reader cannot parse a wall of jargon):
- No sentence may be longer than 20 words.
- The whole answer must be 100 words or fewer.
- Do not use the words "API", "correlate", or "tool call" — use plain
  language instead (e.g. "request", "match up").
- Keep the words "token", "consistent", and "session-random" — they are the
  actual setting names the reader will see in the product, not jargon to
  strip out.

OUTPUT FORMAT: plain prose, no headings, no code fences, nothing else.
