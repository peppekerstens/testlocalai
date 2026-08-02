```json
{ "bugs": [ { "line": "output.DefaultContactName = company.DefaultContact.Name;", "issue": "DefaultContact is documented as optional (ConnectWise may not return it), but it's accessed directly without a null check or the ?. operator — throws NullReferenceException whenever a company has no default contact." } ] }
```
