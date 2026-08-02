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
