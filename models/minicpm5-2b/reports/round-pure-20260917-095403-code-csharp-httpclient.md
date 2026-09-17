# Bench report: code-csharp-httpclient (round pure-20260917-095403)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-httpclient/rounds/prompt-pure-20260917-095403.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: rules (csharp-rules.md + SPEC.md, current best)
- Tokens: 846 prompt / 1768 completion

## VERDICT: BUILD FAIL
```
/home/peppe/github/testlocalai/tasks/code-csharp-httpclient/harness/src/CwClient.cs(6,7): error CS0138: A 'using namespace' directive can only be applied to namespaces; 'HttpStatusCode' is a type not a namespace. Consider a 'using static' directive instead [/home/peppe/github/testlocalai/tasks/code-csharp-httpclient/harness/Bench.Task3.csproj]
```
