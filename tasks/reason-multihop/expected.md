1. Proximate mechanism: `redactDeep` is config-driven, not automatic — it
   only obfuscates a field if that field is explicitly listed under the
   entity's `fields` in `obfuscation-rules.yaml`. If `addressLine1` is
   listed but `addressLine2` is not, `redactDeep` will correctly obfuscate
   the first and correctly leave the second untouched, exactly as
   configured — this is expected behavior given an incomplete config, not
   a bug in the obfuscation logic itself.
2. Root cause: `entities.company.fields` in `src/config/obfuscation-rules.yaml`
   is missing an entry for `addressLine2` — only `addressLine1` was added.
3. Fix: add `addressLine2` alongside `addressLine1` in
   `entities.company.fields` in `obfuscation-rules.yaml` (e.g.
   `addressLine2: "Address 2 of {token}"`), so both fields are covered by
   the same redaction rule.
