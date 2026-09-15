```json
{ "bugs": [
  { "line": "var hasMore = all.Count <= start + pageSize;", "issue": "the condition is backwards -- HasMore should be true when there ARE more items beyond this page (all.Count > start + pageSize), but <= makes it true exactly when there are not." },
  { "line": "return company.DefaultContact.Name;", "issue": "DefaultContact is documented as optional, and this throws a NullReferenceException whenever a company has no DefaultContact." }
] }
```
