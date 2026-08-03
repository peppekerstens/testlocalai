# qwen3.5:4b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of
[`qwen3.5-2b`](../qwen3.5-2b/)/[`qwen3.5-0.8b`](../qwen3.5-0.8b/) in the
same model family — a separate model directory, steering not assumed
to transfer untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed — quality loop closed 2026-08-03, 4 reliable task shapes (up from 3, best among the smaller siblings — still behind `qwen3.5-9b`'s cleaner 8/9), 4 genuinely unstable (coin-flip reliability), 1 unsuitable | 5/9 bare-on-paper (44% empty output) → 4/9 stable, ~65% blended average (see caveat in Final report — this number is not the real picture) | ~65% of an assumed frontier ceiling, but this blends 4 solid tasks with 4 coin-flip ones — see Final report for why a single number misleads here | [Documenter role: final report](#documenter-role-final-report-closed-2026-08-03) |

## Documenter role: final report (closed 2026-08-03)

**Why stopped here.** Full quality loop across two sessions.
**Original close (2026-08-02)**: Phase 0 (dispatch investigation,
including a real correction of an earlier "doesn't need
`enable_thinking=false`" finding), Phase 1 baseline, a sampling-
parameter escalation, Research (cross-model check against
`qwen3.5-2b`), Steering Tier 1 (4 runs), an autonomous Tier 2 gate
(44% < 60%, skipped), and a 3-run Confirm — closed at 3 stable-pass/2
stable-fail/4 unstable. **Re-test (2026-08-03)**: after `qwen3.5:9b`'s
own quality loop found (a) `tasks/doc-repair/SPEC.md` had a bug
affecting every model, and (b) GBNF grammar-constrained decoding as a
lever for structural idioms, this model was re-tested against both
findings.

**Usability score without optimizations**: 5/9 (56%) PASS *on paper*
under the original thinking-enabled preset — but **44% of tasks (4/9)
actually produced zero content** (context-ceiling truncation). Treat
the true bare baseline as unusable for roughly half the tested task
shapes.

**Usability score with optimizations** (`enable_thinking=false` +
steering, Confirm-verified across a consolidated set of draws
collected today): **4 tasks reliably pass** (`doc-verbatim` — newly
fixed via grammar transfer from `qwen3.5:9b`; `doc-restructure` —
also grammar, see "A genuine regression, then re-fixed" below;
`doc-synthesize` — needs its steering override; `doc-crossref` —
reliable bare), **1 task reliably fails** (`doc-surgical` — confirmed
unsuitable on 2 model sizes now via real, varied steering attempts at
each), and **4 tasks are genuinely unstable** (`doc-adapt` 3/6,
`doc-script` 1/6, `doc-repair` 3/6, `doc-summarize` 4/6 — none of
these 4 were ever steered; the SPEC bug fix that resolved `doc-repair`
cleanly on `qwen3.5:9b` did **not** fully stabilize it here, a real
cross-model difference, not smoothed over). Zero truncation across
every post-fix draw.

### A genuine regression, then re-fixed: `doc-restructure`

Worth documenting prominently since it's a real methodological
lesson, not just a `doc-restructure` detail. The original Confirm
(2026-08-02) found this task stable-PASS bare, 3/3. During today's
re-test — unrelated to anything being changed about this specific
task — a fresh Confirm draw came back FAIL, then FAIL again on a
follow-up draw: a genuine regression, not measurement noise (2 draws,
same defect: missing table separator row on a freshly-generated
table — the identical idiom `qwen3.5:9b`'s own `doc-restructure` had).
**Lesson: even a task confirmed 3/3 stable in one session can drift —
periodic re-confirmation matters, not just a one-time Confirm.**
Fixed by transferring `qwen3.5:9b`'s `grammars/doc-restructure.gbnf`
directly (same task, same structural requirement, no adaptation
needed): **8/8 PASS** across every draw collected after the transfer.

### `doc-verbatim`: fixed via direct grammar transfer

This task's original Confirm-phase result was stable-FAIL, 0/3, after
a real, exhausted 4-attempt Tier 1 budget (4 distinct instruction
styles, none beat bare). `qwen3.5:9b`'s own `doc-verbatim` grammar
(structural: blank-line/fence positions forced, line content free)
was copied over verbatim — same task, same `expected.md`, so the
identical structural requirement applies — and tested: **7/7 PASS**
across every draw collected. Closes a defect that 4 rounds of prompt
iteration never touched, exactly the pattern this idiom showed on the
larger sibling too.

### `doc-surgical`: cross-model confirmation, not a new attempt

Fresh bare draws showed the identical defect `qwen3.5:9b` has (dropped
opening "(" / "the C# SDK " prefix from the given exact replacement
text) — a content-fidelity idiom, not structural, so not legitimately
grammar-fixable (see `docs/GRAMMAR-STEERING-PATTERNS.md` for why). One
targeted attempt (the checklist-style reminder, the closest thing to
partial success on `9b`) was tried as a reasonable-effort check given
how strong the cross-model precedent already was: **3/3 FAIL**, same
defect. Now confirmed unsuitable on 2 model sizes via real, varied
attempts at each — a stable cross-model finding, not a fluke.

**Comparison against a mainstream frontier LLM**: no direct benchmark
run exists, so — same as `qwen3.5-9b`'s own report — this is a reasoned
indicator, not a measured score, expressed as a percentage against an
assumed ~100% frontier ceiling on this well-specified 9-task suite.
**Averaged across all 9 tasks' actual per-draw rates: ~65%**
(`doc-verbatim`/`doc-restructure`/`doc-synthesize`/`doc-crossref` each
100%, `doc-surgical` 0%, `doc-adapt` 50%, `doc-script` ≈17%,
`doc-repair` 50%, `doc-summarize` ≈67%). **This number means something
different in kind from `qwen3.5-9b`'s own 89%, not just a lower
version of it** — 9b's figure summarizes 8 solid tasks plus one clean
0%; a single blended average is a fair summary of that shape. 4b's 65%
blends 4 solid tasks, one clean 0%, and **4 tasks at genuine coin-flip
reliability** — the average makes it look like "roughly two-thirds
reliable most of the time," when the real picture is "reliable on 4
task shapes, a coin-flip on 4 more, useless on 1." A single frontier-
LLM-relative percentage is a poor summary for this profile; treat the
per-task table above as the real answer, not this number.

**This is NOT the best qwen3.5-family result overall** —
`qwen3.5-9b` remains clearly stronger (8/9 solid with one clean
failure, vs. this model's 4/9 solid, one clean failure, and 4 tasks at
coin-flip reliability). **What did improve, genuinely**: 3→4 stable
task shapes for this model specifically, and this is now the best
result among the *smaller* siblings tested (`2b`: 1 stable, `0.8b`:
~2 at 67% each) — a real, worthwhile improvement, just not a
family-wide record.

**Final verdict: usable with mandatory `enable_thinking=false` and
mandatory human review on every output — not a "sometimes skip
review" model.** The grammar lever (borrowed from `qwen3.5:9b`'s own
session) closed 2 of this model's own previously-exhausted gaps
(`doc-verbatim`, `doc-restructure`) with zero adaptation needed — real
evidence that a structural-idiom fix, once found for one model size,
is worth checking on siblings before assuming it's size-specific.
`doc-surgical`'s content-fidelity idiom and the 4 genuinely unstable
tasks remain the real ceiling — a property of this model at this
size/role, not something prompt engineering (or grammar, for the
content-fidelity case) can close.

**Per-task detail** (draws collected across today's consolidated
Confirm; original 2026-08-02 Confirm cited where a task wasn't
re-tested):

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-verbatim` | **Stable PASS, 7/7** (grammar, new 2026-08-03) | [`grammars/doc-verbatim.gbnf`](grammars/doc-verbatim.gbnf) — transferred from `qwen3.5-9b`, structural | n/a |
| `doc-restructure` | **Stable PASS, 8/8** (grammar, re-fixed 2026-08-03 after a genuine regression from the original bare-stable result) | [`grammars/doc-restructure.gbnf`](grammars/doc-restructure.gbnf) — transferred from `qwen3.5-9b`, structural | n/a |
| `doc-synthesize` | **Stable PASS, 6/6** | [`task-overrides/doc-synthesize.md`](task-overrides/doc-synthesize.md) — forbidden-token reminder | n/a — Tier 2 gate skipped (specialist rate 44% < 60% threshold, original loop) |
| `doc-crossref` | **Stable PASS, 6/6** (bare) | bare | n/a |
| `doc-surgical` | **Stable FAIL, 0/8** — 2 distinct lever types (original loop) + 1 checklist reminder (2026-08-03), none beat bare; cross-model confirmed with `qwen3.5-9b` | bare (no valid config found) | n/a |
| `doc-adapt` | Unstable, 3/6 (bare, never steered) | bare | n/a |
| `doc-script` | Unstable, 1/6 (bare, never steered) | bare | n/a |
| `doc-repair` | Unstable, 3/6 (bare, once the shared task's bug was fixed — did NOT fully stabilize here, unlike `qwen3.5-9b`'s clean 5/5) | bare | n/a |
| `doc-summarize` | Unstable, 4/6 (bare, never steered) | bare | n/a |

## How to optimize (verify before trusting)

- `enable_thinking=false` is mandatory before any other steering — see
  Setup. Without it, up to 44% of tasks produce zero content.
- For `doc-verbatim`/`doc-restructure`-shaped tasks (blank-line/fence-
  position instability, missing table separator row on a freshly-
  generated table): **prompt-only steering failed first** (4 distinct
  attempts on `doc-verbatim`), a **GBNF grammar** fixed both —
  transferred directly from `qwen3.5-9b` with zero adaptation, since
  it's the same task/idiom. Check a sibling model's `grammars/` before
  re-deriving one from scratch.
- For `doc-synthesize`-shaped tasks: an explicit reminder naming the
  specific forbidden leftover-language token works reliably — see
  `task-overrides/doc-synthesize.md`.
- For `doc-surgical`-shaped tasks (short, exact-quoted replacement
  text fidelity): **genuinely unresolved, confirmed cross-model with
  `qwen3.5-9b`.** 3 distinct lever types across both models, all
  failed. Don't spend further budget here without a new idea.
- For tasks with genuine per-draw instability (`doc-adapt`,
  `doc-script`, `doc-repair`, `doc-summarize`-shaped tasks): no known
  fix. **`doc-repair` specifically: the shared SPEC bug fix that fully
  resolved this task on `qwen3.5:9b` did NOT fully resolve it here**
  (~50% either way) — don't assume a fix transfers identically across
  model sizes just because the underlying cause was shared.
- **A task Confirmed stable can still regress** — `doc-restructure`
  went from 3/3 stable to 0/2 over the course of this project without
  any change to its own config. Periodic re-confirmation matters, not
  just a one-time Confirm.

## Setup

- Served by `llama-server-qwen3.5-4b.service` on `:8086` (Q4_K_M GGUF,
  CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8086`.
- Downloaded 2026-08-02: `unsloth/Qwen3.5-4B-GGUF`,
  `Qwen3.5-4B-Q4_K_M.gguf`, 2.74GB. Fits this GPU's 4GB VRAM without
  the oversubscription `qwen3.5:9b` needed (~436MB free at `-ngl 99`)
  — no `-ngl` tuning applied here, not needed.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:4b`.
- **Required dispatch overrides — mandatory, not optional, per
  `AGENTS.md`'s "every dispatch-level tweak must be documented" rule:**
  - **`DISPATCH_ENABLE_THINKING=false` is required.** Real docs-task
    prompts truncated 4 of 9 tasks (44%) in the Phase 1 baseline. An
    exhaustive sampling-parameter search found no fix that didn't
    involve disabling thinking.
  - `DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20
    DISPATCH_PRESENCE_PENALTY=2.0` — same non-thinking-mode sampling
    parameters as the other qwen3.5 configs.
  - Full reproducible invocation for a docs-role test:
    ```
    DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8086 \
    DISPATCH_ENABLE_THINKING=false DISPATCH_TEMPERATURE=1.0 \
    DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=2.0 \
    bash bench/report.sh qwen3.5:4b docs llamacpp 8086
    ```
- **Mandatory: restart the service and log free VRAM/RAM before every
  test run** (`bench/report.sh`, automatic — see `AGENTS.md`). Applied
  throughout today's re-test.
- **GBNF grammar steering** (`DISPATCH_GRAMMAR_FILE`):
  `bench/pure-run.sh` auto-resolves
  `models/qwen3.5-4b/grammars/<task>.gbnf` per task. Used for
  `doc-verbatim`/`doc-restructure`, both transferred directly from
  `qwen3.5-9b` with zero adaptation.
- **`tasks/doc-repair/SPEC.md` had a bug, fixed (commit `8d98d91`).**
  Its "DEFECT 2" instruction claimed the source table was missing a
  separator row that was, in fact, already present. This model's
  `doc-repair` result is re-tested against the fixed task (see
  per-task table above) — the fix did not fully stabilize it here,
  unlike `qwen3.5-9b`.

## Further reading

- `history.md` — full per-task diagnostic breakdown from the original
  loop, plus the full 2026-08-03 re-test narrative (the
  `doc-restructure` regression investigation, the grammar transfers,
  the `doc-repair` cross-model difference).
- `docs/GRAMMAR-STEERING-PATTERNS.md` — when to reach for
  grammar-constrained decoding, backend capability notes, reusable
  structural grammar templates.
- `models/qwen3.5-9b/` — larger sibling; source of the `doc-verbatim`/
  `doc-restructure` grammars transferred here, and the `doc-repair`
  SPEC bug discovery. `models/qwen3.5-2b/` and `models/qwen3.5-0.8b/`
  — smaller siblings, not yet re-tested with these findings.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:4b
  <role>`, with the env vars above).
- `grammars/` — `doc-verbatim.gbnf`, `doc-restructure.gbnf`, both
  transferred verbatim from `qwen3.5-9b`.
- `task-overrides/` — active: `doc-synthesize.md`. Retired:
  `doc-surgical.md.checklist-attempt-failed-cross-model-confirmed`.
