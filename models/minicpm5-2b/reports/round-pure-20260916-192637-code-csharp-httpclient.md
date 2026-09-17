# Bench report: code-csharp-httpclient (round pure-20260916-192637)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-httpclient/rounds/prompt-pure-20260916-192637.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 563 prompt / 131 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-httpclient/harness/src/CwClient.cs(18,57): error CS0161: 'CwClient.GetAsync(string, CancellationToken)': not all code paths return a value [/home/peppe/github/testlocalai/tasks/code-csharp-httpclient/harness/Bench.Task3.csproj]
```
