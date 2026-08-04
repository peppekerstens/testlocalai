# Cross-model research: docs role, candidates for `qwen3.5:0.8b`

Generated 2026-08-04T19:27:06Z by bench/loop.sh's Research phase (cross-model idiom check only — external/web research is NOT automated, stays manual). Map-reduce: one extraction call per source model, then one combining call.
Source models checked: lfm2.5-1.2b-thinking qwen3.5-0.8b-bf16 qwen3.5-2b qwen3.5-4b qwen3.5-9b

## Candidate techniques for `qwen3.5:0.8b`, docs role

Sourced from cross-model idiom summaries per AGENTS.md's Research phase. **Every entry below is a hypothesis only** — cross-model transfer has backfired before (STE: validated on deepseek-r1-1.5b, negative-transferred to lfm2.5-1.2b-thinking, per AGENTS.md/history.md), so each must be tested bare-vs-steered on qwen3.5:0.8b before being trusted, even when the source model is another qwen3.5 variant.

Note: qwen3.5-0.8b-bf16 is presumably the same/closest model already in this family (own diagnosed idioms: doc-crossref/summarize transfer success ~67%, doc-synthesize noise/reverted, doc-adapt partial divergence, doc-verbatim/surgical/repair/script stable partials, doc-restructure gated dead end). The candidates below are additional levers pulled from *other* models' histories that haven't yet been tried on 0.8b.

1. **Avoid blanket output-discipline preambles** — targets: any task, general lever (not task-specific).
   Source: lfm2.5-1.2b-thinking (Idiom E).
   Technique: do NOT prepend a generic `output-discipline.md` preamble to SPECs; it compressed final answers 13-14x on doc-surgical/doc-script/doc-repair without fixing underlying content errors.
   Caveat: this is a "don't do X" finding from a different model family/size; 0.8b may not exhibit the same compression response to blanket preambles at all — verify the failure mode exists here before treating the avoidance as necessary.

2. **Short, task-specific rules block over long ones (rule-count threshold)** — targets: doc-surgical/doc-adapt/doc-script/doc-repair (find-replace family).
   Source: lfm2.5-1.2b-thinking.
   Technique: prefer a short (~4-bullet) task-specific `surgical-edit-discipline.md` over a longer (7-bullet) version of the same rules; more rules measurably worsened all 4 targeted tasks there.
   Caveat: threshold location (4 vs 7) is model-specific tuning; do not assume 0.8b's threshold is the same number — treat only the *direction* ("more rules can hurt") as transferable, re-tune the count for 0.8b.

