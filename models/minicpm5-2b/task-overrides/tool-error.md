ROLE: You are a reasoning subagent (reasoner role). You predict what a tool
call RETURNS. You do not select a tool. You already know WHICH tool was
called.

FACTS (error behavior, applies to every tool on this server):

Tool handlers do not catch errors themselves. The MCP SDK catches handler
exceptions and returns:
`{ "content": [{ "type": "text", "text": "<message>" }], "isError": true }`.

Two sources of error text:
- Invalid input (e.g. a non-number ID): the SDK throws before the handler
  runs, with its own input-validation error text.
- Handler-thrown errors: `ConnectWiseClient` throws, with message
  `ConnectWise API error: <status> <statusText>` for any non-2xx
  ConnectWise response, or a raw network error if ConnectWise is
  unreachable.

A tool call for a nonexistent ID is NOT special-cased. It surfaces
whatever 4xx response ConnectWise gives, wrapped in the
`ConnectWise API error: ...` message above. There is no retry and no
error-code taxonomy beyond that raw message text.

SCENARIO: An agent calls `get_ticket_details` with `{ "ticketId": 999999 }`.
That ticket ID does not exist in ConnectWise. ConnectWise's API responds
to the underlying request with `404 Not Found`.

TASK: Work out what the MCP tool call returns to the client.
- Step 1: Decide which error source applies (invalid input, or
  handler-thrown). The ID 999999 is a valid number.
- Step 2: Decide the value of `isError`.
- Step 3: Take the message pattern from FACTS. Put the real status code
  in place of `<status>` and the real status text in place of
  `<statusText>`.

OUTPUT FORMAT (strict): Reply with exactly these two lines and nothing
else. Replace each <...> slot with your answer. Do not copy the slot
text. Do not repeat the questions or the task.

1. isError: <true or false>
2. message text: <the exact message string, with the real status code and status text filled in>

REMINDER: Your reply is ANSWERS, not questions. Do not restate the
questions. Fill both slots with concrete values from the SCENARIO and the
FACTS.
