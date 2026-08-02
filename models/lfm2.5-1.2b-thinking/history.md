# lfm2.5:1.2b-thinking — steering history

First real testing session, 2026-08-02. Written up after the fact from
session notes — this model's `models/<model>/reports/` directory did not
exist yet when this testing happened (the reports mechanism was built the
same day, after this run), so unlike qwen/deepseek this history was never
backed by saved report files; it's reconstructed from the diagnostic work
done at the time.

## Bare baseline (18-task doc+reason suite, no steering)

**3/18 PASS**: `doc-restructure`, `reason-multihop`, `reason-coverage`.
**15/18 FAIL**, listed with diagnosis below. Zero truncation warnings —
every task's completion finished with a real answer, largest was 3115
completion tokens (`doc-script`), nowhere near the 8192 ceiling.

Per-failure diagnosis (bare SPEC, before any steering):

| Task | Failure mode |
|---|---|
| `doc-verbatim` | Dropped the closing ` ``` ` fence marker and one blank line — otherwise an accurate copy. Near-miss. |
| `doc-surgical` | Added `[DOC_START]``[DOC_END]` wrapper tags (explicitly forbidden by the task's own SPEC) and a trailing self-referential note ("Note: the original document's exact content is assumed..."). Did not apply the required substitutions — kept old TS-specific tokens instead of the C# equivalents. |
| `doc-adapt` | Added `[DOC_START]`/`[DOC_END]` wrapper (SPEC didn't forbid it as explicitly here) but wrote the doc as a "replaces X with Y" migration-note format instead of a clean adapted document — kept forbidden tokens (`npm`, `node dist`, `Express`) inside the "replaces" phrasing instead of eliminating them. |
| `doc-script` | A stray, unpaired `</think>` (see the infra bug below) leaked into the output and broke bash syntax. Separately, on content grounds: kept forbidden tokens (`npm`, `dist/index.js`), missing required tokens (`curl`, `mcp-session-id`). |
| `doc-synthesize` | Extremely terse — a single vague sentence, missing the required heading, fenced JSON block, bullets, and required tokens entirely. |
| `doc-repair` | Kept most of the table but added meta-commentary describing the edit ("[The original YAML block's missing closing brace is fixed here, followed by the separator row.]") instead of just performing it, and dropped most of the surrounding content. |
| `reason-config-validity` | Wrongly concluded "the config satisfies all requirements" — missed that `owner` (referenced by `nestedEntities.defaultContact`) isn't a valid entity key. |
| `reason-diagnose` | Correctly identified `CW_PRIVATE_KEY` as the missing variable but didn't use the exact required phrase `Missing required environment variable`. |
| `reason-checklist` | Produced nonsensical checks ("Run `curl -v .env`") instead of the SPEC's actual required checks (`dotnet run`, hitting `/mcp`, checking for `mcp-session-id`) — despite all the needed facts being present in the SPEC. Not a missing-facts problem; a task-execution/attention problem. |
| `reason-trace` | Got the general mechanism right (in-memory `transports.Map`, invalidation) but didn't use the exact required phrases `No valid session ID`/`re-initialize`. |
| `reason-consequence` | Described the mechanism generically ("owner.id and owner.name... not present... not redacted") without naming the specific config mechanism (`nestedEntities`) or the required verb `passes through`. |
| `reason-compare` | Gave a correct answer (A) with good reasoning but didn't use the specific required vocabulary (`boot`, `listen`, `config was valid`). |
| `doc-summarize` | Severely under length (19 words), missing the required token `ConnectWise MCP server` and the required fact about the reference implementation/official SDK. |
| `doc-crossref` | Got Source B's fact right (email → `{token}@obfuscated.invalid`) but never named the Source A tool `describe_obfuscation_policy` — wrote "the tool describes obfuscation" instead of using the exact name. |
| `reason-tradeoff` | Extremely terse (2 short sentences), didn't explicitly discuss the privacy side and utility side of the tradeoff as separate required points, despite giving a recommendation. |

## Recurring idioms identified across the 15 failures

- **Idiom A — under-elaboration:** the dominant pattern across most
  `reason-*` failures and several `doc-*` ones — answers were on-topic
  but too compressed to include every explicitly required fact/section/
  exact phrase.
- **Idiom B — meta-commentary/wrapper-tag leakage:** `doc-repair` (edit
  narrated instead of performed), `doc-surgical`/`doc-adapt` (added
  `[DOC_START]`/`[DOC_END]` wrapper tags not asked for).
- **Idiom C — imperfect verbatim copy:** `doc-verbatim` (dropped a fence
  + blank line), `doc-repair` (dropped most content).
- **Idiom D — substitution not applied correctly:** `doc-surgical`/
  `doc-adapt` kept old/forbidden tokens instead of the required new ones,
  or described the substitution in prose instead of performing it.

## Infrastructure bug found: think-tag leak breaking downstream syntax

`doc-script`'s output contained a literal, unpaired `</think>` mid-file,
breaking `bash -n`. Root cause: LFM2.5 embeds its `<think>...</think>`
block *inline* in `content` (confirmed via direct API inspection —
unlike deepseek-r1, which returns reasoning via a separate
`reasoning_content` field entirely). `dispatch.sh`'s strip regex,
`<think>.*?</think>` (non-greedy), only removed the *first* matched pair.
On the failing draw, the model's raw output had a properly paired
`<think>...</think>` block, but then its post-think narration briefly
slipped back into thinking-style prose and emitted a second, unpaired
`</think>` later in the answer — the non-greedy regex left that stray
tag in the final output.

**Fixed:** `dispatch.sh`'s regex changed to `<think>.*</think>` (greedy —
strips everything up through the *last* `</think>`, not the first),
which handles this case regardless of how many `<think>`/`</think>`
tokens appear. Verified via direct re-dispatch: LFM2.5's normal
single-paired-block responses continue to strip correctly (confirmed via
a clean one-sentence smoke-test answer with no leaked tags).

## One steering pass: general "output discipline" rules block

Built `rules/output-discipline.md` targeting the 4 idioms above (no
meta-commentary/wrapper tags, preserve exact identifiers verbatim,
complete every required element before finalizing, reproduce copy tasks
exactly including fence markers, perform substitutions directly instead
of narrating them). Prepended into each of the 15 failing tasks' `SPEC.md`
(pre-steering versions archived to each task's own
`history/SPEC-pre-lfm2-steer.md`).

**Result: 0/15 on the next draw** — no clean win, but real, mixed signal
underneath the headline number:

| Task | Change after steering |
|---|---|
| `doc-verbatim` | **Improved** — down to one remaining mismatch (a dropped blank line) from two before. Closest to a real fix. |
| `doc-surgical` | **Regressed** — output shrank to near-empty (`[DOC_START] ## Error behavior (applies to all tools) [DOC_END]`), still using the forbidden wrapper tags the *original* SPEC (before this session's steering) already explicitly forbade. The added emphasis didn't help and may have triggered over-compliant truncation. |
| `doc-adapt` | Different failure shape, not clearly better or worse — switched to a mechanical "X → replace with Y" listing format instead of prose, still failing. |
| `doc-script` | Tag-leak fixed (confirmed — script starts clean, no syntax error); still fails on content grounds (same forbidden/missing tokens as before). |
| `doc-synthesize` | Unchanged — still a single vague sentence. |
| `doc-repair` | Partial improvement in shape (kept the table this time) but still broken — meta-commentary still leaked ("Note: The exact content of nestedEntities is preserved..."). |
| `reason-config-validity` | Changed answer entirely (now claims a *different* specific violation) — not clearly validated as more correct, just different. |
| `reason-diagnose` | Unchanged — correctly identifies `CW_PRIVATE_KEY` but still doesn't use the exact required phrase. |
| `reason-checklist` | Different wrong commands, not resolved. |
| `reason-trace` | **Improved** — gained the exact required phrase `'400 No valid session ID'` it was missing before. |
| `reason-consequence` | Unchanged — still missing `nestedEntities`/`passes through`. |
| `reason-compare` | Unchanged — still missing the exact required vocabulary. |
| `doc-summarize` | Unchanged — still short/vague. |
| `doc-crossref` | Slight improvement (now explicitly frames "Source B") but still doesn't name `describe_obfuscation_policy` — the core gap survives. |
| `reason-tradeoff` | Slightly more elaborated (5 lines vs 2) but still missing the explicit privacy-side/utility-side framing required. |

