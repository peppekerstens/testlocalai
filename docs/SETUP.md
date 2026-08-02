# Local LLM environment setup

One-time machine/environment setup for running small local LLMs (1–2B
class) on modest consumer hardware — model-agnostic infrastructure, not
steering technique. For how to steer a specific model once it's running,
see `models/<model>/README.md`; for general cross-model practices, see
`LOCAL-LLM-BEST-PRACTICES.md`.

- Host: WSL2, Ubuntu 26.04, kernel `6.18.33.2-microsoft-standard-WSL2`
- GPU: NVIDIA GeForce GTX 1650, 4 GB VRAM, driver 610.57.01, CUDA 13.3
- Established: 2026-08-01

## Table of contents

1. [Host/runtime selection: Ollama vs llama.cpp vs vLLM vs pure Python](#1-hostruntime-selection)
2. [GPU acceleration on WSL2 — the Vulkan saga](#2-gpu-acceleration-on-wsl2)
3. [Installing CUDA toolkit without sudo](#3-installing-cuda-toolkit-without-sudo)
4. [Building llama.cpp with CUDA](#4-building-llamacpp-with-cuda)
5. [Running llama-server as a service](#5-running-llama-server-as-a-service)
6. [Serving API notes (llama-server)](#6-serving-api-notes)
7. [Verifying it worked: measured performance](#7-verifying-it-worked-measured-performance)

---

## 1. Host/runtime selection

Four options were evaluated for serving a 1.5B-class model: **Ollama**,
**llama.cpp**, **vLLM**, and **pure Python** (transformers / PyTorch and
friends). "Pure Python" here means doing the inference in Python yourself
— either `transformers`+PyTorch loading safetensors, or a Python wrapper
around a native engine (`llama-cpp-python`, `ctranslate2`).

### 1.1 Verdict at a glance

| Runtime | Verdict | One-line why |
|---|---|---|
| **Ollama** | Rejected for serving (fallback only) | Easy UX + model manager, but restricted build here (`/api/tokenize`, `/api/embed` → 404), opaque runner, less control. Fine for a LAN review host. |
| **llama.cpp / llama-server** | **Chosen** | Native tokenize/FIM/metrics/per-slot timings, LAN `--host`, GGUF, prebuilt or ~15–30 min CUDA source build. Best control-to-effort ratio on this hardware. |
| **vLLM** | Rejected | 4 GB VRAM can't fit two engines + CUDA graphs; `sm_75` is the oldest supported arch (half-width fp16); heavy install; single-model-per-engine anyway. Built for datacenter throughput, not home 1.5B. |
| **Pure Python** | Rejected for serving (legit for research) | No built-in server/concurrency — you write the HTTP layer + batching yourself; transformers is slow & memory-hungry without extra work; token counting is the one clear win (native `tokenizers`). |

### 1.2 Feature comparison

| Criterion | Ollama | **llama.cpp / llama-server** | vLLM | Pure Python (`transformers`/PyTorch) |
|---|---|---|---|---|
| **Install effort** | Very low (single binary + `ollama pull`) | Low–med (prebuilt tarball, or cmake build) | High (pip + CUDA deps; arch-gated wheels) | Med–high (torch wheels ~2 GB+; bitsandbytes for 4-bit) |
| **Speed (GTX 1650, 1.5B Q4)** | Good (bundles llama.cpp) | **~98–100 tok/s (CUDA)** | Poor fit: sm_75 half-width fp16 | Slow unless quantized + kernel-tuned (bitsandbytes, torch.compile); llama-cpp-python = llama.cpp speed |
| **VRAM footprint** | Per-model runner; OK | Fine-grained (`-ngl`, KV sizing); 1.5B ≈ 0.5–1 GB weights | High: engine + CUDA graph buffers | fp16 1.5B ≈ 3 GB weights (no room for ctx); 4-bit needed |
| **Multi-model** | Yes — one manager, many runners | Yes — one process per model, per port | No — one engine per model | One process = one model (shared VRAM) |
| **Token counting** | `/api/tokenize` (404 on restricted build here) | **Native `/tokenize`, `/v1/chat/completions/input_tokens`** | Yes (`usage`) | Easiest — native `tokenizers` in-process |
| **HTTP API** | Native + OpenAI-compat `/v1` | Native + OpenAI-compat `/v1`, plus `/infill`, `/metrics`, `/health` | OpenAI-compat | None — you build FastAPI/Flask yourself |
| **Concurrency / batching** | Yes (runner-side) | Yes (slots, `n_slots`; continuous batching) | Yes (continuous batching — its whole point) | Manual (GIL, no server); must roll your own |
| **FIM / code endpoints** | Limited | Native `/infill` | No | Model-dependent, manual |
| **Model format** | GGUF | GGUF (native) | HF safetensors (needs conversion) | HF safetensors (GGUF only via llama-cpp-python) |
| **Observability** | Opaque runner | **`/metrics`, per-slot timings, log** | Good (metrics, logs) | Whatever you log yourself |
| **Control of internals** | Low | High | High (but overkill here) | Total — but total responsibility too |
| **Best for** | Quick play / model manager / LAN reviewer | **Steady self-hosted serving** | Throughput farms (≥24 GB VRAM) | Research, novel sampling, in-process embeddings |

### 1.3 Pure Python sub-variants

"Pure Python" splits into three very different realities:

| Variant | Speed | Memory | Notes |
|---|---|---|---|
| `transformers` + PyTorch (fp16) | Slow-ish | ~3 GB for 1.5B fp16 | Simplest to write, no quantization; won't fit a 4 GB card with context |
| `transformers` + bitsandbytes (4-bit) | Better | ~0.7–1 GB weights | Loads GGUF-converted or HF-quant models; bitsandbytes install can be fragile |
| `llama-cpp-python` / `ctranslate2` | **llama.cpp-level** | Same as llama.cpp | Python *bindings* to a native engine — best of both if you insist on Python, but you still write the server + batching |

### 1.4 Why llama.cpp won on this box

- The **only** option that checked every box: GPU speed on 4 GB VRAM,
  native token counting, a real HTTP server with concurrency (slots), FIM,
  metrics, and LAN serving — without writing a server or fighting a
  datacenter-class install.
- Pure Python's one real advantage (in-process `tokenizers`) is moot
  because llama.cpp gives exact token counts over HTTP anyway.
- If we *had* needed Python-side model access (custom sampling, per-token
  hooks), `llama-cpp-python` would be the pick — same engine, Python API.

### 1.5 Multi-model plan

llama.cpp is single-model-per-process; run one instance per port
(`:8080` qwen, `:8081` deepseek, …). Two 1.5B Q4_K_M models ≈ 2.5 GB
combined VRAM — fits 4 GB comfortably.

**OpenAI-compatible serving:** both Ollama and llama-server expose an
OpenAI-compatible `/v1` API, so the dispatch layer treats them identically.
llama-server is preferred at the server level for its introspection
endpoints (see §6, §7 below and `LOCAL-LLM-BEST-PRACTICES.md`'s "Token
accounting").

---

## 2. GPU acceleration on WSL2

### 2.1 The failure

The first llama.cpp build was the **Vulkan** prebuilt. It "worked" — and
ran at CPU speed. Windows Task Manager showed CPU/RAM load, GPU idle.

### 2.2 Diagnosis (reproducible steps)

```bash
nvidia-smi                              # driver present? (was OK: 595.97)
ls /usr/lib/wsl/lib/                    # WSL driver libs injected from Windows
ls /usr/lib/wsl/lib/ | grep -i vulkan   # <- EMPTY = no NVIDIA Vulkan ICD
cat /usr/lib/wsl/lib/nvidia-vulkan-icd.json   # missing
```

The directory `/usr/lib/wsl/lib` is populated from the Windows driver
install (`C:\Windows\System32\lxss\lib\`). It had the CUDA files
(`libcuda.so.1`, `nvidia-smi`, `libnvidia-ml.so.1`, …) but **no Vulkan
files** — the driver package simply didn't bundle the WSL Vulkan ICD.
Without an ICD the Vulkan loader only sees software/paravirt drivers
(`lvp`, `virtio`, `gfxstream`…), so llama.cpp found no NVIDIA device and
fell back to CPU **without warning**.

Also observed during troubleshooting:

- `dmesg | grep dxg` showed `dxgvmb_send_create_process: create_process
  failed -75` / `dxgkio_query_adapter_info: Ioctl failed: -2` → the
  paravirtualized GPU bridge wasn't negotiating with the host.
- After a Windows driver reinstall but *before* a WSL restart: NVML error
  `GPU access blocked by the operating system`, and a **stale
  `/usr/lib/wsl/lib`** (old `libcuda.so` + new `libnvidia-gpucomp`).
  **`wsl --shutdown` from PowerShell (Admin) and reopening WSL fixed
  nvidia-smi.** This is the #1 fix when nvidia-smi breaks after a driver
  change.
- The Windows driver at 610.57.01 still ships **no** WSL Vulkan ICD
  (`nvidia-vulkan-icd.json` absent). Tried reinstall + full reboot — no
  change. Rather than hunt another driver edition, we used CUDA.

### 2.3 Verdict

CUDA passthrough on WSL2 is reliable; Vulkan is a coin flip depending on
driver edition. **If Vulkan isn't there, use the CUDA build of llama.cpp
— not a different driver.** (See §4.) Verify with `nvidia-smi
--query-compute-apps` or, more reliably, watch GPU util spike during a
generation:

```bash
nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader   # while generating
```

---

## 3. Installing CUDA toolkit without sudo

Goal: `nvcc` + CUDA libs (`libcudart`, `libcublas`, …) in `~/cuda`,
no root, no driver (the WSL passthrough driver already provides
`libcuda.so.1`).

### 3.1 Steps that worked

1. Download the Linux x86_64 runfile (matches your CUDA UMD version; ours
   CUDA 13.3.1): ~4.3 GB.
2. The runfile's self-extractor writes to `$TMPROOT` (= `/tmp`), which is
   a small `tmpfs` here (3.9 GB) while the unpacked kit is ~7.9 GB →
   *"Extraction failed. Ensure there is enough space in /tmp"*.
   **Fix:** extract to a big path with `--keep --target`:
   ```bash
   bash cuda_*.linux.run --keep --target=/mnt/c/tmp/cuda-pkg --nox11
   ```
   (`--nox11` avoids the "spawn a terminal" branch when run without a tty:
   `exec: -t: invalid option`.)
3. Post-extract the installer `cuda-installer` needs `libxml2.so.2`,
   which Ubuntu 26.04 ships as `libxml2.so.16` → *shared object not found*.
   **Fix:** skip the installer; merge the extracted package dirs directly:
   ```bash
   mkdir -p ~/cuda
   for d in /mnt/c/tmp/cuda-pkg/builds/cuda_* /mnt/c/tmp/cuda-pkg/builds/libcud*; do
     [ -d "$d" ] && cp -a "$d"/. ~/cuda/
   done
   ```
4. Verify: `~/cuda/bin/nvcc --version` (ours: release 13.3, V13.3.73),
   `~/cuda/targets/x86_64-linux/lib/libcudart.so`,
   `~/cuda/include/cuda_runtime.h`.

### 3.2 Gotchas

- `--extract=...` alone does **not** redirect the internal target dir the
  way `--keep --target` does — use `--keep --target`.
- The "MD5 checksums OK" self-check inside the runfile is real; a
  truncated download fails extraction with the *same* misleading message.
  Verify with the runfile's own MD5 line before blaming /tmp.
- Disk: CUDA toolkit ≈ 7.1 GB, llama.cpp build tree ≈ 6.3 GB.

---

## 4. Building llama.cpp with CUDA

Needed: `cmake` (no system package here; grabbed the portable tarball),
`g++` (present, GNU 15.2), `nvcc` from §3.

```bash
export PATH=~/cuda/bin:$PATH
export CMAKE_CUDA_COMPILER=~/cuda/bin/nvcc

cmake -B build-cuda -DGGML_CUDA=ON \
      -DCMAKE_CUDA_ARCHITECTURES=75 \   # GTX 1650 = Turing sm_75
      -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=OFF .
cmake --build build-cuda --target llama-server -j$(nproc)
```

Notes:
- `-DCMAKE_CUDA_ARCHITECTURES=75` keeps the build to exactly your arch
  (compile time + binary size). Use `nvidia-smi --query-gpu=compute_cap`
  if unsure.
- `libcudart.so.13` is needed at runtime → put `~/cuda/targets/
  x86_64-linux/lib` on `LD_LIBRARY_PATH` (see §5). The CUDA build's own
  `build-cuda/bin` must be there too (it holds `libggml-cuda.so`, etc.).
- Prebuilt releases only ship `vulkan`/`cpu`/`rocm`/`sycl`/`openvino`
  tarballs — **no prebuilt CUDA for Linux** — hence the from-source build.
- Verify GPU actually used: GPU util spikes (we saw 92% during eval) and
  generation ~5× faster than CPU.

---

## 5. Running llama-server as a service

Use a **systemd user service** so the server survives shell exits and
auto-restarts (earlier `nohup` attempts died on shell timeouts).

`~/.config/systemd/user/llama-server.service`:

```ini
[Unit]
Description=llama.cpp llama-server (qwen2.5-coder:1.5b, CUDA)
After=network.target

[Service]
Type=simple
WorkingDirectory=%h/llama
Environment=LD_LIBRARY_PATH=%h/llama/src/llama.cpp/build-cuda/bin:%h/cuda/targets/x86_64-linux/lib
ExecStart=%h/llama/llama-server -m %h/llama/qwen2.5-coder-1.5b-instruct-q4_k_m.gguf \
    --alias qwen2.5-coder:1.5b --host 127.0.0.1 --port 8080 -ngl 99 -c 8192 -fa on
Restart=on-failure
RestartSec=3

[Install]
WantedBy=default.target
```

```bash
systemctl --user daemon-reload
systemctl --user enable --now llama-server
systemctl --user status llama-server
journalctl --user -u llama-server -f     # logs (not ~/llama/server.log)
```

Flags explained:
- `-ngl 99` offload all layers to GPU.
- `-fa on` enable flash attention (note: `--flash-attn` requires a value).
- `-c 8192` context; `n_slots = 4` slots, `n_ctx_slot = 8192` shown at load.

Each additional model gets its own service (own `--alias`, `--port`,
model file) — see `~/.config/systemd/user/llama-server-*.service` for the
ones currently running (deepseek on `:8081`, lfm2.5 on `:8082`, qwen3.5
variants on `:8083`–`:8085`).

---

## 6. Serving API notes

Two ways to talk to llama-server; **choose `/v1/chat/completions`, not
`/completion`**:

- `POST /completion` (raw) does **not** apply the model's chat template →
  a chat-tuned model **rambles, never emits its EOS** (e.g. qwen2.5-coder's
  `<|im_end|>`). Looks broken; it's a template problem. (`dispatch.sh`'s
  `DISPATCH_NOTHINK=1` mode is a deliberate, narrow exception to this —
  see `models/deepseek-r1-1.5b/README.md`.)
- `POST /v1/chat/completions` applies the chat template → clean stop.
  OpenAI-compatible shape: `{"model", "messages":[{role,content}],
  "temperature": 0.2, "max_tokens": 16384, "stream": false}`.
  JSON mode: add `"response_format": {"type": "json_object"}`.
  Response includes `usage.prompt_tokens` / `usage.completion_tokens`.

Other useful endpoints (why llama-server beats Ollama here):
- `GET /health`, `GET /v1/models`
- `POST /tokenize` — exact prompt token counts (verified working)
- `/v1/chat/completions/input_tokens` — input tokens for streaming
- `/infill` — FIM (fill-in-the-middle)
- `/metrics` — Prometheus metrics, incl. per-slot timing
- `/props` — chat-template introspection (needed to build a raw-prompt
  prefill like `DISPATCH_NOTHINK` correctly for a new model)

Ollama equivalent (fallback backend): `POST /api/generate` with full body
`{"model","prompt","stream":false,"options":{"temperature":0.2,
"num_ctx":16384}}`; JSON mode via `"format":"json"`. (This build's
`/api/tokenize` was 404.)

---

## 7. Verifying it worked: measured performance

### llama.cpp, qwen2.5-coder:1.5b (Q4_K_M, 8192 ctx, 4 slots)

| Mode | tokens/s |
|---|---|
| CPU (no GPU offload, pre-fix) | 19–26 gen |
| **CUDA GPU (sm_75)** | **98–100 gen**, ~68–79 prompt-eval |

- GPU util during generation: **92%**; VRAM: 2227 MiB of 4096 MiB used.
- Full system restart + driver reinstall did not change speed class (the
  CPU→GPU jump did); speed validates the CUDA route.

### Smoke-test sanity check (direct dispatch)

`dispatch.sh` round-trip (prompt 23 tok + 4 tok answer) ≈ **0.46 s** on
the CUDA engine.

If your numbers look like the CPU row above after following §1–§6, GPU
offload isn't actually happening — go back to §2's diagnosis steps.
