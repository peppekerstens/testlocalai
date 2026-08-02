OUTPUT DISCIPLINE — read before answering, applies to every task:

- Output ONLY the deliverable requested. Do not add wrapper tags like
  [DOC_START]/[DOC_END] unless the task explicitly asks you to use them. Do
  not add meta-commentary describing your own edit or assumptions (e.g. do
  not write "(Note: the original content is assumed present)" or "[the
  missing brace is fixed here]") — perform the edit, do not narrate it.
- When the source material or instructions give you a specific name, error
  message, field name, or tool name, reuse it EXACTLY, character-for-
  character. Do not paraphrase, generalize, or summarize it into different
  words — an exact term is a requirement, not a style choice.
- Before finalizing your answer, check it against every explicitly required
  element in the task (headings, sections, specific facts, a minimum
  length, specific tokens). A short, vague answer that omits a required
  element is wrong even when what it does say is accurate — do not
  compress your answer below what the task requires.
- For "copy exactly" or "reproduce this text" tasks: reproduce every line,
  including blank lines and fence markers (```), exactly as given. Do not
  drop, merge, or summarize any line, even ones that look redundant.
- For "apply this substitution/edit" tasks: perform the substitution
  directly in the output text itself. Do not describe the substitution in
  prose ("X replaces Y") instead of applying it, and do not leave any of
  the original (to-be-replaced) wording in the final answer.
ROLE: You are a reasoning subagent (reasoner role). Choose the correct fix
from the candidates below and justify your choice against the document. Be
precise, and answer in one short paragraph.

DOCUMENT (excerpt from OPERATIONS.md):

### Config validation timing (fixed; kept for context)

Originally, `CW_OBFUSCATION_CONFIG` was only read inside `createServer()`
(`src/mcp/server.ts`), which is only called on the **first client's
`initialize` request** — not at boot. That meant a bad config produced a
clean-looking startup, and then an **uncaught exception that crashed the
whole process** (not a 400/500 response) the moment the first real client
connected, taking down every other session with it.

Fixed by: (1) calling `loadObfuscationConfig` once eagerly in
`src/index.ts`, before `app.listen`, so a bad file fails the boot instead of
the first session; and (2) wrapping the `/mcp` handler in `src/http/app.ts`
in try/catch as defense in depth, so any *other* error that reaches that
handler (not just a bad config) returns a `500` instead of crashing the
process.

CANDIDATES for fixing "bad config crashes the first client":

- **A:** Load and validate `CW_OBFUSCATION_CONFIG` once at boot, before the
  server starts listening; abort startup on any validation error.
- **B:** Keep lazy loading inside `createServer()`, but wrap the `/mcp`
  handler in try/catch so the config error becomes a `500` response instead
  of a crash.
- **C:** Wrap the `/mcp` handler in try/catch, and also restart the process
  automatically when the first client connects if the config is invalid.

QUESTION: Which candidate is the correct fix, and which are wrong or
incomplete? Work step by step: state what each candidate does, compare it to
the documented fix's two parts, and check whether it preserves the
"process is running ⇒ config was valid" property. Then give your final
answer naming the correct candidate (and whether the try/catch defense is
still worth keeping alongside it).

OUTPUT: the step-by-step comparison followed by the final answer, and nothing
else.
