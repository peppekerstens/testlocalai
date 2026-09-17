# Cross-model research: tool role, candidates for `minicpm5:2b`

Generated 2026-09-17T08:21:42Z by bench/loop.sh's Research phase (cross-model idiom check only — external/web research is NOT automated, stays manual). Map-reduce: one extraction call per source model, then one combining call.
Source models checked: qwen3.5-4b qwen3.5-4b-gsq qwen3.5-9b qwen3.8-27b-gsq-rco

**Result:** None of the four source models has a diagnosed idiom or fix for the tool role. The two candidates below come from dispatch-level findings on other roles or from a bare baseline. Each one is a hypothesis for `minicpm5:2b`.

**Caveat for every candidate:** A technique that worked on one model can backfire on another. For example, STE negative-transferred from deepseek-r1-1.5b to lfm2.5-1.2b-thinking (AGENTS.md, history.md). Test each candidate against the `minicpm5:2b` tool baseline before you adopt it.

- **Candidate 1: Turn off thinking on direct dispatch**
  - **Failure shape:** With thinking on, the model uses the full token cap on reasoning and gives an empty answer (`finish_reason=length`).
  - **Technique:** Set `DISPATCH_ENABLE_THINKING=false` or `DISPATCH_REASONING_EFFORT=none`.
  - **Source:** qwen3.5-4b (docs role, confirmed over multiple 9-task runs). Also qwen3.5-4b-gsq (docs and reason roles; a smoke test confirmed that `none` turns off thinking).
  - **What did not work:** On qwen3.5-4b, 5 sampling presets, down to near-greedy, did not fix it. Nobody tested `--reasoning-budget N`.
  - **Transfer status:** Not tested on the tool role for any model. The 6/6 tool result on qwen3.5-4b-gsq ran with thinking off, so it does not show what thinking on does to tool tasks. First find out if `minicpm5:2b` has thinking on by default.
  - **Caveat:** This is a hypothesis, not a guaranteed fix. It can negative-transfer.

- **Candidate 2: Run the bare baseline before you add steering**
  - **Failure shape:** None. This candidate stops you from adding a fix for a failure that does not exist.
  - **Technique:** Run the tool tasks with no steering first. Add a lever only for a failure shape that you see.
  - **Source:** qwen3.5-4b-gsq, which scored 6/6 PASS bare (reports/report-tool-20260913-185926.md). This is a single draw with no Confirm run, and it needed thinking off.
  - **Caveat:** This is a hypothesis, not a guaranteed result. A 4B model that passes bare does not mean a 2B model will pass bare. Also run a Confirm draw on `minicpm5:2b` before you call any result stable.

**Sources with nothing to give:**
- qwen3.5-9b: no tool-role material. history.md covers only the docs and reason roles.
- qwen3.8-27b-gsq-rco: the README tool section and the history.md extract were both empty. This extract can be a gap in the input, not a real absence. Check the repo files before you rule out this model.
- Out of scope: the qwen3.5-4b GBNF grammar fixes, the `doc-surgical` defect, and the unstable tasks. They apply only to the docs role.

**Next step:** The tool-role idioms for `minicpm5:2b` must come from its own Phase 1 report. The latest commit (e46432d) contains a loop.sh Phase 1 report for this role. Use its failure shapes to decide if Candidate 1 applies.
