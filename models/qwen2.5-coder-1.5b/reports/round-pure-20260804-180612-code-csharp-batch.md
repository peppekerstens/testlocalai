# Bench report: code-csharp-batch (round pure-20260804-180612)

- Prompt: `/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-batch/rounds/prompt-pure-20260804-180612.txt`
- Model: qwen2.5-coder:1.5b (temp 0.2)
- Backend: llamacpp
- Mode: rules (csharp-rules.md + SPEC.md, current best)
- Tokens: 1299 prompt / 321 completion

## VERDICT: BUILD FAIL
```
/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(8,7): error CS0246: The type or namespace name 'YamlDotNet' could not be found (are you missing a using directive or an assembly reference?) [/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
```