**Takeaway, not yet acted on:** a single blanket rules block produced one
clear regression, one clear win, a few genuine partial improvements, and
several unchanged failures — the same lesson this project has learned
with every other model: diagnose and steer *per task*, not with one
lever applied uniformly. That task-specific follow-up pass has not been
done yet — this model's steering work stopped here, mid-iteration, when
session attention moved to other project work (the four new roles,
report-generation tooling, this documentation restructure).

## Docs-role re-test (2026-08-02, session 2) and the blanket-preamble comparison

Fresh docs-only run (`bash bench/report.sh lfm2.5:1.2b-thinking docs`,
`models/lfm2.5-1.2b-thinking/reports/report-docs-20260802-100539.md`)
against the still-steered SPEC.md files from session 1: **1/9 PASS**
(only `doc-restructure`, the one task never steered). All 8 failures
showed the same shape — very short final answers (105–156 bytes) despite
748–2808 completion tokens spent, `finish_reason=stop` (not truncation,
the model chose to stop that short) — worse than session 1's own record
for several of these same tasks (`doc-verbatim` dropped the *entire*
document this time, not just a blank line; `doc-repair` kept 2 lines, not
most of the table). Single draw; see the report for full per-task
idiom classification.

That regression prompted a same-day **bare-vs-steered comparison**: the 8
archived pre-steer SPECs (`tasks/<task>/history/SPEC-pre-lfm2-steer.md`)
were re-dispatched against the same running model/session state as the
steered run above, isolating one variable (presence of the blanket
`output-discipline.md` preamble) while holding everything else constant.

