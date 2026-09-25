#!/usr/bin/env bash
# Real, controlled prompt/generation speed test — runs llama-bench directly
# on the target host over SSH, not an HTTP timing estimate.
#
# Why this exists (2026-09-13): bench/dispatch.sh already captures real
# per-call timings (prompt_tokens_per_second / predicted_tokens_per_second,
# in every task's <out>.tokens.json, added 2026-09-12) from llama-server's
# own "timings" field on each response - genuinely real, not wall-clock
# estimated. But that is one data point per task, at whatever prompt length
# that task happens to have, no repetition, no statistics. llama-bench is
# the correct tool for a real speed answer (fixed prompt/generation lengths,
# repeated N times, averaged). This script runs it on the current Linux
# hosts (legion-t5, gaming-b650): host-agnostic, run over SSH.
#
# llama-bench LOADS THE MODEL ITSELF - it does not talk to a running
# llama-server. It needs the same GPU memory the target host's live
# service already holds, so that service must be stopped first (same
# constraint bench/session-start.sh exists for, on the old local-hoster
# setup). This script does not stop anything for you automatically - the
# right stop command differs per host/service (systemd unit name, sudo
# requirement) - it checks the port is actually free first and refuses to
# run otherwise, telling you what's still listening.
#
# Usage:
#   ./speed-test.sh <ssh-host> <model-path-on-that-host> [llama-bench-args...]
# Examples:
#   ./speed-test.sh gaming-b650 /opt/models/qwen3.8-27b-q6_k.gguf \
#       -ngl 99 -ctk q8_0 -ctv q8_0 -fa 1 -dev Vulkan0
#   ./speed-test.sh legion-t5 /opt/models/qwen3.5-9b-standard.gguf \
#       -ngl 99 -ctk q8_0 -ctv q8_0 -fa 1
#
# Defaults match llama-bench's own (-p 512 -n 128 -r 5) unless overridden
# via extra args after the model path. Output format is markdown
# (llama-bench's default), printed as-is - no re-parsing, so nothing here
# can silently misreport a number llama-bench itself printed correctly.
set -euo pipefail

HOST="${1:?usage: speed-test.sh <ssh-host> <model-path> [llama-bench-args...]}"
MODEL_PATH="${2:?usage: speed-test.sh <ssh-host> <model-path> [llama-bench-args...]}"
shift 2
EXTRA_ARGS=("$@")

# Locate llama-bench on the target host: prefer the installed runtime dir
# (/opt/llama.cpp/, the pattern both legion-t5-llamacpp/ and
# gaming-b650-llamacpp/ use for the server binary), fall back to a
# from-source build tree if that is what exists there instead.
# SPEED_TEST_BIN=<path on host> picks another build, e.g. the PrismML fork
# in /opt/llama.cpp-prism/ for Ternary Bonsai 2 (the mainline build refuses
# PTQ1_0). SPEED_TEST_EXTRA_LIBS=<dir> adds a library dir after the binary's
# own dir: the fork CUDA tarball has no libcudart/libcublas, so legion-t5
# needs /opt/llama.cpp there.
BENCH_BIN=$(ssh -o BatchMode=yes "$HOST" '
  for c in '"${SPEED_TEST_BIN:-}"' /opt/llama.cpp/llama-bench ~/llama.cpp-src/build/bin/llama-bench; do
    [ -x "$c" ] && { echo "$c"; exit 0; }
  done
  exit 1
' ) || {
  echo "ERROR: no llama-bench binary found on $HOST (checked /opt/llama.cpp/ and ~/llama.cpp-src/build/bin/)." >&2
  exit 1
}

# Refuse to run if something is already holding the GPU under a llama-server
# process - llama-bench would either fail to allocate or silently degrade to
# a partial/CPU fallback, and either way the numbers would not mean what
# they claim to. Real check, not a guess: process list, not just a port.
# The bracket trick ([/]) keeps this pgrep from matching its own remote
# invocation - the literal text "[/]llama-server" that ssh sends as this
# command's own argv does not match the regex /llama-server (found the
# hard way earlier this session: an unguarded pgrep/pkill pattern matches
# its own wrapping "sh -c '...'" process too, since that process's cmdline
# contains the same pattern text verbatim).
RUNNING=$(ssh -o BatchMode=yes "$HOST" "pgrep -af '[/]llama-server ' || true")
if [ -n "$RUNNING" ]; then
  echo "ERROR: llama-server is already running on $HOST - stop it first, its GPU memory is not free:" >&2
  echo "$RUNNING" >&2
  exit 1
fi

echo "-> running llama-bench on $HOST: $MODEL_PATH ${EXTRA_ARGS[*]:-}"
LIB_DIR=$(dirname "$BENCH_BIN")${SPEED_TEST_EXTRA_LIBS:+:$SPEED_TEST_EXTRA_LIBS}
ssh -o BatchMode=yes "$HOST" "LD_LIBRARY_PATH='$LIB_DIR' '$BENCH_BIN' -m '$MODEL_PATH' ${EXTRA_ARGS[*]:-}"
