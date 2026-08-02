# qwen2.5-coder:1.5b — steering history

Full historical record, moved out of `README.md` 2026-08-02 so that file
can stay current-state-only. Nothing here is summarized away — this is
the durable record for lookup, since the raw `bench/reports/round-*`
evidence these findings were drawn from was deleted the same day as part
of a reports-scheme redesign (see `AGENTS.md`). Synthesizes three
overlapping historical sources that existed before this split (this
file's own former "Steering iteration history" section, the standalone
`docs/BENCHMARK-REPORT.md`, and `docs/LOCAL-LLM-BEST-PRACTICES.md`
§9/§10) into one record, deduplicated but not shortened — every distinct
fact/number from all three survives here.

## Original 6 tasks: rounds A–L (2026-08-01)

**Design:** 6 small self-contained C# tasks (config loader, thread-safe
cache, async HTTP client, auth contract, DI tool, regex redactor), each
with a fixed xUnit acceptance suite (26 tests total). Single-shot dispatch
per round; rounds A–L iterated the *prompt only*, same model
(`qwen2.5-coder:1.5b`, temp 0.2) throughout.

**Results by round:**

| Round | Steering | PASS / 6 | Notes |
|---|---|---|---|
| A | baseline: plain SPEC only | **0** | 5× BUILD FAIL (missing usings ×3, `Remove` overload, `Task.FromResult(null)`), 1× TEST FAIL |
| B | rules v1 (10 generic rules) | 2 | task4 (auth), task5 (tool) fixed |
| C | rules v2 (14) + complete-file/import/canonical-API/branch-trace | 3 | task2 (cache), task6 (redactor) fixed; task1 still truncated |
| D | rules v3 (16) "KNOW YOUR NAMESPACES" | **1** | **regression**: rule listed all namespaces: model imported packages the project doesn't reference (CS0234) |
| E | rules v4 (task-scoped) + task1 reordered (impl first) + task2 canonical snippet | 3 | |
| F | repeat of E (identical prompt) | 3 | reproducible — same prompt, same result |
| G | + exact `using` lines into task1/3/5 SPECs | 4 | task1 now compiles (was truncated) |
| H | + canonical snippets into task1 (validation) & task5 (`Task.FromResult<string?>`) | 5 | |
| I | task3 snippet fixed (`using System.Net;`) | task3 → PASS | |
| J | full round | 5 | task6 flaked (missing `Regex` using) |
| K | task6 + exact `using System.Text.RegularExpressions;` | task6 → PASS | |
| L | **final steering, full round** | **6 / 6** | |
| M | cross-engine sanity: same 6 tasks re-run on llama.cpp (was CPU-only before GPU fix) | **6/6** | no engine-induced regression vs L. Token counts per task: 1277–1872 prompt / 145–338 completion — each task fits comfortably in a 16K budget |

**Key levers, ranked by impact:**
1. **Exact `using` lines verbatim in the SPEC** — missing usings were the
   most frequent 1.5B failure (8+ occurrences): `CamelCaseNamingConvention`,
   `Regex`, `JsonException`, `IServiceCollection` referenced without being
   imported. Rules describing imports were insufficient; pasted verbatim
   lines worked.
2. **Canonical code snippets embedded verbatim**, not described, for tricky
   API calls (`ConcurrentDictionary.Remove(key)` doesn't exist — must be
   `TryRemove(key, out _)`; `Task.FromResult(null)` can't infer its type,
   needs `Task.FromResult<string?>(null)`) and validation/branch logic
   (204/404 branches, `IsNullOrWhiteSpace` vs `== null`).
3. **Ordering + a class-count checklist**: implementation first, verbatim
   record types last — fixed task1's consistent output truncation (it
   stopped right after the verbatim block, dropping the impl class).
4. **Task-scoped rules only.** Round D proved over-prescription is
   harmful: listing every possible namespace made the model import
   packages the project doesn't reference. More rules ≠ better.

**Consistency caveat:** identical prompt E→F gave identical 3/6 (good
reproducibility), but single-shot output still varies — task6 passed
C/E/F/G then flaked in J until given the exact `using` line. **Always
verify** (`dotnet build` + `dotnet test`); never trust a subagent's
success claim.

## Prompt compression: round N "caveman" (2026-08-01)

**Question:** can the round-L prompt shrink (tokens/context/cost) while
keeping 6/6 quality? Sources: the `caveman` prompt-compression skill
pattern (prompt-art / Jules B.) and JetBrains-style prompt-compression
benchmarks (2026).

**Findings:**
- Theatrical "caveman" acting (dropping grammar to look "small") *hurts*
  quality.
- Compress *behavior*, not *persona* — specific/behavioral compression
  (cut filler, keep instructions precise) beats "you are small/laconic".
- Winning pattern: remove filler and redundancy, keep every technical
  detail intact.

**Caveman ruleset (safe reductions):** drop articles/filler/pleasantries/
hedging (sentence fragments OK); short synonyms OK but never invented
abbreviations (tokenizers split them to the same token count as the full
word anyway); no causal arrows (`→`), write "so"/"because"; technical
terms verbatim, code and error strings exact; no self-reference ("I…"),
persist style every response. **Auto-Clarity rule (the one that
matters): never compress order-dependent behavioral requirements** —
that's exactly where a 1.5B model "fills the gaps" with assumptions.

**Round N result:**

