# qwen3.5:9b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of
[`qwen3.5-4b`](../qwen3.5-4b/)/[`qwen3.5-2b`](../qwen3.5-2b/)/
[`qwen3.5-0.8b`](../qwen3.5-0.8b/) in the same model family. Runs on
this GPU (4GB VRAM) via an explicit partial `-ngl` offload, tuned to
~3x the naive `-ngl 99` speed — see Setup.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed — quality loop closed 2026-08-03, 8 of 9 task shapes stable (3/3 Confirm), 1 unresolved | 5/9 bare → 8/9 stable (89%) | ~89% of an assumed frontier-model ceiling on this specific 9-task suite — see the Final report for reasoning | [Documenter role: final report](#documenter-role-final-report-closed-2026-08-03) |
| Reasoner | 🔬 In progress — bare baseline done 2026-08-04, Tier 1 steering not started | 3/9 bare → not yet steered | Not assessed | [Reasoner role: current status](#reasoner-role-current-status-in-progress) |

## Documenter role: final report (closed 2026-08-03)

**Why stopped here.** Full quality loop across three sessions on the
same day. **Phase A**: thinking-enabled spot-check (inconclusive),
`enable_thinking=false` baseline, Research, Steering Tier 1, an
autonomous Tier 2 gate (56% < 60%, skipped), 3-run Confirm — closed at
4 stable-pass/2 stable-fail/3 unstable. **Phase B**: user-directed
ungated re-loop of every remaining failure (5+ attempts each) plus a
`tasks/doc-repair/SPEC.md` bug fix — closed 8 of 9 tasks; the 9th
(`doc-surgical`) was *believed* closed too via a grammar, but that
grammar turned out to be invalid (see "A real mistake, corrected"
below) — closing at what was genuinely 8/9. **Phase C**: an actual
Tier 2 generalist search (the initial "100% specialist, skip Tier 2"
reasoning had itself skipped `AGENTS.md`'s own autonomous gate rule —
caught and re-opened), plus a Performance phase.

**Usability score without optimizations**: 5/9 (56%) PASS bare, under
`enable_thinking=false` — zero truncation, no hidden empty-output
failures.

**Usability score with optimizations** (Confirm-verified, 3/3 across
6 genuine specialist-config draws collected during this session):
**8 of 9 tasks stable PASS**, 1 (`doc-surgical`) stable FAIL,
genuinely unresolved after 5 distinct legitimate steering attempts.
One task (`doc-synthesize`) needs its own honest caveat: Confirm-
verified 3/3 in two separate small samples, but a larger 6-draw sample
collected later in the session showed 5/6 (≈83%) — a real, specific
instability on that one task, not evidence that every "stable" verdict
in this file is overstated (every other task held a clean 6/6 across
that same larger sample). Zero truncation across every draw, in every
phase.

### A real mistake, corrected: `doc-surgical`'s grammar was invalid

Documented here prominently because it's the most important
methodological finding of this session, not just a `doc-surgical`
detail. A grammar written for `doc-surgical` was described as "near-
fully-literal... legitimate because the content is prompt-given" — it
was actually **fully literal**: one fixed string with zero free-text
nonterminals. The decoder produced that exact output regardless of
what the model generated; the "PASS" was a tautology, true for any
model including a random one. Caught by the user asking directly about
the 100% pass rate this produced. Corrected: the grammar was discarded,
`doc-surgical` was retested and confirmed genuinely unresolved. A
follow-up "partial" grammar attempt (literal only at the 3 specific
edit-anchors, free text elsewhere) caused a **real runaway generation**
(2000+ tokens vs. a normal ~230) — an unbounded free-text rule has no
natural stopping point. Also discarded. See
`docs/GRAMMAR-STEERING-PATTERNS.md` for the reusable "legitimacy line"
and "bounded free-text" rules written directly from this mistake, so a
future session doesn't repeat either failure mode.

**5 distinct legitimate steering attempts on `doc-surgical`, all
failed**, each a different failure shape: a word-level reminder (left
a stray old-text fragment merged with the new text), quoting the exact
target lines verbatim (backfired — the model duplicated the reminder's
own example text into the output), a checklist-style verification
instruction (reverted to not applying the edit at all), a few-shot
worked example (1/5 reliability, not a fix), and a cross-model
transfer of `lfm2.5-1.2b-thinking`'s `surgical-edit-discipline.md` +
`ste-writing.md` rules (same original defect — dropped "(" / "the C#
SDK " prefix from the given replacement text). This matches
`qwen3.5-4b`'s own exhausted attempts on a related idiom — a
structural, not phrasing, limitation.

### Tier 2: a real generalist search, and what it found

The original "8/9 [believed 9/9 at the time] specialist, little value
in Tier 2" framing had itself skipped `AGENTS.md`'s own autonomous
gate rule (≥60% specialist rate → Tier 2 must run) — caught by the
user, re-opened properly.

**No single config matches specialist reliability** — expected, since
the specialist configs differ in *kind* (2 GBNF grammars, 2 named-
token prompt overrides, 5 bare), not just detail. Tested: a hand-
written generic reminder (4 draws: 5/9, 5/9, 6/9, 4/9), a cross-model
transfer of `lfm2.5-1.2b-thinking`'s discipline rules as a blanket
config (2 draws: 6/9, 6/9), and — the one genuine improvement found —
**the same lfm2.5-derived generic config at a lower temperature**
(`0.4` vs. the family's usual `1.0`): **3/3 identical draws at a
stable 6/9**. The hypothesis behind trying this: `doc-script`/
`doc-restructure`'s generic-config failures looked like per-draw
*noise* (temperature should reduce it), while `doc-verbatim`/
`doc-surgical`/`doc-script`'s failures looked like *systematic* bias
(temperature shouldn't touch it) — confirmed exactly that split.
**Accepted by the user as the Tier 2 result at 6/9** (short of
specialist's 8/9, a real and reproducible generalist finding, not a
config actually adopted for serving).

**Does the STE/discipline rule replace any specialist config?**
Tested directly, per the user's own question: no, mostly not.
Comparison: matches `doc-synthesize`'s specialist reliability closely
enough to be worth a follow-up check (didn't hold up at 3 more draws,
kept the specialist override); does **not** replace `doc-script`
(0/2), `doc-verbatim` (0/2), or `doc-restructure` (1/3, vs. grammar's
5/5) — these need their specific levers; shows a possible regression
risk on `doc-repair` (1/2 vs. bare's near-perfect reliability) from
wrapping an already-solved task in unnecessary reminder text. Net:
replaces ~1 of 8 active levers, actively underperforms on the 3 most
important ones.

**The more valuable Tier 2 output wasn't a config at all**: a
documented **decision procedure** (`AGENTS.md`'s Tier 2 section) —
"when a task's failure is structural/positional and resists real
prompt-only steering, check whether the backend supports grammar-
constrained decoding before spending more prompt budget" — plus
`docs/GRAMMAR-STEERING-PATTERNS.md`'s backend-capability notes and
reusable structural-grammar templates. This generalizes across models
and future sessions the way a single prompt config for 9 specific
tasks never could.

### Performance phase: prompt compression

Applied this project's proven caveman ruleset (from
`qwen2.5-coder-1.5b`'s own history — drop filler/articles/hedging in
prose, keep every verbatim string and technical requirement byte-for-
byte) to the 2 controllable specialist overrides' framing text.
`doc-script`: 1172→1123 prompt tokens (**-4.2%**), 7/7 PASS across all
of this session's remaining testing — kept. `doc-synthesize`:
661→627 tokens (-5.1%), but a real regression (4 forbidden tokens
leaked instead of the 1 the reminder targets) — reverted per
`AGENTS.md`'s "revert anything that regresses" rule. Savings were
modest overall (~4-5%, not the ~30% seen on `qwen2.5-coder-1.5b`'s own
caveman round) — this project's doc-task prompts are already lean, so
there's less filler to trim; not a failure of the technique, just a
smaller opportunity here.

**Comparison against a mainstream frontier LLM**: no direct benchmark
run against one exists for this exact suite, so this is a reasoned
indicator, not a measured score. This 9-task suite tests precise,
well-specified instruction-following (exact verbatim reproduction,
exact find-replace edits, structured extraction under strict format
rules) — the kind of task a frontier model (e.g. Claude Haiku 4.5,
GPT-4o-class) would be expected to handle reliably, roughly 95-100%,
since none of it requires novel reasoning, just careful adherence to
given instructions. Against that assumed ~100% ceiling, **this
configuration reaches ~89% (8/9)** — a genuinely strong result for a
9B local model at near-zero cost/latency versus a hosted call, but the
gap is real and concentrated in exactly one task shape (`doc-surgical`:
short, exact-quoted replacement text fidelity), not spread thinly
across the whole suite.

**Final verdict: usable for 8 of 9 task shapes with `enable_thinking=false`
plus the configs below, mandatory human review for `doc-surgical`-shaped
work (or route it elsewhere), lighter review for everything else given
the corrected reliability picture (`doc-synthesize` specifically:
~83%, not 100%).** The best qwen3.5-family result by a clear margin —
8/9 solid with exactly one clean failure, a categorically cleaner
profile than any sibling (`4b`, re-tested 2026-08-03 with this
model's own `doc-repair`/grammar findings: 4 stable, but 4 more at
genuine coin-flip reliability, not a comparably clean shape; `2b`: 1
stable; `0.8b`: ~2 at 67% each) — driven by an unrelated bug fix
(`doc-repair`) and a genuinely new lever class (grammar) neither of
which is specific to this model size. `qwen3.5-4b`'s own
`doc-verbatim`/`doc-restructure` were successfully re-tested with the
grammar approach and fixed via direct transfer (see its own README) —
`-2b`/`-0.8b` not yet done, still worth checking.

**Per-task detail** (Confirm-verified 3/3 unless noted):

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-adapt` | **Stable PASS, 6/6** (bare, never steered) | bare | 2/2 under the generic config |
| `doc-synthesize` | **Mostly stable, 5/6 (≈83%)** — real per-draw instability found via extended testing, not a compression artifact (see Performance phase) | [`task-overrides/doc-synthesize.md`](task-overrides/doc-synthesize.md) — JSON-block + `zod`-token reminders | ~2/2 close but not confirmed as a clean replacement |
| `doc-script` | **Stable PASS, 7/7** (steered + compressed) | [`task-overrides/doc-script.md`](task-overrides/doc-script.md) — compressed both-lines-must-be-gone + forbidden-token reminder | 0/2 — generic version fails, needs the specific token named |
| `doc-summarize` | **Stable PASS, 6/6** (bare, never steered) | bare | 2/2 |
| `doc-crossref` | **Stable PASS, 6/6** (bare, never steered) | bare | 2/2 |
| `doc-repair` | **Stable PASS, 6/6** (bare, once the shared task's bug was fixed) | bare | 1/2 — possible regression risk when wrapped unnecessarily |
| `doc-verbatim` | **Stable PASS, 6/6** (grammar) | [`grammars/doc-verbatim.gbnf`](grammars/doc-verbatim.gbnf) — structural: blank-line/fence positions forced, content free | 0/2 |
| `doc-restructure` | **Stable PASS, 6/6** (grammar) | [`grammars/doc-restructure.gbnf`](grammars/doc-restructure.gbnf) — structural: header/separator/4-row shape forced, cell text free | 1/3 |
| `doc-surgical` | **Stable FAIL, 0/many** — genuinely unresolved after 5 distinct legitimate attempts | bare (no valid config found) | 0/2 |

**Tier 2 generalist config** (the one adopted result, not used for
serving — see above): lfm2.5-derived discipline rules +
`DISPATCH_TEMPERATURE=0.4 DISPATCH_TOP_P=0.9
DISPATCH_PRESENCE_PENALTY=1.5`, stable 6/9 across 3/3 draws.

## Reasoner role: current status (in progress)

**Bare baseline (2026-08-04): 3/9 PASS** (`reason-checklist`,
`reason-consequence`, `reason-tradeoff`), same `DISPATCH_ENABLE_THINKING=false`
dispatch config as the documenter role — see Setup. Zero truncation,
`finish_reason=stop` on all 9. Single draw, not yet a reliability
sample. Tier 1 specialist steering has not started yet.

**Before this number could be trusted, a shared-file contamination bug
had to be fixed first** (2026-08-04): 7 of 9 `reason-*` SPEC.md files
had `lfm2.5-1.2b-thinking`'s "OUTPUT DISCIPLINE" steering block baked
directly into the shared canonical file (never reverted after that
model's own session), inflating this model's first dispatch to an
invalid 6/9. See `history.md`'s "Reasoner role: kickoff" section for
the full story — this model's own docs-role numbers are unaffected,
this only ever touched `reason-*`.

**Failure idiom found in this baseline** (see
`reports/report-reason-20260804-151034.md`'s Findings for full detail):
4 of 6 failures (`reason-diagnose`, `reason-trace`, `reason-compare`,
partially `reason-multihop`) share one shape — the model's reasoning
reaches the substantively correct conclusion but doesn't reproduce the
task's exact required phrase/vocabulary verbatim. The other 2
(`reason-config-validity`: copies extraneous input-schema field names
into its own reasoning; `reason-coverage`: drops one whole required
checklist category rather than getting it wrong) are distinct idioms,
not variants of the same one.

## How to optimize (verify before trusting)

- `DISPATCH_ENABLE_THINKING=false` is required — see Setup. Does NOT
  speed up per-token generation (that's a VRAM-oversubscription/`-ngl`
  question) — it fixes total answer *length*.
- For `doc-synthesize`/`doc-script`-shaped tasks: a targeted prompt
  reminder naming the specific dropped/leaked token works — see
  `task-overrides/`. **`doc-synthesize` specifically is not 100%
  reliable even with its override (~83% at a larger sample) — always
  run multiple draws before trusting a single result.**
- For `doc-verbatim`/`doc-restructure`-shaped tasks (blank-line/fence-
  position instability, missing table separator row on a freshly-
  generated table): prompt-only steering was tried and failed first —
  a **GBNF grammar** (structural, decoding-time) fixed both. See
  `docs/GRAMMAR-STEERING-PATTERNS.md` for when this lever applies and
  starter patterns to adapt.
- For `doc-surgical`-shaped tasks (short, exact-quoted replacement
  text fidelity): **genuinely unresolved.** 5 distinct prompt attempts
  and 2 grammar attempts (1 invalid/discarded, 1 caused a runaway
  generation) all failed. Don't spend further budget here without a
  new idea — route this task shape to a larger model or human review.
- For `doc-repair`-shaped tasks: check the shared task's own `SPEC.md`
  for self-contradictory instructions before assuming a model
  capability gap — this exact task had one (see Setup).
- **Grammar legitimacy rule** (see `docs/GRAMMAR-STEERING-PATTERNS.md`
  for the full reasoning): constrain STRUCTURE only — positions,
  shapes, required-but-already-given literal spans. A grammar whose
  `root` rule is a large fixed literal string tests the grammar
  engine, not the model — this session's `doc-surgical` mistake,
  corrected above, is the concrete cautionary example.
- **Unbounded free-text grammar rules can cause runaway generation** —
  keep every free-text nonterminal bounded (per-line, or anchored to a
  concrete terminator), never open-ended.
- **A generic/shared config reliably underperforms specialist configs
  here** — don't reach for one hoping to simplify maintenance unless
  you've actually measured the gap; see the Tier 2 section above.

## Setup

- Served by `llama-server-qwen3.5-9b.service` on `:8087` (Q4_K_M GGUF,
  CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8087`.
- Downloaded 2026-08-02: `unsloth/Qwen3.5-9B-GGUF`,
  `Qwen3.5-9B-Q4_K_M.gguf`, 5.68GB.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:9b`.
- **`-ngl 99` (request all layers on GPU) is a real anti-pattern on an
  undersized card.** This GPU (GTX 1650, 4096MiB total VRAM) does not
  have enough free VRAM (~3.3GB free after other services stop) to
  hold this 5.68GB model. `-ngl 99` forces the driver to blindly
  re-page the entire model on every layer via NVIDIA's transparent
  VRAM oversubscription — ~2.6-3.1 tok/s. An explicit, smaller `-ngl N`
  gives llama.cpp a fixed, deterministic GPU/CPU split instead.

  **Benchmark (300-token completion, fixed 23-token prompt):**

  | `-ngl` | tok/s | Free VRAM after load | vs. `-ngl 99` |
  |---|---|---|---|
  | 99 (driver-paged, original) | 3.1–3.15 | 195 MB | 1.0x |
  | 9 | 5.90 | 1353 MB | 1.9x |
  | 14 | 7.30 | 655 MB | 2.3x |
  | 18 | 8.59 | 217 MB | 2.7x |
  | 20 | 9.46 | 173 MB | 3.0x |

  **`-ngl 20` is the final serving config**, validated with full
  real-length docs-role runs — no crash/OOM, no quality regression,
  ~3.0x faster than `-ngl 99`. `-ngl 20`'s free VRAM (173MB) is about
  the same as the original broken `-ngl 99` (195MB), yet 3x faster —
  free VRAM margin alone doesn't predict speed, whether the split is
  static/deterministic vs. reactive/driver-paged does.

  **How to work out the right `-ngl` on different hardware**: no
  shortcut skips measuring your own system. Check real free VRAM
  (`nvidia-smi --query-gpu=memory.free --format=csv`), get the model's
  real per-layer weight size from the GGUF's own tensor offset table
  (not a guess), start conservative, push up in small steps re-
  benchmarking each time, and validate the final choice with a real
  full-length workload before trusting it.
- **Mandatory: restart the service and log free VRAM/RAM before every
  test run** (`bench/report.sh`, now automatic — see `AGENTS.md`).
  Found mid-session: ~2.5 hours of continuous dispatching (no restart)
  drove generation from 9.46 down to **0.73 tok/s** — system RAM
  exhausted, swap 100% full. A restart fixed it immediately; root
  cause not fully diagnosed (KV-cache accumulation or fragmentation
  are the leading hypotheses). This is a test-measurement hygiene
  rule, not a production-serving recommendation — it deliberately
  isn't representative of sustained real-world load.
- **Required dispatch overrides**: `DISPATCH_ENABLE_THINKING=false
  DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20
  DISPATCH_PRESENCE_PENALTY=2.0`. Full reproducible invocation:
  ```
  DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8087 \
  DISPATCH_ENABLE_THINKING=false DISPATCH_TEMPERATURE=1.0 \
  DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=2.0 \
  bash bench/report.sh qwen3.5:9b docs llamacpp 8087
  ```
- **GBNF grammar steering** (`DISPATCH_GRAMMAR_FILE`):
  `bench/pure-run.sh` auto-resolves
  `models/qwen3.5-9b/grammars/<task>.gbnf` per task, same mechanism as
  `task-overrides/` — no manual env var needed for a normal
  `bash bench/report.sh` run. Used for `doc-verbatim`/`doc-restructure`
  only — `doc-surgical`'s grammar was found invalid and discarded (see
  the Final report above).
- **`tasks/doc-repair/SPEC.md` had a bug, fixed (commit `8d98d91`).**
  Its "DEFECT 2" instruction claimed the embedded source table was
  missing a separator row — it wasn't (confirmed via `git blame`:
  present since the original import, affecting every model ever
  tested against this task, not just this one). Fixed by removing the
  separator row from the source. This model's `doc-repair` result is
  fully re-tested and confirmed against the fixed task.
- **`tasks/doc-crossref/SPEC.md` also had a bug, fixed (commit
  `62d3995`), a second contamination the original doc-repair fix
  missed.** A "WRITING STYLE — Simplified Technical English" steering
  block — an `lfm2.5-1.2b-thinking` transfer experiment meant to be
  reverted — was still baked into the shared canonical file, so this
  model's `doc-crossref` "bare" result was never actually bare.
  Practical impact checked directly on `qwen3.5:4b`: 3/3 PASS with
  the contamination removed, unchanged — the verdict itself appears
  unaffected, but "bare" was inaccurate until this fix.

## Further reading

- `history.md` — full narrative: every phase, the grammar-legitimacy
  mistake and its correction in full detail, the Tier 2 generalist
  search, the Performance-phase compression work, and the
  `doc-synthesize` reliability finding.
- `docs/GRAMMAR-STEERING-PATTERNS.md` — when to reach for
  grammar-constrained decoding, backend capability notes, reusable
  structural grammar templates, and the legitimacy/bounded-free-text
  rules written from this session's mistakes.
- `models/qwen3.5-4b/`, `models/qwen3.5-2b/`, `models/qwen3.5-0.8b/` —
  smaller siblings; their own `doc-verbatim`/`doc-surgical`-shaped
  stable-FAIL findings predate this session's grammar-lever discovery
  and are next up for a grammar-based re-test.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:9b
  <role>`, with the env vars above).
- `task-overrides/` — active: `doc-script.md` (compressed),
  `doc-synthesize.md` (original wording, compression reverted).
  Retired, kept for reference: `doc-repair.md.pre-fix-archived`,
  `doc-surgical.md.superseded-by-grammar`,
  `doc-surgical.md.few-shot-attempt-unreliable`,
  `doc-surgical.md.lfm25-discipline-attempt-failed`.
- `grammars/` — `doc-verbatim.gbnf`, `doc-restructure.gbnf` (both
  structural, both validated). `doc-surgical.gbnf` does not exist —
  found invalid and discarded, see the Final report above.
