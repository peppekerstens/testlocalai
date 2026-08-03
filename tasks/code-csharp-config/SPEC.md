TASK: YAML config loader, YamlDotNet.
FILE: one file `ObfuscationConfig.cs`. Namespace: `Bench.Task1`.

File MUST start with these EXACT using lines, in order:
```csharp
using System.Text.RegularExpressions;
using YamlDotNet.Serialization;
using YamlDotNet.Serialization.NamingConventions;
```

WRITE IMPLEMENTATION FIRST: ConfigLoader class below with EXACTLY this Load method body, THEN append record types.

```csharp
namespace Bench.Task1;

public sealed class ConfigLoader
{
    public ObfuscationConfig Load(string yaml)
    {
        var deserializer = new DeserializerBuilder()
            .IgnoreUnmatchedProperties()
            .WithNamingConvention(CamelCaseNamingConvention.Instance)
            .Build();
        var config = deserializer.Deserialize<ObfuscationConfig>(yaml);
        if (config is null || config.Connection is null
            || string.IsNullOrWhiteSpace(config.Connection.Token)
            || string.IsNullOrWhiteSpace(config.Connection.BaseUrl))
        {
            throw new InvalidOperationException("Invalid YAML or missing connection details.");
        }
        return config;
    }
}
```

AFTER ConfigLoader, append these record types verbatim:

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

CLASS CHECKLIST: output MUST contain exactly these FIVE classes in this order: ConfigLoader, ObfuscationConfig, ConnectionInfo, ObfuscationSettings, PatternRule. Count all five before closing the fenced block. ConfigLoader MUST be present. Do not stop early.

BEHAVIOR (must hold exactly):
1. Load YAML shaped like:
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
2. If `token` or `baseUrl` missing or empty (whitespace counts empty), throw `InvalidOperationException`. Empty check MUST use `string.IsNullOrWhiteSpace` — `== null` is NOT enough. Use EXACTLY this validation after deserializing:
   ```csharp
   if (config is null || config.Connection is null
       || string.IsNullOrWhiteSpace(config.Connection.Token)
       || string.IsNullOrWhiteSpace(config.Connection.BaseUrl))
   {
       throw new InvalidOperationException("Invalid YAML or missing connection details.");
   }
   ```
3. Malformed YAML -> throw any exception (test only asserts an exception is thrown).
4. If `obfuscation` section absent entirely, `Enabled` must be `false`, `Patterns` empty list.

HINT: YamlDotNet property matching case-sensitive; YAML keys camelCase. Use:
`new DeserializerBuilder().IgnoreUnmatchedProperties().WithNamingConvention(CamelCaseNamingConvention.Instance).Build()`
(imports YamlDotNet.Serialization + YamlDotNet.Serialization.NamingConventions), then `.Deserialize<ObfuscationConfig>(yaml)`. Null result or null connection = error.

OUTPUT: ONLY complete `ObfuscationConfig.cs` in one fenced ```csharp block. No explanations, no other text.
