#!/usr/bin/env bash
# Orchestrator dispatch helper.
# Usage: dispatch.sh <model> <prompt-file> <output-file> [mode]
#   model         : ollama model tag (qwen2.5-coder:1.5b | deepseek-r1:1.5b)
#   prompt-file   : file containing the subagent task prompt
#   output-file   : where the model's response text is written
#   mode          : "text" (default) or "json"
#                     text - plain response; strips  /  blocks if present
#                     json - requests a JSON response, writes it raw
#
# Sends the prompt to the configured backend (non-streaming).
# Backend is selected by the DISPATCH_BACKEND env var:
#   llamacpp (default) - POST /v1/chat/completions on localhost:${LLAMACPP_PORT:-8080}
#   ollama             - POST /api/generate on localhost:${OLLAMA_PORT:-11434}
# llama-server reports prompt/output token counts in its response; when used,
# a sidecar "<output-file>.tokens.json" is written with the counts.
#
# Before dispatching, checks that <model> is actually the model loaded at
# that host:port (llamacpp: GET /v1/models, hard fail on mismatch since it's
# the well-supported native endpoint; ollama: GET /api/ps, soft warning only
# since ollama introspection is best-effort here). This is a per-call safety
# net, not session management — see bench/session-start.sh to stop other
# local hosters and load the intended model before a test run.
# Set DISPATCH_CHECK_MODEL=0 to skip the check (e.g. quick manual testing).
#
# DISPATCH_NOTHINK=1 (deepseek-r1 only, backend=llamacpp only): skips the
# reasoning phase entirely by pre-filling an already-closed, empty
# <think></think> block via the raw llama.cpp /completion endpoint (not
# /v1/chat/completions), so the model continues straight into the answer.
# Eliminates context-exhaustion risk from runaway reasoning entirely, since
# there is no reasoning phase to run away. Evidence-backed per-task, not a
# blanket win — validated (2026-08-01) to genuinely help on tasks that
# mainly need breadth-of-coverage, but to *hurt* tasks needing the model to
# correctly reason about a relationship between two facts (it skips exactly
# the reasoning that gets that relationship right) — check per-task before
# using; see models/deepseek-r1-1.5b/README.md.
#
# Optional sampling-parameter / thinking-mode overrides (backend=llamacpp
# only), all opt-in via env var — unset means identical behavior to before
# these existed (temperature=0.2, nothing else sent):
#   DISPATCH_TEMPERATURE=<float>       overrides the hardcoded 0.2 default
#   DISPATCH_TOP_P / _TOP_K / _MIN_P / _PRESENCE_PENALTY=<value>  added to
#     the request body only if set
#   DISPATCH_ENABLE_THINKING=true|false  sends chat_template_kwargs:
#     {"enable_thinking": <bool>} — the only supported thinking-mode
#     control for model families with no in-prompt /think //no_think
#     switch (e.g. qwen3.5); confirmed working via a direct smoke test
#     before being wired in here, see models/README.md's qwen3.5 section.

set -euo pipefail

MODEL="$1"
PROMPT_FILE="$2"
OUT_FILE="$3"
MODE="${4:-text}"
BACKEND="${DISPATCH_BACKEND:-llamacpp}"

# Hard enforcement: only these models may ever be dispatched.
ALLOWED_MODELS=(
  "qwen2.5-coder:1.5b" "deepseek-r1:1.5b"
  "lfm2.5:1.2b-thinking" "qwen3.5:0.8b" "qwen3.5:2b" "qwen3.5:0.8b-bf16"
  "qwen3.5:4b"
)
MODEL_OK=0
for m in "${ALLOWED_MODELS[@]}"; do
  if [ "$MODEL" = "$m" ]; then MODEL_OK=1; break; fi
done
if [ "$MODEL_OK" -ne 1 ]; then
  echo "ERROR: model '$MODEL' is not allowed. Only: ${ALLOWED_MODELS[*]}" >&2
  exit 3
fi

PORT="${OLLAMA_PORT:-11434}"
LLAMACPP_PORT="${LLAMACPP_PORT:-8080}"
if [ "$BACKEND" = "llamacpp" ]; then
  # /v1/chat/completions applies the model's ChatML template, so qwen emits
  # <|im_end|> and stops naturally (raw /completion would ramble without EOS).
  URL="http://localhost:${LLAMACPP_PORT}/v1/chat/completions"
else
  URL="http://localhost:${PORT}/api/generate"
fi

PROMPT_SIZE=$(wc -c < "$PROMPT_FILE")
if [ "$PROMPT_SIZE" -gt 48000 ]; then
  echo "ERROR: prompt file too large ($PROMPT_SIZE bytes) for a 16K-context subagent" >&2
  exit 2
