# deepseek-r1:1.5b — steering history

Full historical record, moved out of `README.md` 2026-08-02 so that file
can stay current-state-only. Nothing here is summarized away — this is
the durable record for lookup, since the raw `bench/reports/round-*`
evidence these findings were drawn from was deleted the same day as part
of a reports-scheme redesign (see `AGENTS.md`), and the raw per-task
`rounds/out-*.txt` files were already gone before that too, overwritten
by later rounds reusing the same task directories. Also folds in the
overlapping `docs/LOCAL-LLM-BEST-PRACTICES.md` §9.5 write-up (same
findings, no new facts beyond what's below).

## How the current Verdict table was reached

Both DOC/REASON tracks were extended 2026-08-01 with 3 more tasks each
(`doc-summarize`, `doc-crossref`, `doc-restructure`; `reason-multihop`,
`reason-tradeoff`, `reason-coverage`), increasing difficulty. Validated as
achievable via the claude-sonnet-5 blind-subagent protocol before any R1
run (`models/claude-sonnet-5/README.md` "Doc/reason extension", 6/6 PASS).

**First real R1 runs, same day, bare `pure-run.sh` (no steering):**
- Original 12: **0/12** — consistent with this model's documented profile
  (Track DOC not achievable single-shot; Track REASON needs steering),
  not a new regression.
- New 6: **1/6** (`doc-restructure` passed bare; `doc-summarize`,
  `doc-crossref`, `reason-multihop`, `reason-tradeoff`, `reason-coverage`
  failed).

**One steering pass, targeted per failure (not a blanket lever) —
diagnosed each failure's actual output before changing anything:**
- `doc-summarize`: R1 dropped one of 4 required facts (the "prior art"
  fact) under the length limit — restructured the SPEC's fact list into
  an explicit numbered checklist with a "count before you answer"
  instruction (mirrors `doc-verbatim`'s line-count self-check). **Fixed
  — now PASS.**
- `reason-coverage`: R1 literally echoed the SPEC's own "cover these 5
  categories" outline back as its answer instead of filling it in with
  real field names — the **placeholder-latch** idiom, and a bug in how
  the SPEC was written (a numbered template sitting right next to "write
  a numbered list" is too easy to copy), not just a model weakness.
  Restructured as prose bullets (not a numbered list) with an explicit
  worked example and a warning against restating the categories
  verbatim. **Fixed — now PASS.**
- `doc-crossref`: R1 keeps paraphrasing the literal tool name
  `describe_obfuscation_policy` into prose ("describe the obfuscation
  policy") instead of preserving it verbatim — the "substance adapts,
  exact identifiers don't" idiom. Added an explicit "treat this like a
  variable name you must not rename" instruction. **Improved but not
  solid: 1/3 draws PASS post-fix** (was 0/2 before). Still fails most
  draws the same way.
- `reason-tradeoff`: R1 engages with only one of two required
  considerations (phone numbers) and drops the other (note/description
  text) after mentioning it once in passing — the "right pick, wrong
  completeness" idiom. Restructured the SPEC to demand each be discussed
  as its own explicitly separate point. **Improved but not solid: 1/4
  draws PASS post-fix** (was 0/2 before).

**Takeaway:** 2 of 4 targeted fixes reached reliable PASS; 2 measurably
improved (0/2 → 1/3, 1/4) without reaching reliability. Both remaining
idioms (exact-identifier preservation in prose, multi-part-question
completeness) are already-documented R1 limitations this project has
previously found resistant to further prompt engineering at this model's
scale (cf. `reason-diagnose`'s stable config-file misattribution, 3/3) —
treated as a soft ceiling rather than kept iterating without new evidence
a different lever would help.

## STE steering + a real infrastructure bug found (same day, follow-up round)

**Simplified Technical English (ASD-STE100)** — a real, decades-old
aerospace maintenance-manual writing standard (controlled vocabulary,
active voice, one idea per sentence, one name for one thing) — was
piloted as a steering technique on `doc-crossref` and `reason-tradeoff`,
sourced from external research (`woosal1337/blog` ep01 "the cure for AI
slop": cross-model testing found a structured writing system roughly
halves violation rates or better, 74% on Claude Sonnet). Canonical
ruleset: `rules/ste-writing.md`, prepended directly into each task's
`SPEC.md` (doc-mode ignores `--rules`/`--legacy`, so it's embedded, not a
separate flag). "One name for one thing" directly targets the
identifier-paraphrase idiom; "one topic per paragraph" directly targets
the dropped-topic idiom.

**Result, first pass:** `doc-crossref` 4/5, `reason-tradeoff` 3/5 (both up
from ~25–33% pre-STE) — genuine improvement, both promoted; pre-STE SPECs
archived to `history/SPEC-pre-ste.md`.

**Real infrastructure bug found along the way, not a model failure:** two
`reason-tradeoff` draws produced 0-byte output despite burning ~7446
completion tokens each. Root cause, fully confirmed (not guessed): R1's
llama-server response splits `content` (the final answer) from
`reasoning_content` (the `<think>` trace) as separate JSON fields;
`dispatch.sh` only ever read `content`. `llama-server-deepseek.service`'s
context window (`-c 8192`) was too small for some of R1's reasoning
traces, so generation got cut off *while still inside* `reasoning_content`
— `content` was empty because the model never got there, not because it
failed to reason. Confirmed by both fresh draws (`prompt_tokens +
completion_tokens = 8192` exactly, both draws identically) and
retroactively against this project's own earlier `reason-consequence`
finding (`541 + 7651 = 8192` exactly) — "pure think degeneration" had
been mislabeled as a reasoning-quality problem in earlier rounds when it
was this sizing bug the whole time.

**Tooling fixed permanently:** `dispatch.sh` now records `finish_reason`
and `reasoning_content_chars` in every sidecar `.tokens.json`, warns on
stderr immediately when `finish_reason=length`, and `bench.sh`/
`pure-run.sh` both surface a `TRUNCATED-BY-CONTEXT-LIMIT` flag in
reports/results — checked automatically going forward.

**`DISPATCH_NOTHINK=1`** — a second lever, added after the context fix:
`dispatch.sh` can pre-fill an already-closed, empty `<think></think>`
block via llama.cpp's raw `/completion` endpoint (confirmed working via
this server's actual `/props` chat-template, using its real
`<｜User｜>`/`<｜Assistant｜>` turn tokens), so the model skips reasoning
entirely and goes straight to the answer. Deepseek-r1-only, llamacpp-only
(hard-enforced). Standard `chat_template_kwargs: {"enable_thinking":
false}` was tried first and does **not** work for this model (confirmed
empirically — `reasoning_content` still fully populated even for a
trivial question); the prefill trick does.

**Honest result, not the flattering early read:** an initial n=3 sample
looked like a clean win for both tasks (`doc-crossref` 2/3 → then
corrected to 0/3, see below; `reason-tradeoff` 3/3). A proper n=5 run
through the real `bench.sh` pipeline told a different story:
- `doc-crossref`: no-think is **0/3, consistently** — not a token-check
  artifact. Reading the actual answers, no-think versions consistently
  get the fact relationship backwards, describing
  `describe_obfuscation_policy` (a *reporting* tool per its own source
  text) as if it performs the obfuscation itself. `verify.sh` didn't
  catch this at first — both required strings were present, so it scored
  PASS — until the check was tightened to detect the specific backwards
  phrasing. **Thinking measurably helps this task**; no-think is not used
  here.
- `reason-tradeoff`: no-think is **4/8 (50%)** combined across both
  batches — not the clean win the first n=3 batch suggested, and roughly
  comparable to (not clearly better than) the with-thinking STE version's
  content-quality rate. Its one unambiguous benefit: **zero truncation
  risk**, since there's no reasoning phase left to run away. Kept as a
  documented option, not switched to the default — the STE-with-thinking
  SPEC stays primary.

**Lesson reinforced, not new:** a 3-draw sample looked conclusive and
wasn't (this project has said "treat one round as one draw" before —
qwen's task4, R1's reason-checklist — this is the same lesson landing a
third time, now with a concrete before/after (3/3 → 4/8) to point at).

### Context-window bump: tested and reverted (2026-08-01)

The `-c 16384` bump was initially declared "Fixed" without re-testing it
— challenged directly, and a spot check already sitting in hand from the
same session disproved it: 5 draws of `reason-tradeoff` (STE+thinking,
`-c 16384`) came back 1 PASS (740 completion tokens, clean `stop`), 1
**TRUNCATED** (`783 + 15601 = 16384` — hit the new ceiling exactly, same
failure mode as before, just at a bigger number), 2 genuine
content-completeness FAILs (~750 tokens each, well under either ceiling),
and 1 timeout. Raising the ceiling did not stop runaway reasoning; it let
one draw run twice as long before hitting the (now bigger) wall. The
underlying behavior — reasoning length is effectively unbounded for a
minority of draws, regardless of ceiling — was never actually fixed by a
bigger number.

`llama-server-deepseek.service` was reverted to its original `-c 8192`
(confirmed via `/v1/models`: `n_ctx: 8192`), and a fresh, clean 5-draw
batch was run against the current promoted STE+thinking `reason-tradeoff`
SPEC through the real `bench.sh` pipeline (`round-c8k1`..`round-c8k5`):

| Draw | Completion tokens | finish_reason | Result |
|---|---|---|---|
| c8k1 | 614 | stop | PASS |
| c8k2 | 551 | stop | PASS |
| c8k3 | 537 | stop | FAIL (dropped note/description topic) |
| c8k4 | 921 | stop | FAIL (dropped utility side of tradeoff) |
| c8k5 | 694 | stop | PASS |

**3/5 (60%) PASS, zero truncations** — every draw finished with a clean
`stop`, none came close to the 8192 ceiling (largest completion was 921
tokens; prompt was a fixed 783). At least as good as the 16384 spot check
(1/5, confounded by a truncation) and consistent with the original
pre-bump STE first-pass rate (3/5). **Conclusion:** the two historical
truncations that motivated the bump were real, but appear to be rare tail
events tied to occasional runaway reasoning length, not a systematic case
of 8192 being too small for this task. Enlarging the context did not
reduce the rate of that tail event — it only let it burn more tokens
before failing the same way. `-c 8192` was kept (reverted, not
re-bumped): no measured reliability benefit from the larger value, and it
costs more VRAM/latency for nothing. The truncation-tail risk is still
real and still worth guarding against — `DISPATCH_NOTHINK=1` remains the
actual mitigation for it (zero truncation risk by construction), with its
own already-documented accuracy tradeoff (better on `reason-tradeoff`-
style breadth tasks, worse on `doc-crossref`-style relationship tasks).

**Flagged for a future round, not tested:** a claim that a context window
*smaller* than 8k might improve a small model like this one's answers,
recalled but without a source in hand to confirm it. Needs a real
citation before it's worth a test session — same "grounded in real
sources" bar this project applies to every other steering technique.

## Bare-baseline round-by-round data (rounds r1–r3)

Round **r1** (baseline, bare SPEC, temp 0.2, llama.cpp `:8081`) — Track
DOC 0/4, Track REASON 1/3 (`reason-checklist`):

| task | tokens (p/c) | verdict | failure mode |
|---|---|---|---|
| doc-verbatim | 508 / 935 | FAIL | **duplication + framing**: echoed input+note, then added `## Output` and repeated the whole doc again; wrapped everything in a ` ```yaml` fence (MUST NOT). Content itself was an accurate copy. |
| doc-surgical | 601 / 656 | FAIL | **copy-latch, no in-place edits**: reproduced the source verbatim (TS tokens intact), then emitted the two replacement strings as *separate appended ` ```json` snippets* instead of editing the doc in place; leading ` ```json` fence. |
| doc-adapt | 654 / 765 | FAIL | **rewrite instead of preserve**: forbidden/required token checks PASSED (substance adapted correctly) but structure diverged — renumbered steps 4–6, turned the appended note into steps, dropped the `> C# adaptation` line; leading ` ```markdown` fence. |
| doc-script | 995 / 1239 | FAIL | **broke the script**: adapted commands correctly (no npm/node, dotnet present) but rewrote the readiness-poll + session-init sections (initialize POST inside the poll loop, `json Parse`, stray `fi`, `&>&2`), trailing ` ``` ` fence → `bash -n` fails. |
| reason-config-validity | 336 / 457 | FAIL | **shallow verification — WRONG verdict**: concluded "config is valid" and missed that `nestedEntities.defaultContact: owner` references `owner`, which is not a key in `entities`. Confident, wrong. |
| reason-diagnose | 108 / 570 | FAIL | **right culprit, wrong mechanism**: named `CW_PRIVATE_KEY` but blamed "the project's configuration file" instead of the env var not being set (`requireEnv` fail-fast). |
| reason-checklist | 362 / 7830 | **PASS** | passed, but **over-productive**: 162 numbered steps, 7.8K completion tokens for a 4–6 step ask. |

**Round-r1 scorecard:** DOC 0/4, REASON 1/3 (the one pass over-produced).
Reasoning failures are model-level (shallow referential check, mechanism
misattribution), cleanly separated from the role-framing failures by the
two-track split.

**Round-new** (6+6 split, bare SPEC — the five tasks added after the
split): DOC 0/2, REASON 0/3.

| task | tokens (p/c) | verdict | failure mode |
|---|---|---|---|
| doc-synthesize | 516 / 692 | FAIL | **placeholder-latch, no synthesis**: echoed the SPEC's bracketed `[one sentence: …]`/`[what the C# host throws…]` placeholders literally instead of writing prose, and omitted the required heading. Structure without content. |
| doc-repair | 399 / 738 | FAIL | **repair-latch with artifacts**: added annotation text ("Header row / Separator row / Body rows | Table") *inside* the document, duplicated the block, re-fenced; did not just apply the two fixes. |
| reason-trace | 489 / 619 | FAIL | **scenario misread**: answered the load-balancer/instance-B case instead of a process restart — missed `No valid session ID`, `re-initialize`, `Map`. |
| reason-consequence | 541 / 7651 | FAIL | **pure-`<think>` degeneration**: 0-byte output (only a think block, stripped by `dispatch.sh`) with 7651 completion tokens — later diagnosed as context exhaustion, see above. |
| reason-compare | 501 / 645 | FAIL | **right pick, wrong completeness**: chose candidate A correctly but never discussed the `/mcp` try/catch defense the SPEC explicitly requires — missing required tokens `try/catch`, `listen`, `config was valid`. |

The 5 new tasks widened the tracks' leverage: R1 was 0/5 here (big-pickle
5/5), and the failures are all model-level (placeholder-latch,
repair-latch, scenario misread, think-degeneration, incompleteness), not
test artifacts.

**Rounds r2/r3 — steering iterations:**

| task | r1 | r2 | r3 | lever tested in r2/r3 |
|---|---|---|---|---|
| doc-verbatim | FAIL | FAIL | FAIL | delimiters → copied markers; line-count self-check → dropped the inner yaml block |
| doc-surgical | FAIL | FAIL | – | delimiters+FIND→REPLACE → output the edit *mappings*, no doc |
| doc-adapt | FAIL | FAIL | – | delimiters+FIND→REPLACE → copy-latch (input echoed, no edits) |
| doc-script | FAIL | FAIL | – | delimiters + "must pass bash -n" → **bash -n PASS** but copy-latch (no edits applied) |
| reason-config-validity | FAIL | **PASS** | – | step-by-step verification steering **fixed it** (→7.8K-token output though) |
| reason-diagnose | FAIL | FAIL | FAIL | step-by-step steering; model still insists "add to the project's configuration file / .dotnetconfig" (wrong mechanism) and won't quote the log line — 3/3 stable |
| reason-checklist | PASS (162 steps) | FAIL (pure-`<think>` degeneration, empty) | FAIL (5 steps, missing `dotnet run`/`/mcp`) | output caps; r1 bloated, r2 degenerate, r3 structurally right but incomplete |

**Capability verdict after 3 steering rounds:**
- **Track DOC — not achievable single-shot at 1.5B.** Byte-exact
  reproduction of a markdown doc with a nested fenced block fails in
  every framing (bare / delimiters / FIND→REPLACE / line-count). The
  nested fence is mangled every time (dup / split / dropped). In-place
  multi-edit fails three different ways (copy+edit-artifacts,
  edit-mappings, pure copy-latch). Token-level adaptation *does* work
  (doc-adapt r1 passed token checks).
- **Track REASON — 1/3 solid, steering matters.** Step-by-step
  verification is the winning lever (config-validity FAIL→PASS).
  reason-diagnose is a model prior (misattributes to config files),
  stable 3/3. reason-checklist is flaky around the pass line (33% in 3
  draws) with output bloat/degenerate draws — needs output caps +
  re-verification.

**Reference baseline (codenamed "big-pickle" at the time; orchestrator
model, directory now `models/claude-sonnet-5/`):** 12/12 on the full
12-task suite. Calibration: REASON 6/6 for big-pickle vs 0–1/6 for R1 →
the reason tasks are fair, R1's failures are model-level. DOC:
big-pickle's failures were semantic non-errors (blank line /
line-wrapping) — byte-exactness is stricter than production acceptance.
The baseline surfaced test fixes now applied: `doc-verbatim/expected.md`
had a stray blank line contradicting its SPEC ("exactly 16"; fixed),
`doc-surgical`/`doc-adapt` exact-match is now whitespace-normalized
(token+structural; byte-diff diagnostic only) so a correct edit that
re-wraps a phrase passes, and `reason-trace`'s forbidden list penalized
tokens the source doc itself contains (fixed; REQUIRED tokens alone
discriminate). R1's own failures (copy-latch, edit-mappings, scenario
misreads, `<think>` degeneration) still FAIL under the fixed checks — the
fixes do not mask real errors.

## Diagnosed R1 failure idioms (round r1, vs qwen)

1. **Wrapper framing**: R1 opens with a code fence mirroring the doc's
   first fenced language (`yaml/json/markdown`) and closes with one — it
   "echoes" the doc as one big fenced block. qwen (code-emitter-csharp)
   never did this.
2. **Copy-latch**: on edit tasks R1 prefers to reproduce the source
   verbatim rather than apply in-place edits; "be conservative" phrasing
   made it worse. It understands edits but materializes them as trailing
   artifacts (e.g. JSON snippets), not as in-place changes.
3. **Input/output duplication**: verbatim task → prints source, then
   `## Output` + source again. An annotator/echo habit at 1.5B.
4. **Substance adaptation works, exact structure doesn't**: adapt tokens
   pass (no `npm`, C# tokens present) but prose/step structure diverges
   from the reference — a 1.5B R1 cannot reproduce an author's exact
   phrasing for a rewrite task.
5. **Shallow verification (reasoning role)**: on config-validity it
   concluded "valid" without checking `nestedEntities` referential
   integrity; on diagnose it named the right var but the wrong mechanism.
   Verification is pattern-matched, not systematic.
6. **Over-production (reasoning role)**: the one PASS (checklist) emitted
   162 steps / 7.8K tokens against a 4–6 step ask — needs output caps.
7. **Placeholder-latch** (documenter role, new tasks): on a synthesize
   task R1 echoes the SPEC's *structure template* verbatim instead of
   filling it in — structure-without-content.
8. **Repair-latch with artifacts** (documenter role, new tasks): on a
   repair task R1 doesn't just apply the fixes — it annotates them
   in-band, duplicates content, and re-fences.
9. **Scenario misread** (reasoner role, new tasks): reason-trace asked
   about a process restart; R1 answered the load-balancer/instance-B
   case. It latched onto the doc's most vivid paragraph instead of the
   question's actual scenario.
10. **Pure-`<think>` degeneration** (reasoner role, new tasks):
    reason-consequence produced a 7651-token think block and zero
    answer — later diagnosed as context exhaustion (see above), not a
    reasoning failure.

## Steering divergences vs qwen

qwen's winning levers ("show don't describe", verbatim complete shapes in
the SPEC) transferred only partially: the doc fixtures already are
complete shapes, yet R1 still annotates/repeats. The missing piece is
**output-frame control** — delimiters + strict "output only, once, no
fences" — not more content fidelity in the SPEC. Round r2 (Track DOC)
tested `[DOC_START]/[DOC_END]` delimiters around the document,
FIND→REPLACE pairs (exact strings, not prose) for edit tasks, removal of
the "be conservative" R1 self-identification, and explicit one-document
output rules. Track REASON r2 tested step-by-step verification steering
(list each field against its rule before the verdict) + an output cap on
the checklist.