**Result: 0/8 flipped to PASS on bare either** — this is not "bare fixes
it." But output *shape* differed sharply and consistently in one
direction:

| Task | Steered bytes | Bare bytes | Byte ratio |
|---|---|---|---|
| `doc-verbatim` | 145 | 147 | ~1x — no difference |
| `doc-surgical` | 64 | 891 | ~14x |
| `doc-adapt` | 523 | 1193 | ~2.3x |
| `doc-script` | 156 | 2007 | ~13x |
| `doc-synthesize` | 125 | 203 | ~1.6x |
| `doc-repair` | 40 | 558 | ~14x |
| `doc-summarize` | 17 words (fails 20-word floor) | 20 words (passes) | marginal |
| `doc-crossref` | Source A right, B missing | Source A missing, B right | flipped, not added |

For `doc-surgical`, `doc-adapt`, `doc-script`, and `doc-repair`, removing
the preamble produced dramatically more complete output — real content
instead of a near-empty stub — while still failing on the *same kind* of
content error either way (wrong/forbidden tokens, not missing
elaboration). `doc-verbatim` and `doc-synthesize` were unaffected by the
preamble either way — something else is truncating those regardless.
`doc-crossref` reproduced the exact bare-baseline idiom from session 1
(`describe_obfuscation_policy` missing, email/`obfuscated.invalid`
correct) — confirms that specific gap is stable on bare SPEC — but under
the steered SPEC that gap *relocates* to the other fact instead of
closing. `doc-summarize` marginally clears the word-count floor bare but
still misses the same required facts either way.

