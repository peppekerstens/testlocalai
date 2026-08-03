# deepseek-r1:1.5b — steering profile

**Two logical roles**, named subsets each with its own bench track, so
the model and each role can be steered/optimized separately:

1. **documenter** — doc adaptation/creation (README-style docs, config
   schema, tool contracts, operations, end-user guides) plus executable
   artifacts like `test-manual.sh`. Scored by **text fidelity** (and
   `bash -n` for the script). Track: `tasks/doc-*`.
2. **reasoner** — reasoning/analysis work that can't be phrased as a
   coding task, including the manual verification checklist. Scored by
   **content assertions** (no exact-match — reasoning phrasing varies).
   Track: `tasks/reason-*`.

**Never code** — the `code-*` tasks belong to qwen; R1 does not bench
them.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed — suitable for a defined task subset only | Task-category dependent, not one number — see Verdict table | Not assessed | [Verdict: is R1 suitable?](#verdict-is-r1-suitable) |
| Reasoner | ⚠️ Mixed — 1/3 task types solid, rest need steering or are past this model's ceiling | Task-category dependent, not one number — see Verdict table | Not assessed | [Verdict: is R1 suitable?](#verdict-is-r1-suitable) |

## Verdict: is R1 suitable?

**No, not as a general-purpose documenter — but yes for a real, definable
subset of tasks, with real caveats.**

| Category | Example | Verdict | Evidence |
|---|---|---|---|
| Byte-exact reproduction / surgical editing | `doc-verbatim`, `doc-surgical`, `doc-adapt`, `doc-script`, `doc-repair` | **Not suitable — structural limit** | Fails consistently across 3 historical steering rounds + this session. Nested-fence mangling, copy-latch. Not a prompting problem. |
| Diagnosis with a stable misattribution prior | `reason-diagnose` | **Not suitable — model prior, not fixable by prompting** | Names the right variable, wrong mechanism, stable 3/3 across steering attempts. |
| Structural transformation with clear rules | `doc-restructure` | **Suitable** | Passed bare, zero steering needed, first try. |
| Cross-document synthesis w/ exact-identifier preservation | `doc-crossref` | **Suitable with real steering investment** | 4/5 with STE+thinking. Needs it — no-think consistently gets the fact relationship backwards. |
| Bounded compression w/ explicit checklist | `doc-summarize` | **Provisionally suitable — thin evidence** | Fixed, but only 1 draw verified post-fix. Don't trust this line yet without more draws. |
| Exhaustive coverage enumeration, once the SPEC avoids self-mimicry | `reason-coverage` | **Provisionally suitable — thin evidence** | Same caveat: fixed, ~1–2 draws post-fix, not a real reliability sample. |
| Open-ended tradeoff w/ multi-part completeness | `reason-tradeoff` | **Not reliable, either mode** | Best measured rate ~50–60% across two different steering approaches (STE+thinking, no-think). Wouldn't trust unsupervised. |
| Multi-hop root cause | `reason-multihop` | **Unresolved** | Failed bare, never got a steering pass — genuinely open, not "no," just untested. |

**Practical recommendation:** don't deploy R1 as a documenter/reasoner
you trust blind, on anything. For the "suitable" rows, always verify
output — steering gets it to a workable rate, not a guaranteed one. For
the "not suitable" rows, no further prompt engineering is likely to help
— those are past this model's actual ceiling, confirmed across multiple
independent attempts.

**One caveat that cuts the other way:** a context-window bug (see
`history.md`) means a small number of *historical* reasoning-track
failures were inflated by an infra bug, not model quality. Tested and
re-tested — this turned out to be a rare tail event, not a systematic
"8192 is too small" problem; raising the context to 16384 did not reduce
it and was reverted. The original 6 tasks have still not been re-tested
to see whether any of their historical "stable failure" results happened
to land on one of these rare truncation draws — a real, narrow open gap,
but the fix is not "use a bigger context" (already tried, reverted).

## How to optimize for each role

**Documenter (`doc-*`):**
1. Byte-exact/surgical-edit tasks are a hard ceiling at this model size —
   don't spend more steering budget here; route these to a different
   model or a human instead.
2. For tasks that *are* suitable, prepend the STE (Simplified Technical
   English) ruleset (`rules/ste-writing.md`) — controlled vocabulary,
   active voice, one idea per sentence, one name for one thing. This is
   the single highest-leverage lever found so far (roughly doubled the
   pass rate on both tasks it was tried on).
3. Treat exact-identifier preservation (a tool/field name must survive
   into prose unparaphrased) as its own explicit instruction — "treat
   this like a variable name you must not rename" — R1 paraphrases
   identifiers by default otherwise.
4. For fact-checklist tasks, restructure any required-fact list into an
   explicit numbered checklist with a "count before you answer"
   self-check.

**Reasoner (`reason-*`):**
1. Step-by-step verification steering (list each fact/field against its
   rule explicitly, before stating a verdict) is the winning lever for
   verification-shaped tasks.
2. For multi-part questions, explicitly demand each part get its own
   separate, labeled discussion — R1 defaults to answering only the part
   it engages with first and dropping the rest.
3. Cap output length explicitly for checklist/enumeration tasks — R1
   over-produces (100+ steps for a 4–6 step ask) without a stated cap.
4. `DISPATCH_NOTHINK=1` (skip the `<think>` phase entirely via a raw
   `/completion` prefill) eliminates truncation risk by construction, at
   the cost of accuracy on tasks needing multi-fact relational reasoning
   (e.g. `doc-crossref`-style tasks get *worse* with no-think). Check
   per-task before using — not a default.
5. `chat_template_kwargs: {"enable_thinking": false}` does **not** work
   for this model (confirmed empirically) — use `DISPATCH_NOTHINK=1`
   instead if a no-think path is needed.

**Both roles:** run with `DISPATCH_CHECK_MODEL` on (default) and watch
for `finish_reason=length` / `TRUNCATED-BY-CONTEXT-LIMIT` in output —
context exhaustion during reasoning has previously been misdiagnosed as
a content failure; it isn't one.

## Known setup facts

- Whitelisted in `bench/dispatch.sh`; `BENCH_MODEL=deepseek-r1:1.5b` works
  today with no code changes.
- `dispatch.sh` text mode strips `<think>...</think>` blocks
  automatically, so R1 outputs arrive clean.
- Served by `llama-server-deepseek.service` on `:8081` (Q4_K_M GGUF,
  CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8081`. Default
  backend is llamacpp.
- **`tasks/reason-tradeoff/SPEC.md` had a contamination bug, fixed
  2026-08-03 (same class as the `doc-crossref` bug — see root
  `history.md`).** The STE ("WRITING STYLE — Simplified Technical
  English") block this model's `rules/ste-writing.md` documents as a
  steering technique was ALSO baked directly into the shared canonical
  SPEC.md — present since the original import, so this model's very
  first bare `reason-tradeoff` baseline (part of the original 18-task
  combined suite) was never actually measured against a true-bare
  prompt. The block is losslessly preserved at `rules/ste-writing.md`
  (byte-identical), so nothing about the STE-steered results above is
  lost — but the informal "bare vs. STE" before/after comparison
  narrated in `history.md` was really "already-STE-contaminated
  'bare' vs. STE + thinking-mode change," not a clean bare baseline.
  The `reason-tradeoff` row above ("Not reliable, either mode") is the
  final verdict either way, so this doesn't change the practical
  recommendation.

## Bench plan (two tracks)

**Track DOC (documenter)** — `tasks/doc-{verbatim,surgical,adapt,script,synthesize,repair,summarize,crossref,restructure}`:
byte-exact copy, bounded surgical edit, adapt-and-preserve, script
adaptation (`bash -n` + tokens), new-doc synthesis from source material,
in-place repair, bounded summarization, cross-document synthesis with
identifier preservation, structural transformation.

**Track REASON (reasoner)** — `tasks/reason-{config-validity,diagnose,checklist,trace,consequence,compare,multihop,tradeoff,coverage}`:
config validity checking, root-cause diagnosis, manual verification
checklists, code-path tracing, consequence-of-change analysis, candidate
comparison, multi-hop root cause, open-ended tradeoff, exhaustive
coverage enumeration.

All scored by `verify.sh` content assertions; no compile+test.

## Further reading

- `history.md` — full round-by-round steering history, the STE steering
  pass, the context-window infrastructure bug investigation, diagnosed
  failure idioms, and the divergence from qwen's steering playbook.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence going forward (`bash bench/report.sh
  deepseek-r1:1.5b <role>`).
