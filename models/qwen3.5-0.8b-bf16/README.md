# qwen3.5:0.8b-bf16 — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Same model as [`qwen3.5-0.8b`](../qwen3.5-0.8b/)
(Q4_K_M) at full bfloat16 precision instead of quantized — a separate
model directory since precision is a real variable, not assumed to
transfer the Q4 variant's steering results untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — Phase 1 baseline done, Steering starting | 1/9 → not yet steered | Not assessed | [Documenter role: current status](#documenter-role-current-status-preliminary) |

## Documenter role: current status (preliminary)

**Bare baseline, docs role: 1/9 PASS** (`doc-crossref`) —
`reports/report-docs-20260802-130512.md`. No truncation. **Same 5
idioms as the Q4_K_M variant, same task shapes affected** — strong
cross-precision evidence these are model-architecture idioms, not
quantization artifacts. Full breakdown: `history.md`.

Dispatch fix confirmed transferring from the Q4_K_M variant: the
runaway-thinking bug reproduces here too (warm-up ping hit
`finish_reason=length` after 8177 completion tokens, 30,290 reasoning
chars, empty output), and the same `DISPATCH_ENABLE_THINKING=false` +
non-thinking sampling params fix it (clean 3-token response, zero
reasoning content) — verified, not assumed. See "Setup" for the exact
reproducible invocation.

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

- `history.md` — full per-task diagnostic breakdown once testing starts.
- `models/qwen3.5-0.8b/` — the Q4_K_M variant of this same model; check
  its `history.md`/`README.md` for idioms that might transfer (a
  hypothesis to test in the Research phase, not an assumption — see
  `AGENTS.md`'s quality loop).
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh
  qwen3.5:0.8b-bf16 <role>`, with the env vars above).
