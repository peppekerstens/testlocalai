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
- **A structural defect (wrong position/shape) needs a structural fix, not
  more prompt text.** If a task's content is usually right but a fixed
  element (a blank line, a closing fence, a table separator row) keeps
  landing in the wrong place across real, varied prompt attempts, that's
  a signal to check for grammar-constrained decoding support in the
  serving backend rather than keep rewording the same instruction — see
  `docs/GRAMMAR-STEERING-PATTERNS.md` and `AGENTS.md`'s Tier 2 rule.
- **"Use one name for one thing, exact, every time" is a reasonable
  starting-point default, not a proven universal fix.** Originated as
  `lfm2.5-1.2b-thinking`'s `rules/surgical-edit-discipline.md` +
  `rules/ste-writing.md` (Simplified Technical English discipline: exact
  names never paraphrased, active voice, one idea per sentence). Tested
  as a cross-model transfer on `qwen3.5:9b` (2026-08-03): non-regressive
  (every already-passing task stayed passing) but did not clearly
  outperform a from-scratch generic reminder on that model — worth
  trying early in a new model's Research/Steering phase given how often
  exact-token/exact-name fidelity shows up as a failure idiom across
  this project's models, but treat it as a reasonable first guess to
  verify, not an assumed win.

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
| `AGENTS.md` | working agreements for any AI agent operating this project's tooling — read first |
| `README.md` | project purpose, layout, roles, 5-minute setup |
| `history.md` | this project's own history — origin, cross-model findings, retired conventions |
| `docs/SETUP.md` | one-time environment/machine setup (WSL2, CUDA, llama.cpp build, systemd) |
| `docs/LOCAL-LLM-BEST-PRACTICES.md` | this file — cross-model guidance only |
| `docs/GRAMMAR-STEERING-PATTERNS.md` | when to reach for grammar-constrained decoding, backend capability notes, starter grammar patterns |
| `bench/dispatch.sh` | dispatch (ollama + llamacpp backends; token sidecar; per-call loaded-model check; `DISPATCH_GRAMMAR_FILE`) |
| `bench/bench.sh` | bench runner (code harness vs doc `verify.sh`; `--rules <lang>` → `models/<model>/rules/<lang>-rules.md`) |
| `bench/session-start.sh`, `session-stop.sh` | session isolation: stop other local hosters, load the target model |
| `bench/pure-run.sh` | pure self-test runner: controls + model run over a role track (`--test docs\|reason\|tool\|extract\|review`) |
| `bench/report.sh` | enriched report generator: results table + tokens + delta vs previous report; restarts the target service and logs free VRAM/RAM first (mandatory, see `AGENTS.md`) |
| `models/README.md` | cross-model index: which model has been tested against which role |
| `models/<model>/README.md` | that model's current steering profile — verdicts, how to optimize per role |
| `models/<model>/history.md` | that model's full historical narrative (round-by-round evidence) |
| `models/<model>/rules/` | that model's own steering rules — not shared across models |
| `models/<model>/grammars/` | that model's per-task GBNF grammars, auto-resolved by `pure-run.sh` |
| `models/<model>/reports/` | per-run evidence going forward — `round-<round>-<task>.md` (raw) or `report-<role>-<timestamp>.md` (enriched) |
| `tasks/<role>-<name>/` | flat task set: SPECs + test harnesses, role-prefixed |
| `tasks/<project>/` | reference material for a specific source project (SDK probes, cheat-sheets), not tasks |
| `templates/` | copy-to-onboard for a new project or a new model |

This project (`testlocalai`) was originally a gitignored scratch
subdirectory of a C# port repo, `csharp/.orchestration/` — hence some
older references to that path. It's now its own standalone, tracked
repository; see root `history.md` for the origin story.
