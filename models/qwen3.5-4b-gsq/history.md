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

## Full 6-role test, direct legion-t5, first attempt: invalid (2026-09-13)

Ran `bash bench/full-test.sh qwen3.5-4b-gsq llamacpp 11434 192.168.2.133`,
no thinking-mode override set. Docs role came back 4/9 PASS — a real
regression against the 7/9 stable core closed above. Root cause: this
checkpoint defaults to thinking on, and neither
`DISPATCH_ENABLE_THINKING` nor a graded reasoning control was set for
this direct-host command. Several answers spent the full 16,384-token
cap on `reasoning_content` before reaching a real answer (~175 seconds
per task at 94 tok/s, confirmed live on `legion-t5`'s own
`print_timing` log). `litellm-router/config.yaml`'s `qwen3.5-9b-local`
tier already bakes `reasoning_effort: "none"` into every call to this
same backend, which is why this idiom had never shown up through that
path. The run was stopped mid-`reason`-role once the cause was
confirmed. An orphaned dispatch call from this run (`reason-trace`,
still holding a GPU slot with invalid data) needed a second, forceful
kill after the top-level process tree died but the child survived.

**Fix**: `bench/dispatch.sh` gained `DISPATCH_REASONING_EFFORT=none|low|
medium|high`, a top-level `reasoning_effort` body field — the graded
control `qwen3.8`+ and llama-server itself understand directly, the same
field the router already sets per tier. Kept separate from the existing
boolean `DISPATCH_ENABLE_THINKING` (its `chat_template_kwargs.
enable_thinking` mechanism), and mutually exclusive with it by design —
`dispatch.sh` now errors if both are set on one call. A smoke test
against this exact model and host confirmed `reasoning_effort: "none"`
suppresses thinking on a direct dispatch, not only through litellm
(`completion_tokens: 2`, `reasoning_content_chars: 0` on a 1-word
prompt).

## Full 6-role test, direct legion-t5, rerun with reasoning off (2026-09-13)

Same command, `DISPATCH_REASONING_EFFORT=none` added. Clean run, about 2
minutes wall time for the 5 non-code roles combined (versus over an hour
stuck mid-`reason` on the first attempt), plus real `dotnet` compile time
for the code role. Real, single-draw results:

| Role | Result | Report |
|---|---|---|
| Docs (4 tasks under existing `task-overrides/`, 5 bare) | 7/9 PASS | `reports/report-docs-20260913-185823.md` |
| Reason (bare) | 4/9 PASS | `reports/report-reason-20260913-185856.md` |
| Tool-use (bare) | 6/6 PASS | `reports/report-tool-20260913-185926.md` |
| Extract (bare) | 6/6 PASS | `reports/report-extract-20260913-185937.md` |
| Review (bare) | 4/6 PASS | `reports/report-review-20260913-185948.md` |
| Code-emitter (bare, 13 C# + 1 Python) | 14/14 PASS | `reports/report-code-20260913-190003.md` |

The docs role's 7/9 matches the already-closed Documenter result above —
the existing task overrides for `doc-verbatim`, `doc-repair`,
`doc-summarize`, and `doc-script` applied automatically, confirming that
result still holds with reasoning off. The other five roles are fresh,
bare, single-draw baselines with no steering attempted yet.

## Litellm routed-path spot-check (2026-09-13)

Rather than re-run all 6 roles a second time through
`ai-stack/litellm-router` (transport changes latency and cache handling
only, not model output — already established for another model), ran one
already-tested task through the routed path: `DISPATCH_BACKEND=litellm
bash bench/dispatch.sh qwen3.5-9b-local tasks/extract-basic/SPEC.md
<out-file>`. Result matched the direct run exactly: `prompt_tokens: 142,
completion_tokens: 52, finish_reason: stop, reasoning_content_chars: 0` —
byte-for-byte the same token counts as the direct `extract-basic` row
above. Confirms the routed path reaches this exact model with identical
behavior; no full second suite needed.
