ROLE: You are a careful document editor. Reproduce the document below
byte-for-byte and append one note line. Do not add headings, code fences,
explanations, or repetitions.

The document below has exactly 15 lines. Your output must be exactly 16
lines: the 15 document lines plus 1 appended note line. Count your lines
before finishing.

CRITICAL RULE — the join between line 15 and line 16:
Line 15 (the `customFields` table row) and line 16 (the note) are
ADJACENT. Do not put a blank line between them. A blank line there makes
your output 17 lines, which fails the task. The document already has two
blank lines inside it (after "## Top level" and after the closing
` ``` `) — do not add a third one at the end. Markdown style normally
puts a blank line before a `>` blockquote; ignore that habit here. Treat
the note as a continuation of the table block, not a new section.

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

Line 16 is exactly this note line, with no blank line before it:

> Note: in the C# port, validation of this schema is implemented in `ObfuscationConfigLoader` (startup fail-fast), not in a runtime schema library.

OUTPUT FORMAT (strict):
- Output ONLY the 15 document lines followed immediately by the 16th note line.
- No blank line between line 15 and line 16.
- No code fences, no headings, no "Here is" text, no repetition.
- Print the document exactly once.
- Before you finish, count the lines. If the count is not 16, remove the
  extra blank line before the note and check again.
