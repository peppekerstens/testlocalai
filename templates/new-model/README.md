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
   throwaway probe first — a scratch project you build and verify yourself
   (compile it, run it, check real output) rather than trust unverified.
   Record what compiles and what the model gets wrong — this is the seed of
   the steering cheatsheet. **Skip this step** when the model's role already
   works from the project's own existing docs as ground truth (a
   documenter/reasoner role reproducing or reasoning about real doc
   fixtures) — there's nothing to probe first. This is exactly why
   qwen2.5-coder-1.5b (code-emitter-csharp, unfamiliar ConnectWise/MCP SDK)
   went through this step and deepseek-r1-1.5b (documenter/reasoner) didn't.
   (The original worked example, `tasks/csharp/probe/`, was retired
   2026-08-03 once its findings were folded into a real task,
   `tasks/code-mcpidentity/` — read that task's `SPEC.md` for what a
   probe-derived task looks like once it's done.)
3. **Probe the model** (skip if step 2 was skipped). Send the probe + a
   "write a cheatsheet for me" prompt through `bench/dispatch.sh` (text
   mode). Fix + re-run once. This tells you how the model talks about the
   domain before you write real SPECs. Keep the round-trips —
   `models/<model>/prompts/`, `/outputs/`, `/logs/` — but only as scratch:
   once the cheatsheet/probe is finished, fold its verified findings
   directly into the real task's `SPEC.md`/behavior contract (there is no
   separate intermediate reference-doc location anymore — see root
   README's Layout table), then delete the raw trail rather than leaving
   it as a stale duplicate (see root README's "Two kinds of history"). If
   a finding doesn't map cleanly into a task the harness can check (e.g. a
   hosting/routing default, not a unit-testable behavior), it's fine for
   it to not survive anywhere durable — don't invent a task just to store
   a fact; re-derive it from the SDK/docs again if it's ever needed.
4. **Bench it.** `BENCH_MODEL=<model> ./.orchestration/bench/bench.sh
   code-<name> <round> <FileName>.cs` (or `bench/report.sh <model> <role>`
   for a doc-kind role track). Use the same round label as other models
   so reports are comparable. This automatically writes to
   `models/<model>/reports/` — see `AGENTS.md`'s "after a test run"
   rule: the run isn't done until it's on disk, not just seen in your
   terminal.
5. **Steer.** Inspect the failed outputs; fix SPECs/rules; re-run. Copy
   `MODEL-README-SCAFFOLD.md` (this directory) to `models/<model>/
   README.md` for a new model, or use it as the structure check for an
   existing one — Overview table up top, one current-state-only section
   per role, "how to optimize" instructions. Put the actual
   round-by-round narrative (what you tried, what happened, in order) in
   `models/<model>/history.md` instead, every time, not just at the end
   — see `AGENTS.md`'s README-shape rule and the scaffold's own inline
   comments for exactly what does and doesn't belong.
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
