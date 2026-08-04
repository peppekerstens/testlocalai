# Working agreements for AI agents operating this project

Rules for any AI agent working in this repo. Named `AGENTS.md`, not a
tool-specific filename — this project aims to produce guidance reusable
outside any one AI tool ([`README.md`](README.md)).

Scope: **project-tooling behavior** — how to run/interpret `bench/`
scripts, how task scope is named. NOT model-specific steering — that
belongs in `models/<model>/README.md` + `models/<model>/rules/`.

## Scoping language is literal

A named subset ("the doc tests", "just tool-use") is an exact filter,
not a hint. `bench/pure-run.sh` defaults to the combined 18-task
doc+reason suite; scope it explicitly:

```bash
bash bench/pure-run.sh <model> --test docs      # tasks/doc-*
bash bench/pure-run.sh <model> --test reason    # tasks/reason-*
bash bench/pure-run.sh <model> --test tool      # tasks/tool-*
bash bench/pure-run.sh <model> --test extract   # tasks/extract-*
bash bench/pure-run.sh <model> --test review    # tasks/review-*
bash bench/pure-run.sh <model> --test docs,reason   # explicit, same as no filter
```

**Why:** "start the documenting test" once ran the bare 18-task
invocation instead of `--test docs` — real mistake, not hypothetical.
A caller who names a scope must get exactly that scope back.

**How to apply:** use the explicit selector. If a new role/suite has
none yet, add one rather than falling back to "run everything" (see
`tasks/tool-*`, `tasks/extract-*`, `tasks/review-*`, `tasks/visual-*`).

## Reports are model-scoped; scratch files are not evidence

Reports live under `models/<model>/reports/`, never a shared dir.

- **Raw per-task** (`bench.sh`, or a single doc-kind task):
  `models/<model>/reports/round-<round>-<task-basename>.md`.
- **Aggregated** (`bench/report.sh <model> <role>`, role =
  `docs`/`reason`/`tool`/`extract`/`review`):
  `report-<role>-<timestamp>.md` — results table, tokens, diff vs. the
  previous report, all automatic. `## Findings`/`## Suggested next
  steps` start as a `<!-- NOT DONE YET` placeholder — the script can't
  know *why* a task failed, so don't guess; read the raw output first.

`bench/pure-run.sh`'s working files (`bench/tmp/*`) are scratch — never
cite them as evidence. Output worth keeping goes in a report or a
named file under `models/<model>/`. (History of the old flat
`bench/reports/round-*` tree: see `history.md`.)

## Completing a report: what MUST be filled in after `report.sh` runs

`report.sh` generates everything mechanical (header, results, tokens,
diff). It leaves `## Findings`/`## Suggested next steps` templated on
purpose. **A report with those sections still templated is not
finished.** Vague findings are what made the old report tree low-value
— be specific, not "go add some analysis."

**For every FAIL task, and every task whose verdict changed since the
previous report — one bullet under `## Findings` with all four, in
order:**

1. **Exact failure, quoted, not paraphrased.** Read the raw output
   (`bench/tmp/out-<task>.txt`, or `tasks/<task>/rounds/out-<round>.txt`
   for `bench.sh`), re-run `verify.sh` against it, quote the actual
   failing diagnostic line. Never summarize as "it failed to include X."
2. **Idiom classification.** Check the model's `history.md` for a
   matching diagnosed idiom. State "matches `<idiom>`, already known"
   or "new idiom." Don't skip because it seems obvious.
3. **Truncation judgment, only if `finish_reason` shows one.** State
   whether this is the known rare-tail-event pattern (see
   `models/deepseek-r1-1.5b/history.md`) or something new. Never
   recommend a context-size change without this judgment written
   first — one was tried on unexamined evidence, declared "fixed," and
   had to be walked back.
4. **Sample-size caveat.** If this is the only draw (true for almost
   every `report.sh` call), say "single draw, not a reliability
   sample" explicitly. n=1/n=3 results have looked conclusive and been
   wrong at least three times in this project (qwen task4 ~62%
   reliability behind one 6/6; deepseek-r1's no-think rate 3/3→4/8;
   lfm2.5's steering gains invisible in a 0/15 headline). Never state a
   rate without this caveat.

**Every `## Suggested next steps` bullet must:** name a specific task
+ lever (not "steer more"/"try again" — cite `history.md`'s fix
pattern if one exists, else ground it in the quoted failure above);
state explicitly whether more draws are needed first; state explicitly
whether `README.md`'s status needs updating (do it now if yes, don't
defer).

