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
