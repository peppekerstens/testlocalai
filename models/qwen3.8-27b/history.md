# qwen3.8-27b — steering history

First real testing session, 2026-08-28 (Claude Code session, prompted by
peppe: "assess/investigate qwen3.8-27b capabilities" for the
`local-llm-first` skill, which had only published benchmarks — Terminal-
Bench 2.1, SWE-bench Pro, GPQA Diamond — no real delegated-run evidence).

## Transport: not `bench/dispatch.sh`, and why

This model is reached through `ai-stack/litellm-router` (LiteLLM,
config-only mode) at `http://192.168.2.183:4000`, model alias
`local-first` — a remote OpenAI-compatible gateway with bearer auth, in
front of what the `local-llm-first` skill describes as a 27B Qwen
deployment. `bench/dispatch.sh` doesn't support this shape at all:
`DISPATCH_BACKEND` is hardcoded to `llamacpp` (localhost:8080) or
`ollama` (localhost:11434) only, and `ALLOWED_MODELS` is a fixed
allowlist that doesn't include this model tag.

Considered extending `dispatch.sh` with a third `openai` backend mode
(base URL + bearer token, matching the existing llamacpp/ollama branch
pattern) — legitimate, reusable, and not hard given the existing code
shape. **Didn't do it this session**: `dispatch.sh` and `pure-run.sh` are
precision-tested infrastructure with a documented history of real
incidents from agents editing them carelessly (see e.g. the
`lfm2.5-1.2b-thinking` shared-`SPEC.md`-contamination incident in that
model's own history.md) — a rushed edit inside an already very long,
unrelated session (this was a side investigation off a `obsidian-sync-
selfhost` network-segregation session) felt like the wrong place to take
that risk. Wrote a standalone runner instead
(`qwen_router_bench.py`, scratchpad-only, not committed to this repo)
that reuses this repo's real `SPEC.md` prompts and `verify.sh` scripts
unmodified — same task content, same verification, different transport
— so results are genuinely comparable, not lower-quality.

**If this model gets tested further**: adding the real `openai` backend
to `dispatch.sh` (small, additive, testable in isolation first against a
known-good task) is the right follow-up, not continuing to run a
parallel standalone script long-term.

## Phase 1 baseline: docs, tool-use, review, reason (bare, single draw)

Ran 4 of the 6 established roles bare (`temperature=0.2`, default
sampling, no `enable_thinking` override attempted — unlike `qwen3.5`,
no model-card evidence yet that this model family needs one).
Code-emitter skipped: those tasks use a build+test harness
(`tasks/code-csharp-*/harness/`), not a standalone `verify.sh` —
replicating that correctly standalone (matching `bench.sh`'s exact
compile/test invocation) was more risk than this pass's scope
warranted; flagged as a real gap, not silently skipped. Extract also not
attempted this pass (time-boxed, not a negative finding).

**Results**: docs 9/9, tool-use 6/6, review 6/6, reason 6/9. Full
per-task detail and the three reasoning failures (quoted, classified) in
`README.md` — not duplicating here.

**Every prior model in this repo needed steering to get a decent
documenter score; this one didn't need any for a first pass.** Worth
being honest about the likely reason: 27B is a genuinely different size
class from everything else tested here (0.8B–9B) — this isn't evidence
that this repo's steering methodology stops mattering at scale, just
that *this specific 9-task documenter suite* turned out to be within
this model's unsteered capability. Tool-use and review are new roles for
any small/local model in this repo (see `models/README.md`'s prior "no
real small-model run yet" line for tool-use) — first data point, not
confirmed-stable.

## What this session did NOT do (be honest about the gap)

- **No Research phase** (cross-model idiom check, external model-card
  search) — nothing failed badly enough yet to warrant it.
- **No Steering attempted on the 3 reasoning failures.** All three read
  as plausibly fixable with a targeted reminder (config-validity: "don't
  invent fields not in the source doc"; multihop: "name the specific
  field/path, not just the mechanism"; tradeoff: "cover both sides
  explicitly") — untested hypotheses, not validated fixes. Don't copy
  these into a task-override without actually running them.
- **No Confirm-phase stability check** — every number above is n=1.
  A second bare draw could land differently, especially on the reasoner
  role's near-misses (multihop and tradeoff both got most of the answer
  right — plausibly flaky rather than a hard ceiling).
- **Code-emitter and extract roles untested.**
- **`data/leaderboard.json`/`docs/leaderboard.html` not updated** —
  `AGENTS.md`'s "after a test run, persist it" rule calls for this;
  skipped to keep this session's scope bounded, flagged instead of
  silently done. `models/README.md`'s index rows *are* updated (see that
  file's diff) — just not the generated dashboard mirror.

## Follow-up, if this model gets more investment

1. Real `dispatch.sh` `openai` backend (see above) before any further
   runs, so this stops being a parallel script.
2. Confirm-phase redraws on the 3 reasoning failures specifically —
   cheapest way to find out if they're real ceiling or single-draw noise.
3. Code-emitter role, once the harness question is resolved.
4. `data/leaderboard.json` + regenerate `docs/leaderboard.html`.

## Real coding-delegation evidence, 2026-08-28 (not via this repo's own dispatch path)

Separate from the Phase 1 baseline above: this exact model, reached through
the same `local-first` router but via `opencode run` (not `dispatch.sh` —
still no `openai` backend, see follow-up #1), was delegated 8 real files
while scaffolding the `matrix-selfhost` repo — shell-script template
adaptation and a Docker Compose file, not the doc/tool/review/reason
suite above. Real evidence, not synthetic: 6 of 8 good (2 needed fixes
that were arguably spec gaps more than model failures — see the
`local-llm-first` skill's delegate table for the full writeup, not
duplicated here), plus 2 genuine hangs on scripts whose *content*
described SSH/remote-exec commands (a harness-level tool-permission
stall, not a model-quality issue — confirmed via direct router pings
showing the backend was idle both times).

This prompted `tasks/adapt-bash-simple/`, `adapt-bash-complex/`, and
`adapt-bash-remote-content/` (see `docs/adapt-role-proposal.md`) — real
tasks grounded in this incident, not yet dispatched against this or any
other model. A real Phase 1 run against those three, through a proper
`dispatch.sh` `openai` backend once built, would be the natural way to
turn this anecdotal evidence into a real baseline number.
