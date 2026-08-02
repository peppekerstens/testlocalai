Real source: docs/TOOL_CONTRACTS.md line 78-80: "Optional fields are
omitted entirely from the JSON (not emitted as `null`) when ConnectWise
doesn't return them — every `if (redactedX.field) output.field = ...` in
the source only assigns on a truthy value." This is this project's own
real, documented output convention — the extraction task below applies the
same discipline to a different schema. Not read by any script — kept for
traceability.
