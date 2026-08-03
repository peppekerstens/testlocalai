using Xunit;

namespace Bench.Task1;

public class ConfigLoaderTests
{
    private const string ValidYaml = """
        connection:
          token: "abc123"
          baseUrl: "https://api.example.com"
        obfuscation:
          enabled: true
          patterns:
            - name: email
              regex: "\\b[\\w.+-]+@[\\w-]+\\.[\\w.]+\\b"
              replacement: "[EMAIL]"
        """;

    [Fact]
    public void LoadsValidYaml()
    {
        var loader = new ConfigLoader();
        var cfg = loader.Load(ValidYaml);
        Assert.Equal("abc123", cfg.Connection.Token);
        Assert.Equal("https://api.example.com", cfg.Connection.BaseUrl);
        Assert.True(cfg.Obfuscation.Enabled);
        var p = Assert.Single(cfg.Obfuscation.Patterns);
        Assert.Equal("email", p.Name);
        Assert.Equal("[EMAIL]", p.Replacement);
    }

    [Fact]
    public void MissingTokenThrows()
    {
        var loader = new ConfigLoader();
        var yaml = ValidYaml.Replace("token: \"abc123\"", "token: \"\"");
        Assert.Throws<InvalidOperationException>(() => loader.Load(yaml));
    }

    [Fact]
    public void MissingBaseUrlThrows()
    {
        var loader = new ConfigLoader();
        var yaml = ValidYaml.Replace("baseUrl: \"https://api.example.com\"", "baseUrl: \"\"");
        Assert.Throws<InvalidOperationException>(() => loader.Load(yaml));
    }

    [Fact]
    public void WhitespaceOnlyTokenThrows()
    {
        // The SPEC requires string.IsNullOrWhiteSpace, not just an empty-string
        // check — a whitespace-only token must be rejected the same as "".
        var loader = new ConfigLoader();
        var yaml = ValidYaml.Replace("token: \"abc123\"", "token: \"   \"");
        Assert.Throws<InvalidOperationException>(() => loader.Load(yaml));
    }

    [Fact]
    public void MalformedYamlThrows()
    {
        var loader = new ConfigLoader();
        Assert.ThrowsAny<Exception>(() => loader.Load("connection: [unclosed"));
    }

    [Fact]
    public void DefaultsWhenObfuscationSectionAbsent()
    {
        var loader = new ConfigLoader();
        var cfg = loader.Load("""
            connection:
              token: "t1"
              baseUrl: "https://x.example"
            """);
        Assert.False(cfg.Obfuscation.Enabled);
        Assert.Empty(cfg.Obfuscation.Patterns);
    }
}
