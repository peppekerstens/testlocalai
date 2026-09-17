# Bench report: code-csharp-workflow (round pure-20260917-081435)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-workflow/rounds/prompt-pure-20260917-081435.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 873 prompt / 924 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/src/TicketWorkflow.cs(47,69): error CS8635: Unexpected character sequence '...' [/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/Bench.Workflow.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/src/TicketWorkflow.cs(47,71): error CS1002: ; expected [/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/Bench.Workflow.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/src/TicketWorkflow.cs(47,71): error CS1513: } expected [/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/Bench.Workflow.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/src/TicketWorkflow.cs(48,69): error CS8635: Unexpected character sequence '...' [/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/Bench.Workflow.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/src/TicketWorkflow.cs(48,71): error CS1002: ; expected [/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/Bench.Workflow.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/src/TicketWorkflow.cs(48,71): error CS1513: } expected [/home/peppe/github/testlocalai/tasks/code-csharp-workflow/harness/Bench.Workflow.csproj]
```
