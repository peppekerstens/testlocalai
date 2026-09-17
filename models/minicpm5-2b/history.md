# minicpm5-2b — history

Full narrative of the tests of `minicpm5:2b`. `README.md` has the current
state only. `reports/` has the raw per-run data.

Purpose of the first tests: find out if `minicpm5:2b` can replace
`qwen3.5:9b` as the chat backend of `legion-t5` for `litellm-router`.

## 2026-09-12 — Phase 1 baseline, 5 roles

Commit `9db673f`. Temporary `llama-server` on `legion-t5`, port 11434,
reached with `ssh -L 8080:localhost:11434 192.168.2.133`. `qwen3.5`'s chat
service was stopped for the run. `--ctx-size 32768`, `--flash-attn on`,
`--jinja`. `dispatch.sh` got a permanent `ALLOWED_MODELS` entry for
`"minicpm5:2b"`. Code-emitter was not attempted (no build and test
harness for this pass). Visual has no tasks.

Bare, single draw, `temperature` 0.2: **22/36**.

| Role | Bare | Report |
|---|---|---|
| Documenter | 6/9 | `reports/report-docs-20260912-083329.md` |
| Reasoner | 3/9 | `reports/report-reason-20260912-083813.md` |
| Tool-use | 6/6 | `reports/report-tool-20260912-084137.md` |
| Extract | 3/6 | `reports/report-extract-20260912-084211.md` |
| Review | 4/6 | `reports/report-review-20260912-084236.md` |

Idioms found in this run:

- **Default thinking mode consumes the completion budget.** On 4 of 36
  tasks (`doc-script`, `doc-repair`, `reason-coverage`, `review-clean`),
  the reasoning phase used all 16384 completion tokens before any visible
  answer. With `DISPATCH_ENABLE_THINKING=false`, `reason-coverage` and
  `review-clean` passed. `doc-script` and `doc-repair` stopped
  truncating but still failed on real content defects (wrong tokens, a
  missing YAML fence).
- **Meta-commentary in a verbatim task** (`doc-verbatim`): the model added
  `Line 16 is exactly this note line:` before the text it had to copy
  byte for byte.
- **Right shape, missing one specific detail** (`reason-checklist`,
  `reason-trace`, `reason-consequence`, `reason-multihop`,
  `review-concurrency`): the structure was correct, but `verify.sh` did
  not find a required term. `review-concurrency` did not name
  `Dictionary` as the unsafe type.
- **Wrong answer** (`reason-compare`): the model picked the wrong
  candidate (`'B only'`).
- **Trailing period on extracted strings** (`extract-basic`,
  `extract-nested`): the model added a period that the source text does
  not have.
- **Dropped field** (`extract-optional`): a required JSON field was
  missing.

## 2026-09-12 — steering pass, 5 roles

Commit `68b8a61`. One `task-overrides/<task>.md` reminder per failing
task that thinking-off did not fix, 10 overrides in total. 3 draws each,
`temperature` 0.2.

- **Fixed (6)**: `reason-checklist` 2/3, `reason-multihop` 3/3,
  `extract-basic` 2/3, `extract-nested` 2/3, `extract-optional` 2/3,
  `review-concurrency` 2/3.
- **Not fixed (4)**: `doc-verbatim` 0/3, `reason-trace` 0/3,
  `reason-consequence` 1/3, `reason-compare` 0/3.
- **Blanket thinking off is not a win.** With thinking off for every
  task, docs dropped to 4/9 and review to 2/6. Extract rose to 5/6.
  Thinking helps this model on some tasks and hurts it on others.

The commit message gave a total of 22/36 bare to 30/36 steered.

## 2026-09-12 — re-run at `--ctx-size 131072`

Commit `588985f`. The first try used 262144. That is above the
`n_ctx_train` of 131072 and did not fit in VRAM. The re-run used
`--ctx-size 131072 --no-kv-offload --cache-type-k q8_0 --cache-type-v
q8_0 -ngl 99`, the same context as `qwen3.5:9b` in production.

