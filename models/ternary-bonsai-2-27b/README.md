# ternary-bonsai-2-27b — steering profile

Model file: `Ternary-Bonsai-2-27B-PTQ1_0.gguf` (Prism ML, Apache 2.0). A ternary build of Qwen3.8-27B, weights {-1, 0, +1} with one FP16 scale per 128 weights, 1.75 bits per weight, 5.95 GB. Background, file choice and the network audit of the fork: `ai-stack/docs/ternary-bonsai-2-27b.md`.

**Role: all 6 report.sh roles** (`tasks/doc-*`, `tasks/reason-*`, `tasks/tool-*`, `tasks/extract-*`, `tasks/review-*`, `tasks/code-*`), first tested 2026-09-25.

## Overview

| Role | Status | Pass rate (bare → current) | vs. mainstream LLM | Details |
|---|---|---|---|---|
| Documenter | 🔬 Preliminary — 2 real failures, 1 verifier false fail | 7/10 bare | Not assessed | [Documenter role](#documenter-role-preliminary) |
| Reasoner | 🔬 Preliminary — thinking low, 1 real failure, 1 runaway, 1 verifier false fail | 7/10 bare | Not assessed | [Reasoner role](#reasoner-role-preliminary) |
| Tool-use | 🔬 Preliminary — clean bare pass | 10/10 bare | Not assessed | [Tool-use role](#tool-use-role-preliminary) |
| Extract | 🔬 Preliminary — clean bare pass | 10/10 bare | Not assessed | [Extract role](#extract-role-preliminary) |
| Review | 🔬 Preliminary — clean bare pass | 10/10 bare | Not assessed | [Review role](#review-role-preliminary) |
| Code-emitter | 🔬 Preliminary — clean bare pass | 14/14 bare | Not assessed | [Code-emitter role](#code-emitter-role-preliminary) |

All results are single draws, not reliability samples.

## Setup

- Host: `legion-t5` (RTX 3060 Ti, 8 GB). The mainline builds on both LLM hosts refuse `PTQ1_0`. Use the PrismML fork in `/opt/llama.cpp-prism/` (release `prism-b10709-9a9394a`).
- The fork CUDA tarball has no `libcudart`/`libcublas`. Start it with `LD_LIBRARY_PATH=/opt/llama.cpp-prism:/opt/llama.cpp`.
- Free the GPU first: stop `llama-embed` and `llama-rerank` (together 7.4 GB). Start them again after the test.
- Test server, as a transient user unit:
  `systemd-run --user --unit=bonsai-test --setenv=LD_LIBRARY_PATH=/opt/llama.cpp-prism:/opt/llama.cpp /opt/llama.cpp-prism/llama-server --model /opt/models/ternary-bonsai-2-27b-ptq1_0.gguf --alias ternary-bonsai-2:27b --host 0.0.0.0 --port 11500 -ngl 99 -fa on -c 32768 --cache-type-k q8_0 --cache-type-v q8_0 --parallel 1 --jinja --offline`
- `ufw` on legion-t5 blocks port 11500. Reach it with `ssh -f -N -L 11500:localhost:11500 legion`, then `bash bench/report.sh ternary-bonsai-2:27b <role> llamacpp 11500 localhost`.
- Thinking control: the chat template defaults to thinking ON at `xhigh`. `DISPATCH_ENABLE_THINKING=false` turns it off. `DISPATCH_REASONING_EFFORT=low` reaches the template (the prompt grows by the low-effort sentence). The template accepts only `low`, `medium` and `xhigh`.
- Each report's hardware line records the thinking mode of that run.

## Gotchas

- **Special llama.cpp build required.** Mainline llama.cpp refuses `PTQ1_0`. Use the PrismML fork (release `prism-b10709-9a9394a` or newer) in `/opt/llama.cpp-prism/`. Never replace `/opt/llama.cpp`, the production services use it.
- **Gibberish means the wrong binary.** Mainline has no Hadamard transform. A Bonsai 2 `Q2_0` file loads there but gives gibberish.
- **The fork CUDA tarball has no CUDA runtime.** Error: `libcudart.so.12: cannot open shared object file`. Fix: `LD_LIBRARY_PATH=/opt/llama.cpp-prism:/opt/llama.cpp`.
- **Thinking is ON at `xhigh` by default.** Set `DISPATCH_ENABLE_THINKING=false` for every role. The template accepts only `low`, `medium` and `xhigh`.
- **Thinking `low` can run away.** 2 of 10 reason tasks used more than 15,000 tokens. `reason-checklist` gave no answer after 16,384 tokens and 9 minutes, and passed with thinking off.
- **`speed-test.sh` needs the fork binary.** Use `SPEED_TEST_BIN=/opt/llama.cpp-prism/llama-bench SPEED_TEST_EXTRA_LIBS=/opt/llama.cpp`.
- **`report.sh` cannot restart this server.** It is a transient unit, not a `llama-*` unit, so the mandatory restart is skipped with a warning. Restart `bonsai-test` by hand before a long run.
- **Port 11500 is blocked by `ufw`.** A direct request hangs. Use the SSH tunnel from Setup.
- **Free the GPU first.** On legion-t5, stop `llama-embed` and `llama-rerank`, and start them again after the test.
- **Vulkan generation is slow.** On the R9700 the fork generates 9.2 tok/s, against 35.1 tok/s on the 3060 Ti. Prefill is fine. See the performance section.
- **Neither host has a mainline `llama-bench`.** Use the fork's `llama-bench` for every model. It is mainline plus the Bonsai types.
- **`Linger=no` for peppe on gaming-b650.** A `systemd-run --user` unit stops when the SSH session ends. Run a test server in the same SSH call as the test.

## Documenter role: preliminary

7/10 PASS, bare, thinking OFF, single draw.

| Task | Result | Cause |
|---|---|---|
| `doc-verbatim` | FAIL | One added blank line in a verbatim copy. Content correct. |
| `doc-script` | FAIL | Deleted the EDIT 1 target line instead of replacing it, and dropped `LOG_FILE="$(mktemp)"`. |
| `doc-audience` | FAIL (verifier) | The output states fact 3 as "can never match". The verifier list has only "cannot match". |

## Reasoner role: preliminary

7/10 PASS, bare, thinking `low`, single draw. The 3 tasks that both qwen3.8-27b builds failed at `low` (`reason-config-validity`, `reason-multihop`, `reason-tradeoff`) pass.

| Task | Result at low | Tokens | Result at OFF |
|---|---|---|---|
| `reason-checklist` | FAIL, runaway thinking, truncated at 16,384 tokens (9 min) | 16,384 | PASS, 432 tokens, 13 s |
| `reason-consequence` | FAIL, names the right mechanism, then gives the wrong value for `owner.name` | 15,184 | not run |
| `reason-coverage` | FAIL (verifier): backticks in "no `owner`" break the regex | 3,285 | not run |

Thinking `low` is not safe for this model without a token cap: 2 of 10 tasks used more than 15,000 tokens. Normal tasks at `low` used 373 to 2,730 tokens.

## Tool-use role: preliminary

10/10 PASS, bare, thinking OFF, single draw. 26 to 202 completion tokens per task.

## Extract role: preliminary

10/10 PASS, bare, thinking OFF, single draw.

## Review role: preliminary

10/10 PASS, bare, thinking OFF, single draw.

## Code-emitter role: preliminary

14/14 PASS, bare, thinking OFF, single draw (12 C# + 2 Python tasks), real compile and test via `bench.sh`.

## Performance (measured 2026-09-25)

`legion-t5`, RTX 3060 Ti 8 GB, fork build 10709, `-ngl 99 -fa on`, q8_0 KV cache. Raw GPU power samples: [`power/2026-09-25/`](power/2026-09-25/).

| Value | Result |
|---|---|
| llama-bench pp512 | 354.05 ± 2.10 tok/s |
| llama-bench tg128 | 35.14 ± 0.10 tok/s |
| Generation in the test tasks | 33 to 34.6 tok/s (30.7 tok/s at 15,000+ tokens) |
| Prefill in the test tasks (200 to 1,000 tokens) | 229 to 337 tok/s |
| GPU power, llama-bench busy | mean 183 W, max 200 W (500 ms samples, `nvidia-smi`) |
| GPU power, idle | 10 W |
| VRAM, `-c 32768` | 7,096 of 7,841 MiB |
| VRAM, `-c 16384` | 6,472 MiB |
| Model load | about 6 s |
| Full test, 64 tasks | 30 minutes (5 roles OFF: 7 minutes, reason at low: 23.5 minutes) |

Comparison with `qwen3.8-27b-gsq-rco` (IQ3_S, 12.1 GB) on gaming-b650 (R9700, 32 GB): generation 38.7 to 38.9 tok/s at 296 to 299 W. Bonsai gives about 90 % of that speed on a 8 GB card, at about 62 % of the GPU power. The GPU power is from different sensors on different cards, so read it as a rough ratio. No wall-power or EUR measurement for this model yet.

### RTX 3060 Ti (CUDA) against R9700 (Vulkan), measured 2026-09-25

Same fork build 10709, same `llama-bench` settings (`-ngl 99 -fa 1 -ctk q8_0 -ctv q8_0`, pp512, tg128, 5 repeats). On gaming-b650 `llama-chat` was stopped, so nothing else ran on the R9700. Raw data and the run script: [`power/2026-09-25/`](power/2026-09-25/).

| Value | RTX 3060 Ti 8 GB, CUDA | R9700 32 GB, Vulkan | R9700 against 3060 Ti |
|---|---|---|---|
| pp512 | 354.05 ± 2.10 tok/s | 546.20 ± 0.56 tok/s | 1.54 x |
| tg128 | 35.14 ± 0.10 tok/s | 9.18 ± 0.07 tok/s | **0.26 x** |
| GPU power, llama-bench | mean 183 W | mean 289 W (300 W cap) | |
| HTTP generation, thinking off | 34.9 tok/s | 9.1 tok/s | |
| Maximum context, alone on the card | 32,768 (7.1 of 7.8 GB) | 262,144 (17.8 GB free after load) | |
| Maximum context next to `llama-chat` with 1 slot, 1.5 GB kept free | – | 110,592 (1,606 MiB free) | |

- **Generation on Vulkan is 3.8 times slower than on the 3060 Ti, at 1.6 times the power.** The output is correct: the thinking-off answer is word for word the same on both cards. The prefill is faster on Vulkan. So the slow part is the `PTQ1_0` matrix-vector path in the Vulkan backend of the fork, which is new (branch `fix/ptq1_0-vulkan-supports-op`). The same R9700 generates 38.8 tok/s with the 27B GSQ-RCO model on mainline.
- A first run with `llama-chat` busy on a 68,000-token prompt gave tg128 4.75 tok/s and pp512 325 tok/s. That run is not valid. Its power log is kept as `r9700-llama-bench-power-shared-with-llama-chat.log`.
- Verdict: on the R9700, Bonsai 2 is not useful today. Use the 3060 Ti (CUDA), or wait for a faster Vulkan kernel in the fork.

## How to optimize (verify before trusting)

1. Fix the 2 verifier false fails first (`doc-audience`, `reason-coverage`), then re-verify the saved outputs in `raw/`. Check the other models' saved outputs against the new rule too.
2. Run 3 draws of every role with `bench/confirm.sh` before any status moves past Preliminary.
3. Run the reason role with thinking OFF, 3 draws, to get the same-task OFF vs LOW comparison.
4. For `doc-script`: steer only after 3 draws show the same failure.

Full narrative: `history.md`'s "2026-09-25: first full test on legion-t5".

## Further reading

- `history.md`: the run narrative and new idioms.
- `reports/`: one report per role, with Findings.
- `raw/`: saved raw outputs, including `reason-checklist` at low and at OFF.
- `ai-stack/docs/ternary-bonsai-2-27b.md`: file choice, fork install and network audit.
- `../qwen3.8-27b-gsq-rco/README.md`: the base model at IQ3_S, for comparison.
