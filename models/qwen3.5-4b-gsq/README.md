# qwen3.5-4b-gsq — steering profile

Distinct artifact from [`qwen3.5-4b`](../qwen3.5-4b/) (`unsloth/Qwen3.5-4B-GGUF`,
Q4_K_M). This one is `ISTA-DASLab/Qwen3.5-4B-GGUF-GSQ`, the `Q2_K_XL` file.

A gradient-search low-bit quantization, a real, verified 1.81 GiB, against
the other's 2.74 GiB. Same base weights, different quantization method and
size. Steering is not assumed to transfer between the two directories
untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Quality loop in progress, started 2026-09-13 | not yet reported | Not assessed | [Documenter role](#documenter-role) |

## Documenter role

Quality loop started 2026-09-13 via `bash bench/loop.sh qwen3.5-4b-gsq docs`.
This section replaces once the loop reaches Confirm or closes early — see
`history.md` for the running narrative and `reports/` for each raw run.

## Setup

- Served by `llama-chat-4b-gsq.service` on `legion-t5` (`192.168.2.133:11436`),
  reached from this workstation over an SSH port forward
  (`ssh -N -L 8090:localhost:11436 peppe@192.168.2.133`) — run bench with
  `LLAMACPP_PORT=8090`.
- `--ctx-size 245760 --parallel 2 --kv-unified --flash-attn on
  --cache-type-k q8_0 --cache-type-v q8_0 -ngl 99`. Real, tested max for this
  model on this 8 GiB RTX 3060 Ti, two slots, one shared KV pool — see
  `ai-stack/litellm-router` session history, 2026-09-13, for the empirical
  derivation (262144, the model's own native ceiling, only fits when
  `embed-local` holds zero VRAM, which is not this box's normal running
  state — its CPU-mode residual footprint, about 158 MiB, is enough to push
  262144 into a real, confirmed CUDA out-of-memory).
- Whitelisted in `bench/dispatch.sh` as `qwen3.5-4b-gsq`.
- **Required dispatch overrides — mandatory, not optional, per `AGENTS.md`'s
  "every dispatch-level tweak must be documented" rule:**
  - `DISPATCH_ENABLE_THINKING=false` — same qwen3.5-family reasoning-off
    convention as every other model in this directory. Not yet independently
    re-verified as mandatory for this checkpoint, see Phase 0 below. Carried
    over from the family default until Phase 1 says otherwise.
  - `DISPATCH_HW_LABEL="legion-t5, RTX 3060 Ti 8GB, ctx=245760 parallel=2 kv-unified"`.
    Set this on every dispatch against this host. Do not compare its tok/s
    against any other model's report unless the Hardware line matches.
- Full reproducible invocation for a docs-role test:
  ```
  DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8090 \
    DISPATCH_ENABLE_THINKING=false \
    DISPATCH_HW_LABEL="legion-t5, RTX 3060 Ti 8GB, ctx=245760 parallel=2 kv-unified" \
    bash bench/report.sh qwen3.5-4b-gsq docs
  ```

## See also

- `history.md` — running narrative for this model's testing.
- `reports/` — raw per-run reports.
- [`qwen3.5-4b`](../qwen3.5-4b/) — same base model, different quantization,
  own separate steering profile.
