# qwen3.5:4b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of
[`qwen3.5-2b`](../qwen3.5-2b/)/[`qwen3.5-0.8b`](../qwen3.5-0.8b/) in the
same model family — a separate model directory, steering not assumed
to transfer untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed — quality loop closed 2026-08-02, 3 reliable task shapes, 4 genuinely unstable, 2 unsuitable | 5/9 bare-on-paper (44% empty output) → ~52%/draw with real content every time | Not comparable overall; best qwen3.5-family content reliability so far on 3 task shapes | [Documenter role: final report](#documenter-role-final-report-closed-2026-08-02) |

## Documenter role: final report (closed 2026-08-02)

**Why stopped here.** Full quality loop: Phase 0 (dispatch
investigation, including a real correction of an earlier "doesn't need
`enable_thinking=false`" finding), Phase 1 baseline, a sampling-
parameter escalation (full-role test, then 5 fast single-task-capped
attempts, all exhausted before falling back to `enable_thinking=false`
per explicit user direction — see `history.md`), Research (cross-model
check against `qwen3.5-2b`), Steering Tier 1 (4 runs), an autonomous
Tier 2 gate (44% < 60%, skipped), and a 3-run Confirm.

**Usability score without optimizations**: 5/9 (56%) PASS *on paper*
under the original thinking-enabled preset — but **44% of tasks (4/9)
actually produced zero content** (context-ceiling truncation after
burning the full 8192-token budget on unresolved reasoning). The
headline number materially overstates real usability; treat the true
bare baseline as unusable for roughly half the tested task shapes.

**Usability score with optimizations** (`enable_thinking=false` +
Steering, Confirm-verified across 3 draws): **3 tasks reliably pass**
(`doc-synthesize` — needs its steering override; `doc-crossref`,
`doc-restructure` — reliable bare), **2 tasks reliably fail**
(`doc-verbatim`, `doc-surgical` — confirmed unsuitable after real,
varied steering attempts: 4 and 2 distinct instruction styles
respectively, none beat bare), and **4 tasks are genuinely unstable**
(`doc-adapt` 1/3, `doc-script` 1/3, `doc-repair` 2/3, `doc-summarize`
1/3 — none of these 4 were ever steered, so the instability is the
model's own reliability ceiling on this role, not a fixable prompt
gap). Average ~52% pass rate per draw — but that average is
misleading on its own: it's not "half the tasks always pass," it's a
specific 3/2/4 split. **Zero truncation** across every post-fix draw —
the categorical improvement over the bare baseline isn't the raw pass
rate (which is similar), it's that every draw now produces real,
reviewable content on every task instead of a 44% chance of nothing.

**Comparison against a mainstream frontier LLM**: not comparable
overall — a model like Claude Haiku 4.5 would be expected to pass
close to all 9 tasks reliably, not show a 3/2/4 stable-pass/stable-
fail/coin-flip split. **This is the best qwen3.5-family content
reliability result so far on 3 specific task shapes** (cross-document
synthesis with correct forbidden-token avoidance, structural
transformation, new-section synthesis), all near-zero cost/latency
versus a hosted frontier call — but the model cannot be trusted
unsupervised even on task shapes it sometimes gets right, unlike a
frontier model's default reliability.

**Final verdict: usable with mandatory `enable_thinking=false` and
mandatory human review on every output — not a "sometimes skip
review" model.** This is a materially different profile from
`qwen3.5-2b`'s one rock-solid specialist result: bigger did not mean
uniformly more reliable here, it meant a wider spread of
partially-working task shapes with real content instead of empty
truncated output. The 4 genuinely unstable tasks are the single most
important finding of this loop — a property of the model itself at
this size on this role, not something prompt engineering can close.

**Per-task detail**:

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-synthesize` | **Stable PASS, 3/3 Confirm draws** | [`task-overrides/doc-synthesize.md`](task-overrides/doc-synthesize.md) — forbidden-token reminder | n/a — Tier 2 gate skipped (specialist rate 44% < 60% threshold) |
| `doc-crossref` | **Stable PASS, 3/3 Confirm draws** (bare) | bare | n/a |
| `doc-restructure` | **Stable PASS, 3/3 Confirm draws** (bare) | bare | n/a |
| `doc-repair` | Unstable, 2/3 Confirm draws (bare, never steered) | bare | n/a |
| `doc-adapt` | Unstable, 1/3 Confirm draws (bare, never steered) | bare | n/a |
| `doc-script` | Unstable, 1/3 Confirm draws (bare, never steered) | bare | n/a |
| `doc-summarize` | Unstable, 1/3 Confirm draws (bare, never steered) | bare | n/a |
| `doc-verbatim` | **Stable FAIL, 0/3** — 4/4 Tier 1 budget used, 4 distinct instruction styles, none beat bare | bare | n/a |
| `doc-surgical` | **Stable FAIL, 0/3** — 2 distinct lever types tried, zero movement | bare | n/a |

## Setup

- Served by `llama-server-qwen3.5-4b.service` on `:8086` (Q4_K_M GGUF,
  CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8086`.
- Downloaded 2026-08-02: `unsloth/Qwen3.5-4B-GGUF`,
  `Qwen3.5-4B-Q4_K_M.gguf`, 2.74GB.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:4b`.
- **Required dispatch overrides — mandatory, not optional (corrected
  2026-08-02 — see `history.md` for why the original "not needed"
  finding was wrong), per `AGENTS.md`'s "every dispatch-level tweak
  must be documented" rule:**
  - **`DISPATCH_ENABLE_THINKING=false` is required.** A Phase 0 smoke
    test on trivial 3-word prompts (3/3 clean) suggested this model
    doesn't have the runaway-thinking bug its smaller siblings have
    (0.8B: 100% reproduction; 2B: ~50%). **That was wrong** — real
    docs-task prompts (more context, more complexity) truncated 4 of 9
    tasks (44%) in the Phase 1 baseline, confirmed live via
    `journalctl` monitoring (two genuine 8192-token truncations, one
    taking 210.9s wall-clock — the established reference: a normal
    completion takes ~15-45s, a runaway one ~211s at this model's
    ~37-40 tok/s). An exhaustive sampling-parameter search (5 distinct
    combinations, original preset through near-greedy decoding) found
    no fix that didn't involve disabling thinking. This model family
    has no in-prompt `/think`/`/no_think` switch —
    `chat_template_kwargs.enable_thinking` is the only control.
  - `DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20
    DISPATCH_PRESENCE_PENALTY=2.0` — the same non-thinking-mode
    sampling parameters used for the 0.8B/2B configs (same model
    family).
  - Full reproducible invocation for a docs-role test:
    ```
    DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8086 \
    DISPATCH_ENABLE_THINKING=false DISPATCH_TEMPERATURE=1.0 \
    DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=2.0 \
    bash bench/report.sh qwen3.5:4b docs llamacpp 8086
    ```
  - **A real llama-server flag was identified but not needed**:
    `--reasoning-budget N` (confirmed supported by the installed
    build) caps reasoning tokens and forces a clean `</think>` instead
    of running unrestricted — a genuine middle ground between
    unrestricted thinking and disabling it entirely. Not tried, since
    `enable_thinking=false` fully resolved the truncation problem
    first. Worth revisiting only if a future session wants this
    model's *thinking* content back (e.g. for a role where reasoning
    traces matter) without reintroducing the runaway risk.

## Further reading

- `history.md` — full per-task diagnostic breakdown once testing starts.
- `models/qwen3.5-2b/` and `models/qwen3.5-0.8b/` — smaller siblings;
  check their `history.md`/`README.md` for idioms that might transfer
  (a hypothesis, not an assumption — see `AGENTS.md`'s quality loop).
  Note: Q3's idiom already showed non-uniform transfer from 0.8B to 2B;
  expect the same caution here.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:4b
  <role>`, with the env vars above).
