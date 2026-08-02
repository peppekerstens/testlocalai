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
