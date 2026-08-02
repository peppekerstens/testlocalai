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
