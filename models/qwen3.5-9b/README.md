# qwen3.5:9b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of
[`qwen3.5-4b`](../qwen3.5-4b/)/[`qwen3.5-2b`](../qwen3.5-2b/)/
[`qwen3.5-0.8b`](../qwen3.5-0.8b/) in the same model family. Runs on
this GPU (4GB VRAM) only via VRAM oversubscription — see Setup.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — Steering Tier 1 closed, Confirm next | 5/9 bare → 1 confirmed specialist fix, rest bare instability | Not assessed | [Documenter role: current status](#documenter-role-current-status-preliminary) |

## Documenter role: current status (preliminary)

**A thinking-enabled spot-check was run first** (2026-08-02, per
explicit user request, before any real baseline) to check whether the
larger 9B size alone resolves the runaway-thinking bug seen on
`qwen3.5:4b`, without disabling thinking. **Result: inconclusive on
the original question, but informative** — see `history.md` for the
full narrative. Summary: the 4 tasks that truncated on 4B
(`doc-verbatim`, `doc-adapt`, `doc-script`, `doc-repair`) were each
given up to 12 minutes, thinking enabled; all 4 timed out, all
cancelled in a tight, consistent 1915-2179 token band (~23-27% of the
8192 context) — never near the ceiling. A follow-up extended test on
`doc-verbatim` (up to 120 min) reached 5504 tokens (67% of context,
`truncated=0`, steady ~2.8 tok/s) before being killed by
`bench/dispatch.sh`'s own hardcoded 30-minute client-side timeout, not
by the model or the server. **No evidence of a genuinely stuck/looping
runaway was observed** — every draw was still progressing steadily
when cut off — but the test infrastructure (this GPU's severe
VRAM-oversubscription slowdown, ~12x slower than `qwen3.5:4b`) made it
impractical to let any draw run to full natural completion or the
8192-token ceiling within a reasonable time budget. **The original
question (does 9B alone fix runaway-thinking without disabling it) was
not conclusively answered** — treat as an open question, not "9B fixes
it."

**Given this, switched to `enable_thinking=false` for a normal
baseline run**, matching every other qwen3.5 config tested in this
project. **Bare baseline: 5/9 PASS, zero truncation** —
`reports/report-docs-20260802-173725.md`. Genuine 5/9, no hidden
empty-output failures.

**Steering Tier 1 closed after 3 runs.** `doc-synthesize`'s combined
fix (fenced-JSON-block reminder + `zod`-token reminder — 2
independently diagnosed idioms on the same task) worked cleanly.
`doc-verbatim`, `doc-surgical`, `doc-restructure` all reverted to bare
after real attempts (2, 1, 1 runs) — gated early once cross-model
evidence, especially `qwen3.5-4b`'s own exhaustive 4-attempt history
on the identical idioms, pointed to low expected value from further
iteration rather than mechanically exhausting the full 4-run budget on
each. `doc-adapt`, `doc-script`, `doc-repair`, `doc-summarize`,
`doc-crossref` were never steered — their pass/fail swings across all
3 Steering runs are pure bare-task instability. Per-task detail:

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-synthesize` | **PASS** (combined fix, confirmed on its latest draw) | [`task-overrides/doc-synthesize.md`](task-overrides/doc-synthesize.md) — JSON-block + `zod`-token reminders | n/a — Tier 2 gate skipped (specialist rate 56% < 60% threshold) |
| `doc-adapt` | Bare, flipped pass/fail across draws — real instability | bare | n/a |
| `doc-script` | Bare, flipped pass/fail across draws — real instability | bare | n/a |
| `doc-repair` | Bare, flipped pass/fail across draws — real instability | bare | n/a |
| `doc-summarize` | Bare, stable PASS across Steering draws so far | bare | n/a |
| `doc-crossref` | Bare, stable PASS across Steering draws so far | bare | n/a |
| `doc-verbatim` | 2 attempts, same idiom `qwen3.5-4b` never resolved in 4 — reverted | bare | n/a |
| `doc-surgical` | 1 attempt, matches `qwen3.5-4b`'s finding this lever doesn't help — reverted | bare | n/a |
| `doc-restructure` | 1 attempt, zero movement — reverted | bare | n/a |

**Tier 2 gate**: 5/9 ≈ 56% specialist rate, below the 60% threshold —
skipped per `AGENTS.md`'s autonomous rule. Next: Confirm.

## How to optimize (verify before trusting)

- `DISPATCH_ENABLE_THINKING=false` is required — see Setup.
  **Correction to an earlier assumption**: disabling thinking does NOT
  speed up per-token generation on this hardware (still ~3.1 tok/s,
  the VRAM-oversubscription bottleneck applies to every token
  regardless of content) — what it fixes is total answer *length*
  (hundreds of tokens instead of thousands+), which is what keeps a
  full docs-role run practical.
- For `doc-synthesize`-shaped tasks: a combined fenced-JSON-block +
  `zod`-token reminder works reliably — see
  [`task-overrides/doc-synthesize.md`](task-overrides/doc-synthesize.md).
- For `doc-verbatim`/`doc-restructure`-shaped tasks (structural
  blank-line/separator-row dropping) and `doc-surgical`-shaped tasks
  (line-wrap collapsing): instruction-based steering does not reliably
  fix these on this model — matches `qwen3.5-4b`'s own findings on the
  identical idioms. Don't spend further steering budget here.

## Setup

- Served by `llama-server-qwen3.5-9b.service` on `:8087` (Q4_K_M GGUF,
  CUDA), context `-c 8192`; run bench with `LLAMACPP_PORT=8087`.
- Downloaded 2026-08-02: `unsloth/Qwen3.5-9B-GGUF`,
  `Qwen3.5-9B-Q4_K_M.gguf`, 5.68GB.
- Whitelisted in `bench/dispatch.sh` as `qwen3.5:9b`.
- **VRAM oversubscription — a real, load-bearing setup fact, per
  `AGENTS.md`'s "every dispatch-level tweak must be documented"
  rule.** This GPU (GTX 1650, 4096MiB total VRAM) does not have enough
  free VRAM (~3.3GB free after other services stop) to hold this
  5.68GB model. `-ngl 99` (request all layers on GPU) was used anyway,
  per explicit user instruction accepting VRAM overflow. The service
  loads successfully (llama.cpp's own auto-fit heuristic logs `failed
  to fit params to free device memory... abort` at startup but
  proceeds regardless) via the NVIDIA driver's transparent VRAM
  oversubscription (paging between VRAM and system RAM over PCIe,
  handled by the GPU driver/DMA, not CPU-side code) — confirmed live:
  GPU utilization sits at 99% during generation while system-wide CPU
  stays low (~10-12%, one `llama-server` thread pegged near 100% for
  orchestration/sync, not compute) and `llama-server`'s virtual memory
  size is ~56.5GB (far exceeding both the 4GB VRAM and 8GB system RAM
  — the signature of driver-managed paging, not a normal allocation).
  **Practical consequence: ~12x slower generation** (~2.6-3.1 tok/s vs.
  `qwen3.5:4b`'s fully-GPU-resident ~37-40 tok/s) — this is a hardware
  ceiling, not something further tuning fixes.
- **Required dispatch overrides**: `DISPATCH_ENABLE_THINKING=false
  DISPATCH_TEMPERATURE=1.0 DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20
  DISPATCH_PRESENCE_PENALTY=2.0` — same non-thinking-mode sampling
  parameters as the other qwen3.5 configs (same model family).
  Full reproducible invocation for a docs-role test:
  ```
  DISPATCH_BACKEND=llamacpp LLAMACPP_PORT=8087 \
  DISPATCH_ENABLE_THINKING=false DISPATCH_TEMPERATURE=1.0 \
  DISPATCH_TOP_P=1.0 DISPATCH_TOP_K=20 DISPATCH_PRESENCE_PENALTY=2.0 \
  bash bench/report.sh qwen3.5:9b docs llamacpp 8087
  ```
- **`bench/dispatch.sh`'s hardcoded 30-minute (1800s) client-side
  `urlopen` timeout is shorter than an outer `timeout` wrapper may
  suggest** — discovered during the thinking-enabled spot-check, where
  an outer `timeout 7200` (2 hours) never got a chance to fire because
  the inner Python request timed out first at 30 minutes. Relevant if
  ever testing this model with thinking re-enabled or any other
  slow-generation scenario; not relevant with `enable_thinking=false`,
  where generation is fast enough this ceiling is never approached.

## Further reading

- `history.md` — full narrative of the thinking-enabled spot-check
  (the 4-task 12-minute-cap run, the extended 120-minute single-task
  test, and the CPU/GPU bottleneck investigation).
- `models/qwen3.5-4b/`, `models/qwen3.5-2b/`, `models/qwen3.5-0.8b/` —
  smaller siblings; check their `history.md`/`README.md` for idioms
  that might transfer once a real baseline exists here.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:9b
  <role>`, with the env vars above).
