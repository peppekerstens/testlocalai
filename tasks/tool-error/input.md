Real source: docs/TOOL_CONTRACTS.md, `## Error behavior (applies to all
tools)` section — nonexistent IDs are not special-cased, they surface
ConnectWise's own 4xx response wrapped in `ConnectWise API error: <status>
<statusText>`, with `isError: true`. Not read by any script — kept for
traceability of where the facts in SPEC.md/expected.md were sourced from.
