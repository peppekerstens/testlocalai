# claude-sonnet-5 — reference baseline (orchestrator model)

**Naming note:** this directory was renamed from `big-pickle` (2026-08-01)
for consistency with `models/qwen2.5-coder-1.5b/` and
`models/deepseek-r1-1.5b/`, which are both named after the actual model,
not a codename. One honesty caveat this rename doesn't paper over: the
**original** 12-task doc/reason baseline below predates this session — it
was run by "the orchestrator model via opencode," and its exact model
version was never independently pinned at the time, so it's presumed but
not confirmed to be claude-sonnet-5. The **"Code-emitter extension"** and
**"Original 6 code-* tasks"** sections below (2026-08-01) ARE confirmed
claude-sonnet-5 — verified directly from this session's own subagent
transcripts (`tool_uses: 0`, pure text completion). The historical sections
keep the "big-pickle" name in their own text where it's describing a
specific dated run, since that's what it was actually called at the time;
only the directory/file identity changed.

**What this is:** not a steered local subagent — this is the model running
the orchestration itself. It is recorded here as a **reference baseline**:
the same bench tasks run against a frontier-grade model, to (a) validate
the test suite and (b) calibrate what a 1.5B local model can and cannot be
expected to reach. Treat its scores as the ceiling, not as something to
steer.

**Why not in `ALLOWED_MODELS`:** `bench/dispatch.sh` only dispatches to
HTTP-served local backends (llamacpp `:8080/:8081`, ollama). This model has
no such endpoint; it is run through a fresh subagent session instead, so it
cannot be a `BENCH_MODEL=claude-sonnet-5` bench run. `ALLOWED_MODELS` stays
the local-model gate.

## How the run was done (purity protocol)

- One fresh subagent session, with **no prior knowledge** of these tests,
  was given only the prompt material for each task (`SPEC.md` + `input.md`),
  one task dir per task. `expected.md`/`verify.sh`/prior `out-*`/reports were
  never exposed.
- The subagent wrote its deliverable per the SPEC's OUTPUT FORMAT; the
  mechanical `verify.sh` was the sole judge. No human/model judgment on
  output quality.
- Same 7 tasks, same order, same verifiers as the deepseek-r1 track.

## Scorecard (fresh subagent draws, temp 0.2-equivalent)

| task | verdict | note |
|---|---|---|
| doc-verbatim | **PASS** (after test fix) | all content correct; only prior diff was a stray blank line in `expected.md` (fixed — see below) |
| doc-surgical | **PASS** (after verifier normalization) | edits correct; only diff was line-wrapping |
| doc-adapt | **PASS** (after verifier normalization) | edits correct; only diff was line-wrapping |
| doc-script | PASS | 90 lines, valid bash (`bash -n` clean) |
| reason-config-validity | PASS | correct verdict + named violating field |
| reason-diagnose | PASS | correct root cause + fix |
| reason-checklist | PASS | 12 lines = 6 two-line steps |

**Result: 7/7 PASS** (was 4/7 before the doc-verbatim fix and the
surgical/adapt whitespace normalization).

New tasks from the 6+6 split (second draw, same purity protocol):

| task | verdict | note |
|---|---|---|
| doc-synthesize | PASS | new C# error-behavior section; correct structure + all required tokens, no stale TS tokens |
| doc-repair | PASS | both repairs applied (closing fence + table separator row); everything else intact |
| reason-trace | PASS | restart trace through the in-memory `transports` map → `400 No valid session ID`; correctly cited the doc's own load-balancer analogy |
| reason-consequence | PASS | `owner` removed from `nestedEntities` → value passes through untouched; member name now reaches the client |
| reason-compare | PASS | picked candidate A (eager boot validation), justified against the two-part documented fix, kept the try/catch defense |

**Combined: 12/12 PASS.**

## What the baseline run validated

1. **Test suite discriminates.** big-pickle 5/7 vs deepseek-r1 ~0–2/7 on the
   same tasks → the harness measures real capability differences, not noise.
2. **REASON track is sound.** 3/3 for big-pickle, 0–1/3 for deepseek → the
   reason tasks are fair content-assertion tests (no answer-leak in SPECs —
   prompt↔expected word overlap was 40–70%, all task-necessary terms).
3. **Byte-exactness is stricter than the SPEC it ships with.** big-pickle's
   doc-track failures were **semantic non-errors** — content correct, only
   bytes differed (blank line; line-wrapping). This confirmed the
   "exact-diff stricter than production acceptance" caveat (plan Phase 6 is
   token-level, not byte-level) and led to two test fixes.

## Code-emitter extension: 6 new tasks (2026-08-01, model: claude-sonnet-5)

