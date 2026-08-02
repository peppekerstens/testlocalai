ROLE: You are a documentation subagent (documenter role). Two source
excerpts are below, from two different docs. Write a short FAQ-style answer
(2-3 sentences) to the question: "Will a contact's email address be visible
to the AI assistant?" Your answer MUST combine a specific fact from EACH
source below — do not answer from only one of them, and do not invent a
fact that appears in neither.

SOURCE A (docs/END_USER_GUIDE.md, "If something looks wrong"):

You can also just ask the assistant to describe exactly what gets hidden —
it can call `describe_obfuscation_policy` and tell you, field by field, for
whichever tool you're curious about, always matching what the server is
actually configured to do right now.

SOURCE B (docs/TOOL_CONTRACTS.md, `ContactOutput` field table, `email` row):

| Field | Type | Source | Redaction |
|---|---|---|---|
| `email` | string, optional | `contact.email` | **obfuscated** → `{token}@obfuscated.invalid` |

RULES:
- From Source B: state the EXACT transformation — email is replaced with
  `{token}@obfuscated.invalid`, not just "hidden" or "removed".
- From Source A: you MUST write the tool name `describe_obfuscation_policy`
  itself, in backticks, character-for-character exactly as it appears in
  Source A. Paraphrasing it away — writing "the assistant can describe the
  obfuscation policy" or similar without the literal function name in
  backticks — is WRONG even if the meaning is correct. This is a specific
  callable tool name, not a description of a feature; treat it the same
  way you'd treat a variable name you must not rename.
- Do NOT invent a different tool name, a different placeholder format
  (e.g. `[REDACTED]`, `***`), or claim email is NOT obfuscated.
- Do NOT copy either source verbatim as a block quote — answer in your own
  words as a short FAQ answer, but the tool name itself is an exception to
  "your own words": copy that one identifier exactly.

OUTPUT: the FAQ answer only, nothing else.
