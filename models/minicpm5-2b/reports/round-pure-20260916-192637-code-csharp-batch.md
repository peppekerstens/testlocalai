# Bench report: code-csharp-batch (round pure-20260916-192637)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-batch/rounds/prompt-pure-20260916-192637.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 759 prompt / 408 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(49,21): error CS8031: Async lambda expression converted to a 'Task' returning delegate cannot return a value [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(53,21): error CS8031: Async lambda expression converted to a 'Task' returning delegate cannot return a value [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(49,21): error CS8030: Anonymous function converted to a void returning delegate cannot return a value [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(53,21): error CS8030: Anonymous function converted to a void returning delegate cannot return a value [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
```
