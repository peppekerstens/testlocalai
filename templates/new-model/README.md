# New model — onboarding recipe

Goal: build a per-model steering profile (`models/<model>/`) before trusting
the model on real tasks. Small models each have their own failure idioms —
the recipe below surfaces them cheaply.

## Steps

1. **Whitelist.** Add `<model>` to `ALLOWED_MODELS` in `bench/dispatch.sh`.
   That list is the only hard gate; nothing else needs wiring.
2. **Probe the domain — only if the model needs grounding it doesn't
   already have.** If the model's role faces an SDK/API surface it doesn't
   know (a code-emitter role against an unfamiliar library), run a tiny
   throwaway probe first (see `tasks/csharp/probe/` for a working example).
   Record what compiles and what the model gets wrong — this is the seed of
   the steering cheatsheet. **Skip this step** when the model's role already
   works from the project's own existing docs as ground truth (a
   documenter/reasoner role reproducing or reasoning about real doc
   fixtures) — there's nothing to probe first. This is exactly why
   qwen2.5-coder-1.5b (code-emitter-csharp, unfamiliar ConnectWise/MCP SDK)
   went through this step and deepseek-r1-1.5b (documenter/reasoner) didn't.
3. **Probe the model** (skip if step 2 was skipped). Send the probe + a
   "write a cheatsheet for me" prompt through `bench/dispatch.sh` (text
   mode). Fix + re-run once. This tells you how the model talks about the
   domain before you write real SPECs. Keep the round-trips —
   `models/<model>/prompts/`, `/outputs/`, `/logs/` — but only as scratch:
   once the cheatsheet/probe is finished and promoted into its durable home
   (`tasks/<project>/`), delete the raw trail rather than leaving it as a
   stale duplicate (see root README's "Two kinds of history").
4. **Bench it.** `BENCH_MODEL=<model> ./.orchestration/bench/bench.sh
   code-<name> <round> <FileName>.cs` (or `bench/report.sh <model> <role>`
   for a doc-kind role track). Use the same round label as other models
   so reports are comparable. This automatically writes to
   `models/<model>/reports/` — see `AGENTS.md`'s "after a test run"
   rule: the run isn't done until it's on disk, not just seen in your
   terminal.
5. **Steer.** Inspect the failed outputs; fix SPECs/rules; re-run. Keep
   `models/<model>/README.md` current-state-only — a verdict/status
   summary and "how to optimize" instructions (e.g. "qwen2.5-coder:1.5b
   drifts to idiomatic-wrong code unless the SPEC shows a complete
   verbatim shape"). Put the actual round-by-round narrative (what you
   tried, what happened, in order) in `models/<model>/history.md`
   instead — see `AGENTS.md`'s README-shape rule.
6. **Learn from history.** The previous model's steering is your
   baseline; check its `history.md` for what carried over and what
   didn't, and add the new model to `models/README.md`'s index once it
   has a real result to report.

## Backends

- `DISPATCH_BACKEND=llamacpp` (default) — localhost:8080, `/v1/chat/completions`
- `DISPATCH_BACKEND=ollama` — localhost:11434, `/api/generate`.
  (writes a token sidecar `out-<round>.txt.tokens.json`).

## Verify before you trust

A single 6/6 round is one draw. Re-run the trickiest task a few times
before trusting the prompt — this has bitten every model steered in this
project so far (see `models/qwen2.5-coder-1.5b/history.md` for a worked
example of a rate that looked stable at n=3 and wasn't, and
`bench/report.sh`'s repeated-run comparison for a way to check
reproducibility mechanically instead of by eye).
