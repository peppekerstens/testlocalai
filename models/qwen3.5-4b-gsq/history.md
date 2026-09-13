# qwen3.5-4b-gsq — history

## Model registration (2026-09-13)

New model, distinct from the existing [`qwen3.5-4b`](../qwen3.5-4b/)
directory. `ISTA-DASLab/Qwen3.5-4B-GGUF-GSQ`, the `Q2_K_XL` file, a
gradient-search low-bit quantization. Real, verified size: 1.81 GiB,
against the existing directory's `unsloth/Qwen3.5-4B-GGUF` Q4_K_M at 2.74
GiB. Same base weights, different quantization method and size — steering
not assumed to transfer between the two.

Deployed as a persistent systemd service on `legion-t5`
(`llama-chat-4b-gsq.service`, `ai-stack` repo), two slots, `--kv-unified`,
245,760 shared context. See `ai-stack/legion-t5-llamacpp/README.md` for the
real VRAM math behind that exact number, including the 262,144 native
ceiling that only fits when `embed-local` holds zero VRAM, which is not
this box's real running state.

## Docs role — Phase 1 through Confirm (2026-09-13)

**Phase 1 baseline**: 4/9 PASS bare. `enable_thinking=false` set from the
start, per the qwen3.5-family default — not independently re-verified as
mandatory for this specific checkpoint (Phase 0 was skipped, no new red
flags for a qwen3.5 checkpoint already well characterized in this project).

**Research phase**: cross-model idiom check ran against all 7 other tested
models (`research-docs.md`). Confirmed several idioms this checkpoint would
go on to hit are already known family-wide, most notably the table
separator row substitution (see Confirm Findings below).

**Tier 1, round 1** (5 tasks steered: `doc-verbatim`, `doc-surgical`,
`doc-adapt`, `doc-repair`, `doc-summarize`): 6/9 after round 1.

- `doc-verbatim` — fixed. Idiom: an extra blank line inserted before an
  appended `> Note:` line, a reflexive Markdown blockquote-spacing habit,
  pushing a 16-line requirement to 17. Lever: name the exact join point and
  the competing habit explicitly, plus a self-check targeted at that one
  failure mode.
- `doc-repair` — fixed. Idiom: the closing fence for Defect 1 landed at the
  end of the whole document instead of right after the YAML block it was
  meant to close, nesting an unrelated table inside the fence. Lever: a
  wrong/right contrast pair plus a positional self-check, reused from a
  working pattern already on record for this model.
- `doc-summarize` — fixed. Idiom: fact 4 (that other ConnectWise MCP
  servers are also TypeScript/Node) got compressed into vague causal
  language without ever stating the required attribute — checklist item
  satisfied on paper, not in substance. Lever: show the prior wrong output
  verbatim, name the missing attribute specifically, give one correct
  worked example.
- `doc-surgical` and `doc-adapt` — steered, but gated out after round 1
  showed no real improvement (`AGENTS.md`'s gate-on-run-2 rule). Reverted
  to bare.

**Tier 1, round 2** (1 task remaining: `doc-script`): 7/9.

- `doc-script` — fixed. Idiom: a two-line FIND block collapsed to one
  REPLACE line, but the model deleted only one of the two source lines
  line-by-line instead of treating the FIND block as one contiguous unit —
  passed its own "stays valid bash" check while leaving a dead variable
  assignment behind. Lever: quote the model's own actual wrong output next
  to the correct one, plus a literal greppable self-check instead of a
  vague "check your edits" instruction.

No active FAIL tasks remained after round 2 — Tier 1 stopped there.

**Tier 2 gate**: 7/9 specialist tasks PASS, 78%. GO (≥60% threshold).

**Tier 2, generalist search**: not run as a dispatch search. Reasoned
directly from this run's own Tier 1 evidence instead of spending the
budget on dispatch calls likely to fail the same way — each of the 4
working overrides above needed a quote of that exact task's own wrong
output next to the correct one; that content is inherently task-specific
by construction, not something a single shared wrapper prompt can carry.
This matches `AGENTS.md`'s own documented decision procedure for
`qwen3.5:9b`'s docs role in this exact project: when failures differ in
*kind*, not detail, check for a shared *technique* rather than a shared
*artifact*. Here that shared technique is real and already used four
times: **quote the model's own concrete wrong output next to the correct
one, plus one self-check tied to the specific failure mode** — not a
single reusable prompt block, but a reusable authoring pattern. **No
generalist artifact exists for this role on this checkpoint** — stated
plainly, per `AGENTS.md`, rather than shipping a diluted compromise
config.

**Confirm** (3 draws, unchanged state): 8, 6, 8 PASS. **VERDICT: FLAKY.**
Two tasks flip — `doc-restructure` (never steered, was already a bare
pass) and `doc-surgical` (steered then reverted before Confirm ran).
Full diagnosis in `reports/confirm-docs-20260913-110428.md`'s Findings:
both are known, already-diagnosed idioms recurring at a real, non-trivial
per-draw rate, not fresh regressions and not caused by any steering
change. **Decision: did not revert.** There is no steering change to
revert for either task. Treating 7/9 as the honest stable core and
documenting both flaky tasks openly is the accurate picture, not reverting
something that was never the cause.

## Performance run: skipped, with reason (2026-09-13)

Real measured generation speed on this checkpoint is already fast: 85 to
105 tokens per second depending on load (solo vs 2-slot concurrent,
`ai-stack/litellm-router` session, 2026-09-13). No task in this role showed
truncation, and no failure traced to output length or verbosity — every
diagnosed idiom above is a formatting-fidelity or splice-boundary error,
not a padding problem. `AGENTS.md`'s own caveat on the "caveman"-style
output-shaping lever: "only apply where failures are about padding, not
missing content" — none of this role's failures are, so a Performance
pass has no real lever to apply here. Skipped rather than run for its own
sake.