**New finding (new idiom, confirmed regression, resolved issue) also
goes in `models/<model>/history.md`**, not just the report — the
report is per-run, `history.md` is the narrative.

**Write Findings/Suggested-next-steps before starting the next run,
not after.** A hypothesis formed while diagnosing is tempting to chase
immediately — don't; finish this report first. **Why:** an agent once
diagnosed all 8 failures in a report, formed a real hypothesis, and
launched a follow-up dispatch immediately — the report sat templated
the whole time, and the analysis existed only in conversation, at risk
of being lost the same way an unpersisted result is.

**Verification, mechanical then advisory:**
- `bash bench/report-check.sh <report-file>` — hard gate, exit 1 if
  Findings/Suggested-next-steps are still templated.
- `bash bench/report-heuristics.sh <report-file>` — advisory only,
  always exits 0. Flags a FAIL with no sample-size language nearby, a
  banned vague phrase, or no task named in Suggested next steps.
  Keyword presence/absence is not proof either way — read the report;
  treat this as a nudge, not a verdict.

## Per-model doc-task steering: never edit tasks/<task>/SPEC.md

`tasks/<task>/SPEC.md` is shared and model-agnostic. **Never edit it to
steer one model.** Instead create
`models/<model-dir>/task-overrides/<task>.md` (`:` → `-` in the model
tag) — `pure-run.sh`/`report.sh` use it automatically when present,
falling back to bare `SPEC.md` otherwise. Mirrors `bench.sh`'s existing
`--rules <lang>` mechanism for code tasks.

**Why:** `lfm2.5-1.2b-thinking`'s own quality loop once did exactly the
"never" above — overwrote shared `SPEC.md` for 6 tasks, silently
contaminating the next model's "bare" baseline before anyone caught
it. Full incident: `models/lfm2.5-1.2b-thinking/history.md`.

**How to apply:** write steering under the steering model's own
`task-overrides/`, never touch `SPEC.md`. Starting a new model's Phase
1 baseline needs no cleanup check — bare `SPEC.md` is guaranteed
stable; other models' overrides never apply outside their own
`model-dir`.

## The quality loop — standard structure for a model+role optimization

For "test and optimize `<model>` for `<role>`," follow this structure,
not ad hoc diagnosis. A "run" = one full role re-test
(`bash bench/report.sh <model> <role>`), not a single task. Write
Findings/Suggested-next-steps before the next run in the loop, every
time (see rule above).

**Check for prior work before starting.** Read
`models/<model>/reports/report-<role>-*.md`, `README.md`,
`history.md`. Run budgets (4/task Tier 1, 5 Tier 2) are cumulative
across sessions, not reset per invocation — map prior runs onto the
phases below and continue from there, don't restart at Phase 1.

**Phase 0 — Pre-flight infra research** (conditional, uncapped).
Before Phase 1, check external sources for dispatch-level needs —
sampling params, thinking-mode control, known pathological behaviors —
when the model is new here, or Phase 1's warm-up shows
truncation/empty output/runaway generation. Infra/dispatch only
(sampling, `enable_thinking`, context size), not prompting technique
(that's the Research phase — technique carries real negative-transfer
risk, see Idiom E). Document any applied finding per the dispatch-tweak
rule below. Skip for an already-known model with no new red flags.

**Phase 1 — Reference run.** One baseline `report.sh` run against
current state (or the most recent existing report, if the prior-work
check found one). Anchor for every later "did it improve" comparison.

**Research phase** (always both parts, uncapped, before any steering —
cheap relative to a dispatch run):
1. **Cross-model idiom check** — read every other tested model's
   `history.md`/`README.md` for this same role's diagnosed idioms.
2. **External research** — web search, model card/prompting guide, for
   this exact checkpoint.

