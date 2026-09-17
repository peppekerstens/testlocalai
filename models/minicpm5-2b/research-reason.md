# Cross-model research: reason role, candidates for `minicpm5:2b`

Generated 2026-09-17T10:19:19Z by bench/loop.sh's Research phase (cross-model idiom check only — external/web research is NOT automated, stays manual). Map-reduce: one extraction call per source model, then one combining call.
Source models checked: qwen3.5-4b qwen3.5-4b-gsq qwen3.5-9b qwen3.8-27b-gsq-rco

Hypotheses only, not fixes. Check each one against the bare `minicpm5:2b` reason baseline before you keep it.

## Dispatch-level candidates (check these before any prompt steering)

1. **Runaway thinking: output cut off at the token limit or empty.** Sources: **qwen3.5-4b-gsq** (reason role) and **qwen3.5-4b** (docs role only).
   - **Technique:** turn reasoning off. On qwen3.5-4b-gsq, `DISPATCH_REASONING_EFFORT=none` fixed a stalled reason run. That was one smoke test and one rerun, with no Confirm. On qwen3.5-4b, `enable_thinking=false` fixed truncation 3/3, but on docs tasks only. `--reasoning-budget N` is a middle option that nobody tested yet.
   - **How to detect it:** look for `finish_reason=length` with empty content. On qwen3.5-4b, a runaway took about 211s and a normal answer took about 15-45s. That timing comes from one journalctl reading.
   - **Caveat:** this can transfer in the wrong direction. A 2B model can need its thinking for multi-step reason tasks. Also, `reasoning_effort` and `enable_thinking` cannot be used together in dispatch.sh. Measure both settings. Do not assume reasoning off is better.

2. **Sampling presets do not fix runaway thinking (a negative result).** Source: **qwen3.5-4b** (docs role).
   - **Technique:** skip sampling-preset sweeps as a fix for truncation. Five presets, down to near-greedy, all failed.
   - **Caveat:** each preset had one draw on one docs task. This is weak evidence, and it can be different on minicpm5.

3. **Structural output defects.** Source: **qwen3.5-4b** (docs role).
   - **Technique:** use a GBNF grammar where prompt changes do not fix the structure. Results were 7/7 on doc-verbatim and 8/8 on doc-restructure.
   - **Caveat:** this is confirmed for docs only. Reason tasks are graded mostly on content, not layout. A grammar can also limit how the model reasons. Use it only if minicpm5 shows a structural failure.

## Prompt/SPEC-level candidates (from reason-role diagnoses)

4. **Exact-phrase idiom: the reasoning is correct, but the required phrase is paraphrased.** Source: **qwen3.5-9b** (reason role).
   - **Technique:** in the per-task override, tell the model to copy the exact phrase word for word.
   - **Results:** confirmed 3/3 on reason-consequence ('passes through') and reason-multihop (entities.company). Partial on reason-trace ('re-initialize', about 63%) and reason-compare ('config was valid', about 86%).
   - **Caveat:** the partial results show that the technique does not always hold, even on the source model. deepseek-r1-1.5b misses the same 'config was valid' phrase, so small models have a general problem with it. Expect this to be a hard target on a 2B model.

5. **A different required token is missing in each draw (reason-checklist).** Source: **qwen3.5-9b**.
   - **Technique:** none validated. A possible next step is to list all required tokens explicitly in the override.
   - **Caveat:** this is untested on the source model too, and its bare pass rate is about 33%. Treat it as an open idea, not as a technique.

6. **A whole required category is missing (reason-coverage).** Source: **qwen3.5-9b**.
   - **Technique:** tell the model to list every checklist category first, then fill in each one.
   - **Caveat:** planned but never tested on any model. A "list first" step also makes the output longer, and a 2B model can then drift or truncate.

7. **Input schema field names appear in the answer (reason-config-validity).** Source: **qwen3.5-9b** (the verdict was correct but contained idField and tokenTemplate).
   - **Technique:** none validated yet. The step-by-step verification fix from deepseek-r1-1.5b (seen only secondhand, through the qwen3.5-9b notes) targeted a wrong verdict. That is a different failure shape.
   - **Caveat:** first find out which failure shape minicpm5 shows: a wrong verdict or leaked field names. Then pick a lever.

8. **Output-discipline block.** Source: **qwen3.5-9b**, which got it by accident from lfm2.5's leftover block in shared reason-* SPEC.md files. Commit cd77859 removed the block.
   - **Technique:** add an explicit OUTPUT DISCIPLINE block to the minicpm5 override. On qwen3.5-9b it raised the bare score from 3/9 to 6/9.
   - **Caveat:** that 6/9 result was a contaminated, invalid draw, not a controlled test. Put the block in the minicpm5 override only. Never put it in shared SPEC.md, because that contaminates the other models' baselines.

## Harness checks before you blame the model

9. **False FAILs from the verifier (reason-diagnose).** Source: **qwen3.5-9b**.
   - **What happened:** verify.sh required the hidden token `requireEnv`. Commit 350f276 changed it to accept any valid fail-fast wording.
   - **Technique:** before you steer, read the FAIL diffs and confirm that the verifier grades content, not one exact wording.
   - **Caveat:** this is not a model technique, but it still needs a check. Other reason-* verify.sh checks can have the same bug.

10. **Gate thresholds on a flaky model.** Source: **qwen3.5-9b**.
    - **Technique:** run at least 3 Confirm draws. qwen3.5-9b bare scores were 3-5/9, and steered Confirm draws were 8/9, 5/9 and 4/9. Do not accept a steer on one good draw. Skip Tier 2 below the 60% threshold.
    - **Caveat:** a 2B model can vary more between draws, so 3 draws can be too few.

## No usable input

- **qwen3.8-27b-gsq-rco:** its README reason section and its history.md were both empty, so it gives no candidates. The extraction step possibly failed (wrong paths or section markers). Check that before you treat it as "no data".
- **qwen3.5-4b:** it has no reason-role data. Candidates 1-3 come from its docs role only.

## General caveat for all candidates

Each technique above was validated, if at all, on a larger or different model: 4B, 9B or 27B. None was tested on `minicpm5:2b`. Negative transfer already happened in this repo: STE helped deepseek-r1-1.5b but hurt lfm2.5-1.2b-thinking. Add one candidate at a time, and compare it with the minicpm5 bare baseline over the Confirm draws.
