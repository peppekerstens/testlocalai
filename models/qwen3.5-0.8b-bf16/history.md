# qwen3.5:0.8b-bf16 — steering history

First real testing session, 2026-08-02.

## Phase 0: dispatch fix confirmed transferring from the Q4_K_M variant

`bench/session-start.sh qwen3.5:0.8b-bf16 llamacpp`'s warm-up ping
reproduced the same runaway-thinking bug as the Q4_K_M variant:
`finish_reason=length` after 8177 completion tokens, 30,290 chars of
`reasoning_content`, empty final answer. Smoke-tested the same fix
(`DISPATCH_ENABLE_THINKING=false` + the model card's non-thinking
sampling params): clean 3-token response, zero reasoning content,
confirmed working for this precision variant too — expected, since
`enable_thinking` and the recommended sampling parameters aren't
precision-specific, but verified rather than assumed per this
project's own discipline.

## Phase 1: reference baseline (docs role, 9 tasks)

`reports/report-docs-20260802-130512.md`: **1/9 PASS** (`doc-crossref`).
No truncation. Single draw.

**Same 5 idioms as `qwen3.5-0.8b` (Q4_K_M), same task shapes affected**
— strong cross-precision evidence these are model-architecture idioms:

- **Idiom Q1 (structural dropping)**: `doc-verbatim`, `doc-repair`,
  `doc-restructure`. `doc-verbatim`'s failure is more severe on this
  draw than typically seen on Q4 — duplicated the entire prompt
  content (including the instruction line itself), not just a
  near-miss copy. Single draw; not yet clear if that's a precision
  effect or ordinary per-draw variance.
- **Idiom Q2 (instruction bleed)**: `doc-surgical` — reproduces the
  `OUTPUT FORMAT (strict):` leak into the output, same shape as Q4.
- **Idiom Q3 (substitution not applied)**: `doc-adapt`, `doc-script` —
  identical forbidden/missing tokens to Q4's baseline.
- **`doc-crossref` passes bare** on this draw — matches the
  already-documented per-draw instability on this exact task across
  every model tested in this project (Idiom Q4 territory), not
  evidence this variant lacks the idiom.
- `doc-summarize`/`doc-synthesize`: same missing-fact/missing-structure
  shape as Q4.

**Research-phase plan**: `qwen3.5-0.8b` (Q4_K_M) is the natural
cross-precision hypothesis source — same model, already has validated
specialist configs for 3 tasks. Testing those directly rather than
inventing new fixes from scratch.

## Steering: cross-precision transfer from qwen3.5-0.8b (Q4_K_M)

**Run 1** (`reports/report-docs-20260802-130746.md`, 2/9): copied
`qwen3.5-0.8b`'s exact `doc-crossref`/`doc-summarize`/`doc-script`
overrides unmodified. **`doc-crossref` and `doc-summarize` PASS
immediately** — strong cross-precision transfer, no adaptation needed.
`doc-script` still FAILs, same shape as Q4's stable-partial state.

**Run 2** (`reports/report-docs-20260802-130926.md`, 2/9): gave the
remaining 6 tasks their first specialist attempt, reusing Q4's rules
files directly. **`doc-synthesize` PASSES** — the *opposite* of Q4's
result with the identical instruction (Q4 regressed under this exact
lever) — first clear evidence a fix's effect isn't guaranteed to
transfer across precision even when the underlying idiom does.
`doc-summarize` flipped to FAIL this draw (unchanged override) — first
sign of the same per-draw instability already documented for this task
on Q4. `doc-verbatim`/`doc-surgical`/`doc-adapt`/`doc-repair` all
showed real partial improvement without a full PASS; `doc-restructure`
showed the same task-nature conflict already found on Q4 (instruction
says preserve structure, task requires transforming it) — **gated out,
reverted to bare**.

**Run 3** (`reports/report-docs-20260802-131130.md`, 1/9): re-dispatched
the 4 promising tasks plus `doc-crossref`/`doc-summarize`/
`doc-synthesize` unchanged, as a 2nd-draw stability check.
`doc-crossref` flipped back to FAIL, `doc-summarize` flipped back to
PASS, `doc-synthesize` flipped to FAIL — all 3 now show clear
per-draw instability, matching Q4's own ~67%-not-100% reliability
pattern rather than being clean wins. `doc-verbatim`/`doc-surgical`/
`doc-adapt`/`doc-repair` stayed FAIL on both draws with consistent
partial improvement over bare each time — stable partials, same
category as `doc-script`.

**Tier 1 closed**: outcome closely mirrors the Q4_K_M variant's —
3 tasks with real but flaky reliability (`doc-crossref`,
`doc-summarize`, `doc-synthesize`), 5 stable partials without a full
PASS (`doc-verbatim`, `doc-surgical`, `doc-adapt`, `doc-repair`,
`doc-script`), 1 gated to bare (`doc-restructure`). Moving to Confirm
to quantify the 3 flaky tasks' real reliability.
