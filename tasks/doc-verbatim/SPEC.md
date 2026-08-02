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
ROLE: You are a careful document editor. Reproduce the document below
byte-for-byte and append one note line. Do not add headings, code fences,
explanations, or repetitions.

The document below has exactly 15 lines. Your output must be exactly 16
lines: the 15 document lines plus 1 appended note line. Count your lines
before finishing.

DOCUMENT (15 lines, begins next):

## Top level

```yaml
mode: consistent | session-random   # required
entities: { ... }                    # required, may be empty map
nestedEntities: { ... }               # optional, defaults to {}
customFields: { ... }                 # optional, omit entirely to disable
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `mode` | enum: `"consistent"` \| `"session-random"` | yes | Any other string fails validation at startup. See "Token modes" below. |
| `entities` | map of string → [EntityRule](#entityrule) | yes | Key is the entity type name (e.g. `company`, `contact`, `member`) — this name is what `nestedEntities` values reference, and what a tool passes as `rootEntityType` when it fetches data. Free-form; not a fixed enum. |
| `nestedEntities` | map of string → string | no (default `{}`) | Key is a JSON property name as it appears in a ConnectWise response (e.g. `defaultContact`, `owner`, `company`); value must be a key that exists in `entities`. |
| `customFields` | [CustomFieldsRule](#customfieldsrule) | no | Omit to disable custom-field exclusion entirely. |

Line 16 is exactly this note line:

> Note: in the C# port, validation of this schema is implemented in `ObfuscationConfigLoader` (startup fail-fast), not in a runtime schema library.

OUTPUT FORMAT (strict):
- Output ONLY the 15 document lines followed by the 16th note line.
- No code fences, no headings, no "Here is" text, no repetition.
- Print the document exactly once.
