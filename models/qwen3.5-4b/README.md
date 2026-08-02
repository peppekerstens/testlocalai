# qwen3.5:4b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of
[`qwen3.5-2b`](../qwen3.5-2b/)/[`qwen3.5-0.8b`](../qwen3.5-0.8b/) in the
same model family — a separate model directory, steering not assumed
to transfer untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — Phase 1 baseline done, Steering starting | 5/9 bare (best of qwen3.5 family), 44% truncation rate | Not assessed | [Documenter role: current status](#documenter-role-current-status-preliminary) |

## Documenter role: current status (preliminary)

**Bare baseline, docs role: 5/9 PASS** —
`reports/report-docs-20260802-135441.md`, by far the best bare
baseline of any qwen3.5 config tested this session (0.8B: 1/9, 2B:
2/9). Single draw.

**Correction to Phase 0's "0/3" framing below: it understated the real
risk.** Trivial smoke-test prompts (3/3 clean) do not represent real
docs-task behavior — **4 of 9 tasks (44%) in this single baseline draw
hit `finish_reason=length` with completely empty final output**
(`doc-verbatim`, `doc-adapt`, `doc-script`, `doc-repair`), confirmed
live via `journalctl` monitoring during the run: two tasks truncated
outright at the 8192-token ceiling (one took 210.9s wall-clock — the
established reference for "how long does a runaway task take": normal
~15-45s vs. runaway ~211s at this model's ~37-40 tok/s), and a third
came within 314 tokens of the same ceiling before narrowly converging.
Full breakdown: `history.md`.

**Per explicit user instruction: sampling-parameter and thinking-
control experimentation is the priority lever, with `enable_thinking=
false` explicitly deprioritized as a last resort, not a default.** A
real middle-ground lever was identified via research and confirmed
supported by the installed llama-server build: `--reasoning-budget N`
(server-startup flag, forces a clean `</think>` at N tokens instead of
running unrestricted to the context ceiling). Not yet tried — Steering
starts with alternate sampling parameters first, per instruction.

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
