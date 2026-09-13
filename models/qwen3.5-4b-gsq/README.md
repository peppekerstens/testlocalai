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
| Reasoner | 🔬 Preliminary — 5 real failures, 2026-09-13 | 4/9 bare | Not assessed | [Reasoner role](#reasoner-role) |
| Tool-use | 🔬 Preliminary — clean bare pass, 2026-09-13 | 6/6 bare | Not assessed | [Tool-use role](#tool-use-role) |
| Extract | 🔬 Preliminary — clean bare pass, 2026-09-13 | 6/6 bare | Not assessed | [Extract role](#extract-role) |
| Review | 🔬 Preliminary — 2 real failures, 2026-09-13 | 4/6 bare | Not assessed | [Review role](#review-role) |
| Code-emitter | 🔬 Preliminary — clean bare pass, 2026-09-13 | 14/14 bare | Not assessed | [Code-emitter role](#code-emitter-role) |

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

## Reasoner role

4/9 PASS, bare, single draw, `DISPATCH_REASONING_EFFORT=none`, direct
legion-t5 dispatch, 2026-09-13. Real failures: `reason-diagnose`,
`reason-trace`, `reason-consequence`, `reason-compare`,
`reason-multihop`. No idiom classification exists yet for these
failures — this is a raw pass/fail count only, not steered.
`reports/report-reason-20260913-185856.md`.

## Tool-use role

6/6 PASS, bare, single draw. No failures at n=1.
`reports/report-tool-20260913-185926.md`.

## Extract role

6/6 PASS, bare, single draw. No failures at n=1.
`reports/report-extract-20260913-185937.md`.

## Review role

4/6 PASS, bare, single draw. Real failures: `review-null`,
`review-logic`. Idiom classification not done yet.
`reports/report-review-20260913-185948.md`.

## Code-emitter role

14/14 PASS, bare, single draw (13 C# + 1 Python task), real
compile+test via `bench.sh`. `reports/report-code-20260913-190003.md`.

## How to optimize (verify before trusting)

- Reasoner, tool-use, extract, review, code-emitter: nothing steered
  yet — every number above is a bare, single-draw baseline. No idioms
  confirmed. Before trusting any of these as stable, run at least a
  3-draw Confirm on each role, per the methodology in `AGENTS.md`.
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

- Served by `llama-chat.service` on `legion-t5` (`192.168.2.133:11434`),
  the same service and port previously used for `qwen3.5:9b` — swapped in
  place 2026-09-13. Reachable two ways, confirmed live the same day:
  - **Direct**: `DISPATCH_HOST=192.168.2.133 LLAMACPP_PORT=11434` (the
    `DISPATCH_HOST` override, no SSH tunnel needed). This replaces the
    earlier `llama-chat-4b-gsq.service` / port `11436` / tunnel setup
    below, now stale. No entry needed in `ALLOWED_MODELS` beyond the
    existing `qwen3.5-4b-gsq` whitelist line.
  - **Via `ai-stack/litellm-router`**, model_name `qwen3.5-9b-local` — a
    real naming catch, same pattern as `qwen3.8-27b-gsq-rco` and
    `qwen3.8-27b-local`: the router never learned the real name of this
    model, only the tier name it swapped into. `DISPATCH_BACKEND=litellm
    bash bench/report.sh qwen3.5-9b-local <role>` reaches this exact
    model; `qwen3.5-4b-gsq` does not.
- `--ctx-size 245760 --parallel 2 --kv-unified --flash-attn on
  --cache-type-k q8_0 --cache-type-v q8_0 -ngl 99`. Real, tested max for this
  model on this 8 GiB RTX 3060 Ti, two slots, one shared KV pool — see
  `ai-stack/litellm-router` session history, 2026-09-13, for the empirical
  derivation (262144, the model's own native ceiling, only fits when
  `embed-local` holds zero VRAM, which is not this box's normal running
  state — its CPU-mode residual footprint, about 158 MiB, is enough to push
  262144 into a real, confirmed CUDA out-of-memory).
- Whitelisted in `bench/dispatch.sh` as `qwen3.5-4b-gsq` for direct
  backends. `DISPATCH_BACKEND=litellm` skips that gate — the real gate
  for that path is the `config.yaml` file in `ai-stack/litellm-router`.
- **Required dispatch overrides — mandatory, not optional, per `AGENTS.md`'s
  "every dispatch-level tweak must be documented" rule:**
  - `DISPATCH_REASONING_EFFORT=none` — confirmed live 2026-09-13 as
    mandatory for a direct dispatch: this model defaults to thinking on,
    and a first full-test run without this set lost 16,384 tokens per
    task to `reasoning_content` before any real answer, on every task
    (docs role alone came back 4/9, unusable). Same field
    `litellm-router/config.yaml` already bakes into the `qwen3.5-9b-local`
    tier, so a litellm-routed call needs no override — a direct call
    does. `DISPATCH_ENABLE_THINKING=false` (the older boolean control)
    also works but is redundant with this; set only one, never both —
    `bench/dispatch.sh` errors if both are set.
  - `DISPATCH_HW_LABEL="legion-t5, RTX 3060 Ti 8GB, ctx=245760 parallel=2 kv-unified"`.
    Set this on every dispatch against this host. Do not compare its tok/s
    against a report for a different model unless the Hardware line
    matches.
- Full reproducible invocation for a full 6-role test (2026-09-13, real,
  used to produce the numbers above for every non-Documenter role):
  ```
  DISPATCH_TEMPERATURE=0.2 DISPATCH_REASONING_EFFORT=none \
    bash bench/full-test.sh qwen3.5-4b-gsq llamacpp 11434 192.168.2.133
  ```
  A single-role invocation follows the same pattern via `bench/report.sh`,
  e.g.:
  ```
  DISPATCH_HOST=192.168.2.133 LLAMACPP_PORT=11434 \
    DISPATCH_REASONING_EFFORT=none \
    DISPATCH_HW_LABEL="legion-t5, RTX 3060 Ti 8GB, ctx=245760 parallel=2 kv-unified" \
    bash bench/report.sh qwen3.5-4b-gsq docs
  ```

## Further reading

- `history.md` — running narrative for this model's testing.
- `reports/` — raw per-run reports.
- [`qwen3.5-4b`](../qwen3.5-4b/) — same base model, different quantization,
  own separate steering profile.
