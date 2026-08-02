# qwen3.5:0.8b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed — quality loop closed 2026-08-02, 2 of 9 task shapes usable with per-task steering | 1/9 → ~2/9 (2 tasks confirmed ~67% reliable specialist, rest unsuitable) | Not comparable overall; 2 narrow task shapes usable with review | [Documenter role: final report](#documenter-role-final-report-closed-2026-08-02) |

## Documenter role: final report (closed 2026-08-02)

**Why stopped here.** Full quality loop run: Research phase (no
cross-model or external fix existed for this model's idioms), Tier 1
specialist optimization (4 Steering runs, every failing task given a
genuine attempt, gated per the 2nd-run rule), an autonomous Tier 2 gate
(specialist pass rate 2/9 = 22%, below the 60% threshold — Tier 2
skipped, no generalist search attempted), and a 3-run Confirm check.
That's the full loop, not a partial run — closing here reflects a
completed process, not budget exhaustion.

**Usability score without optimizations (bare): 1/9 (11%) PASS**
(`reports/report-docs-20260802-114242.md`, `doc-summarize` on that
particular bare draw — not stable, see idioms below).

**Usability score with optimizations: 2/9 tasks reach a reliable,
if imperfect, specialist PASS (~67% each, confirmed via 3-run Confirm:
`doc-crossref` 2/3, `doc-summarize` 2/3); 1 more task reaches a stable
partial improvement without a full PASS (`doc-script`); the remaining 6
tasks — including `doc-restructure`, which passes bare on this model
unlike `lfm2.5-1.2b-thinking` — showed no net improvement from steering
after real per-task budget was spent, several regressing when steered
at all.** Role-level PASS count varied 1-3 of 9 across the 3 Confirm
draws (averaging ~2/9) — there is no single stable "current" number for
the whole role, only per-task numbers; see the per-task table below.

**Comparison against a mainstream frontier LLM: not comparable overall.**
A model like Claude Haiku 4.5 would be expected to pass close to all 9
of these tasks zero-shot. **The one narrow exception**: for the 2 task
shapes that reached a working specialist config — cross-document fact
synthesis with exact-identifier preservation (`doc-crossref`) and
bounded multi-fact summarization under a word limit (`doc-summarize`)
— this model reaches ~67% reliability at near-zero cost/latency versus
a hosted frontier-model call, usable with human review on those two
specific task shapes, not unsupervised and not for anything else tested.

**Final verdict: not suitable as a general documenter.** With dedicated
per-task specialist configuration (not a generic prompt), usable for 2
of the 9 tested task shapes at ~67% reliability under review — not
unsupervised, not general-purpose. All byte-exact-copy, multi-step
surgical-edit, in-place-repair, script-edit, and restructuring task
shapes tested remain unsuitable even after dedicated per-task steering
effort (several actively regressed when steered). No generalist
config was searched for or is expected to exist, per the autonomous
Tier 2 gate — consistent with this project's standing finding that
small models don't generalize a single config across heterogeneous task
shapes within one role (see root `README.md`).

**Five idioms diagnosed** (see `history.md` for the full per-task
diagnostic trail and how each fix attempt went):
1. **Idiom Q1 — structural-element dropping** (headings, table
   separator rows) — no validated fix found; `doc-verbatim` came
   closest (down to 1 line of defect on 2 of 4 attempts) but the
   4-attempt picture was contradictory, not a reliable trend.
2. **Idiom Q2 — instruction/prompt bleed** (`doc-surgical` copying the
   edit-instructions block itself into its output) — a boundary-
   discipline instruction measurably reduced this in isolated draws but
   results were noise-dominated across 3 attempts; not solved.
3. **Idiom Q3 — substitution not applied** (`doc-adapt`, `doc-script`)
   — matches `deepseek-r1-1.5b`'s independent "structural limit, not a
   prompting problem" verdict on the same task family; an
   edit-verification instruction did not move this idiom on any task
   tested (3 attempts).
4. **Idiom Q4 — `doc-crossref`'s `describe_obfuscation_policy` drop**,
   confirmed independently on all 3 models tested in this project —
   **the one idiom with a working fix**: an exact-fact reminder naming
   the specific dropped fact reached ~67% reliability.
5. **`doc-synthesize`** showed the best partial *bare* performance of
   any model tested here, but regressed under steering — left bare.

**Per-task detail** (Confirm-verified, `history.md`'s "Confirm" section
for the full 3-run trace):

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-crossref` | **~67% reliable PASS** (2/3 Confirm draws) | [`task-overrides/doc-crossref.md`](task-overrides/doc-crossref.md) — exact-fact reminder for the historically-dropped tool name | n/a — Tier 2 gate skipped (specialist rate 22% < 60% threshold) |
| `doc-summarize` | **~67% reliable PASS** (2/3 Confirm draws) | [`task-overrides/doc-summarize.md`](task-overrides/doc-summarize.md) — sharpened single-fact reminder | n/a |
| `doc-script` | Stable partial — 1 forbidden token remains, 0/3 Confirm draws pass but content quality improved over bare | [`task-overrides/doc-script.md`](task-overrides/doc-script.md) | n/a |
| `doc-verbatim` | 4/4 runs used, contradictory results — reverted to bare | bare — no variant beat bare with confidence | n/a |
| `doc-surgical` | 3 attempts, noise-dominated — reverted to bare | bare — no variant beat bare with confidence | n/a |
| `doc-repair` | **⚠️ Needs re-test — result invalidated 2026-08-02.** Pre-fix: gated out (flat after run 1) — measured against a buggy task version, see Setup | bare | n/a |
| `doc-adapt` | Gated out (flat after run 1, matches R1's cross-model signal) | bare | n/a |
| `doc-synthesize` | Gated out (regressed) | bare — steering hurt this task | n/a |
| `doc-restructure` | Gated out in run 1 (instruction conflicted with the task's job); passes bare ~2/3 draws, pre-existing instability unrelated to this loop | bare | n/a |

## How to optimize (verify before trusting)

- `DISPATCH_ENABLE_THINKING=false` is mandatory before any other
  steering — see Setup below.
- For `doc-crossref`/`doc-summarize`-shaped tasks (exact-identifier
  cross-document synthesis, bounded fact-checklist summarization): an
  exact-fact reminder naming the specific historically-dropped fact
  reaches ~67% reliability — see
  [`task-overrides/doc-crossref.md`](task-overrides/doc-crossref.md)
  and
  [`task-overrides/doc-summarize.md`](task-overrides/doc-summarize.md).
- For structural-element-dropping idioms (headings, table separator
  rows — `doc-verbatim`-shaped tasks): instruction-based steering does
  not reliably fix this at this model size — 4 distinct attempts
  produced a contradictory, noise-dominated picture, not a trend.
  Don't spend further budget on this idiom family here.
- For instruction/prompt-bleed idioms (`doc-surgical`-shaped tasks): a
  boundary-discipline instruction measurably helps on isolated draws
  but the effect is noise-dominated across repeated attempts (3 tried)
  — not a reliable fix yet. `stop` sequences (see "Potential helpers"
  below) are a more promising un-implemented lever than more prompt
  text.
- For substitution-not-applied idioms (`doc-adapt`/`doc-script`-shaped
  tasks): matches `deepseek-r1-1.5b`'s independent "structural limit,
  not a prompting problem" verdict on the same task family — treat as
  a likely capability ceiling at this model size, not a prompting gap.

## Potential helpers (documented, not yet integrated)

- **API-level `stop` sequences** (e.g. `"stop": ["[DOC_END]"]` on
  `/v1/chat/completions`) — targets Idiom Q2 (instruction bleed past a
  document-boundary marker) mechanically instead of relying on a
  textual instruction. Not yet wired into `dispatch.sh`: the existing
  override pattern (`DISPATCH_TEMPERATURE` etc.) is global-per-run, but
  this needs to be per-task (different tasks use different markers —
  `[DOC_END]` vs `[SCRIPT_END]`). Worth a dedicated dispatch-mechanism
  extension if Q2 doesn't respond to prompt-level fixes.

## Setup

- Served by `llama-server-qwen3.5-0.8b.service` on `:8083` (Q4_K_M
  GGUF, CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8083`.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:0.8b`.
- **Required dispatch overrides — do not test this model without these,
  per `AGENTS.md`'s "every dispatch-level tweak must be documented"
  rule:**
  - `DISPATCH_ENABLE_THINKING=false` — **mandatory, not optional.**
    Without it, this model enters an unterminated thinking loop on
    ordinary prompts: the warm-up ping during session setup
    (2026-08-02) hit `finish_reason=length` after 8177 completion
    tokens, 27,081 chars of `reasoning_content`, and an empty final
    answer — reproduces the pre-existing 3/3 runaway-reasoning finding
    already noted in `models/README.md`. Qwen3.5's own model card
    documents this directly: "Qwen3.5-0.8B is more prone to entering
    thinking loops... which may prevent it from terminating generation
    properly." This model family has **no in-prompt `/think`/`/no_think`
    switch** — `chat_template_kwargs.enable_thinking` (now wired into
    `dispatch.sh`, 2026-08-02) is the only control.
  - `DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20
    DISPATCH_PRESENCE_PENALTY=2.0` — the model card's recommended
    **non-thinking-mode, text-task** sampling parameters. `dispatch.sh`
    previously hardcoded `temperature=0.2` for every model; that's well
    outside this model's recommended 0.6-1.0 range and was never
    validated against it. Smoke-tested working (2026-08-02): a trivial
    prompt with all of the above returned a clean 10-token answer,
    `finish_reason=stop`, zero reasoning content.
  - Full reproducible invocation for a docs-role test:
    ```
    DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8083 \
    DISPATCH_ENABLE_THINKING=false DISPATCH_TEMPERATURE=1.0 \
    DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=2.0 \
    bash bench/report.sh qwen3.5:0.8b docs llamacpp 8083
    ```
    (`bench/report.sh`'s own `backend`/`port` positional args only cover
    `DISPATCH_BACKEND`/`LLAMACPP_PORT` — the sampling/thinking overrides
    must be exported separately, they aren't passed through by that
    script.)
- `bash bench/session-start.sh qwen3.5:0.8b llamacpp` stops other local
  hosters and starts this service exclusively — its own warm-up ping
  does NOT set the overrides above, so expect (and ignore) one
  runaway-reasoning warning during session start itself; that warning
  is not evidence about the model's real capability, only about not
  having disabled thinking yet.
- **`tasks/doc-repair/SPEC.md` had a bug, fixed 2026-08-02 (commit
  `8d98d91`), invalidating this model's `doc-repair` result.** Its
  "DEFECT 2" instruction claimed the source table was missing a
  separator row that was, in fact, already present (confirmed via
  `git blame`: present since the task's original import). Fixed by
  removing the separator row from the source so DEFECT 2 is now
  genuinely real. This model's `doc-repair` result (gated out flat
  after run 1 — see the per-task table above) was measured against
  the easier, buggy version and needs a fresh test round; not yet
  re-run for this model as of this write. Found and fixed while
  investigating `qwen3.5:9b`'s `doc-repair` failures — see that
  model's `history.md` for the full diagnosis.

## Further reading

- `history.md` — full per-task diagnostic breakdown of the baseline run
  and the runaway-thinking bug investigation.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:0.8b
  <role>`, with the env vars above).
