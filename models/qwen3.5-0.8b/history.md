# qwen3.5:0.8b — steering history

First real testing session, 2026-08-02.

## Pre-baseline: the runaway-thinking bug, confirmed and fixed

Before any task-suite run, `bench/session-start.sh qwen3.5:0.8b
llamacpp`'s own warm-up ping reproduced the runaway-reasoning failure
mode already noted in `models/README.md` (0.8B/0.8B-bf16/2B, 3/3 on a
trivial prompt): `finish_reason=length` after 8177 completion tokens,
27,081 chars of `reasoning_content`, empty final answer. Cross-checked
against the official Qwen3.5-0.8B model card (Hugging Face, fetched
2026-08-02), which independently documents exactly this: "Qwen3.5-0.8B
is more prone to entering thinking loops... which may prevent it from
terminating generation properly," and states this model family has no
in-prompt `/think`/`/no_think` switch — `chat_template_kwargs.
enable_thinking` is the only supported control, which `dispatch.sh` had
never sent (added this session — `DISPATCH_ENABLE_THINKING` env var).
The model card's recommended non-thinking-mode sampling parameters
(temperature 1.0, top_p 1.0, top_k 20, presence_penalty 2.0) also
replace `dispatch.sh`'s previous hardcoded `temperature=0.2`, which was
never validated against this model and is well outside its recommended
0.6-1.0 range. Smoke-tested working before the real baseline: a trivial
prompt with all of the above returned a clean 10-token answer,
`finish_reason=stop`, zero reasoning content. See `README.md`'s Setup
section for the exact reproducible invocation.

## Phase 1: reference baseline (docs role, 9 tasks)

`reports/report-docs-20260802-113029.md`: **1/9 PASS** (`doc-summarize`
only). No truncation — all 9 tasks `finish_reason=stop`, confirming the
`enable_thinking` fix holds across a full role, not just one prompt.
Single draw (n=1) throughout — first run for this model, no prior
history to check idiom stability against yet.

**Five idioms diagnosed, some new to this model, some cross-model
reproductions:**

- **Idiom Q1 — structural-element dropping (headings, table separator
  rows).** The single most common failure this run: `doc-verbatim`,
  `doc-repair`, and `doc-restructure` (3 of 8 FAILs) all dropped a
  heading and/or a markdown table separator row while otherwise
  preserving content correctly — `doc-repair` in particular performed
  both required repairs correctly and failed purely on the dropped
  heading/blank line, the closest FAIL to a real fix this run. Distinct
  from `lfm2.5-1.2b-thinking`'s near-total content loss on the same
  copy task (`doc-verbatim`) — this model keeps far more content, loses
  specific structural markers instead.
- **Idiom Q2 — instruction/prompt bleed into output.** `doc-surgical`'s
  raw output didn't stop at the document's `[DOC_END]` marker — it
  continued copying the edit instructions and `OUTPUT FORMAT (strict):`
  block verbatim into the answer, on top of not applying any of the 3
  required edits (all 3 pre-edit forbidden tokens survived unchanged).
  Not observed in this shape on either other model tested in this
  project.
- **Idiom Q3 — substitution not applied.** `doc-adapt` and `doc-script`
  both kept pre-edit forbidden tokens (`npm`/`node dist`,
  `node `/`dist/index.js`) instead of applying the required C#-port
  substitutions. Matches the already-documented idiom on both
  `deepseek-r1-1.5b` (called a structural ceiling there — "not suitable,
  not a prompting problem," 3 historical steering rounds) and
  `lfm2.5-1.2b-thinking` (Phase 2, never fully resolved either).
- **Idiom Q4 — `doc-crossref`'s specific identifier drop, now confirmed
  on 3 of 3 models tested in this project.** Missing exactly
  `describe_obfuscation_policy` (Source A), Source B's
  `obfuscated.invalid` fact correct — the identical gap independently
  diagnosed on `deepseek-r1-1.5b` and `lfm2.5-1.2b-thinking`. Three
  independent ~1-2B models, same specific fact dropped, same specific
  fact kept. Worth treating as a cross-model finding (possibly a
  task-construction fragility, not purely a per-model weakness), not
  just re-logging it three separate times.
- **Idiom Q5**: `doc-synthesize` shows the best partial performance of
  any model's bare baseline on this task so far (fenced JSON block
  present, only missing bullets + one token) — worth noting as a
  relative strength, not just a FAIL.

**Not yet done**: Phase 2 (task-specific steering) has not started.
Idiom Q1 is the clear highest-leverage first target (task-agnostic,
3 of 8 failures, closest-to-passing task `doc-repair` included), but per
the quality loop, 2-3 more bare draws to confirm idiom stability before
spending steering budget is the recommended next step — see the
report's Suggested next steps.

