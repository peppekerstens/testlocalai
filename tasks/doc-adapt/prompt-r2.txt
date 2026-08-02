ROLE: You are a careful document editor. Copy the document below exactly,
then apply the five FIND→REPLACE edits inside it. Do not rephrase, renumber,
merge, or reword any step. Do not comment.

The document begins at the [DOC_START] marker and ends at the [DOC_END]
marker. The markers are delimiters ONLY — never copy them into the output.

[DOC_START]

## Startup sequence and what can fail

`src/index.ts` runs, in order, at every process start (`npm start` /
`node dist/index.js`):

1. Reads `CW_COMPANY_ID`, `CW_PUBLIC_KEY`, `CW_PRIVATE_KEY`, `CW_CLIENT_ID`
   via `requireEnv(...)` — **missing any of these throws immediately and the
   process exits before binding to a port.** Nothing is logged except the
   variable name (`Missing required environment variable: <NAME>`); no
   ConnectWise call is made to validate the credentials are actually correct,
   only that they're present.
2. Builds the `ConnectWiseClient` (no network call yet — credentials aren't
   verified against ConnectWise at this point).
3. Loads and validates `CW_OBFUSCATION_CONFIG` via `loadObfuscationConfig` —
   **an invalid file (bad regex, missing required field) throws here and the
   process exits before binding to a port**, the same fail-fast shape as
   step 1. See "Config validation timing" below for the history here.
4. Builds the Express app and starts listening on `PORT` (default `3000`).

[DOC_END]

Apply exactly these five edits, nothing else:

EDIT 1 — find this exact text:
`src/index.ts`
and replace it with:
`src/ConnectwiseMcp/Program.cs`

EDIT 2 — find this exact text:
(`npm start` / `node dist/index.js`)
and replace it with:
(`dotnet run --project src/ConnectwiseMcp`)

EDIT 3 — find this exact text:
`loadObfuscationConfig`
and replace it with:
`ObfuscationConfigLoader.Load`

EDIT 4 — find this exact text:
Builds the Express app
and replace it with:
Builds the ASP.NET Core (`WebApplication`) host

EDIT 5 — after the last line of the document (step 4), append exactly this
line:
> C# adaptation (§7 #4): the config is reloaded per plan §7 #4 — edits take effect without a restart; boot-time validation still fails fast.

OUTPUT FORMAT (strict):
- Output ONLY the full document with the five edits applied.
- The output is one continuous document — the old strings must be GONE from
  it; do NOT list the edits after the document.
- Step numbering (1.–4.) must stay exactly as it is, with step 4 followed by
  the appended note line.
- No code fences, no headings, no "Here is" text, no [DOC_START]/[DOC_END].
- Print the document exactly once.
