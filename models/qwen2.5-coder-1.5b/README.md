# qwen2.5-coder:1.5b — steering profile

**Role: code-emitter-csharp.** Bench evidence is code-emitter evidence
only; deepseek-r1 owns the documentation/reasoning roles (see
`models/deepseek-r1-1.5b/`). Rules and SPECs here are qwen-specific —
reverse engineered from *this model's* observed failures on C# tasks, not
a generic/shared ruleset. A different model may need different rules,
non-prose scaffolding, or none — don't assume these transfer.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Code-emitter (C#) | ✅ Established — two validated recipes | Not a single number — two task families, each with its own recipe and verified-equal-quality outcome; see `history.md` for round-by-round pass rates | Not assessed | [Use this](#use-this) |

## Use this

**Two different recipes for two task families — do not mix them:**

- **Original 6** (`code-csharp-config`, `code-csharp-cache`, `code-csharp-httpclient`,
  `code-csharp-auth`, `code-csharp-tool`, `code-csharp-redactor`): `--rules csharp`
  (`rules/csharp-rules.md` + `SPEC.md`) — compressed "caveman-style"
  prompt, validated equal-quality at lower token cost. Pre-compression
  verbose version archived at `rules/history/csharp-rules-verbose.md` +
  each task's `history/SPEC-verbose.md`, runnable via `bench.sh --legacy`.
- **New 6** (`code-csharp-stats`, `code-csharp-equality`, `code-csharp-events`,
  `code-csharp-repository`, `code-csharp-batch`, `code-csharp-workflow`): **bare `SPEC.md`, no
  `--rules` flag.** Prepending `rules/csharp-rules.md` to these tasks
  *hurts* — the rules file's canonical-API examples (YamlDotNet,
  `System.Text.Json.Nodes`) are vivid enough that qwen reproduces them
  regardless of task relevance.

**Rule going forward:** a shared `<lang>-rules.md` does not automatically
generalize to a new task in the same language. Before assuming a new task
needs the rules block, check whether its `SPEC.md` is already
self-sufficient (compressed style, verbatim shapes for every method — an
ellipsis `{ ... }` left for a non-trivial method is exactly where draws
get flaky).

## Setup

- Served by llama.cpp CUDA build via `llama-server.service` (systemd user
  service) on `:8080` → use `DISPATCH_BACKEND=llamacpp`. Ollama is the
  unchanged fallback. See `docs/SETUP.md` for the full environment build.
- temp 0.2, num_ctx 16384 (hardcoded in `bench/dispatch.sh`).
- Model file: `qwen2.5-coder-1.5b-instruct-q4_k_m.gguf` (~1 GB, 16K context).

## How to optimize for the code-emitter role

1. **Show, don't describe.** Paste a complete verbatim method/class in
   the SPEC, never describe the shape in prose — description invites
   idiom drift at this scale.
2. **Canonical snippets for tricky API calls.** Exact `using` lines
   verbatim; implementation first, verbatim record/DTO types last, plus a
   class-count checklist for multi-type files.
3. **Scope every rule to the task.** A rules block earned on one task
   family actively hurts an unrelated one — check self-sufficiency before
   attaching it.
4. **Prose compression is free; code-shape compression is not.** Cut
   filler freely; never compress an order-dependent requirement or a
   code shape into a description.
5. **Treat one PASS round as one draw.** Re-run a tricky task several
   times before trusting a prompt — single-shot variance is real even on
   a winning prompt.

## Potential helpers (documented, not yet integrated)

Everything above is prompt-only steering — no tool access, no compile
feedback, no reference lookup beyond what's pasted into the SPEC. None of
this is wired into `bench.sh`/`dispatch.sh` yet; it's a menu for future
improvement runs. Each entry targets a specific documented failure this
model actually has, not a generic "AI tools are good" list:

| Helper | Addresses | Why (evidence) |
|---|---|---|
| **Roslyn MCP server** — e.g. [egorpavlikhin/roslyn-mcp](https://github.com/egorpavlikhin/roslyn-mcp), [carquiza/RoslynMCP](https://github.com/carquiza/RoslynMCP), [dotnet-roslyn-mcp](https://www.nuget.org/packages/dotnet-roslyn-mcp) | missing `using`s, API/overload misuse | The top two documented 1.5B failure modes (see `history.md`). Exposes real compile diagnostics as a tool call for an iterative dispatch→errors→retry loop, which `bench.sh` doesn't currently do (single-shot only). Highest-leverage, highest-effort: needs an actual retry loop, not just an added tool. |
| **Official Microsoft NuGet MCP server** ([learn.microsoft.com/en-us/nuget/concepts/nuget-mcp-server](https://learn.microsoft.com/en-us/nuget/concepts/nuget-mcp-server)) | API/overload misuse (e.g. `Remove` vs `TryRemove`, `Task.FromResult<string?>(null)`) | Lets a model query the *real* API surface of a referenced package instead of guessing from training data — targets the canonical-API-hallucination failure that canonical snippets currently work around by brute-force pasting. |
| **.NET Types Explorer MCP server** ([mcpservers.org/servers/v0v1kkk/dotnetmetadatamcpserver](https://mcpservers.org/servers/v0v1kkk/dotnetmetadatamcpserver)) | same as above, reflection-based | Alternative/complementary to the NuGet server — looks up actual type members instead of published docs. |
| **Context7** ([context7.com](https://context7.com)) | stale/hallucinated library usage in general | General-purpose fallback for anything the NuGet/Roslyn servers don't cover. |
| **Roslyn analyzers as a build gate** — built-in .NET analyzers (free), [Roslynator](https://github.com/enisn/Roslynator), `Microsoft.VisualStudio.Threading.Analyzers` + `AsyncFixer`, `StyleCop.Analyzers` | contract-logic gaps, async mistakes | Pipeline step on the model's output before scoring, not an AI capability. The threading analyzers are directly relevant to the `code-csharp-batch` task category (concurrent execution, `ConfigureAwait`, blocking-on-async). |
| **`dotnet format`** | surface-level style/formatting drift | Auto-fixes formatting so a reviewer isn't distracted by noise unrelated to logic correctness. |
| **Iterative refine loop** (technique, not a product) | output truncation, any build-time-catchable error | Feed the exact `CS####` errors back into a second dispatch round instead of a fresh single-shot attempt. Biggest architectural lift here — touches `bench.sh` and `dispatch.sh`, not just an added tool. |

## Further reading

- `history.md` — full steering iteration history (rounds A–L, prompt
  compression research, the 6-task extension, onboarding).
- `models/README.md` — cross-model index and role-coverage table.
- `reports/` — per-run evidence going forward (`bash bench/report.sh
  qwen2.5-coder:1.5b <role>`; code-* tasks don't have a role track yet,
  use `bash bench/bench.sh <task> <round> <file> --rules` directly).
