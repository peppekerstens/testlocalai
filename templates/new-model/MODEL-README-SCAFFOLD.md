<!--
Scaffold for models/<model>/README.md. Copy this file, fill in every
placeholder, delete every HTML comment (including this one) before
committing. See AGENTS.md's "README shape: current-state only, history
deferred" rule for the reasoning behind every constraint marked below.

THE ONE RULE THAT MATTERS MOST: every time you're about to add a
sentence describing what just happened in a run/phase ("this time we
tried X and Y happened") — stop. That sentence belongs in history.md,
appended, not here. This file gets its *content replaced*, section by
section, never appended to. If you re-read a section you're about to
edit and it already sounds like a story instead of a current fact or
instruction, that's the signal the rule already got broken once —
fix it before adding more, don't add a second story on top of the first.
-->

# <model> — steering profile

**Role: <role-name(s)>** (`tasks/<prefix>-*`<if multiple roles, name
each track and which task prefix it covers>).

## Overview

<!--
One row per role this model has EVER been tested against, tested or
not. Every cell must be current-state, not narrative. "Details" links
to that role's own heading below (so keep heading text stable once
linked — renaming it breaks the link).
-->

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| <role> | <🔬 Preliminary / ⚠️ Mixed / ✅ Established / ❌ Not suitable — pick one, with a one-clause reason> | <n/N → n/N> | <"Not assessed" until a loop actually closes for this role — don't guess> | [<role> role](#<anchor-matching-heading-below>) |

## <Role> role: <current status | final report (closed <date>)>

<!--
One section per role in the table above, same order. Heading text must
match the table's Details link.

- If this role's quality loop is still open/preliminary: state the
  CURRENT pass rate and the CURRENT best-known idiom list only. No
  "first we tried X, then..." — if you have that story, it's already
  (or belongs) in history.md.
- If this role's quality loop is CLOSED: this section IS the quality
  loop's Final report per AGENTS.md's "Final report" rule — must state
  (1) why the loop stopped, (2) usability score without optimizations,
  (3) usability score with optimizations, (4) a stated comparison
  against a mainstream frontier LLM with explicit restrictions, (5) a
  final verdict sentence.
- If this role went through Tier 1/Tier 2 Steering (per-task specialist
  optimization, see AGENTS.md's quality loop), include the per-task
  table below. This is where the real picture lives — the Overview
  table above is one aggregate number, "no generalist found" reads as a
  bare failure without this table showing which tasks DO have a working
  specialist config.
- Either way: end with a pointer like "Full narrative: history.md's
  '<section name>'" rather than summarizing the narrative here.
-->

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| <task> | <e.g. "near-pass, 1 defect" / "PASS" / "FAIL, gated out run 1"> | <link to `task-overrides/<task>.md`, or "bare — steering hurt this task"> | <how it does under the Tier 2 generalist, or "n/a — no generalist found for this role"> |

## How to optimize (verify before trusting)

<!--
Actionable idioms/instructions only, grouped by role if more than one.
Each bullet: state the CURRENT fact/instruction. If the bullet needs a
clause explaining what was tried and what happened to justify itself,
that clause belongs in history.md — link to it, don't retell it here.

BAD  (narrative, delete this style):
  "This got worse, not better, after adding an explicit instruction
  against it on one task (X regressed to Y) — don't assume more
  emphasis on an already-stated rule helps."

GOOD (actionable, keep this style):
  "Emphasis on an already-stated rule does not reliably help and can
  trigger a different failure idiom instead — see history.md's
  '<section>' for why."
-->

- <idiom 1, stated as current fact/instruction>
- <idiom 2, ...>

## Setup

<!--
Setup facts only: systemd service + port, GGUF source/quant/license,
dispatch.sh whitelist status, and — critically — any REQUIRED
dispatch-level override per AGENTS.md's "every dispatch-level tweak
must be documented" rule (DISPATCH_TEMPERATURE, DISPATCH_ENABLE_
THINKING, etc.), with the exact reproducible env-var invocation, not
just "some tuning was needed."
-->

- Served by `<service>` on `:<port>` (<quant>, <backend>); run bench
  with `<port env var>=<port>`.
- Downloaded <date>: `<HF repo>`, <quant>, ~<size>. License: <license>.
- Whitelisted in `bench/dispatch.sh` as `<model tag>`.
- <any mandatory DISPATCH_* overrides — omit this bullet entirely if
  none are needed, don't leave a placeholder "none" line>

## Further reading

- `history.md` — full per-task diagnostic breakdown, every idiom, every
  tried variant, and the reasoning behind every keep/revert decision.
  The narrative home for this model — nothing above should duplicate it.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run raw evidence (`bash bench/report.sh <model>
  <role>`).
- `task-overrides/` — <only if this model has doc-task steering> the
  exact, literal prompt dispatched for each doc task with task-specific
  steering — auto-resolved by `bench/pure-run.sh`, never a direct edit
  to the shared `tasks/<task>/SPEC.md` (see `AGENTS.md`'s "Per-model
  doc-task steering" rule).
