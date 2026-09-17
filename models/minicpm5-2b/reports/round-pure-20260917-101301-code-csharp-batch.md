# Bench report: code-csharp-batch (round pure-20260917-101301)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-batch/rounds/prompt-pure-20260917-101301.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 757 prompt / 1578 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(41,32): error CS1660: Cannot convert lambda expression to type 'Task<BatchResult<TResult>>' because it is not a delegate type [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
```
