# Bench report: code-csharp-auth (round pure-20260804-180854)

- Prompt: `/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-auth/rounds/prompt-pure-20260804-180854.txt`
- Model: qwen2.5-coder:1.5b (temp 0.2)
- Backend: llamacpp
- Mode: rules (csharp-rules.md + SPEC.md, current best)
- Tokens: 898 prompt / 105 completion

## VERDICT: BUILD FAIL
```
/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-auth/harness/src/AuthResolver.cs(5,7): error CS0138: A 'using namespace' directive can only be applied to namespaces; 'CancellationToken' is a type not a namespace. Consider a 'using static' directive instead [/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-auth/harness/Bench.Task4.csproj]
/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-auth/harness/src/AuthResolver.cs(6,7): error CS0246: The type or namespace name 'YamlDotNet' could not be found (are you missing a using directive or an assembly reference?) [/mnt/c/Users/peppe/OneDrive/GitHub/testlocalai/tasks/code-csharp-auth/harness/Bench.Task4.csproj]
```
