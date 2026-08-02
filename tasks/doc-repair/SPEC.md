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
ROLE: You are a careful document editor. The document below contains TWO
defects. Repair both defects IN PLACE and output the repaired document. Do
not reword, renumber, merge, or add anything except the two repairs. Do not
comment.

DOCUMENT (begins next line, ends at [DOC_END]):

## Top level

```yaml
mode: consistent | session-random   # required
entities: { ... }                    # required, may be empty map
nestedEntities: { ... }               # optional, defaults to {}

| Field | Type | Required | Notes |
|---|---|---|---|
| `mode` | enum: `"consistent"` \| `"session-random"` | yes | Any other string fails validation at startup |
| `entities` | map of string → EntityRule | yes | Key is the entity type name |
| `nestedEntities` | map of string → string | no (default `{}`) | value must be a key that exists in `entities` |
| `customFields` | CustomFieldsRule | no | Omit to disable |

[DOC_END]

DEFECT 1 — the YAML fenced block is missing its closing fence (the line
containing just ```). Add the closing fence after the last YAML line
(`nestedEntities: { ... }`) and before the table. Nothing else changes.

DEFECT 2 — the table is missing the separator row that separates the header
row from the body rows. Add the standard separator row
(`|---|---|---|---|`) immediately after the header row. The header row and
all body rows keep their exact text.

OUTPUT FORMAT (strict):
- Output ONLY the repaired document, starting at the `## Top level` heading
  and ending after the `customFields` table row.
- No code fences around the whole output, no [DOC_END], no commentary.
- Print the document exactly once.
