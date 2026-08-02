# qwen3.5:4b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of
[`qwen3.5-2b`](../qwen3.5-2b/)/[`qwen3.5-0.8b`](../qwen3.5-0.8b/) in the
same model family — a separate model directory, steering not assumed
to transfer untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — Phase 0 done, Phase 1 starting | n/a | Not assessed | [Documenter role: current status](#documenter-role-current-status-preliminary) |

## Documenter role: current status (preliminary)

Not yet tested. See "Setup" — this is the first qwen3.5 config tested
in this project where the runaway-thinking bug does NOT apply.

## Setup

- Served by `llama-server-qwen3.5-4b.service` on `:8086` (Q4_K_M GGUF,
  CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8086`.
- Downloaded 2026-08-02: `unsloth/Qwen3.5-4B-GGUF`,
  `Qwen3.5-4B-Q4_K_M.gguf`, 2.74GB.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:4b`.
- **Dispatch overrides — genuinely different from every other qwen3.5
  config tested in this project, per `AGENTS.md`'s "every
  dispatch-level tweak must be documented" rule:**
  - **`DISPATCH_ENABLE_THINKING=false` is NOT needed here.** Every
    smaller qwen3.5 config tested in this project (0.8B: 100%
    reproduction; 2B: ~50%) hit a runaway-thinking bug where the model
    never reaches a stop token and burns the full context. At 4B, 3/3
    bare smoke-test draws completed cleanly (`finish_reason=stop`,
    559-1770 completion tokens, 1835-6021 reasoning chars) — the model
    reasons for a while but reliably converges to an answer instead of
    running away. **Real evidence the bug is a small-model-scale issue
    within this family, not a universal architecture defect** — don't
    assume it needs the same fix as the smaller configs without
    checking first, the way this exact check just did.
  - **Use thinking-mode sampling params instead** (the model defaults
    to thinking mode and handles it fine at this size — forcing
    `enable_thinking=false` would suppress a capability this size
    doesn't need suppressed): `DISPATCH_TEMPERATURE=1.0
    DISPATCH_TOP_P=0.95 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=1.5`
    — the model card's recommended **thinking-mode, text-task**
    parameters (distinct from the non-thinking-mode params used for
    the smaller configs).
  - Full reproducible invocation for a docs-role test:
    ```
    DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8086 \
    DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=0.95 \
    DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=1.5 \
    bash bench/report.sh qwen3.5:4b docs llamacpp 8086
    ```
  - **Cost/latency note**: even a trivial 3-word smoke-test prompt used
    559-1770 completion tokens (mostly reasoning). Expect real docs
    tasks to cost meaningfully more tokens/latency per dispatch than
    the smaller, non-thinking-forced configs — worth factoring into
    any final usability verdict alongside quality.

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
