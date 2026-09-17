# Bench report: code-csharp-tool (round pure-20260917-101048)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-csharp-tool/rounds/prompt-pure-20260917-101048.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: bare SPEC.md (current best)
- Tokens: 567 prompt / 941 completion

## VERDICT: TEST FAIL
[xUnit.net 00:00:00.17]     Bench.Task5.TicketToolTests.GetTicketReturnsNullForUnknownId [FAIL]
[xUnit.net 00:00:00.18]     Bench.Task5.TicketToolTests.GetTicketReturnsTextForKnownId [FAIL]
[xUnit.net 00:00:00.19]     Bench.Task5.TicketToolTests.ResolvesTicketToolFromDi [FAIL]
