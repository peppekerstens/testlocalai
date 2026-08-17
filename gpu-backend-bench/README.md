# GPU backend bench — Vulkan vs ROCm on the remote worker's new AMD card

**Status: resolved 2026-08-17 — native Windows Vulkan confirmed working.
WSL2 GPU compute stays non-functional on this machine/card (see
"Decision" below); not investigated further since the working path was
found.**

Standalone investigation, separate from `bench/`'s task-correctness
steering harness. This is about raw hardware/backend throughput on the
remote worker machine (`docs/REMOTE-WSL2-SETUP.md`) after its GPU was
swapped from an Nvidia RTX 3060-class 8GB card to an
**AMD Radeon AI PRO R9700** (32GB, Navi 48/RDNA4 — same die as the
consumer RX 9070 XT). Not part of the model-steering quality loop;
archive or delete this directory once a backend decision is made.

## Why this exists

Several performance claims came up while planning the fix (see chat
history, not reproduced here) that we want to verify empirically rather
than take on faith, per this project's own "evidence over assumption"
rule:

1. "Vulkan is faster than ROCm for models that fit in a single GPU;
   ROCm falls behind on multi-GPU splits" (or the reverse — sources
   disagreed on some particulars).
2. "ROCm wins prompt-processing, Vulkan wins token-generation" on AMD
   hardware.
3. CPU-RAM-overflow (partial `-ngl` offload) has its own, backend-
   agnostic performance cliff — not the same mechanism as multi-GPU
   sync overhead.

## Plan

1. Fresh Vulkan-only WSL2 distro (`gpubench-vulkan`) — via `wsl --import`
   (not `wsl --install`, which silently fails over this access path —
   see `docs/REMOTE-WSL2-SETUP.md`).
2. No SSH into the new distro directly — driven entirely via the
   Windows-side bridge (`bench/remote-worker/connect.sh win` →
   `wsl -d gpubench-vulkan -- ...`), same access pattern the docs
   already recommend as the default.
3. A few simple, targeted `llama-bench` runs across CPU / iGPU / R9700,
   each mapped to one of the claims above (see "Test matrix").
4. Second fresh WSL2 distro (`gpubench-rocm`) with ROCDXG + ROCm 7.2.1.
5. Re-run the comparable subset of tests from step 3.
6. Results below, decision, then retire whichever distro/environment
   didn't win (or keep both if the honest answer is "depends on
   workload").

## Test matrix