Both always run regardless of what the other finds. A sourced fix is a
*hypothesis*, verified in Steering like any other lever — state
helped/neutral/hurt and why (backfire on a different model is a real
finding, see `lfm2.5-1.2b-thinking` Idiom E, STE negative-transferred
from `deepseek-r1-1.5b`). Name any useful helper tooling found (linter,
MCP tool, schema validator) in the report/README even if unimplemented.

**Steering phase — specialist first, then generalist.** Fixes for one
task can conflict with another's needs (a "preserve structure exactly"
fix helped `doc-verbatim`/`doc-repair` but broke `doc-restructure` for
`qwen3.5:0.8b`) — batching hides that conflict. Preference order in
both tiers: cross-model-validated / research-informed fixes first, then
novel task-specific fixes grounded in the exact quoted idiom — never a
blanket rules block prepended to everything (measurably hurt several
`lfm2.5-1.2b-thinking` tasks, Idiom E).

*Tier 1 — per-task specialist.* Independent optimization per failing
task, stored as `models/<model-dir>/task-overrides/<task>.md`. Budget:
≤4 runs/task, tracked separately per task. **Gate on run 2**: after the
first real attempt, keep investing (up to 4) only in tasks showing real
partial improvement; gate out (revert to bare/best-prior) anything flat
or regressed after run 1. A batched first probe across plausibly
similar tasks is fine to conserve budget — split into independent
branches the moment the batch result is mixed.

*Tier 2 gate — automatic, no question asked.* Once Tier 1 settles, run
`bash bench/tier2-gate.sh <report-file>`. Exit 0 (≥60% specialist hit
rate) → run Tier 2. Exit 1 (<60%) → skip straight to Confirm on the
Tier 1 result. Quote the script's output line in the report.

