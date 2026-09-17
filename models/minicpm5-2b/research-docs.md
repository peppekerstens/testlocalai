# Cross-model research: docs role, candidates for `minicpm5:2b`

Generated 2026-09-17T10:57:36Z by bench/loop.sh's Research phase (cross-model idiom check only — external/web research is NOT automated, stays manual). Map-reduce: one extraction call per source model, then one combining call.
Source models checked: lfm2.5-1.2b-thinking qwen3.5-0.8b qwen3.5-0.8b-bf16 qwen3.5-2b qwen3.5-4b qwen3.5-4b-gsq qwen3.5-9b qwen3.8-27b-gsq-rco

## Candidate techniques for `minicpm5:2b`, docs role

**Caveat for every candidate:** each item is a hypothesis from a different model. It is not a validated fix for `minicpm5:2b`. A fix can transfer negatively. For example, STE worked on deepseek-r1-1.5b and made lfm2.5-1.2b-thinking worse (AGENTS.md/history.md). Run bare first. Use a candidate only when the bare failure shape matches the source. Test one candidate at a time. Confirm with 3 draws before you keep it.

No input came from `qwen3.8-27b-gsq-rco`. Its extraction was empty.

### A. Checks before you steer

1. **Runaway thinking: truncation, empty answer, `finish_reason=length`**
   - Source: qwen3.5-0.8b, qwen3.5-0.8b-bf16, qwen3.5-4b (confirmed). qwen3.5-4b-gsq (single draw plus smoke test).
   - Technique: send `chat_template_kwargs.enable_thinking=false` or `DISPATCH_REASONING_EFFORT=none`. Use the non-thinking sampling values from the model card. Make sure every task ends with `finish_reason=stop`.
   - Caveat: the minicpm5 chat template can ignore this kwarg. Run a smoke test on the flag before you trust it. A result from a Qwen template does not show that minicpm5 honors the flag.

2. **Stray `</think>` tag in the output breaks syntax (doc-script)**
   - Source: lfm2.5-1.2b-thinking (fix checked).
   - Technique: use the greedy strip regex in `dispatch.sh`. Make sure it matches the reasoning tag format of minicpm5.
   - Caveat: this is a harness fix for lfm2.5 tag output. minicpm5 can use a different tag or no tag.

3. **SPEC bug looks like a model failure (doc-repair)**
   - Source: qwen3.5-9b (bare 6/6 after the SPEC fix). qwen3.5-0.8b-bf16 and qwen3.5-2b (results invalid, re-test needed).
   - Technique: before you steer doc-repair, make sure the minicpm5 run uses the fixed task version.
   - Caveat: this is not a model technique. It prevents steering against a broken task.

### B. Output length and preamble

4. **Idiom E: a global discipline preamble shrinks answers 2–14x**
   - Source: lfm2.5-1.2b-thinking (single draw, later runs agree).
   - Technique: start from the bare SPEC. Do not add `output-discipline.md` or other generic preambles.
   - Caveat: this is an anti-pattern on one 1.2B thinking model. A 2B model can react differently. Treat a preamble as a separate test, not as a default.

### C. Content drops (crossref, summarize)

5. **Q4: doc-crossref drops `describe_obfuscation_policy`**
   - Source: qwen3.5-0.8b and qwen3.5-0.8b-bf16 (2/3 each). The same drop occurs on 3 models, so the cause can be the task itself.
   - Technique: add a reminder that names that exact fact.
   - Caveat: this is a 2/3 result, not a stable fix. On lfm2.5 the drop still occurred on each draw.

6. **Q5: doc-crossref gives backwards attribution**
   - Source: qwen3.5-2b (confirmed 3/3).
   - Technique: add a reminder that states the correct mechanism and direction.
   - Caveat: this is confirmed on one model only. Use it only if minicpm5 reverses the attribution. Do not use it for a dropped name.

7. **doc-summarize: a fact or required attribute is missing**
   - Source: qwen3.5-4b-gsq (confirmed). qwen3.5-0.8b (2/3).
   - Technique: quote the model's own wrong output. Name the missing attribute (for example TypeScript/Node). Give one worked example. The 0.8b version uses a reminder that names the single missing fact.
   - Caveat: on lfm2.5, STE wording made the summary 20→10 words. On qwen3.5-2b this task was unstable bare. Watch the word count after you steer.

