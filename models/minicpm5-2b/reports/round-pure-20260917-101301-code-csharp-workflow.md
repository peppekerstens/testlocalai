# Bench report: code-csharp-workflow (round pure-20260917-101301)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-workflow/rounds/prompt-pure-20260917-101301.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 873 prompt / 871 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/src/TicketWorkflow.cs(47,100): error CS1002: ; expected [/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/Bench.Workflow.csproj]
```
