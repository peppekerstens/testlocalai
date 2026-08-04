# Working agreements for AI agents operating this project

Rules for any AI agent (Claude Code or otherwise) that runs scripts, reads
tasks, or makes changes inside `.orchestration/`. Named `AGENTS.md` rather
than a tool-specific filename on purpose — this project's own stated goal
is to produce guidance reusable outside any one AI tool
([`README.md`](README.md)), so the rules governing how it's operated
belong here, in the project, not in any single tool's private/personal
memory or config.

This file is for **project-tooling behavior** — how to interpret and
invoke the scripts in `bench/`, how task scope is named and selected. It is
NOT where model-specific steering lives — that's a separate, per-model
concern under `models/<model>/README.md` + `models/<model>/rules/` (e.g.
`models/deepseek-r1-1.5b/rules/ste-writing.md`). If a rule is about how to
get one specific model to succeed at a task, it goes there, next to that
model, not here. If a rule is about how any agent (or any human) should
invoke or interpret this project's own tooling regardless of which model
is under test, it goes here.

## Scoping language is literal

When asked to run/test a named subset — "the doc tests", "just tool-use",
"the reason tasks" — treat that as an exact filter, not a hint toward
whatever broader default the underlying tooling normally runs.

`bench/pure-run.sh` bundles `doc-*` and `reason-*` tasks into one 18-task
suite by default (the "documenter/reasoner" role spans both tracks), and
now (2026-08-02) supports explicit track selection:

```bash
bash bench/pure-run.sh <model> --test docs      # only tasks/doc-*
bash bench/pure-run.sh <model> --test reason    # only tasks/reason-*
bash bench/pure-run.sh <model> --test tool      # only tasks/tool-*
bash bench/pure-run.sh <model> --test extract   # only tasks/extract-*
bash bench/pure-run.sh <model> --test review    # only tasks/review-*
bash bench/pure-run.sh <model> --test docs,reason   # both, same as no filter, but explicit
```

**Why:** an agent asked to "start the documenting test" once ran the bare
no-filter invocation, silently running the full combined 18-task suite
instead of just the 9 `doc-*` tasks — a real, caught mistake, not a
hypothetical. A script invoked with an explicit flag must run exactly what
the flag says. A bare/no-argument invocation running a broader default is
fine, but a caller who *did* specify a narrower scope must get exactly
that scope back, in scripts and in how an AI agent interprets a request
identically — inconsistency between the two is what causes confusion for
any reader (human or AI) of this project's results later.

**How to apply:** when asked to run/test/do a named subset of this
project's task suites, either (a) invoke the tooling with the explicit
selector for exactly that subset (`--test docs`, `--test reason`, or an
explicit task list), or (b) if no such selector exists yet for a new
suite/role being added, add one rather than falling back to a "run
everything" default — see `tasks/tool-*`, `tasks/extract-*`,
`tasks/review-*`, `tasks/visual-*` for the same discipline applied as new
roles are added.

## Reports are model-scoped; scratch files are not evidence

Reports live under `models/<model>/reports/`, never a shared
`bench/reports/` — a finding is always for one specific model, and mixing
models together in one directory (the pre-2026-08-02 layout) is exactly
what made the old reports hard to navigate. Two kinds of report:

- **Raw per-task verdict** (`bench.sh`, code-* tasks or a single doc-kind
  task): `models/<model>/reports/round-<round>-<task-basename>.md`.
- **Enriched, aggregated report** (`bench/report.sh <model> <role>`, role
  = `docs`/`reason`/`tool`/`extract`/`review`): `models/<model>/reports/
  report-<role>-<YYYYMMDD-HHMMSS>.md` — results table, token usage, and a
  diff against that model+role's previous report, computed automatically.
  The "Findings"/"Suggested next steps" sections are deliberately left as
  an explicit `<!-- TODO -->` — the script only knows PASS/FAIL/tokens,
  not *why* a task failed; don't fill those sections with guessed
  analysis, actually read the raw failure first.

`bench/pure-run.sh`'s own working files (`out-<task>.txt`,
`.tokens.json`) go in `bench/tmp/` — scratch, freely overwritten,
never cited as evidence in a report or a README. If a run's raw output is
worth keeping, it needs to land somewhere versioned (a report, or a
deliberately-named file under the relevant `models/<model>/`), not sit as
a mutable file in `bench/tmp/` that the next run will silently overwrite.

(2026-08-02: the previous `bench/reports/round-*` tree — ~50 directories,
no consistent naming convention, shallow single-verdict content, and two
stray hand-written summary docs duplicating `docs/BENCHMARK-REPORT.md` —
was deleted rather than migrated. Its raw evidence didn't reliably survive
a migration - some of it predates `dispatch.sh`'s token-tracking feature
entirely - and the actual findings were already written up in prose in the
relevant `models/<model>/README.md` files, which remain the durable
record.)

