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

RULES FOR THE TWO REPAIRS:

1. The closing fence goes in the MIDDLE of the document, not at the end.
   It goes on the line directly after `nestedEntities: { ... }`. The table
   comes after the fence, outside the YAML block.

   WRONG (fence at the end, the table is still inside the YAML block):
   nestedEntities: { ... }  ...
   (blank line)
   | Field | Type | Required | Notes |
   ...
   | `customFields` | CustomFieldsRule | no | Omit to disable |
   ```

   RIGHT (fence directly after the last YAML line):
   nestedEntities: { ... }  ...
   ```
   (blank line)
   | Field | Type | Required | Notes |

2. The separator row goes on the line directly after the header row
   `| Field | Type | Required | Notes |`. It has exactly four `---` cells.
   Do not put a blank line between the header row, the separator row, and
   the body rows.

3. The document has exactly two lines of ``` : the opening ```yaml line and
   the new closing ``` line. Do not add a third fence.

4. Copy every other line exactly as it is, including the comments after `#`
   and the spaces before them.

SELF-CHECK before you print (do not print the check):
- The line after `nestedEntities: { ... }` is ``` .
- The line after `| Field | Type | Required | Notes |` is `|---|---|---|---|`.
- The last line of the output is the `customFields` table row. It is not ``` .

OUTPUT FORMAT (strict):
- Output ONLY the repaired document, starting at the `## Top level` heading
  and ending after the `customFields` table row.
- No code fences around the whole output, no [DOC_END], no commentary.
- Print the document exactly once.
