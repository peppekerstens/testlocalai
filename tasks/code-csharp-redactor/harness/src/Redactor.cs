using System.Text.RegularExpressions;
using System.Collections.Generic;

namespace Bench.Task6;

public sealed class PatternRule
{
    public string Name { get; set; } = "";
    public string Regex { get; set; } = "";
    public string Replacement { get; set; } = "";
}

public sealed class Redactor
{
    public string Redact(string input, IReadOnlyList<PatternRule> rules)
    {
        if (string.IsNullOrEmpty(input))
        {
            return string.Empty;
        }

        if (rules == null || rules.Count == 0)
        {
            return input;
        }

        string result = input;
        foreach (var rule in rules)
        {
            try
            {
                result = Regex.Replace(result, rule.Regex, rule.Replacement);
            }
            catch (ArgumentException)
            {
                // Skip invalid regex
            }
        }

        return result;
    }
}
