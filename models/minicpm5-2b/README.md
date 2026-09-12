# minicpm5-2b — steering profile

**Not tested via this repo's usual local-only path.** This model runs on
`legion-t5` (`192.168.2.133`), a separate host on the LAN, not on this
machine. Reached it the same way `qwen3.8-27b` did (see that model's
README): `bench/dispatch.sh` and `bench/report.sh` ran unmodified, over an
SSH local port-forward (`ssh -L 8080:localhost:11434 192.168.2.133`) to a
temporary `llama-server` instance serving `minicpm5:2b`, added to
`dispatch.sh`'s `ALLOWED_MODELS` for this pass. Real `SPEC.md`/`verify.sh`
per task, same as every other model in this repo — only the transport
differs.

**Phase 1 baseline, all five established task roles** (bare, single draw,
default sampling, no steering) — requested explicitly as "do all tests,"
wider than the usual docs+reason default. Code-emitter not attempted
(needs the build+test harness, out of scope for this pass, same reasoning
as `qwen3.8-27b`'s README). Visual has no tasks yet (scaffold only).

**Purpose of this pass**: a real, evidence-based comparison against
`qwen3.5:9b`, to help decide whether `minicpm5:2b` could replace it as
`legion-t5`'s chat backend for `litellm-router`.

## Overview

| Role | Status | Pass rate (bare) | With thinking disabled (partial re-test) | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed | 6/9 | 6/9 (2 truncated tasks re-tested, both still fail, now on real content grounds) | [Documenter](#documenter-role) |
| Reasoner | ⚠️ Mixed | 3/9 | 1 task re-tested, flips to PASS | [Reasoner](#reasoner-role) |
| Tool-use | ✅ Strong bare baseline | 6/6 | not re-tested (no truncation) | [Tool-use](#tool-use-role) |
| Extract | ⚠️ Mixed | 3/6 | not re-tested (no truncation) | [Extract](#extract-role) |
| Review | ⚠️ Mixed | 4/6 | 1 task re-tested, flips to PASS | [Review](#review-role) |
| **Total** | | **22/36 (61%)** | **24/36 on the 4 tasks re-tested (67%)** | |

**Single draw throughout (n=1) — not a reliability sample.** Every rate
above could look different on a second draw. The "with thinking disabled"
column is real, verified data for the 4 specific tasks that truncated
under bare defaults — it is not a full second suite run, so it does not
mean the other 32 tasks would score the same with thinking off.

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
