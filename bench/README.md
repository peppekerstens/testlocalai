# Bench runner — local-LLM proficiency benchmark

Scratch research (gitignored, `.orchestration/`). Purpose: measure how well a
small local LLM performs its role against fixed ground truth — code tasks
(xUnit acceptance tests) for the code-emitter-csharp role, doc tasks
(`verify.sh` fidelity assertions) for the documenter role, reason tasks
(content assertions) for the reasoner role — and tune steering
(SPECs, rules, per-model quirks) until it passes. Task sets live flat under
`../tasks/` (role-prefixed: `code-*`, `doc-*`, `reason-*`), since a task's
skill (compile C#, reproduce a doc, reason about a log) isn't necessarily
tied to one source project. A project-scoped `tasks/<project>/` subdir for
reference-only material (SDK probes, cheat-sheets) was an optional pattern,
retired 2026-08-03 — its one instance (`tasks/csharp/`) was folded into a
real task (`tasks/code-mcpidentity/`) once its findings were verified; see
`history.md`.

## Protocol

1. Two task kinds, auto-detected by `bench.sh`:
   - **Code tasks** (`tasks/code-*/harness/`): tiny standalone C#
     project —
     - `tests/` — fixed xUnit acceptance tests (written by the orchestrator;
       these are the ground truth).
     - `src/` — where the subagent's transcription lands.
     - One `SPEC.md` per task: the exact task text pasted into the prompt.
   - **Doc tasks** (`tasks/doc-{verbatim,surgical,adapt,script,synthesize,repair}/`):
     deliverable is the model's whole output text; a task-local `verify.sh`
     scores it with fidelity assertions (exact-diff and/or
     forbidden/required tokens; the synthesize task uses structure +
     token assertions, not exact-match). No harness, no build. Built for
     deepseek-r1's **documenter** role.
   - **Reason tasks** (`tasks/reason-{config-validity,diagnose,checklist,trace,consequence,compare}/`):
     content-assertion tasks scored by `verify.sh` (no exact-match — phrasing
     varies). Built for deepseek-r1's **reasoner** role.
2. Dispatch the SPEC (and, in Round B, the model's rules block from
   `models/<model>/rules/`) to `qwen2.5-coder:1.5b` (override with
   `BENCH_MODEL`) via `dispatch.sh` (text mode, temperature 0.2).
   The prompt asks for ONE file, verbatim, fenced (code) or the document
   verbatim (doc).
3. Orchestrator transcribes the fenced code to `src/`, then:
   `dotnet test tasks/<task>/harness/<Task>.csproj` (whichever
   `.csproj` the harness has; doc tasks: `verify.sh` verdict body instead).
4. Score per task:
   - Code: `PASS` (compiles + all green), `BUILD FAIL`, `TEST FAIL`.
   - Doc: `PASS`/`FAIL` from `verify.sh`, with the assertion diagnostics.
5. Failure modes are classified and logged to
   `models/<model>/reports/round-<letter>-<task>.md` (model-scoped, not a
   shared `bench/reports/`).
6. Round A = no rules. Round B = same tasks +
   `models/qwen2.5-coder-1.5b/rules/csharp-rules.md` prepended. Round C
   (optional) = rules + "TDD: write tests first" hint, or smaller-chunk
   prompts.

## Session isolation (recommended before a real bench run)

Multiple local LLM hosters running at once (e.g. both `llama-server.service`
and `llama-server-deepseek.service`) is the normal *steering* setup, but for
a clean *benchmark* run you want exactly one provider, one model, one port:

```bash
# stop every other local hoster, start only the target model, warm it up:
bash bench/session-start.sh qwen2.5-coder:1.5b llamacpp
# ... run bench.sh / pure-run.sh calls ...
# restore whatever was running before (asks for confirmation first):
bash bench/session-stop.sh
```

`session-start.sh` snapshots current state to `bench/.session-state.json`
before touching anything, so `session-stop.sh` can restore it exactly —
it never assumes a fixed "default" state. Both scripts support
`SESSION_DRY_RUN=1` to preview actions without changing anything.

This is optional lifecycle setup, not a hard requirement: `dispatch.sh`
independently checks, on every single call, that the expected model is
actually loaded at the target host:port (`GET /v1/models` for llamacpp,
hard fail on mismatch; `GET /api/ps` for ollama, soft warning) — so running
`bench.sh` without `session-start.sh` first still fails fast and clearly
instead of silently talking to the wrong model. Skip the check with
`DISPATCH_CHECK_MODEL=0` if needed.

## Running

```bash
# baseline (no rules) — one code task at a time:
bash bench/bench.sh code-config a ObfuscationConfig.cs
# rules-injected (reads models/<BENCH_MODEL>/rules/<lang>-rules.md; default lang csharp):
bash bench/bench.sh code-config b ObfuscationConfig.cs --rules csharp
# different model (needs its own models/<model>/rules/ if using --rules):
BENCH_MODEL=deepseek-r1:1.5b bash bench/bench.sh code-config c ObfuscationConfig.cs
# doc task (whole output is the deliverable; no src-file arg):
bash bench/bench.sh doc-verbatim r1
# a future model would need its own models/<that-model>/rules/python-rules.md:
# bash bench/bench.sh code-config x SomeFile.cs --rules python
```

Default backend is llama.cpp (`:8080`); switch with
`DISPATCH_BACKEND=ollama`. Reports land in
`models/<model>/reports/round-<round>-<task>.md` — one raw verdict per
task per call. `pure-run.sh`'s scratch output (`out-<task>.txt` +
`.tokens.json`) lands in `bench/tmp/`, freely overwritten, not evidence.

