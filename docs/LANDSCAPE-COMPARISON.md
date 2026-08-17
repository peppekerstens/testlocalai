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
| **PinchBench** (Kilo.ai) | Agent task success (scheduling, coding, research, file mgmt) for "OpenClaw" coding-agent models | Unclear/secondary — leaderboard is built around Anthropic/OpenAI/Google models; can run locally per its own docs | Automated + LLM-judge, public leaderboard (success rate, speed, cost) | No — it's a comparative leaderboard, not a fix-this-model tool |
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
- [PinchBench site](https://aitoolly.com/product/pinchbench)
- [llama-bench README](https://github.com/ggml-org/llama.cpp/blob/master/tools/llama-bench/README.md)
- [llama-benchy](https://github.com/eugr/llama-benchy)
- [Harness-Bench write-up](https://neuralnoise.com/2026/harness-bench-wip/)
- [lm-evaluation-harness](https://github.com/EleutherAI/lm-evaluation-harness)
- [promptfoo Ollama docs](https://www.promptfoo.dev/docs/providers/ollama/)
- [promptfoo llama.cpp docs](https://www.promptfoo.dev/docs/providers/llama.cpp/)
- [promptfoo sandboxed code evals](https://www.promptfoo.dev/docs/guides/sandboxed-code-evals/)
- [Awesome-AI-Evaluations-Tools](https://github.com/danielrosehill/Awesome-AI-Evaluations-Tools)