**New idiom, not previously documented for this model — Idiom E:
preamble-induced compression.** The blanket `output-discipline.md` block,
prepended ahead of the task instructions on every steered SPEC, appears
to measurably shorten this model's final answer on tasks where the model
would otherwise produce substantial content, without buying back any
correctness on the errors it was meant to fix (forbidden tokens, exact
identifiers) — those same errors persist in the *longer* bare answers
too. This reframes session 1's "no task-specific follow-up done yet"
takeaway: before doing per-task steering on top of the blanket preamble,
the preamble itself needs to be treated as a suspect, not a settled
foundation. Single comparison draw per task — this needs 2-3 more draws
each before the "preamble hurts these 4 tasks" read is trusted as a
rate rather than a same-day sample.

## Task-specific steering pass on the 4 preamble-affected tasks

Built `rules/surgical-edit-discipline.md` — short, targeted at the
literal-find-replace task family (`doc-surgical`, `doc-adapt`,
`doc-script`, `doc-repair` all share the same "copy exactly, apply N
numbered FIND→REPLACE edits, no delimiter markers, no commentary"
structure) rather than a general-purpose rules block. Replaced the old
`output-discipline.md` preamble with this on those 4 tasks' live
`SPEC.md`; left the other 4 previously-steered tasks
(`doc-verbatim`/`doc-synthesize`/`doc-summarize`/`doc-crossref`)
unchanged. Full docs-role re-test:
`models/lfm2.5-1.2b-thinking/reports/report-docs-20260802-102044.md`.

**Result: 2/9 PASS** (`doc-restructure`, `doc-crossref` — the latter
unchanged-SPEC, a per-draw flip not a fix, consistent with the
instability already noted above). None of the 4 newly-steered tasks
passed outright, but real, specific movement:

- **`doc-surgical`**: the "copy the exact given text" instruction fixed
  the wrong-SDK-name leakage completely (forbidden tokens now PASS) —
  but surfaced a new idiom instead: fabricated narration claiming the
  source document "isn't visible," plus the delimiter markers it was
  told not to reproduce. **New idiom — Idiom F: hallucinated
  missing-context narration.** Not in `output-discipline.md`'s scope and
  not covered by `surgical-edit-discipline.md`'s current wording either.
- **`doc-adapt`**: the old forbidden tokens (`npm`, `node dist`) are
  gone; the remaining failure narrowed to 2 of 5 edits (one dropped
  entirely — `ObfuscationConfigLoader` step missing from the output, not
  just misworded; one simply not performed — `Express` token survives).
  Real partial fix.
- **`doc-script`**: unmoved — reproduces the same failure shape as the
  unsteered bare-comparison draw from the previous section. The missing
  `curl`/`mcp-session-id` tokens (untouched by either target edit) show
  the back half of the script got dropped from the output — a
  completeness gap, not the substitution idiom the new instruction
  targets.
- **`doc-repair`**: down to a single remaining defect (the YAML closing
  fence written as a text comment instead of literal backticks) from
  multiple defects before — closest of the 4 to a real fix.

Idiom E (preamble-induced compression) is holding up as a real, useful
diagnosis — completion-token counts and output substance both rose
across all 4 re-steered tasks vs. the blanket-preamble run. Idiom F is
new and specific to `doc-surgical`'s draw so far; needs more draws before
folding a fix into `surgical-edit-discipline.md`. Single draw per task
throughout this pass — see the report for the full per-task caveats and
next-step levers.

## Phase 2 run 2: tried a 7-bullet rules variant, reverted

Added 3 more grounded bullets to `surgical-edit-discipline.md`
(explicit "the document IS visible", "count/check off each edit",
"don't drop untouched content") targeting the exact gaps run 1's report
diagnosed. Result: **worse on all 4 targeted tasks**, not better —
`doc-surgical`'s Idiom F narration got worse despite being told directly
its premise was false, `doc-adapt`/`doc-script` reintroduced forbidden
tokens run 1 had already fixed, `doc-repair` introduced a new
placeholder-comment idiom. Reverted to the run-1 (4-bullet) version per
the quality loop's stop-early rule
(`reports/report-docs-20260802-104628.md`). This sharpens Idiom E: even
a short, task-specific, evidence-grounded instruction addition can cross
this model's tolerance threshold and flip from helping to triggering
narration-instead-of-execution — the threshold for this model+task
family already looked reached at 4 bullets.

