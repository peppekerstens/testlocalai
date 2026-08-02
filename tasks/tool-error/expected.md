1. `isError` is `true`. The nonexistent ticket ID is not special-cased, so
   this surfaces as a normal handler-thrown error, same as any other
   non-2xx ConnectWise response.
2. The message text is `ConnectWise API error: 404 Not Found` (the
   `ConnectWise API error: <status> <statusText>` pattern with `404` and
   `Not Found` substituted in), returned inside
   `{ "content": [{ "type": "text", "text": "ConnectWise API error: 404 Not Found" }], "isError": true }`.
