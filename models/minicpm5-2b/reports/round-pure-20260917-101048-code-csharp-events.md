# Bench report: code-csharp-events (round pure-20260917-101048)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-events/rounds/prompt-pure-20260917-101048.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 544 prompt / 3087 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/src/TicketStatusNotifier.cs(7,11): error CS8956: File-scoped namespace must precede all other members in a file. [/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/Bench.Events.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/src/TicketStatusNotifier.cs(3,7): error CS0138: A 'using namespace' directive can only be applied to namespaces; 'Array' is a type not a namespace. Consider a 'using static' directive instead [/home/peppe/github/testlocalai/tasks/code-csharp-events/harness/Bench.Events.csproj]
```