| Measure | Round M (full) | Round N (caveman) |
|---|---|---|
| Pass rate | 6/6 | **6/6** |
| Total prompt tokens | 9303 | **6557 (-29.5%)** |
| Total completion tokens | 1335 | **1195 (-10.5%)** |

- **Prose compression is safe; code-shape compression is not.** The
  *first* caveman attempt (before this fix) failed — 0/8 on task4 and
  occasional failures on tasks 1/2/5 — because the SPEC *described* a
  shape instead of *showing* a complete one (produced e.g.
  `xDevUser ?? "anonymous"` for whitespace handling instead of the exact
  required check, `try/catch` instead of validation, `_lock` referenced
  without a backing field, spurious `using YamlDotNet`).
- **Fix:** keep every verbatim code shape byte-for-byte, compress only
  the surrounding prose. Once each task's SPEC contained a complete
  verbatim target, all 6 passed reliably (4/4, 3/3, 4/4 fresh-draw checks
  on the previously-flaky tasks).
- **Single-round 6/6 overstates robustness.** Reliability sampling on
  task4 specifically (the whitespace edge case): full rules + full SPEC
  ~62% (5/8), caveman-before-fix 0/8, caveman-with-shape 100%. A single
  pass is not proof a model "solved" a task.
- Token savings are prompt-side — completions barely shrank (the persona
  doesn't shorten the model's own code output); the win is ~30% less
  context consumed per dispatch.
- Auto-Clarity rule validated empirically: the only failures were exactly
  the compressed-away order/edge requirements; restoring them verbatim
  fixed everything.

This round is why the compressed variant is now qwen's default —
promoted to plain `csharp-rules.md`/`SPEC.md`, pre-compression version
archived under `rules/history/csharp-rules-verbose.md` + each task's
`history/SPEC-verbose.md`, still runnable via `bench.sh --legacy`.

**Re-verified post-restructure:** both the current default and the
archived `--legacy` pair were re-run against `code-config` after a later
directory/rules reorganization — both still PASS, confirming the
reorganization didn't change behavior, only where things live.

## Extended to 6 more tasks (2026-08-01)

New tasks: `code-stats`, `code-equality`, `code-events`,
`code-repository`, `code-batch`, `code-workflow` — increasing
difficulty/length (see `bench/README.md`'s "Extended code-emitter
suite"), structurally different from the original 6 (LINQ, value
equality, events, generics, async fan-out, state machines — none needing
YAML/JSON/HTTP).

- **First real run (round `run1`):** `--rules csharp` (the original 6's
  winning mode) only reached 3/6 — 2 BUILD FAIL from hallucinated
  `using YamlDotNet...`/`System.Text.Json` (rules-block contamination —
  the rules file's canonical-API examples are vivid enough that qwen
  reproduces them regardless of task relevance, the same over-prescription
  failure round D diagnosed, now shown to also occur *across* task
  families sharing one static rules file, not just within one
  over-long rules file), 1 TEST FAIL from two real `TopStatuses` logic
  bugs in `code-stats` (returning the full list instead of empty on
  `n==0`; counting occurrences within an already-deduplicated list
  instead of the source data).
- **Dropping rules entirely (round `run2`):** bare `SPEC.md`, no
  `--rules`, jumped straight to 5/6 with zero other changes — confirmed
  the rules block itself caused both build failures, not the tasks.
- **Closing the last verbatim gaps:** `code-equality`'s `Deduplicate` and
  `code-stats`'s `AverageOpenPriority`/`TopStatuses` were the only
  methods in either SPEC still left as `{ ... }` instead of shown
  verbatim — exactly where draws got flaky (`code-equality`:
  `HashSet<CompositeKey>` given a stray `StringComparer` argument, a type
  error; `code-stats`: `.Average()` called on a possibly-empty sequence,
  throwing instead of returning `0.0`). Making both fully verbatim
  brought both to 100% across repeated draws (`code-equality` 7/7,
  `code-stats` 7/7 after the fix, vs. intermittent failures before) —
  same "show, don't describe" lesson as round N, applied per-method
  instead of per-task.
- **Final 3-draw consistency check (round `consistency`):** new 6 tasks
  18/18 (100%); original 6 tasks 16/18 (88.9%, two draw-variance
  failures). Confirmed two different recipes are the maintained
  recommendation for the two task families, not a one-off result — see
  current `README.md`'s "Use this" for the resulting rule.

## Onboarding history

- The original onboarding round-trips (0.3a-cheatsheet, 0.3b-probe) that
  built the first steering are gone, not lost — their content is fully
  superseded: 0.3a-cheatsheet's output is `tasks/csharp/sdk-cheat-sheet.md`
  verbatim; 0.3b-probe's two attempts both regressed and were discarded,
  and the working probe (`tasks/csharp/probe/`) was hand-assembled by the
  orchestrator instead — see `ORCHESTRATION.md` deviation #5.

## Measured hardware performance (this model, this box)

See `docs/SETUP.md` for the full CUDA/WSL2 setup this was measured under.
llama.cpp, qwen2.5-coder:1.5b (Q4_K_M, 8192 ctx, 4 slots): CPU (no GPU
offload) 19–26 tok/s generation → CUDA GPU (sm_75) **98–100 tok/s**
generation, ~68–79 tok/s prompt-eval, 92% GPU utilization, 2227 MiB of
4096 MiB VRAM used. A `dispatch.sh` round-trip (prompt 23 tok + 4 tok
answer) took ≈0.46s on the CUDA engine.