*Tier 2 — generalist search* (≤5 runs, gate must pass). Search for one
shared config for an end user who doesn't know the task shape ahead of
time. **"No generalist exists" is a fully acceptable outcome for a
small local model** — state it plainly rather than shipping a mediocre
compromise. Small models here have repeatedly not generalized a single
config across heterogeneous task shapes within a role (see
`history.md`'s "specialists don't generalize" finding).

**When no generalist config exists, check for a generalist *decision
procedure* before closing Tier 2.** Some failures differ in *kind*, not
detail, so no single prompt closes the gap — e.g. `qwen3.5:9b`'s docs
role needed decoding-level grammar constraints for 3 tasks and a
specific reminder for a 4th; no shared wording worked, because it was
never a phrasing problem (see `models/qwen3.5-9b/history.md`). The
reusable finding there was a rule, not an artifact: **when a failure is
structural/positional and resists prompt-only steering, check whether
the backend supports grammar-constrained decoding before spending more
iteration budget.** See `docs/GRAMMAR-STEERING-PATTERNS.md`. Document
this as a decision procedure in the model's own README/history — not
forced into the per-task table's "Generalist result" column, which is
for literal shared configs only.

Stop either tier early once runs stop improving, or the role fully
passes. **Phase/tier transitions (Research → Steering, Tier 1 → gate →
Confirm, Confirm → Performance → Final report) are autonomous** — state
what finished, its result, and that you're proceeding, then proceed.
Ask only when a finding genuinely changes strategy in a way these rules
don't resolve, not as a routine check-in.

## Confirm — check the optimization is real, not one lucky draw

Once improvement stops, run `bash bench/confirm.sh <model> <role>`
against the current state, unchanged — 3 more back-to-back runs,
writes `confirm-<role>-<timestamp>.md` with a per-task consistency
table and CONFIRMED/FLAKY verdict.

- **CONFIRMED**: this is the loop's result.
- **FLAKY**: revert to the last committed checkpoint before the change
  that introduced flakiness, re-run `confirm.sh` against that instead.
  Never ship a flaky result just because one draw looked good.

## Performance run (max 5 full role re-test runs)

Once Confirm is stable: apply token/latency optimizations that do
**not** reduce confirmed quality (same pass count/verdicts, re-checked
after each change; revert regressions). One candidate: "caveman"-style
output shaping (github.com/juliusbrussee/caveman) — strips filler to
cut *output* tokens. **Caveat:** no effect on input or reasoning-phase
tokens (no help for a thinking model's `<think>` budget); costs
~1-1.5k extra input tokens as its own overhead. Several models here
fail via *under*-elaboration, not verbosity (e.g.
`lfm2.5-1.2b-thinking` Idiom A/E) — only apply where failures are about
padding, not missing content.

## Final report

The model+role's `README.md` per-role section is replaced with the
final report (not a separate doc). Must state, beyond the existing
README-shape requirements:

- **Usability without optimizations** — bare-baseline verdict (Phase 1).
- **Usability with optimizations** — Confirm-settled verdict.
- **Comparison against a mainstream frontier LLM** — e.g. "comparable
  to Claude Haiku 4.1, with restrictions: ..." — state caveats
  explicitly (context size, still-failing task types,
  reliability/latency). Qualitative judgment grounded in the loop's
  actual evidence, reasoning shown, not just asserted.

**Checkpoint: run `bash bench/check-readme-shape.sh <model>`** before
calling the Final report done. Diffs README headings against
`templates/new-model/MODEL-README-SCAFFOLD.md` (exit 0 = all present,
exit 1 lists what's missing). **Why a script, not a read-through:** a
missing "How to optimize" section reads as nothing-wrong on a
read-through — it only shows as a gap in a heading diff. All 4
`qwen3.5-*` READMEs shipped without it despite the rule already
existing as a manual instruction; caught only when the user asked for
a heading diff by hand. Once headings match, confirm content per
section by eye: Overview table row updated (status, pass rate,
comparison, working Details link); role section is current-state, not
a round-by-round retelling (that's `history.md`); "How to optimize"
entries are facts/instructions, not "we tried X and Y happened."

## After a test run, persist it — don't leave findings only in chat

A run isn't done until its result is on disk, not just reported in
conversation:

1. Generate a report (`report.sh` for a role-track run; `bench.sh`
   writes its own per-call).
2. Update `models/<model>/README.md`'s current-state summary.
3. If a new idiom/regression/finding surfaced, add it to
   `models/<model>/history.md` too — README stays current-state-only.

**Why:** `lfm2.5-1.2b-thinking` had a real baseline and steering pass
reported only in conversation, zero persisted — indistinguishable from
never having been tested.

**Rule: a full test run needs ≥1 commit.** Writing the files isn't
enough — an uncommitted file is as invisible to the next `git log`
reader as an unwritten one.

## README shape: current-state only, history deferred

No `README.md` in this project accumulates into a chronological log:

- **Root `README.md`**: project purpose, `bench/`/reports overview,
  pointers. No round-by-round detail.
- **`models/README.md`**: one index — model × role × status, linking
  to each model's own README. Nothing else.
- **`models/<model>/README.md`**: current state only. Starts with an
  **Overview table** — one row per role ever tested: `Role | Status |
  Pass rate (bare → current) | vs. mainstream LLM | Details` (Details
  = link to that role's own heading). Below: per-role status, direct
  "how to optimize" instructions, setup facts. **A role that went
  through Tier 1/2 Steering also needs a per-task table**: `Task |
  Specialist result | Specialist config | Generalist result`
  (Specialist config = link to `task-overrides/<task>.md` or "bare";
  Generalist = Tier 2's result or "no generalist — n/a") — without this
  table, "no generalist found" reads as a bare failure instead of the
  specific per-task picture it actually is. Ends with links to
  `history.md`/`reports/`. Any story-shaped sentence ("first we tried
  X, then Y happened") belongs in `history.md`, not here — **replace**
  the status section's content every run, never append a "here's what
  changed" paragraph.
- **`models/<model>/history.md`**: full narrative — round-by-round
  results, diagnosed idioms, debugging trails. Completeness over
  brevity; this is the fallback once raw per-run evidence ages out.
  Distinct from `reports/` (raw per-run data, doesn't connect across
  runs) — neither replaces the other.

**Why:** this rule existed because one model's README grew to 418
lines, ~80% narrative — and still wasn't self-enforcing; a second
model's README grew back to ~115 lines of narrative the same day
despite the rule already existing, caught only by the user. Full
incident, and the Overview-table/replace-don't-append fix it produced:
`history.md`.

## Every dispatch-level tweak must be documented, not just passed as a flag

Any adjustment outside a task's `SPEC.md` — `dispatch.sh` env var
overrides (`DISPATCH_TEMPERATURE`, `_TOP_P`/`_TOP_K`/`_MIN_P`/
`_PRESENCE_PENALTY`, `_ENABLE_THINKING`, `_NOTHINK`, backend/port), a
systemd service's `-c`/`-ngl`/launch flags, anything passed at the
command line rather than tracked in a file — must be written into
`models/<model>/README.md`'s **Setup** section (exact vars/values)
before a run using it counts as reported. **Why:** unlike a `SPEC.md`
change, a dispatch tweak leaves no trace by default — a future session
re-running the "same" test without knowing the override silently gets
a different, probably worse, result. **How to apply:** add/update the
Setup section alongside the report/history entry that used it — the
literal reproducible values, not "some tuning was needed."

## Don't assume the visual role is wired up

`README.md`'s Roles table lists **visual** as scaffold-only:
`models/lfm2.5-vl-450m/README.md` has a plan, but no GGUF downloaded,
no systemd service, no `tasks/visual-*`, not in `dispatch.sh`'s
`ALLOWED_MODELS`. Read that README's "what still needs to happen"
first — a `models/lfm2.5-vl-450m/` directory existing is not evidence
the role is usable.

## Unattended operation is authorized in this repo

`.claude/settings.json` blanket-allows `Bash`, `Edit`, `Write`
(2026-08-02) so an agent can dispatch/diagnose/steer/report/commit/push
without stopping at each step (compound commands like a `for` loop
don't match narrow per-command prefixes, which is why this was widened
from a prefix allowlist). **Not** a license to skip judgment on
genuinely risky ops: force-push, `git reset --hard`, branch deletion,
`--no-verify`/`--no-gpg-sign` are explicit denies regardless, and
anything destructive outside this repo's own tree still needs raising.

**Git push is scoped to this repo only, enforced by GitHub, not just
convention.** `origin` uses a dedicated deploy key
(`~/.ssh/id_ed25519_testlocalai`, this repo's GitHub deploy keys only,
not the account-wide key), routed via SSH host alias
`github-testlocalai` with `IdentitiesOnly yes`. Verified empirically:
the same key tried against a different repo (`connectwise-mcp`) was
rejected ("Repository not found" — deploy keys are invisible to repos
they aren't attached to). An unattended loop here cannot push
elsewhere even by mistake.

**Service restarts/reloads are authorized for a quality-loop lever.**
Some levers are server-startup flags, not per-request dispatch (e.g.
llama-server's `--reasoning-budget N` is set via the systemd service's
`ExecStart`). Testing values means editing the service file +
`systemctl --user daemon-reload && restart` between attempts —
explicitly authorized, not something to ask about each time (a restart
costs seconds; not testing a real lever can cost minutes — one
runaway-thinking task measured 211s). Document per the dispatch-tweak
rule above; restore the previous value if the tested one isn't kept.

**Mandatory: restart the target LLM service and log free VRAM/RAM
before every `bench/report.sh` run.** Discovered on `qwen3.5:9b`: a
~2.5h session with no restart drove generation from 9.46 tok/s to 0.73
tok/s (RAM exhausted, swap full) — not visible in any earlier short
run. `report.sh` now does this automatically for the `llamacpp`
backend (restarts the matching unit, waits for `/health`, logs
pre-run free VRAM/RAM into the report header) — a report is
self-documenting about the memory conditions it ran under, and a
degraded session never silently passes as clean. Test-measurement
hygiene, not a production-serving recommendation — deliberately not
representative of sustained real-world load (the condition that
surfaced this). Doesn't apply to ad-hoc `dispatch.sh`/`pure-run.sh`
calls during rapid iteration; if a steering session runs long without
going through `report.sh`, check VRAM/RAM manually
(`nvidia-smi --query-gpu=memory.free --format=csv`, `free -h`) and
restart if either looks tight.

## See also

- [`README.md`](README.md) — project purpose, layout, best-first
  presentation rule, how to add a new model or a new source project.
- `history.md` — project-level narrative (origin, cross-model
  findings, retired conventions).
- `models/<model>/README.md` — per-model verdicts and bench-plan history.
- `models/<model>/rules/` — per-model steering blocks (what actually
  helps *that* model succeed — never assumed to transfer to another).
