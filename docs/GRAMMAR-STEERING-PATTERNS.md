# Grammar-constrained decoding: when to reach for it, and starter patterns

Cross-model guidance, not one model's steering profile — see `AGENTS.md`'s
quality loop, Tier 2, for the decision-procedure rule this file backs up.
Origin: discovered and first used on `qwen3.5:9b`'s docs role
(`models/qwen3.5-9b/history.md`), generalized here because the underlying
finding — some structural failures resist all prompt-only steering but
fold immediately under a decoding-time constraint — isn't specific to
that one model.

## When to reach for this

Grammar-constrained decoding restricts which tokens the model is allowed
to emit at each step, so the output is *guaranteed* structurally valid —
not just encouraged to be, the way a prompt instruction is. Reach for it
when a task's failure has this shape:

- The model's actual **content** is usually correct (right words, right
  facts) — the failure is **positional/structural**: a blank line in the
  wrong place or missing, a closing fence/marker landing at the end of
  the document instead of where it belongs, a table missing its
  separator row.
- **Real prompt-only steering has already been tried and failed**, ideally
  more than once with genuinely different instruction styles (not just
  reworded restatements of the same idea) — grammar isn't a first resort,
  it's what you reach for once prompt text has demonstrably not been the
  right lever for *this specific defect shape*.

Do **not** reach for it when the failure is about **content generation
itself** — wrong facts, bad synthesis, wrong word choice in freely-
composed text. A grammar can't fix "the model doesn't know what to say,"
only "the model knows what to say but keeps putting a fixed element in
the wrong place." Forcing content that way just hardcodes the test's
answer into the decoder — see the legitimacy rule below.

## Backend capability — verify, don't assume

**Confirmed working in this project**: `llama.cpp`/`llama-server`, via
its OpenAI-compatible `/v1/chat/completions` endpoint's `grammar` field
(GBNF format) — wired into `bench/dispatch.sh` as `DISPATCH_GRAMMAR_FILE`,
auto-resolved per-task by `bench/pure-run.sh` from
`models/<model-dir>/grammars/<task>.gbnf`. Smoke-tested and used for real
task fixes 2026-08-02/03.

**Not verified in this project — check before assuming**: Ollama's
grammar/structured-output support, any hosted API's equivalent (some
expose JSON-schema-constrained output but not arbitrary GBNF), or any
future backend this project adds. A model swapped from `llamacpp` to
`ollama` backend in `bench/dispatch.sh` does **not** automatically carry
grammar support with it — check the backend's own docs for an equivalent
mechanism before assuming a grammar file will do anything, and note the
result (works / doesn't / not tested) here or in the model's own Setup
section per the "every dispatch-level tweak must be documented" rule.

## The legitimacy line: structure only, never content

This is the one rule that matters most when writing a grammar for this
purpose — see `models/qwen3.5-9b/history.md` for the real mistake that
established it:

- **Legitimate**: forcing *shape* — required line count, a literal
  fence/separator/prefix at a specific position, cell-count-per-row —
  while leaving the actual words/content as a free-text nonterminal the
  model still has to generate correctly on its own.
- **Illegitimate**: a grammar whose `root` rule (or a large fraction of
  it) is a single literal string matching the expected answer. This
  doesn't test the model at all — the decoder produces that exact output
  regardless of what the model would have generated, for *any* model,
  even one with random weights. A first attempt at fixing
  `qwen3.5:9b`'s `doc-surgical` did exactly this by accident (rationalized
  at the time as "the content is prompt-given so it's fine" — it wasn't;
  prompt-given-ness doesn't change that a fully-forced grammar makes the
  model's actual output irrelevant to the result). Caught and reverted;
  see that model's history.md for the full story and why the task was
  correctly left unresolved instead.
- **The genuine edge case**: a "surgical edit" archetype task (verbatim
  copy + fully prompt-given literal replacements, zero creative freedom
  by the task's own design) can legitimately use a *large* fraction of
  literal grammar, since every character of the correct answer is
  already given verbatim somewhere in the prompt — forcing compliance
  with instructions already given in-context is different from injecting
  outside ground truth. Even there, prefer leaving as much as possible
  free (see `doc-verbatim`'s pattern below) rather than defaulting to
  full-literal; only reach for near-literal when the specific defect is
  itself content-fidelity on a short, exactly-quoted span, not structure.

## Starter patterns (adapt, don't necessarily reuse verbatim)

Each of these is a real, working pattern from `models/qwen3.5-9b/grammars/`
— read as a shape to adapt to your task's actual required structure, not
a drop-in.

### Pattern: fixed line/paragraph count with free content per line

For a document with a known, fixed structural skeleton (a heading, a
fenced block of N lines, a blank-line-separated table) where the defect
is blank lines or fence markers landing in the wrong place or being
dropped:

```gbnf
root ::= "<literal heading>\n\n```yaml\n" line line line line "```\n\n" header "\n<literal separator>\n" row "\n" row "\n" row "\n" row "\n" note

line ::= [^\n]+ "\n"
header ::= [^\n]+
row ::= [^\n]+
note ::= "> " [^\n]+
```

The literal strings force the skeleton (blank-line positions, fence
placement, separator content); `line`/`header`/`row`/`note` stay free —
the model still has to get the actual words right, it just can't
misplace the structural elements around them. (`doc-verbatim.gbnf`.)

### Pattern: table shape without dictating cell content

For a task requiring genuine synthesis into table cells (the actual
words in each cell are the thing being tested), where the defect is
specifically a missing/malformed separator row or wrong row count:

```gbnf
root ::= "| <literal header cols> |\n<literal separator>\n" row "\n" row "\n" row "\n" row

row ::= "| " cell " | " cell " |"
cell ::= [^\n|]+
```

Only the table's outer shape (header text, separator, exact row count,
cell-count-per-row) is forced; every cell's actual content is fully
free. This is the right level of constraint when the observed failure
is "forgets the separator row when generating a new table," not
anything about the synthesized content itself. (`doc-restructure.gbnf`.)

### Pattern that looked promising but wasn't: unbounded free-text runs

An attempt at a "partial" grammar for `doc-surgical` used
`pre ::= [^\x00]*` (any character, unbounded) between forced literal
anchors, hoping to leave more of the document genuinely free than a
fully-literal grammar would. **This caused a real runaway generation**
(over 2000 tokens before being killed, versus a normal ~230-token
answer) — an unbounded free-text rule gives the grammar no natural
stopping point, so nothing pushes the model toward finishing once it's
inside that rule. Keep free-text runs **bounded** — per-line
(`[^\n]+ "\n"`, as in the first pattern above) or otherwise anchored to
a concrete, reachable terminator — never open-ended.

## Further reading

- `models/qwen3.5-9b/history.md` — the full narrative: diagnosis,
  the fully-literal mistake and its correction, the runaway-generation
  incident, and the final per-task outcomes.
- `AGENTS.md`'s quality loop, Tier 2 — the decision-procedure rule this
  file exists to back up.
- `bench/dispatch.sh` / `bench/pure-run.sh` — the actual
  `DISPATCH_GRAMMAR_FILE` mechanism and per-task auto-resolution.
