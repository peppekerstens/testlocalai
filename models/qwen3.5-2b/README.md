# qwen3.5:2b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of [`qwen3.5-0.8b`](../qwen3.5-0.8b/)
in the same model family (not just a precision variant — a real
parameter-count difference, 2B vs 0.8B) — a separate model directory,
steering not assumed to transfer untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — Steering Tier 1 closed, Confirm next | 2/9 → 3/9 (1 specialist PASS, 2 bare PASS, 1 stable partial) | Not assessed | [Documenter role: current status](#documenter-role-current-status-preliminary) |

## Documenter role: current status (preliminary)

**Bare baseline, docs role: 2/9 PASS** (`doc-summarize`,
`doc-restructure`) — `reports/report-docs-20260802-132935.md`, better
than either 0.8B variant's bare baseline (both 1/9). No truncation.

**Idiom picture differs meaningfully from the 0.8B variants** — not a
scaled-up copy of the same failures. Q1 (structural dropping) and Q2
(instruction bleed) still present, same shape as 0.8B. **Q3
(substitution not applied) is largely resolved at this size** —
`doc-adapt`/`doc-script` get the actual substitution content right,
only failing on formatting. **New idiom Q5 (backwards semantic
attribution)**: `doc-crossref` gets both required facts present but
describes the tool as performing the obfuscation rather than reporting
it — a logic error, not a missing-fact error, never seen on 0.8B. Full
breakdown: `history.md`.

**Steering Tier 1 closed after 2 runs.** `doc-crossref`'s new
mechanism-reminder fix worked immediately (2/2 PASS so far). One
severe regression found and reverted: `doc-surgical`'s
boundary-discipline instruction triggered a degenerate repetition loop
(same paragraph repeated ~8 times) — an idiom not seen on either 0.8B
variant. `doc-verbatim` reached a 1-line-defect near-miss; a follow-up
refinement made it worse and was reverted. `doc-adapt`/`doc-script`/
`doc-synthesize`/`doc-repair` showed no promise on their first
attempt, gated to bare. Per-task detail:

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-crossref` | **PASS** (2/2 so far, needs Confirm) | [`task-overrides/doc-crossref.md`](task-overrides/doc-crossref.md) — new Q5-specific mechanism reminder | n/a — Tier 2 gate pending |
| `doc-summarize` | **PASS bare**, no steering needed | bare | n/a |
| `doc-restructure` | **PASS bare** most draws, needs Confirm (already-documented per-draw instability project-wide) | bare | n/a |
| `doc-verbatim` | Stable partial — 1-line defect, best-observed state kept after a worse refinement was reverted | [`task-overrides/doc-verbatim.md`](task-overrides/doc-verbatim.md) | n/a |
| `doc-surgical` | Gated out — **regressed to a degenerate repetition loop**, new idiom not seen on 0.8B | bare | n/a |
| `doc-adapt` | Gated out (flat after run 1) | bare | n/a |
| `doc-script` | Gated out (flat after run 1) | bare | n/a |
| `doc-synthesize` | Gated out (flat after run 1) | bare | n/a |
| `doc-repair` | Gated out (flat after run 1) | bare | n/a |

**Tier 2 gate**: tasks with a current PASS = `doc-crossref`,
`doc-summarize`, `doc-restructure` = 3/9 ≈ 33% — below the 60%
threshold. Tier 2 skipped per `AGENTS.md`'s autonomous rule. Next:
Confirm.

## Setup

- Served by `llama-server-qwen3.5-2b.service` on `:8084` (Q4_K_M GGUF,
  CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8084`.
- Downloaded 2026-08-01: `Qwen/Qwen3.5-2B` Q4_K_M GGUF, ~1.2GB. License:
  same as `qwen3.5-0.8b`.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:2b`.
- **Required dispatch overrides — mandatory, not optional, per
  `AGENTS.md`'s "every dispatch-level tweak must be documented" rule:**
  - `DISPATCH_ENABLE_THINKING=false` — same runaway-thinking bug as
    both 0.8B variants, confirmed via direct test (2026-08-02): a
    bare-dispatch draw with no override hit `finish_reason=length`
    after 8174 completion tokens, 22,527 reasoning chars, empty answer.
    **Note: not deterministic on every draw** — this session's initial
    `session-start.sh` warm-up ping happened to succeed (6.4s, no
    runaway) before a direct follow-up test reproduced the bug on its
    very next draw. Don't take one successful warm-up as evidence the
    bug doesn't apply — it's real and reproducible, just not 100%
    per-draw (unlike the 0.8B variants, which reproduced it on every
    draw tested so far). This model family has no in-prompt
    `/think`/`/no_think` switch — `chat_template_kwargs.enable_thinking`
    is the only control.
  - `DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20
    DISPATCH_PRESENCE_PENALTY=2.0` — same model-card-recommended
    non-thinking-mode sampling parameters as the 0.8B variants (same
    model family). Smoke-tested working: clean 9-token response,
    `finish_reason=stop`, zero reasoning content.
  - Full reproducible invocation for a docs-role test:
    ```
    DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8084 \
    DISPATCH_ENABLE_THINKING=false DISPATCH_TEMPERATURE=1.0 \
    DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=2.0 \
    bash bench/report.sh qwen3.5:2b docs llamacpp 8084
    ```
- `bash bench/session-start.sh qwen3.5:2b llamacpp` stops other local
  hosters and starts this service exclusively — its own warm-up ping
  does NOT set the overrides above and may or may not hit the
  runaway-thinking bug (non-deterministic, see above) — don't treat
  either outcome as evidence about the fix's necessity.

## Further reading

- `history.md` — full per-task diagnostic breakdown once testing starts.
- `models/qwen3.5-0.8b/` and `models/qwen3.5-0.8b-bf16/` — the smaller
  siblings of this same model family; check their `history.md`/
  `README.md` for idioms that might transfer (a hypothesis to test in
  the Research phase, not an assumption — see `AGENTS.md`'s quality
  loop). Note: a real parameter-count difference (2B vs 0.8B) is a
  bigger jump than the precision-only difference between the two 0.8B
  variants — transfer is less certain here.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:2b
  <role>`, with the env vars above).
