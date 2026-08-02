# qwen3.5:0.8b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — Steering Tier 1 closed, 2 tasks passing (unconfirmed) | 1/9 → 2/9 specialist (unconfirmed, see per-task table) | Not assessed | [Documenter role: current status](#documenter-role-current-status-preliminary) |

## Documenter role: current status (preliminary)

**Bare baseline (with the mandatory `enable_thinking=false` +
non-thinking sampling params, no content-level steering), docs role: 1/9
PASS** — `reports/report-docs-20260802-114242.md` (the corrected,
verified-bare run; an earlier same-day run was contaminated with
leftover `lfm2.5-1.2b-thinking` steering on 6 of 9 tasks — see
`history.md`'s correction note. All 5 idioms below reproduced, several
more clearly, once re-tested against verified-bare prompts, so the
diagnosis itself held up). No truncation across all 9 tasks, confirming
the dispatch fix (see Setup) holds for a full role, not just one prompt.
`doc-summarize`/`doc-crossref` flipped PASS↔FAIL between the two runs
despite identical, always-bare SPECs — real per-draw instability on
both, independent of the contamination.

**Five idioms diagnosed** (n=1 per idiom, confirmed reproducing on a
second, independent draw for `doc-surgical`/`doc-adapt`/`doc-restructure`
— not yet a rate, see `history.md`):
1. **Idiom Q1 — structural-element dropping** (headings, table
   separator rows) — the most common failure this run (3 of 8 FAILs:
   `doc-verbatim`, `doc-repair`, `doc-restructure`), otherwise strong
   content fidelity. `doc-repair` performed both required repairs
   correctly and failed purely on this. **Highest-leverage first Phase
   2 target.**
2. **Idiom Q2 — instruction/prompt bleed** (`doc-surgical` copied the
   edit-instructions block itself into its output, past the `[DOC_END]`
   marker, on top of not applying any edits) — new, not seen on the
   other 2 models tested in this project.
3. **Idiom Q3 — substitution not applied** (`doc-adapt`, `doc-script`)
   — matches the already-documented idiom on both other models tested
   here; `deepseek-r1-1.5b` calls this a structural ceiling for its
   scale, not a prompting problem.
4. **Idiom Q4 — `doc-crossref`'s `describe_obfuscation_policy` drop,
   now confirmed independently on 3 of 3 models tested in this
   project** (`deepseek-r1-1.5b`, `lfm2.5-1.2b-thinking`, this model) —
   same exact fact dropped, same exact other fact kept, every time.
   Worth treating as a cross-model finding.
5. **`doc-synthesize`** shows the best partial bare performance of any
   model tested here so far (fenced JSON block present) — a relative
   strength, not just a FAIL.

