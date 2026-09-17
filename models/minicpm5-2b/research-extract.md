# Cross-model research: extract role, candidates for `minicpm5:2b`

Generated 2026-09-17T08:29:34Z by bench/loop.sh's Research phase (cross-model idiom check only — external/web research is NOT automated, stays manual). Map-reduce: one extraction call per source model, then one combining call.
Source models checked: qwen3.5-4b qwen3.5-4b-gsq qwen3.5-9b qwen3.8-27b-gsq-rco

**Scope limit:** No source model has a diagnosed extract-role idiom. qwen3.5-9b and qwen3.8-27b-gsq-rco give no material. Most candidates below come from the docs role. All sources are Qwen models of 4B parameters or more. minicpm5:2b is a different family and is 2B, so the risk of negative transfer is higher than usual.

**Caveat for every item:** Each candidate is a hypothesis, not a fix. A technique that worked on one model can backfire on another. Example: STE transferred negatively from deepseek-r1-1.5b to lfm2.5-1.2b-thinking (AGENTS.md, history.md). Run a 3-draw Confirm on minicpm5:2b before you accept or reject any candidate.

- **Turn off thinking before the baseline**
  - **Failure shape:** `finish_reason=length` with empty output, because thinking uses the full token cap.
  - **Source:** qwen3.5-4b (docs role, confirmed: 44% truncation fell to zero with `DISPATCH_ENABLE_THINKING=false`). qwen3.5-4b-gsq (extract role, `DISPATCH_REASONING_EFFORT=none` as a prerequisite, smoke test only; the damage showed on docs, not on extract).
  - **Technique:** Make sure thinking is off for minicpm5:2b before Phase 1. First find out if the model has a thinking mode.
  - **Caveat:** Not proven on extract for any model. If minicpm5:2b has no thinking mode, this lever does nothing.

- **Do not tune sampling to fix truncation**
  - **Failure shape:** Runaway output or truncation.
  - **Source:** qwen3.5-4b (docs role: 5 presets, including near-greedy, all failed).
  - **Technique:** If truncation occurs, change the thinking switch before you change sampling presets.
  - **Caveat:** This is a negative result from one model and one role. Sampling can behave differently on minicpm5:2b.

- **Use a GBNF grammar for structural defects**
  - **Failure shape:** Malformed output structure, for example dropped separators or broken format. For extract, this can mean invalid JSON or wrong field layout.
  - **Source:** qwen3.5-4b (docs role, confirmed 7/7 and 8/8 after prompt steering failed 4 times).
  - **Technique:** When a structural defect survives 2 prompt changes, stop prompt steering and apply a GBNF grammar for the output schema.
  - **Caveat:** Confirmed on docs only. A grammar can hide content errors or make a small model produce valid but empty fields.

- **Stop early on content-fidelity drops**
  - **Failure shape:** The model drops or changes part of the exact source text, for example a missing prefix.
  - **Source:** qwen3.5-4b and qwen3.5-9b (docs role, doc-surgical: 0/8 with grammar and with a checklist reminder).
  - **Technique:** If minicpm5:2b drops exact text, record it as a possible capacity limit. Do not spend more than 2 steering rounds on it.
  - **Caveat:** This is a negative result on larger models. A smaller model is not likely to do better, but a different family can react to a different lever.

- **Run the bare baseline before any steering**
  - **Failure shape:** Unnecessary steering on a role that already passes.
  - **Source:** qwen3.5-4b-gsq (extract role: bare 6/6 PASS, single draw, no Confirm).
  - **Technique:** Run the extract tasks bare, with thinking off. Apply steering only to tasks that fail.
  - **Caveat:** This is a single-draw result on a 4B model. A 2B model can fail where the 4B model passed.

- **Confirm with 3 draws before you trust any result**
  - **Failure shape:** A single draw passes or fails by chance.
  - **Source:** qwen3.5-4b (docs role, broad per-draw instability at 4B).
  - **Technique:** Run a 3-draw Confirm on each baseline result and each steering result before you record it.
  - **Caveat:** This is a method, not a fix. Instability is likely larger at 2B, so 3 draws can still be too few.