When the code-* task suite was extended with 6 new tasks
(`code-csharp-stats`, `code-csharp-equality`, `code-csharp-events`, `code-csharp-repository`,
`code-csharp-batch`, `code-csharp-workflow` — increasing difficulty and length, covering
LINQ, value equality, delegates/events, generics+factory, async fan-out,
and state-machine patterns; see `bench/README.md` for the full table), each
was validated the same way as the original 12-task baseline: a **fresh,
isolated subagent** (model: **claude-sonnet-5**, zero tool calls — pure
text completion from the SPEC, confirmed via each transcript's `tool_uses:
0`) was given ONLY that task's `SPEC.md` text, with explicit instructions
not to read any file or explore the repository. Its response was
transcribed exactly like `bench.sh` would transcribe a real model's output,
then `dotnet test` was the sole judge — no test file or reference
implementation was ever shown to the subagent.

| task | verdict | tests |
|---|---|---|
| code-csharp-stats | **PASS** | 14/14 |
| code-csharp-equality | **PASS** | 14/14 |
| code-csharp-events | **PASS** | 6/6 |
| code-csharp-repository | **PASS** | 14/14 |
| code-csharp-batch | **PASS** | 9/9 |
| code-csharp-workflow | **PASS** | 53/53 |

**Result: 12/12 (6 tasks × 2 layers) PASS** — each task was also verified
against an independently hand-written reference implementation before the
blind run, confirming the test suite itself is coherent and achievable,
not just that the blind attempt happened to match. No test-suite fixes
were needed this round (unlike the original baseline, which surfaced three
real bugs — see below); all 6 new harnesses were correct on first
verification.

## Original 6 code-* tasks: retroactive review + blind validation (2026-08-01)

The original 6 code-* tasks (`code-csharp-config`, `code-csharp-cache`, `code-csharp-httpclient`,
`code-csharp-auth`, `code-csharp-tool`, `code-csharp-redactor`) had never been through this
blind-subagent protocol — they were tuned iteratively against qwen itself
(rounds A–L) but never independently validated the way the doc/reason
suite and the 6 new code tasks were. Reviewing them surfaced real,
previously-untested gaps between what each SPEC *stated* as required
behavior and what the test suite actually *checked*:

| task | gap found | fix |
|---|---|---|
| code-csharp-config | whitespace-only `token` never tested (only empty-string) | added `WhitespaceOnlyTokenThrows` |
| code-csharp-cache | `capacity <= 0` constructor throw never tested | added zero/negative capacity tests |
| code-csharp-httpclient | "empty body → null" only tested via `204`, never a `200` with an empty body | added `GetAsyncReturnsNullForEmptyOkBody` |
| code-csharp-auth | `requireAuth=true` + *whitespace* `xDevUser` never tested (only `null`) | added the missing combination |
| code-csharp-tool | **no test ever substituted a different `ITicketStore`** — a `TicketTool` that silently ignored its constructor parameter and created its own `InMemoryTicketStore` internally would have passed every existing test unchanged; the stated "constructor injection only" contract was unverified | added `UsesTheInjectedStore_NotAnInternallyCreatedOne` with a fake store returning a distinguishable sentinel |
| code-csharp-redactor | the existing test used two non-overlapping patterns (email, phone), so nothing would fail if rules ran out of order or all against the original input instead of chaining | added `RulesChainInOrder_EachOnPreviousResult` (cat→dog→fish) |

`code-csharp-tool` was the most significant finding — a real, exploitable gap in
what the test suite actually enforced versus what the SPEC claimed to
require. All 6 gaps are now closed.

After fixing, all 6 tasks were re-validated with the same two-layer
protocol as above (existing/reference implementation, then a blind
claude-sonnet-5 subagent given only the SPEC text, zero tool calls
confirmed):

| task | verdict | tests |
|---|---|---|
| code-csharp-config | **PASS** | 6/6 |
| code-csharp-cache | **PASS** | 6/6 |
| code-csharp-httpclient | **PASS** | 5/5 |
| code-csharp-auth | **PASS** | 7/7 |
| code-csharp-tool | **PASS** | 4/4 |
| code-csharp-redactor | **PASS** | 5/5 |

**Result: 12/12 PASS.** One minor, non-blocking finding: `code-csharp-tool`'s
SPEC-mandated `GetTicketAsync` body (`Task.FromResult("Ticket 1")`
assigned to a `Task<string?>`-returning method) triggers compiler warning
`CS8619` (nullable reference mismatch) — present in the SPEC's own
"use exactly this shape" snippet, not something the model introduced.
Cosmetic; doesn't affect build success or test results. Left as-is rather
than deviating from the verbatim shape that's proven to work — noted here
for anyone who wants to clean it up later.

Combined with the 6 new tasks above, **all 12 code-* tasks now have
independent blind-subagent validation**, not just qwen-tuning history.

## Doc/reason extension: 6 new tasks (2026-08-01, model: claude-sonnet-5)

Following a bare-baseline `pure-run.sh` run against deepseek-r1:1.5b
(0/12 — expected, matches this model's already-documented profile; see
`models/deepseek-r1-1.5b/README.md`), the DOC + REASON suite was extended
with 3+3 new tasks —
`doc-summarize`, `doc-crossref`, `doc-restructure`, `reason-multihop`,
`reason-tradeoff`, `reason-coverage` — increasing difficulty, grounded in
summarization-faithfulness and multi-hop-RCA research (see
`bench/README.md`'s "Extended DOC + REASON suite" for sources), with
fixtures pulled from real project docs (`ARCHITECTURE.md`,
`END_USER_GUIDE.md`, `TOOL_CONTRACTS.md`), not fabricated.

Each was validated with the same purity protocol as the code suite: a
fresh, isolated subagent (zero tool calls, confirmed) got only `SPEC.md`,
and `verify.sh` — never shown to the subagent — was the sole judge.

| task | verdict |
|---|---|
| doc-summarize | **PASS** (after a `verify.sh` fix — see below) |
| doc-crossref | **PASS** |
| doc-restructure | **PASS** |
| reason-multihop | **PASS** |
| reason-tradeoff | **PASS** |
| reason-coverage | **PASS** |

**Result: 6/6 PASS.** One real bug found, in the test harness, not the
model: `doc-summarize`'s `verify.sh` required the literal substring
`"reference implementation"`, but the SPEC itself explicitly states
`"...or that the official SDK is TypeScript"` as an acceptable alternate
phrasing. The blind subagent's summary correctly used that alternate
phrasing (`"the official @modelcontextprotocol/sdk this project depends
on"`) and initially failed the check — a false negative caused by the
verifier not honoring the flexibility its own SPEC promised, not a model
error. Fixed by accepting either phrasing; re-verified PASS. Every other
task passed on the first blind draw with no fixes needed.

Each task's `SPEC.md`/`expected.md` pair was also control-checked directly
(`expected.md`→PASS, empty→FAIL) before the blind run, same as every doc/
reason task in this suite.

## Test-suite fixes this baseline surfaced

1. `doc-verbatim/expected.md` had a stray blank line (17 lines) contradicting
   its own SPEC ("exactly 16 lines: 15 doc lines + 1 note"). A model that
   follows the SPEC literally could not pass. **Fixed** (blank line dropped);
   re-verified: expected→PASS, empty→FAIL, big-pickle output→PASS.
2. `doc-surgical`/`doc-adapt` verifiers compared byte-exact, so a model that
   correctly applied every edit but re-wrapped an inserted phrase failed.
   **Fixed**: exact-match is now **whitespace-normalized** (token+structural
   compare); byte-diff remains as a diagnostic-only line. Token checks
   (forbidden/required) unchanged and still gating. Re-verified: expected→
   PASS, empty→FAIL, big-pickle→PASS, and the deepseek copy-latch failures
   (edit-mappings instead of a document) still FAIL — normalization does not
   mask real errors.
3. `reason-trace`'s first verifier penalized tokens that appear **in the
   source document** (`round-robin`, `sticky`, `load balancer`). big-pickle's
   correct answer cited the document's own load-balancer analogy and failed
   on a false negative. **Fixed**: dropped the forbidden list — the REQUIRED
   tokens alone discriminate (a wrong mechanism misses `in-memory`, `400`,
   `No valid session ID`, `Map`). Re-verified: expected→PASS, empty→FAIL,
   big-pickle→PASS, deepseek still FAIL (scenario misread — answered the
   load-balancer case instead of a restart).

## Tool-use extension: new role, 6 tasks (2026-08-02, model: claude-sonnet-5)

A new role beyond code-emitter and documenter/reasoner — see
`AGENTS.md`/`README.md` for the role taxonomy — grounded entirely in this
repo's own real `docs/TOOL_CONTRACTS.md` (the 5 real MCP tools this server
exposes: `list_companies`, `list_contacts`, `search_tickets`,
`get_ticket_details`, `describe_obfuscation_policy`), not fabricated
tools. Tests tool/argument selection, not code generation or prose —
output is a strict fenced JSON block, scored by parsing it, not by token
matching prose. Increasing difficulty: `tool-select` (single-tool basic
selection) → `tool-args` (exact argument key/type fidelity against a
prose request) → `tool-multi` (recognize when TWO tool calls are needed)
→ `tool-none` (hallucination resistance — a request implies a tool that
doesn't exist) → `tool-error` (predict tool call error BEHAVIOR from
documented rules, not selection) → `tool-policy` (combine tool selection
with a specific, given domain fact).