**Research phase complete** (cross-model check + external research, both
required before Steering per `AGENTS.md`'s quality loop): no validated
fix exists anywhere in this project for Q1 or Q2; Q3 gets a negative
signal from `deepseek-r1-1.5b`'s own "structural limit, not a prompting
problem" verdict on the same task family — deprioritized accordingly.
Full findings: `history.md`'s "Research phase" section.

**Steering phase (Tier 1, specialist) closed after 4 runs: 2 tasks
PASS, 1 stable partial, 6 reverted to bare.** Full narrative in
`history.md`'s "Steering run 1" through "Steering runs 3-4" sections.
Per-task detail:

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-crossref` | **PASS** (needs Confirm re-verification — this task has documented per-draw flakiness) | [`task-overrides/doc-crossref.md`](task-overrides/doc-crossref.md) — exact-fact reminder for the historically-dropped tool name | n/a — Tier 2 not started |
| `doc-summarize` | **PASS on 1 of 2 draws** (needs Confirm re-verification) | [`task-overrides/doc-summarize.md`](task-overrides/doc-summarize.md) — sharpened single-fact reminder | n/a |
| `doc-script` | Stable partial — 1 forbidden token remains, reproduced identically across 3 draws | [`task-overrides/doc-script.md`](task-overrides/doc-script.md) | n/a |
| `doc-verbatim` | 4/4 runs used, contradictory results (best: 1-line defect; worst: severe) — **reverted to bare** | bare — no variant beat bare with confidence | n/a |
| `doc-surgical` | 3 attempts, noise-dominated (best/worst/worst) — **reverted to bare** | bare — no variant beat bare with confidence | n/a |
| `doc-repair` | Gated out (flat after run 1) | bare — steering didn't help | n/a |
| `doc-adapt` | Gated out (flat after run 1, matches R1's cross-model "structural limit" signal) | bare — steering didn't help | n/a |
| `doc-synthesize` | Gated out (regressed) | bare — steering hurt this task | n/a |
| `doc-restructure` | Gated out in run 1 (instruction conflicted with the task's actual job) | bare — steering hurt this task | n/a |

**Next: Confirm (re-verify the 2 PASSes) or Tier 2 (generalist search).**
Given the pattern (2 narrow specialist wins, 2 noise-dominated tasks
reverted to bare after real budget spent, several actively harmed by
steering), a working generalist for this role is not expected —
consistent with this project's now-standing finding that small models
don't generalize a single config across heterogeneous task shapes (see
root `README.md`).

## Potential helpers (documented, not yet integrated)

- **API-level `stop` sequences** (e.g. `"stop": ["[DOC_END]"]` on
  `/v1/chat/completions`) — targets Idiom Q2 (instruction bleed past a
  document-boundary marker) mechanically instead of relying on a
  textual instruction. Not yet wired into `dispatch.sh`: the existing
  override pattern (`DISPATCH_TEMPERATURE` etc.) is global-per-run, but
  this needs to be per-task (different tasks use different markers —
  `[DOC_END]` vs `[SCRIPT_END]`). Worth a dedicated dispatch-mechanism
  extension if Q2 doesn't respond to prompt-level fixes.

## Setup

- Served by `llama-server-qwen3.5-0.8b.service` on `:8083` (Q4_K_M
  GGUF, CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8083`.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:0.8b`.
- **Required dispatch overrides — do not test this model without these,
  per `AGENTS.md`'s "every dispatch-level tweak must be documented"
  rule:**
  - `DISPATCH_ENABLE_THINKING=false` — **mandatory, not optional.**
    Without it, this model enters an unterminated thinking loop on
    ordinary prompts: the warm-up ping during session setup
    (2026-08-02) hit `finish_reason=length` after 8177 completion
    tokens, 27,081 chars of `reasoning_content`, and an empty final
    answer — reproduces the pre-existing 3/3 runaway-reasoning finding
    already noted in `models/README.md`. Qwen3.5's own model card
    documents this directly: "Qwen3.5-0.8B is more prone to entering
    thinking loops... which may prevent it from terminating generation
    properly." This model family has **no in-prompt `/think`/`/no_think`
    switch** — `chat_template_kwargs.enable_thinking` (now wired into
    `dispatch.sh`, 2026-08-02) is the only control.
  - `DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20
    DISPATCH_PRESENCE_PENALTY=2.0` — the model card's recommended
    **non-thinking-mode, text-task** sampling parameters. `dispatch.sh`
    previously hardcoded `temperature=0.2` for every model; that's well
    outside this model's recommended 0.6-1.0 range and was never
    validated against it. Smoke-tested working (2026-08-02): a trivial
    prompt with all of the above returned a clean 10-token answer,
    `finish_reason=stop`, zero reasoning content.
  - Full reproducible invocation for a docs-role test:
    ```
    DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8083 \
    DISPATCH_ENABLE_THINKING=false DISPATCH_TEMPERATURE=1.0 \
    DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=2.0 \
    bash bench/report.sh qwen3.5:0.8b docs llamacpp 8083
    ```
    (`bench/report.sh`'s own `backend`/`port` positional args only cover
    `DISPATCH_BACKEND`/`LLAMACPP_PORT` — the sampling/thinking overrides
    must be exported separately, they aren't passed through by that
    script.)
- `bash bench/session-start.sh qwen3.5:0.8b llamacpp` stops other local
  hosters and starts this service exclusively — its own warm-up ping
  does NOT set the overrides above, so expect (and ignore) one
  runaway-reasoning warning during session start itself; that warning
  is not evidence about the model's real capability, only about not
  having disabled thinking yet.

## Further reading

- `history.md` — full per-task diagnostic breakdown of the baseline run
  and the runaway-thinking bug investigation.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:0.8b
  <role>`, with the env vars above).
