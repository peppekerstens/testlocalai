# lfm2.5:1.2b-thinking — steering profile

**Status: preliminary — one bare baseline + one steering pass, both on
the same day, work paused mid-iteration.** Treat everything below as an
early read, not a settled verdict like `models/deepseek-r1-1.5b/`'s.

**Role: documenter/reasoner** (same combined role as deepseek-r1 — see
its README for the doc/reason track split). Tracks: `tasks/doc-*` +
`tasks/reason-*`.

## Current status

**Bare baseline (no steering), full 18-task doc+reason suite: 3/18
PASS** (`doc-restructure`, `reason-multihop`, `reason-coverage`) — already
ahead of deepseek-r1's bare baseline (1/18) at this stage, and notably
passes `reason-multihop` bare, which R1 never solved even after a full
steering pass. **Zero context-truncation warnings across all 18 tasks** —
no task came anywhere near the 8192 context ceiling, unlike R1's
runaway-reasoning tail risk (see `models/deepseek-r1-1.5b/history.md`).

**One general steering pass (an "output discipline" rules block covering
meta-commentary suppression, exact-identifier preservation, completeness
self-checking, and verbatim-copy fidelity), applied to all 15 bare
failures: 0/15 on the next draw.** Not a clean win, but not a wash either
— see `history.md` for the honest per-task breakdown (real regressions,
real improvement, and several unchanged).

**Docs-only re-test + bare-vs-steered comparison (2026-08-02, session
2): 1/9 PASS with the blanket preamble still applied, 0/8 flipped to
PASS on a re-dispatched bare comparison — but the comparison surfaced a
new idiom.** The blanket `output-discipline.md` preamble measurably
*shortens* this model's output (6–14x smaller) on `doc-surgical`,
`doc-adapt`, `doc-script`, and `doc-repair`, without fixing the
underlying content errors (forbidden/missing tokens persist in the
longer bare answers too) — see `history.md`'s "Idiom E: preamble-induced
compression." **This changes the diagnosis from session 1's "unfinished,
needs task-specific follow-up on top of the blanket block" to "the
blanket block itself needs to go for the affected tasks before any
task-specific follow-up is worth doing."** Not yet acted on — the next
step is dropping the preamble on those 4 tasks and pairing narrower,
task-specific instructions instead. `doc-verbatim`/`doc-synthesize` are
unaffected by the preamble either way; something else drives those.
Single comparison draw per task — see `history.md` for the sample-size
caveat before treating this as a settled rate.

**A real infrastructure bug was found and fixed during this pass**, not
specific to this model's quality: LFM2.5 embeds its `<think>...</think>`
block *inline* in `content` (unlike R1, which returns it in a separate
`reasoning_content` field) — `dispatch.sh`'s strip regex was non-greedy
and only removed the *first* `<think>…</think>` pair, so a stray, unpaired
second `</think>` (from the model's post-think narration occasionally
slipping back into thinking-style prose) survived into the final output
and corrupted it once (broke bash syntax on `doc-script`). Fixed:
`dispatch.sh` now strips through the *last* `</think>`, not the first.

## How to optimize (preliminary — verify before trusting)

These are diagnosed idioms from the one steering pass so far, not proven
fixes:

1. **Meta-commentary/wrapper-tag leakage.** LFM2.5 sometimes adds
   `[DOC_START]`/`[DOC_END]`-style wrapper tags or narrates its own edit
   ("(Note: the original content is assumed present)") even when
   explicitly told not to — this got *worse*, not better, after adding an
   explicit instruction against it on one task (`doc-surgical` regressed
   to a near-empty, still-wrapped output). Don't assume more emphasis on
   an already-stated rule helps; it may trigger over-compliant truncation
   instead.
2. **Exact-identifier preservation is a real, partially fixable gap.**
   Several failures were dropping a specific required exact phrase or
   tool name (`reason-diagnose`'s `Missing required environment
   variable`, `doc-crossref`'s `describe_obfuscation_policy`). One task
   (`reason-trace`) gained its missing exact phrase after steering;
   most others didn't move — inconsistent enough that this needs
   task-specific follow-up, not blanket "use exact words" instructions.
3. **Under-elaboration / dropped required facts** was the single most
   common idiom across the reason-* failures — answers were technically
   on-topic but too compressed to include every explicitly required
   element. Not resolved by the general steering pass.
4. **Verbatim-copy fidelity is close but not solid.** `doc-verbatim` went
   from two structural mismatches (dropped fence + dropped blank line) to
   one (just the blank line) after steering — the closest of any failing
   task to a real fix, worth another targeted pass.
5. **Do not apply the `DISPATCH_NOTHINK`-style raw-completion prefill
   trick built for R1 to this model without adapting it first** — it
   would need LFM2.5's own chat-template turn tokens (verify via
   `/props`, don't assume R1's `<｜User｜>`/`<｜Assistant｜>` tokens work
   here), and Liquid ships a separate non-thinking `LFM2.5-1.2B-Instruct`
   checkpoint as the more principled equivalent — worth trying instead of
   prefill-hacking the Thinking checkpoint, not yet tested either way.

## Setup

- Served by `llama-server-lfm2.service` on `:8082` (Q4_K_M GGUF, CUDA),
  context `-c 8192`; run bench with `LLAMACPP_PORT=8082`.
- Downloaded 2026-08-01: `LiquidAI/LFM2.5-1.2B-Thinking-GGUF`,
  Q4_K_M, ~731MB. License: LFM Open License v1.0 (Apache-derived,
  free under $10M annual revenue).
- Whitelisted in `bench/dispatch.sh` as `lfm2.5:1.2b-thinking`.

## Further reading

- `history.md` — full per-task diagnostic breakdown of the baseline
  failures and the steering pass results.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence going forward (`bash bench/report.sh
  lfm2.5:1.2b-thinking <role>`).
