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
| Documenter | ⚠️ Mixed — quality loop closed 2026-09-13, 7 of 9 task shapes stable, 2 flaky (both pre-existing model idioms, not steering regressions) | 4/9 bare → 7/9 stable (Confirm ran FLAKY at 8/6/8, not clean, see caveat) | Not assessed | [Documenter role: final report](#documenter-role-final-report-closed-2026-09-13) |

## Documenter role: final report (closed 2026-09-13)

**Usability without optimizations**: 4/9 (44%) PASS bare, `enable_thinking=false`
set from the start (family default, not yet independently re-verified for
this exact checkpoint).

**Usability with optimizations**: 7/9 stable across Tier 1 steering,
confirmed as the honest core result after a FLAKY Confirm verdict (8, 6, 8
across 3 draws). The 2 flaky tasks, `doc-restructure` and `doc-surgical`,
are not steering regressions — full reasoning in Confirm's own Findings,
`reports/confirm-docs-20260913-110428.md`, and the round-by-round narrative
in `history.md`. `doc-adapt` is the one task that stayed a consistent,
confirmed FAIL, no partial improvement found in one real attempt.

**Comparison against a mainstream frontier LLM**: not assessed for this
role on this checkpoint. `qwen3.5-9b`, the closest sibling with a real
comparison in this project, lands at roughly 89% of an assumed frontier
ceiling on the same 9-task set with a cleaner 8/9 stable result — this
checkpoint's 7/9 (78%), with 2 tasks genuinely flaky rather than cleanly
stable, sits below that. Caveats: smaller model (4B against 9B), a
materially different quantization (2-bit gradient search against
Q4_K_M/Q4_K_M-class formats used elsewhere in this project), and no direct
frontier-model run against this exact 9-task set to anchor the comparison
numerically rather than by analogy to a sibling's own number.

Per-task table:

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-verbatim` | ✅ Fixed, round 1 | `task-overrides/doc-verbatim.md` | no generalist — n/a |
| `doc-repair` | ✅ Fixed, round 1 | `task-overrides/doc-repair.md` | no generalist — n/a |
| `doc-summarize` | ✅ Fixed, round 1 | `task-overrides/doc-summarize.md` | no generalist — n/a |
| `doc-script` | ✅ Fixed, round 2 | `task-overrides/doc-script.md` | no generalist — n/a |
| `doc-surgical` | ⚠️ Gated out, reverted to bare, still flaky at Confirm | bare | no generalist — n/a |
| `doc-adapt` | ❌ Gated out, reverted to bare, consistent FAIL | bare | no generalist — n/a |
| `doc-crossref` | ✅ Stable bare, never needed steering | bare | no generalist — n/a |
| `doc-synthesize` | ✅ Stable bare, never needed steering | bare | no generalist — n/a |
| `doc-restructure` | ✅ Stable bare in Tier 1, flaky at Confirm (known family idiom) | bare | no generalist — n/a |

**Tier 2 generalist search**: no generalist config found, and none
searched by dispatch — reasoned directly from this run's own Tier 1
evidence instead. Every one of the 4 working overrides needed a quote of
that exact task's own wrong output next to the correct one. That content
is inherently task-specific. No single shared prompt block can carry it. Full reasoning in `history.md`.

**Performance run**: skipped, with reason. Real speed already runs 85 to
105 tok/s depending on load, and no failure in this role traces to output
length or verbosity — see `history.md`.

## How to optimize (verify before trusting)

- `DISPATCH_ENABLE_THINKING=false` first, before any other steering.
  Carried over from the qwen3.5 family default, see Setup.
- For a `doc-verbatim`/`doc-repair`/`doc-summarize`/`doc-script`-shaped
  fix: quote the model's own actual wrong output next to the correct one,
  then add one self-check tied to the exact failure mode. This pattern
  fixed all 4 in one attempt each — see `task-overrides/` for each real
  config used.
- For `doc-surgical`-shaped tasks (a single backtick sliding one position
  in a short exact-quote edit): steering did not stick. One attempt,
  gated out. The bare model still gets this right most draws, wrong on
  some — real per-draw instability on one specific idiom, not a fix
  worth chasing further without a new idea.
- For `doc-restructure`-shaped tasks (a valid but non-literal markdown
  table separator, `:---` instead of `---`): never needed steering to
  pass once, but the bare model does not always avoid this idiom. Same
  idiom is documented across `qwen3.5-0.8b`, `qwen3.5-4b`, `qwen3.5-9b`,
  and `lfm2.5-1.2b-thinking` — check a grammar-constrained fix from a
  sibling model's `grammars/` before inventing a new lever.
- `doc-adapt` (a splice-boundary error, deleting untouched text adjacent
  to an edit): unresolved. One real attempt, no partial improvement,
  gated out per `AGENTS.md`'s rule.

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

## Further reading

- `history.md` — running narrative for this model's testing.
- `reports/` — raw per-run reports.
- [`qwen3.5-4b`](../qwen3.5-4b/) — same base model, different quantization,
  own separate steering profile.
