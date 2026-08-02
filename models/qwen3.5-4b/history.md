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
