# qwen3.5:9b — steering history

First real testing session, 2026-08-02.

## Setup: VRAM oversubscription accepted

Downloaded `unsloth/Qwen3.5-9B-GGUF` Q4_K_M (5.68GB) — this GPU (GTX
1650, 4096MiB total VRAM, ~3.3GB free after stopping other services)
cannot hold this model natively. Per explicit user instruction ("won't
fit in vram and overflow. i accept that"), started the service with
`-ngl 99` anyway. Startup log showed `failed to fit params to free
device memory: n_gpu_layers already set by user to 99, abort` but the
service loaded and served successfully regardless — this is llama.cpp's
own auto-fit heuristic giving up (since the user forced a literal
value) and proceeding, with the NVIDIA driver's transparent VRAM
oversubscription mechanism handling the actual overflow via
driver-managed paging over PCIe.

## Pre-baseline: thinking-enabled spot-check (per explicit user request)

Before any real Phase 1 baseline, the user asked for a narrow,
targeted check: does the larger 9B size alone resolve the
runaway-thinking bug seen on `qwen3.5:4b`, without disabling thinking?
Explicitly scoped as a spot-check, not a full quality loop.

**Initial smoke test** (trivial 3-word prompt, 5-min cap): timed out.
Server logs showed steady generation at ~3.13 tok/s, cancelled at 930
decoded tokens (not truncated by the server — cancelled by the client
timeout). This immediately raised a methodological concern: at this
speed, even a normal-length answer (~1500-2000 tokens, typical for
these docs tasks) would take 8-11 minutes, making a 5-minute cap
unable to distinguish "genuinely running away" from "just slow."
Flagged to the user, who chose to raise the cap to ~12 minutes.

**4-task spot-check, 12-minute cap each, thinking enabled** (the 4
tasks that truncated on `qwen3.5:4b`: `doc-verbatim`, `doc-adapt`,
`doc-script`, `doc-repair`): **all 4 timed out.** Cancellation points,
in order: `doc-verbatim` 2179 tokens, `doc-adapt` 2160 tokens,
`doc-script` 2124 tokens, `doc-repair` 1915 tokens — a strikingly
tight, consistent band (23-27% of the 8192 context), none anywhere
near the ceiling. This consistency itself is informative: it suggests
the model was on a similar, steady trajectory each time, not that any
one task was uniquely pathological — but 12 minutes still wasn't long
enough to see any of them either converge or hit the wall.

**Extended single-task test, `doc-verbatim`, up to 120-minute cap**
(10x the original window, per explicit user request: "we should have
provided at least 10 times the solution window? try with 1 task"):
launched in parallel with the tail of the 4-task spot-check (server
has 4 concurrent slots). **Result: failed with exit code 1, not the
expected 124 (timeout) or 0 (success).** Root cause: `bench/
dispatch.sh`'s own Python client has a hardcoded `urlopen(...,
timeout=1800)` (30 minutes) — shorter than the outer `bash timeout
7200` (2 hours) I'd set, so the client-side socket timeout fired
first, well before the outer cap could matter. This was a real gap in
the spot-check's own methodology, not a finding about the model,
caught and diagnosed rather than mistaken for a runaway signal.

**But the server-side logs from that same task were still genuinely
useful.** At the moment of cancellation (client disconnect, not server
truncation): **5504 tokens decoded (67% of the 8192 context),
`truncated=0`, steady ~2.81 tok/s the entire way** — meaningfully
further than any of the 12-minute-capped draws, still generating
normally, no sign of the kind of stuck/looping degenerate pattern seen
elsewhere in this project (e.g. `qwen3.5-2b`'s repetition-loop
regression under a different instruction). **No evidence of a
genuinely stuck runaway was observed at any point in this spot-check**
— every draw was still making steady forward progress when it was cut
off by test infrastructure (a timeout), not by the model's own
`</think>` emission or the server's context ceiling.

**Conclusion: the original question was not conclusively answered.**
The evidence leans toward "this model doesn't get stuck the way 4B's
worst cases did" (no repetition, no obviously pathological pattern,
steady token-by-token progress even past 5500 tokens) — but it's
equally consistent with "this model just takes proportionally longer
to think before answering, and would still eventually hit the same
context-ceiling truncation 4B showed, just further out." Distinguishing
these would need either a full uncapped run (impractical at ~2.8-3.1
tok/s — a full run to the 8192 ceiling would take ~44+ minutes even
without any client-side timeout interference) or a fix to `dispatch.sh`'s
hardcoded client timeout, neither of which was in scope for this
targeted spot-check.

## CPU/GPU bottleneck investigation (per explicit user request)

The user observed "hardly any CPU load" during these tests and asked
for an assessment. Live monitoring during a fresh short dispatch
showed: **GPU utilization 99%, system-wide CPU only ~10-12%** (one
`llama-server` thread pegged near 100% for GPU-orchestration/sync
overhead, not raw compute), and `llama-server`'s virtual memory size
at **~56.5GB** — far exceeding both the 4GB VRAM and ~8GB system RAM,
the signature of NVIDIA driver-managed VRAM-oversubscription paging
(handled by the GPU driver/DMA engine over PCIe, not CPU-side code).

**Historical check, not just a live snapshot** (the user specifically
asked about the *past hour*, not the current moment): `llama-server`'s
cumulative CPU time (`ps -o time`) versus wall-clock elapsed
(`ps -o etime`) since service start gave **1h 15m 11s of CPU time over
1h 34m 48s of wall-clock — ~79% of one CPU core, sustained across the
entire session** (covering both the 4-task spot-check and the extended
test). This resolves the apparent contradiction: there *was*
substantial, sustained CPU work the whole time, concentrated on a
single thread — it just reads as "hardly any load" on a coarse,
multi-core system-wide view (e.g. ~79%/8 cores ≈ 10% aggregate),
because the work was never spread across cores, not because there was
little work being done.

**Mechanism, complete picture**: the GPU is doing real compute at 99%
occupancy but spends most of that time stalled waiting on PCIe
transfers for weight pages that don't fit in the 4GB VRAM and had to
be evicted to system RAM. That stall shows up as GPU "busy" time, not
CPU compute — hence low CPU load despite the GPU being fully occupied.
This is the root cause of the ~12x slowdown versus `qwen3.5:4b`'s
fully-GPU-resident config, and it's a hardware ceiling for this GPU +
model-size combination, not something further parameter tuning fixes.

## Next: switching to `enable_thinking=false` for a normal baseline

Per explicit user instruction ("kill the extended test, wrap up
findings. set the think off and do normal test run"): the
thinking-enabled spot-check is closed as inconclusive-but-informative
on its original question. Proceeding to a standard Phase 1 baseline
with `enable_thinking=false` (matching every other qwen3.5 config
tested in this project), which will also resolve the practical
problem — non-thinking generation should run at normal speed even
under this GPU's VRAM oversubscription, since there's no long
reasoning phase to pay the PCIe-stall cost against.

**Correction, confirmed via smoke test**: this expectation was
half-right. Generation speed itself stayed at ~3.1 tok/s (the
VRAM-oversubscription PCIe-paging bottleneck applies to every token,
not specifically to long reasoning chains — it's a per-token cost
regardless of content). What changed is total answer *length*: without
a reasoning phase, individual answers are dramatically shorter (hundreds
of tokens, not thousands), so the *total* time for a full docs-role
run stays practical even at the same per-token speed.

## Phase 1: reference baseline (docs role, 9 tasks)

`reports/report-docs-20260802-173725.md`: **5/9 PASS**, no truncation
(all `finish_reason=stop`). Matches or exceeds every smaller qwen3.5
config's bare baseline (0.8B: 1/9, 2B: 2/9, 4B: 5/9-on-paper but with
44% hidden empty-output truncation that this run doesn't have — this
is a genuine, trustworthy 5/9). Single draw.

**All 4 FAILs are near-misses matching idiom families already
diagnosed on `qwen3.5-4b`** — no new idioms found:
- `doc-verbatim`: dropped both blank lines (heading→fence,
  fence→table) — same structural-dropping idiom seen on every smaller
  config.
- `doc-surgical`: forbidden/required tokens both PASS, fails purely on
  line-wrap collapsing — same idiom `qwen3.5-4b`'s
  `formatting-fidelity.md` targeted (mixed success there, never fully
  closed).
- `doc-synthesize`: bullet count and required tokens PASS, missing
  only the fenced JSON block — closest near-miss of the 4.
- `doc-restructure`: all content checks PASS, missing only the table
  separator row — same family as `doc-verbatim`.

**Research-phase plan**: check `qwen3.5-4b`'s outcomes for these exact
4 tasks before inventing new fixes. `doc-verbatim`/`doc-restructure`
were both ultimately reverted to bare on 4B after real, varied
attempts — a negative signal worth weighting. `doc-surgical`'s
`formatting-fidelity.md` never fully worked there either. `doc-
synthesize` DID have a working fix on 4B (a forbidden-token reminder)
— worth testing, though the specific gap here (missing JSON block,
not a forbidden token) differs from what that fix targeted.

## Steering: Tier 1 (3 runs) — one confirmed fix, strong cross-model gating

**Run 1** (`reports/report-docs-20260802-175322.md`, 6/9): first
attempt for all 4 FAILs. `doc-synthesize`'s fenced-JSON-block reminder
worked immediately. `doc-verbatim`'s 2-blank-line fix improved (both
targeted gaps closed) but a 3rd, unaccounted-for blank line (before
the note line) became the new sole defect. `doc-surgical`'s
`formatting-fidelity.md` (reused from `qwen3.5-4b`) regressed — the
substitution content itself came back wrong, matching that same
model's finding this lever doesn't reliably help this idiom.
`doc-restructure`'s table-separator reminder showed zero movement.

**Run 2** (`reports/report-docs-20260802-180647.md`, 4/9):
`doc-verbatim`'s refined 3-blank-line instruction still failed — same
single-line-defect shape, different specific line each draw, matching
`qwen3.5-4b`'s own exhaustive (4-attempt) history on this identical
idiom. `doc-surgical`/`doc-restructure` (already reverted to bare)
stayed FAIL as expected. `doc-script` (bare, never touched) flipped to
FAIL — real per-draw noise. `doc-synthesize` (kept override) flipped
to FAIL too, but not a regression of the original fix — the JSON block
and bullets and required tokens all still passed; a *second*,
independent idiom surfaced (`zod` token leaking in), matching what
other qwen3.5 configs show on this exact task.

**Gate decision**: `doc-verbatim` reverted to bare after 2 attempts
here — cross-model evidence (4B's full 4-attempt history on the
identical idiom, never resolved, always a different specific
manifestation) was strong enough to stop early rather than spend the
remaining Tier 1 budget against a pattern this consistent.

**Run 3** (`reports/report-docs-20260802-182001.md`, 5/9):
`doc-synthesize`'s combined fix (JSON-block reminder + `zod`-token
reminder together) **worked** — clean PASS, both idioms addressed.
`doc-script` (bare) flipped back to PASS. `doc-repair` (bare, never
touched by any steering this entire session) flipped to FAIL for the
first time — a new instability data point on a task previously assumed
stable.

**Tier 1 closed.** Final state: `doc-synthesize` has a confirmed
working override (combined fix). `doc-verbatim`, `doc-surgical`,
`doc-restructure` all reverted to bare after real, evidence-grounded
attempts (2, 1, 1 runs respectively — gated early where cross-model
history already pointed to low expected value, rather than
mechanically using the full 4-run budget on each). `doc-adapt`,
`doc-script`, `doc-repair`, `doc-summarize`, `doc-crossref` were never
steered; their swings across all 3 Steering runs (`doc-script`:
FAIL→PASS→PASS→FAIL→PASS across the 4 draws so far, `doc-repair`:
PASS→PASS→PASS→FAIL) are pure bare-task instability.

## Tier 2 gate: skipped (autonomous)

Tasks with a current PASS on the final Steering draw = `doc-adapt`,
`doc-script`, `doc-synthesize`, `doc-summarize`, `doc-crossref` = 5/9
≈ 56% — below the 60% threshold. Tier 2 skipped per `AGENTS.md`'s
autonomous gate rule, no question asked. Moving to Confirm — essential
given the volume of bare-task instability observed across this
Steering phase.
