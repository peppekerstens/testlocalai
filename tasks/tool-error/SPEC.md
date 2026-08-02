ROLE: You are a reasoning subagent (reasoner role) predicting tool call
BEHAVIOR, not selecting a tool. You already know WHICH tool was called —
your job is to predict exactly what it returns.

FACTS (error behavior, applies to every tool on this server):

Tool handlers do not catch errors themselves. Handler exceptions are
caught by the MCP SDK, which returns:
`{ "content": [{ "type": "text", "text": "<message>" }], "isError": true }`.

Two sources of error text:
- Invalid input (e.g. a non-number ID): the SDK throws before the handler
  runs, with its own input-validation error text.
- Handler-thrown errors: `ConnectWiseClient` throws, with message
  `ConnectWise API error: <status> <statusText>` for any non-2xx
  ConnectWise response, or a raw network error if ConnectWise is
  unreachable.

A tool call for a nonexistent ID (e.g. `get_ticket_details` with a
`ticketId` that doesn't exist) is NOT special-cased — it surfaces whatever
ConnectWise's own 4xx response produces, wrapped in the
`ConnectWise API error: ...` message above. There is no retry and no
error-code taxonomy beyond that raw message text.

SCENARIO: An agent calls `get_ticket_details` with `{ "ticketId": 999999 }`
— a ticket ID that does not exist in ConnectWise. ConnectWise's API
responds to the underlying request with `404 Not Found`.

QUESTION: What does the MCP tool call actually return to the client?
Answer these two things explicitly:
1. Is `isError` true or false in the response?
2. What is the exact shape/wording of the error message text (not a vague
   paraphrase — use the actual message pattern from the facts above, with
   the real status code and status text substituted in)?

OUTPUT: your answer to both questions, nothing else.
