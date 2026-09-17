# minicpm5-2b — steering profile

`openbmb/MiniCPM5-2B`, official GGUF release (`openbmb/MiniCPM5-2B-GGUF`,
`Q4_K_M`, 1.56 GB). This model runs on `legion-t5` (`192.168.2.133`), not
on this machine. `bench/dispatch.sh` reaches it over an SSH tunnel. Every
task uses the real `SPEC.md` and `verify.sh`, as for every other model.
Only the transport is different.

## Overview

State on 2026-09-17: one bare re-run, then one `bench/loop.sh` steering
pass per role, then a 3-draw Confirm per role.

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Tool-use | ✅ Confirmed — `tool-error` fixed by a per-task override | 9/10 → 10/10 (Confirm 10, 10, 10) | Not assessed | [Tool-use role](#tool-use-role-confirmed-2026-09-17) |
| Extract | ⚠️ Flaky — no confirmed steering gain | 8/10 → 9 to 10/10 (Confirm 9, 10, 9) | Not assessed | [Extract role](#extract-role-flaky-2026-09-17) |
| Review | ⚠️ Flaky — no confirmed steering gain | 7/10 → 6 to 8/10 (Confirm 7, 8, 6) | Not assessed | [Review role](#review-role-flaky-2026-09-17) |
| Code-emitter | ⚠️ Flaky — no confirmed steering gain, config is bare | 11/14 → 9 to 11/14 (Confirm 11, 9, 10) | Not assessed | [Code-emitter role](#code-emitter-role-flaky-2026-09-17) |
| Reasoner | ⚠️ Flaky — no confirmed steering gain, weakest role | 5/10 → 5 to 6/10 (Confirm 6, 6, 5) | Not assessed | [Reasoner role](#reasoner-role-flaky-2026-09-17) |
| Documenter | ⚠️ Flaky — no confirmed steering gain | 5/10 → 6 to 7/10 (Confirm 7, 6, 6) | Not assessed | [Documenter role](#documenter-role-flaky-2026-09-17) |
| Visual | Not attempted | — | — | [Visual role](#visual-role-not-attempted) |

**Read these numbers with 3 limits:**

1. **"Bare" is not fully bare.** `bench/pure-run.sh` uses
   `task-overrides/<task>.md` when that file exists. The bare column is
   the 2026-09-17 re-run (45/64). In that run, 10 tasks used overrides
   from 2026-09-12: `doc-verbatim`, `reason-checklist`, `reason-trace`,
   `reason-consequence`, `reason-compare`, `reason-multihop`,
   `extract-basic`, `extract-nested`, `extract-optional`,
   `review-concurrency`. The 2026-09-16 run had the same 10 overrides.
2. **Variance is larger than the steering effect.** Between draws of one
   unchanged config, 2 to 3 tasks per role change verdict. The code-emitter
   Confirm ran a fully bare config and still gave 11, 9 and 10 of 14.
3. **Only tool-use has a confirmed gain.** The other 5 roles got a FLAKY
   Confirm verdict. The user decision is to report them as measured, with
   no revert rounds.

"vs. mainstream LLM" is not assessed for any role. No frontier model ran
this 10-task suite, so this repo has no grounded comparison.

## Tool-use role: confirmed 2026-09-17

**Usability without optimizations**: 9/10 bare. `tool-error` failed in
all 3 bare runs (2026-09-16 thinking on, 2026-09-16 thinking off,
2026-09-17).

**Usability with optimizations**: 10/10 in all 3 Confirm draws. Verdict
CONFIRMED. The override targets a "question echo" idiom: the model copied
the two question lines back and gave no answer.

**Comparison against a mainstream LLM**: not assessed.

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `tool-error` | ✅ Fixed in round 1, 3/3 at Confirm | [`task-overrides/tool-error.md`](task-overrides/tool-error.md) | Tier 2 gate GO (10/10), not run — n/a |
| other 9 tasks | ✅ 3/3 at Confirm, no steering needed | bare | n/a |

Evidence: [`reports/confirm-tool-20260917-082715.md`](reports/confirm-tool-20260917-082715.md).

## Extract role: flaky, 2026-09-17

**Usability without optimizations**: 8/10 on 2026-09-17, 9/10 on
2026-09-16. On 2026-09-17, `extract-basic` and `extract-optional` failed.

**Usability with optimizations**: 9, 10 and 9 of 10 at Confirm. Verdict
FLAKY. Only `extract-optional` varies. It passes 1 of 3 draws. 9 tasks
passed every draw, and no task failed every draw.

**Comparison against a mainstream LLM**: not assessed.

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `extract-basic` | ✅ 3/3 at Confirm. The same override failed in the bare re-run and in round 1. | [`task-overrides/extract-basic.md`](task-overrides/extract-basic.md) (2026-09-12) | Tier 2 gate GO (9/10), not run — n/a |
| `extract-optional` | ⚠️ 1/3 at Confirm. Gated out after round 2. | bare | not run — n/a |
| `extract-invalid` | ✅ 3/3 at Confirm. Bare also passed on 2026-09-16 and 2026-09-17. | [`task-overrides/extract-invalid.md`](task-overrides/extract-invalid.md) (round 3) | not run — n/a |
| `extract-nested` | ✅ 3/3 at Confirm. Failed once, in round 2. | [`task-overrides/extract-nested.md`](task-overrides/extract-nested.md) (2026-09-12) | not run — n/a |
| other 6 tasks | ✅ 3/3 at Confirm | bare | n/a |

Evidence: [`reports/confirm-extract-20260917-083623.md`](reports/confirm-extract-20260917-083623.md).

## Review role: flaky, 2026-09-17

**Usability without optimizations**: 7/10 on 2026-09-17 and on
2026-09-16. The failing tasks were not the same in the 2 runs.

**Usability with optimizations**: 7, 8 and 6 of 10 at Confirm. Verdict
FLAKY. 3 tasks vary. `review-swallow` and `review-multi` failed every
draw.

**Comparison against a mainstream LLM**: not assessed.

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `review-async` | ✅ 3/3 at Confirm. Bare failed (truncated) on 2026-09-16 and 2026-09-17. | [`task-overrides/review-async.md`](task-overrides/review-async.md) (round 1) | Tier 2 gate GO (6/10), not run — n/a |
| `review-clean` | ✅ 3/3 at Confirm. Bare passed on 2026-09-17 and failed in round 3. | [`task-overrides/review-clean.md`](task-overrides/review-clean.md) (round 4) | not run — n/a |
| `review-concurrency` | ⚠️ 2/3 at Confirm, draw 3 truncated | [`task-overrides/review-concurrency.md`](task-overrides/review-concurrency.md) (2026-09-12) | not run — n/a |
| `review-decoy` | ⚠️ 2/3 at Confirm, draw 3 truncated. Bare passed on 2026-09-16 and 2026-09-17. | [`task-overrides/review-decoy.md`](task-overrides/review-decoy.md) (round 3) | not run — n/a |
| `review-dispose` | ⚠️ 2/3 at Confirm, draw 1 truncated. Bare passed on 2026-09-16 and 2026-09-17. | [`task-overrides/review-dispose.md`](task-overrides/review-dispose.md) (round 2) | not run — n/a |
| `review-swallow` | ❌ 0/3, truncated at 16384 tokens in every draw. Gated out after round 2. | bare | not run — n/a |
| `review-multi` | ❌ 0/3. Gated out after round 2. | bare | not run — n/a |
| `review-null`, `review-offbyone`, `review-logic` | ✅ 3/3 at Confirm | bare | n/a |

Evidence: [`reports/confirm-review-20260917-093901.md`](reports/confirm-review-20260917-093901.md).

## Code-emitter role: flaky, 2026-09-17

**Usability without optimizations**: 11/14 on 2026-09-17 and on
2026-09-16. `code-csharp-batch`, `code-csharp-events` and
`code-csharp-workflow` failed in both runs.

**Usability with optimizations**: none kept. Shared `csharp-rules.md` and
`python-rules.md` files gave 10/14 in round 1 and round 2. The loop gated
both out, so the Confirm config is fully bare. Confirm gave 11, 9 and 10
of 14. Verdict FLAKY.

**Comparison against a mainstream LLM**: not assessed.

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `code-csharp-batch` | ❌ 0/3 at Confirm | bare (rules gated out after round 2) | Tier 2 gate GO (10/14), not run — n/a |
| `code-csharp-events` | ❌ 0/3 at Confirm, draw 3 truncated | bare (rules gated out) | not run — n/a |
| `code-csharp-workflow` | ❌ 0/3 at Confirm | bare (rules gated out) | not run — n/a |
| `code-csharp-httpclient` | ⚠️ 1/3 at Confirm | bare | not run — n/a |
| `code-csharp-tool` | ⚠️ 2/3 at Confirm | bare | not run — n/a |
| `code-python-auth` | ✅ 3/3 at Confirm. Failed in round 1 (no Python rules) and in round 2 (with `python-rules.md`). | bare (rules gated out) | n/a |
| other 8 C# tasks | ✅ 3/3 at Confirm | bare | n/a |

Evidence: [`reports/confirm-code-20260917-101621.md`](reports/confirm-code-20260917-101621.md).

## Reasoner role: flaky, 2026-09-17

**Usability without optimizations**: 5/10 on 2026-09-17, 4/10 on
2026-09-16. Both runs used 2026-09-12 overrides on 5 of the 10 tasks, see
the Overview limits.

**Usability with optimizations**: 6, 6 and 5 of 10 at Confirm. Verdict
FLAKY. 3 tasks vary, and 3 tasks failed every draw.

**No confirmed regression.** The 2026-09-16 README called 4/10 a real
regression from 7/9 on 2026-09-12. Both numbers are single draws. Both
runs used the same overrides for `reason-trace` and `reason-consequence`.
The 2026-09-12 3-draw check of those overrides gave only 0/3 and 1/3. The
7/9 draw is therefore not a stable reference.

**Comparison against a mainstream LLM**: not assessed.

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `reason-coverage` | ✅ 3/3 at Confirm, and a PASS in all 4 rounds. Bare truncated at 16384 tokens on 2026-09-16 and 2026-09-17. | [`task-overrides/reason-coverage.md`](task-overrides/reason-coverage.md) (round 1) | Tier 2 gate GO (6/10), not run — n/a |
| `reason-config-validity` | ⚠️ 2/3 at Confirm | [`task-overrides/reason-config-validity.md`](task-overrides/reason-config-validity.md) (round 2) | not run — n/a |
| `reason-consequence` | ⚠️ 1/3 at Confirm | [`task-overrides/reason-consequence.md`](task-overrides/reason-consequence.md) (2026-09-12) | not run — n/a |
| `reason-multihop` | ⚠️ 2/3 at Confirm, draw 3 truncated | [`task-overrides/reason-multihop.md`](task-overrides/reason-multihop.md) (2026-09-12) | not run — n/a |
| `reason-checklist` | ❌ 0/3 at Confirm, 2 draws truncated | [`task-overrides/reason-checklist.md`](task-overrides/reason-checklist.md) (2026-09-12) | not run — n/a |
| `reason-compare` | ❌ 0/3 at Confirm. Failed in every run since 2026-09-12. | [`task-overrides/reason-compare.md`](task-overrides/reason-compare.md) (2026-09-12) | not run — n/a |
| `reason-trace` | ❌ 0/3 at Confirm. The 2026-09-12 override was gated out after round 2. | bare | not run — n/a |
| `reason-diagnose`, `reason-priority`, `reason-tradeoff` | ✅ 3/3 at Confirm | bare | n/a |

Evidence: [`reports/confirm-reason-20260917-105239.md`](reports/confirm-reason-20260917-105239.md).

## Documenter role: flaky, 2026-09-17

**Usability without optimizations**: 5/10 on 2026-09-17 and on
2026-09-16. The failing tasks were not the same in the 2 runs.

**Usability with optimizations**: 7, 6 and 6 of 10 at Confirm. Verdict
FLAKY. 2 tasks vary, and 3 tasks failed every draw. The Tier 2 gate gave
SKIP (5/10 specialist hit rate).

**Comparison against a mainstream LLM**: not assessed.

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-adapt` | ✅ 3/3 at Confirm, and a PASS in all 4 rounds. Bare failed on 2026-09-16 and 2026-09-17. | [`task-overrides/doc-adapt.md`](task-overrides/doc-adapt.md) (round 1) | Tier 2 gate SKIP (5/10) — no generalist, n/a |
| `doc-script` | ✅ 3/3 at Confirm, and a PASS in all 4 rounds. Bare failed on 2026-09-16 and 2026-09-17 (truncated). | [`task-overrides/doc-script.md`](task-overrides/doc-script.md) (round 1) | n/a |
| `doc-restructure` | ⚠️ 2/3 at Confirm, draw 3 truncated. Bare passed on 2026-09-16 and 2026-09-17. | [`task-overrides/doc-restructure.md`](task-overrides/doc-restructure.md) (round 3) | n/a |
| `doc-surgical` | ⚠️ 2/3 at Confirm. Bare passed on 2026-09-17. | [`task-overrides/doc-surgical.md`](task-overrides/doc-surgical.md) (round 3) | n/a |
| `doc-verbatim` | ❌ 0/3 at Confirm, 2 draws truncated | [`task-overrides/doc-verbatim.md`](task-overrides/doc-verbatim.md) (2026-09-12) | n/a |
| `doc-repair` | ❌ 0/3, truncated in every draw. Round 1 override gated out after round 2. | bare | n/a |
| `doc-audience` | ❌ 0/3, draw 1 truncated. Round 1 override gated out after round 2. Bare passed on 2026-09-16. | bare | n/a |
| `doc-synthesize` | ✅ 3/3 at Confirm. Bare failed on 2026-09-16. | bare | n/a |
| `doc-summarize`, `doc-crossref` | ✅ 3/3 at Confirm | bare | n/a |

Evidence: [`reports/confirm-docs-20260917-115158.md`](reports/confirm-docs-20260917-115158.md).

## Visual role: not attempted

`legion-t5` has no `mmproj` vision projector for this model, only the
text GGUF. `report.sh` has no `visual` role.

## How to optimize (verify before trusting)

- **Tool-use**: use `task-overrides/tool-error.md`. This is the only
  confirmed steering gain for this model.
- **Keep thinking on** (the default). Blanket
  `DISPATCH_ENABLE_THINKING=false` made every role worse on 2026-09-16:
  docs 4/10, reason 3/10, tool 8/10, extract 9/10 (no net gain), review
  4/10, code 8/14. Many of those answers were near-empty (12 to 66
  tokens).
- **Per-task thinking off is not a general fix.** On 2026-09-16 (single
  draw) it fixed `extract-basic` and `review-clean`. On `doc-verbatim`,
  `doc-repair`, `review-async` and `review-swallow` it removed the
  truncation, but a real content defect stayed. On `reason-coverage` it
  did not remove the truncation. The 2026-09-17 runs used no per-task
  thinking override.
- **Truncation at the 16384-token completion cap** is the main failure
  shape of the tasks that still fail: `review-swallow` (3 of 3 Confirm
  draws), `doc-repair` (3 of 3), `doc-verbatim` (2 of 3),
  `reason-checklist` (2 of 3). `reason-coverage` stopped truncating with
  its override. A truncated answer has empty visible content. `--ctx-size`
  is not the lever: the largest prompt was 1,328 tokens.
- **Measure with at least 3 draws.** One unchanged config changes 2 to 3
  verdicts per role between draws. A single-draw PASS or FAIL does not
  show a fix or a regression for this model.
- **Candidate overrides, not confirmed at role level**: `doc-adapt`,
  `doc-script`, `reason-coverage` and `review-async` failed bare and
  passed all 3 Confirm draws. The first 3 also passed all 4 rounds.
  `review-async` failed once, in round 2. Their roles got a FLAKY
  verdict, so these gains are not confirmed.
- **Do not use a shared rules file for code-emitter.** `csharp-rules.md`
  and `python-rules.md` gave 10/14 in 2 rounds against 11/14 bare.
- **Tier 2 generalist search is not done.** The gate gave GO for
  extract (9/10), review (6/10), code-emitter (10/14) and reasoner (6/10).
  Nobody ran the search. Documenter gave SKIP (5/10).
- **Still open after steering**: `reason-compare` (fails in every run
  since 2026-09-12), `reason-trace`, `reason-checklist`, `doc-verbatim`,
  `doc-repair`, `doc-audience`, `review-swallow`, `review-multi`,
  `code-csharp-batch`, `code-csharp-events`, `code-csharp-workflow`.

## Setup

Setup of the 2026-09-17 bare re-run, steering pass and Confirm. The
host was put back to production after the run.

- **Host**: `legion-t5` (`192.168.2.133`), RTX 3060 Ti 8 GB.
- **Shared GPU**: `qwen3.5-4b-gsq` (`llama-chat.service`) kept serving
  `litellm-router`. A temporary systemd drop-in set `--parallel 1
  --ctx-size 122880` for the run.
- **Model server**: a temporary unit `llama-minicpm5-test`, started with
  `systemd-run`:
  ```
  /opt/llama.cpp/llama-server --model /opt/models/minicpm5-2b.gguf \
    --alias minicpm5:2b --host 0.0.0.0 --port 11437 --ctx-size 32768 \
    --parallel 1 --n-gpu-layers 99 --flash-attn on --jinja
  ```
- **Transport**: `legion-t5`'s ufw blocks port 11437. Dispatch used an SSH
  tunnel: `ssh -N -L 18437:localhost:11437 legion`.
- **Invocation**:
  ```
  DISPATCH_HW_LABEL="legion-t5, RTX 3060 Ti 8 GB, GPU shared with qwen3.5-4b-gsq (llama-chat --parallel 1 --ctx-size 122880, live litellm traffic); minicpm5:2b llama-server --ctx-size 32768 --parallel 1 -ngl 99 --flash-attn on --jinja, port 11437 via SSH tunnel localhost:18437; tok/s not comparable with solo-GPU runs" \
    bash bench/report.sh minicpm5:2b <role> llamacpp 18437 localhost
  bash bench/loop.sh minicpm5:2b <role> 4 llamacpp 18437
  ```
  Use the same `DISPATCH_HW_LABEL` for `loop.sh`.
- **Restart**: `report.sh` restarts only local units. A wrapper restarted
  `llama-minicpm5-test` on `legion-t5` before each role.
- **Sampling**: no `DISPATCH_*` sampling or thinking override.
  `dispatch.sh` defaults apply: `temperature` 0.2, thinking on.
- **Why `--ctx-size 32768` is valid**: the largest prompt was 1,328
  tokens. Prompt plus the 16384-token completion cap stays below 32768.
  `docs/POWER-AND-COST.md` (2026-09-17) shows that `--ctx-size` does not
  change the output for prompts up to 12k tokens. That test used the
  qwen models, not this model. It gave byte-identical answers at 3
  context sizes.
- **VRAM**: 7,701 of 8,192 MiB during the run, no out-of-memory error.
- **Speed**: about 187 tok/s generation. Do not compare this with
  solo-GPU runs. The GPU was shared, and the ctx and parallel flags
  differ from the 2026-09-12 runs.
- **Revert after the run**: `qwen3.5-4b-gsq` went back to `--parallel 2
  --ctx-size 245760`. The temporary unit and the drop-in were removed.
  The tunnel was closed.
- **Whitelist**: `bench/dispatch.sh` `ALLOWED_MODELS` has a permanent
  `"minicpm5:2b"` entry.
- **Raw outputs of the bare re-run**: `raw/20260917-bare/` (the 50
  non-code tasks).

The 2026-09-12 and 2026-09-16 runs used other server setups (port 11434,
`qwen3.5` stopped, ctx 32768 or 131072). `history.md` has those details.

## Further reading

- [`history.md`](history.md) — full narrative: 2026-09-12 baseline and
  steering, 2026-09-16 expanded suite, 2026-09-17 re-run, steering pass
  and Confirm.
- [`reports/`](reports/) — raw per-run reports and Confirm files.
- `research-<role>.md` — cross-model idiom research of the 2026-09-17
  steering pass.
