# qwen3.5:4b — steering history

First real testing session, 2026-08-02.

## Phase 0: initial smoke test understated the runaway-thinking risk

3/3 bare dispatch draws on a trivial 3-word prompt completed cleanly
(`finish_reason=stop`, 559-1770 completion tokens) — no truncation,
unlike 0.8B (100% reproduction) and 2B (~50%). Documented in
`README.md` as evidence the bug doesn't apply at this size.

**This was premature — trivial prompts understated the real risk.**
The Phase 1 baseline (real docs-task prompts, more context/complexity)
showed a 44% single-draw truncation rate (4 of 9 tasks). See Phase 1
below. Corrected in `README.md`.

## Phase 1: reference baseline (docs role, 9 tasks)

`reports/report-docs-20260802-135441.md`: **5/9 PASS** — the best bare
baseline of any qwen3.5 config tested this session (0.8B: 1/9, 2B:
2/9). Dispatched with the thinking-mode "text tasks" sampling preset,
no `enable_thinking` override. Single draw.

**4 of 9 tasks (44%) hit `finish_reason=length` with completely empty
final output** — `doc-verbatim`, `doc-adapt`, `doc-script`,
`doc-repair`. Confirmed via direct `journalctl` monitoring of
`llama-server-qwen3.5-4b.service` during this exact run (user
specifically asked for reference timing while watching this happen
live):

- Task 24507: truncated at `n_tokens=8191` (~16:07).
- Task 34639: truncated at `n_tokens=8191`, took 210.9s wall-clock
  (26.74 ms/token eval time × 7773 decoded tokens + prompt eval) —
  **established reference timing**: a normal non-runaway completion
  takes ~15-45s at this model's ~37-40 tok/s generation speed; a
  genuine runaway that exhausts the full context takes ~211s.
- Task 46532: reached 7878/8192 tokens and converged *just* in time
  (`truncated=0`) — a near-miss, not a 3rd runaway, but close enough
  to explain why `doc-crossref`'s PASS used 7087 of 8192 completion
  tokens (a narrow margin, not a comfortable one).

**These 4 truncated tasks are not diagnosable as content idioms** the
way the smaller configs' Q1-Q5 were — an empty final answer carries no
content signal to classify against `expected.md`. The only applicable
lever is context/thinking-length management (sampling parameters or a
hard reasoning-token budget), not prompt-level content steering.

**The 5 PASSes are genuine content correctness**, not
truncation-adjacent near-misses, with the caveat that `doc-crossref`'s
margin was narrow (see above).

