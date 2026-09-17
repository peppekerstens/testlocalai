# Bench report: code-csharp-events (round pure-20260917-094144)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-events/rounds/prompt-pure-20260917-094144.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: rules (csharp-rules.md + SPEC.md, current best)
- Tokens: 728 prompt / 16384 completion
- ⚠️ TRUNCATED (finish_reason=length) — context/token limit hit before generation finished. reasoning_content=69989 chars. If the output below is empty or short, this is context exhaustion, not a model reasoning failure — do not score it as a content bug without checking the server's context size first.

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/src/TicketStatusNotifier.cs(11,80): error CS8635: Unexpected character sequence '...' [/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/Bench.Events.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/src/TicketStatusNotifier.cs(11,82): error CS1002: ; expected [/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/Bench.Events.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/src/TicketStatusNotifier.cs(11,82): error CS1513: } expected [/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/Bench.Events.csproj]
```