### D. Structure fidelity (verbatim, restructure, repair)

8. **Q1: blank-line drift or missing table separator row (doc-verbatim, doc-restructure)**
   - Source: qwen3.5-9b (6/6 each). It transferred to qwen3.5-4b (7/7, 8/8). This candidate has the best transfer evidence.
   - Technique: use a structural GBNF grammar. Force the blank-line, fence, header and separator positions. Leave the cell and line content free.
   - Caveat: prompt rules for the same shape failed on qwen3.5-0.8b. The rules also made doc-restructure worse (preserve rule against transform task). A fully literal grammar was an invalid tautology on 9b. Free text between fixed points ran past 2000 tokens. Make sure the minicpm5 backend supports the grammar.

9. **doc-verbatim: extra blank line before an appended `> Note:`**
   - Source: qwen3.5-4b-gsq (confirmed, round 1).
   - Technique: name the join point and the competing blockquote-spacing habit. Add a self-check for that point.
   - Caveat: this is a habit of one model. On qwen3.5-2b a more explicit follow-up leaked instruction text into the output.

10. **doc-repair: closing fence at the end of the document, not after the YAML block**
    - Source: qwen3.5-4b-gsq (confirmed, round 1).
    - Technique: give a wrong/right contrast pair. Add a self-check on the fence position.
    - Caveat: on qwen3.5-9b, a generic reminder on a solved doc-repair dropped it to 1/2. Use this only if the fence shape occurs. Do candidate 3 first.

### E. Find-and-replace (script, adapt, synthesize, surgical)

11. **doc-script: half-done two-line edit, forbidden token kept (`dist/index.js`)**
    - Source: qwen3.5-9b (7/7, also after compression). qwen3.5-4b-gsq (confirmed, round 2).
    - Technique: state that both lines must be gone and name the forbidden token (9b). Or quote the model's own wrong output next to the correct output and add a literal, greppable self-check (4b-gsq).
    - Caveat: a generic reminder failed 0/2 on 9b. An edit-verification rule had no effect on qwen3.5-0.8b. lfm2.5 stayed 0/3. Small models can hit a structural limit here.

12. **doc-synthesize: fenced JSON block missing, forbidden `zod` token leaks**
    - Source: qwen3.5-4b (6/6). qwen3.5-9b (5/6, about 83%).
    - Technique: use one combined reminder for the JSON block and the forbidden token.
    - Caveat: exact-fact steering on qwen3.5-0.8b removed the JSON block and added a forbidden token. Compression made 9b worse. A pass on 0.8b-bf16 did not transfer across precisions.

13. **doc-surgical: forbidden tokens leak, edits described but not made**
    - Source: lfm2.5-1.2b-thinking (partial, 0/3 Confirm).
    - Technique: use the 4-bullet `surgical-edit-discipline.md`. Do not use the 7-bullet version, which was worse.
    - Caveat: the same rules failed on qwen3.5-9b. doc-surgical is a stable FAIL on 4b and 9b. Expect a limit, not a fix.

14. **Q2: instruction text leaks past `[DOC_END]` (doc-surgical)**
    - Source: qwen3.5-0.8b. Not tested on any model.
    - Technique: set an API-level `stop: ["[DOC_END]"]` for each task.
    - Caveat: there is no evidence on any model. The prompt-level boundary rule caused a repetition loop on qwen3.5-2b and new self-narration on 0.8b. Use the API stop, not a prompt rule.

### F. Anti-patterns from the sources (do not do these)

- Do not copy a set of fixes as a bundle. Test each fix alone (qwen3.5-2b).
- Group tasks by shape (copy, repair, transform), not by symptom, before you batch a fix (qwen3.5-0.8b).
- Do not add a reminder to a task that passes bare (qwen3.5-9b doc-repair, 1/2).
- Do not add a "the document IS visible" rule for a false "source not visible" claim (lfm2.5, worse).
- Do not add more instruction text as a default. It did not help lfm2.5 in about 9 variants.

**Method that transferred best:** quote the task's own wrong output next to the correct output (qwen3.5-4b-gsq). For structure-only defects, use a grammar (qwen3.5-9b → qwen3.5-4b).