## Completing a report: exactly what MUST be filled in after `report.sh` runs

`bench/report.sh` mechanically generates the header, the results table,
token counts, and the delta vs. the previous report — everything it can
know without reading content. It leaves `## Findings` and `## Suggested
next steps` with a `<!-- NOT DONE YET` placeholder comment on purpose,
because it cannot read *why* a task failed. **A report with those
sections still templated is not finished** — do not treat report
generation as complete until they're filled in per the checklist below
(`bash bench/report-check.sh <report-file>` verifies mechanically). This is deliberately specific, not
"go add some analysis," because vague findings are exactly what made the
old `bench/reports/round-*` tree low-value in the first place.

**For every task in the results table with verdict FAIL, and every task
whose verdict *changed* since the previous report (a flip either
direction, not just new failures) — write one bullet under `## Findings`
with all four of these, in order:**

1. **Exact failure, quoted, not paraphrased.** Read the raw output —
   `bench/tmp/out-<task>.txt` if this came through `pure-run.sh`/
   `report.sh`, or `tasks/<task>/rounds/out-<round>.txt` if through
   `bench.sh` — then re-run that task's `verify.sh` against it and quote
   the actual failing diagnostic line(s) (e.g. `- missing Source A fact:
   'describe_obfuscation_policy'`), not a summary like "it failed to
   include a required fact." The report itself never carries this; it
   has to come from reading the file.
2. **Idiom classification.** Check this model's `history.md` for an
   already-diagnosed failure idiom matching this one. State explicitly
   either "matches `<idiom name>`, already known" or "new idiom, not
   previously documented for this model." Don't skip this because it
   feels obvious — the value is in the explicit record, not the
   inference.
3. **Truncation judgment, only if `finish_reason` shows truncation.**
   State explicitly whether this looks like the known rare-tail-event
   pattern (see `models/deepseek-r1-1.5b/history.md`'s context-window
   investigation — raising context size did not fix that model's
   truncation rate, it only let it burn more tokens before failing the
   same way) or something genuinely new. **Never recommend a context-size
   change in "Suggested next steps" without this explicit judgment
   written first** — a context bump was tried once already on
   unexamined evidence, declared "fixed," and had to be walked back after
   the user asked for the re-test that disproved it.
4. **Sample-size caveat.** If this run is the only draw of this task
   you have (true for almost every single `report.sh` invocation, since
   it runs each task once), write "single draw, not a reliability
   sample" explicitly. This project has independently re-learned that an
   n=1 or n=3 result can look conclusive and be wrong at least three
   times (qwen's task4 ~62% reliability behind one 6/6 round; deepseek-
   r1's no-think rate correcting from an apparent 3/3 to 4/8; lfm2.5's
   steering pass showing real per-task movement invisible in the 0/15
   headline number) — never state a rate or draw a conclusion from a
   single report without this caveat.

**Under `## Suggested next steps`, every suggestion must:**
- Name a specific task and a specific lever — not "steer more" or "try
  again." If an idiom from step 2 above already has a documented fix
  pattern for this model (check `history.md`), cite it and propose
  applying the same pattern; if not, propose something grounded in the
  exact quoted failure from step 1, not a generic guess.
