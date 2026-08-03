# Project history

The narrative home for this project itself — origin, cross-model
findings that shaped its conventions, and retired naming/structure.
Per-model findings live in `models/<model>/history.md`; this file is
one level up, for facts about the project, not about any one model.

## Origin

This project began as a subset of the `connectwise-mcp` C# port repo,
where it lived at `csharp/.orchestration/` — hence the project's
original name, `.orchestration`. It was organized as standalone from
early on and eventually renamed to match its actual GitHub repo,
`testlocalai`, once it was clearly generic: usable for any
AI-enhanced project and any local LLM, not just the C# port or
`qwen2.5-coder`. Older documentation, commit messages, or file paths
may still reference `.orchestration` or `csharp/.orchestration/` —
that's this same project under its earlier name, not a different one.

Task sets (SPECs + harnesses) live flat under `tasks/`, role-prefixed
(`code-*`, `doc-*`, `reason-*`, `tool-*`, `extract-*`, `review-*`,
`visual-*`) — a task's skill isn't tied to one source project, so it
isn't nested under one. A `tasks/<project>/` convention for
source-project-specific reference material (SDK probes, cheat-sheets)
existed for a while (e.g. `tasks/csharp/`) but was retired 2026-08-03 —
see "Retired: onboarding-trail cleanup example" below.

## Cross-model finding: specialists don't generalize

Small local models at the scale tested here (~1-2B parameters) have
repeatedly not generalized a single steering config across
heterogeneous task shapes within one role — a fix that helps one task
actively hurts another that needs different behavior. Two concrete
cases that established this as an expected pattern, not a one-off:

- `qwen2.5-coder-1.5b` needed a two-recipe split across its two
  code-task families — one config per family, not one config for both.
- `qwen3.5:0.8b`'s structure-preservation fix helped a copy task while
  breaking a restructure task in the same run.

This is why per-model steering sessions default to finding a
**specialist** config per task first, and only search for a
**generalist** afterward — see `AGENTS.md`'s quality loop, Steering
phase, for the two-tier structure this produced. "No generalist
exists" is a fully acceptable, expected outcome to document, not a
failure to keep chasing.

## Best-first presentation: why, with an example

Whatever configuration is currently validated-best for a given
model+role+task is kept under its plain name (`SPEC.md`,
`<lang>-rules.md`), never buried behind a qualifier or sitting as a
co-equal alternative next to something worse. This is a **process**
rule, not a technique endorsement — "best" is re-evaluated per model,
per role, per task, and never assumed to transfer.

Example of why the "never assumed to transfer" caveat matters:
compressed ("caveman-style") prompts won for `qwen2.5-coder-1.5b` on
its C# code-emission tasks specifically. That's one model's evidence
on one task family — not a general recommendation to compress prompts,
and not something later assumed to apply to any other model without
its own real test.

## Retired: onboarding-trail cleanup example

`models/<model>/{prompts,outputs,logs}/` holds unscored, manual
round-trips from onboarding a model before any task SPEC existed for
it — meant to be provisional. `qwen2.5-coder-1.5b`'s onboarding trail
was retired once its findings were fully captured in durable artifacts
local to this repo (originally `tasks/csharp/sdk-cheat-sheet.md` +
`tasks/csharp/probe/`) plus a deviation note in the source
`connectwise-mcp` repo's own `ORCHESTRATION.md` (not a file that lives
here) — nothing was lost, the raw transcript was just redundant once
superseded.

**⚠️ 2026-08-03: this pattern is a cautionary tale now, not just a clean
example.** A later session overwrote `tasks/csharp/sdk-cheat-sheet.md`
in place while doing unrelated sanitation, not realizing it was the
*sole* remaining copy of the preserved findings this note describes —
the raw trail really was already gone by then, so that edit nearly
caused real, permanent loss. Recovered from git history and relocated
to `models/qwen2.5-coder-1.5b/onboarding-cheatsheet-original.md` — see
that model's `history.md` for the full incident. `tasks/<project>/` as
a reference-material location has been retired (nothing currently uses
it); the lesson generalizes past this one file: **a "durable" artifact
that isn't clearly marked as the sole surviving copy of something else
you already deleted is a trap for the next session** — mark it loudly,
or don't rely on deleting the original until the durable copy is
confirmed genuinely redundant elsewhere too.
