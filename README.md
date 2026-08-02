# .orchestration — local-LLM optimization guidance

If you are an AI agent operating tooling in this directory, read
[`AGENTS.md`](AGENTS.md) first — project-tooling behavior rules (how task
scope is named/selected, etc.), distinct from the per-model steering under
`models/<model>/`.

Scratch research (gitignored). Given a set of tasks a small local LLM must
perform, what does it take to get the outcome right? Measure, steer,
re-measure — the findings live in the docs, the evidence lives in `bench/`.
The point is not a private benchmark: the output is steering guidance meant
to be **consumed by other AI-enhanced projects** to correctly steer their
own subagents.

Steering is scoped narrowly on purpose, along two axes: **role** first
(code-emitter, documenter, reasoner, tool-use, extract, review, visual —
different models, different failure modes, different levers; see
"Roles" below), then **task/language** within that role (C#
code-emission needs different rules than Python would; see the
`--rules <lang>` split in `bench.sh`). A rule earned by one model on one
task is never assumed to generalize — see "Adding a new model" below.

**Cross-model finding, expected going forward, not just a one-off:**
small local models at the scale tested here (~1-2B parameters) have
repeatedly not generalized a single steering config across
heterogeneous task shapes within one role — a fix that helps one task
actively hurts another that needs different behavior
(`qwen2.5-coder-1.5b`'s two-recipe split for its two code-task families;
`qwen3.5:0.8b`'s structure-preservation fix helping a copy task while
breaking a restructure task in the same run). Per-model steering
sessions default to finding a **specialist** config per task first, and
only then search for a **generalist** — with "no generalist exists" a
fully acceptable, expected outcome to document, not a failure to keep
chasing. See `AGENTS.md`'s quality loop, Steering phase, for the
two-tier structure this produces.

**Best-first presentation (standing rule):** whatever configuration is
currently validated-best for a given model+role+task is what an end-user or
AI reader encounters first, under its plain name (`SPEC.md`,
`<lang>-rules.md`) — never buried behind a qualifier or sitting as a
co-equal alternative next to something worse. Superseded variants are kept
only when they carry real iteration/comparison value, filed under a
`history/` subdir with a plain note on why they lost, not deleted outright.
This is a **process** rule, not a technique endorsement: "best" is
re-evaluated per model, per role, per task, and never assumed to transfer —
e.g. compressed ("caveman-style") prompts currently win for
qwen2.5-coder-1.5b on the C# code-emission tasks specifically; that is one
model's evidence, not a recommendation to compress prompts in general.

Origin: this began as a subset of the connectwise-mcp C# port repo and
still lives inside it (`csharp/.orchestration/`), but is organized as if
already standalone. Generic by design: usable for any AI-enhanced project
and any local LLM, not just the C# port or qwen2.5-coder — task sets,
reference material, and findings may come from other source repos in the
future, not just this one. Task sets (SPECs + harnesses) live flat under
`tasks/`, role-prefixed (`code-*`, `doc-*`, `reason-*`, `tool-*`,
`extract-*`, `review-*`, `visual-*`) — a task's skill isn't tied to one
source project, so it isn't nested under one. Reference material tied to a
specific source project (SDK probes, cheat-sheets) lives under
`tasks/<project>/` instead (e.g. `tasks/csharp/`). Per-model steering
history lives under `models/<model>/`.

## Roles

Grounded in real usage-pattern research (see `bench/README.md` for
sources), not invented — each is a genuinely distinct skill with its own
failure modes, not a re-labeling of another role.

| Role | Prefix | Tests | Status |
|---|---|---|---|
| Code-emitter | `code-*` | Generate correct, compiling C# from a spec | Established |
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
| `bench/` | generic runner: `dispatch.sh`, `bench.sh`, `pure-run.sh`, `report.sh` |
| `tasks/<role>-<name>/` | flat task set: SPECs + test harnesses; each task's `rounds/` holds its prompt/output history |
| `tasks/<project>/` | reference material for a specific source project, not tasks (e.g. `tasks/csharp/probe/`, `sdk-cheat-sheet.md`) |
| `models/README.md` | index: which model has been tested against which role, with a status indicator |
| `models/<model>/README.md` | that model's current steering profile (verdicts, how to optimize per role) — current-state only, see `AGENTS.md`'s README-shape rule |
| `models/<model>/history.md` | that model's full historical narrative — round-by-round evidence, diagnosed idioms, debugging trails |
| `models/<model>/rules/` | that model's own steering rules — not shared across models |
| `models/<model>/reports/` | per-run evidence — `round-<round>-<task>.md` (raw) or `report-<role>-<timestamp>.md` (enriched, via `bench/report.sh`) |
| `templates/` | copy-to-onboard for a new project or a new model |

### Two kinds of history

Easy to conflate: `tasks/<task>/rounds/` is scored and automatic — one
prompt/output pair per `bench.sh` dispatch of that task, verdict from the
harness or `verify.sh`.
`models/<model>/{prompts,outputs,logs}/` is unscored and manual — raw
`dispatch.sh` round-trips from onboarding a model *before* any task SPEC
existed (see "Adding a new model" below). Treat the onboarding trail as
provisional: once its findings land in a durable artifact (a cheat-sheet, a
probe project, a README note), delete the raw trail rather than letting it
sit as a stale shadow copy. (qwen2.5-coder-1.5b's onboarding trail was
retired this way once fully superseded by
`tasks/csharp/{sdk-cheat-sheet.md,probe/}` and `ORCHESTRATION.md`
deviation #5 — nothing was lost, the raw transcript was just redundant.)

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
   BENCH_MODEL=qwen2.5-coder:1.5b bash bench/bench.sh code-config a ObfuscationConfig.cs
   ```
   Report lands in `models/qwen2.5-coder-1.5b/reports/round-a-code-config.md`
   (model-scoped, not a shared bench/reports/ — findings are always for one
   specific model); prompt/output round history lands in
   `tasks/code-config/rounds/`. Verdict = PASS / BUILD FAIL / TEST FAIL.
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
always the current validated-best prompt, per "Best-first presentation"
above; a superseded variant, if worth keeping, goes in `history/` — and
either a `harness/` holding `tests/` (ground truth), `src/` (subagent
transcription target), and a csproj — or, for
**doc tasks**, an `input.md`+`SPEC.md`+`expected.md` and a `verify.sh` that
scores the model's whole output (fidelity assertions, e.g. exact-diff and
forbidden/required tokens). The bench runner is language-agnostic up to the
"build+test" step — swap that for your project's build command, or use the
doc path to score prose instead of code.