| Test | Claim it targets | Distro |
|---|---|---|
| CPU-only vs R9700-only, same model | Sanity: is GPU offload doing anything | Vulkan |
| R9700-only, full offload | "Vulkan wins single-GPU" | Vulkan |
| iGPU+R9700 split (`--device Vulkan0,Vulkan1`) | "Vulkan multi-GPU falls behind" (caveat: iGPU so weak this won't cleanly isolate the effect — real second dGPU, i.e. the 3060 later, is the cleaner version of this test) | Vulkan |
| R9700, deliberately reduced `-ngl` | CPU-RAM-overflow cliff is backend-agnostic | Vulkan |
| Same model/settings, ROCm vs Vulkan, pp/tg reported separately | "ROCm wins pp, Vulkan wins tg" | Both |

## Results

**Investigation redirected 2026-08-17.** Before any of the planned
Vulkan-vs-ROCm benchmarking could run, step 1 (fresh Vulkan WSL2
distro) surfaced a more fundamental blocker: **neither AMD GPU (iGPU
or R9700) is visible to WSL2 at all**, on this machine, right now. The
Vulkan-vs-ROCm comparison never happened — there was nothing to
benchmark once GPU passthrough itself proved non-functional.

### The actual finding

`vulkaninfo` hangs indefinitely (confirmed real timeout, not a script
bug) when scanning all Vulkan ICDs; isolated to just the AMD RADV
driver, it fails fast and cleanly with *"Failed to detect any valid
GPUs in the current config."* Root: WSL2's `dxgkrnl` driver fails to
query the GPU adapter at kernel-init time, ~1.7s into every boot —
`dxgkio_query_adapter_info: Ioctl failed: -22` (EINVAL) — before any
user-mode process, WSL distro, or application has even started.

### What was ruled out, with real evidence for each

| Hypothesis | Test | Result |
|---|---|---|
| Stale state in the old WSL2 distro (pre-dating the GPU swap) | Fresh `wsl --import` distro, same failure | Ruled out |
| Driver version too old | `AMD Software 26.7.1` installed vs. `26.2.2` minimum for ROCm-on-WSL | Ruled out — driver is new enough |
| Outdated WSL/kernel | Updated both channels: stable (already current, 2.7.11) and pre-release (`wsl --update --pre-release` → 2.9.4, kernel 6.18.35.2, a real update) | Ruled out — identical failure on the new kernel |
| Stale Windows/hypervisor state since the physical card swap | Full `Restart-Computer -Force`, confirmed via `LastBootUpTime`, re-tested immediately | Ruled out — identical failure, and boot-error timestamp (1.7s) is *before* any process could run anyway |
| Something on the Windows host holding/using the GPU (a game, Ollama, etc.) | Checked running processes and `\GPU Engine(*)\Utilization Percentage` right after the clean reboot | Ruled out — nothing GPU-active, and the failure predates any process starting |

### External corroboration

The exact error (`dxgkio_query_adapter_info: Ioctl failed: -22`) appears
in multiple **open, unresolved** `microsoft/WSL` GitHub issues across
different AMD GPUs — RX 6600 XT on Windows 11 build 26100 (this machine
is on build 26200, very close), RX 7800 XT, integrated Ryzen graphics —
and even one Nvidia/CUDA case with the identical signature. No
maintainer-confirmed root cause or fix found in any of them as of this
investigation. AMD officially claims WSL2 support for the R9700
(ROCDXG + Adrenalin 26.2.2+ + ROCm 7.2.1), but that appears to be a
claim not yet reliably true in practice for this hardware/driver/
Windows-build combination.

### Untested, lower-confidence remaining options

Not pursued (diminishing returns after the above): Windows optional
feature state for Hyper-V/GPU-PV components specifically (separate
from base WSL2, which clearly works — CPU-only distros function fine),
Windows Event Viewer for a more specific host-side error, a clean
driver uninstall+reinstall (current install shows `Status: OK` in
Device Manager, so low prior probability this is it).

### Decision

WSL2 GPU compute is not currently viable on this machine for this
card. Pivoting to running GPU-accelerated work **natively on Windows**
(bypasses `dxgkrnl`/GPU-PV entirely, talks to the driver directly) —
see root `README.md`'s optimization-spectrum discussion and the
`bench/remote-worker/` setup for how this affects the actual
quality-loop harness, not just this side investigation.

### Native Windows resolution — confirmed working

Built a full native Windows toolchain from scratch (`C:\AI\` on the
remote machine — git 2.55.0, CMake 4.4.2, Ninja 1.13.2, Vulkan SDK
1.4.357.0, MSVC 19.44 via VS 2022 Build Tools), cloned llama.cpp,
built with `-DGGML_VULKAN=ON`. Confirmed via `llama-server.exe
--list-devices`:

```
Vulkan0: AMD Radeon(TM) Graphics (16186 MiB, 15377 MiB free)
Vulkan1: AMD Radeon AI PRO R9700 (32624 MiB, 31704 MiB free)
```

Note the iGPU's real figure (16GB, shared system RAM) vs. the
misleading 512MB `Win32_VideoController.AdapterRAM` figure noted below
— that WMI field is an inaccurate legacy metric for iGPUs; Vulkan's own
device query is the trustworthy number.

Then loaded a real model (`Qwen2.5-0.5B-Instruct-Q4_K_M`, picked small
deliberately for a fast smoke test, not a capacity test — both devices
have far more VRAM than this needs) and ran actual inference via
`llama-cli.exe --device Vulkan1 -ngl 99`:

```
> What is the capital of France? Answer in one sentence.
The capital of France is Paris.

[ Prompt: 95.3 t/s | Generation: 71.0 t/s ]
```

Correct output, real generation speed reported — genuine GPU-
accelerated inference confirmed end-to-end, not just device
enumeration. This is the actual resolution: native Windows + Vulkan is
the working path on this machine for now; the Vulkan-vs-ROCm
throughput question from the original plan is deferred (nothing to
compare against without a working ROCm path too, and native Windows
ROCm/HIP wasn't attempted this session).

## Known pitfalls going in (from `docs/REMOTE-WSL2-SETUP.md` + this session)

- `wsl --install` fails silently over this access path — use
  `wsl --import` against a downloaded rootfs tarball instead.
- Long installs/builds can die if the bridging SSH session drops —
  keep foreground with a keepalive, don't background-and-walk-away.
- The iGPU's `Get-CimInstance Win32_VideoController` `AdapterRAM`
  figure (512MB) is misleading — a legacy WMI field, not the real
  ceiling. Vulkan's own device query reports the real number (16GB,
  shared system RAM) — trust that instead, confirmed working below.
- Windows-side commands now go through PowerShell 7 (default shell
  changed 2026-08-17), not `cmd.exe` — PowerShell syntax required
  (`$env:VAR`, `;` not `&`, `Remove-Item` not `del`), see
  `docs/REMOTE-WSL2-SETUP.md`'s "Windows/SSH gotchas" section.
