# qwen3.5:4b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of
[`qwen3.5-2b`](../qwen3.5-2b/)/[`qwen3.5-0.8b`](../qwen3.5-0.8b/) in the
same model family — a separate model directory, steering not assumed
to transfer untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — Steering Tier 1 closed, Confirm next | 3/9 bare → 4/9 best draw, real per-draw instability observed | Not assessed | [Documenter role: current status](#documenter-role-current-status-preliminary) |

## Documenter role: current status (preliminary)

**Working baseline, docs role: 3/9 PASS, zero truncation** —
`reports/report-docs-20260802-151206.md`, dispatched with
`DISPATCH_ENABLE_THINKING=false` (see Setup — this is now this model's
required configuration, not optional). This supersedes an earlier
thinking-enabled baseline that looked better on paper (5/9 PASS) but
wasn't usable — 4 of those 9 tasks produced *zero* content (truncated
at the context ceiling), a 44% failure rate hidden behind the headline
number. Getting to the working baseline took a real escalation
(full-role sampling test → fast single-task capped tests → 5 failed
sampling combinations → `enable_thinking=false` as the explicit
fallback), documented in full in `history.md`.

**Steering Tier 1 closed after 4 runs: 1 confirmed working override,
2 tasks reverted to bare after real effort, and a broader finding —
this role shows real, significant per-draw instability independent of
steering.** `doc-synthesize`'s targeted fix (drop the leftover `zod`
token) worked cleanly and held across all 4 post-fix draws.
`doc-verbatim` (4 different instruction styles tried) and
`doc-surgical` (2 different lever types tried) both reverted to bare —
no variant beat bare with confidence. **The more important finding**:
`doc-adapt`, `doc-script`, `doc-repair`, `doc-summarize`, and even
`doc-restructure` (previously PASS on every draw this entire session)
all flipped pass/fail across the 4 Steering draws despite never being
touched by any steering — single-draw pass counts for this model swung
from 3 to 7 out of 9 purely from bare-task noise. **Confirm is
essential here, not a formality.** Per-task detail:

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-synthesize` | **PASS, 4/4 post-fix draws** | [`task-overrides/doc-synthesize.md`](task-overrides/doc-synthesize.md) — forbidden-token reminder | n/a — Tier 2 gate skipped (specialist rate 44% < 60% threshold) |
| `doc-crossref` | PASS, consistent across all Steering draws (bare, never needed steering) | bare | n/a |
| `doc-repair` | Bare, flipped pass/fail across draws — real instability | bare | n/a |
| `doc-summarize` | Bare, flipped pass/fail across draws — real instability | bare | n/a |
| `doc-adapt` | Bare, flipped pass/fail across draws — real instability | bare | n/a |
| `doc-script` | Bare, flipped pass/fail across draws — real instability | bare | n/a |
| `doc-restructure` | Bare, flipped to FAIL once after passing every prior draw this session | bare | n/a |
| `doc-verbatim` | 4/4 Tier 1 budget used, 4 distinct instruction styles, none beat bare — reverted | bare | n/a |
| `doc-surgical` | 2 distinct lever types tried, zero movement — reverted | bare | n/a |

**Tier 2 gate**: 4/9 ≈ 44% specialist rate, below the 60% threshold —
skipped per `AGENTS.md`'s autonomous rule. Next: Confirm.

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
