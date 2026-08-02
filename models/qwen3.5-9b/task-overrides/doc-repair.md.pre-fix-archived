STRUCTURE CHECKLIST — verify your output against ALL of these before
finishing, in order:

1. Line 1 of your output is exactly `## Top level` (not the ```yaml
   line — the heading comes first).
2. Line 2 is blank.
3. Line 3 starts the ```yaml block.
4. The ```yaml block contains exactly 3 lines (`mode:`, `entities:`,
   `nestedEntities:`) then a closing ``` on its own line — that closing
   ``` must come right there, immediately after `nestedEntities: { ... }`,
   NOT at the end of the whole document. Putting it at the end would wrap
   the entire table inside the YAML block, which is wrong.
5. After that closing ```, a blank line, then the table starts with its
   header row.
6. The table's separator row (`|---|---|---|---|`) may already be
   present and correct in the source below — if so, keep it exactly as
   given; do not add a second one or alter it.

Go through all 6 checklist items against your draft before outputting.

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
