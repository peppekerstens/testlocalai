# Bench report: code-csharp-batch (round pure-20260917-081435)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-batch/rounds/prompt-pure-20260917-081435.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 757 prompt / 16384 completion
- ⚠️ TRUNCATED (finish_reason=length) — context/token limit hit before generation finished. reasoning_content=76164 chars. If the output below is empty or short, this is context exhaustion, not a model reasoning failure — do not score it as a content bug without checking the server's context size first.

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(49,21): error CS8031: Async lambda expression converted to a 'Task' returning delegate cannot return a value [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(53,21): error CS8031: Async lambda expression converted to a 'Task' returning delegate cannot return a value [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(49,21): error CS8030: Anonymous function converted to a void returning delegate cannot return a value [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(53,21): error CS8030: Anonymous function converted to a void returning delegate cannot return a value [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
```
