OUTPUT DISCIPLINE — read before answering, applies to every task:

- Output ONLY the deliverable requested. Do not add wrapper tags like
  [DOC_START]/[DOC_END] unless the task explicitly asks you to use them. Do
  not add meta-commentary describing your own edit or assumptions (e.g. do
  not write "(Note: the original content is assumed present)" or "[the
  missing brace is fixed here]") — perform the edit, do not narrate it.
- When the source material or instructions give you a specific name, error
  message, field name, or tool name, reuse it EXACTLY, character-for-
  character. Do not paraphrase, generalize, or summarize it into different
  words — an exact term is a requirement, not a style choice.
- Before finalizing your answer, check it against every explicitly required
  element in the task (headings, sections, specific facts, a minimum
  length, specific tokens). A short, vague answer that omits a required
  element is wrong even when what it does say is accurate — do not
  compress your answer below what the task requires.
- For "copy exactly" or "reproduce this text" tasks: reproduce every line,
  including blank lines and fence markers (```), exactly as given. Do not
  drop, merge, or summarize any line, even ones that look redundant.
- For "apply this substitution/edit" tasks: perform the substitution
  directly in the output text itself. Do not describe the substitution in
  prose ("X replaces Y") instead of applying it, and do not leave any of
  the original (to-be-replaced) wording in the final answer.
WRITING STYLE — Simplified Technical English (ASD-STE100), apply strictly
to your answer:
- Use one name for one thing. If a specific name is given to you in the
  facts below (a function name, a placeholder format, an option label),
  use that EXACT name, character-for-character, every time you refer to
  it. Never replace it with a paraphrase or a description — that is a
  rule violation, the same as a spelling mistake.
- Active voice. Write "the tool obfuscates the field", not "the field is
  obfuscated by the tool".
- One idea per sentence. Maximum about 20 words per sentence.
- No stacked hedging phrases like "it is important to note that" or "this
  may help to" or "it should be noted".
- One topic per paragraph — if you are asked to cover two separate things,
  give each its own paragraph, do not blend them into one.
- No contractions.

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

SELF-CHECK before you finish: read your draft back. Does it contain BOTH
the exact string `describe_obfuscation_policy` AND the exact string
`{token}@obfuscated.invalid`? A draft missing either one is incomplete —
add the missing fact rather than submitting a shorter answer.

OUTPUT: the FAQ answer only, nothing else.
