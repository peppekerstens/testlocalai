ROLE: You are a careful document editor. The document below has two defects.
Repair both defects in place. Do not reword, renumber, merge, or add
anything except the two repairs. Do not comment.

The document begins at the [DOC_START] marker and ends at the [DOC_END]
marker. The markers are delimiters only. Do not copy the markers into the
output.

[DOC_START]

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

DEFECT 1 — the YAML block opens with the line ` ```yaml ` but never closes.
Add one closing fence line, three backticks only, right after the line
`nestedEntities: { ... }               # optional, defaults to {}` and
right before the blank line that comes before the table. Add nothing
else. The table stays outside the fenced block.

DEFECT 2 — the table has a header row but no separator row. Add one
separator row, `|---|---|---|---|`, right after the header row
`| Field | Type | Required | Notes |` and before the first body row. Keep
the header row and all body rows exactly as they are.

CRITICAL RULE — where the closing fence goes:

A prior run put the closing fence in the wrong place. It closed the fence
after the LAST table row, at the very end of the document. That put the
whole table inside the YAML block. Do not repeat that.

Wrong (a prior run produced this — do not repeat it):
```
nestedEntities: { ... }               # optional, defaults to {}

| Field | Type | Required | Notes |
|---|---|---|---|
| `mode` | enum: `"consistent"` \| `"session-random"` | yes | Any other string fails validation at startup |
| `entities` | map of string → EntityRule | yes | Key is the entity type name |
| `nestedEntities` | map of string → string | no (default `{}`) | value must be a key that exists in `entities` |
| `customFields` | CustomFieldsRule | no | Omit to disable |
```
```

Right (use this placement — the fence closes BEFORE the table, not after
it):
```
nestedEntities: { ... }               # optional, defaults to {}
```

| Field | Type | Required | Notes |
|---|---|---|---|
| `mode` | enum: `"consistent"` \| `"session-random"` | yes | Any other string fails validation at startup |
...
```

Before you finish, count the fence lines in your output. There are
exactly two: one opening fence right after `## Top level`, right before
`mode: consistent | session-random`; one closing fence right after
`nestedEntities: { ... }`, right before the blank line. Check there is no
third fence anywhere later in the document, including at the end.

OUTPUT FORMAT (strict):
- Output only the repaired document, starting at the `## Top level`
  heading and ending after the `customFields` table row.
- No code fences around the whole output, no [DOC_START], no [DOC_END],
  no commentary.
- Print the document exactly once.
