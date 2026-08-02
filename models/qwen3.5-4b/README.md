# qwen3.5:4b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of
[`qwen3.5-2b`](../qwen3.5-2b/)/[`qwen3.5-0.8b`](../qwen3.5-0.8b/) in the
same model family — a separate model directory, steering not assumed
to transfer untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — Steering starting | 3/9 bare (`enable_thinking=false`, 0% truncation) | Not assessed | [Documenter role: current status](#documenter-role-current-status-preliminary) |

## Documenter role: current status (preliminary)

**Working baseline, docs role: 3/9 PASS, zero truncation** —
`reports/report-docs-20260802-151206.md`, dispatched with
`DISPATCH_ENABLE_THINKING=false` (see Setup — this is now this model's
required configuration, not optional). Single draw. The 6 FAILs are
almost all single-defect near-misses with real, mostly-correct content
(`doc-surgical`/`doc-adapt`/`doc-synthesize` all pass their forbidden/
required-token checks, failing only on whitespace or one stray token)
— a strong Steering starting point. Full breakdown: `history.md`.

**This supersedes an earlier thinking-enabled baseline that looked
better on paper (5/9 PASS) but wasn't usable**: 4 of those 9 tasks
produced *zero* content (truncated at the 8192-token context ceiling
after burning the full budget on unresolved reasoning), a 44% failure
rate hidden behind the headline number. Getting there took a real
escalation, documented in full in `history.md`:

1. A full-role sampling-parameter test (34+ min, 4+ truncations,
   killed mid-run) showed no improvement over the original preset.
2. Switched to a fast single-task, 3-minute-capped test loop. **5
   sampling-parameter combinations — spanning the original preset
   through near-deterministic (near-greedy) decoding — all timed out**;
   no amount of temperature/top_p/top_k/presence_penalty tuning
   resolved the runaway-thinking behavior.
3. `DISPATCH_ENABLE_THINKING=false` (the explicit fallback, only after
   the above was exhausted) succeeded immediately and eliminated
   truncation entirely on a full 9-task re-test.

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
