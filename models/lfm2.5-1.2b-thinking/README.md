# lfm2.5:1.2b-thinking — steering profile

**Role: documenter/reasoner** (same combined role as deepseek-r1 — see
its README for the doc/reason track split). Tracks: `tasks/doc-*` +
`tasks/reason-*`.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | ❌ Closed 2026-08-02 — not suitable | 1/9 → 1/9 (11%) | Not comparable — a frontier small model (e.g. Claude Haiku 4.5) is expected to pass ~9/9 on these tasks zero-shot | [Documenter role: final report](#documenter-role-final-report-closed-2026-08-02) |
| Reasoner | 🔬 Preliminary, paused mid-iteration | 2/9 → 2/9 (22%, not re-verified since) | Not assessed | [Reasoner role: current status](#reasoner-role-current-status-preliminary) |

## Documenter role: final report (closed 2026-08-02)

**Why stopped here.** Two full quality-loop phases (task-specific
steering, cross-model idiom transfer from `deepseek-r1-1.5b`) produced 9
distinct SPEC variants tried against the docs role. Every run left the
majority of tasks failing (7-8 of 9), and several well-motivated,
evidence-grounded interventions — a general output-discipline preamble,
a longer task-specific rules block, a cross-model-validated writing-style
technique (STE) — measurably made results *worse*, not better, with zero
exceptions across the full session. That pattern, not a specific
remaining idea, is why this loop stopped: the evidence says more
prompt-engineering investment on this model+role is low-expected-value.
Full narrative, all idioms (A through F), and every tried variant:
`history.md`.

**Usability score without optimizations (bare): 1/9 (11%) PASS.** Only
`doc-restructure` — rule-based structural transformation, no byte-exact
or multi-edit requirement — passes bare.

**Usability score with optimizations: practically unchanged — 1/9 on
most draws, occasionally 2/9.** Real per-task content-quality gains
landed on 3 of the 4 most-invested-in tasks (`doc-surgical`'s
wrong-SDK-content leakage eliminated; `doc-adapt`'s broken-edit count
roughly halved; `doc-repair` down to a single remaining defect — ⚠️
this specific `doc-repair` finding needs re-verification, see Setup)
— but
**zero of the 9 tasks moved from a stable FAIL to a stable PASS**
(confirmed via a 3-run consistency check). The occasional 2/9 draws are
fully explained by two tasks' pre-existing, steering-independent
per-draw instability (`doc-crossref`, one anomalous `doc-restructure`
failure), not by anything the optimization work changed.

**Comparison against a mainstream frontier LLM: not comparable.** A
model like Claude Haiku 4.5 would be expected to pass close to all 9 of
these tasks zero-shot — they test precise instruction-following (exact
substitution, verbatim reproduction, identifier preservation, fact-count
compliance under a word limit), well inside frontier-small-model
capability. **The one restriction that does hold**: for
`doc-restructure`'s specific task shape, this model's output has been
indistinguishable from correct across every draw tested, at near-zero
cost/latency versus a hosted frontier-model call.

**Final verdict: not suitable as a documenter, general-purpose or
narrowly, beyond one task shape.** Usable only for
`doc-restructure`-style work — route everything else in this role to a
larger model or a human reviewer. Mirrors `deepseek-r1-1.5b`'s own
independent verdict on an overlapping task set (same 5 tasks flagged as
a structural ceiling in its README) — a capability-scale finding at the
~1-2B parameter range, not an artifact of either specific checkpoint.

## Reasoner role: current status (preliminary)

**Not part of the closed documenter loop above — untouched since session
1.** Bare baseline (as part of the original combined 18-task doc+reason
suite): 2/9 `reason-*` tasks pass (`reason-multihop`, `reason-coverage`).
One blanket "output discipline" steering pass applied across both
tracks together: reasoner pass rate unchanged at 2/9 (same two tasks;
the other 7 showed mixed per-task movement — one gained its missing
exact phrase, most stayed failing — but none flipped to PASS). No
task-specific reasoner steering has been done. See `history.md`'s "One
steering pass" section for the full per-task table.

## How to optimize (preliminary — verify before trusting)

Actionable idioms only — see `history.md` for the discovery trail behind
each one (what was tried, in what order, why).

**Documenter role** (verdict above is final; these are reference only,
not a reason to keep steering this role further):
- LFM2.5 sometimes adds `[DOC_START]`/`[DOC_END]` wrapper tags or
  narrates its own edit instead of performing it — Idiom B/F. Emphasis
  on banning this does not reliably fix it and can trigger a different
  narration idiom instead of the original one.
- **Blanket rules blocks measurably shrink this model's output (Idiom
  E)** — a general-purpose meta-rules block prepended ahead of the task
  costs this small thinking model attention it needs for the task
  itself. Prefer short, task-family-specific instructions (see
  `rules/surgical-edit-discipline.md`) over a general one.
- **STE (Simplified Technical English) negative-transfers to this
  model** — the opposite of its validated result on `deepseek-r1-1.5b`.
  Do not apply it here, especially not to tasks already in the
  under-elaboration idiom family.
- Exact-identifier preservation (a tool/field name surviving into prose
  unparaphrased) is a real, only-partially-fixable gap —
  `doc-crossref`'s `describe_obfuscation_policy` is the clearest example.
- Verbatim-copy fidelity (`doc-verbatim`) is closer than most —
  structural elements (headings, fence placement) are the main
  remaining gap, not content substance.

**Reasoner role:**
- Under-elaboration / dropped required facts is the single most common
  idiom across `reason-*` failures — answers are on-topic but too
  compressed to include every explicitly required element. Not resolved
  by the one blanket steering pass tried so far.
- Do not apply the `DISPATCH_NOTHINK`-style raw-completion prefill trick
  built for `deepseek-r1-1.5b` to this model without adapting it first —
  it needs LFM2.5's own chat-template turn tokens (verify via `/props`).
  Liquid also ships a separate non-thinking `LFM2.5-1.2B-Instruct`
  checkpoint, untested, worth trying instead of prefill-hacking the
  Thinking checkpoint.

## Setup

- Served by `llama-server-lfm2.service` on `:8082` (Q4_K_M GGUF, CUDA),
  context `-c 8192`; run bench with `LLAMACPP_PORT=8082`.
- Downloaded 2026-08-01: `LiquidAI/LFM2.5-1.2B-Thinking-GGUF`,
  Q4_K_M, ~731MB. License: LFM Open License v1.0 (Apache-derived,
  free under $10M annual revenue).
- Whitelisted in `bench/dispatch.sh` as `lfm2.5:1.2b-thinking`.
- LFM2.5 embeds its `<think>...</think>` block *inline* in `content`
  (unlike R1's separate `reasoning_content` field) — `dispatch.sh`
  strips through the *last* `</think>`, not the first, to handle a
  stray unpaired second tag this model occasionally emits.
- **`tasks/doc-repair/SPEC.md` had a bug, fixed 2026-08-02 (commit
  `8d98d91`), invalidating this model's `doc-repair` finding.** Its
  "DEFECT 2" instruction claimed the source table was missing a
  separator row that was, in fact, already present (confirmed via
  `git blame`: present since the task's original import). Fixed by
  removing the separator row from the source so DEFECT 2 is now
  genuinely real. This model's "`doc-repair` down to a single
  remaining defect" finding (see the Documenter final report above,
  with a real steering override at `task-overrides/doc-repair.md`)
  was measured against the easier, buggy version — the "single
  remaining defect" was likely the genuine one (fence placement) even
  before this fix, so the finding may hold up, but it needs a fresh
  test round to confirm rather than being trusted as-is. Not yet
  re-run for this model as of this write. Found and fixed while
  investigating `qwen3.5:9b`'s `doc-repair` failures — see that
  model's `history.md` for the full diagnosis.

## Further reading

- `history.md` — full per-task diagnostic breakdown, every idiom (A-F),
  every tried variant, and the reasoning behind every keep/revert
  decision. The narrative home for this model — nothing here duplicates
  it.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run raw evidence (`bash bench/report.sh
  lfm2.5:1.2b-thinking <role>`).
- `task-overrides/` — the exact, literal prompt dispatched for each doc
  task this model has task-specific steering on (`doc-verbatim`,
  `doc-surgical`, `doc-adapt`, `doc-script`, `doc-repair`,
  `doc-synthesize`) — auto-resolved by `bench/pure-run.sh`, never a
  direct edit to the shared `tasks/<task>/SPEC.md` (see `AGENTS.md`'s
  "Per-model doc-task steering" rule). `doc-summarize`/`doc-crossref`
  have no override file — this model's final state for both is bare.