## Confirm: 3-loop consistency check on the run-1 (reverted) state

Ran the full docs role 3 more times, unchanged, against the reverted
run-1 state (`surgical-edit-discipline.md` 4-bullet version on
`doc-surgical`/`doc-adapt`/`doc-script`/`doc-repair`; old blanket
`output-discipline.md` still on `doc-verbatim`/`doc-synthesize`/
`doc-summarize`/`doc-crossref`; `doc-restructure` bare). Results:
`reports/report-docs-20260802-105008.md` (0/9),
`report-docs-20260802-105345.md` (2/9),
`report-docs-20260802-105626.md` (1/9).

**Pass count did swing (0, 2, 1) — but tracing it per task shows the
swing is entirely explained by two tasks this session never touched:**
`doc-restructure` (FAIL, PASS, PASS) and `doc-crossref` (FAIL, PASS,
FAIL). **`doc-surgical`, `doc-adapt`, `doc-script`, and `doc-repair` —
the actual subject of this steering work — FAILED all 3 confirm runs,
0/3 each, with no exceptions.** That's a *stable* result for the
steered tasks specifically: consistently improved content quality (per
Phase 2 run 1's diagnosis) but consistently short of a full PASS, not a
flaky one.

`doc-crossref`'s instability was already documented (Idiom E section,
session 2) — its SPEC hasn't changed since. `doc-restructure` failing
once (out of what is now 5+ draws across this entire session, all
others PASS) is new — the one FAIL showed a genuine content defect (an
invented extra table row, `report-docs-20260802-105008.md`), and
completion-token counts were elevated across *every* task in that
specific run (2800–4200 vs. the usual 700–3000), suggesting a real
higher-variance draw rather than an infra fault — service health and
GPU state were checked at the time and showed nothing abnormal (56% VRAM
used, 3% utilization, no truncation).

**Decision: do not revert the steering.** The quality loop's Confirm
rule says to revert to the previous checkpoint on flakiness, but the
flakiness measured here isn't attributable to anything changed this
session — reverting `surgical-edit-discipline.md` further (to the old
blanket preamble, or to bare) would not touch `doc-restructure` or
`doc-crossref` at all, since neither was ever part of this steering
work, and Idiom E already established the blanket-preamble alternative
is a confirmed *worse* content-quality baseline for these 4 tasks. The
run-1 4-bullet state stays as this loop's current best-known state:
0/4 stable on the steered tasks (not yet a fix, but the best content
quality reached so far and not flaky itself), plus 2 known-unstable,
unrelated tasks whose instability predates this session's work.

## Phase 3: cross-model idiom transfer from deepseek-r1-1.5b (documenter role)

`deepseek-r1-1.5b` is the only other model in this project tested
against the docs role. Its `README.md` verdict table lists
`doc-verbatim`/`doc-surgical`/`doc-adapt`/`doc-script`/`doc-repair` —
**the exact same 5 tasks** lfm2.5's Phase 2 plateaued on — as "Not
suitable — structural limit... Not a prompting problem", failing
consistently across 3 historical R1 steering rounds. This is
cross-model evidence (not proof) that Phase 2's diminishing returns on
those 4 tasks (`doc-verbatim` untouched this session but shows the same
severity) may be a real capability ceiling at this model scale, not a
sign more prompt iteration would eventually work — consistent with
Confirm's decision to stop iterating there rather than a coincidence.

R1's `history.md` documents two directly transferable, validated fixes
for tasks lfm2.5 has NOT yet had task-specific steering on:

