# Landscape comparison — why this isn't just another eval harness

Researched 2026-08-17, prompted by discovering PinchBench and
llama-bench and wanting to know whether this project duplicates
something that already exists. Short answer: no — see "Assessment"
below. This doc is the durable record of that research, referenced
from the root `README.md`'s "Where this fits in the optimization
spectrum" section.

## What each surveyed tool actually is

| Tool | What it measures | Local-model support | Scoring | Produces a steering guide? |
|---|---|---|---|---|
| **llama-bench** (llama.cpp built-in) | Pure throughput: tok/s for prompt-eval and generation, at different context/batch/GPU-layer configs | Yes — it *is* the llama.cpp perf tool | N/A — no correctness dimension at all | No |
| **llama-benchy** | Same idea as llama-bench, generalized to vLLM/SGLang/llama.cpp | Yes | N/A — still pure speed | No |
| **PinchBench** (Kilo.ai) | Agent task success (53 tasks / 8 categories: productivity, research, writing, coding, analysis, email, memory, skills) for a model acting as "the brain of an OpenClaw agent" | Indirect only — requires a running OpenClaw instance as a hard dependency; OpenClaw itself supports llama.cpp/Ollama, but PinchBench's own docs never mention pointing at a local endpoint directly | Automated + LLM-judge (mix undocumented per-task), public leaderboard (success rate, speed, cost) | No — it's a comparative leaderboard, not a fix-this-model tool |
| **Harness-Bench** (neuralnoise.com, WIP) | 17 quantized local LLMs × 5 coding-agent harnesses (Aider, Claude Code, OpenCode, Qwen CLI, Pi) on 16 real SWE tasks, hidden `test.sh` grading in a sandboxed workspace | Yes — this is its whole point | Hidden-test pass/fail, matrix + Pareto speed/accuracy frontier | **Explicitly the opposite** — it standardizes flags identically across every model precisely to keep comparisons fair; no per-model prompt tuning allowed |
| **lm-evaluation-harness** (EleutherAI) | Standard academic benchmarks — MMLU, HellaSwag, BIG-bench, etc. — via few-shot log-likelihood scoring | Yes, any HF/local backend | Fixed-dataset accuracy | No — raw knowledge/reasoning capability, not real-world task correctness |
| **promptfoo** | General config-driven eval framework: providers (Ollama, llama.cpp, APIs), assertions, LLM-graded checks, sandboxed code eval | Yes, well-supported (dedicated Ollama/llama.cpp provider docs) | Assertion-based, pass/fail + score | No — it's plumbing you *could* build a steering workflow on top of, but ships none itself |
| DeepEval / OpenAI Evals / Inspect / HELM (surveyed, not deep-dived) | General-purpose LLM output testing (RAG, agents, hallucination, etc.) | Varies, generally yes | Metric libraries / model-graded | No |

A targeted search specifically for "per-model prompt/decoding steering"
tooling against a curated evals-tools list came back empty — the only
"steering" hits in that space are *activation steering* (editing
internal model activations at inference time, a research technique),
which is unrelated to the prompt/decoding-config steering this project
does.

## PinchBench deep-dive — is it expandable to this project's use case?

Revisited 2026-08-17 after a closer look, since of everything surveyed
it looked the most mature (1.3k stars, 383 commits, real automated
grading, `--suite`-based extensibility for adding new tasks). The
actual runner lives in `pinchbench/skill` (Python, `uv`-managed), not
the `leaderboard`/`api` repos, which are just the pinchbench.com
frontend.

**The blocker: OpenClaw is a mandatory intermediary, not an optional
provider.** PinchBench's own Requirements list "a running OpenClaw
instance" — every task runs the model *through* OpenClaw's agent loop
(its own system prompts, tool definitions, memory/skills system), not
as a direct prompt-in/text-out call PinchBench controls. OpenClaw
itself does support local backends (llama.cpp, Ollama, LM Studio, vLLM
providers, per its own docs) so a local model could theoretically sit
underneath — but PinchBench never documents that path, and more
importantly it wouldn't matter: this project's entire method is
precise control over prompt content, sampling params, and decoding
constraints, which is exactly what routing through someone else's
agent scaffolding takes away. You'd be steering OpenClaw's prompt, not
the model's.

**Task-domain overlap is thin.** PinchBench's 8 categories are
personal-assistant-shaped (calendar, email triage, daily summaries,
stock/market research, memory retrieval) versus this project's
dev-tool-shaped roles (compile-and-test C# code, edit real project docs
verbatim, pick the right MCP tool call, find a seeded bug without
rewriting). Only "coding" and parts of "analysis"/"research" brush up
against Code-emitter/Reasoner/Extract — Documenter, Review, and
Tool-use (in the "match this repo's real `TOOL_CONTRACTS.md`" sense)
have no equivalent. Adopting PinchBench's schema would mean authoring
nearly the entire task suite fresh anyway, in a schema built for a
different kind of task.

