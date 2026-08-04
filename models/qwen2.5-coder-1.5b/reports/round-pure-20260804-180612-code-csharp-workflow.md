# Bench report: code-csharp-workflow (round pure-20260804-180612)

- Prompt: `/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-workflow/rounds/prompt-pure-20260804-180612.txt`
- Model: qwen2.5-coder:1.5b (temp 0.2)
- Backend: llamacpp
- Mode: rules (csharp-rules.md + SPEC.md, current best)
- Tokens: 1413 prompt / 435 completion

## VERDICT: BUILD FAIL
```
/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-workflow/harness/src/TicketWorkflow.cs(5,7): error CS0246: The type or namespace name 'YamlDotNet' could not be found (are you missing a using directive or an assembly reference?) [/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-workflow/harness/Bench.Workflow.csproj]
```
