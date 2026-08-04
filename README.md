# testlocalai — steering benchmarks for small local LLMs

**What this is:** a benchmark + steering harness for small local LLMs
(the kind you can actually run on a laptop GPU, not a hosted frontier
model). For a given task — write this C# code, edit this doc exactly,
pick the right tool call — it measures whether a model gets it right
out of the box, and if not, works out what prompt-level or
decoding-level changes fix it. The output is steering guidance meant to
be **reused by other AI-enhanced projects**, not a private scoreboard.

If you're an AI agent operating tooling in this repo, read
[`AGENTS.md`](AGENTS.md) first — the operating rules for how a steering
session is run. This file is the map of what's here and how to use it.

## How it works, in short

- **Role first, task second.** A model's failure modes differ by *role*
  (writing code vs. editing docs vs. picking a tool) more than by task
  within a role — see the Roles table below.
- **Specialist before generalist.** Steering sessions default to
  finding a working config per task first; a single config that covers
  every task in a role is a bonus to look for after, never assumed.
  "No generalist config exists" is a valid, expected finding to
  document, not a failure to keep chasing.
- **Best-first, always.** Whatever's currently validated-best for a
  model+role+task sits under its plain name (`SPEC.md`,
  `<lang>-rules.md`) — never buried behind a qualifier. Superseded
  attempts move to a `history/` subdir with a note on why they lost,
  not deleted.
- **Evidence over assumption.** Every claim in a model's README is
  backed by a real dispatch + verify run, not inferred from another
  model or another task. See `models/<model>/history.md` for the
  full trail behind each one.

Full reasoning, past findings, and the project's origin: [`history.md`](history.md).

## Where this fits in the optimization spectrum

Steering a prompt is the cheapest way to make a small LLM better at a
task — not the only one. From hardest/most powerful to easiest/most
accessible:

| Approach | Difficulty | What it needs | Changes the model? |
|---|---|---|---|
| Train an LLM from scratch ([video](https://www.youtube.com/watch?v=T9egZA5ppQw)) | Highest | Huge compute, huge dataset, ML research expertise | Yes — from nothing |
| Fine-tune, e.g. Unsloth/QLoRA ([video](https://www.youtube.com/watch?v=4JofSJIrjwU)) | High | A GPU, a training run, labeled examples | Yes — adjusts weights |
| RAG ([video](https://www.youtube.com/watch?v=Of19Mu0F8o0)) | Medium | An embedding pipeline + vector store + retrieval logic | No — adds context at query time |
| **Steer the prompt/decoding — this project** | Lowest | A prompt, sampling params, maybe a grammar file | No — same GGUF, untouched |

This project lives entirely in the last row: no training, no retrieval
infra — just squeezing more correctness out of an already-quantized
GGUF via prompt content, sampling parameters, and (when prompting
alone hits a wall) grammar-constrained decoding. A "poor man's
Unsloth," working purely at inference time. See `AGENTS.md`'s quality
loop for how that search is actually run, and
`docs/GRAMMAR-STEERING-PATTERNS.md` for when prompting alone stops
being enough.

## Roles

Grounded in real usage-pattern research (see `bench/README.md` for
sources), not invented — each is a genuinely distinct skill with its own
failure modes, not a re-labeling of another role.

| Role | Prefix | Tests | Status |
|---|---|---|---|
| Code-emitter | `code-<lang>-*` | Generate correct, compiling code from a spec (C# established; Python added 2026-08-03 — see `bench/bench.sh`'s harness language auto-detection) | Established |
| Documenter | `doc-*` | Edit/reproduce/adapt real project docs exactly | Established |
| Reasoner | `reason-*` | Reason about docs/config/behavior — root cause, tradeoffs, coverage | Established |
| Tool-use | `tool-*` | Pick the right MCP tool + exact arguments from this repo's real `docs/TOOL_CONTRACTS.md`; recognize when no tool applies or when several calls are needed | Added 2026-08-02 |
| Extract | `extract-*` | Structured field extraction / classification from free text into a fixed schema | Added 2026-08-02 |
| Review | `review-*` | Find real seeded bugs in C# without rewriting the code — opposite skill direction from code-emitter | Added 2026-08-02 |
| Visual | `visual-*` | Image/screenshot/diagram understanding | **⚠️ Scaffold only — see `models/lfm2.5-vl-450m/README.md`** |

## Layout

| Path | What |
|---|---|
| `docs/SETUP.md` | one-time environment/machine setup (WSL2, CUDA, llama.cpp, systemd) |
| `docs/LOCAL-LLM-BEST-PRACTICES.md` | cross-model guidance — not a specific model's steering profile |
| `docs/GRAMMAR-STEERING-PATTERNS.md` | when to reach for grammar-constrained decoding instead of prompt text, backend capability notes, and a starter library of structural grammar patterns |
| `docs/QUALITY-LOOP-WORKFLOW.md` | visual (mermaid) guide to the quality loop + the scripted/rule-machine/template/judgment control mechanism — doubles as an AI agent's quick-reference for which script to run at each step |
| `docs/REMOTE-WSL2-SETUP.md` | condensed findings from standing up a second, remote llama.cpp host over SSH |
| `bench/` | generic runner: `dispatch.sh`, `bench.sh`, `pure-run.sh`, `report.sh` |
| `tasks/<role>-<name>/` | flat task set: SPECs + test harnesses; each task's `rounds/` holds its prompt/output history |
| `tasks/<project>/` | reference material for a specific source project, not tasks — optional pattern, retired 2026-08-03 (its one instance, `tasks/csharp/`, was folded into a real task, `tasks/code-csharp-mcpidentity/`, and model-specific onboarding evidence moved to `models/<model>/`; see `history.md`) |
| `models/README.md` | index: which model has been tested against which role, with a status indicator |
| `models/<model>/README.md` | that model's current steering profile (verdicts, how to optimize per role) — current-state only, see `AGENTS.md`'s README-shape rule |
| `models/<model>/history.md` | that model's full historical narrative — round-by-round evidence, diagnosed idioms, debugging trails |
| `models/<model>/grammars/` | per-model, per-task GBNF grammars (decoding-level structural constraints) — see `bench/pure-run.sh` |
| `models/<model>/rules/` | that model's own steering rules — not shared across models |
| `models/<model>/reports/` | per-run evidence — `round-<round>-<task>.md` (raw) or `report-<role>-<timestamp>.md` (enriched, via `bench/report.sh`) |
| `templates/` | copy-to-onboard for a new project or a new model |
| `history.md` | this project's own history — origin, cross-model findings, retired conventions |

Two kinds of history, easy to conflate: `tasks/<task>/rounds/` is
scored and automatic — one prompt/output pair per `bench.sh` dispatch,
verdict from the harness or `verify.sh`. `models/<model>/{prompts,
outputs,logs}/` is unscored and manual — raw round-trips from onboarding
a model *before* any task SPEC existed. Treat the onboarding trail as
provisional: once its findings land in a durable artifact (a
cheat-sheet, a probe project, a README note), delete the raw trail
rather than letting it sit as a stale shadow copy.

## 5-minute setup

0. No environment yet (no llama.cpp/CUDA/systemd service running)? Start
   with `docs/SETUP.md` — this section assumes that part is already done.
1. Backends: `DISPATCH_BACKEND=llamacpp` (default, localhost:8080) or
   `ollama` (localhost:11434). No service yet? Both are plain HTTP.
2. Pick a model that is whitelisted in `bench/dispatch.sh` (add it there —
   that list is the only hard gate).
3. Optional but recommended for a real benchmark run (not just poking at
   one task): `bash bench/session-start.sh <model> <backend>` first, to
   stop every other local hoster and load only the target model — see
   "Session isolation" in `bench/README.md`. `dispatch.sh` checks the
   loaded model on every call regardless, so this step is about a clean
   run, not correctness.
4. Run one task:
   ```bash
   BENCH_MODEL=qwen2.5-coder:1.5b bash bench/bench.sh code-csharp-config a ObfuscationConfig.cs
   ```
   Report lands in `models/qwen2.5-coder-1.5b/reports/round-a-code-csharp-config.md`
   (model-scoped, not a shared bench/reports/ — findings are always for one
   specific model); prompt/output round history lands in
   `tasks/code-csharp-config/rounds/`. Verdict = PASS / BUILD FAIL / TEST FAIL.
   Doc tasks (no harness, `verify.sh` scoring) take no src-file:
   `bash bench/bench.sh doc-verbatim r1`. For an aggregated, enriched
   report across a whole role's task suite (results table, token deltas vs
   the previous run) instead of one raw per-task verdict, use
   `bench/report.sh <model> <role>` — see `bench/README.md`.
5. Check `models/README.md` for what's already been tested against this
   model+role, then that model's own `README.md` for its specific
   verdict and "how to optimize" instructions before steering from
   scratch. `docs/LOCAL-LLM-BEST-PRACTICES.md` has cross-model guidance
   that isn't specific to any one model.

## Adding a new model

1. Add the model tag to `ALLOWED_MODELS` in `bench/dispatch.sh`.
2. Follow `templates/new-model/` (probe → cheatsheet → steering recipe).
3. Record results in `models/<model>/`; note quirks in its README.
4. If the model needs prose steering rules, write
   `models/<model>/rules/<lang>-rules.md` (`bench.sh --rules <lang>` reads
   it). Rules are earned per model from its own observed failures, not a
   shared cross-model ruleset — don't assume another model's rules apply;
   some models may need none, or need non-prose scaffolding instead.
5. Run the bench with `BENCH_MODEL=<model>`; keep rounds comparable by
   using the same round label across models.

DeepSeek-R1 note: `dispatch.sh` already strips `<think>` blocks in text
mode, so R1 outputs come back clean.

## Adding a new project

Copy `templates/new-project/`. A task set is a directory with `SPEC.md` —
always the current validated-best prompt, per "Best-first, always" above;
a superseded variant, if worth keeping, goes in `history/` — and
either a `harness/` holding `tests/` (ground truth), `src/` (subagent
transcription target), and a csproj — or, for
**doc tasks**, an `input.md`+`SPEC.md`+`expected.md` and a `verify.sh` that
scores the model's whole output (fidelity assertions, e.g. exact-diff and
forbidden/required tokens). The bench runner is language-agnostic up to the
"build+test" step — swap that for your project's build command, or use the
doc path to score prose instead of code.
