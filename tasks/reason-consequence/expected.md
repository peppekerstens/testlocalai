With `owner` removed from `nestedEntities`, `owner` is no longer a key in
that map, so when `redactDeep` walks the response and asks whether the
`owner` property name is present in `nestedEntities`, the answer is no. Its
value therefore passes through completely untouched, however deep it is
nested — the mechanism is keyed by property name, not by the `{ id, name }`
shape, so the shape alone does not trigger redaction. As a result, both
`owner.name` (previously obfuscated as a nested `member` entity) and
`owner.id` reach the client as-is: the output emits `owner: { id: 101, name:
"Jane Doe" }`, exposing the real member name that used to be obfuscated.
