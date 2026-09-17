# Bench report: code-csharp-batch (round pure-20260917-100522)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-batch/rounds/prompt-pure-20260917-100522.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 757 prompt / 790 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(57,36): error CS0117: 'TaskCreationOptions' does not contain a definition for 'LoopState' [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
```
