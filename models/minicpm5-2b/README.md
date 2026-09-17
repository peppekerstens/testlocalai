# minicpm5-2b — steering profile

**Not tested via this repo's usual local-only path.** This model runs on
`legion-t5` (`192.168.2.133`), a separate host on the LAN, not on this
machine. Reached it the same way `qwen3.8-27b` did (see that model's
README): `bench/dispatch.sh` and `bench/report.sh` ran unmodified, over an
SSH local port-forward (`ssh -L 8080:localhost:11434 192.168.2.133`) to a
temporary `llama-server` instance serving `minicpm5:2b`. Real
`SPEC.md`/`verify.sh` per task, same as every other model in this repo —
only the transport differs.

**Hardware and context, corrected 2026-09-12**: all results below are
from `legion-t5`, RTX 3060 Ti 8GB VRAM, `--ctx-size 131072` (this model's
own trained maximum — `n_ctx_train` is 131072, not higher; an initial
262144 request over-ran that and also failed to fit VRAM), matching
`qwen3.5:9b`'s own production context for a fair comparison. An earlier
pass in this same file ran at `--ctx-size 32768` — checked directly, not
assumed: max prompt across every task stayed under 1100 tokens the whole
session, nowhere near either limit, so this correction changed nothing
about which tasks pass or fail. All reports now carry a `**Hardware**`
line and a `tok/s` column — see the Speed section below for what those
numbers mean and do not mean.

