# qwen3.5:2b — steering history

First real testing session, 2026-08-02.

## Phase 0: runaway-thinking bug confirmed, non-deterministic per draw

`bench/session-start.sh qwen3.5:2b llamacpp`'s own warm-up ping
succeeded cleanly (6.4s, no runaway reasoning) — the first time any
qwen3.5 config's warm-up hasn't hit the bug. A direct follow-up
dispatch with no override reproduced it immediately on the very next
draw (`finish_reason=length`, 8174 completion tokens, 22,527 reasoning
chars, empty answer) — confirms the bug is real here too, just not
100% per-draw the way it was on both 0.8B variants (every draw tested
there hit it). Documented explicitly in the README so a future session
doesn't mistake one lucky warm-up for evidence the fix isn't needed.
Same `DISPATCH_ENABLE_THINKING=false` + non-thinking sampling params
fix confirmed working via smoke test.

## Phase 1: reference baseline (docs role, 9 tasks)

`reports/report-docs-20260802-132935.md`: **2/9 PASS** (`doc-summarize`,
`doc-restructure`) — better than either 0.8B variant's bare baseline
(both 1/9). No truncation. Single draw.

**The idiom picture is meaningfully different from the 0.8B variants,
not just a scaled-up copy of the same failures:**

- **Idiom Q1 (structural dropping)** still present on `doc-verbatim`/
  `doc-repair`, same family as the 0.8B variants, though
  `doc-verbatim`'s specific defect this draw (merged/reflowed lines
  rather than a dropped fence or blockquote marker) differs in detail.
- **Idiom Q2 (instruction bleed)** still present on `doc-surgical` —
  same `[DOC_END]` leak shape as both 0.8B variants, unresolved by the
  larger parameter count.
- **Idiom Q3 (substitution not applied) is largely resolved at this
  size.** `doc-adapt` gets the substitution content fully correct
  (`forbidden Node/TS tokens absent: PASS`, `required C# tokens
  present: PASS`) — its only failure is whitespace/line-merging
  formatting, not the substitution itself. `doc-script` similarly
  shows partial resolution (required tokens present, down to 1 of 2
  forbidden tokens vs. the typical 2-of-2 on 0.8B). This is a real
  capability difference tied to parameter count — 0.8B's Q3 idiom was
  cross-model-confirmed as a likely structural ceiling on
  `deepseek-r1-1.5b`; this 2B checkpoint shows that ceiling isn't
  universal at this general model-family/task combination, just at the
  smaller size.
- **New idiom — Q5: backwards semantic attribution.** `doc-crossref`
  gets both required facts *present* (a real improvement over 0.8B's
  typical "drops one of the two facts" failure) but describes the tool
  `describe_obfuscation_policy` as performing the obfuscation itself
  rather than reporting/describing an obfuscation that already
  happened elsewhere — a logic error, not a missing-fact error. Never
  seen on either 0.8B variant. Larger model, different failure
  *category*, not just a lower failure *rate*.

**Practical implication for the Research phase**: don't assume 0.8B's
diagnosed fixes transfer here the way bf16↔Q4 transferred almost
perfectly — Q3's near-resolution at this size already shows the idiom
inventory itself changes with parameter count, not just the reliability
of fixes for the same idioms. Treat 0.8B's overrides as a source of
hypotheses to check individually, not a bundle to copy wholesale.

## Steering: Tier 1

**Run 1** (`reports/report-docs-20260802-133310.md`, 3/9): built
task-specific fixes for all 7 failing tasks — `structure-preservation.md`
(reused from `qwen3.5-0.8b`) for `doc-verbatim`/`doc-repair`,
`boundary-discipline.md`+`edit-verification.md` (reused) for
`doc-surgical`, a new `formatting-fidelity.md` for `doc-adapt`/
`doc-script` (targeting the whitespace/line-merging gap identified in
Phase 1, not substitution — that idiom was already resolved bare), a
new `mechanism-reminder-crossref.md` targeting the new Q5 idiom
(backwards semantic attribution), and a new
`structure-completeness-synthesize.md`.