3. **Do not use STE (Simplified Technical English) for under-elaboration tasks** — targets: doc-summarize, doc-synthesize (or 0.8b's structural analogs).
   Source: deepseek-r1-1.5b (originated fix) → lfm2.5-1.2b-thinking (confirmed negative transfer).
   Technique: this is itself a negative-transfer warning, not a fix to adopt — STE's "~20 words/sentence" framing got read as a brevity instruction and cut output length below even bare baseline.
   Caveat: explicitly flagged in AGENTS.md as the canonical example of backfiring transfer; if 0.8b already avoids STE, no action needed, but if any existing 0.8b override embeds STE-style sentence-length framing, treat it as suspect and test dropping it.

4. **Mechanism-reminder override for backwards semantic attribution** — targets: doc-crossref (if 0.8b exhibits a tool-described-as-performing-an-action idiom).
   Source: qwen3.5-2b (Q5, confirmed 3/3).
   Technique: task-specific `mechanism-reminder-crossref.md` clarifying that a tool *reports/describes* an action rather than *performs* it.
   Caveat: qwen3.5-0.8b-bf16's own history already logs doc-crossref as a transfer-success task (~67%, mechanism unspecified) — check whether this is the same fix already applied before treating it as new; if the 0.8b idiom shape differs (e.g. no backwards-attribution error), this technique doesn't apply.

5. **Reuse `structure-preservation.md` for merged/reflowed-line drops** — targets: doc-verbatim.
   Source: qwen3.5-2b (Q1), itself reused from 0.8b's own history.
   Technique: apply `structure-preservation.md` to fix line-merging/blank-line-drop defects; got 2b down to a single stable 1-line defect (never full PASS).
   Caveat: qwen3.5-0.8b-bf16's history already lists doc-verbatim as a "stable partial" — this file may already be in use at 0.8b; confirm before re-applying, and note that a *more* explicit follow-up instruction made things worse at 2b (leaked instruction text into output) — don't escalate specificity if the simple version underperforms.

6. **Avoid combined boundary+edit-verification overrides for `[DOC_END]`-style instruction bleed** — targets: doc-surgical.
   Source: qwen3.5-2b (Q2) — negative result.
   Technique: this is a caution, not a fix — `boundary-discipline.md`+`edit-verification.md` combined caused a catastrophic regression (degenerate ~8x repetition loop) at 2b, a new failure mode not seen at 0.8b.
   Caveat: single-draw finding, not retried, so may be noise even at 2b; but given the severity (repetition loop) if 0.8b's own doc-surgical history mentions similar leakage, test any multi-file combined override cautiously and roll back immediately on repetition symptoms.

7. **`enable_thinking=false` for runaway-thinking truncation** — targets: any task, general config lever (not steering-file based).
   Source: qwen3.5-4b, confirmed mandatory fix (eliminated 44% empty-output rate).
   Technique: disable thinking mode entirely if qwen3.5:0.8b shows empty/truncated outputs from context-ceiling exhaustion during reasoning.
   Caveat: this fixed a *config*-level defect specific to 4b's reasoning verbosity; only worth trying if 0.8b actually exhibits empty-output truncation — if 0.8b never runs out of context on this role, this lever is irrelevant and shouldn't be applied preemptively.

8. **GBNF grammar transfer for doc-verbatim blank-line placement** — targets: doc-verbatim.
   Source: qwen3.5-9b (originated) → qwen3.5-4b (transferred structurally, 7/7 PASS).
   Technique: structural GBNF grammar forcing blank-line/fence positions while leaving content free, after repeated prompt-only fixes failed.
   Caveat: this is a bigger investment (grammar authoring) than a prompt override; only pursue after prompt-level techniques (#5 above) are exhausted on 0.8b, and confirm 0.8b's harness even supports GBNF grammars the way 4b/9b's does.

9. **GBNF grammar transfer for doc-restructure missing table separator row** — targets: doc-restructure.
   Source: qwen3.5-9b (originated) → qwen3.5-4b (transferred, 8/8 PASS).
   Technique: structural-only grammar forcing header/separator/row shape, cell text left free.
   Caveat: qwen3.5-0.8b-bf16's own history logs doc-restructure as a "gated dead end" — a grammar-based structural fix is a fundamentally different lever than whatever was tried before, so it's worth a fresh look, but confirm the dead-end wasn't itself a grammar attempt before re-trying.

10. **Named forbidden-token reminder for doc-synthesize/doc-script bleed** — targets: doc-synthesize, doc-script (e.g. leaking `zod` or leftover token in a merged edit).
    Source: qwen3.5-4b (doc-synthesize, 6/6 stable) and qwen3.5-9b (doc-script, explicit "both original lines must be gone" + named token, 7/7 stable).
    Technique: an override that explicitly names the forbidden token and states the completeness condition (both source lines/instances must be removed), rather than a generic "no forbidden tokens" rule.
    Caveat: qwen3.5-0.8b-bf16's own history already flags doc-synthesize as "noise, reverted" with a *different* steering attempt — this named-token variant hasn't been tried at 0.8b specifically, so it's worth a fresh single-draw test, but don't assume it'll succeed just because the shape looks similar at 4b/9b.

11. **Fix shared SPEC.md bug rather than steer the model** — targets: doc-repair.
    Source: qwen3.5-9b (traced FAIL to a canonical task-file bug, not a model gap; fixed file → 5/5 bare pass).
    Technique: before writing any doc-repair steering file for 0.8b, re-check whether 0.8b's FAILs are actually caused by the same SPEC.md defect (a task description claiming a separator row is missing when it's already present) — if so, this is a project-wide fix, not a per-model one.
    Caveat: qwen3.5-4b explicitly did NOT get fixed by this same SPEC fix (stayed 3/6) despite the bug being real — confirmed the fix is necessary-but-not-sufficient per model, so expect it may not fully resolve 0.8b's doc-repair even if the SPEC bug is present and worth fixing regardless.

12. **doc-surgical content-drop (dropped "(" / prefix in literal replacement) — treat as possible structural ceiling** — targets: doc-surgical.
    Source: qwen3.5-9b (5 distinct prompt fixes all failed; near-literal grammar was invalid/tautological; bounded-free-text grammar caused runaway generation) and qwen3.5-4b (checklist-reminder failed 3/3, "confirmed stable-FAIL", noted as cross-model consistent with 9b).
    Technique: this is a negative-result catalog, not a fix — useful mainly to set expectations low and avoid re-deriving the same 5+ failed prompt variants on 0.8b from scratch.
    Caveat: 0.8b's own history already lists doc-surgical as a "stable partial," so the failure shape may differ from 9b/4b's; don't assume the ceiling transfers — but if 0.8b's steering attempts start converging on the same failed shapes (word reminder, verbatim-quote leaking example text, checklist reverting the edit), stop early per the quality-loop's stop-early rule rather than re-running all 5 variants.
