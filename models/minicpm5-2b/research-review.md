# Cross-model research: review role, candidates for `minicpm5:2b`

Generated 2026-09-17T08:38:53Z by bench/loop.sh's Research phase (cross-model idiom check only — external/web research is NOT automated, stays manual). Map-reduce: one extraction call per source model, then one combining call.
Source models checked: qwen3.5-4b qwen3.5-4b-gsq qwen3.5-9b qwen3.8-27b-gsq-rco

## Candidate techniques for `minicpm5:2b`, review role

**Caveat for every candidate:** each item is a hypothesis. None of the source models has a confirmed review-role fix. A technique that worked on one model can make another model worse. For example, STE transferred negatively from deepseek-r1-1.5b to lfm2.5-1.2b-thinking (per AGENTS.md and history.md). Test each candidate against the `minicpm5:2b` Phase 1 review baseline. Use a 3-draw Confirm before you keep it.

1. **Turn reasoning off**
   - **Failure shape it targets:** runaway thinking. The model uses the token cap on `reasoning_content` and gives no answer, or the output is cut off.
   - **Source:** qwen3.5-4b-gsq (`DISPATCH_REASONING_EFFORT=none`, confirmed live for all roles). qwen3.5-4b (`enable_thinking=false`, fixed a 44% truncation rate on docs, confirmed across several Confirm sets).
   - **Technique:** set `DISPATCH_REASONING_EFFORT=none`, or `DISPATCH_ENABLE_THINKING=false`. Do not set both, because `dispatch.sh` gives an error. Run a smoke test and make sure `reasoning_content_chars` is 0.
   - **Precondition:** use this only if the Phase 1 outputs show a reasoning channel or truncated answers. If `minicpm5:2b` has no thinking mode, this candidate does not apply.
   - **Caveat:** no model has tested this on review. The qwen evidence comes from other roles and from the qwen chat template. The `minicpm5:2b` template can behave differently.

2. **Show the wrong output next to the correct output, then add one self-check**
   - **Failure shape it targets:** a failure that repeats on one task, such as a wrong format, a wrong splice point, or a missed finding.
   - **Source:** qwen3.5-4b-gsq, docs role. This method fixed 4 of 4 tasks.
   - **Technique:** in the steering prompt, put the model's own wrong output from the failed task next to the expected output. Then add one self-check line for that failure only. The fix is specific to each task, so there is no general artifact.
   - **Caveat:** this worked on docs only and was not tested on review. A 2B model can copy the contrast example as the answer, or ignore the self-check. Look for both effects in the Confirm draws.

3. **Classify the failures before you choose a lever**
   - **Failure shape it targets:** none directly. This is a process guard.
   - **Source:** qwen3.5-4b-gsq. The docs failures were about format and splice points, not padding. The note says to find the cause of review failures before you use the caveman lever.
   - **Technique:** read each FAIL output in the Phase 1 review report. Give each one a failure shape before Tier 1 steering. Use a length-cut lever (caveman) only if the failure is padding or truncation.
   - **Caveat:** this is a workflow rule from one model, not a tested fix. `minicpm5:2b` is a smaller model, so its failures can be different, for example missed findings instead of format errors.

### Sources with nothing to use
- **qwen3.5-9b:** no review-role material. history.md covers only the docs and reasoner roles. Look for `models/qwen3.5-9b/reports/report-review-*` files to confirm.
- **qwen3.8-27b-gsq-rco:** the extraction step returned empty README and history.md sections. This is possibly a path or folder-name mismatch, not missing work. Read the files directly before you decide that there is no data.

### Overall gap
No source model has a confirmed review-role idiom. The only review data point is the qwen3.5-4b-gsq bare baseline: 4/6 PASS, single draw, and no diagnosis of the 2 failures. So the `minicpm5:2b` Phase 1 failure shapes must drive the steering. Use the three items above only as starting guesses.