- All 5 roles re-ran with the overrides in place: **28/36** (docs 5/9,
  reason 7/9, tool 6/6, extract 5/6, review 5/6). The change from 22/36
  is draw-to-draw variance at `temperature` 0.2. The largest prompt was
  below 1,100 tokens, so the context size did not bind in either run.
- The 6 fixed overrides held. `reason-checklist` dropped to 1/3 in this
  draw.
- **Reminder plus thinking off** on the 4 unresolved tasks
  (`doc-verbatim`, `reason-trace`, `reason-consequence`,
  `reason-compare`): **0/12**. Thinking off ran faster (95 to 98 tok/s
  against 30 to 70 tok/s) but did not fix the content.
- Every report since then has a Hardware line and a tok/s column.

## 2026-09-16 — expanded suite, 10 tasks per role, 6 roles

Commit `e177461`. The suite grew to 10 tasks per role on 2026-09-15.
Code-emitter ran for the first time. Same transport as 2026-09-12 (port
11434, `qwen3.5-4b-gsq` stopped). The report headers of this run say
"local (this machine)", because `DISPATCH_HW_LABEL` was not set. The
real host was `legion-t5`.

**The "bare" run was not fully bare.** `bench/pure-run.sh` uses
`task-overrides/<task>.md` when that file exists. The 10 overrides from
2026-09-12 were in place, so 10 tasks ran with steering. This was not
noticed on 2026-09-16.

Thinking on (default), single draw: **45/64**.

| Role | "Bare" | Thinking off, all tasks |
|---|---|---|
| Documenter | 5/10 | 4/10 |
| Reasoner | 4/10 | 3/10 |
| Tool-use | 9/10 | 8/10 |
| Extract | 9/10 | 9/10 (`extract-basic` fixed, `extract-optional` broke) |
| Review | 7/10 | 4/10 |
| Code-emitter | 11/14 | 8/14 |

- **Blanket thinking off is worse in every role.** Many thinking-off
  answers were near-empty (12, 33, 56, 66 tokens).
- **Per-task thinking off** on the 7 truncated tasks: `extract-basic` and
  `review-clean` passed. `doc-verbatim`, `doc-repair`, `review-async` and
  `review-swallow` stopped truncating but failed on content (the review
  answers were 12 tokens). `reason-coverage` still truncated at 16384.
- The 2026-09-16 README called the reasoner result a "real regression"
  from 7/9 to 4/10 (`reason-trace`, `reason-consequence`,
  `reason-coverage`). **This claim is weak.** The 7/9 was one draw at
  131072 ctx. Both runs used the same 2026-09-12 overrides for
  `reason-trace` and `reason-consequence`. Those overrides gave only 0/3
  and 1/3 in the 2026-09-12 3-draw check. `reason-coverage` had no
  override in either run.
- Findings of the 12 reports stayed templated in commit `e177461`. Commit
  `b8ef1b3` filled them on 2026-09-17. For 42 of 51 bullets, the raw
  output no longer existed, and the bullets say so.

## 2026-09-17 — bare re-run, side by side with qwen3.5

Commit `b8ef1b3`. This time `qwen3.5-4b-gsq` kept serving
`litellm-router`, with a temporary drop-in for `--parallel 1 --ctx-size
122880`. `minicpm5:2b` ran as a temporary unit `llama-minicpm5-test` on
port 11437, `--ctx-size 32768 --parallel 1`. The SSH tunnel went to local
port 18437. `README.md` Setup has the exact commands.

Result: **45/64**, the same total as 2026-09-16. The same 10 overrides
from 2026-09-12 were in place.

| Role | 2026-09-16 | 2026-09-17 | Changed verdicts |
|---|---|---|---|
| Documenter | 5/10 | 5/10 | `doc-synthesize` FAIL → PASS, `doc-audience` PASS → FAIL (truncated) |
| Reasoner | 4/10 | 5/10 | `reason-config-validity` FAIL → PASS |
| Tool-use | 9/10 | 9/10 | none |
| Extract | 9/10 | 8/10 | `extract-optional` PASS → FAIL (truncated) |
| Review | 7/10 | 7/10 | `review-clean` FAIL → PASS, `review-multi` PASS → FAIL |
| Code-emitter | 11/14 | 11/14 | none |

