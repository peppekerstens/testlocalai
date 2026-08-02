# qwen3.5:9b — steering profile

**Role: documenter** (docs role, `tasks/doc-*`). Not yet tested against
any other role. Larger sibling of
[`qwen3.5-4b`](../qwen3.5-4b/)/[`qwen3.5-2b`](../qwen3.5-2b/)/
[`qwen3.5-0.8b`](../qwen3.5-0.8b/) in the same model family. Runs on
this GPU (4GB VRAM) only via VRAM oversubscription — see Setup.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | ⚠️ Mixed — quality loop closed 2026-08-02, 4 stable-pass task shapes (best qwen3.5-family result), 2 stable-fail, 3 genuinely unstable | 5/9 bare (zero truncation) → 4/9 stable pass, ~59% average per draw | Not comparable overall; best qwen3.5-family content reliability result of the whole session | [Documenter role: final report](#documenter-role-final-report-closed-2026-08-02) |

## Documenter role: final report (closed 2026-08-02)

**Why stopped here.** Full quality loop: a thinking-enabled spot-check
first (per explicit user request, to check whether 9B alone resolves
the runaway-thinking bug seen on `qwen3.5:4b` without disabling
thinking — result inconclusive, see `history.md`), then
`enable_thinking=false` Phase 1 baseline, Research (cross-model check
against `qwen3.5-4b`), Steering Tier 1 (3 tasks attempted, 1 fixed), an
autonomous Tier 2 gate (56% < 60%, skipped), and a 3-run Confirm.

**Usability score without optimizations**: 5/9 (56%) PASS bare, under
`enable_thinking=false` — genuine 5/9, zero truncation, no hidden
empty-output failures (unlike `qwen3.5:4b`'s thinking-enabled bare
baseline, which looked similar on paper but actually had 44% empty
output from context-ceiling truncation).

**Usability score with optimizations** (Confirm-verified across 3
draws): **4 tasks reliably pass** (`doc-adapt`, `doc-synthesize` — needs
its steering override, `doc-summarize`, `doc-crossref` — all 3/3),
**2 tasks reliably fail** (`doc-verbatim`, `doc-surgical` — confirmed
unsuitable, matching their Steering-phase gate decisions exactly), and
**3 tasks are genuinely unstable** (`doc-script` 1/3, `doc-repair` 2/3,
`doc-restructure` 1/3 — none of these were ever steered, so the
instability is the model's own reliability ceiling on this role, not a
fixable prompt gap). Average 16/27 ≈ 59% pass rate across the 3 draws —
but that average is misleading on its own: it's a 4/2/3 stable-pass/
stable-fail/unstable split, not "roughly 6 in 9 always pass." Zero
truncation across every Confirm draw — `enable_thinking=false` holds
completely.

**Comparison against a mainstream frontier LLM**: not comparable
overall — a model like Claude Haiku 4.5 would be expected to pass
close to all 9 tasks reliably, not show a 4/2/3 stable-pass/stable-
fail/unstable split. **This is the best qwen3.5-family content
reliability result of the whole session** (4 stable-pass tasks vs.
4B's 3, 2B's 1, 0.8B's ~2-at-67%-each), all near-zero cost/latency
versus a hosted frontier call once the ~12x VRAM-oversubscription
slowdown is accepted — but the model cannot be trusted unsupervised
even on task shapes it sometimes gets right, unlike a frontier model's
default reliability.

**Final verdict: usable with mandatory `enable_thinking=false` and
mandatory human review on every output — not a "sometimes skip
review" model.** Bigger did help here relative to `qwen3.5:4b` (4
stable-pass vs. 3), but the improvement is incremental, not
categorical — 3 tasks remain genuinely unstable regardless of size. A
notable cross-model finding: the same 2 structural idioms
(`doc-verbatim`'s blank-line handling, `doc-surgical`'s line-wrap
collapsing) are now confirmed unresolved at 2 different model sizes
(4B and 9B) via real, varied steering attempts at each — this is a
stable cross-model finding, not a fluke of either individual model.

**Per-task detail**:

| Task | Specialist result | Specialist config | Generalist result |
|---|---|---|---|
| `doc-synthesize` | **Stable PASS, 3/3 Confirm draws** (combined fix) | [`task-overrides/doc-synthesize.md`](task-overrides/doc-synthesize.md) — JSON-block + `zod`-token reminders | n/a — Tier 2 gate skipped (specialist rate 56% < 60% threshold) |
| `doc-adapt` | **Stable PASS, 3/3 Confirm draws** (bare, never steered) | bare | n/a |
| `doc-summarize` | **Stable PASS, 3/3 Confirm draws** (bare, never steered) | bare | n/a |
| `doc-crossref` | **Stable PASS, 3/3 Confirm draws** (bare, never steered) | bare | n/a |
| `doc-verbatim` | **Stable FAIL, 0/3** — 2 attempts, same idiom `qwen3.5-4b` never resolved in 4 — reverted | bare | n/a |
| `doc-surgical` | **Stable FAIL, 0/3** — 1 attempt, matches `qwen3.5-4b`'s finding this lever doesn't help — reverted | bare | n/a |
| `doc-script` | Unstable, 1/3 Confirm draws (bare, never steered) | bare | n/a |
| `doc-repair` | Unstable, 2/3 Confirm draws (bare, never steered) | bare | n/a |
| `doc-restructure` | Unstable, 1/3 Confirm draws — 1 attempt during Steering, zero movement, reverted | bare | n/a |

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
- For `doc-verbatim`-shaped tasks (blank-line dropping) and
  `doc-surgical`-shaped tasks (line-wrap collapsing): instruction-based
  steering does not reliably fix these on this model — matches
  `qwen3.5-4b`'s own findings on the identical idioms across 2
  different model sizes now. Don't spend further steering budget here.
- For tasks with genuine per-draw instability (`doc-script`,
  `doc-repair`, `doc-restructure`-shaped tasks): no known fix — none
  were moved by the one steering attempt tried (`doc-restructure`
  only), because the instability appears independent of prompt
  content. Always run multiple draws before trusting any single result
  on these task shapes.

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

- `history.md` — full narrative, including the thinking-enabled
  spot-check (the 4-task 12-minute-cap run, the extended 120-minute
  single-task test, and the CPU/GPU bottleneck investigation), the
  full Steering-phase diagnostic detail, and the 3-run Confirm.
- `models/qwen3.5-4b/`, `models/qwen3.5-2b/`, `models/qwen3.5-0.8b/` —
  smaller siblings; `doc-verbatim`/`doc-surgical`'s structural idioms
  are now confirmed unresolved at both 4B and 9B — see each one's
  `history.md`/`README.md`.
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence (`bash bench/report.sh qwen3.5:9b
  <role>`, with the env vars above).
- `task-overrides/` — the exact, literal prompt dispatched for
  `doc-synthesize` with task-specific steering — auto-resolved by
  `bench/pure-run.sh`, never a direct edit to the shared
  `tasks/doc-synthesize/SPEC.md` (see `AGENTS.md`'s "Per-model doc-task
  steering" rule).