**Grading rigor is a step down, not up, for this project's standard.**
"Evidence over assumption" here means a real build+test or exact-diff
result backs every claim. PinchBench mixes in LLM-judge grading for
much of its 53 tasks (the docs don't specify the split), which is
inherently softer than this project's C#-compiles-and-passes-tests or
doc-verbatim-diff verdicts.

**No steering loop exists there either.** Same conclusion as the rest
of the landscape (see "What's actually different here" below) — even
in the best case, the Tier 1/Tier 2/Confirm search process would need
to be built from scratch on top of it.

**Net: expandable in principle, not worth it in practice.** Getting
PinchBench to test a local quantized model would require (a) wiring
OpenClaw itself to a local backend, (b) accepting that the model is
being tested with OpenClaw's scaffolding wrapped around it rather than
this project's own controlled prompt, (c) authoring an almost entirely
new task suite in PinchBench's schema to cover the dev-tool roles this
project actually cares about, and (d) building the steering loop from
scratch anyway on top of two new heavyweight dependencies (PinchBench's
Python/`uv` stack, plus OpenClaw's own Node-based agent framework and
plugin/gateway system). That's a rewrite that trades away the one
thing (direct, minimal-surface control over the model) this project
depends on, in exchange for a nicer leaderboard UI it doesn't need.
Confirms the user's own instinct going in: this would be a project of
its own, not an incremental adoption.

## Similarities to this project

- All of them run a model against a fixed task suite over HTTP against
  a local/self-hosted backend (llama.cpp server or Ollama) — same infra
  assumption this repo makes.
- Role/category task taxonomies are common (Harness-Bench's
  per-language SWE tasks, PinchBench's coding/scheduling/research/file
  categories) — same instinct as this repo's Roles table.
- Hidden/sandboxed grading via a real test script (Harness-Bench's
  `test.sh`) mirrors this repo's `verify.sh`/build+test harness pattern
  almost exactly.
- Markdown/CSV/JSON reporting, model-scoped result tables — same shape
  as `bench/report.sh` output.

## What's actually different here

1. **The deliverable.** Every surveyed tool produces a *score* or a
   *ranking*. This project produces a *fix* — a steering recipe
   (prompt/decoding config) that makes a specific model pass a specific
   task, committed as reusable evidence (`models/<model>/README.md`,
   `rules/`, `grammars/`). Nothing in the landscape treats "make this
   model work" as the output; Harness-Bench goes so far as to
   explicitly forbid the customization this project's methodology is
   built around, in order to keep its comparisons fair.
2. **The quality loop itself.** The structured, gated search (Phase 0 →
   baseline → research → Tier 1 specialist per-task → Tier 2 generalist
   gate → Confirm 3-run consistency → bounded performance pass) is a
   disciplined tuning process, not a benchmark run. No surveyed tool has
   an analog — they all assume a fixed prompt/config per model.
3. **Grammar-constrained decoding as a first-class fallback.** When
   prompting alone plateaus, this project has a documented, deliberate
   escalation to GBNF grammars (`docs/GRAMMAR-STEERING-PATTERNS.md`) —
   decoding-level steering integrated into the workflow, not a bolt-on.
4. **Scale/shape of the task set.** This project is deliberately small
   and hand-curated (tens of tasks, deep evidence per task) versus the
   landscape's either massive fixed academic suites (MMLU/BIG-bench) or
   broad-but-shallow agent leaderboards. It optimizes for depth of
   evidence per model+task, not breadth of coverage.
5. **Performance is gated by correctness, not the other way round.**
   llama-bench-style throughput numbers only get pursued *after*
   Confirm passes, and must not regress quality — none of the surveyed
   tools combine both axes per-model like that.

## Assessment: build vs. adopt

**Keep building this as its own thing.** Nothing surveyed replaces the
actual mission (steering-guide generation via a disciplined per-model
search) — the closest conceptual neighbor, Harness-Bench, is
structurally opposed to it (fairness-through-standardization vs.
steering-through-customization). Switching to any of these would mean
giving up the deliverable this project exists to produce.

Two narrow, low-risk infra borrows are worth considering later — not a
pivot, just reducing hand-rolled plumbing, and neither is urgent:

- **llama-bench for raw tok/s baselines** in the Performance run phase,
  instead of timing through `bench.sh`'s own dispatch path — it's the
  authoritative tool for exactly that one narrow measurement, and this
  repo doesn't currently use it anywhere.
- **promptfoo as an optional runner underneath `bench.sh`/`dispatch.sh`**
  for new task types (it already has mature Ollama/llama.cpp providers,
  assertion authoring, and sandboxed code eval) — only worth revisiting
  if the current hand-rolled harness becomes a real maintenance burden;
  the role taxonomy, quality-loop steering process, and evidence-backed
  guide output would all still need to be built on top regardless,
  since promptfoo doesn't have them.

## Sources

- [PinchBench leaderboard](https://github.com/pinchbench/leaderboard)
- [PinchBench skill (benchmark runner)](https://github.com/pinchbench/skill)
- [PinchBench site](https://aitoolly.com/product/pinchbench)
- [OpenClaw local models](https://docs.openclaw.ai/gateway/local-models)
- [OpenClaw llama.cpp provider](https://docs.openclaw.ai/plugins/llama-cpp)
- [OpenClaw Ollama provider](https://docs.openclaw.ai/providers/ollama)
- [llama-bench README](https://github.com/ggml-org/llama.cpp/blob/master/tools/llama-bench/README.md)
- [llama-benchy](https://github.com/eugr/llama-benchy)
- [Harness-Bench write-up](https://neuralnoise.com/2026/harness-bench-wip/)
- [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness)
- [promptfoo Ollama docs](https://www.promptfoo.dev/docs/providers/ollama/)
- [promptfoo llama.cpp docs](https://www.promptfoo.dev/docs/providers/llama.cpp/)
- [promptfoo sandboxed code evals](https://www.promptfoo.dev/docs/guides/sandboxed-code-evals/)
- [Awesome-AI-Evaluations-Tools](https://github.com/danielrosehill/Awesome-AI-Evaluations-Tools)