**Research finding, mid-baseline (per explicit user request while
watching the run)**: web research into Qwen3.5's known infinite-
thinking failure mode surfaced a real llama.cpp server flag,
`--reasoning-budget N` (confirmed supported by the installed build via
`llama-server --help`) — forces a clean `</think>` at N tokens instead
of running unrestricted to the context ceiling with zero output. This
is a genuine middle ground between the current unrestricted-thinking
state (44% truncation) and `DISPATCH_ENABLE_THINKING=false`
(explicitly the last resort per user instruction, not to be used
without exhausting sampling-parameter and budget-based alternatives
first). Trade-off: it's a server-startup flag
(`LLAMA_ARG_THINK_BUDGET`), not a per-request dispatch override like
temperature/top_p — testing different N values means restarting
`llama-server-qwen3.5-4b.service` between attempts. User explicitly
authorized this ("even if this means reloading... relatively short
compared to a 5 minute wait on a runaway task").

**Next steps, in priority order per explicit user instruction**:
1. Try alternate sampling-parameter combinations first (different
   temp/top_p/top_k/presence_penalty, or the model card's "precise
   coding" preset).
2. Try `--reasoning-budget N` at a few candidate values if sampling
   alone doesn't resolve the truncation rate.
3. Only consider `DISPATCH_ENABLE_THINKING=false` if both of the above
   are exhausted — explicitly deprioritized by the user, not the
   default fallback it was for the smaller configs.

## Steering-parameter escalation: 5 sampling attempts, then `enable_thinking=false`

Per user direction: first tried the full 9-task role under the
"precise coding" thinking-mode preset (`temp=0.6 top_p=0.95 top_k=20
presence_penalty=0.0`) as a candidate fix. This ran for **34+ minutes**
(vs. Phase 1's ~24 min) and accumulated 4+ confirmed truncations before
being killed mid-run — clearly no better than Phase 1's baseline, and
far too slow to iterate on at the full-role scale. **Lesson: testing
sampling-parameter candidates against all 9 tasks is the wrong
granularity when truncation itself is the failure mode being fixed** —
a single runaway task alone costs ~211s, so a full run can't
distinguish "this preset helps" from "this preset doesn't help" without
burning 20-30+ minutes either way.

**Switched to a fast single-task, 3-minute-capped test loop** (per
user request) on `doc-repair` (smallest prompt, 419 tokens — fastest
signal). 5 sampling-parameter combinations tried, each capped at 180s
via `timeout 180`, none completed within the cap:

1. `temp=1.0 top_p=0.95 top_k=20 pp=1.5` (Phase 1's original preset) —
   timeout.
2. `temp=1.0 top_p=0.95 top_k=20 pp=2.0` (strong presence penalty) —
   timeout.
3. `temp=0.6 top_p=0.7 top_k=20 pp=1.5` (tighter sampling) — timeout.
4. `temp=0.3 top_p=0.8 top_k=5 pp=2.0` (low-diversity) — timeout.
5. `temp=0.01 top_p=1.0 top_k=1 pp=0.0` (near-greedy, effectively
   deterministic decoding) — timeout.

**No sampling-parameter combination reduced truncation, across the
full range from the original preset to near-deterministic decoding.**
This is strong evidence the runaway-thinking behavior isn't a sampling
artifact at all for this specific task/model combination — it's
something about the `<think>` token's emission probability never
naturally dropping regardless of how the rest of the distribution is
shaped, consistent with the external research done earlier this
session ("the `</think>` token is probabilistic... quantization shifts
probability distributions... degrades low-frequency token emission").

**Per the user's own explicit escalation plan** ("try a few loops with
params (5 loops more) - if no improvement, thinking off"):
`DISPATCH_ENABLE_THINKING=false` was tried as the fallback on the same
`doc-repair` task — **succeeded immediately**, well under the 3-minute
cap (165 completion tokens, `finish_reason=stop`, zero reasoning
content), and the content was a near-miss (`both repairs present:
PASS`, only a whitespace/blank-line difference from a full match).

**Full 9-task re-test with `enable_thinking=false`** (per user
instruction — "if improve, test all again as baseline"):
`reports/report-docs-20260802-151206.md`, **3/9 PASS**, completed in a
small fraction of Phase 1's runtime. **Zero truncation** — every task
`finish_reason=stop`. Lower raw PASS count than Phase 1 (5/9) but a
categorically better failure profile: Phase 1's 5/9 hid a 44% *empty
output* rate behind its headline number; this run's 6 FAILs are almost
all single-defect near-misses with real, mostly-correct content
(`doc-surgical`/`doc-adapt`/`doc-synthesize` all pass their forbidden/
required-token checks, failing only on whitespace or one stray token).

**Conclusion: `enable_thinking=false` is now this model's working
dispatch configuration, same posture as the 0.8B/2B configs.** The
Phase 0 finding ("this model doesn't need `enable_thinking=false`,
unlike its siblings") is **superseded, not just refined** — it was
based on a 3/3-clean smoke test using trivial prompts that never
exercised the failure mode real docs-task prompts reliably trigger.
`README.md` corrected accordingly. Proceeding to Steering with this as
the new reference baseline.

## Steering: Tier 1 (4 runs) — one clean win, real bare-task instability surfaced

Cross-model check: `qwen3.5-2b` had already tried
`formatting-fidelity.md` on this exact `doc-adapt`/`doc-script`
line-wrap idiom and it didn't work there either, and `boundary-
discipline.md` caused a catastrophic repetition-loop regression on
`doc-surgical` there — but on this model, `doc-surgical`'s defect was
already diagnosed as line-wrapping (not instruction bleed, the idiom
`boundary-discipline` targets), so that specific regression risk
wasn't applicable here and was avoided by using the right lever for
the actual defect instead of reusing the exact same fix wholesale.

**Run 1** (`reports/report-docs-20260802-151822.md`, 4/9): first
attempt for all 6 near-miss FAILs. `doc-synthesize`'s `zod`-token
reminder worked immediately. `doc-verbatim`'s fix targeted the wrong
blank-line location for that draw's specific defect.
`doc-surgical`/`doc-adapt` (`formatting-fidelity.md`, reused from
`qwen3.5-2b`) showed zero movement. `doc-script`/`doc-summarize`
(targeted exact-token/phrase reminders) showed zero movement despite
being about as specific as an instruction can get.

**Run 2** (`reports/report-docs-20260802-152143.md`, 7/9): gated
`doc-adapt`/`doc-script`/`doc-summarize`/`doc-surgical` to bare per the
2nd-run rule. `doc-verbatim`'s corrected blank-line fix (before-note
location) — **still failed, but this draw's actual defect was the
*other* blank line** (after heading), which run 1's original
instruction had targeted. **Real per-draw instability in which of two
blank lines drops, not a misdiagnosis.** All 3 gated-to-bare tasks
PASSED this draw — single-draw evidence only, explicitly flagged as
needing Confirm before trusting.

**Run 3** (`reports/report-docs-20260802-152423.md`, 4/9): tried a
combined instruction covering both blank-line locations for
`doc-verbatim` (still failed) and an example-based line-wrap
instruction for `doc-surgical` (still failed, 2nd lever type, 2nd
failure — gated to bare). **`doc-adapt`/`doc-script` (bare) flipped
back to FAIL**, and `doc-repair` (never steered, always bare) flipped
to FAIL for the first time this session — confirms instability is
broad across this role's bare tasks, not confined to the ones under
active Steering.

**Run 4** (`reports/report-docs-20260802-152711.md`, 4/9):
`doc-verbatim`'s 4th and final Tier 1 attempt — a literal line-by-line
enumeration of all 16 expected output lines (the style that helped
partially on other qwen3.5 configs for this same task). **Still
failed**, same 1-line-defect shape. 4 distinct instruction styles
tried across 4 runs (positional description ×2, combined, literal
enumeration), none confidently beat bare — **reverted to bare.**
`doc-restructure` (bare, PASS on literally every draw before this one,
across the entire session) flipped to FAIL — the clearest single data
point that this role's per-draw noise is real and broad, not an
artifact of anything being steered.

**Tier 1 closed.** Final state: `doc-synthesize` has a confirmed
working override (PASS on all 4 post-fix draws). `doc-verbatim` and
`doc-surgical` both reverted to bare after real, varied attempts (4
and 2 runs respectively) found nothing that beat bare with confidence.
Every other task (`doc-repair`, `doc-adapt`, `doc-script`,
`doc-summarize`, `doc-crossref`, `doc-restructure`) was never steered
— any pass/fail swings recorded above are pure bare-task per-draw
instability, real and broad across this role, which is exactly what
the Confirm phase exists to quantify.

## Tier 2 gate: skipped (autonomous)

Tasks with a current PASS on the final Steering draw = 4/9 ≈ 44%
(`doc-synthesize`, `doc-repair`, `doc-summarize`, `doc-crossref`) —
below the 60% threshold. Tier 2 skipped per `AGENTS.md`'s autonomous
gate rule, no question asked. Moving to Confirm — essential here given
the volume of per-draw instability observed across this Steering
phase, not a formality.