For an aggregated, enriched report across a whole role's task suite
instead — results table, token usage, and a diff against that model+
role's previous report — use `bench/report.sh` instead of calling
`pure-run.sh` directly:

```bash
# writes models/<model>/reports/report-<role>-<YYYYMMDD-HHMMSS>.md
bash bench/report.sh deepseek-r1:1.5b reason
bash bench/report.sh lfm2.5:1.2b-thinking tool llamacpp 8082
```

`report.sh` automates verdicts, token counts, `finish_reason`/truncation
detection, and the delta vs the previous report for that exact model+role.
It does NOT automate the "Findings" / "Suggested next steps" sections —
those need someone to actually read the raw failures and are left as an
explicit `<!-- TODO -->` placeholder rather than faking analysis. Covers
`docs`/`reason`/`tool`/`extract`/`review` (same tracks as `pure-run.sh
--test`); `code-*` tasks still use `bench.sh` directly (different harness,
compile+test not dispatch+verify.sh).

Self-test the whole suite (control: expected must PASS, empty must FAIL,
then a model run on every task):

```bash
# all 18 tasks (both tracks), deepseek-r1:1.5b via llama.cpp :8080:
bash bench/pure-run.sh
# only the doc-* track (document editing/reproduction), or only reason-*
# (reasoning about docs/config/behavior) — explicit, not inferred:
bash bench/pure-run.sh deepseek-r1:1.5b --test docs
bash bench/pure-run.sh deepseek-r1:1.5b --test reason
bash bench/pure-run.sh deepseek-r1:1.5b --test docs,reason   # same as no filter, but explicit
# different model, or an explicit subset of individual tasks:
bash bench/pure-run.sh qwen2.5-coder:1.5b doc-synthesize reason-compare
# R1 serves on :8081:
LLAMACPP_PORT=8081 bash bench/pure-run.sh
```

`--test docs`/`--test reason`/`--test docs,reason` and an explicit task list
are mutually exclusive — pick one. This distinction is deliberate: a caller
(script or AI agent) that says "run the doc tests" should get exactly the
9 `doc-*` tasks, not the combined 18, even though the bare no-argument
default does run all 18 for convenience.

Task → src file mapping (code tasks):

| task | src file |
|---|---|
| code-config | ObfuscationConfig.cs |
| code-cache | TokenCache.cs |
| code-httpclient | CwClient.cs |
| code-auth | AuthResolver.cs |
| code-tool | TicketTool.cs |
| code-redactor | Redactor.cs |
| code-stats | TicketStats.cs |
| code-equality | CompositeKey.cs |
| code-events | TicketStatusNotifier.cs |
| code-repository | InMemoryRepository.cs |
| code-batch | BatchProcessor.cs |
| code-workflow | TicketWorkflow.cs |