6 tasks changed verdict with no change in steering. Reports:
`reports/report-<role>-20260917-0757..0814*.md`. Raw outputs of the 50
non-code tasks: `raw/20260917-bare/`.

Speed was about 187 tok/s on the shared GPU. VRAM use was 7,701 of 8,192
MiB, with no out-of-memory error.

## 2026-09-17 — steering pass, `bench/loop.sh` per role

One `loop.sh` run per role, in this order: tool, extract, review, code,
reason, docs. Each run: resume from the bare report, cross-model Research
phase (`research-<role>.md`), Tier 1 with at most 4 rounds and the gate on
run 2, Tier 2 gate, Confirm with 3 draws. No external research and no
Tier 2 search ran.

The loop authors an override only for a failing task that has no
override file yet. Tasks with a 2026-09-12 override kept that override
unchanged, unless the gate removed it.

### Tool-use

- Round 1 (`report-tool-20260917-082205.md`): new override
  `tool-error.md` for a "question echo" idiom. The model copied the two
  question lines back and gave no answer. 10/10.
- Round 2: no failing task left. Tier 2 gate: GO (10/10).
- Confirm: 10, 10, 10. **CONFIRMED.**

### Extract

- Round 1 (`082934`): 8/10. No new override (`extract-basic` and
  `extract-optional` already had 2026-09-12 overrides).
- Round 2 (`083051`): 7/10. `extract-basic` passed, `extract-nested` and
  `extract-invalid` failed. 3 tasks flipped in about one minute, with no
  change. Gate: `extract-optional` gated out, its 2026-09-12 override
  deleted.
- Round 3 (`083250`): 9/10. New override `extract-invalid.md` for a
  trailing period in a verbatim summary. `extract-optional` returned only
  `{"id": 7788}`.
- Idiom candidate: the model avoids explicit `null`. It writes a
  placeholder (`"Unknown"`), omits keys, or describes the missing fields
  in `summary`.
- Tier 2 gate: GO (9/10). Confirm: 9, 10, 9. **FLAKY** (`extract-optional`).

### Review

- Round 1 (`084005`): 7/10. New overrides `review-async.md`,
  `review-swallow.md`, `review-multi.md`.
- Round 2 (`084703`): 5/10. New override `review-dispose.md`. Gate:
  `review-swallow` and `review-multi` gated out and deleted.
- Round 3 (`085946`): 4/10. New override `review-decoy.md` for a false
  positive on a decoy.
- Round 4 (`090916`): 6/10. New override `review-clean.md` for a false
  positive on a clean method (an invented null argument).
- `review-swallow` truncated at 16384 in rounds 2 to 4 and in every
  Confirm draw.
- Tier 2 gate: GO (6/10). Confirm: 7, 8, 6. **FLAKY**
  (`review-concurrency`, `review-decoy`, `review-dispose`).

### Code-emitter

- Round 1 (`094144`): 10/14. New `rules/csharp-rules.md` with 2 rules for
  the compiler errors of the failing tasks.
- Round 2 (`095403`): 10/14. `csharp-rules.md` refined, new
  `rules/python-rules.md` for `code-python-auth`. Gate: both rules files
  gated out and deleted. `.gated-code` lists all 14 tasks.
- Round 3: no active failing task left. Tier 2 gate: GO (10/14).
- Confirm on the fully bare config: 11, 9, 10. **FLAKY**
  (`code-csharp-httpclient`, `code-csharp-tool`). This is the clearest
  proof of draw-to-draw variance in this pass, because no steering was
  active.

### Reasoner

- Round 1 (`101949`): 6/10. New override `reason-coverage.md`. The model
  had copied the abstract category descriptions instead of field names.
  `reason-coverage` passed and did not truncate again in any later draw.
- Round 2 (`102653`): 7/10. New override `reason-config-validity.md`.
  Gate: `reason-trace` gated out, its 2026-09-12 override deleted.