**`doc-crossref` PASSES** — the Q5-specific fix worked immediately.
**`doc-surgical` regressed catastrophically** — the boundary-discipline
instruction triggered a degenerate repetition loop, the same paragraph
about "Error behavior (applies to all tools)..." repeated roughly 8
times in the output. An unambiguous regression, gated out on the spot
rather than waiting for a 2nd draw. `doc-verbatim` improved to a single
1-line defect (missing blank line before the note line) — real
progress, continuing. `doc-adapt`/`doc-script` showed no movement
(formatting-fidelity didn't fix the line-merging), `doc-synthesize`
showed no movement, `doc-repair` showed no clear improvement (a new
stray `[DOC_END]` leak appeared) — all 4 gated out per the 2nd-run rule,
reverted to bare.

**Run 2** (`reports/report-docs-20260802-133551.md`, 2/9): refined
`doc-verbatim`'s remaining defect with an explicit "no blank line
before the note line" instruction — got worse, not better (leaked
`Line 16 is exactly this note line:` instruction text into the output).
Reverted to the simpler run-1 version rather than keep this worse
variant. `doc-crossref` held PASS (2/2 draws). `doc-restructure`
regressed on this draw (bare, unrelated to steering — matches its
already-documented per-draw instability project-wide).

**Tier 1 closed.** Final state: `doc-crossref` confirmed working (2/2),
`doc-summarize`/`doc-restructure` pass bare (never needed steering),
`doc-verbatim` kept at its best-observed state (1-line defect, not a
full PASS — 2 of 4 budget runs used, stopping here since the 2nd
attempt made things worse rather than closing the gap), 5 tasks
reverted to bare after real attempts showed no promise or regressed
(`doc-surgical`, `doc-adapt`, `doc-script`, `doc-synthesize`,
`doc-repair`).

## Tier 2 gate: skipped (autonomous)

3 tasks with a current PASS (`doc-crossref`, `doc-summarize`,
`doc-restructure`) ÷ 9 = 33% — below the 60% threshold. Tier 2 skipped
per `AGENTS.md`'s autonomous gate rule, no question asked.

## Confirm: 3-loop consistency check

`reports/report-docs-20260802-133838.md` (2/9), `-133947.md` (1/9),
`-134055.md` (1/9). Per-task tracing:

- **`doc-crossref`**: PASS, PASS, PASS — **3/3, fully stable.** The
  strongest confirmed specialist result across any qwen3.5 variant
  tested this session (both 0.8B variants topped out at ~67%). The
  new Q5-specific mechanism-reminder fix is a clean, reliable win.
- **`doc-summarize`** (bare, no steering applied): PASS, FAIL, FAIL —
  1/3. Lower than assumed from Phase 1's single-draw bare pass — real
  instability, consistent with this task's project-wide flakiness, not
  evidence of anything steering-related since nothing was changed here.
- **`doc-restructure`** (bare, no steering applied): FAIL, FAIL, FAIL —
  0/3 this round. Same already-documented per-draw instability landing
  badly this time; not caused by anything in this loop.
- **`doc-verbatim`**: FAIL throughout Confirm — matches its "stable
  partial, never a full PASS" characterization from Steering.

**Final confirmed state**: 1 task fully reliable specialist PASS
(`doc-crossref`, 3/3 — the strongest result of the whole qwen3.5
family tested this session), 1 stable partial without a full PASS
(`doc-verbatim`), 2 tasks that pass bare on some draws but not
reliably (`doc-summarize`, `doc-restructure` — untouched by steering,
this is just this project's already-known bare instability on these
exact tasks), 6 tasks unsuitable even after dedicated per-task
steering effort (`doc-surgical` — including a new degenerate-
repetition regression, `doc-adapt`, `doc-script`, `doc-synthesize`,
`doc-repair`, plus `doc-verbatim` short of a full PASS).