Extended code-emitter suite (added 2026-08-01, increasing difficulty and
length; grounded in SWE-Sharp-Bench's real-world C# bug categories and
common C#/.NET interview-prep pattern categories, not observed production
failures — separate from the "maps to observed production failures" table
below since the grounding differs):

| task | pattern under test | difficulty / length |
|---|---|---|
| code-stats | LINQ deferred execution + aggregation | easy / short |
| code-equality | manual `IEquatable<T>`/`GetHashCode`, case-insensitive value equality | easy–medium / short–medium |
| code-events | delegates/events, per-handler exception isolation | medium / medium |
| code-repository | generics + factory pattern | medium / medium–long |
| code-batch | async/Task fan-out with partial-failure aggregation | medium–hard / long |
| code-workflow | exhaustive state-machine transition validation (6 states) | hard / longest |

Each was validated with the orchestrator-model reference-baseline purity
protocol before being considered done: an isolated subagent got only
`SPEC.md` (zero tool calls, confirmed), its output was transcribed and run
through `dotnet test` with no test file ever shown to it — see
`models/claude-sonnet-5/README.md` "Code-emitter extension" for the full
scorecard (12/12 PASS: reference impl + blind subagent, both layers, all 6
tasks). Also covers the original 6 code-* tasks, retroactively reviewed
and validated the same way — see that file's "Original 6 code-* tasks"
section.

Doc-fidelity suite (deepseek-r1, Track DOC — documenter role):

| task | archetype | scoring |
|---|---|---|
| doc-verbatim | copy-verbatim | exact-diff vs `expected.md` |
| doc-surgical | surgical-edit | forbidden/required tokens + exact-diff |
| doc-adapt | adapt-and-preserve | forbidden/required tokens + exact-diff |
| doc-script | executable manual-test (test-manual.sh) | `bash -n` + forbidden/required tokens |
| doc-synthesize | author-new-doc | structure + required/forbidden tokens (no exact-match) |
| doc-repair | fix-in-place | whitespace-normalized exact-match + repair-presence |

Reasoning suite (deepseek-r1, Track REASON — reasoner role; content
assertions, no exact-match):

| task | what it tests | scoring |
|---|---|---|
| reason-config-validity | schema reasoning | required tokens (culprit field/value/rule) + forbidden (wrong culprit) |
| reason-diagnose | error diagnosis | required tokens (culprit + mechanism) + forbidden (wrong cause) |
| reason-checklist | verification-checklist authoring | required tokens + ≥3 numbered steps + forbidden (npm/node/tsc) |
| reason-trace | code-path tracing of an MCP call | required tokens only (mechanism discriminates) |
| reason-consequence | contract-change impact | required tokens + forbidden (claims nothing changes) |
| reason-compare | pick correct fix among candidates | required tokens (correct candidate + justification) |

Extended DOC + REASON suite (added 2026-08-01, 3+3, increasing difficulty;
grounded in faithfulness/completeness summarization-evaluation research and
multi-hop root-cause-analysis research — see sources below; fixtures are
real excerpts from `docs/ARCHITECTURE.md`, `docs/END_USER_GUIDE.md`,
`docs/TOOL_CONTRACTS.md`, not fabricated):

| task | archetype | scoring |
|---|---|---|
| doc-summarize | bounded-length faithful compression | required/forbidden tokens + word-count + sentence-count bounds (new dimension: genuine compression, not just fidelity) |
| doc-crossref | cross-document synthesis (2 unrelated sources) | required tokens unique to EACH source (fails if only one was read) |
| doc-restructure | bullet-list → table, fact-preserving | required tokens (all facts) + structural check (real table markup, old list format gone) |
| reason-multihop | two-hop root cause (config-driven redaction gap) | required tokens for BOTH hops + forbidden (the plausible-but-ruled-out single-hop answer) |
| reason-tradeoff | open-ended tradeoff, no single correct pick | both sides argued + explicit pick (`Option A`/`Option B`) + forbidden (factually wrong claims) — scored on process, not which option |
| reason-coverage | exhaustive edge-case enumeration (hardest/longest) | ≥5 numbered items spanning 5 distinct categories, each naming a specific real field |

