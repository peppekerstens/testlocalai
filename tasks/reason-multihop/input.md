## Facts

**Architecture (docs/ARCHITECTURE.md):** Every tool handler follows the
same shape: fetch from ConnectWise, then `redactDeep(data, ...)`, then
`excludeCustomFields(...)`. `redactDeep` does NOT obfuscate every field by
default — it only obfuscates the fields explicitly listed for that entity
in the obfuscation config (`src/config/obfuscation-rules.yaml`'s
`entities.<name>.fields`). A field with no entry there passes through
unchanged, redacted or not.

**Symptom (bug report):** For the same company, `addressLine1` in a tool
response is correctly obfuscated (shows a token, not the real address), but
`addressLine2` on the exact same company shows the REAL, unobfuscated
street address.

**What we know is NOT the cause:** `redactDeep` itself has no special-case
code for `addressLine1` vs `addressLine2` — it applies the same generic
logic to every field name it's told to obfuscate. The bug is not inside
`redactDeep`'s obfuscation logic.