- Round 3 (`103445`): 7/10. Round 4 (`103904`): 6/10. No new overrides.
- Idiom candidates from round 4: the final pick contradicts the model's
  own per-candidate verdicts (`reason-compare`). The final answer repeats
  the doc wording and does not state the concrete outcome
  (`reason-consequence`). A nested value is checked against the
  top-level table row, not the sub-schema (`reason-config-validity`).
- Tier 2 gate: GO (6/10). Confirm: 6, 6, 5. **FLAKY**
  (`reason-config-validity`, `reason-consequence`, `reason-multihop`).

### Documenter

**Incident: the first docs run resumed from the wrong report.**
`loop.sh` picks the newest report of a role by file mtime. A subagent
edited the 2026-09-16 reports at 10:04 to fill in their Findings. The
2026-09-17 docs report had an mtime of 10:03. So `loop.sh` (log
`bench/logs/loop.sh-20260917-105244-636499.log`) resumed from
`report-docs-20260916-191428.md`, the thinking-off run, and started
round 1 on the wrong failing set. The run was stopped in round 1. Its 5
uncommitted overrides were deleted. Commit `0866dea` (Research phase) was
kept, because the cross-model research does not depend on the report.
The restart (log `loop.sh-20260917-110638-644651.log`) resumed from
`report-docs-20260917-075730.md`. Finding: the mtime-based choice is
fragile. Any later edit of an older report can change which report
`loop.sh` resumes from.

- Round 1 (`111003`): 7/10. New overrides `doc-adapt.md` (the model
  deleted the rest of a line after a mid-line replace), `doc-script.md`
  (a half-done edit), `doc-repair.md`, `doc-audience.md`.
- Round 2 (`111327`): 5/10. Gate: `doc-repair` and `doc-audience` gated
  out and deleted.
- Round 3 (`112034`): 6/10. New overrides `doc-surgical.md` (old
  backticks kept around a replaced span) and `doc-restructure.md`.
- Round 4 (`112724`): 5/10. All 5 failing tasks truncated at 16384 with
  empty visible output. Idiom candidate: "empty content at the
  completion cap".
- Tier 2 gate: SKIP (5/10). Confirm: 7, 6, 6. **FLAKY**
  (`doc-restructure`, `doc-surgical`).

## 2026-09-17 — Confirm summary and decision

| Role | Confirm draws | Verdict | Always pass | Always fail |
|---|---|---|---|---|
| Tool-use | 10, 10, 10 | CONFIRMED | 10 | none |
| Extract | 9, 10, 9 | FLAKY | 9 | none |
| Review | 7, 8, 6 | FLAKY | 5 | `review-swallow`, `review-multi` |
| Code-emitter | 11, 9, 10 | FLAKY | 9 | `code-csharp-batch`, `code-csharp-events`, `code-csharp-workflow` |
| Reasoner | 6, 6, 5 | FLAKY | 4 | `reason-checklist`, `reason-compare`, `reason-trace` |
| Documenter | 7, 6, 6 | FLAKY | 5 | `doc-verbatim`, `doc-repair`, `doc-audience` |

AGENTS.md says to revert a FLAKY result to the last checkpoint and run
Confirm again. **The user decided not to do that.** The decision: report
the 5 FLAKY roles as measured, as "no confirmed steering gain", with no
revert rounds. The reason: this model changes 2 to 3 verdicts per role
between draws, also without steering. That variance is larger than the
steering effect. Only tool-use has a confirmed gain.

Per task, some overrides look useful but are not confirmed at role level.
`doc-adapt`, `doc-script` and `reason-coverage` failed bare and passed
every draw after their override (4 rounds plus 3 Confirm draws).
`review-async` did the same, except for one FAIL in round 2.

Not done after this pass: the Tier 2 generalist search (gate GO for
extract, review, code-emitter and reasoner), the Performance run, and a
Hindsight retain of the per-task outcomes.

After the run, the host went back to production: `qwen3.5-4b-gsq` back to
`--parallel 2 --ctx-size 245760`, temporary unit and drop-in removed,
tunnel closed.
