# qwen3.5:0.8b — steering profile

**Status: quality loop starting — Phase 1 (reference baseline) not run
yet.** Whitelisted, service wired, dispatch-level fix applied; no task
suite has been run against it yet.

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role.

## Current status

Not yet tested. See "Setup" below for what had to be fixed before a
baseline run would produce any signal at all.

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

- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:0.8b
  <role>`, with the env vars above).
