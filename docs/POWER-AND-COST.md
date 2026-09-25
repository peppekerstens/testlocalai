# Local LLM power, performance and cost (measured 2026-09-17)

Date: 2026-09-17, 08:50 to 09:11 CEST
Hosts: gaming-b650 (qwen3.8-27b), legion-t5 (qwen3.5-4b-gsq)
Scripts: [`bench/power/`](../bench/power/). Raw data: [`models/qwen3.8-27b-gsq-rco/power/2026-09-17/`](../models/qwen3.8-27b-gsq-rco/power/2026-09-17/) and [`models/qwen3.5-4b-gsq/power/2026-09-17/`](../models/qwen3.5-4b-gsq/power/2026-09-17/).

## Summary

| Value | gaming-b650, qwen3.8-27B IQ3_S | legion-t5, qwen3.5-4B Q2_K_XL |
|---|---|---|
| Generation speed | 38.7 to 38.9 tok/s | 102.8 to 103.1 tok/s (reasoning off) |
| Prefill speed (12k-token prompt) | 942 to 954 tok/s | 2,418 to 2,434 tok/s |
| GPU power, generation | 296 to 299 W (cap 300 W) | 195 to 199 W (limit 200 W) |
| GPU power, prefill | 284 to 289 W | 183 to 192 W |
| CPU package power under load | 28 W | 14 W |
| Idle power, GPU + CPU package | 8 to 11 W + 20 W | 10 to 12 W + 3 W |
| Output cost, wall estimate (energy only) | **EUR 0.80 per 1M tokens** | **EUR 0.20 per 1M tokens** |
| Input cost, wall estimate (energy only) | **EUR 0.032 per 1M tokens** | **EUR 0.008 per 1M tokens** |
| Output cost, GPU + CPU sensors only | EUR 0.65 per 1M tokens | EUR 0.16 per 1M tokens |
| Input cost, GPU + CPU sensors only | EUR 0.026 per 1M tokens | EUR 0.007 per 1M tokens |

Price: EUR 0.28 per kWh. The "wall estimate" adds a fixed rest-of-system load and a PSU loss (see Method).

