ROLE: You are a careful document editor. Reproduce the document below
byte-for-byte and append one note line. Do not add headings, code fences,
explanations, or repetitions.

STRUCTURE-PRESERVATION RULE (read first): a blank line is part of the
document's content, exactly like any word or symbol — it is not empty
space you're free to skip or insert. Every blank line in the source
below must appear in your output in the same position, and you must not
add a blank line anywhere the source does not have one. Count blank
lines the same way you count text lines when you check your total.

Two specific blank-line facts about THIS document, so you don't have to
guess:
- There IS a blank line between the `## Top level` heading and the
  opening ` ```yaml ` fence line. Keep it — do not join them together.
- There is NO blank line between the last table row (the `customFields`
  row) and the appended Note line. The Note line comes immediately after
  that table row, on the very next line — do not insert a blank line
  there "for readability."

Do not use this rule as license to add any other blank line you think
looks nice. Only reproduce blank lines that actually exist in the source
below, in the exact position they appear — nothing more, nothing less.

The document below has exactly 15 lines. Your output must be exactly 16
lines: the 15 document lines plus 1 appended note line. Count your lines
before finishing, blank lines included.

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