## Correction: the above baseline was contaminated, re-run confirms it anyway

Immediately after the Phase 1 baseline above, starting Phase 2 revealed
6 of 9 `tasks/doc-*/SPEC.md` files still carried leftover
`lfm2.5-1.2b-thinking` steering text from that model's own quality loop
earlier this session — `doc-verbatim`, `doc-surgical`, `doc-adapt`,
`doc-script`, `doc-synthesize`, `doc-repair` were dispatched against
that model's task-specific prompts, not bare ones, mischaracterized as
"bare baseline" above. Root cause and fix: `bench/pure-run.sh` had no
per-model prompt resolution — doc-task steering had been done by
directly overwriting the shared `SPEC.md`, unlike `bench.sh`'s existing
non-destructive `--rules` mechanism for code tasks. Fixed in
`bench/pure-run.sh` (now checks `models/<model-dir>/task-overrides/
<task>.md` first, falling back to bare `SPEC.md`) — see `AGENTS.md`'s
"Per-model doc-task steering" rule. All 9 `tasks/doc-*/SPEC.md` restored
to true bare; `lfm2.5-1.2b-thinking`'s exact tested state preserved
under its own `task-overrides/`, verified byte-identical to what its
reports actually dispatched — no evidence lost.

**Re-ran the docs role against the now-verified-bare SPECs**:
`reports/report-docs-20260802-114242.md`, still **1/9 PASS**, but a
*different* task passing (`doc-crossref`, not `doc-summarize`) — pure
per-draw noise, confirmed because those two tasks' SPECs were never
contaminated in the first place (identical prompt both times). **All 5
idioms (Q1-Q5) reproduced on the corrected run**, several more clearly:
Q2 (`doc-surgical`'s instruction bleed) came back *worse* — duplicated
content plus the entire edit-instructions block copied verbatim,
stronger confirmation this is a real, robust idiom rather than an
artifact of the contaminated prompt. `doc-script` showed real
improvement (1 forbidden token instead of 2, required tokens now pass).
**Bottom line: the contamination was a real methodological error worth
fixing at the harness level (done), but it did not invalidate the
substantive idiom diagnosis** — every idiom identified from the flawed
run held up when re-tested cleanly. Retraction note added to the top of
the original report; it stays on disk as evidence of a second (steered)
draw rather than being deleted.

**Phase 1 is now genuinely complete and verified.**

## Research phase (per the restructured quality loop — always both, before any steering)

**Cross-model idiom check** (`deepseek-r1-1.5b`, `lfm2.5-1.2b-thinking` —
the only other models tested against this role):
- **No validated fix found for Idiom Q1** (structural-element/heading/
  table-separator dropping). `lfm2.5-1.2b-thinking`'s own README lists
  "structural elements (headings, fence placement)" as its own
  still-open gap, never resolved across its whole closed loop. Genuinely
  open problem across every model tested in this project so far, not
  just this one.
- **No prior instance of Idiom Q2** (instruction/prompt bleed past a
  document-boundary marker) on either other model. New to this project.
- **Idiom Q3 (substitution not applied) gets a useful negative
  signal**: `deepseek-r1-1.5b`'s README calls this exact task family
  "Not suitable — structural limit... Not a prompting problem," failing
  across 3 historical steering rounds. Treat as a warning against
  over-investing Steering-phase budget on `doc-adapt`/`doc-script`
  before trying the higher-confidence Q1/Q2 levers first.

**External research**: Qwen3.5-0.8B's own model card doesn't cover
formatting/structural-preservation prompting specifically (checked
during Phase 0). General search for small-model techniques to prevent
generation from continuing past a document-boundary marker surfaced a
concrete, real lever: **API-level `stop` sequences** (e.g. passing
`"stop": ["[DOC_END]"]` on `/v1/chat/completions`) mechanically halt
generation the moment the model starts emitting the marker, instead of
relying on the model "understanding" a textual instruction not to
continue — directly relevant to Idiom Q2. **Not yet implemented**:
`dispatch.sh`'s existing override pattern (`DISPATCH_TEMPERATURE` etc.)
is global-per-run, but this needs to be per-task (different tasks use
different markers — `[DOC_END]` for `doc-surgical`/`doc-adapt`,
`[SCRIPT_END]` for `doc-script`) — logging as a documented helper for a
future dispatch-mechanism extension rather than half-implementing it
mid-loop. See `README.md`'s "Potential helpers" for the persisted
version of this finding.

Proceeding to the Steering phase: Q1 first (task-agnostic, no cross-model
fix to borrow, affects the most tasks), Q3 deprioritized per the
cross-model negative signal.