- **`doc-summarize`** (R1: dropped 1 of 4 required facts under the
  length limit → restructured the SPEC's fact list into an explicit
  numbered checklist + "count before you answer" → **fixed, now PASS**).
  lfm2.5's `doc-summarize` failure is the same idiom: missing 2-3
  required facts/tokens, under the word-count floor.
- **`doc-crossref`** (R1: paraphrased the exact tool name
  `describe_obfuscation_policy` into prose instead of preserving it
  verbatim → explicit "treat this like a variable name you must not
  rename" instruction, later reinforced by the STE ruleset below →
  improved, then 4/5 with STE). lfm2.5's `doc-crossref` shows the same
  "substance right, exact identifier wrong" shape (missing either
  `describe_obfuscation_policy` or `obfuscated.invalid` depending on
  draw).
- **STE (Simplified Technical English, `rules/ste-writing.md`)**:
  controlled vocabulary, active voice, one idea per ~20-word sentence,
  no hedging, exact-identifier preservation as a named rule. Validated
  on R1 across `doc-crossref` (4/5) and `reason-tradeoff` (3/5), both up
  from ~25-33% pre-STE — R1's single highest-leverage lever found.
- **`doc-synthesize`** (R1: failed via "placeholder-latch" — echoing the
  SPEC's own bracketed `[one sentence: ...]` placeholders literally
  instead of writing prose, same idiom `reason-coverage` had; fixed
  there via prose bullets + a worked example + an explicit warning
  against restating the template verbatim). **Confirmed the same
  bracketed-placeholder pattern exists verbatim in lfm2.5's
  `doc-synthesize` SPEC** (`[one sentence: who throws, who catches...]`,
  `[what the C# host throws...]`) — same task, shared across models.
  lfm2.5's actual failure shape differs though (extreme under-
  elaboration, not literal placeholder-echoing) — this is a weaker
  transfer candidate than the other two, worth trying but not assumed.

**Correction before applying anything — checked the actual bare SPECs,
not just the diagnosis, first:** `doc-crossref`'s and `doc-summarize`'s
*bare* SPECs (`tasks/<task>/history/SPEC-pre-lfm2-steer.md`) already
contain R1's exact validated fixes, baked into the shared task text from
the start, not something to newly apply:

- `doc-crossref`'s bare SPEC already has the full STE ruleset prepended,
  the "treat this like a variable name you must not rename" instruction,
  AND a self-check ("does your draft contain BOTH exact strings?").
  lfm2.5 still fails a substantial fraction of draws despite all three
  being present from the very first bare draw this model ever saw.
  **Not a new lever — already tried by construction, doesn't reliably
  transfer.** No further action taken on this task this phase.
- `doc-summarize`'s bare SPEC already has an explicit numbered fact
  checklist and a "count before you answer" instruction, matching R1's
  exact fix. lfm2.5 still drops 2-3 of the 4 required facts and misses
  the word-count floor anyway. **Same conclusion — already present,
  already insufficient.** STE specifically was never applied to this
  task for either model though (R1 piloted STE only on `doc-crossref`/
  `reason-tradeoff`) — that specific combination is untested, applying
  STE alone (not the checklist restructure, which already exists) this
  run.
- `doc-synthesize`'s bare SPEC has no writing-style preamble at all —
  genuinely untested. Applying STE + an explicit warning against
  echoing the bracketed `[...]` placeholders verbatim (the fix pattern
  R1 used for the same placeholder-latch idiom on `reason-coverage`).

`doc-verbatim` stays untouched — R1's structural-limit evidence adds
weight to treating it as a same-family ceiling task alongside the 4
already-plateaued ones, not worth this phase's budget.

### Phase 3 run 1 result: STE negative-transfers to this model

`reports/report-docs-20260802-110413.md`: **1/9 PASS** (`doc-restructure`
only). finish_reason=stop throughout, no truncation. Single draw.