Each was validated with the same purity protocol as every other role in
this suite: a fresh, isolated subagent (zero tool calls, confirmed via
`tool_uses: 0` in the run's own usage metadata) got only the task's
`SPEC.md`, and `verify.sh` — never shown to the subagent — was the sole
judge.

| task | verdict |
|---|---|
| tool-select | **PASS** |
| tool-args | **PASS** |
| tool-multi | **PASS** |
| tool-none | **PASS** |
| tool-error | **PASS** |
| tool-policy | **PASS** |

**Result: 6/6 PASS, first blind draw, no fixes needed.** One near-miss
caught and fixed during harness construction (before the blind run, not
after): `tool-error`'s forbidden-phrase check for "invented special-case
handling" originally matched the bare substring `special-case`/
`special-cased`, which also matched the ground-truth answer's own correct
negation ("the ID is **not** special-cased") — a false-negative-on-
`expected.md` bug caught by this project's own expected→PASS control
check before any model ever saw the task. Fixed by requiring the
affirmative phrasing specifically (`is special-cased`, `has special
handling`, etc.), not a negation-blind substring.

Each task's `SPEC.md`/`expected.md` pair was also control-checked directly
(`expected.md`→PASS, empty→FAIL) before the blind run, same as every task
in this suite.

## Extract extension: new role, 6 tasks (2026-08-02, model: claude-sonnet-5)

Structured extraction/classification — the third new role researched
(`bench/README.md`'s "New roles beyond code/doc/reason"). Output is a
strict JSON block/array, scored by parsing and field-matching, not prose
tokens. Increasing difficulty: `extract-basic` (flat schema extraction) →
`extract-optional` (omit-not-null discipline — mirrors this project's own
real `TOOL_CONTRACTS.md` convention: "Optional fields are omitted
entirely... not emitted as null") → `extract-multi` (find all N entities
in one paragraph, not just the first) → `extract-classify` (closed-set
classification with a surface-urgency-vs-rule-definition trap: alarming
wording, but the correct label per the given rules is one tier lower) →
`extract-ambiguous` (a REQUIRED field never stated in the text — correct
answer is `null`, not a plausible-looking invented number) →
`extract-nested` (nested `company`/`contact` objects, mirroring
`TOOL_CONTRACTS.md`'s real nested-entity shape, not flattened siblings).

Same purity protocol: fresh isolated subagent (zero tool calls, confirmed
via `tool_uses: 0`), `SPEC.md` only, `verify.sh` as sole judge.

| task | verdict |
|---|---|
| extract-basic | **PASS** |
| extract-optional | **PASS** |
| extract-multi | **PASS** |
| extract-classify | **PASS** |
| extract-ambiguous | **PASS** |
| extract-nested | **PASS** |

**Result: 6/6 PASS, first blind draw, no fixes needed.** Every task's
`SPEC.md`/`expected.md` pair was also control-checked directly
(`expected.md`→PASS, empty→FAIL) before the blind run.

## Review extension: new role, 6 tasks (2026-08-02, model: claude-sonnet-5)

Code review/bug-finding — opposite skill direction from code-emitter
(read code for defects, don't write new code). Doc-kind tasks (no
`harness/csproj`): a C# snippet is embedded directly in `SPEC.md`, the
model reports found bugs as JSON, scored by parsing + keyword-matching the
actual mechanism named, not by compiling/running the snippet.
Increasing difficulty: `review-null` (missing null check on a documented-
optional field) → `review-offbyone` (`<=` vs `<` boundary bug, produces a
silent extra empty page) → `review-async` (`.Result` blocking on a `Task`
— deadlock/thread-starvation risk) → `review-concurrency` (plain
`Dictionary` under concurrent access — mirrors this project's own real
`code-csharp-cache`/`TokenGenerator` theme) → `review-logic` (`||` vs `&&`
operator mixup — silently wrong, doesn't crash, hardest to spot) →
`review-clean` (negative control: the exact `review-null` snippet with
the bug fixed — correct answer is `{ "bugs": [] }`; any reported bug is a
false positive).

Same purity protocol: fresh isolated subagent (zero tool calls, confirmed
via `tool_uses: 0`), `SPEC.md` only, `verify.sh` as sole judge.

| task | verdict |
|---|---|
| review-null | **PASS** |
| review-offbyone | **PASS** |
| review-async | **PASS** |
| review-concurrency | **PASS** |
| review-logic | **PASS** |
| review-clean | **PASS** |

**Result: 6/6 PASS, first blind draw, no fixes needed.** `review-clean`
confirms the suite isn't just rewarding "always report a bug" — the model
correctly returned an empty `bugs` array on the one snippet with no real
defect. Every task's `SPEC.md`/`expected.md` pair was also control-checked
directly (`expected.md`→PASS, empty→FAIL) before the blind run.