fi

CHECK_MODEL="${DISPATCH_CHECK_MODEL:-1}"
NOTHINK="${DISPATCH_NOTHINK:-0}"
if [ "$NOTHINK" = "1" ] && { [ "$MODEL" != "deepseek-r1:1.5b" ] || [ "$BACKEND" != "llamacpp" ]; }; then
  echo "ERROR: DISPATCH_NOTHINK=1 only supports model=deepseek-r1:1.5b, backend=llamacpp (the prefill trick needs its specific chat-template turn tokens)." >&2
  exit 5
fi

# Optional per-dispatch sampling-parameter / thinking-mode overrides, all
# opt-in via env var and llamacpp-only — unset means "send exactly what
# this script has always sent" (temperature=0.2, no top_p/top_k/min_p/
# presence_penalty, no chat_template_kwargs), so every model that doesn't
# set these is completely unaffected. Added for qwen3.5, whose model card
# recommends temperature 0.6-1.0 (not 0.2) and documents the 0.8B variant
# as "more prone to entering thinking loops... which may prevent it from
# terminating generation properly" — chat_template_kwargs.enable_thinking
# is the only supported control (this model family has no in-prompt
# /think /no_think switch), confirmed working via a direct smoke test
# before this was wired in here (see models/README.md).
TEMPERATURE="${DISPATCH_TEMPERATURE:-0.2}"
TOP_P="${DISPATCH_TOP_P:-}"
TOP_K="${DISPATCH_TOP_K:-}"
MIN_P="${DISPATCH_MIN_P:-}"
PRESENCE_PENALTY="${DISPATCH_PRESENCE_PENALTY:-}"
ENABLE_THINKING="${DISPATCH_ENABLE_THINKING:-}"

python3 - "$MODEL" "$PROMPT_FILE" "$MODE" "$URL" "$BACKEND" "$OUT_FILE" "$CHECK_MODEL" "$NOTHINK" "$TEMPERATURE" "$TOP_P" "$TOP_K" "$MIN_P" "$PRESENCE_PENALTY" "$ENABLE_THINKING" <<'PY' > "$OUT_FILE"
import json, re, sys, urllib.request

(model, prompt_file, mode, url, backend, out_file, check_model, nothink,
 temperature, top_p, top_k, min_p, presence_penalty, enable_thinking) = sys.argv[1:15]
with open(prompt_file, encoding="utf-8") as f:
    prompt = f.read()


def check_loaded_model():
    if backend == "llamacpp":
        check_url = url.rsplit("/v1/chat/completions", 1)[0] + "/v1/models"
        strict = True
    else:
        check_url = url.rsplit("/api/generate", 1)[0] + "/api/ps"
        strict = False
    try:
        with urllib.request.urlopen(check_url, timeout=5) as resp:
            data = json.load(resp)
        if backend == "llamacpp":
            ids = [m.get("id") for m in data.get("data", [])]
        else:
            ids = [m.get("name") or m.get("model") for m in data.get("models", [])]
    except Exception as e:
        msg = f"could not verify loaded model at {check_url}: {e}"
        if strict:
            sys.stderr.write(f"ERROR: {msg}\n")
            sys.exit(4)
        sys.stderr.write(f"WARNING: {msg} (ollama introspection is best-effort here)\n")
        return
    if model not in ids:
        msg = f"expected model '{model}' not loaded at {check_url}; currently loaded: {ids or '(none)'}"
        if strict:
            sys.stderr.write(f"ERROR: {msg}. Run bench/session-start.sh first.\n")
            sys.exit(4)
        sys.stderr.write(f"WARNING: {msg}\n")


if check_model == "1":
    check_loaded_model()

