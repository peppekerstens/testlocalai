# Bench report: code-csharp-events (round pure-20260917-100522)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-events/rounds/prompt-pure-20260917-100522.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 544 prompt / 3752 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/src/TicketStatusNotifier.cs(11,80): error CS8635: Unexpected character sequence '...' [/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/Bench.Events.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/src/TicketStatusNotifier.cs(11,82): error CS1002: ; expected [/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/Bench.Events.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/src/TicketStatusNotifier.cs(11,82): error CS1513: } expected [/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/Bench.Events.csproj]
```
