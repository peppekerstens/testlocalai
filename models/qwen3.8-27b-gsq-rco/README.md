# qwen3.8-27b-gsq-rco — steering profile

Full model file: `Qwen3.8-27B-GSQ-RCO-IQ3_S-mtp` (ISTA-DASLab, ~3.4
bits/weight, MTP head bundled), served on `gaming-b650` as
`llama-chat.service`'s production model. Reached only through
`ai-stack/litellm-router`, never dispatched to directly — see "Setup"
below for the one real naming catch this causes.

**Role: all 6 report.sh-compatible roles** (`tasks/doc-*`, `tasks/reason-*`,
`tasks/tool-*`, `tasks/extract-*`, `tasks/review-*`, `tasks/code-*`),
first tested 2026-09-13.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — strong bare baseline, 2026-09-13 | 9/9 bare | Not assessed | [Documenter role](#documenter-role) |
| Reasoner | 🔬 Preliminary — 3 real failures, 2026-09-13 | 6/9 bare | Not assessed | [Reasoner role](#reasoner-role) |
| Tool-use | 🔬 Preliminary — clean bare pass, 2026-09-13 | 6/6 bare | Not assessed | [Tool-use role](#tool-use-role) |
| Extract | 🔬 Preliminary — clean bare pass, 2026-09-13 | 6/6 bare | Not assessed | [Extract role](#extract-role) |
| Review | 🔬 Preliminary — clean bare pass, 2026-09-13 | 6/6 bare | Not assessed | [Review role](#review-role) |
| Code-emitter | 🔬 Preliminary — clean bare pass, 2026-09-13 | 14/14 bare | Not assessed | [Code-emitter role](#code-emitter-role) |

## Documenter role

9/9 PASS, bare, single draw. No failures at n=1. Not yet steered — no
tasks needed it.

## Reasoner role

6/9 PASS, bare, single draw. Real failures: `reason-config-validity`,
`reason-multihop`, `reason-tradeoff`. Idiom classification against each
task's own failure idiom is not done yet — this is a raw pass/fail
count only, not steered.

## Tool-use role

6/6 PASS, bare, single draw. No failures at n=1.

## Extract role

6/6 PASS, bare, single draw. No failures at n=1.

## Review role

6/6 PASS, bare, single draw. No failures at n=1.

## Code-emitter role

14/14 PASS, bare, single draw (12 C# + 2 Python tasks), real
compile+test via `bench.sh`. First real result for this role on this
machine. The initial run here showed 1/14 because `dotnet` was not
installed at all. Installing it (`dotnet-install.sh --channel 8.0`,
user-local, no sudo) and rerunning gave this real number.

## How to optimize (verify before trusting)

Nothing steered yet — every role above is a bare, single-draw baseline.
No idioms confirmed. Before trusting any of these numbers as stable,
run at least a 3-draw Confirm on each role, per this project's own
methodology (see `AGENTS.md`).

## Setup

- Served by `llama-chat.service` on `gaming-b650`, port `11434`
  (GSQ-RCO quant, llama.cpp), reached here via
  `ai-stack/litellm-router`'s `qwen3.8-27b-local` model_name, not
  directly. Real serving config, real speed numbers, and the parallel
  2-slot setup: `ai-stack/gaming-b650-llamacpp/README.md`.
- Downloaded 2026-09-13:
  [`ISTA-DASLab/Qwen3.8-27B-GSQ-RCO-GGUF`](https://huggingface.co/ISTA-DASLab/Qwen3.8-27B-GSQ-RCO-GGUF),
  `Qwen3.8-27B-GSQ-RCO-IQ3_S-mtp.gguf`, 12.1 GB.
- Not in `bench/dispatch.sh`'s `ALLOWED_MODELS` list, and does not need
  to be — `DISPATCH_BACKEND=litellm` skips that gate entirely (the
  router's own `config.yaml` is the real gate for this path).
- **Naming catch, real, not yet fully solved**: `litellm-router` knows
  this model only as `qwen3.8-27b-local` (its model_name), never as
  `qwen3.8-27b-gsq-rco`. Dispatch commands MUST use that name:
  `DISPATCH_BACKEND=litellm bash bench/report.sh qwen3.8-27b-local
  <role>`, or `bash bench/full-test.sh qwen3.8-27b-local litellm` for
  every role at once. `report.sh`/`pure-run.sh` derive the results
  directory directly from that dispatch argument, with no override
  option today — a fresh run lands in `models/qwen3.8-27b-local/`, not
  here. Move its `reports/` and any new `round-*.md` files into this
  directory by hand after every run, until dispatch.sh gains a real
  directory-override option.
- No mandatory `DISPATCH_*` overrides found yet — every role above ran
  with dispatch.sh's own defaults (`DISPATCH_TEMPERATURE=0.2`).

## Further reading

- `history.md` — not started yet; nothing has been steered.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run raw evidence (`bash bench/report.sh
  qwen3.8-27b-local <role> litellm`).