if nothink == "1":
    # Pre-fill an already-closed, empty <think></think> block via the raw
    # llama.cpp /completion endpoint (not /v1/chat/completions, which
    # doesn't allow injecting a partial assistant turn). The model
    # continues generation from inside its own (empty) closed think block,
    # so it proceeds straight to the answer — no reasoning phase, no
    # context-exhaustion risk from a runaway <think>. Turn-delimiter
    # tokens below are DeepSeek-R1-distill's own chat template (verified
    # via this server's /props endpoint), not general-purpose.
    completion_url = url.rsplit("/v1/chat/completions", 1)[0] + "/completion"
    raw_prompt = f"<｜User｜>{prompt}<｜Assistant｜><think>\n\n</think>\n\n"
    body = json.dumps({
        "prompt": raw_prompt,
        "temperature": 0.2,
        "n_predict": 4096,
        "stream": False,
        "stop": ["<｜end▁of▁sentence｜>", "<｜User｜>"],
    })
    req = urllib.request.Request(
        completion_url, data=body.encode(), headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req, timeout=1800) as resp:
        data = json.load(resp)
    response = (data.get("content") or "").strip()
    finish_reason = "length" if data.get("stop_type") == "limit" else "stop"
    tokens = {
        "prompt_tokens": data.get("tokens_evaluated"),
        "completion_tokens": data.get("tokens_predicted"),
        "finish_reason": finish_reason,
        "reasoning_content_chars": 0,
    }
    with open(out_file + ".tokens.json", "w", encoding="utf-8") as f:
        json.dump(tokens, f)
    if finish_reason == "length":
        sys.stderr.write(
            f"WARNING: nothink generation hit n_predict limit (tokens_predicted="
            f"{tokens['completion_tokens']}) without reaching a stop token.\n"
        )
    sys.stdout.write(response)
    sys.exit(0)

if backend == "llamacpp":
    body_dict = {
        "model": model,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": float(temperature),
        "max_tokens": 16384,
        "stream": False,
    }
    if top_p:
        body_dict["top_p"] = float(top_p)
    if top_k:
        body_dict["top_k"] = int(top_k)
    if min_p:
        body_dict["min_p"] = float(min_p)
    if presence_penalty:
        body_dict["presence_penalty"] = float(presence_penalty)
    if enable_thinking:
        body_dict["chat_template_kwargs"] = {"enable_thinking": enable_thinking == "true"}
    body = json.dumps(body_dict)
    if mode == "json":
        body = json.loads(body)
        body["response_format"] = {"type": "json_object"}
        body = json.dumps(body)
else:
    body = json.dumps({
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": 0.2, "num_ctx": 16384},
    })
    if mode == "json":
        body = json.loads(body)
        body["format"] = "json"
        body = json.dumps(body)

req = urllib.request.Request(
    url, data=body.encode(), headers={"Content-Type": "application/json"}
)
with urllib.request.urlopen(req, timeout=1800) as resp:
    data = json.load(resp)

choice = data["choices"][0] if backend == "llamacpp" else None
message = choice["message"] if choice else None
response = message["content"] if backend == "llamacpp" else data["response"]
# Reasoning models (e.g. DeepSeek-R1 via llama-server) may return the
# chain-of-thought in a separate `reasoning_content` field, distinct from
# `content` (the actual answer). If generation is truncated by the
# server's context window while still inside that reasoning phase,
# `content` is legitimately empty — not a model failure, a sizing bug.
# Surface this immediately instead of silently shipping an empty output.
reasoning_content = (message or {}).get("reasoning_content") if backend == "llamacpp" else None
finish_reason = choice.get("finish_reason") if choice else None

if backend == "llamacpp":
    tokens = {
        "prompt_tokens": data.get("usage", {}).get("prompt_tokens"),
        "completion_tokens": data.get("usage", {}).get("completion_tokens"),
        "finish_reason": finish_reason,
        "reasoning_content_chars": len(reasoning_content) if reasoning_content else 0,
    }
    with open(out_file + ".tokens.json", "w", encoding="utf-8") as f:
        json.dump(tokens, f)
    if finish_reason == "length":
        sys.stderr.write(
            f"WARNING: generation truncated by context/token limit (finish_reason=length). "
            f"prompt_tokens={tokens['prompt_tokens']} completion_tokens={tokens['completion_tokens']}"
            + (f", reasoning_content={tokens['reasoning_content_chars']} chars (never reached the answer)"
               if reasoning_content else "")
            + ". If content is empty/short, this is context exhaustion, not a model reasoning failure "
              "— check the server's -c/context size before concluding the model can't do the task.\n"
        )

if mode == "text":
    # Strip inline thinking blocks (relevant when the backend/template
    # inlines them into `content` with <think> tags rather than returning
    # them via a separate reasoning_content field, as handled above).
    # Greedy up to the LAST </think>, not the first: some models (observed
    # on LFM2.5-1.2B-Thinking) occasionally emit a second, unpaired
    # </think> later in their answer (the model's post-think narration
    # briefly slips back into thinking-style prose). A non-greedy first-pair
    # strip leaves that stray closing tag in the final output, corrupting it
    # (e.g. breaking bash syntax in a script-generation task). Stripping
    # through the last </think> instead removes the whole thing.
    response = re.sub(r"<think>.*</think>", "", response, flags=re.S).strip()

sys.stdout.write(response)
PY

echo "dispatch complete: $MODEL -> $OUT_FILE"