Each was validated the same way as the code suite: control checks
(`expected.md`→PASS, empty→FAIL) plus a blind claude-sonnet-5 subagent
given only `SPEC.md` (zero tool calls, confirmed), scored by `verify.sh`
with no reference answer ever shown to it — 6/6 PASS. One real bug was
found and fixed in this process: `doc-summarize`'s `verify.sh` only
checked the literal string `"reference implementation"`, but the SPEC
itself explicitly allows the alternate phrasing `"official SDK"` — the
blind model correctly used the alternate phrasing and the check was too
narrow, not the model. See `models/claude-sonnet-5/README.md` "Doc/reason
extension" for the full scorecard.

Sources for the archetype grounding: faithfulness/completeness/conciseness
as the standard summarization-evaluation axes (FABLES, arXiv:2404.01261;
multi-dimensional summarization evaluation surveys, 2026), and multi-hop
root-cause-analysis research on symptoms appearing far from their true
cause in fault propagation (arXiv:2508.04699; ACM AIware 2026 cloud-RCA
reasoning-failure taxonomy).

## Task coverage (maps to observed production failures)

| task | skill under test | production failure it guards |
|---|---|---|
| code-config | YAML config parse → typed records | external `ObfuscationConfigLoader` typedness |
| code-cache | thread-safe token cache | external `TokenGenerator` non-thread-safe cache |
| code-httpclient | async HTTP + `JsonNode` return (not `object`) | external `ConnectWiseClient` returning `object` |
| code-auth | follow auth contract exactly, no extra headers | external `AuthResolver` reading `Authorization` |
| code-tool | DI constructor injection + tool method | SDK tool authoring for Task 5.2 |
| code-redactor | regex redaction, don't break on bad rule | external `Redactor` |

## Research sources (2026-07)

- switchlabs.dev — "Prompting AI for Code Generation: Best Practices
  (2025)": prompt structure, step-by-step formats, tests/docs in prompt,
  iterative refinement, long-context limits.
- ollama.com/library/qwen2.5-coder:1.5b — series 0.5B–32B, Q4_K_M 986 MB,
  FIM-aware prompt template.
- ACM "Test-Driven Development and LLM-based Code Generation"
  (dl.acm.org/doi/10.1145/3691620.3695527) — tests-before-code measurably
  improves correctness; test-count threshold effect.
- AAAI "Hot or Cold? Adaptive Temperature Sampling for Code Generation" —
  temperature 0 is best for deterministic generation; our dispatch already
  uses 0.2, reviews use 0.0.
- oracle/agentize 2025 study on agent harnesses (todo: fetch).

## New roles beyond code/doc/reason (2026-08-02)

Researched to answer "what other roles are LLMs actually used for" before
inventing new task families — grounded in current industry-survey sources,
not guessed:

- checkmarx.com "Top 12 AI Developer Tools in 2026" and verdent.ai "AI
  Coding Agents 2026" — cite code review/bug-flagging and automated test
  generation as standalone agent categories, distinct from code
  generation itself (opposite skill direction: reading code for defects,
  not writing new code) → **review** role.
- Repeatedly cited "agentic tool-calling" / function-calling as a top LLM
  application category (assemblyai.com "7 LLM use cases... 2026",
  n-ix.com "LLM use cases for enterprises in 2026") — and this project's
  own domain (an MCP server) makes it uniquely well-grounded: real tool
  contracts already exist in `docs/TOOL_CONTRACTS.md`, no fabricated
  fixture needed → **tool-use** role, `tasks/tool-*`, added first (no new
  model download required).
- Structured data extraction / classification cited as one of the most
  common "utility" LLM roles across the same sources — exact-schema
  output is a genuinely different scoring shape (parse + field-match) from
  open-ended prose, distinct from the reason-* track's free-form analysis
  → **extract** role, planned.
- Vision/multimodal underrepresented in this project entirely until now.
  huggingface.co/blog/vlms-2025 and roboflow.com "Best Local
  Vision-Language Models for Offline AI" both point to small (<2B),
  llama.cpp-compatible options; `LiquidAI/LFM2.5-VL-450M` (450M params,
  same LFM Open License and recency window as `lfm2.5-1.2b-thinking`
  already in this project) is the concrete pick, not a placeholder →
  **visual** role, planned, needs a new model download + llama-server
  multimodal-projector (mmproj) wiring.

See `../README.md`'s "Roles" table for status of each, and
`../models/claude-sonnet-5/README.md`'s "Tool-use extension" section for
the first role's blind-subagent validation record.
