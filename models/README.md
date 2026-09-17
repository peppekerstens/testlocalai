# Models — index

Every local LLM tested in this project, and which role(s) it's actually
been tested against. One row per model+role combination — most models
only cover one or two roles, so a full model×role matrix would be mostly
empty cells. See `../README.md`'s "Roles" table for what each role tests
in general; this table is model-specific results.

A visual rendering of this same information (bare vs. steered pass rate
per row) is `../docs/leaderboard.html`, generated from
`../data/leaderboard.json` — that file is a hand-maintained mirror of
this table's rows, not derived from it automatically. Adding/updating a
row here means also updating `data/leaderboard.json` and re-running
`python3 bench/leaderboard.py` (see `AGENTS.md`'s "After a test run,
persist it" rule) — this index alone does not update the dashboard.

| Model | Role | Status | Evidence |
|---|---|---|---|
| [`qwen2.5-coder-1.5b`](qwen2.5-coder-1.5b/) | code-emitter | ✅ Established — two validated recipes (original 6 / new 6 task families) | `qwen2.5-coder-1.5b/README.md` |
| [`deepseek-r1-1.5b`](deepseek-r1-1.5b/) | documenter | ⚠️ Mixed — suitable for a defined task subset, not general-purpose (see its Verdict table) | `deepseek-r1-1.5b/README.md` |
| [`deepseek-r1-1.5b`](deepseek-r1-1.5b/) | reasoner | ⚠️ Mixed — 1/3 task types solid, rest need steering or are past this model's ceiling | `deepseek-r1-1.5b/README.md` |
| [`lfm2.5-1.2b-thinking`](lfm2.5-1.2b-thinking/) | documenter | ❌ Not suitable — quality loop closed 2026-08-02, 1/9 bare and with optimizations (see Final report) | `lfm2.5-1.2b-thinking/README.md` |
| [`lfm2.5-1.2b-thinking`](lfm2.5-1.2b-thinking/) | reasoner | 🔬 Preliminary — one bare baseline + one steering pass, work paused mid-iteration (not part of the closed docs-role loop) | `lfm2.5-1.2b-thinking/README.md` |
| [`qwen3.5-0.8b`](qwen3.5-0.8b/) | documenter | ⚠️ Mixed — quality loop closed 2026-08-02, 2 of 9 task shapes usable (~67% reliable) with per-task steering, rest unsuitable | `qwen3.5-0.8b/README.md` |
| [`qwen3.5-0.8b-bf16`](qwen3.5-0.8b-bf16/) | documenter | ⚠️ Mixed — quality loop closed 2026-08-02, same 2 of 9 task shapes usable as Q4_K_M (~67% reliable); precision doesn't justify the extra size | `qwen3.5-0.8b-bf16/README.md` |
| [`qwen3.5-2b`](qwen3.5-2b/) | documenter | ⚠️ Mixed — quality loop closed 2026-08-02, `doc-crossref` fully reliable (3/3, strongest qwen3.5 result), rest unsuitable | `qwen3.5-2b/README.md` |
| [`qwen3.5-4b`](qwen3.5-4b/) | documenter | ⚠️ Mixed — quality loop closed 2026-08-03, 4 stable-PASS task shapes (2 via grammar transferred from `qwen3.5-9b`), 4 genuinely unstable, 1 unsuitable (cross-model confirmed) | `qwen3.5-4b/README.md` |
| [`qwen3.5-9b`](qwen3.5-9b/) | documenter | ⚠️ Mixed — quality loop closed 2026-08-03, 8 of 9 task shapes stable (3/3 Confirm, ~89% of an assumed frontier ceiling), `doc-surgical` genuinely unresolved (best qwen3.5-family result of the session) | `qwen3.5-9b/README.md` |
| [`qwen3.5-4b-gsq`](qwen3.5-4b-gsq/) | documenter | 🔬 Quality loop in progress, started 2026-09-13 | `qwen3.5-4b-gsq/README.md` |
| [`qwen3.8-27b`](qwen3.8-27b/) | documenter | 🔬 Phase 1 only — 9/9 bare, single draw, no steering needed (unlike every smaller model above) | `qwen3.8-27b/README.md` |
| [`qwen3.8-27b`](qwen3.8-27b/) | tool-use | 🔬 Phase 1 only — 6/6 bare, single draw. First real small-model result against this suite | `qwen3.8-27b/README.md` |
| [`qwen3.8-27b`](qwen3.8-27b/) | review | 🔬 Phase 1 only — 6/6 bare, single draw | `qwen3.8-27b/README.md` |
| [`qwen3.8-27b`](qwen3.8-27b/) | reasoner | ⚠️ Mixed, Phase 1 only — 6/9 bare, single draw; all 3 failures partial/imprecise, not wrong-headed (see README) | `qwen3.8-27b/README.md` |
| [`minicpm5-2b`](minicpm5-2b/) | tool-use | ✅ Confirmed 2026-09-17 — 10/10 in all 3 Confirm draws, `tool-error` fixed by a per-task override | `minicpm5-2b/README.md` |
| [`minicpm5-2b`](minicpm5-2b/) | extract | ⚠️ Flaky 2026-09-17 — Confirm 9/10/9, no confirmed steering gain (`extract-optional` unstable) | `minicpm5-2b/README.md` |
| [`minicpm5-2b`](minicpm5-2b/) | review | ⚠️ Flaky 2026-09-17 — Confirm 7/8/6, no confirmed steering gain, `review-swallow` and `review-multi` always fail | `minicpm5-2b/README.md` |
| [`minicpm5-2b`](minicpm5-2b/) | code-emitter | ⚠️ Flaky 2026-09-17 — Confirm 11/9/10 of 14, no steering gain, 3 C# tasks always fail | `minicpm5-2b/README.md` |
| [`minicpm5-2b`](minicpm5-2b/) | reasoner | ⚠️ Flaky 2026-09-17 — Confirm 6/6/5, no confirmed steering gain, weakest role | `minicpm5-2b/README.md` |
| [`minicpm5-2b`](minicpm5-2b/) | documenter | ⚠️ Flaky 2026-09-17 — Confirm 7/6/6, no confirmed steering gain, 3 tasks always fail | `minicpm5-2b/README.md` |
| [`lfm2.5-vl-450m`](lfm2.5-vl-450m/) | visual | 🚧 Scaffold only — model not downloaded, role not wired up | `lfm2.5-vl-450m/README.md` |
| — (no model tested yet) | extract | Task suite built + blind-subagent-validated only — no real small-model run yet | `claude-sonnet-5/README.md` "Extract extension" |

## Reference baseline (not a steering target)

[`claude-sonnet-5`](claude-sonnet-5/) — the orchestrator's own model,
used to validate that every task suite is actually achievable before any
small local model is tested against it (isolated subagent, zero tool
calls, `verify.sh` as sole judge — never shown ground truth). Not
"steered" or "optimized" the way the models above are; its README is a
validation ledger, not a profile to keep current-state-trimmed the same
way.

## Downloaded, not yet profiled

Real small-model smoke tests were run against these during initial setup
(context-window/`enable_thinking`-toggle probes — see
`deepseek-r1-1.5b/history.md` and the qwen3.5 investigation), but no task
suite has been run against them yet, so there's no role/status to report:

- `lfm2.5:1.2b-thinking-bf16` variants — downloaded 2026-08-02,
  whitelisted in `bench/dispatch.sh`, systemd service wired. Same known
  runaway-thinking finding as `qwen3.5` below may apply — not yet
  re-verified per-config.
- `qwen3.5:0.8b`, `qwen3.5:0.8b-bf16`, and `qwen3.5-2b` now have real
  rows above — see each one's own README Setup section for the
  required dispatch overrides (`enable_thinking=false` is mandatory,
  not optional, though not 100% deterministic per draw on `qwen3.5-2b`
  specifically — see its README) before testing it further.

## Adding a model here

See root `README.md`'s "Adding a new model". Once a model has at least
one real task-suite run against a role, give it a row above (or its own
row per role tested) and create `models/<model>/README.md` following the
shape of an existing entry: current status up top, "how to optimize"
instructions, link to `history.md` (once there's enough narrative to
warrant separating it out) and `reports/`.
