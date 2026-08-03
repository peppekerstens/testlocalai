# qwen3.5:2b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of [`qwen3.5-0.8b`](../qwen3.5-0.8b/)
in the same model family (not just a precision variant — a real
parameter-count difference, 2B vs 0.8B) — a separate model directory,
steering not assumed to transfer untested.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed — quality loop closed 2026-08-02, 1 fully reliable task shape, rest unsuitable | 2/9 bare → 1 task at 100%, 1 stable partial, rest unchanged | Not comparable overall; 1 narrow task shape usable, high confidence | [Documenter role: final report](#documenter-role-final-report-closed-2026-08-02) |

## Documenter role: final report (closed 2026-08-02)

**Why stopped here.** Full quality loop: Phase 0 (dispatch fix
confirmed, and found to be non-deterministic per draw unlike the 0.8B
variants), Phase 1 baseline (2/9 bare — better than either smaller
variant, and a meaningfully different idiom picture, not a scaled-up
copy), Research phase (0.8B's overrides tested as individual
hypotheses, not a bundle), Tier 1 specialist optimization (2 Steering
runs, including one severe regression caught and reverted), an
autonomous Tier 2 gate (specialist rate 3/9 ≈ 33%, below the 60%
threshold — Tier 2 skipped), and a 3-run Confirm check.

**Usability score without optimizations (bare): 2/9 (22%) PASS**
(`reports/report-docs-20260802-132935.md`) — the best bare baseline of
any qwen3.5 config tested this session.

**Usability score with optimizations: 1 task reaches full, 3/3
Confirm-verified reliability** (`doc-crossref` — the strongest
confirmed result of any qwen3.5 variant tested this session, both
0.8B configs topped out at ~67%); **1 task reaches stable partial
improvement without a full PASS** (`doc-verbatim`); **2 bare-passing
tasks turned out less reliable under Confirm than Phase 1 suggested**
(`doc-summarize` 1/3, `doc-restructure` 0/3 — pre-existing per-draw
instability, unrelated to this loop's work, since neither was
steered); **6 tasks remain unsuitable**, including one new failure
mode not seen on either smaller variant (`doc-surgical` regressed to a
degenerate repetition loop under one tested instruction, reverted).

**Comparison against a mainstream frontier LLM: not comparable
overall.** A model like Claude Haiku 4.5 would be expected to pass
close to all 9 zero-shot. **The narrow exception is stronger here than
on either 0.8B variant**: `doc-crossref` reaches full, confirmed
reliability (not ~67% — 3/3), usable with less review overhead than
either smaller config's version of the same task, at near-zero
cost/latency versus a hosted frontier-model call.

**Final verdict: not suitable as a general documenter, but with the
single strongest specialist result of the qwen3.5 family tested this
session.** Usable, with high confidence, for `doc-crossref`-shaped
work (cross-document fact synthesis with correct mechanism
attribution) — the only task across all 3 qwen3.5 configs tested this
session to reach fully stable Confirm-verified reliability rather than
a ~67% partial rate. Everything else tested remains unsuitable,
including a genuinely new failure mode (degenerate repetition) not
observed at the smaller size — bigger is not uniformly safer, it
trades some idioms for others.

**Per-task detail** (Confirm-verified):

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-crossref` | **PASS, 3/3 Confirm draws — fully reliable** | [`task-overrides/doc-crossref.md`](task-overrides/doc-crossref.md) — new Q5-specific mechanism reminder | n/a — Tier 2 gate skipped (specialist rate 33% < 60% threshold) |
| `doc-verbatim` | Stable partial — 1-line defect every draw, never a full PASS | [`task-overrides/doc-verbatim.md`](task-overrides/doc-verbatim.md) | n/a |
| `doc-summarize` | Bare, unreliable — 1/3 Confirm draws, untouched by steering | bare | n/a |
| `doc-restructure` | Bare, unreliable — 0/3 Confirm draws this round, untouched by steering | bare | n/a |
| `doc-surgical` | Gated out — regressed to a degenerate repetition loop, new idiom vs. 0.8B | bare | n/a |
| `doc-adapt` | Gated out (flat after run 1; substitution content itself is already correct bare, only formatting fails) | bare | n/a |
| `doc-script` | Gated out (flat after run 1; same partial-correctness-bare pattern as `doc-adapt`) | bare | n/a |
| `doc-synthesize` | Gated out (flat after run 1) | bare | n/a |
| `doc-repair` | **⚠️ Needs re-test — result invalidated 2026-08-02.** Pre-fix: gated out (flat after run 1) — measured against a buggy task version, see Setup | bare | n/a |

## How to optimize (verify before trusting)

- `DISPATCH_ENABLE_THINKING=false` is mandatory before any other
  steering — see Setup below (note the non-deterministic warm-up
  caveat there).
- For `doc-crossref`-shaped tasks (cross-document synthesis requiring
  correct mechanism attribution, not just fact presence): a
  mechanism-specific reminder reaches full, stable reliability — see
  [`task-overrides/doc-crossref.md`](task-overrides/doc-crossref.md).
  This is a different idiom from the 0.8B variants' `doc-crossref`
  gap (missing fact vs. backwards semantic attribution) — don't reuse
  the 0.8B fix verbatim, diagnose the actual defect first.
- For `doc-verbatim`-shaped tasks: task-specific steering reaches a
  stable 1-line-defect partial, never a full PASS — see
  [`task-overrides/doc-verbatim.md`](task-overrides/doc-verbatim.md).
- For `doc-surgical`-shaped tasks: **do not use a boundary-discipline-
  style instruction** — it triggered a degenerate repetition loop on
  this model (a failure mode not seen on either 0.8B variant). Gated
  to bare; no working lever found yet.
- For `doc-adapt`/`doc-script`-shaped tasks: unlike the 0.8B variants,
  substitution content is already correct bare here — only formatting
  fails. A different lever than what worked (or didn't) on 0.8B is
  needed; not yet found.

## Setup

- Served by `llama-server-qwen3.5-2b.service` on `:8084` (Q4_K_M GGUF,
  CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8084`.
- Downloaded 2026-08-01: `Qwen/Qwen3.5-2B` Q4_K_M GGUF, ~1.2GB. License:
  same as `qwen3.5-0.8b`.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:2b`.
- **Required dispatch overrides — mandatory, not optional, per
  `AGENTS.md`'s "every dispatch-level tweak must be documented" rule:**
  - `DISPATCH_ENABLE_THINKING=false` — same runaway-thinking bug as
    both 0.8B variants, confirmed via direct test (2026-08-02): a
    bare-dispatch draw with no override hit `finish_reason=length`
    after 8174 completion tokens, 22,527 reasoning chars, empty answer.
    **Note: not deterministic on every draw** — this session's initial
    `session-start.sh` warm-up ping happened to succeed (6.4s, no
    runaway) before a direct follow-up test reproduced the bug on its
    very next draw. Don't take one successful warm-up as evidence the
    bug doesn't apply — it's real and reproducible, just not 100%
    per-draw (unlike the 0.8B variants, which reproduced it on every
    draw tested so far). This model family has no in-prompt
    `/think`/`/no_think` switch — `chat_template_kwargs.enable_thinking`
    is the only control.
  - `DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20
    DISPATCH_PRESENCE_PENALTY=2.0` — same model-card-recommended
    non-thinking-mode sampling parameters as the 0.8B variants (same
    model family). Smoke-tested working: clean 9-token response,
    `finish_reason=stop`, zero reasoning content.
  - Full reproducible invocation for a docs-role test:
    ```
    DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8084 \
    DISPATCH_ENABLE_THINKING=false DISPATCH_TEMPERATURE=1.0 \
    DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=2.0 \
    bash bench/report.sh qwen3.5:2b docs llamacpp 8084
    ```
- `bash bench/session-start.sh qwen3.5:2b llamacpp` stops other local
  hosters and starts this service exclusively — its own warm-up ping
  does NOT set the overrides above and may or may not hit the
  runaway-thinking bug (non-deterministic, see above) — don't treat
  either outcome as evidence about the fix's necessity.
- **`tasks/doc-repair/SPEC.md` had a bug, fixed 2026-08-02 (commit
  `8d98d91`), invalidating this model's `doc-repair` result.** Its
  "DEFECT 2" instruction claimed the source table was missing a
  separator row that was, in fact, already present (confirmed via
  `git blame`: present since the task's original import). Fixed by
  removing the separator row from the source so DEFECT 2 is now
  genuinely real. This model's `doc-repair` result (gated out flat
  after run 1 — see the per-task table above) was measured against
  the easier, buggy version and needs a fresh test round; not yet
  re-run for this model as of this write. Found and fixed while
  investigating `qwen3.5:9b`'s `doc-repair` failures — see that
  model's `history.md` for the full diagnosis.
- **`tasks/doc-crossref/SPEC.md` also had a bug, fixed (commit
  `62d3995`), a second contamination the doc-repair fix missed.** A
  "WRITING STYLE — Simplified Technical English" steering block — an
  `lfm2.5-1.2b-thinking` transfer experiment meant to be reverted —
  was baked into the shared canonical file. **This model's own
  `task-overrides/doc-crossref.md` (this model's strongest, ~3/3
  Confirm-verified result) was built on top of the already-
  contaminated SPEC** — it includes the STE block internally, not just
  this model's own mechanism reminder. This model's single best result
  of the whole project may partly reflect that extra guidance, not
  solely the reminder its own history attributes it to. Left as-is (a
  real, working, validated config), but read the attribution with that
  caveat — worth a from-scratch re-test to isolate the two effects if
  this result ever matters for a real decision.

## Further reading

- `history.md` — full per-task diagnostic breakdown, every idiom,
  every tried variant, and the reasoning behind every keep/revert
  decision.
- `models/qwen3.5-0.8b/` and `models/qwen3.5-0.8b-bf16/` — the smaller
  siblings of this same model family; check their `history.md`/
  `README.md` for idioms that might transfer (a hypothesis to test in
  the Research phase, not an assumption — see `AGENTS.md`'s quality
  loop). Note: a real parameter-count difference (2B vs 0.8B) is a
  bigger jump than the precision-only difference between the two 0.8B
  variants — transfer is less certain here.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:2b
  <role>`, with the env vars above).
