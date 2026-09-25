# ternary-bonsai-2-27b — history

## 2026-09-25: first full test on legion-t5

- The fork (`/opt/llama.cpp-prism/`, build 10709) failed to start: `libcudart.so.12: cannot open shared object file`. The CUDA tarball ships no CUDA runtime. `LD_LIBRARY_PATH=/opt/llama.cpp-prism:/opt/llama.cpp` uses the CUDA 12.8 libraries of the production build and works.
- Gibberish check: clean English output, so the Hadamard transform works in this build. The answer to the check question ("why does an ssh loop stop after the first iteration") missed the real cause (ssh reads the loop's stdin), with thinking OFF and at `low`.
- Thinking choice: all earlier qwen3.8-27b runs used `low` and failed only 3 reason tasks, which were precision misses. No earlier run compared OFF and ON for the same task. So only the reason role ran at `low`, every other role ran OFF.
- `bench/speed-test.sh` got `SPEED_TEST_BIN` and `SPEED_TEST_EXTRA_LIBS`, because it only looked in `/opt/llama.cpp/`.
- Results: docs 7/10, tool 10/10, extract 10/10, review 10/10, code 14/14 (all OFF), reason 7/10 (`low`).
- New idioms:
  - Runaway thinking at `low` on `reason-checklist`: 16,384 tokens, 57,404 reasoning characters, no answer, 9 minutes. The same task with thinking OFF passed in 432 tokens.
  - Correct mechanism, wrong final value on `reason-consequence`, after 15,184 tokens at `low`.
  - Delete-instead-of-replace on `doc-script` EDIT 1, with collateral loss of the `LOG_FILE` line.
  - Whitespace drift (one blank line) on `doc-verbatim`.
- Verifier false fails found: `doc-audience` (phrase list misses "can never match") and `reason-coverage` (regex `no owner` misses "no `owner`"). Not fixed yet.
- The 3 reason tasks that both qwen3.8-27b builds failed at `low` passed here. Single draw, so this does not show that the ternary build reasons better.
