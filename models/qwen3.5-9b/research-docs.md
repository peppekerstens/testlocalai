# Cross-model research: docs role, candidates for `qwen3.5:9b`

Generated 2026-08-04T20:01:13Z by bench/loop.sh's Research phase (cross-model idiom check only — external/web research is NOT automated, stays manual). Map-reduce: one extraction call per source model, then one combining call.
Source models checked: lfm2.5-1.2b-thinking qwen3.5-0.8b-bf16 qwen3.5-0.8b qwen3.5-2b qwen3.5-4b

## Candidate techniques for qwen3.5:9b, docs role

General caveat (applies to every item): every technique below is a hypothesis carried over from a different model, not a proven fix for qwen3.5:9b. A technique validated on one model has already backfired when moved to another (STE negative-transferred from deepseek-r1-1.5b to lfm2.5-1.2b-thinking, per AGENTS.md/history.md). Treat every entry as something to test via Steering + Confirm, not applied directly. Note: qwen3.5-4b's doc-verbatim/doc-restructure grammar fixes were transferred FROM qwen3.5-9b itself, so those are not external candidates for 9b.

- doc-repair — runaway-thinking truncation -> DISPATCH_ENABLE_THINKING=false. Source: qwen3.5-4b (confirmed, zero truncation across full 9-task re-test). Caveat: verify 9b exhibits the same truncation symptom first; env-level change may also affect other tasks.

- doc-crossref — exact-fact reminder naming the specific dropped fact (describe_obfuscation_policy). Source: qwen3.5-0.8b (confirmed cross-model on 3 models, ~67% reliability). Caveat: fact-specific — if 9b drops a different fact, reminder needs re-targeting; unproven at 9b's scale.

- doc-summarize — sharpened single-fact/word-limit reminder. Source: qwen3.5-0.8b (confirmed, ~67%). Caveat: same-family instruction regressed the sibling task doc-synthesize on qwen3.5-0.8b-bf16 — validate per-task, don't apply blanket.

- doc-verbatim/doc-repair — explicit structure-preservation instruction. Source: qwen3.5-0.8b-bf16 (stable partial, never full PASS) and qwen3.5-0.8b (contradictory across draws, reverted). Caveat: weak/disagreeing even between the two 0.8b precisions — low confidence for 9b.

- doc-restructure — do NOT apply structure-preservation instruction (anti-pattern). Source: qwen3.5-0.8b-bf16 and qwen3.5-0.8b, both confirming it conflicts with the task's transform job and regresses it. Caveat: 9b likely already has a working grammar-based fix here (per 4b summary), so this may be moot.

- doc-surgical — boundary-discipline instruction to reduce prompt bleed. Source: qwen3.5-0.8b (reverted, not solved) and qwen3.5-0.8b-bf16 (partial, not full fix). Caveat: qwen3.5-4b independently concluded this task's defect is content-fidelity not structural and unfixable via grammar, "cross-model consistent with 9b" — 9b may already have a known ceiling here.

- doc-surgical — API-level stop sequence (e.g. "stop": ["[DOC_END]"]). Source: qwen3.5-0.8b (identified via research, never tried on any model). Caveat: harness-level, mechanically different from failed prompted-compliance attempts, but zero empirical track record anywhere.

- doc-adapt — do NOT bother with edit-verification-style instructions (anti-pattern). Source: qwen3.5-0.8b, matching deepseek-r1-1.5b's independent "structural limit, not a prompting problem" verdict. Caveat: cross-model convergence strengthens this signal, but both source models are far smaller than 9b.

- doc-script — edit-verification instruction (marginal, stable partial only). Source: qwen3.5-0.8b. Caveat: same instruction family as the doc-adapt failure; low confidence.

- doc-synthesize — do NOT apply exact-fact-reminder/edit-verification steering (anti-pattern). Source: qwen3.5-0.8b (regressed: lost JSON block, hallucinated forbidden token) and qwen3.5-0.8b-bf16 (0/3 in Confirm, diagnosed as noise). Caveat: both 0.8b precisions converge on "leave bare" via different mechanisms; assumption that this generalizes to 9B params is untested.

- Under-specified, flagged for follow-up only (technique text not available in this extraction): qwen3.5-2b's "Q5 backwards attribution" (fixed & confirmed) and "Q1 structural dropping" (partial, unconfirmed) — pull qwen3.5-2b's own history.md before attempting. qwen3.5-2b's "Q2 boundary violation" (fix caused regression) and "Q3 formatting" (fix ineffective) are negative signals only. lfm2.5-1.2b-thinking's six labeled idioms (under-elaboration, preamble-induced compression, task-specific micro-steering partial win, hallucinated narration, STE negative transfer, verbatim-copy ceiling) have no technique detail available here; the STE item is the canonical negative-transfer example (deepseek-r1-1.5b -> lfm2.5-1.2b-thinking) motivating validation of every candidate above before use on qwen3.5-9b.
