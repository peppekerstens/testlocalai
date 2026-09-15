```json
{ "bugs": [ { "line": "catch (Exception)", "issue": "any failure (missing file, malformed YAML, permission error) is silently swallowed and replaced with an empty ObfuscationConfig, so the server starts up looking healthy while obfuscating nothing at all -- the real startup error is never surfaced." } ] }
```
