# Local LLM Best Practices — cross-model guidance

General practices that apply regardless of which specific model you're
steering. For one-time environment/machine setup, see `SETUP.md`. For a
specific model's own steering profile (what works for *that* model,
verdicts, role optimization), see `models/<model>/README.md` — this file
does not duplicate that; it's genuinely cross-cutting only.

## 1. What generalizes across models (and what doesn't)

- **Steering beats hardware.** Every model tested in this project went
  from a low or zero baseline pass rate to a measurably better one purely
  by changing the prompt — no model swap, no fine-tuning. See each
  model's own README for its specific numbers.
- **Roles are model-specific, and so is the steering that works for
  them.** A rule earned by one model on one task family is never assumed
  to generalize — not to a different task family for the *same* model
  (qwen's `csharp-rules.md` actively hurt its own new 6 tasks), and
  especially not to a different model. See `models/<model>/rules/` — per
  model, never shared.
- **A single passing round is one draw, not a verdict.** Every model
  profiled here has at least one case where an early small sample looked
  conclusive and a larger one corrected it (qwen's task4 ~62% reliability
  behind a single 6/6 round; deepseek-r1's no-think rate correcting from
  an apparent 3/3 win to 4/8 on a larger sample). Re-run a tricky task
  several times before trusting a prompt.
- **Always verify — never trust a claimed success.** Score by an actual
  build+test or a content-fidelity check (`verify.sh`), never by reading
  the model's own account of what it did.
- **Watch for context/token exhaustion before blaming model quality.** A
  0-byte or truncated answer can be genuine context exhaustion mid-
  reasoning, not a content failure — `dispatch.sh` surfaces
  `finish_reason=length` / `TRUNCATED-BY-CONTEXT-LIMIT` automatically now;
  check it before concluding a model "can't do" a task (see
  `models/deepseek-r1-1.5b/history.md` for the investigation that found
  this being silently mislabeled).

## 2. Token accounting

Prompt/output token counts are essential for steering experiments and for
budgeting a subagent's context window.

- **llama.cpp backend:** `usage.prompt_tokens` / `usage.completion_tokens`
  in the `/v1/chat/completions` response. `dispatch.sh` writes a sidecar
  `<output>.tokens.json` (`{"prompt_tokens":N,"completion_tokens":M,
  "finish_reason":...,"reasoning_content_chars":...}`).
- **Ollama (restricted build):** no `/api/tokenize`. Workaround: hit
  `/api/generate` with `num_predict:1` and read `prompt_eval_count`
  (~0.6s, "tokenize-only" call).
- Reports show `- Tokens: <P> prompt / <C> completion` — see
  `bench/report.sh` for the enriched, per-run version with deltas.

## 3. File map

| Path | What |
|---|---|
| `csharp/.orchestration/AGENTS.md` | working agreements for any AI agent operating this project's tooling — read first |
| `csharp/.orchestration/README.md` | project purpose, layout, roles, 5-minute setup |
| `csharp/.orchestration/docs/SETUP.md` | one-time environment/machine setup (WSL2, CUDA, llama.cpp build, systemd) |
| `csharp/.orchestration/docs/LOCAL-LLM-BEST-PRACTICES.md` | this file — cross-model guidance only |
| `csharp/.orchestration/bench/dispatch.sh` | dispatch (ollama + llamacpp backends; token sidecar; per-call loaded-model check) |
| `csharp/.orchestration/bench/bench.sh` | bench runner (code harness vs doc `verify.sh`; `--rules <lang>` → `models/<model>/rules/<lang>-rules.md`) |
| `csharp/.orchestration/bench/session-start.sh`, `session-stop.sh` | session isolation: stop other local hosters, load the target model |
| `csharp/.orchestration/bench/pure-run.sh` | pure self-test runner: controls + model run over a role track (`--test docs\|reason\|tool\|extract\|review`) |
| `csharp/.orchestration/bench/report.sh` | enriched report generator: results table + tokens + delta vs previous report |
| `csharp/.orchestration/models/README.md` | cross-model index: which model has been tested against which role |
| `csharp/.orchestration/models/<model>/README.md` | that model's current steering profile — verdicts, how to optimize per role |
| `csharp/.orchestration/models/<model>/history.md` | that model's full historical narrative (round-by-round evidence) |
| `csharp/.orchestration/models/<model>/rules/` | that model's own steering rules — not shared across models |
| `csharp/.orchestration/models/<model>/reports/` | per-run evidence going forward — `round-<round>-<task>.md` (raw) or `report-<role>-<timestamp>.md` (enriched) |
| `csharp/.orchestration/tasks/<role>-<name>/` | flat task set: SPECs + test harnesses, role-prefixed |
| `csharp/.orchestration/tasks/<project>/` | reference material for a specific source project (SDK probes, cheat-sheets), not tasks |
| `csharp/.orchestration/templates/` | copy-to-onboard for a new project or a new model |
| `csharp/ORCHESTRATION.md` | C# port orchestration (the *port's* doc — not this guide) |

Git note: `csharp/.orchestration/` is gitignored scratch — everything
under it lives there by design (LLM research is the test-bed product, not
repo-tracked). Tracked port docs live directly under `csharp/`.
