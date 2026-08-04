STRUCTURE-PRESERVATION REMINDER — read before answering:

This model has a documented history of two specific defects on byte-for-byte
copy tasks:
1. Dropping or altering a markdown table's separator row (a line like
   `|---|---|---|---|`), or changing its dash counts.
2. Dropping the leading `> ` marker on blockquote lines when appending a note
   line at the end — this happened before on the near-identical "reproduce a
   document, then append a note line" task, where the appended note was
   itself a blockquote.

The document below contains BOTH risks: it has a table with a separator row,
AND the required appended line is a blockquote (`> Note: ...`). Check for
both before finishing.

WHITESPACE — the yaml block below uses exact multi-space padding to align
trailing `#` comments, e.g.:
`entities: { ... }                    # required, may be empty map`
Reproduce every run of spaces character-for-character. Do NOT collapse
multiple spaces into one, and do NOT re-pad to a different alignment. Copy
the whitespace exactly as it appears in the source — do not "fix" or
"normalize" it, even if it looks uneven.

CODE FENCE CLARIFICATION — "no code fences" in the output rules below means:
do NOT wrap your entire answer in an extra outer pair of triple backticks.
It does NOT mean remove the ` ```yaml ` / ` ``` ` fence lines that are
already part of the document's own content (lines 3 and 8 below). Those two
fence lines are literal document text and MUST appear in your output
exactly as shown, in their original position, unchanged.

ROLE: You are a careful document editor. Reproduce the document below
byte-for-byte and append one note line. Do not add headings, code fences,
explanations, or repetitions beyond what the document itself already
contains.

The document below has exactly 15 lines. Your output must be exactly 16
lines: the 15 document lines plus 1 appended note line.

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

Line 16 is exactly this note line (a blockquote — keep the leading `> `):

> Note: in the C# port, validation of this schema is implemented in `ObfuscationConfigLoader` (startup fail-fast), not in a runtime schema library.

OUTPUT FORMAT (strict):
- Output ONLY the 15 document lines followed by the 16th note line.
- No extra outer code fences, no headings, no "Here is" text, no repetition.
- Print the document exactly once.

SELF-CHECK before you finish — count your output line by line:
1. `## Top level`
2. (blank)
3. ` ```yaml` — fence, unchanged
4. `mode:` line — exact spacing before `#`
5. `entities:` line — exact spacing before `#`
6. `nestedEntities:` line — exact spacing before `#`
7. `customFields:` line — exact spacing before `#`
8. ` ``` ` — closing fence, unchanged
9. (blank)
10. table header row
11. table separator row — `|---|---|---|---|` exactly, not shortened or lengthened
12. `mode` table row
13. `entities` table row
14. `nestedEntities` table row
15. `customFields` table row
16. `> Note: ...` — starts with `> `, do not drop the `> `

If your draft has more or fewer than 16 lines, or line 16 is missing its
leading `> `, or line 11's separator row is missing or altered, fix it
before submitting.
