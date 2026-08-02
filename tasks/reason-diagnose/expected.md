The log line `Missing required environment variable: CW_PRIVATE_KEY` shows
the server exits immediately, before binding to a port, because the
environment variable `CW_PRIVATE_KEY` is not set. Startup reads the four
`CW_*` credential variables via `requireEnv(...)` and throws the moment one
is missing, logging only the variable name. The fix is to set
`CW_PRIVATE_KEY` (along with the other three `CW_*` variables) in the
environment or `.env` file and re-run `dotnet run --project
src/ConnectwiseMcp`.
