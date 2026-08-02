ROLE: You are a reasoning subagent. Diagnose the error below. Give the root
cause and the exact fix, in one short paragraph. Do not speculate about
causes that contradict the log.

SERVER LOG (entire startup output):

```
$ dotnet run --project src/ConnectwiseMcp
Error: Missing required environment variable: CW_PRIVATE_KEY
```

QUESTION: What is the root cause of this error? Work step by step: quote the
exact error line from the log, state what mechanism in the server's startup
produces that message (what it does and when it aborts), then give the exact
fix. Do not invent causes not supported by the log.

OUTPUT: the step-by-step diagnosis followed by the fix, and nothing else.
