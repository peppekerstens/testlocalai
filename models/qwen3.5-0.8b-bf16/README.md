# qwen3.5:0.8b-bf16 — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Same model as [`qwen3.5-0.8b`](../qwen3.5-0.8b/)
(Q4_K_M) at full bfloat16 precision instead of quantized — a separate
model directory since precision is a real variable, not assumed to
transfer the Q4 variant's steering results untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed — quality loop closed 2026-08-02, 2 of 9 task shapes usable with per-task steering | 1/9 → ~2/9 (2 tasks confirmed ~67% reliable specialist, rest unsuitable) | Not comparable overall; 2 narrow task shapes usable with review | [Documenter role: final report](#documenter-role-final-report-closed-2026-08-02) |

## Documenter role: final report (closed 2026-08-02)

**Why stopped here.** Full quality loop: Phase 0 (dispatch fix
confirmed transferring from the Q4_K_M variant), Phase 1 baseline,
Research phase (the Q4_K_M variant's own validated overrides as the
cross-precision hypothesis, tested directly), Tier 1 specialist
optimization (3 Steering runs), an autonomous Tier 2 gate (specialist
rate 3/9 ≈ 33%, below the 60% threshold — Tier 2 skipped, no question
asked), and a 3-run Confirm check. Completed process, not budget
exhaustion.

**Usability score without optimizations (bare): 1/9 (11%) PASS**
(`reports/report-docs-20260802-130512.md`).

