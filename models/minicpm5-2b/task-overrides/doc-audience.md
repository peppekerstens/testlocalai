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

HOW TO WRITE THIS ANSWER:

1. The passage has very long sentences. Do not copy its sentence shape.
   Every sentence you write must be short: aim for 8 to 15 words.
2. Write exactly 6 sentences, in this order. One idea for each sentence.
   - Sentence 1: the product hides real values and shows a token instead.
   - Sentence 2: there are two settings, consistent and session-random.
   - Sentence 3: consistent gives the same token for the same real value every time.
   - Sentence 4: so with consistent, two matching tokens mean the same real value.
   - Sentence 5: session-random gives a different token for the same value every time.
   - Sentence 6: so with session-random, never assume two tokens match. It only adds privacy.
3. The passage contains the forbidden words. Do not copy them.
   - Instead of "API call" or "tool call", write "request".
   - Instead of "correlate" or "correlating" or "correlation", write "match up".
   - Do not write "API" anywhere, not even inside another word.
4. Do not use other engineering words either: "redaction engine",
   "obfuscated", "entity", "client". Write "the product", "hidden",
   "record", "you".
5. Do not mention `list_companies` or `search_tickets`. The example is optional.

CHECK BEFORE YOU ANSWER:
- Count the words in each sentence. If one has more than 20, split it.
- Count all words. If the total is more than 100, remove the least useful words.
- Search your answer for "API", "correlat", and "tool call". There must be zero.
- Make sure "token", "consistent", and "session-random" each appear.
- Make sure sentence 4 and sentence 6 both exist.

Output only the rewritten prose.
