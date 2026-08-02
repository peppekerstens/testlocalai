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
next steps` as `<!-- TODO -->` on purpose, because it cannot read *why* a
task failed. **A report with those sections still empty is not
finished** — do not treat report generation as complete until they're
filled in per the checklist below. This is deliberately specific, not
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

## The quality loop — standard structure for a model+role optimization session

When asked to run a test-and-optimization loop for a model+role (e.g.
"test and optimize `lfm2.5:1.2b-thinking` for documenting"), follow this
structure rather than diagnosing and steering ad hoc. Every "run" below
means one full role re-test (`bash bench/report.sh <model> <role>`, or
the task subset that role covers) — not a single task. Every phase
follows the existing report rules above: write Findings/Suggested next
steps into the report **before** starting the next run in the loop, not
after (see the rule just above this one).

**Phase 1 — Reference run.** One baseline `bash bench/report.sh <model>
<role>` run against the model's current state (bare, or whatever
steering already exists) before touching anything. This is the anchor
every later phase's "did it improve" comparison is measured against.

**Phase 2 — Obvious-improvement runs (max 5 full role re-test runs).**
Diagnose the reference run's failures per the report-completion rules
(exact `verify.sh` quotes, idiom classification), apply grounded,
task-specific steering — a short instruction targeted at the actual
diagnosed idiom, not a general-purpose blanket rules block prepended to
everything (a blanket preamble measurably *hurt* several tasks for
`lfm2.5:1.2b-thinking`, see its `history.md`'s Idiom E) — then re-run the
full role test. Repeat, up to 5 runs total in this phase. Stop early
(move to Confirm) once a run doesn't improve on the previous one, or
once every task in the role passes.

**Phase 3 — Cross-model idiom transfer (max 5 full role re-test runs).**
Before inventing new fixes, check every other `models/<other-model>/`
that has been tested against this *same* role's `history.md` and
`README.md` for diagnosed idioms/fixes already validated there. Apply
any that plausibly transfer to this model, re-test, up to 5 runs. A fix
that worked for one model is a *hypothesis* for another, not a given —
state in the report whether each borrowed fix helped, was neutral, or
didn't apply here, and why.

**Phase 4 — External research (max 5 full role re-test runs).** Search
external sources (web search, the model's card/official prompting
guide) for prompting/steering guidance specific to this exact model
checkpoint. Apply candidate techniques, re-test, up to 5 runs. Whether
or not an external technique found here gets applied, the report and
`README.md` must name any helper tooling identified as potentially
useful going forward (a linter/formatter that could catch a structural
defect before `verify.sh` does, an MCP tool, a schema validator, etc.)
— even tooling not implemented yet — so the finding isn't lost.

Any phase (2, 3, or 4) ends early and moves to Confirm once a run
produces no further improvement over the previous one, regardless of
remaining budget in that phase's max-5.

## Confirm — check the optimization is real, not one lucky draw

Once the quality loop's improvement phases stop producing gains:

1. Re-run the full role test **3 more times** against the current
   best-known state, unchanged, back to back. Every verdict up to this
   point in the loop was a single draw (n=1) per the sample-size rule
   above — this is where that gets checked, not skipped.
2. **If consistent** (same pass count, same per-task verdicts across all
   3 runs): this is the loop's confirmed result.
3. **If flaky** (pass count or any task's verdict varies across the 3
   runs): revert to the previous checkpoint — the last committed state
   before the change that introduced the flakiness — and run *that*
   state's own 3-loop consistency check instead. Keep whichever
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

The model+role's `README.md` Current-status section **is** the quality
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
- **`models/<model>/README.md`**: current state only — a verdict/status
  table, direct "how to optimize for role X" instructions, setup facts.
  Ends with links to `history.md` and `reports/`. If a section is telling
  a story ("first we tried X, then Y happened, so we tried Z") instead of
  stating a current fact or instruction, it belongs in `history.md`, not
  here.
- **`models/<model>/history.md`**: the full narrative — round-by-round
  results, diagnosed idioms as they were found, debugging trails,
  everything that explains *how* the current state was reached. Nothing
  here needs to be concise; completeness matters more than brevity,
  since this is the fallback for full historical lookup once
  `bench/reports/round-*`-style raw evidence ages out or gets
  regenerated. Append here after a steering session; don't let it leak
  back into the README.

**Why:** `models/deepseek-r1-1.5b/README.md` grew to 418 lines, ~80% of
it round-by-round narrative, before this rule existed — a reader looking
for "should I use this model for task X" had to read a lab notebook to
find out. The fix (2026-08-02) split every model's README along this
line; this rule is what keeps it split going forward instead of drifting
back.

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

## See also

- [`README.md`](README.md) — project purpose, layout, best-first
  presentation rule, how to add a new model or a new source project.
- `models/<model>/README.md` — per-model verdicts and bench-plan history.
- `models/<model>/rules/` — per-model steering blocks (what actually helps
  *that* model succeed — never assumed to transfer to another model).
