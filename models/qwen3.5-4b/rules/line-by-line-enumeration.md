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
16. the `> `-prefixed note line

Lines 2 and 9 are blank lines — both must be present, neither merged
away. Count your output against this list before submitting.
