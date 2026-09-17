# Cross-model research: code role, candidates for `minicpm5:2b`

Generated 2026-09-17T09:41:15Z by bench/loop.sh's Research phase (cross-model idiom check only — external/web research is NOT automated, stays manual). Map-reduce: one extraction call per source model, then one combining call.
Source models checked: qwen2.5-coder-1.5b qwen3.5-4b-gsq qwen3.8-27b-gsq-rco

## Candidate techniques for `minicpm5:2b`, role `code`

These are hypotheses, not fixes. A technique that worked on one model can fail on another. Example: STE worked on deepseek-r1-1.5b but gave negative transfer on lfm2.5-1.2b-thinking (AGENTS.md, history.md). Use a candidate only when `minicpm5:2b` shows the same failure shape. Test each one alone against the bare baseline.

1. **Missing `using` lines**
   - **Source:** qwen2.5-coder-1.5b (confirmed).
   - **Technique:** Paste the exact `using` lines into the SPEC.
   - **Caveat:** This is a hypothesis for `minicpm5:2b`. Negative transfer is possible. The source result is older than the 2026-08-03 incident (`-ngl 99`, before the dispatch fixes), so it was not tested again.

2. **Wrong API calls or wrong branch shape**
   - **Source:** qwen2.5-coder-1.5b (confirmed: task4 went from 62% to 100%, equality and stats 7/7).
   - **Technique:** Paste full code snippets and full method bodies into the SPEC. Do not describe them in prose.
   - **Caveat:** This is a hypothesis for `minicpm5:2b`. Negative transfer is possible. The source result is also older than the 2026-08-03 incident.

3. **Imports of packages that the project does not use**
   - **Source:** qwen2.5-coder-1.5b (confirmed 18/18).
   - **Failure shape:** Too many rules, or shared rules. Round D scored 1/6. Extended tasks scored 3/6 with rules and 5/6 without rules.
   - **Technique:** Use rules that apply to one task only, or use no rules file.
   - **Caveat:** This is a hypothesis for `minicpm5:2b`. Negative transfer is possible. The source result is also older than the 2026-08-03 incident.

4. **Model stops before it writes all the classes**
   - **Source:** qwen2.5-coder-1.5b (confirmed on task1).
   - **Technique:** Put the implementation first in the prompt. Add a checklist that counts the classes.
   - **Caveat:** This is a hypothesis for `minicpm5:2b`. Negative transfer is possible. The source result is also older than the 2026-08-03 incident.

5. **Prompt too long (token cost)**
   - **Source:** qwen2.5-coder-1.5b (confirmed).
   - **Technique:** Compress the prose only (-29.5% tokens). Never compress code shapes, because that breaks the output.
   - **Caveat:** This is a hypothesis for `minicpm5:2b`. Negative transfer is possible. A 2B model can be more sensitive to compressed prose than a 1.5B coder model. The source result is also older than the 2026-08-03 incident.

6. **Thinking uses up the 16,384-token cap (slow or cut-off output)**
   - **Source:** qwen3.5-4b-gsq (smoke test only, one draw).
   - **Technique:** Set `DISPATCH_REASONING_EFFORT=none` in `bench/dispatch.sh`. Do not set `DISPATCH_ENABLE_THINKING` at the same time, because the two settings exclude each other.
   - **Caveat:** This is a hypothesis for `minicpm5:2b`. Negative transfer is possible. First make sure that `minicpm5:2b` has a thinking mode and that thinking fills the cap. qwen3.5-4b-gsq scored 14/14 bare, so this lever did not fix a code idiom. It only removed the cap problem.

7. **Process step: bare baseline and Confirm**
   - **Source:** qwen3.5-4b-gsq.
   - **Technique:** Run the tasks bare before you add levers. Run a 3-draw Confirm before you call a result stable.
   - **Caveat:** This is a hypothesis for `minicpm5:2b`. The source model did not complete a Confirm run, so this step is only a recommendation.

**No source:** qwen3.8-27b-gsq-rco gave no candidates. Its README.md `code` section and its history.md came back empty. Make sure that `models/qwen3.8-27b-gsq-rco/README.md` and `history.md` exist, then extract them again.

**Size note:** qwen2.5-coder-1.5b is the closest in size to `minicpm5:2b`. It is also the only source with diagnosed code idioms. All of its results are older than the 2026-08-03 incident, so check them again before you trust them.
