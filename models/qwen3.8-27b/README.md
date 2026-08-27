# qwen3.8-27b — steering profile

**Not tested via this repo's usual dispatch path.** This model is served
through `ai-stack/litellm-router` (model alias `local-first`), a remote
OpenAI-compatible gateway — not a local llama-server/ollama instance on
this machine, which is what `bench/dispatch.sh`'s `llamacpp`/`ollama`
backends assume. Results below came from a standalone runner
(`qwen_router_bench.py`, not checked into this repo — ran from a Claude
Code session's scratchpad) that reuses this repo's real `SPEC.md`/
`verify.sh` per task, POSTs to the router directly, and parses the same
`VERDICT: PASS/FAIL` convention. Genuinely comparable results, different
transport — not run through `bench/pure-run.sh`/`bench.sh` themselves.
See `history.md` for why, and what proper `dispatch.sh` integration
would need (a third backend mode) if this model gets tested further.

**Phase 1 baseline only** (bare, single draw, default sampling —
`temperature=0.2`, no steering, no `enable_thinking` override tried).
Not a closed quality loop — no Research/Steering/Confirm phases run.

## Overview

| Role | Status | Pass rate (bare) | Details |
|---|---|---|---|
| Documenter | ✅ Strong bare baseline | 9/9 | [Documenter](#documenter-role) |
| Tool-use | ✅ Strong bare baseline | 6/6 | [Tool-use](#tool-use-role) |
| Review | ✅ Strong bare baseline | 6/6 | [Review](#review-role) |
| Reasoner | ⚠️ Mixed bare baseline | 6/9 | [Reasoner](#reasoner-role) |
| Code-emitter | 🚧 Not tested | — | Needs the build+test harness (`tasks/code-csharp-*/harness/`), not just `verify.sh` — out of scope for this pass, see history.md |
| Extract | 🚧 Not tested | — | Not attempted this pass |

**Single draw throughout (n=1) — not a reliability sample.** Every rate
above could look different on a second draw; no task was re-run to check
stability. Treat "6/9" etc. as "this is what one bare attempt looked
like," not a measured pass rate.

## Documenter role

9/9 PASS, bare, single draw. The strongest bare-baseline documenter
result of any model in this repo by a wide margin — every `qwen3.5`
variant (0.8b through 9b) needed steering to get even partway there (best
bare baseline in that family was `qwen3.5-9b` at 5/9, and even that took
a full quality loop to reach 8/9 stable). At 27B, this suite needed no
steering at all on a first pass.

## Tool-use role

6/6 PASS, bare, single draw. **First real small/local-model result
against this suite** — `models/README.md`'s "no real small-model run
yet" line for tool-use predates this. Directly relevant to
`local-llm-first`'s own stated gap ("No published data on tool-calling
reliability specifically, so treat that as unproven") — this is now a
real data point, though still single-draw.

## Review role

6/6 PASS, bare, single draw. Found the seeded bug and named the specific
mechanism (not just "there might be an issue") on every task, including
the async/concurrency-flavored ones that are usually the hardest review
shape.

## Reasoner role

6/9 PASS, bare, single draw. **Three real, specific failures — not a
generic "reasoning is weak":**

- **`reason-config-validity`: FAIL** — required tokens present, but two
  *hallucinated, unrelated* tokens also present (`idField`, `tokenTemplate`
  — not real fields in the source doc). Over-generation, not a missed
  fact: the model added plausible-sounding config keys that don't exist.
- **`reason-multihop`: FAIL** — both reasoning hops present and correct
  in substance, but hop 2 doesn't name `entities.company` specifically —
  a precision/specificity miss on an otherwise-correct multi-hop chain,
  not a broken chain.
- **`reason-tradeoff`: FAIL** — gave the utility side of a two-sided
  tradeoff plus an explicit recommendation, but omitted the privacy side
  entirely. Partial-credit miss (one side of two), not a missed tradeoff
  concept.

**Pattern across all three: partial/imprecise, not wrong-headed.** Every
failure got the core reasoning right and lost on a specific missing or
hallucinated detail — worth keeping in mind before assuming a reasoning
delegation failure means the model "doesn't understand" the problem.

## Setup

Not applicable in the usual sense (no local systemd unit / `-ngl`
tuning) — this is a remote endpoint. Router: `http://192.168.2.183:4000/
v1/chat/completions`, model alias `local-first`, `Authorization: Bearer
${LITELLM_MASTER_KEY}` (see `~/.env`). See `local-llm-first` Claude Code
skill for the full deployment description and the "verify it's actually
live before delegating" check.
