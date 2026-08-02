EXACT LAYOUT — read before answering:

These two lines from the source must appear ADJACENT in your output,
with NO blank line between them:
  | `customFields` | [CustomFieldsRule](#customfieldsrule) | no | Omit to disable custom-field exclusion entirely. |
  > Note: in the C# port, validation of this schema is implemented in `ObfuscationConfigLoader` (startup fail-fast), not in a runtime schema library.

Every OTHER section break in the source (heading→fence, fence→table)
keeps its own blank line exactly as shown in the source below — only
the pair above has no blank line between them.

The closing ` ``` ` fence goes immediately after the fourth YAML line
(after the `customFields: { ... }` line), never at the end of your
output. Copy the `> ` line's leading `> ` exactly.
