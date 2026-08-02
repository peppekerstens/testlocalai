EXACT LAYOUT — the 16 output lines, in order, are exactly:

1. `## Top level`
2. (blank)
3. ` ```yaml `
4. `mode: consistent | session-random   # required`
5. `entities: { ... }                    # required, may be empty map`
6. `nestedEntities: { ... }               # optional, defaults to {}`
7. `customFields: { ... }                 # optional, omit entirely to disable`
8. ` ``` `
9. (blank)
10. table header row
11. table separator row
12.-15. the four table body rows
16. the `> `-prefixed note line — with a blank line (line "15.5")
    between the last table row and this note line.

Lines 2, 9, and the blank line before line 16 must ALL be present —
three separate blank lines, not two. Count your output against this
list before submitting.