**Usability score with optimizations: 2/9 tasks reach a reliable, if
imperfect, specialist PASS (~67% each, Confirm-verified: `doc-crossref`
2/3, `doc-summarize` 2/3 — both essentially identical to the Q4_K_M
variant's own confirmed reliability on the same 2 tasks); 5 more tasks
reach stable partial improvement without a full PASS
(`doc-verbatim`, `doc-surgical`, `doc-adapt`, `doc-repair`,
`doc-script`); 2 tasks showed no net improvement worth keeping
(`doc-synthesize` — passed once during Steering but 0/3 in Confirm,
reverted to bare; `doc-restructure` — instruction conflicted with the
task's actual job, reverted to bare).**

**Comparison against a mainstream frontier LLM: not comparable
overall**, same reasoning as the Q4_K_M variant — a model like Claude
Haiku 4.5 would be expected to pass close to all 9 zero-shot. **The
same narrow exception applies**: `doc-crossref` and `doc-summarize`
reach ~67% reliability at near-zero cost/latency versus a hosted
frontier-model call, usable with human review on those two specific
task shapes only.

**Final verdict: not suitable as a general documenter — result nearly
identical to the Q4_K_M variant of this same model.** Usable for the
same 2 of 9 task shapes at ~67% reliability under review. **The
precision variants converged on almost the same outcome**: cross-
precision transfer worked immediately and without modification for the
2 tasks that matter most (`doc-crossref`, `doc-summarize` — copied
overrides, zero adaptation, same ~67% reliability both variants). The
practical differences were narrow: `doc-adapt` reached stable partial
improvement here but was gated flat on Q4, and `doc-synthesize` looked
promising here before Confirm caught it as noise, whereas the same
instruction was a clean regression on Q4 — different evidence, same
practical conclusion on both. **Bottom line for anyone choosing between
the two precisions for this role: use whichever is cheaper to run
(Q4_K_M, smaller) — bf16 does not deliver enough incremental quality to
justify its ~3x size for this task set.**

**Per-task detail** (Confirm-verified):

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-crossref` | **~67% reliable PASS** (2/3 Confirm draws) | [`task-overrides/doc-crossref.md`](task-overrides/doc-crossref.md) — identical to Q4's, zero adaptation needed | n/a — Tier 2 gate skipped (specialist rate 33% < 60% threshold) |
| `doc-summarize` | **~67% reliable PASS** (2/3 Confirm draws) | [`task-overrides/doc-summarize.md`](task-overrides/doc-summarize.md) — identical to Q4's | n/a |
| `doc-verbatim` | Stable partial — consistent 1-line-defect improvement over bare, never a full PASS | [`task-overrides/doc-verbatim.md`](task-overrides/doc-verbatim.md) | n/a |
| `doc-surgical` | Stable partial — instruction-bleed reduced, substitution still not applied | [`task-overrides/doc-surgical.md`](task-overrides/doc-surgical.md) | n/a |
| `doc-adapt` | Stable partial — forbidden-token count reduced (differs from Q4, where this task was gated flat) | [`task-overrides/doc-adapt.md`](task-overrides/doc-adapt.md) | n/a |
| `doc-repair` | Stable partial — near-miss every draw | [`task-overrides/doc-repair.md`](task-overrides/doc-repair.md) | n/a |
| `doc-script` | Stable partial — same shape as Q4's transferred override | [`task-overrides/doc-script.md`](task-overrides/doc-script.md) | n/a |
| `doc-synthesize` | 0/3 Confirm, one Steering-phase PASS looked like noise — **reverted to bare** | bare — steering didn't hold up | n/a |
| `doc-restructure` | Gated out — instruction conflicted with the task's actual job (transform, not preserve) | bare | n/a |

## How to optimize (verify before trusting)

- `DISPATCH_ENABLE_THINKING=false` is mandatory before any other
  steering — see Setup below.
- For `doc-crossref`/`doc-summarize`-shaped tasks: `qwen3.5-0.8b`'s
  exact-fact-reminder overrides transfer here with zero adaptation and
  the same ~67% reliability — reuse them directly rather than
  reinventing, see
  [`task-overrides/doc-crossref.md`](task-overrides/doc-crossref.md)
  and
  [`task-overrides/doc-summarize.md`](task-overrides/doc-summarize.md).
- For `doc-verbatim`/`doc-surgical`/`doc-adapt`/`doc-repair`/
  `doc-script`-shaped tasks: task-specific steering reaches a stable
  partial improvement (never a full PASS) — see their
  `task-overrides/` files. Don't expect a full fix from further prompt
  iteration on these task shapes at this size.
- **Precision is not the lever here** — this variant and the Q4_K_M
  variant converged on nearly the same outcome across every task
  tested. If choosing between them, prefer Q4_K_M (smaller, same
  quality) — see the Final report above.

## Setup

- Served by `llama-server-qwen3.5-0.8b-bf16.service` on `:8085`
  (bfloat16 GGUF, CUDA), context `-c 8192`; run bench with
  `LLAMACPP_PORT=8085`.
- Downloaded 2026-08-01: `Qwen/Qwen3.5-0.8B` bf16 GGUF, ~1.4GB (vs
  Q4_K_M's ~460MB). License: same as `qwen3.5-0.8b`.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:0.8b-bf16`.
- **Required dispatch overrides — identical to `qwen3.5-0.8b`, confirmed
  independently for this precision variant, per `AGENTS.md`'s "every
  dispatch-level tweak must be documented" rule:**
  - `DISPATCH_ENABLE_THINKING=false` — **mandatory, not optional**, same
    reason as the Q4 variant (see `qwen3.5-0.8b/README.md`'s Setup
    section for the full explanation). This model family has no
    in-prompt `/think`/`/no_think` switch.
  - `DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20
    DISPATCH_PRESENCE_PENALTY=2.0` — same model-card-recommended
    non-thinking-mode sampling parameters as the Q4 variant (this is
    the same underlying model, just different precision — the
    recommended sampling params aren't precision-specific).
  - Full reproducible invocation for a docs-role test:
    ```
    DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8085 \
    DISPATCH_ENABLE_THINKING=false DISPATCH_TEMPERATURE=1.0 \
    DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=2.0 \
    bash bench/report.sh qwen3.5:0.8b-bf16 docs llamacpp 8085
    ```
- `bash bench/session-start.sh qwen3.5:0.8b-bf16 llamacpp` stops other
  local hosters and starts this service exclusively — its own warm-up
  ping does NOT set the overrides above, so expect (and ignore) one
  runaway-reasoning warning during session start itself.

## Further reading

- `history.md` — full per-task diagnostic breakdown, every idiom,
  every tried variant, and the reasoning behind every keep/revert
  decision.
- `models/qwen3.5-0.8b/` — the Q4_K_M variant of this same model; check
  its `history.md`/`README.md` for idioms that might transfer (a
  hypothesis to test in the Research phase, not an assumption — see
  `AGENTS.md`'s quality loop).
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh
  qwen3.5:0.8b-bf16 <role>`, with the env vars above).
