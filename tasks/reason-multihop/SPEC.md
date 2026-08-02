ROLE: You are a reasoning subagent (reasoner role). Diagnose the bug below.
This diagnosis requires TWO hops, not one — do not stop at the first
mechanism you find. Work step by step: state the proximate mechanism
first, then go one level deeper to the actual root cause, then state the
exact fix.

FACTS:

**Architecture:** Every tool handler follows the same shape: fetch from
ConnectWise, then `redactDeep(data, ...)`, then `excludeCustomFields(...)`.
`redactDeep` does NOT obfuscate every field by default — it only obfuscates
the fields explicitly listed for that entity in the obfuscation config
(`src/config/obfuscation-rules.yaml`'s `entities.<name>.fields`). A field
with no entry there passes through unchanged, redacted or not.

**Symptom:** For the same company, `addressLine1` in a tool response is
correctly obfuscated, but `addressLine2` on the exact same company shows
the REAL, unobfuscated street address.

**Ruled out:** `redactDeep` itself has no special-case code for
`addressLine1` vs `addressLine2` — it applies the same generic logic to
every field name it's told to obfuscate. The bug is not inside
`redactDeep`'s obfuscation logic.

QUESTION: Trace this to its root cause across BOTH hops:
1. Proximate mechanism: given `redactDeep` isn't buggy and isn't
   special-casing either field, why would it obfuscate one and not the
   other? (Answer using the architecture fact above.)
2. Root cause: given that mechanism, what is the ONE specific thing that
   must be missing for `addressLine2` specifically? Name the exact
   config file and section.
3. Fix: state the exact fix in one sentence.

Do not stop at "redaction is broken" or "there's a bug in redactDeep" —
that contradicts the "ruled out" fact above and is not the two-hop answer
being asked for.

OUTPUT: your two-hop diagnosis (numbered 1-3 as above), nothing else.
