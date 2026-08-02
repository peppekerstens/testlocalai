# Error behavior (C# port)

Tool handlers do not catch errors themselves. Exceptions thrown by a handler
(or by input validation) are caught by the C# MCP host, which returns a
single MCP content item with the error shape below.

```json
{ "content": [{ "type": "text", "text": "<message>" }], "isError": true }
```

- **Invalid input** (e.g. `companyId` not a number): the host throws before
  the handler runs, with a message naming the tool and the validation
  failure.
- **Handler-thrown errors**: the C# `ConnectWiseClient` throws
  `HttpRequestException` with message `ConnectWise API error: <status>
  <statusText>` for any non-2xx ConnectWise response, or an
  `HttpRequestException` wrapping the network failure when ConnectWise is
  unreachable. Both propagate to the client as the `isError: true` shape
  above — there is no retry and no error-code taxonomy.
