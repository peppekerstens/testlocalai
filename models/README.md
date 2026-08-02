# Models — index

Every local LLM tested in this project, and which role(s) it's actually
been tested against. One row per model+role combination — most models
only cover one or two roles, so a full model×role matrix would be mostly
empty cells. See `../README.md`'s "Roles" table for what each role tests
in general; this table is model-specific results.

| Model | Role | Status | Evidence |
|---|---|---|---|
| [`qwen2.5-coder-1.5b`](qwen2.5-coder-1.5b/) | code-emitter | ✅ Established — two validated recipes (original 6 / new 6 task families) | `qwen2.5-coder-1.5b/README.md` |
| [`deepseek-r1-1.5b`](deepseek-r1-1.5b/) | documenter | ⚠️ Mixed — suitable for a defined task subset, not general-purpose (see its Verdict table) | `deepseek-r1-1.5b/README.md` |
| [`deepseek-r1-1.5b`](deepseek-r1-1.5b/) | reasoner | ⚠️ Mixed — 1/3 task types solid, rest need steering or are past this model's ceiling | `deepseek-r1-1.5b/README.md` |
| [`lfm2.5-1.2b-thinking`](lfm2.5-1.2b-thinking/) | documenter | ❌ Not suitable — quality loop closed 2026-08-02, 1/9 bare and with optimizations (see Final report) | `lfm2.5-1.2b-thinking/README.md` |
| [`lfm2.5-1.2b-thinking`](lfm2.5-1.2b-thinking/) | reasoner | 🔬 Preliminary — one bare baseline + one steering pass, work paused mid-iteration (not part of the closed docs-role loop) | `lfm2.5-1.2b-thinking/README.md` |
| [`qwen3.5-0.8b`](qwen3.5-0.8b/) | documenter | ⚠️ Mixed — quality loop closed 2026-08-02, 2 of 9 task shapes usable (~67% reliable) with per-task steering, rest unsuitable | `qwen3.5-0.8b/README.md` |
| [`qwen3.5-0.8b-bf16`](qwen3.5-0.8b-bf16/) | documenter | ⚠️ Mixed — quality loop closed 2026-08-02, same 2 of 9 task shapes usable as Q4_K_M (~67% reliable); precision doesn't justify the extra size | `qwen3.5-0.8b-bf16/README.md` |
| [`qwen3.5-2b`](qwen3.5-2b/) | documenter | 🔬 Preliminary — bare baseline 2/9 (best of the qwen3.5 family so far), Steering starting | `qwen3.5-2b/README.md` |
| [`lfm2.5-vl-450m`](lfm2.5-vl-450m/) | visual | 🚧 Scaffold only — model not downloaded, role not wired up | `lfm2.5-vl-450m/README.md` |
| — (no model tested yet) | tool-use | Task suite built + blind-subagent-validated only (`claude-sonnet-5`) — no real small-model run yet | `claude-sonnet-5/README.md` "Tool-use extension" |
| — (no model tested yet) | extract | Task suite built + blind-subagent-validated only — no real small-model run yet | `claude-sonnet-5/README.md` "Extract extension" |
| — (no model tested yet) | review | Task suite built + blind-subagent-validated only — no real small-model run yet | `claude-sonnet-5/README.md` "Review extension" |

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
