ROLE: You are a coding subagent. Implement exactly the task below.
You are Qwen 2.5 Coder 1.5B: be conservative, prefer simple correct code,
do not add anything not requested.

TASK: Implement a YAML config loader using the YamlDotNet library.

FILES TO CREATE: exactly ONE file: `ObfuscationConfig.cs`
Its namespace MUST be: `Bench.Task1`

The file must contain ALL of these types, exactly as specified.

WRITE THE IMPLEMENTATION FIRST. Start the file with the ConfigLoader
class below (with its usings), THEN append the record types after it.

Your file MUST start with these EXACT using lines, in this order:
```csharp
using System.Text.RegularExpressions;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;
```

```csharp
namespace Bench.Task1;

public sealed class ConfigLoader
{
    public ObfuscationConfig Load(string yaml)
    {
        // use YamlDotNet to deserialize yaml into ObfuscationConfig
    }
}
```

Then, AFTER the ConfigLoader class, append these record types verbatim:

```csharp
public sealed class ObfuscationConfig
{
    public ConnectionInfo Connection { get; set; } = new();
    public ObfuscationSettings Obfuscation { get; set; } = new();
}

public sealed class ConnectionInfo
{
    public string Token { get; set; } = "";
    public string BaseUrl { get; set; } = "";
}

public sealed class ObfuscationSettings
{
    public bool Enabled { get; set; }
    public List<PatternRule> Patterns { get; set; } = new();
}

public sealed class PatternRule
{
    public string Name { get; set; } = "";
    public string Regex { get; set; } = "";
    public string Replacement { get; set; } = "";
}
```

CLASS CHECKLIST — your output file MUST contain exactly these FIVE
classes, in this order: ConfigLoader, ObfuscationConfig, ConnectionInfo,
ObfuscationSettings, PatternRule. Before you close the fenced block,
count them and confirm all five are present. The ConfigLoader class MUST
be present in your output. Do not stop early — the file is not complete
until all five classes exist.

BEHAVIOR CONTRACT (must hold exactly):
1. Load a YAML document shaped like:
   ```yaml
   connection:
     token: "abc123"
     baseUrl: "https://api.example.com"
   obfuscation:
     enabled: true
     patterns:
       - name: email
         regex: "\\b[\\w.+-]+@[\\w-]+\\.[\\w.]+\\b"
         replacement: "[EMAIL]"
   ```
2. If `token` or `baseUrl` is missing or empty (whitespace counts as
   empty), throw `InvalidOperationException`. The empty-string check MUST
   use `string.IsNullOrWhiteSpace` — checking `== null` is NOT enough.
   Use EXACTLY this validation logic after deserializing:
   ```csharp
   if (config is null || config.Connection is null
       || string.IsNullOrWhiteSpace(config.Connection.Token)
       || string.IsNullOrWhiteSpace(config.Connection.BaseUrl))
   {
       throw new InvalidOperationException("Invalid YAML or missing connection details.");
   }
   ```
3. If the YAML is malformed and cannot be parsed, throw any exception
   (the test only asserts that an exception is thrown).
4. If the `obfuscation` section is absent entirely, `Enabled` must be
   `false` and `Patterns` must be an empty list.

HINT: YamlDotNet property matching is case-sensitive and the YAML keys are
camelCase. Use:
`new DeserializerBuilder().IgnoreUnmatchedProperties().WithNamingConvention(CamelCaseNamingConvention.Instance).Build()`
(import `YamlDotNet.Serialization` and
`YamlDotNet.Serialization.NamingConventions`), then call
`.Deserialize<ObfuscationConfig>(yaml)`. If deserialization returns null
or the connection is null, treat that as an error.

OUTPUT FORMAT: output ONLY the complete contents of the single file
`ObfuscationConfig.cs` inside one fenced code block starting with
```csharp and ending with ```. No explanations, no other text.
