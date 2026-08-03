# New project — task set

A benchmark task is a self-contained micro-task with fixed acceptance tests.
The harness proves (or disproves) that a small local LLM can write the code
correctly, and the SPEC is the lever you tune. Tasks live flat under
`tasks/`, named `<role>-<name>` (role prefix: `code-`/`doc-`/`reason-`/…) —
not nested under a project subdir, since a task's skill isn't tied to one
source project.

If your project has an unfamiliar SDK/API surface, probe it first (a
throwaway scratch project you build and verify yourself), then fold the
*verified* findings directly into the resulting task's `SPEC.md` — don't
keep a separate standalone reference doc/probe directory around
afterward. (A `tasks/<project>/` reference-material-only convention
existed for this earlier but was retired 2026-08-03: its one instance,
`tasks/csharp/`, was pure overhead once its findings landed in a real
task — see `tasks/code-csharp-mcpidentity/SPEC.md` for what that looks like,
and root `history.md` for why the standalone version was dropped.)

## Task-set layout

```
tasks/
├── <role>-<name>/            # one task per skill you care about
│   ├── SPEC.md               # the exact prompt — always the current
│   │                          # validated-best; never a lesser co-equal
│   │                          # variant (see root README "Best-first
│   │                          # presentation")
│   ├── harness/
│   │   ├── <Task>.csproj     # OR requirements.txt for a Python task —
│   │   │                      # bench.sh auto-detects which from this
│   │   │                      # marker file; see its header comment for
│   │   │                      # how to add a third language
│   │   ├── src/              # subagent transcription lands here (runner clears it)
│   │   └── tests/            # fixed acceptance tests = GROUND TRUTH
│   ├── rounds/                # generated: prompt-<round>.txt, out-<round>.txt
│   └── history/               # optional: superseded SPEC.md variants worth
│                               # keeping for iteration comparison (bench.sh
│                               # --legacy), e.g. history/SPEC-verbose.md
└── <role>-<name2>/           # every task is a flat sibling — no project
                                # subdir; fold any SDK/domain findings
                                # straight into this SPEC.md instead
```

## SPEC skeleton

Write the task text so the model can reproduce it without inference. The
single biggest lever found so far (at 1.5B scale): **show the complete
code shape verbatim; never describe behavior you could paste instead.**

```markdown
# Task: <one sentence>

## Contract
- File: `<Name>.cs` in namespace `<Ns>` (C#) or `<name>.py` (Python — no
  namespace, just a module-level function/class per the harness's import
  convention)
- <exact behavior, in order of application; numbered if order matters>

## Input/edge cases
- <every edge case you will test, spelled out>

## MUST / MUST NOT
- MUST: <constraints the tests check>
- MUST NOT: <negative examples; e.g. "no using lines beyond: …">

## Recommended shape
```csharp
<complete class/method — the verbatim target>
```
```

## Running

```bash
BENCH_MODEL=<model> ./.orchestration/bench/bench.sh <role>-<name> <round> <FileName>.cs
```

Reports land in `models/<model>/reports/round-<round>-<basename>.md` —
model-scoped, not a shared directory (findings are always for one specific
model, see `AGENTS.md`). Round-label strings can still be reused across
different models' report sets for side-by-side comparison, but each
model's reports live under its own `models/<model>/reports/`, never mixed
together. Prompt/output history lands in the task's own `rounds/` dir.
For an aggregated, enriched report across a whole role's task suite
instead of one raw per-task verdict, use `bench/report.sh <model> <role>`
— see `bench/README.md`.

## Pointers

- Rules files are per-model, not shared: `models/<model>/rules/<lang>-rules.md`
  is always that model's current validated-best (whatever technique earned
  it — don't assume a compressed/"caveman-style" ruleset is the right
  starting point for a new model; a new model may need different rules,
  or none at all). Superseded variants worth keeping live in
  `models/<model>/rules/history/`, runnable via `bench.sh --legacy`.
- What the whole exercise concluded so far: `models/README.md` (index of
  every model × role tested, with a status indicator), then each
  `models/<model>/README.md` for that model's specific verdict.
- Build step is in `bench/bench.sh` ("build+test") — swap for your language.