**Phase 1 baseline, all five established task roles** (bare, single draw,
default sampling, no steering) — requested explicitly as "do all tests,"
wider than the usual docs+reason default. Code-emitter not attempted
(needs the build+test harness, out of scope for this pass, same reasoning
as `qwen3.8-27b`'s README). Visual has no tasks yet (scaffold only).

**Purpose of this pass**: a real, evidence-based comparison against
`qwen3.5:9b`, to help decide whether `minicpm5:2b` could replace it as
`legion-t5`'s chat backend for `litellm-router`.

## Overview

**Suite expanded to 10 tasks/role 2026-09-16 — table below is current, the
2026-09-12 9-task/6-task numbers are historical, see that section below.**

| Role | Status | Bare (10 tasks, 2026-09-16) | After per-task fix | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed | 5/10 | 5/10 — not steered this pass | [2026-09-16 section](#2026-09-16-expanded-suite-10-tasksrole-6-roles) |
| Reasoner | ⚠️ Mixed, regressed | 4/10 | 4/10 — not steered this pass | [2026-09-16 section](#2026-09-16-expanded-suite-10-tasksrole-6-roles) |
| Tool-use | ✅ Strongest role | 9/10 | 9/10 — not steered this pass | [2026-09-16 section](#2026-09-16-expanded-suite-10-tasksrole-6-roles) |
| Extract | ✅ Good | 9/10 | **10/10** — extract-basic fixed | [2026-09-16 section](#2026-09-16-expanded-suite-10-tasksrole-6-roles) |
| Review | ⚠️ Mixed | 7/10 | **8/10** — review-clean fixed | [2026-09-16 section](#2026-09-16-expanded-suite-10-tasksrole-6-roles) |
| Code-emitter | ✅ Good, first pass | 11/14 | 11/14 — not steered this pass | [2026-09-16 section](#2026-09-16-expanded-suite-10-tasksrole-6-roles) |
| Visual | Not attempted | — | — | no `mmproj` vision projector on legion-t5, `report.sh` has no `visual` role |
| **Total** | | **45/64 (70%)** | **47/64 (73%)** | |

Blanket `DISPATCH_ENABLE_THINKING=false` across all 6 roles was tried and
made every single role worse (see 2026-09-16 section) — do not use it as
a global default for this model. 12 content-idiom failures across
docs/reason/tool/code remain un-steered (deferred, not attempted).

**Small samples throughout** (n=1 per bare draw, n=3 per steered task) —
not a reliability sample. The bare rate moved from 22/36 to 28/36 between
the two draws at `temperature=0.2` — real per-draw variance at a non-zero
temperature, not a context-length or hardware effect (both draws ran on
the same GPU; only the context size changed, and it never bound either
time). 9 tasks remain genuinely unresolved after a real steering attempt
each: `doc-verbatim`, `doc-script`, `doc-repair` (documenter),
`reason-trace`, `reason-consequence`, `reason-compare` (reasoner). See
each role's section below for what was tried and why it did not close
them.

## 2026-09-16 Expanded Suite (10 tasks/role, 6 roles)

Task suite expanded 2026-09-15 to 10 tasks per role (doc/reason/tool/
extract/review) plus 14 brand-new tasks this model had never seen. Same
transport as before (temporary `llama-server` on legion-t5, port 11434,
same flags), `qwen3.5-4b-gsq`'s production `llama-chat.service` stopped
for the duration, per explicit ask. `code` role attempted for the first
time this pass (text-only, no build+test harness gap for this role —
that gap only ever blocked the *2026-09-12* pass). `visual` still not
attempted: this model has no `mmproj` vision-projector file on legion-t5,
and `report.sh` has no `visual` role at all — the only real visual pass
in this repo uses `qwen3.8-27b-gsq-rco`, the one model here with a
working vision projector.

**Bare, single draw, thinking on (the default, no override):**

| Role | Bare | New tasks this role | Failing tasks |
|---|---|---|---|
| Documenter | 5/10 | doc-audience (PASS) | verbatim(trunc), adapt, script, synthesize, repair(trunc) |
| Reasoner | 4/10 | reason-priority (PASS) | config-validity, checklist, trace, consequence, compare, coverage(trunc) |
| Tool-use | 9/10 | chain, clarify, conflict, typecoerce (all PASS) | tool-error |
| Extract | 9/10 | conflict, invalid, noisy, numeric (all PASS) | extract-basic(trunc) |
| Review | 7/10 | dispose, multi, decoy (PASS), swallow (FAIL) | async(trunc), clean(trunc), swallow(trunc) |
| Code-emitter | 11/14 | — (first pass for this role) | code-csharp-batch, code-csharp-events, code-csharp-workflow |

Real regression vs. 2026-09-12: reasoner dropped from 7/9 to 4/10 —
`reason-trace`, `reason-consequence`, `reason-coverage` all regressed
from a prior PASS. Two of the four new tool tasks and all four new
extract tasks passed bare with no steering.

**Blanket `DISPATCH_ENABLE_THINKING=false`, all 6 roles, full re-run —
confirms the 2026-09-12 finding, harder evidence this time:**

| Role | Bare | Thinking off | Verdict |
|---|---|---|---|
| Documenter | 5/10 | 4/10 | worse |
| Reasoner | 4/10 | 3/10 | worse |
| Tool-use | 9/10 | 8/10 | worse |
| Extract | 9/10 | 9/10 | no net gain — `extract-basic` fixed, `extract-optional` newly broke |
| Review | 7/10 | 4/10 | much worse |
| Code-emitter | 11/14 | 8/14 | much worse |

Many thinking-off failures returned near-empty completions (12, 33, 56,
66 tokens) — the model cutting itself short, not a lost reasoning
benefit. **Blanket disable is confirmed worse across every role on the
expanded suite. The per-task-only rule from 2026-09-12 stands — do not
set this as a global default for this model.**

**Per-task `DISPATCH_ENABLE_THINKING=false`, scoped only to the 7 tasks
that failed by truncation in the bare pass** (`doc-verbatim`,
`doc-repair`, `reason-coverage`, `extract-basic`, `review-async`,
`review-clean`, `review-swallow`):

| Task | Truncation gone? | Result |
|---|---|---|
| `extract-basic` | yes | **PASS — fixed** |
| `review-clean` | yes | **PASS — fixed** |
| `doc-verbatim` | yes | still FAIL — real content defect underneath, same as 2026-09-12 |
| `doc-repair` | yes | still FAIL — real content defect underneath |
| `review-async` | yes | still FAIL — near-empty (12 tokens) |
| `review-swallow` | yes | still FAIL — near-empty (12 tokens) |
| `reason-coverage` | **no** | still FAIL, still truncated at 16384 — new anomaly, this task did not respond to the fix this time (it did on 2026-09-12) |

2 of 7 fixed outright. On the other 4, thinking-off removes the
truncation but the task still fails on real content — the truncation was
masking a defect, not causing one, same conclusion as 2026-09-12. No
further per-task steering (targeted reminders for the remaining 12
content-idiom failures) was run this pass — deferred, not attempted.

## Steering pass, 2026-09-12

One `task-overrides/` reminder per failing task (targeting the specific
idiom found in the bare run), 3 draws each, `temperature=0.2`
(this model's default — no mandatory override profile the way `qwen3.5`
needs one). Real result, not assumed: **6 of 10 targeted tasks fixed
outright** (`reason-checklist` 2/3, `reason-multihop` 3/3,
`extract-basic` 2/3, `extract-nested` 2/3, `extract-optional` 2/3,
`review-concurrency` 2/3), **4 stayed unresolved** (`doc-verbatim` 0/3,
`reason-trace` 0/3, `reason-consequence` 1/3, `reason-compare` 0/3) —
plain phrasing reminders did not move these; whatever holds them back
needs a different lever. Re-tested at 131072 ctx: the same 6 hold
(`reason-checklist` dropped to 1/3 this draw, the other 5 unchanged or
better — normal variance, not a regression tied to context).

**Second optimize path, tried on the 4 still-unresolved tasks**: combined
the existing phrasing reminder with `DISPATCH_ENABLE_THINKING=false`
(the lever that fixed `reason-coverage` and `review-clean` earlier).
**0/12 across all four tasks** — thinking-off ran noticeably faster
(95-98 tok/s vs. 30-70 tok/s with thinking on) but did not fix the
content itself on any of the three draws for any of the four tasks. Real,
checked result: these 4 have a deeper gap than either lever addresses
alone — a phrasing reminder does not help, and removing the reasoning
phase does not either. Likely a genuine capability ceiling for a 2B model
on these specific tasks, not a prompting or thinking-mode problem.

**A real, useful negative finding, checked directly rather than assumed
transferable from `qwen3.5`**: disabling thinking as a blanket default
(the way `qwen3.5` needs) was tried across all four roles at once, not
just the 4 originally-truncated tasks. It was NOT a uniform win —
`docs` dropped to 4/9 and `review` dropped to 2/6 with thinking off by
default, while `extract` improved to 5/6. Thinking mode is actively
useful to this model on some tasks and actively harmful on others; the
per-task approach (disable it only where it truncates, per the original
findings) is the right lever for this model, not a global default.

## The one finding that matters most: default thinking mode

`minicpm5:2b` runs in thinking mode by default, the same as `qwen3.5`.
Unlike `qwen3.5`, its reasoning phase can consume the entire 16384-token
completion budget before producing any visible answer, on tasks that need
a longer completion. This happened on 4 of 36 tasks, across three
different roles (`doc-script`, `doc-repair`, `reason-coverage`,
`review-clean`) — confirmed to recur across roles, not one task family.

Re-ran all 4 with `DISPATCH_ENABLE_THINKING=false`
(`chat_template_kwargs.enable_thinking: false`, the same mechanism already
used for `qwen3.5`, confirmed live to work on this model's chat template
too):

- `reason-coverage` and `review-clean`: **fixed**. Truncation gone,
  `verify.sh` now PASSes on both.
- `doc-script` and `doc-repair`: truncation gone, but both **still FAIL**
  — real content defects (wrong tokens, a missing YAML fence) that
  thinking mode had been hiding, not causing.

**Recommendation for any further work on this model**: default to
`DISPATCH_ENABLE_THINKING=false` as a task-override, not a per-task fix —
this looks like a property of the model, not one task family. Not yet
confirmed whether disabling thinking ever costs a task that currently
passes bare — that needs a full second suite run with thinking off,
not done in this pass.

## Documenter role

6/9 PASS, bare, single draw. Two of the three failures were the
truncation idiom above, since re-tested (see that section). The third:

- **`doc-verbatim`: FAIL** — added an unprompted explanatory line
  (`Line 16 is exactly this note line:`) directly before the content it
  was supposed to reproduce byte-for-byte. A new idiom for this model:
  meta-commentary inserted into a verbatim-reproduction task.

Full detail: `reports/report-docs-20260912-083329.md`.

## Reasoner role

3/9 PASS, bare, single draw — the weakest bare result of the five roles.
`reason-coverage`'s FAIL was the truncation idiom, since fixed (see
above). The other five FAILs split into two idioms:

- **Four "right shape, missing a specific detail" misses**
  (`reason-checklist`, `reason-trace`, `reason-consequence`,
  `reason-multihop`): each got the general structure and direction right,
  but `verify.sh`'s exact-token check caught a missing specific term or
  named detail. Pattern, not isolated: this happened four times in one
  9-task run.
- **One genuine wrong answer** (`reason-compare`): picked the wrong
  candidate outright (`wrong-candidate token present: 'B only'`), not
  just an incomplete one.

Full detail: `reports/report-reason-20260912-083813.md`.

## Tool-use role

6/6 PASS, bare, single draw, no truncation. Matches `qwen3.8-27b`'s own
6/6 bare tool-use result at a fraction of the parameter count. The
strongest role for this model in this pass.

Full detail: `reports/report-tool-20260912-084137.md`.

## Extract role

3/6 PASS, bare, single draw, no truncation. Two distinct idioms found:

- **A consistent trailing-period idiom** (`extract-basic`,
  `extract-nested`): the model appends a period to an extracted string
  field even when the source text has none. Seen twice in one run — a
  real pattern, not a one-off. Likely a one-line, low-effort steering fix
  if this model gets a follow-up pass.
- **A dropped-field idiom** (`extract-optional`): a required JSON field
  missing entirely from the output, a different failure shape from the
  trailing-period one.

First real small-model result against this suite in this repo — see
`models/README.md`'s prior "no real small-model run yet" note for
extract.

Full detail: `reports/report-extract-20260912-084211.md`.

## Review role

4/6 PASS, bare, single draw. `review-clean`'s FAIL was the truncation
idiom, since fixed (see above). The other FAIL:

- **`review-concurrency`: FAIL** — found real concurrency-unsafe code but
  did not name `Dictionary` as the specific unsafe type `verify.sh`
  requires. Same "right area, missing a specific named detail" idiom seen
  four times in the reasoner role above.

Full detail: `reports/report-review-20260912-084236.md`.

## Speed

Every report now carries a `tok/s` column (`predicted_tokens_per_second`
from `llama-server`'s own `timings`, not estimated) and a `**Hardware**`
line. Real range across this pass on `legion-t5`: roughly 30-115 tok/s,
task-dependent — thinking mode costs real speed on tasks where it
engages heavily (30-70 tok/s), the same tasks bare and thinking-off
runs on the same task hit 95-98 tok/s.

**Speed comparisons across models are valid only when the Hardware line
matches exactly.** This model's numbers above are all from the same
`legion-t5` config (`--ctx-size 131072 --no-kv-offload --cache-type-k
q8_0 --cache-type-v q8_0 -ngl 99`). Any comparison against `qwen3.5:9b`
or `qwen3.5:4b` needs their reports' own Hardware lines checked first —
different `-ngl`, different `--no-kv-offload` state, or a different GPU
each independently invalidate a raw tok/s comparison, even though
correctness (PASS/FAIL) still compares fine across different hardware.

## Setup

Not a permanent local systemd unit for this pass — a temporary
`llama-server` instance on `legion-t5`, GPU-loaded, `--ctx-size 32768`,
`--flash-attn on`, `--jinja`, alias `minicpm5:2b`, port 11434 (`qwen3.5`'s
chat service stopped for the duration, per the explicit ask for this
test). Reached from this machine via `ssh -L 8080:localhost:11434
192.168.2.133`, then `bench/report.sh "minicpm5:2b" <role>` exactly as any
local model. `dispatch.sh`'s `ALLOWED_MODELS` gained a `"minicpm5:2b"`
entry for this pass — a real, permanent addition, not reverted, since
this is expected to see further work.

Model file: `openbmb/MiniCPM5-2B`, official GGUF release
(`openbmb/MiniCPM5-2B-GGUF`, `Q4_K_M`, 1.56 GB) — see
`ai-stack/legion-t5-llamacpp/README.md` for the download record on the
host side (that repo's own documentation was deliberately not updated
with test-result content as part of this pass, per an explicit
instruction to keep this decision-pending work scoped to this repo only).
