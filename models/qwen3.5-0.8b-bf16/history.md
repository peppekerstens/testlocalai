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
