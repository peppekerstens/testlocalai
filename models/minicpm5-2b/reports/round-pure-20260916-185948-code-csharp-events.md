# Bench report: code-csharp-events (round pure-20260916-185948)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-events/rounds/prompt-pure-20260916-185948.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 544 prompt / 2197 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/src/TicketStatusNotifier.cs(6,11): error CS8956: File-scoped namespace must precede all other members in a file. [/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/Bench.Events.csproj]
```
