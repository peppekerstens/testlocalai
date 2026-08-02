# lfm2.5-vl-450m — ⚠️ SCAFFOLD ONLY, NOT WIRED UP

**Status: placeholder. Nothing in this file has been executed or
verified.** No GGUF has been downloaded, no systemd service exists, no
`tasks/visual-*` tasks have been written, and this model is NOT in
`bench/dispatch.sh`'s `ALLOWED_MODELS` whitelist. Do not assume any of the
below works until it has actually been done and this warning removed.

This file exists only to hold the plan and candidate choice so the
**visual** role (see `../../README.md`'s "Roles" table) isn't forgotten,
per explicit instruction to scaffold-only for now and flag remaining work
rather than build it end-to-end in the same pass as the other three new
roles (tool-use, extract, review — all fully built and validated as of
2026-08-02).

## Candidate model (researched, not downloaded)

`LiquidAI/LFM2.5-VL-450M` — chosen during the same research pass that
picked `lfm2.5:1.2b-thinking` (see `../lfm2.5-1.2b-thinking/README.md`):

- 450M params, general-purpose vision-language, handles images up to
  512×512 without upscaling.
- Native llama.cpp GGUF support (confirmed via `LiquidAI/LFM2.5-VL-450M`
  and `LiquidAI/LFM2-VL-450M-GGUF` on Hugging Face), needs a multimodal
  projector (`mmproj`) file alongside the main GGUF — llama-server's
  vision support requires passing both.
- License: `LFM Open License v1.0` (Apache-derived, free below $10M
  annual revenue) — same license family as `lfm2.5-1.2b-thinking`.
- Recency: part of the same LFM2.5 family released 2026-01 through
  2026-06 — well within the project's "under 1 year old" bar.
- Not confirmed suitable for fine-grained OCR (per its own model card) —
  fine for general image/screenshot description tasks, likely a poor fit
  for a task that needs to read small dense text out of a screenshot.

## What still needs to happen, in order, before this role is real

1. Download both the main GGUF and its `mmproj` file from
   `LiquidAI/LFM2.5-VL-450M-GGUF` (verify exact quant filenames via the HF
   API first, same as was done for the other three models — don't guess
   filenames).
2. Confirm the local llama.cpp build actually supports this model's vision
   architecture (same check done for `lfm2.cpp`/`lfm2moe.cpp` before
   trusting `lfm2.5:1.2b-thinking` — grep the build tree / binary, don't
   assume).
3. Create a new systemd `--user` unit (`llama-server-lfm2-vl.service`,
   next free port — `8086`, since `8080`–`8085` are taken by the five
   models already wired up) — llama-server's `--mmproj` flag for the
   projector file, following the same pattern as the existing units.
4. Add the model's alias to `bench/dispatch.sh`'s `ALLOWED_MODELS`.
5. Figure out how images actually get INTO a dispatch call — every
   existing task in this project is text-only (`SPEC.md` as the prompt).
   `dispatch.sh` has no image-passing path yet; llama-server's
   `/v1/chat/completions` supports an `image_url`/base64 content part for
   vision models, but nothing in this project's tooling constructs that
   today. This is real, non-trivial plumbing work, not just "download and
   go" — budget for it explicitly, don't underestimate it as a copy of
   the text-model pattern.
6. Design 6 `tasks/visual-*` tasks (increasing difficulty, real image
   fixtures — e.g. a screenshot of this project's own docs/output, not a
   stock photo) with `SPEC.md`/`expected.md`/`verify.sh`, validated via
   the same blind claude-sonnet-5 subagent protocol used for tool-use/
   extract/review — though note the blind-subagent step itself needs a
   vision-capable subagent call, which may need its own adaptation of the
   validation protocol (check whether the `Agent` tool supports image
   inputs to a subagent before assuming this step works unmodified).
7. Run real model tests, diagnose failures, steer — same discipline as
   every other role in this project.

**Do not skip straight to step 6 or 7** — steps 1-5 are real
infrastructure that doesn't exist yet, confirmed by grep/inspection, not
assumed present.
