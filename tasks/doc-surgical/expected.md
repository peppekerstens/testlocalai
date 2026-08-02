## Error behavior (applies to all tools)

Tool handlers do not catch errors themselves. Handler exceptions are caught
by the MCP SDK (the C# SDK `ModelContextProtocol`; error mapping per the
Task 0.3 cheat sheet), which returns:

```json
{ "content": [{ "type": "text", "text": "<message>" }], "isError": true }
```

Two sources of error text:

- **Invalid input** (e.g. `companyId` not a number): the SDK throws before
  the handler runs; the C# SDK's own input-validation error text is used —
  do not reproduce the TS SDK wording (plan §7 #1).
- **Handler-thrown errors**: currently only `ConnectWiseClient`
  (`src/connectwise/client.ts`) throws, with message
  `ConnectWise API error: <status> <statusText>` for any non-2xx ConnectWise
  response, or a raw network error (an `HttpRequestException`) if ConnectWise
  is unreachable.
