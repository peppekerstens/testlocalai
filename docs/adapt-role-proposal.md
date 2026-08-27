# Proposed role: `adapt` (not yet added to the Roles table)

Three new tasks, `tasks/adapt-bash-simple/`, `tasks/adapt-bash-complex/`,
and `tasks/adapt-bash-remote-content/`, added 2026-08-28 — grounded in
real work, not invented: they mirror the actual shape of shell-script
template-adaptation delegated to `opencode`/local-first (qwen3.8-27b)
that same day while scaffolding the `matrix-selfhost` repo (see that
model's `history.md` "Real Coding-Delegation Evidence" section for the
source incidents).

## `adapt-bash-remote-content` — an honest partial reproduction, not a full one

Grounded in a real, worse incident the same day: delegating a script
whose *content* described SSH/remote-exec commands hung indefinitely
twice — confirmed (via a direct router ping returning in <0.4s both
times) as a harness-level tool-permission stall, not a text-generation
problem. `dispatch.sh` is a raw completion call with no tool-use loop, so
it **cannot reproduce that hang** — there's no tool-execution path to
get stuck in. This task instead checks the one text-generation-level
signal available to it: does the model stay in scope and just author the
adapted content, or does its response text start narrating an execution
attempt ("let me run this to check..."). That's a real but partial
proxy for the underlying issue, not the bug itself — said explicitly in
the task's own header comment so a future reader doesn't overclaim what
a PASS here actually means.

## Why not just `code-emitter`

`code-emitter` (`code-csharp-*`, `code-python-*`) is "generate correct,
compiling code from a spec," graded by a build+test harness
(`harness/src/`, `harness/tests/`). These new tasks are a different skill:
faithfully adapt an *existing, working* file per an exact list of deltas,
changing nothing else — closer in spirit to `review`'s "opposite skill
direction from code-emitter" framing than to code-emitter itself. No
build/test harness needed — `bash -n` + grep-based checks on the required
substitutions, same verification style as `doc-*`/`review-*`/`tool-*`.

## Why not added to the Roles table directly

`README.md`'s own stated principle: roles are "grounded in real usage-
pattern research... not invented." Two tasks from one real incident is a
real data point, but not yet the kind of broader grounding the existing
roles cite. Left as a proposal, not a unilateral addition — a real
decision for peppe, not mine to make on this repo.

## `adapt-bash-complex` — a deliberate trap, grounded in a real idiom

Mirrors the actual mistake found in the source incident: a literal
`500→600` substitution left a comment asserting something now-false
("matching the live worker VM 600" — this VM was never live). The task
gives the model the fact it needs to catch this (an explicit "this is
brand-new, never been live" line) without instructing the fix directly —
same shape as the real spec gap that produced the original idiom.
`VERDICT` is the 4 literal substitutions + syntax only (crisply
gradable); whether the stale-claim implication got caught is reported as
a separate, non-blocking idiom signal in `verify.sh`'s output — the
task's strict OUTPUT FORMAT (code only) gives the model no clean channel
to flag the issue instead of just fixing it, so this is deliberately not
a hard pass/fail criterion.

Both `verify.sh` scripts self-tested against hand-crafted correct/wrong/
literal-substitution answers before being considered done — not just
trusted on first write.

## Not yet done

No model has actually been dispatched against these two tasks yet — they
exist and are verified to grade correctly, but that's Phase 0 (task
construction), not Phase 1 (a real baseline run). Natural next step:
`bash bench/pure-run.sh qwen3.8-27b --test adapt` once (or if) that
`--test` filter is wired up in `pure-run.sh` for the new prefix (it
currently isn't — see `AGENTS.md`'s "Scoping language is literal" rule,
a new suite needs the filter added, not a "run everything" fallback).
