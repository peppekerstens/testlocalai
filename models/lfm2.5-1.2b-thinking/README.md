# lfm2.5:1.2b-thinking — steering profile

**Status: preliminary — bare baseline + 3 steering passes across two
sessions, both on the same day.** Treat everything below as an early
read, not a settled verdict like `models/deepseek-r1-1.5b/`'s.

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

**Task-specific follow-up on the 4 preamble-affected tasks: 2/9 PASS**
(`doc-restructure`, and `doc-crossref` on an unchanged SPEC — a per-draw
flip, not a fix). Built `rules/surgical-edit-discipline.md`, a short
block targeted at the literal find-replace task family, replacing the
blanket preamble on `doc-surgical`/`doc-adapt`/`doc-script`/`doc-repair`
only. None of the 4 passed outright but each moved: `doc-surgical`'s
wrong-SDK-name leakage is fully fixed but a new idiom appeared instead
(fabricated "document isn't visible" narration — Idiom F); `doc-adapt`
narrowed from 5 broken edits to 2; `doc-script` didn't move (its gap is
dropped script content, not wrong tokens — the current instruction
doesn't target that); `doc-repair` is down to one remaining defect (a
literal closing fence not emitted) — closest to solved. Full breakdown:
`reports/report-docs-20260802-102044.md` and `history.md`'s "Task-specific
steering pass on the 4 preamble-affected tasks". Single draw per task —
next step is 2-3 more draws per task before trusting any of this as a
rate, plus a `doc-script`-specific completeness instruction and a
`doc-surgical`-specific fix for Idiom F.

**A 7-bullet expansion of the rules block was tried and reverted** —
adding 3 more grounded bullets made all 4 targeted tasks worse, not
better (see `history.md`'s "Phase 2 run 2"). **Do not re-attempt
expanding `rules/surgical-edit-discipline.md` further** as the next
lever; this model's tolerance for instruction-block length on this task
family appears to already be at its ceiling at 4 bullets.

**Confirm (3-loop consistency check) result: the steered tasks are
stable, the pass-count swing is not theirs.** Re-running the docs role 3
more times against the reverted 4-bullet state gave 0/9, 2/9, 1/9 — but
per-task tracing shows `doc-surgical`/`doc-adapt`/`doc-script`/
`doc-repair` (the tasks actually steered this session) FAILED all 3
runs with no exceptions. Every bit of the pass-count swing is
`doc-restructure` (bare, previously 100% reliable, failed once with a
genuine content defect) and `doc-crossref` (already known unstable, see
above) — neither touched by this session's work. **Decision: keep the
current 4-bullet state, do not revert** — nothing tried so far (blanket
preamble, bare, 4-bullet, 7-bullet) has produced a full PASS on these 4
tasks, and the 4-bullet version has the best measured content quality of
everything tried. Full breakdown: `history.md`'s "Confirm" section.
**This quality loop's Phase 2 is exhausted at diminishing returns** (2
of 5 runs used, the 2nd made things worse) — next step per
`AGENTS.md`'s quality loop is Phase 3 (check other models' `history.md`
for this same docs role for transferable idioms) rather than more
bullets on this same rules file.

**Phase 3 (cross-model idiom transfer from `deepseek-r1-1.5b`, 2 of 5
runs used): no new PASS, but a clear negative result worth keeping.**
R1's README independently lists the exact same 5 tasks
(`doc-verbatim`/`doc-surgical`/`doc-adapt`/`doc-script`/`doc-repair`) as
a structural ceiling at that model's scale — cross-model support for
Phase 2's plateau being a real limit, not under-steering. R1's other two
validated fixes (STE writing style, fact-checklist-with-count) turned
out to already be baked into `doc-crossref`/`doc-summarize`'s shared
bare SPECs and were already failing for lfm2.5 regardless — not new
levers. **Applying STE fresh where it wasn't already present
(`doc-summarize`) made it measurably worse** (10 words vs. 17-20 in
every other variant) — a confirmed negative transfer, the opposite of
R1's result, consistent with this model's under-elaboration idiom
(Idiom A/E) rather than R1's. **Do not apply STE to this model on tasks
in that idiom family.** Reverted `doc-summarize`/`doc-crossref` to bare
(bare is empirically best for both, though neither passes); kept a
narrow placeholder-echo warning on `doc-synthesize` (no STE), which
recovered its required heading without closing the task. Full
breakdown: `history.md`'s "Phase 3" sections.

**Running total across Phases 2+3: ~9 SPEC variants tried, one
consistent pattern — additional instruction text has never net-improved
this model's docs-role performance, and has regressed it more than once**
(Idiom E, Idiom F, and now STE's negative transfer). Worth treating as
the headline finding for this role, not just a step toward one.

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
   instead. A narrower version of this same instruction later fixed
   `doc-surgical`'s specific wrong-content leakage but produced a new
   variant instead — fabricated "the document isn't visible" narration
   (Idiom F, see `history.md`) — so this idiom isn't closed, just
   changed shape.
6. **Blanket rules blocks can measurably shrink this model's output
   (Idiom E).** The general `output-discipline.md` preamble cut output
   length 6–14x on `doc-surgical`/`doc-adapt`/`doc-script`/`doc-repair`
   without fixing their content errors — a general-purpose meta-rules
   block prepended ahead of the task appears to cost this small thinking
   model attention it needs for the actual task. Prefer a short,
   task-family-specific instruction (see `rules/surgical-edit-discipline.md`)
   over a general one for this model.
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