- Explicitly state whether more draws are needed before acting on this
  finding at all (tie back to the sample-size caveat — "gather 3-5 more
  draws before changing the SPEC" is a valid, often correct, suggestion).
- Explicitly state whether `models/<model>/README.md`'s current-state
  verdict table/status needs updating as a result — yes/no, and what
  changes — closing the loop with the rule below. If yes, do it as part
  of finishing this report, don't leave it for later.

**When a finding here is genuinely new** (a new idiom, a confirmed
regression, a resolved issue) — not just "still failing the same way as
last time" — add it to `models/<model>/history.md` too, in addition to
this report. The report is the per-run record; `history.md` is the
narrative that explains how the model's current state was reached.

**Write the Findings/Suggested-next-steps up before starting the next
exploratory run, not after.** Diagnosing a run's failures often surfaces
a hypothesis worth testing immediately (e.g. "is the steering block
itself the problem?") — the temptation is to go chase it with a fresh
dispatch right away. Don't: finish writing this report's Findings and
Suggested next steps with what you already know *first*, then start the
follow-up run as its own step. **Why:** an agent diagnosed all 8 failures
in a `lfm2.5:1.2b-thinking` docs-role report, formed a real hypothesis,
and immediately launched a second comparison dispatch to test it — the
first report sat with both sections still at their TODO placeholder text
the whole time. Analysis that exists only in conversation and gets
interrupted (a permission prompt, a context compaction, the session
ending) is lost exactly like the un-persisted-report failure mode this
section already warns about, just one layer earlier: mid-diagnosis
instead of post-run.

**Before treating a report as done, run `bash bench/report-check.sh
<report-file>`** — mechanically confirms `## Findings` and `## Suggested
next steps` were actually filled in (exit 0) rather than left at
report.sh's placeholder (exit 1). This only catches "still templated",
not "filled in badly" — the checklist above is still what makes the
content correct, this just makes forgetting it impossible to miss.

Once that passes, `bash bench/report-heuristics.sh <report-file>` gives
a second, weaker pass: it flags (as advisory warnings, never a fail —
it always exits 0) a FAIL task with no sample-size-caveat language
nearby, a banned vague phrase ("steer more"/"try again") in Suggested
next steps, or no specific task named there at all. Keyword presence
is not proof the checklist above was actually satisfied, and its
absence is not proof it wasn't — treat its output as "worth a second
look," not a verdict. This is the deliberate Tier-4 remainder: the
parts of report-completion that genuinely need judgment, not more
scripting.

## Per-model doc-task steering: never edit tasks/<task>/SPEC.md

`tasks/<task>/SPEC.md` is the single, shared, model-agnostic task
definition — every model this project ever tests dispatches the exact
same path. **Never edit a doc task's `SPEC.md` to steer one specific
model.** To steer a model on a doc task, create
`models/<model-dir>/task-overrides/<task>.md` (model-dir = the model tag
with `:` replaced by `-`, matching every other `models/<dir>/` path) —
`bench/pure-run.sh` (and therefore `bench/report.sh`) checks for this
file first and dispatches it instead of the bare `SPEC.md` when it
exists, falling back to bare otherwise. This exactly mirrors
`bench.sh`'s existing `--rules <lang>` mechanism for code tasks
(`models/<model>/rules/<lang>-rules.md`, composed with `SPEC.md` at
dispatch time, `SPEC.md` itself never touched) — code tasks already got
this right; doc tasks didn't have an equivalent until this rule
(2026-08-02).

**Why:** `lfm2.5-1.2b-thinking`'s own quality loop once did exactly the
"never" above — overwrote the shared `SPEC.md` directly for 6 tasks —
and silently contaminated the *next* model's "bare" baseline with
leftover steering, committed before anyone caught it. Full incident:
`models/lfm2.5-1.2b-thinking/history.md`.

**How to apply:** before writing task-specific doc steering, create the
override under the *steering model's own* `task-overrides/` directory,
never edit the shared `SPEC.md`. Before starting a brand-new model's
Phase 1 baseline, you do not need to check or restore anything — bare
`SPEC.md` is now guaranteed stable, and a previous model's overrides
only ever apply to dispatches for that exact model (its own
`model-dir` in the override path). If you ever need the literal prompt
a previous model's report was generated against, check that model's
`task-overrides/<task>.md` first, `SPEC.md` only if no override exists
for that task.

## The quality loop — standard structure for a model+role optimization session

When asked to run a test-and-optimization loop for a model+role (e.g.
"test and optimize `lfm2.5:1.2b-thinking` for documenting"), follow this
structure rather than diagnosing and steering ad hoc. Every "run" below
means one full role re-test (`bash bench/report.sh <model> <role>`, or
the task subset that role covers) — not a single task. Every phase
follows the existing report rules above: write Findings/Suggested next
steps into the report **before** starting the next run in the loop, not
after (see the rule just above this one).

**Always check for prior work on this exact model+role before starting
a loop.** Read `models/<model>/reports/report-<role>-*.md`,
`README.md`, and `history.md` first. The Steering phase's run budgets
(4 per task in Tier 1, 5 for Tier 2) are cumulative for a given
model+task or model+role, not reset every time the loop is invoked (in
a new session, after a `/loop`, whatever) — prior runs are real evidence
regardless of whether they were originally run under this exact phase
structure. Map them onto the phases retroactively instead of re-running
work already done: the most recent report from before the current
invocation's changes is Phase 1's reference run; already-applied
steering (task-specific, borrowed from another model, or from external
research) counts against the relevant task's Tier 1 budget or Tier 2's
budget. Continue the loop from wherever prior work left off —
don't discard it and restart at Phase 1 just because it predates this
section.

**Phase 0 — Pre-flight infra research (conditional, uncapped).** Before
Phase 1, do a quick external check for dispatch-level requirements —
recommended sampling parameters, thinking-mode control, known
pathological behaviors (context-exhaustion loops, template quirks) —
whenever the model is new to this project, or Phase 1's own warm-up
shows truncation/empty output/runaway generation. **Why up front:** for
`qwen3.5:0.8b`, skipping this would have made Phase 1 itself
uninformative — the model's own card documents a known unterminated-
thinking-loop failure mode that a naive baseline would have hit on
every task. This is dispatch/infra research only (sampling params,
`enable_thinking`, context size) — *not* prompting/steering-technique
research, which stays in the Research phase below, because technique
research carries real negative-transfer risk (see Idiom E) that
infra-level fixes don't. Any dispatch-level finding applied here must be
documented per the "every dispatch-level tweak must be documented"
rule. Skip entirely for a model already known to this project with no
new pathological signs.

**Phase 1 — Reference run.** One baseline `bash bench/report.sh <model>
<role>` run against the model's current state (bare, or whatever
steering already exists) before touching anything, *or* the most recent
existing report if the "check for prior work" rule above found one.
This is the anchor every later phase's "did it improve" comparison is
measured against.

**Research phase (always both parts, uncapped, before any steering).**
Cheap relative to a dispatch run, so it always runs in full before
spending Steering-phase budget, not as a fallback once steering plateaus:
1. **Cross-model idiom check.** Read every other `models/<other-model>/`
   that has been tested against this *same* role's `history.md` and
   `README.md` for diagnosed idioms/fixes already validated there.
2. **External research.** Search external sources (web search, the
   model's card/official prompting guide) for prompting/steering
   guidance specific to this exact model checkpoint.
Both always run, regardless of what the other finds. A fix or technique
sourced either way is a *hypothesis* for this model, not a given — it
gets applied and verified in the Steering phase below like any other
lever, and the report must state whether it helped, was neutral, or
hurt, and why (a technique validated on one model backfiring on another
is a real, useful finding — see `lfm2.5-1.2b-thinking`'s Idiom E, STE
negative-transferred from `deepseek-r1-1.5b`). Whether or not an
external technique found here gets applied, the report and `README.md`
must also name any helper tooling identified as potentially useful
going forward (a linter/formatter, an MCP tool, a schema validator) —
even tooling not implemented yet — so the finding isn't lost.

**Steering phase — two tiers, specialist first, then a generalist
search.** Optimizations for one task can directly conflict with what
another task needs (a "preserve structure exactly" fix helped
`doc-verbatim`/`doc-repair` for `qwen3.5:0.8b` but broke
`doc-restructure`, whose entire job is to *change* structure) — batching
a fix across tasks that turn out to need opposite behavior hides that
conflict behind one flat headline number instead of surfacing it. Order
of preference within both tiers: cross-model-validated fixes and
research-informed techniques first (from the Research phase above), then
genuinely novel task-specific fixes grounded in the actual diagnosed
idiom (exact `verify.sh` quotes) — never a general-purpose blanket rules
block prepended to everything (measurably *hurt* several tasks for
`lfm2.5:1.2b-thinking`, see Idiom E).

*Tier 1 — Per-task specialist optimization.* Every currently-failing
task gets its own independent optimization attempt, unconstrained by
what any other task needs, stored as its own
`models/<model-dir>/task-overrides/<task>.md`. Budget: up to 4 runs per
task (a "run" is still one full role re-test — not every task's
override necessarily changes every run, so track each task's own
attempt count separately from the shared run counter). **Gate on the
2nd run**: give every task a genuine first attempt; after that result,
only keep investing further runs (up to the 4-run cap) in a task that
showed *some* real promise (a clear partial improvement, even short of
a full PASS — `doc-verbatim` going from "drops the whole table" to "one
tiny remaining defect" counts). A task that's flat or regressed after
run 1 gets gated out — stop, revert its override to bare (or whatever
prior state was best), move on. Don't burn the full per-task budget on
tasks showing no signal. It's fine, and expected, for a batched
diagnostic run to test a shared candidate fix across several
plausibly-similar tasks at once as the *first* probe (conserves
budget) — but the moment that batch's result is mixed, not uniform,
immediately split into independent per-task branches instead of
continuing to treat it as one lever.

*Tier 2 gate — decide automatically, do not ask.* Once Tier 1 settles
(every task either has a working specialist override or was gated out
to bare), run `bash bench/tier2-gate.sh <report-file>` against the
Tier-1-settled report. Exit 0 (GO, ≥60% specialist hit rate) → run
Tier 2. Exit 1 (SKIP, <60%) → skip Tier 2 entirely and go straight to
Confirm on the Tier 1 result. No exception, no question asked — a 60%+
specialist hit rate is the signal a shared config has enough of a
common target to be worth searching for; below it, Tier 1's own
per-task results (several tasks actively harmed by any steering at
all, see Tier 1 above) already answer the "is there a generalist"
question before spending Tier 2's budget finding out the slow way.
Quote the script's own output line in the report — this is a report
line, not a permission question.

*Tier 2 — Generalist search (max 5 runs, only when the gate above
passes).* Search for a single shared config usable by an end user who
doesn't know in advance which task shape they'll hit. **"No generalist
exists" is a fully acceptable, expected outcome for a small local
model, not a failure of this phase** — state it plainly in the report
and README rather than shipping a mediocre compromise nobody actually
wants. This mirrors `qwen2.5-coder-1.5b`'s own independent finding
("two different recipes for two task families — do not mix them," a
shared rules file that helps one family actively hurts the other) —
small models at the scale tested in this project have repeatedly not
generalized a single steering config across heterogeneous task shapes
within one role. Expect this outcome, don't fight it.

**When "no generalist config exists," check for a generalist *decision
procedure* before closing Tier 2 (added 2026-08-03).** A single shared
config genuinely cannot cover tasks whose fixes differ in *kind*, not
just detail — e.g. `qwen3.5:9b`'s docs role: 3 tasks needed
decoding-level grammar constraints (no prompt text fixes them, tested
extensively), 1 needed a specific named forbidden-token reminder (a
generic version of the same reminder measurably failed across 4 draws
— see `models/qwen3.5-9b/history.md`). No wording of one shared prompt
closes that gap; it was never a phrasing problem. What *does*
generalize across models and future sessions in that situation isn't
an artifact, it's a rule: **"when a task's failure is structural/
positional (wrong place for a fence, blank line, or table separator —
not wrong content), and resists real prompt-only steering, check
whether the serving backend supports grammar-constrained decoding
before spending more prompt-iteration budget."** This is genuinely
reusable — on any model, not just the one that discovered it — which
is what "generalist" is actually for. See
`docs/GRAMMAR-STEERING-PATTERNS.md` for the backend-capability check
and a starter library of structural grammar patterns to adapt rather
than re-derive from scratch. Document this kind of finding in the
model's own README/history.md as what it is — a decision procedure,
not a shared config — don't force it into the per-task
Specialist/Generalist table's "Generalist result" column, which is for
literal shared configs only.

Stop either tier early (move to Confirm) once further runs stop
producing improvement, or once every task in the role passes. **Moving
between phases/tiers (Research → Steering, Tier 1 → Tier 2 gate →
Confirm, Confirm → Performance → Final report) is autonomous — don't
stop to ask whether to continue.** State what phase just finished, its
result, and that you're proceeding, in that order, then proceed. Ask
only when a finding genuinely changes strategy in a way these rules
don't already resolve (a new idiom needing a real judgment call, a
dispatch-level change with real cost/risk) — not as a routine
between-phases check-in.

## Confirm — check the optimization is real, not one lucky draw

Once the quality loop's improvement phases stop producing gains, run
`bash bench/confirm.sh <model> <role>` against the current best-known
state, unchanged — it re-runs the full role test 3 more times back to
back and writes `confirm-<role>-<timestamp>.md` with a per-task
consistency table and a CONFIRMED/FLAKY verdict (every verdict up to
this point in the loop was a single draw, per the sample-size rule
above — this is where that gets checked, not skipped or re-derived by
hand each time).

- **CONFIRMED**: this is the loop's result.
- **FLAKY**: revert to the previous checkpoint — the last committed
  state before the change that introduced the flakiness — and run
  `confirm.sh` again against *that* state instead. Keep whichever
  confirmed-stable state is best; don't ship a flaky "improvement" as
  the loop's result just because one draw of it looked good.

## Performance run (max 5 full role re-test runs)

Once Confirm has settled on a stable state: investigate and apply
token-usage/latency optimizations that do **not** reduce the confirmed
quality (same pass count and per-task verdicts, checked by re-running
after each change — revert anything that regresses). One known
candidate technique: "caveman"-style output shaping
(github.com/juliusbrussee/caveman) — a short instruction that strips
filler, hedging, and pleasantries to cut *output* tokens specifically.
**Caveat before applying it here:** it only reduces output tokens (not
input or reasoning-phase tokens — no help for a "thinking" model's
`<think>` budget) and costs ~1-1.5k extra input tokens per turn as the
instruction's own overhead. Several models in this project already fail
via *under*-elaboration/terseness, not verbosity (e.g.
`lfm2.5-1.2b-thinking`'s Idiom A/E) — applying a "be terser" technique to
a model whose failures are about missing required content will make it
worse, not save tokens for free. Only apply where the model's failures
are about padding/verbosity, not missing content.

## Final report

The model+role's `README.md` gets its per-role section (see the
README-shape rule's Overview-table structure) replaced with the quality
loop's final report — not a separate document. It must state, in
addition to whatever the existing README-shape rules already require:

- **Usability score without optimizations** — the bare-baseline pass
  rate/verdict for this role (Phase 1's reference run).
- **Usability score with optimizations** — the Confirm-settled pass
  rate/verdict.
- **A comparison against a mainstream frontier LLM** — e.g. "with all
  optimizations and helper tooling applied, quality on this role is
  comparable to Claude Haiku 4.1, with the following restrictions:
  ..." — state the restrictions/caveats explicitly (context size, task
  types that still fail, reliability/flakiness, latency). This is a
  qualitative judgment call grounded in the loop's actual evidence, not
  a mechanically computed number — show the reasoning, don't just assert
  the comparison.

**Checkpoint before treating the Final report as done: run `bash
bench/check-readme-shape.sh <model>`.** Mechanically diffs the model's
`README.md` headings against `templates/new-model/MODEL-README-SCAFFOLD.md`
(exit 0 if every scaffold heading/pattern is present, exit 1 with the
missing ones listed otherwise). **A "How to optimize" section missing
entirely reads as nothing wrong on a read-through** (the file just
flows from the Final report straight to Setup, which looks complete)
— it only shows up as a gap when the heading lists are compared. This
exact failure happened: all 4 `qwen3.5-*` model READMEs written in one
session skipped "How to optimize" entirely, despite this checkpoint
rule already existing as a manual "run grep and compare" instruction,
caught only when the user asked "does your latest report conform to
the template?" and a heading diff was finally run by hand — the reason
this is now a script instead of a step an agent has to remember to run
manually. Once headings match, confirm content per section: the Overview
table has this role's row updated (status, pass rate, mainstream
comparison, and its Details link still resolves to the right heading);
the role section reads as current-state/verdict, not a round-by-round
retelling of the loop (that belongs in `history.md`, linked, not
summarized); "How to optimize" entries for this role are stated as
facts/instructions, not narrated as "we tried X and Y happened."
**Why:** this is the same check that would have caught
`lfm2.5-1.2b-thinking`'s README growing back into a 115-line narrative
mid-loop, closing the gap the scaffold was built for instead of relying
on remembering the rule unprompted at the one moment (loop closure)
it matters most.

## After a test run, persist it — don't leave findings only in chat

Any time you run a real model against a task/role (`bench.sh`,
`pure-run.sh`, or `bench/report.sh`), the run isn't done until its result
is written to a file, not just reported to the user in conversation.
Concretely, after a run:

1. Generate a report — prefer `bash bench/report.sh <model> <role>` for a
   role-track run (writes `models/<model>/reports/report-<role>-
   <timestamp>.md` automatically); `bench.sh` already writes its own
   `models/<model>/reports/round-<round>-<task>.md` per call.
2. Update `models/<model>/README.md`'s current-state summary (its verdict
   table / "Current status" section) to reflect the new result — a report
   file that nothing else points to is easy to miss later.
3. If the run surfaced a new diagnosed idiom, a regression, or a genuinely
   new finding (not just a number going up or down), add it to
   `models/<model>/history.md`, not just the README — the README stays
   current-state-only (see the next rule).

**Why:** `models/lfm2.5-1.2b-thinking/` had zero persisted results despite
a real baseline run and a real steering pass having already happened —
both were reported only in conversation and would have been lost
entirely if no one thought to write them down after the fact. A model
with real test data and no file recording it is indistinguishable, to the
next reader, from a model that was never tested.

**Rule: a full test run requires at least one commit, minimum.** Writing
the report/README/history files to disk isn't enough by itself — an
uncommitted file is still invisible to the next `git log` reader and can
be lost the same way an unwritten one can. Every full test run must end
with **at least one commit** covering whatever it produced or updated.
More commits are fine (e.g. one for the report, one for the README/history
update) — fewer than one is not.

## README shape: current-state only, history deferred

A `README.md` anywhere in this project must stay to-the-point and
traversable, not accumulate into a chronological log. Concretely:

- **Root `README.md`**: project purpose, what `bench/` and the reports
  system are, pointers to everything else. No round-by-round detail.
- **`models/README.md`**: one index — which model has been tested against
  which role, with a status indicator, linking to each model's own
  README. Nothing else.
- **`models/<model>/README.md`**: current state only — starts with an
  **Overview table**, one row per role this model has ever been tested
  against (tested or not): `Role | Status | Pass rate (bare → current) |
  vs. mainstream LLM | Details` (Details = a markdown link to that
  role's own heading further down). Below the table: per-role sections
  with a verdict/status, direct "how to optimize for role X"
  instructions, setup facts. **If the role went through Tier 1/Tier 2
  Steering (per-task specialist optimization), that role's section also
  needs a per-task table**: `Task | Specialist result | Specialist
  config | Generalist result` (Specialist config = a link to
  `task-overrides/<task>.md` or "bare" if gated out; Generalist
  result/config = whatever Tier 2 settled on, or "no generalist —
  n/a" if Tier 2 found none) — the role-level Overview row is one
  aggregate number, this table is where the actual per-task,
  per-strategy picture lives, without which "no generalist found" reads
  as a bare failure instead of the specific, useful per-task result it
  actually is. Ends with links to `history.md` and `reports/`. If a
  sentence is telling a story ("first we tried X, then
  Y happened, so we tried Z") instead of stating a current fact or
  instruction, it belongs in `history.md`, not here — this includes
  phase-by-phase progress updates: don't append "here's what changed
  this run" paragraphs to a status section over the course of a loop,
  replace the section's content with the new current state and push
  what changed (and why) to `history.md` instead, every time, not just
  at the end.
- **`models/<model>/history.md`**: the full narrative — round-by-round
  results, diagnosed idioms as they were found, debugging trails,
  everything that explains *how* the current state was reached. Nothing
  here needs to be concise; completeness matters more than brevity,
  since this is the fallback for full historical lookup once
  `bench/reports/round-*`-style raw evidence ages out or gets
  regenerated. Append here after a steering session; don't let it leak
  back into the README. This is a distinct, necessary layer from
  `reports/` (raw per-run mechanical data — a results table plus that
  run's own Findings/Suggested-next-steps) — reports don't connect
  across runs into a "how did we get here" story, `history.md` does;
  neither one replaces the other.

**Why:** `models/deepseek-r1-1.5b/README.md` grew to 418 lines, ~80% of
it round-by-round narrative, before this rule existed — a reader looking
for "should I use this model for task X" had to read a lab notebook to
find out. The fix (2026-08-02) split every model's README along this
line. **This rule alone wasn't enough to prevent a repeat**: later the
same day, `models/lfm2.5-1.2b-thinking/README.md`'s "Current status"
section grew to ~115 lines of round-by-round narrative anyway — every
quality-loop phase appended its own paragraph instead of replacing the
section's content, even though `history.md` already had the same
material, fuller, in parallel the whole time. Caught by the user, not
self-caught. The Overview-table requirement and the explicit
"replace, don't append, every time" instruction above were added at the
same time as the fix, specifically because the rule already existing
wasn't sufficient — the failure mode is losing track of the rule
mid-loop, not not knowing it.

## Every dispatch-level tweak must be documented, not just passed as a flag

Any adjustment made to get better results out of a model that lives
*outside* a task's `SPEC.md` — a `dispatch.sh` env var override
(`DISPATCH_TEMPERATURE`, `DISPATCH_TOP_P`/`_TOP_K`/`_MIN_P`/
`_PRESENCE_PENALTY`, `DISPATCH_ENABLE_THINKING`, `DISPATCH_NOTHINK`,
backend/port selection, a systemd service's `-c`/`-ngl`/other launch
flags, anything else passed at the command line or baked into a service
file rather than into a tracked task file — must be written into that
model's own `README.md` **Setup** section (the exact env
vars/flags/values used) before a test run using it counts as reported.
**Why:** unlike a `SPEC.md` steering change, a dispatch-level tweak
leaves no file-level trace by default — it's just a shell argument for
one invocation, easy to apply, get a result from, and then lose the
moment the exact command isn't re-typed identically later. A future
session (or a different agent) re-running the "same" test without
knowing a specific override was needed will silently get a different,
probably worse, result and have no way to know why. **How to apply:**
before or alongside any report/history entry that used a non-default
dispatch parameter, add or update a line in `models/<model>/README.md`'s
Setup section stating the exact env var(s) and value(s) required to
reproduce that model's test conditions — not just "some tuning was
needed," the literal reproducible command/values.

## Don't assume the visual role is wired up

`README.md`'s Roles table lists **visual** as scaffold-only
(2026-08-02) — `models/lfm2.5-vl-450m/README.md` has the plan and
candidate model choice, but no GGUF is downloaded, no systemd service
exists, no `tasks/visual-*` tasks exist, and the model is not in
`dispatch.sh`'s `ALLOWED_MODELS`. If asked to test/run/steer the visual
role, read that README's "what still needs to happen" list first — do
not treat the presence of a `models/lfm2.5-vl-450m/` directory as
evidence the role is usable.

## Unattended operation is authorized in this repo

`.claude/settings.json` blanket-allows the `Bash` tool (`Bash(*)`,
2026-08-02 — previously a long list of narrow per-command prefixes,
widened because compound commands like a `for` loop or a `&&`/`;` chain
don't match a single narrow prefix and fell through to a permission
prompt even when every command inside them was already individually
allowed) so an AI agent can run multiple optimization loops — dispatch,
diagnose, steer, report, commit, push — without stopping to ask
permission at each step. This is a deliberate, explicit
grant (2026-08-02), scoped to this repo only, not a general license to
skip judgment on genuinely risky operations: force-push, `git reset
--hard`, branch deletion, and `--no-verify`/`--no-gpg-sign` are explicit
`deny` entries regardless, and destructive operations outside this
repo's own scope still need to be raised, not just done.

The same file also blanket-allows the `Edit` and `Write` tools
(2026-08-02) — file edits/creates of any kind (steering rules, task
files, scripts, reports, README/history updates) don't prompt either.
Without this, an agent steering a model for a newly added task type or
role can't actually write the new task files, rule files, or code
changes that role requires without stopping for permission on every
single file — this closes that gap the same way the Bash/git grant
already does for shell commands. Same scope caveat as above: this
authorizes routine file changes in this repo, not a license to skip
judgment — e.g. still raise before touching anything outside this repo's
own directory tree.

**Git push is scoped to this repo only, enforced by GitHub itself, not
just by convention.** This repo's `origin` remote uses a dedicated SSH
deploy key (`~/.ssh/id_ed25519_testlocalai`, added to *this repo's*
GitHub deploy keys with write access — not the account-wide personal
key), routed via an SSH config host alias (`github-testlocalai`) with
`IdentitiesOnly yes` so it can never fall back to a broader key. Verified
empirically, not just configured: the same deploy key was tested against
a different repo (`connectwise-mcp`) and GitHub rejected it ("Repository
not found" — deploy keys are invisible to repos they aren't attached to).
An unattended loop running in this repo cannot push anywhere else, even
by mistake — this isn't a policy an agent has to remember to follow, it's
enforced at the GitHub key level.

**Service restarts/reloads are authorized when in service of a quality
loop lever (2026-08-02).** Some genuine steering levers are
server-startup flags, not per-request dispatch overrides — e.g.
llama-server's `--reasoning-budget N` (caps reasoning tokens, forcing a
clean `</think>` instead of running unrestricted to the context
ceiling) is set via the systemd service's `ExecStart`, not an env var
`bench/dispatch.sh` can pass per-call. Testing different values means
editing the service file and running `systemctl --user daemon-reload`
+ `restart` between attempts. This is explicitly authorized, not
something to ask about each time: a restart takes a few seconds,
trivial next to the cost of *not* testing a real lever — a single
runaway-thinking task this project measured took 211 seconds. Document
any such change per the existing "every dispatch-level tweak must be
documented" rule (the systemd service's flags are exactly the kind of
setup fact that rule already requires recording in the model's own
`README.md`), and restore the previous flag value/config afterward if
the value being tested doesn't end up as the kept configuration —
don't leave an untested or rejected value live in the service file.

**Mandatory: restart the target LLM service and log free VRAM/RAM
before every `bench/report.sh` test run (2026-08-03).** Discovered on
`qwen3.5:9b`: a ~2.5-hour sustained session (many dispatches across
several steering rounds, no restart in between) drove generation from
a validated 9.46 tok/s down to 0.73 tok/s — system RAM exhausted, swap
100% full — found mid-test, not something any earlier *short*
validation run had surfaced. A fresh restart fixed it immediately.
`bench/report.sh` now does this automatically for the `llamacpp`
backend: restarts the systemd unit matching the target model's
`--alias`, waits for `/health`, then logs pre-run free VRAM
(`nvidia-smi`) and free RAM (`free -m`) into the report's header — so
a report is self-documenting about the memory conditions it ran under,
and a degraded-session result never silently passes as a clean one.
This is a **test-measurement** hygiene rule, not a production-serving
recommendation — it optimizes for clean, reproducible signal about the
model's own capability, deliberately not representative of how a
service behaves under continuous real-world load (which is exactly
the condition that surfaced this problem in the first place). Applies
to `bench/report.sh` (the "this counts as an official test run" entry
point); doesn't apply to ad-hoc single-task `dispatch.sh`/`pure-run.sh`
calls during rapid iterative steering, where restarting before every
single prompt attempt would be disproportionate overhead — but if a
steering session runs long (multiple hours, dozens of rounds) without
going through `report.sh`, check free VRAM/RAM manually
(`nvidia-smi --query-gpu=memory.free --format=csv`, `free -h`) and
restart if either looks tight, rather than assuming a slow draw is a
model/task problem.

## See also

- [`README.md`](README.md) — project purpose, layout, best-first
  presentation rule, how to add a new model or a new source project.
- `models/<model>/README.md` — per-model verdicts and bench-plan history.
- `models/<model>/rules/` — per-model steering blocks (what actually helps
  *that* model succeed — never assumed to transfer to another model).
