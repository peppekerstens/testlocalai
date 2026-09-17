# Bench report: code-csharp-batch (round pure-20260917-101048)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-batch/rounds/prompt-pure-20260917-101048.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 757 prompt / 666 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(55,36): error CS0117: 'TaskCreationOptions' does not contain a definition for 'LoopState' [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/src/BatchProcessor.cs(60,31): error CS1503: Argument 1: cannot convert from 'System.Collections.Generic.List<System.Threading.Tasks.Task<Bench.Batch.BatchResult<TResult>>>' to 'System.Collections.Generic.IEnumerable<Bench.Batch.BatchResult<TResult>>' [/home/peppe/github/testlocalai/tasks/code-csharp-batch/harness/Bench.Batch.csproj]
```