- **`doc-summarize` (STE applied): got worse, not better — 10 words**
  (down from 17 under the old blanket preamble, 20 bare, both already
  under the required-fact count). `"TypeScript/Node chosen. OAuth
  support justifies. Prior servers align. All confirmed."` — STE's
  "one idea per sentence, ~20 words max" reads to this model as a
  brevity instruction and triggers telegraphic fragment compression,
  the opposite of R1's result on the same technique. **Confirmed
  negative transfer, not neutral — do not use STE on this model for
  tasks in the under-elaboration idiom family (matches Idiom A/E).**
  Reverting `doc-summarize` to bare (empirically the best of the 3
  variants tried on this task: bare=20 words, blanket=17, STE=10 — all
  fail the same missing-facts check regardless, so bare's better
  word-count compliance is the only real differentiator).
- **`doc-synthesize` (STE + placeholder-warning applied): unchanged
  severity** — still a single terse sentence, still missing heading/
  JSON/bullets. The placeholder-warning didn't cause harm (no
  placeholder-echoing appeared, wasn't happening before either) but
  didn't fix the actual gap. Given STE is now confirmed harmful
  elsewhere on this model, dropping it here too and keeping only the
  placeholder-warning (untested in isolation, lower-risk than a general
  style constraint) for one more check.
- **`doc-crossref` (reverted to bare): reproduces the exact
  already-documented bare-baseline idiom** (Source A tool name missing,
  Source B fact present) — not new information, confirms the revert
  didn't make anything worse. Bare stays the simplest defensible choice
  here since neither blanket nor bare has ever beaten the other on pass
  rate, and bare avoids adding unproven risk.

**Broader pattern now visible across both Phase 2 and Phase 3**: on
this model+role, *every* attempt to add instruction text — however
well-motivated, however short, however grounded in either this model's
own diagnosed idioms or another model's validated fixes — has either
done nothing or made things measurably worse. Zero exceptions so far
across ~7 experimental variants tried this session. This is itself the
main finding worth carrying forward, not just a step on the way to one.

### Phase 3 run 2 result: corrections applied, still 1/9

`reports/report-docs-20260802-110808.md`: **1/9 PASS** (`doc-restructure`
only), same headline as run 1. Corrections from run 1 (drop STE from
`doc-summarize`, drop STE from `doc-synthesize` keeping only the
placeholder-warning): both sub-metrics improved without flipping either
task to PASS.

- **`doc-summarize` (bare)**: 23 words — now passes the length floor
  (was 10 under STE, 20 bare-in-comparison, 17 under the old blanket
  preamble) — confirms bare is the right choice for this task. Still
  missing the same 3 facts every variant has always missed
  (`Python`, `ConnectWise MCP server`, the SDK-reference-implementation
  fact) — that specific gap has not moved under any variant tried
  across this entire session (bare, blanket, STE). Treat as a stable
  content gap independent of instruction-style, not something the
  writing-style lever can reach.
- **`doc-synthesize` (placeholder-warning only, no STE)**: gained the
  required section heading (missing under every prior variant including
  Phase 3 run 1's STE version) — real, if small, improvement. Still
  missing the fenced JSON block, bullets, and 3 required tokens.
- **`doc-crossref` (bare)**: identical failure shape to run 1 — the
  stable, already-documented bare idiom, not new information.

**Phase 3 conclusion (2 of 5 runs used, stopping here):** no task in
this docs role has been moved to PASS by any cross-model idiom transfer
attempted. Real, measurable sub-metric gains landed (word-count
compliance, a recovered heading) but none closed a task. Combined with
Phase 2's parallel plateau, the evidence base now spans 2 full phases
and ~9 experimental SPEC variants without a single net new PASS beyond
the original bare 1 (`doc-restructure`) — consistent with R1's
cross-model finding that several of these task shapes may be at or near
this model-scale's ceiling, not a sign of insufficient prompt
engineering. Next per the quality loop is Phase 4 (external research)
or accepting this as the loop's plateau and moving to Confirm on this
Phase-3 state.