> **Energy cost only, not the total cost of ownership (TCO).** All EUR values in this report are the electricity cost during inference. They do not include the hardware purchase and write-off, idle power, or other ownership costs. The values are incomplete as a cost of local inference. See [What the cost values do not include](#what-the-cost-values-do-not-include).

Main findings:

1. **The context size has no effect** on speed, power or output for prompts up to 12k tokens. Every completed request gave a byte-identical answer at all 3 context sizes on both hosts.
2. **Yesterday's input cost was 9 times too high.** Heavy parallel load made prefill slow: 117 tok/s then, 945 tok/s now. Generation speed did not change (38.5 then, 38.8 now).
3. **Reasoning does not change the cost per token.** It changes the number of tokens per task. On gaming-b650, the same DNS essay took 1,756 tokens with reasoning off and 4,292 tokens with xhigh. That is 2.4 times the energy.
4. **Reasoning on legion-t5 is a risk.** With reasoning on, the 4B model reasoned for more than 9,200 tokens on the needle task and gave no answer before the 120 s limit. This happened at all 3 context sizes.
5. **The 4B model is weak on long input.** With reasoning off, it found the 5 error codes in the 12k-token log in only 2 of 8 requests. One request looped until its 600-token cap.

## Why a new measurement

The 2026-09-16 measurement (opencode session `ses_f557a0d3affesWJ9FhhGLEaxP0`) ran while other LLM requests loaded both machines. This measurement removes that load:

- `litellm-router` on LXC 109 stopped from about 08:17 to 09:11. No client could reach the models through it.
- The load generator sent requests directly to `llama-server` on port 11434.
- One sequential request stream per host. Both hosts ran at the same time, because they share no hardware.
- Both servers had empty slots before each set.

## Method

### Hardware and server configuration

| | gaming-b650 | legion-t5 |
|---|---|---|
| CPU | AMD Ryzen 7 7800X3D, 16 threads | AMD Ryzen 5 5600G, 12 threads |
| GPU | AMD Radeon AI PRO R9700, 32 GB, Vulkan (RADV) | NVIDIA RTX 3060 Ti, 8 GB, CUDA |
| Model | qwen3.8-27b-gsq-rco IQ3_S (12.1 GB), mmproj loaded | qwen3.5-4b-gsq Q2_K_XL (1.9 GB) |
| Production flags | `--ctx-size 524288 --parallel 2 --no-kv-unified`, flash-attn, KV q8_0 | `--ctx-size 245760 --parallel 2 --kv-unified`, flash-attn, KV q8_0 |
| `n_ctx_train` | 262144 | 262144 |

Neither host uses a context above `n_ctx_train`, so the server applies no RoPE scaling at any tested size.

### Test matrix

| Host | `--ctx-size` (per slot) | Reasoning modes |
|---|---|---|
| gaming-b650 | 524288 (262144), production | off, low, medium, xhigh |
| gaming-b650 | 262144 (131072) | off, xhigh |
| gaming-b650 | 131072 (65536) | off, xhigh |
| legion-t5 | 245760 (245760, shared), production | off, on |
| legion-t5 | 122880 | off, on |
| legion-t5 | 61440 | off, on |

The qwen3.8 chat template supports `enable_thinking` false, plus `reasoning_effort` low, medium and xhigh (the default). The qwen3.5 template supports only thinking on or off. A check with `/apply-template` showed a different prompt for each mode.

For each context size, the sweep script wrote a systemd drop-in with the new `--ctx-size`, restarted `llama-chat`, waited for `/health`, and read `n_ctx` back from `/props`. At the end, it removed the drop-in and restored production. Both hosts run their production context again (checked at 09:11).

### Workload

- One mixed set of 120 s per mode. The requests alternate: gen task, prefill task, gen task.
- **Gen tasks** (about 40 to 100 input tokens), in a fixed order:
  0. DNS failure essay (open answer)
  1. Electricity cost calculation (exact answer 89.71)
  2. Proxmox backup design essay (open answer)
  3. Request timing calculation (exact answer 53.6)
- **Prefill task:** a 12,000-word log (about 12,085 tokens) with 5 hidden error codes. The model must list them in order. The answer is exact.
- Temperature 0.7, `seed = 42 + i`, `cache_prompt: false`, streaming.
- Request *i* has the same prompt and seed at every context size.
- **Output caps:** 4 times the upper estimate of a good answer.
  - Reasoning off: 10,000 / 2,400 / 12,000 / 2,400 tokens for tasks 0 to 3, and 600 for the needle task.
  - Reasoning on: 40,000 / 16,000 / 48,000 / 16,000 tokens, and 32,000 for the needle task.
  - A request that reaches its cap counts as a failure (`cap_failures`).
- **Hard stop:** at 120 s, the load generator closes the open request, and `llama-server` cancels it. A cut request is not a failure. Its streamed tokens and its power still count for speed and cost.
- 40 s idle baseline for each context size, and 10 s cool-down between modes.

### Power measurement

- A sampler on each host recorded data once each second, as root:
  - GPU power, busy %, VRAM and temperature: `amdgpu` hwmon `power1_average` (gaming-b650), `nvidia-smi` (legion-t5).
  - CPU package power from the RAPL energy counter (`intel-rapl:0`, which the AMD driver also uses).
  - CPU utilization and system memory.
- The streamed answer gives the time of the first token for each request:
  - Prefill window: from the request start to the first token.
  - Generation window: from the first token to the end of the request, or to the stop.
- The analysis integrates the power samples over each window.
- Input tokens come from `/tokenize` on the rendered template. Output tokens come from `timings.predicted_n`, or from the streamed token count for a cut request.
- Cost per 1M tokens = energy (J) / tokens x 10^6 / 3.6x10^6 x EUR 0.28.
- **Sensor values** use GPU + CPU package power only.
- **Wall estimate** = (GPU + CPU package + rest of system) / 0.90 PSU efficiency. Rest of system is 35 W for gaming-b650 and 25 W for legion-t5. These two values are estimates. No wall meter was available.

## Results: gaming-b650 (qwen3.8-27B)

### Speed, power and cost for each mode and context size

| ctx (per slot) | Mode | Requests | Completed | Cut | Cap failures | Correct | Prefill tok/s | Gen tok/s | GPU W prefill / gen | CPU W | GPU junction max | EUR/1M in (wall) | EUR/1M out (wall) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 262144 | off | 5 | 4 | 1 | 0 | 3/3 | 945 | 38.9 | 288 / 297 | 27.7 | 96 °C | 0.032 | 0.801 |
| 262144 | low | 5 | 4 | 1 | 0 | 3/3 | 925 | 38.7 | 284 / 297 | 27.7 | 99 °C | 0.032 | 0.805 |
| 262144 | medium | 4 | 3 | 1 | 0 | 2/2 | 954 | 38.7 | 289 / 297 | 27.8 | 99 °C | 0.032 | 0.805 |
| 262144 | xhigh | 2 | 1 | 1 | 0 | – | n/a * | 38.7 | n/a * / 299 | 28.5 | 99 °C | n/a * | 0.810 |
| 131072 | off | 5 | 4 | 1 | 0 | 3/3 | 942 | 38.9 | 287 / 296 | 27.8 | 96 °C | 0.032 | 0.801 |
| 131072 | xhigh | 2 | 1 | 1 | 0 | – | n/a * | 38.7 | n/a * / 299 | 28.4 | 100 °C | n/a * | 0.809 |
| 65536 | off | 5 | 4 | 1 | 0 | 3/3 | 953 | 38.8 | 289 / 296 | 27.8 | 96 °C | 0.032 | 0.803 |
| 65536 | xhigh | 2 | 1 | 1 | 0 | – | n/a * | 38.7 | n/a * / 299 | 28.4 | 100 °C | n/a * | 0.810 |

\* With xhigh, the first gen request took 111 s. The stop then cut the needle request during prefill, before its first token. The only prefill window is a 79-token prompt, which is too short for a valid value. `results.md` shows the invalid numbers (109 to 161 tok/s).

The junction temperature reaches 96 to 100 °C. Power and speed stay stable during the whole set, so the data shows no thermal throttling.

### Tokens and energy for each task (completed requests, production context)

| Task | Mode | Output tokens | Of which reasoning | Time | Energy (wall est.) | Cost | Result |
|---|---|---|---|---|---|---|---|
| DNS essay | off | 1,756 | 0 | 45.1 s | 5.0 Wh | EUR 0.0014 | – |
| DNS essay | low | 2,131 | 268 | 55.3 s | 6.1 Wh | EUR 0.0017 | – |
| DNS essay | medium | 2,711 | 576 | 70.3 s | 7.8 Wh | EUR 0.0022 | – |
| DNS essay | xhigh | 4,292 | 537 | 111.6 s | 12.4 Wh | EUR 0.0035 | – |
| Electricity calculation | off | 412 | 0 | 11.2 s | 1.2 Wh | EUR 0.0003 | correct |
| Electricity calculation | low | 300 | 167 | 8.5 s | 0.9 Wh | EUR 0.0003 | correct |
| Electricity calculation | medium | 472 | 344 | 12.7 s | 1.4 Wh | EUR 0.0004 | correct |
| Needle task (12k input) | off | 59 | 0 | 13.5 s | 1.5 Wh | EUR 0.0004 | correct (2/2) |
| Needle task (12k input) | low | 312 to 357 | 213 to 248 | 20.5 to 21.7 s | 2.3 Wh | EUR 0.0006 | correct (2/2) |
| Needle task (12k input) | medium | 371 | 276 | 22.1 s | 2.4 Wh | EUR 0.0007 | correct (1/1) |

Energy for each request = time x (GPU + CPU + 35 W) / 0.90, which is about 400 W for this host.

Prefill of the 12k-token prompt takes 12.0 s every time. With reasoning off, the needle task spends 89% of its time on input.

## Results: legion-t5 (qwen3.5-4B)

| ctx | Mode | Requests | Completed | Cut | Cap failures | Correct | Prefill tok/s | Gen tok/s | GPU W prefill / gen | CPU W | GPU temp max | EUR/1M in (wall) | EUR/1M out (wall) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 245760 | off | 17 | 16 | 1 | 1 | 5/12 | 2,432 | 102.8 | 190 / 196 | 14.0 | 72 °C | 0.008 | 0.197 |
| 245760 | on | 2 | 1 | 1 | 0 | – | 2,518 | 87.7 | 186 / 199 | 14.6 | 72 °C | 0.008 | 0.235 |
| 122880 | off | 17 | 16 | 1 | 1 | 5/12 | 2,434 | 102.8 | 192 / 195 | 14.1 | 72 °C | 0.008 | 0.197 |
| 122880 | on | 2 | 1 | 1 | 0 | – | 2,491 | 87.8 | 190 / 199 | 14.7 | 73 °C | 0.008 | 0.235 |
| 61440 | off | 17 | 16 | 1 | 1 | 5/12 | 2,418 | 103.1 | 192 / 196 | 14.0 | 72 °C | 0.008 | 0.197 |
| 61440 | on | 2 | 1 | 1 | 0 | – | 2,385 | 87.8 | 183 / 198 | 14.4 | 73 °C | 0.008 | 0.234 |

Details for reasoning off (the same at all 3 context sizes):

| Task | Output tokens | Time | Correct |
|---|---|---|---|
| DNS essay | 958 to 1,106 | 9.3 to 11.2 s | – |
| Backup essay | 1,038 to 1,302 | 10.3 to 13.1 s | – |
| Electricity calculation | 408 to 411 | 4.2 s | 2/2 |
| Timing calculation | 364 to 371 | 3.8 to 3.9 s | 1/2 (one answer 53.7) |
| Needle task (12k input) | 24 to 59, and one at the 600 cap | 4.8 to 11.1 s | 2/8, 1 cap failure |

With reasoning on, the DNS essay took 793 tokens in 7.9 s. The needle task then reasoned for 9,241 to 9,276 tokens without an answer until the 120 s stop. The mean generation speed of 87.7 tok/s in this mode is lower because that request grew to about 21k tokens of context. Generation gets slower as the context grows.

## Does the context size change behavior?

For this workload (prompts up to 12k tokens), no.

| Host | Mode | Comparison | Completed request pairs | Identical answers |
|---|---|---|---|---|
| gaming-b650 | off | 262144 vs 131072 and vs 65536 per slot | 4 + 4 | 8/8 |
| gaming-b650 | xhigh | 262144 vs 131072 and vs 65536 per slot | 1 + 1 | 2/2 |
| legion-t5 | off | 245760 vs 122880 and vs 61440 | 16 + 16 | 32/32 |
| legion-t5 | on | 245760 vs 122880 and vs 61440 | 1 + 1 | 2/2 |

- The answers are byte-identical, and the cut requests stopped at nearly the same token count.
- Speed differs by less than 0.5%, and power by less than 2%.
- The only real difference is memory:

| Host | ctx | VRAM used | VRAM free |
|---|---|---|---|
| gaming-b650 (32,624 MiB) | 524288 | 31,921 MiB | about 700 MiB |
| gaming-b650 | 262144 | 23,089 MiB | about 9.5 GB |
| gaming-b650 | 131072 | 18,673 MiB | about 13.9 GB |
| legion-t5 (8,192 MiB) | 245760 | 7,468 MiB | about 720 MiB |
| legion-t5 | 122880 | 4,828 MiB | about 3.3 GB |
| legion-t5 | 61440 | 3,508 MiB | about 4.6 GB |

What this test does not cover. These are other possible causes for the worse behavior that you noticed in practice:

1. **Long conversations near the slot limit.** Only prompts up to 12k tokens were tested. Quality at 100k+ tokens of real context is a different question.
2. **legion-t5 uses `--kv-unified`.** Two parallel requests share one 245,760-token pool, so one long session reduces the space for the other.
3. **No `max_tokens` in clients.** An earlier run without caps showed a loop of more than 22,000 tokens on legion-t5 (`aborted/raw-uncapped-0828/`). Reasoning on legion-t5 ran for more than 9,200 tokens on a simple task. A client without a token limit waits a long time for such a loop, and it looks like bad behavior.
4. **litellm fallbacks.** `qwen3.5-9b-last-resort` really serves the 4B model. A request that falls back gets a weaker model.

## Comparison with the 2026-09-16 measurement (under load)

| Value | 2026-09-16, under load | 2026-09-17, clean | Change |
|---|---|---|---|
| gaming-b650 prefill | 117 tok/s | 945 tok/s | 8.1 times faster |
| gaming-b650 generation | 38.5 tok/s solo, 35 with 2 parallel | 38.8 tok/s | the same |
| gaming-b650 GPU power | about 300 W | 296 to 299 W | the same |
| gaming-b650 input cost | EUR 0.23 per 1M (340 W basis) | EUR 0.026 sensor, EUR 0.032 wall est. | 9 times lower |
| gaming-b650 output cost | EUR 0.69 per 1M (340 W basis) | EUR 0.65 sensor, EUR 0.80 wall est. | about the same |
| legion-t5 output cost | EUR 0.18 per 1M (250 W guess) | EUR 0.16 sensor, EUR 0.20 wall est. | the estimate was close |
| legion-t5 prefill | unknown | 2,430 tok/s | new |

The 340 W basis of yesterday is GPU + CPU, so compare it with the sensor values.

## What the cost values do not include

The cost values in this report show only the electricity that the hosts use while they process requests. They are a lower limit, not the total cost of ownership (TCO). Do not compare them directly with cloud API prices, because a cloud price includes hardware, idle capacity and operations.

| Cost part | In this report | Note |
|---|---|---|
| Electricity during inference | yes | GPU + CPU package measured, rest of system and PSU loss estimated |
| Hardware purchase and write-off (GPU, host, PSU) | **no** | Usually the largest part when the hosts are not busy all day |
| Idle power when no request runs | **no** | The hosts run 24 hours a day. See the estimate below. |
| Hardware wear, repair and replacement | **no** | A GPU at 300 W and 96 to 100 °C junction ages faster |
| Cooling and room heat | **no** | |
| Network, UPS, disk space for models | **no** | |
| Time for setup, maintenance and steering tests | **no** | |
| Lower quality: retries, failed requests, cloud fallback | **no** | Example: legion-t5 found the error codes in only 2 of 8 requests |

### Idle power around the clock (estimate)

Based on the measured idle power, plus the same rest-of-system estimate and PSU loss as above. EUR 0.28 per kWh.

| Host | Idle power, wall estimate | Energy per day | Cost per day | Cost per year |
|---|---|---|---|---|
| gaming-b650 | about 72 W | 1.73 kWh | EUR 0.49 | about EUR 177 |
| legion-t5 | about 43 W | 1.04 kWh | EUR 0.29 | about EUR 107 |

This cost stays the same when no request runs. It is not in the cost per token.

### Hardware write-off per token (formula and example)

```
hardware cost per 1M tokens = purchase price / (write-off years x 365 x tokens per day / 1,000,000)
```

Example with **EUR 3,000 of hardware per host and a 5-year write-off**. These are placeholder values, not the real purchase price or write-off period. Output tokens only, one request stream:

| Host | Use of the day | Output tokens per day | Write-off per 1M output tokens | Energy cost per 1M output tokens (this report) |
|---|---|---|---|---|
| gaming-b650 | 100% | 3.35M | EUR 0.49 | EUR 0.80 |
| gaming-b650 | 25% | 0.84M | EUR 1.96 | EUR 0.80 |
| gaming-b650 | 10% | 0.34M | EUR 4.90 | EUR 0.80 |
| legion-t5 | 100% | 8.90M | EUR 0.18 | EUR 0.20 |
| legion-t5 | 25% | 2.22M | EUR 0.74 | EUR 0.20 |
| legion-t5 | 10% | 0.89M | EUR 1.85 | EUR 0.20 |

To use real values, replace EUR 3,000 and 5 years in the formula. The write-off scales in proportion to the price and in inverse proportion to the years. Even at 100% use, the write-off is close to the energy cost on legion-t5. At low use, it is larger on both hosts. With 2 busy slots, the tokens per day are about double, and the write-off per token is about half.

### Real use and total cost (2026-09-19)

These tables use the real traffic from `LiteLLM_SpendLogs` on LXC 109 for the 7 days before 2026-09-19. The cost values are from this report: inference energy (wall estimate), idle power for the hours without requests, EUR 0.28 per kWh. Busy time comes from the measured prefill and generation speeds, one request stream. The cloud fallback tiers are not included.

| Host | Tokens per day, in / out | Busy time per day |
|---|---|---|
| gaming-b650 (qwen3.8-27B) | 5.5M / 0.46M | about 5 h |
| legion-t5 (qwen3.5-4B) | 8.7M / 0.14M | about 1.4 h |

**Total cost with a placeholder write-off** (EUR 3,000 per host, 5 years, not the real purchase price):

| | gaming-b650 | legion-t5 |
|---|---|---|
| Inference energy per day | EUR 0.55 | EUR 0.10 |
| Idle energy per day (rest of the day) | EUR 0.39 | EUR 0.27 |
| Write-off per day | EUR 1.64 | EUR 1.64 |
| **Total per day** | **EUR 2.58** | **EUR 2.01** |
| **Per 1M output tokens** | **EUR 5.55** | **EUR 14.80** |
| Per 1M tokens, in + out together | EUR 0.43 | EUR 0.23 |

Each EUR 1,000 of hardware over 5 years adds EUR 1.18 per 1M output tokens on gaming-b650 and EUR 4.04 on legion-t5. legion-t5 costs more per output token because it is busy only about 6% of the day.

**Total cost without write-off** (inference energy + idle energy):

| | gaming-b650 | legion-t5 | Both hosts |
|---|---|---|---|
| Inference energy per day | EUR 0.55 | EUR 0.10 | EUR 0.65 |
| Idle energy per day | EUR 0.39 | EUR 0.27 | EUR 0.66 |
| **Total per day** | **EUR 0.94** | **EUR 0.37** | **EUR 1.31** |
| Total per month | EUR 28.60 | EUR 11.30 | EUR 39.90 |
| Total per year | EUR 343 | EUR 135 | EUR 478 |
| **Per 1M output tokens** | **EUR 2.02** (energy only: 0.80) | **EUR 2.73** (energy only: 0.20) | |
| Per 1M tokens, in + out together | EUR 0.16 | EUR 0.04 | |

Idle power is 41% of this cost on gaming-b650 and 74% on legion-t5. The idle cost stays the same when the traffic changes, so the cost per token goes down with more use. Both tables assume that the hosts run 24 hours a day only for LLM work. For comparison, the OpenCode Go cloud fallback costs a flat $10 per month.

### Value in litellm: 2 times the energy cost (decision 2026-09-19)

The litellm cost values are 2 times the measured energy cost. The uplift is a middle-ground share of idle power and hardware write-off. The hosts were not bought only for AI, so a full write-off is too high, and energy only is too low.

| litellm model | input_cost_per_token | output_cost_per_token | EUR per 1M, in / out |
|---|---|---|---|
| qwen3.8-27b-local, qwen3.8-27b-nothink | 0.000000064 | 0.0000016 | 0.064 / 1.60 |
| embed-local (Qwen3-Embedding, legion-t5 GPU) | 0.0000000037 | 0 |
   | embed-fallback (gaming-b650 CPU) | 0.000000043 | 0 | 0.016 / 0.40 |

### History in litellm is not recalculated

LiteLLM calculates the cost once, when a request completes, and stores it in `LiteLLM_SpendLogs`. A price change does not change the stored rows. The database keeps the old values on purpose (decision 2026-09-19). Use the table below for the history.

| Period | Stored cost for local tiers |
|---|---|
| 2026-09-11 to 2026-09-17 12:17 | 0 or partial, no prices set |
| 2026-09-17 12:17 to 2026-09-19 deploy | 1 times energy (old prices) |
| After the 2026-09-19 deploy | 2 times energy (new prices) |

All local calls from 2026-09-11 to 2026-09-19, stored cost against the cost at the new prices (EUR):

| Tier | Calls | Stored | At new price |
|---|---|---|---|
| qwen3.8-27b-local | 3,283 | 0.002 | 3.751 |
| qwen3.8-27b-nothink | 1,885 | 1.188 | 4.428 |
| qwen3.5-9b-last-resort | 687 | 0.005 | 0.768 |
| qwen3.5-9b-local | 709 | 0.034 | 0.544 |
| qwen3.5-9b-json | 397 | 0.000 | 0.078 |
| **Total** | **6,961** | **1.230** | **9.569** |

The "At new price" column does not subtract cached prompt tokens, so it can be up to about 8% too high. For a period that starts before the 2026-09-19 deploy, add the difference (EUR 8.34) to the litellm spend.

### Embedding and rerank on legion-t5 (measured 2026-09-20)

The 2026-09-20 stack change moved Qwen3-Embedding-0.6B and Qwen3-Reranker-0.6B to llama-server on the legion-t5 GPU, and put a CPU copy of both on gaming-b650 as the fallback. qwen3.5-4B stopped, which freed the RTX 3060 Ti. Method: load from the workstation straight to llama-server, 60 s per test, GPU power at 1 Hz, CPU package 14 W and rest of system 25 W from the 2026-09-17 measurement, PSU 0.90, EUR 0.28 per kWh.

| Test | Throughput | GPU power | Energy per 1M tokens | With the x2 uplift |
|---|---|---|---|---|
| Embedding, 32 texts per call | 6,577 tok/s | 103 W | EUR 0.0019 | EUR 0.0037 |
| Rerank, 50 documents per call | 7,828 tok/s | 139 W | EUR 0.0019 | EUR 0.0039 |
| Idle, both models loaded | — | 17.7 W | — | — |

The CPU fallback on gaming-b650 is much slower. Its throughput is measured, its power is an estimate of 80 W CPU package, because the energy counter needs root.

| Fallback test | Throughput | Against the GPU | Energy per 1M tokens | With the x2 uplift |
|---|---|---|---|---|
| Embedding (CPU) | 463 tok/s | 14 times slower | EUR 0.022 | EUR 0.043 |
| Rerank (CPU) | 30 tok/s | 260 times slower | EUR 0.33 | EUR 0.66 |

A real rerank call carries 6,229 tokens (6.9 documents), from 1,522 calls in 6 hours of live traffic. One call therefore costs EUR 0.0000245 on the GPU and about EUR 0.0041 on the CPU fallback.

**LiteLLM cannot track a rerank call.** It records 0 tokens for it, and its rerank price needs `meta.billed_units.search_units` in the response. llama-server does not send that field, so `input_cost_per_query` changes nothing (checked live 2026-09-20). The rerank tiers therefore always show 0 spend. The embedding tiers do track cost: `embed-local` 0.0000000037 per token, `embed-fallback` 0.000000043.

Limits of this measurement: other traffic ran on the same GPU during the rerank window (25 embedding calls and 11 rerank calls through the router), so the rerank value is an upper limit. The embedding window was almost clean (2 foreign calls, 22 tokens). The idle power of 17.7 W is higher than the 10 to 12 W of 2026-09-17, because 2 models now stay loaded.

## Re-assessment after the Strix pentest (2026-09-25)

The first sustained agentic load hit gaming-b650 on 2026-09-25: a Strix web pentest of Outline, model `qwen3.8-27b-local`, about 9 h 37 m, then a failure on a model stream idle timeout. It changes three things in the numbers above. Report: `outline-selfhost/pentest/`.

### The run in numbers (from `LiteLLM_SpendLogs`, key `strix`)

| Metric | Value |
|---|---|
| Requests | 250 (all local tier, no fallback) |
| Prompt tokens | 17,793,896 |
| Completion tokens | 155,382 |
| Input to output ratio | about 114 to 1 |
| litellm spend | EUR 0.7683 |
| Duration | about 9 h 37 m |

### Finding 1: prompt caching cuts the effective input cost far more than 8%

The deployed rate is 2 times energy (input 0.000000064). At that rate the raw tokens cost about EUR 1.39. The recorded spend is EUR 0.77, about 55%. litellm discounts cached prompt tokens, and an agentic loop re-reads a large, stable prefix every turn, so the cache reuse is high.

| Prompt size | Requests | Effective input rate (EUR/token) |
|---|---|---|
| under 20k | 3 | 0.000000064 (full 2x) |
| 20k to 60k | 40 | 0.0000000216 |
| over 60k | 206 | 0.0000000302 |

The average effective input rate is 0.0000000292, below the 1x energy rate. So about 45% of the prompt work was cached, not 8%. The 8% figure under [History in litellm](#history-in-litellm-is-not-recalculated) holds for chat traffic. For a prefill-heavy agentic load, the cache saving is much larger and scales with prefix stability.

### Finding 2: wall energy is higher than the token cost for a long run

Wall power under load is about 342 W ((GPU 238 W measured + 70 W CPU/board/rest) / 0.90 PSU). Over 9.62 h that is about 3.29 kWh, about EUR 0.92 at 0.28 EUR per kWh.

The wall energy (EUR 0.92) is higher than the litellm token cost (EUR 0.77), even with the 2x uplift. A long, stall-prone agentic run holds the GPU powered for hours, and the token metric does not count that idle-under-load time. **For an agentic or pentest load, price on time times power, not on tokens.** The per-token metric stays right for chat.

### Finding 3: the 5.5M tokens per day baseline is a bursty average

The last 7 days of gaming-b650 chat traffic are not flat:

| Day | Prompt tokens | Completion tokens |
|---|---|---|
| 2026-09-18 | 66,939 | 12,686 |
| 2026-09-19 | 10,240,934 | 644,270 |
| 2026-09-20 | 17,451,066 | 1,339,962 |
| 2026-09-21 | 14,066,270 | 565,023 |
| 2026-09-22 | 1,559,420 | 85,061 |
| 2026-09-23 | 2,012,475 | 205,744 |
| 2026-09-24 | 1,714,124 | 189,932 |
| 2026-09-25 | 18,260,439 | 195,108 (Strix day) |

The daily input ranges from 1.5M to 18M tokens. One Strix pentest (17.8M input) equals about 3 heavy chat days or 10 light days. The per-day and per-1M numbers above are an average over this bursty range, not a steady rate.

### Two caveats found

- `request_duration_ms` is not clean wall-clock busy time. Summed per day it reaches 38 to 40 h on busy days, more than 24 h, because 2 slots run in parallel and the duration includes stream waits and the 300 s stalls. Do not use it for busy-hours. Use a GPU power logger.
- The R9700 GPU idles at about 8 W and runs at about 238 W under load, both read from `/sys/class/drm/card1/device/hwmon/hwmon7/power1_average` with no root. gaming-b650 has no `nvidia-smi`.

### Still open

- Prefill versus decode energy per token, measured apart. A quick `power1_average` sampler gave spurious reads (a 28 GW spike), so it needs a proper harness that filters bad reads and sustains each phase. Script: `bench/power/r9700-watt-log.sh`.

## Limits of this measurement

- **Energy cost only.** The cost values leave out hardware write-off, idle power and other ownership costs (see [What the cost values do not include](#what-the-cost-values-do-not-include)).
- **No wall meter.** The rest-of-system power (35 W / 25 W) and the PSU efficiency (90%) are estimates. The sensor values are a lower limit.
- **One request stream.** Production uses `--parallel 2`. Yesterday, 2 parallel streams gave about 35 tok/s each on gaming-b650 at the same 300 W. That is about 70 tok/s in total, so the cost per token is about half with 2 busy slots. This test did not measure that.
- **Small samples.** xhigh (gaming-b650) and reasoning on (legion-t5) completed only 1 request per set. Their speed and power values are reliable, because each set has about 120 power samples. Their tokens-per-task and correctness values are single samples.
- **Prefill for xhigh** is not valid (see the note under the gaming-b650 table).
- **Averaged GPU power.** `power1_average` on the R9700 is a driver average. Windows of less than 2 s (short gen prompts) have less accurate prefill energy. The 12k-token prefill windows (12 s and 4.7 s) are long enough.
- **Hardware idle only.** The idle power is the GPU + CPU package with the models loaded, and without disks, fans or the board.

## Recommendations

1. **Put the costs in litellm** `model_info`. Use 2 times the wall estimate (see [Value in litellm](#value-in-litellm-2-times-the-energy-cost-decision-2026-09-19)). The values are EUR per token. litellm shows all costs as USD, so treat its spend numbers as EUR.

   | litellm model | input_cost_per_token | output_cost_per_token |
   |---|---|---|
   | qwen3.8-27b-local, qwen3.8-27b-nothink | 0.000000064 | 0.0000016 |
   | embed-local (Qwen3-Embedding, legion-t5 GPU) | 0.0000000037 | 0 |
   | embed-fallback (gaming-b650 CPU) | 0.000000043 | 0 |

   Live on litellm-router since 2026-09-19, and the embedding values since 2026-09-20. The four qwen3.5-9b tiers were removed on 2026-09-20, when qwen3.5-4B stopped on legion-t5. A rerank tier cannot be priced (see above).
2. **Set `max_tokens` in clients** that call legion-t5, and do not use reasoning on with the 4B model for extraction work.
3. **The context size is a memory choice, not a quality choice** for prompts up to 12k tokens. A smaller context frees VRAM, for example about 9.5 GB on gaming-b650 at `--ctx-size 262144`.
4. **Optional next test (about 30 minutes):** 2 parallel streams on gaming-b650 for the cost per token with full slots, and a long-context quality test at 64k and 128k tokens of input.

## Files

| Path | Content |
|---|---|
| `models/<model>/power/2026-09-17/ctx<N>/<mode>.jsonl` | Every request: prompt tokens, first-token time, output tokens, finish reason, correctness, full answer and reasoning text |
| `models/<model>/power/2026-09-17/ctx<N>/power.csv` | 1 Hz samples: GPU W, busy %, VRAM, temperature, CPU package W, CPU %, memory |
| `models/<model>/power/2026-09-17/ctx<N>/phases.jsonl`, `props.json`, `host.txt` | Phase times, server properties, host data |
| `models/<model>/power/2026-09-17/sweep-<host>.log` | Restart and health log for each context size |
| `models/<model>/power/2026-09-17/results.json`, `results.md` | Output of `bench/power/analyze.py` (both hosts) |
| `bench/power/` | Sampler, load generator, sweep scripts, analysis. See `bench/power/README.md`. |

Two stopped earlier runs (without output caps, and with 180 s sets) stay outside the repo, in `~/llm-power-2026-09-17/aborted/` on the workstation. The run without caps contains a 22,000-token loop on legion-t5.
