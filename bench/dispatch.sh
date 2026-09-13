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
#   llamacpp (default) - POST /v1/chat/completions, direct to a llama-server
#   ollama              - POST /api/generate, direct to an Ollama server
#   litellm             - POST /v1/chat/completions through ai-stack's
#                         litellm-router (local-first with cloud fallback;
#                         see the litellm branch further down for the real
#                         cache/timings trade-offs this backend has)
# Host defaults to localhost for llamacpp/ollama (override with
# DISPATCH_HOST=<ip>, added 2026-09-13 to reach a remote box like legion-t5
# or gaming-b650 directly, with no SSH detour) and to the router's own
# address for litellm (override with DISPATCH_HOST or LITELLM_HOST). Ports:
# LLAMACPP_PORT (default 8080), OLLAMA_PORT (default 11434), LITELLM_PORT
# (default 4000).
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
#     {"enable_thinking": <bool>} — the on/off-only thinking-mode control
#     for model families with no in-prompt /think //no_think switch and
#     no graded control (e.g. qwen3.5 and earlier, up to but not
#     including qwen3.8); confirmed working via a direct smoke test
#     before being wired in here, see models/README.md's qwen3.5 section.
#   DISPATCH_REASONING_EFFORT=none|low|medium|high  sends a top-level
#     "reasoning_effort" body field instead — the graded control qwen3.8
#     and later support natively (llama-server accepts this field
#     directly on /v1/chat/completions, same field litellm-router's own
#     config.yaml sets per tier, e.g. qwen3.8-27b-local: low,
#     qwen3.5-9b-local: none — see that file's comments). Works on both
#     backend=llamacpp (straight to llama-server) and backend=litellm
#     (passed through, since every tier's allowed_openai_params includes
#     "reasoning_effort" — this can override the router's own tier
#     default for one call, on purpose, to test a different level through
#     the same routed path). "none" fully disables reasoning; this is a
#     different mechanism from DISPATCH_ENABLE_THINKING's chat_template_
#     kwargs.enable_thinking, so the two are mutually exclusive — set the
#     one your model actually supports (models/README.md documents which
#     models on this project use which). Added 2026-09-13 after the
#     qwen3.5-4b-gsq direct-host test used neither and lost 16,384 tokens
#     per task to unwanted default-on thinking; see that model's README
#     for the real number.
#   DISPATCH_GRAMMAR_FILE=<path>  reads a GBNF grammar file and sends it as
#     "grammar" in the request body (backend=llamacpp only) — llama-server
#     masks the next-token distribution at every step to keep output valid
#     against the grammar, guaranteed by construction, not just encouraged
#     by a prompt instruction. Use for STRUCTURAL constraints only (e.g.
#     "a lone ``` line must appear here", "table must have N rows each
#     with M cells") — never write a grammar that dictates the literal
#     answer content itself (e.g. hardcoding the expected diff's exact
#     wording), which would just be hardcoding the test's answer via the
#     decoding mechanism instead of testing the model. See
#     models/qwen3.5-9b/history.md for the reasoning behind this line and
#     any grammars actually tried.

set -euo pipefail

MODEL="$1"
PROMPT_FILE="$2"
OUT_FILE="$3"
MODE="${4:-text}"
BACKEND="${DISPATCH_BACKEND:-llamacpp}"

# Hard enforcement: only these models may ever be dispatched to
# llamacpp/ollama directly. Does NOT apply to backend=litellm - the real
# gate there is litellm-router's own config.yaml (an unconfigured
# model_name just 404s), and litellm's model_name space (e.g.
# "qwen3.5-9b-local") is a different set of strings than this list's raw
# model tags (e.g. "qwen3.5:9b") - the same model reached two ways under
# two different names, not two models.
ALLOWED_MODELS=(
  "qwen2.5-coder:1.5b" "deepseek-r1:1.5b"
  "lfm2.5:1.2b-thinking" "qwen3.5:0.8b" "qwen3.5:2b" "qwen3.5:0.8b-bf16"
  "qwen3.5:4b" "qwen3.5:9b" "minicpm5:2b" "qwen3.5-4b-gsq"
)
if [ "$BACKEND" != "litellm" ]; then
  MODEL_OK=0
  for m in "${ALLOWED_MODELS[@]}"; do
    if [ "$MODEL" = "$m" ]; then MODEL_OK=1; break; fi
  done
  if [ "$MODEL_OK" -ne 1 ]; then
    echo "ERROR: model '$MODEL' is not allowed. Only: ${ALLOWED_MODELS[*]}" >&2
    exit 3
  fi
fi

# DISPATCH_HOST: added 2026-09-13 so llamacpp/ollama can reach a remote
# box directly (e.g. legion-t5, gaming-b650) instead of only ever
# localhost - no change for existing callers, since it defaults to
# localhost exactly as before. litellm has its own separate default
# (the router's real address), set below, since "localhost" is never
# right for it in this environment.
DISPATCH_HOST_DEFAULT="localhost"
PORT="${OLLAMA_PORT:-11434}"
LLAMACPP_PORT="${LLAMACPP_PORT:-8080}"
LITELLM_MASTER_KEY=""
if [ "$BACKEND" = "llamacpp" ]; then
  HOST="${DISPATCH_HOST:-$DISPATCH_HOST_DEFAULT}"
  # /v1/chat/completions applies the model's ChatML template, so qwen emits
  # <|im_end|> and stops naturally (raw /completion would ramble without EOS).
  URL="http://${HOST}:${LLAMACPP_PORT}/v1/chat/completions"
elif [ "$BACKEND" = "litellm" ]; then
  # Routes through ai-stack/litellm-router instead of a bare llama-server -
  # local-first with cloud fallback, whichever this model_name's config.yaml
  # entry resolves to. Real loss found live 2026-09-13: the router's Redis
  # response cache returns a byte-identical cached answer (and cached
  # timings) for a repeat of the exact same model+messages+params, which
  # would silently turn every 2nd/3rd draw of this project's own 3-draw
  # Confirm methodology into a replay of draw 1, not a real new run. Fixed
  # below by disabling cache on every request this script sends - a
  # per-request override, not a change to the router's own production
  # cache setting (see litellm-router/config.yaml's own cache: True).
  #
  # Real gap, not fixed: a request that actually falls through to the
  # cloud fallback tier gets no "timings" field at all (that object is a
  # llama.cpp-specific extension a hosted OpenAI-compatible endpoint does
  # not return) - tok/s is simply absent for those responses, not wrong.
  HOST="${DISPATCH_HOST:-${LITELLM_HOST:-192.168.2.183}}"
  LITELLM_PORT="${LITELLM_PORT:-4000}"
  URL="http://${HOST}:${LITELLM_PORT}/v1/chat/completions"
  LITELLM_ENV_FILE="${LITELLM_ENV_FILE:-$HOME/github/ai-stack/litellm-router/.env}"
  if [ ! -f "$LITELLM_ENV_FILE" ]; then
    echo "ERROR: $LITELLM_ENV_FILE not found - set LITELLM_ENV_FILE to point at ai-stack/litellm-router/.env" >&2
    exit 6
  fi
  LITELLM_MASTER_KEY="$(grep '^LITELLM_MASTER_KEY=' "$LITELLM_ENV_FILE" | head -1 | cut -d= -f2-)"
  if [ -z "$LITELLM_MASTER_KEY" ]; then
    echo "ERROR: LITELLM_MASTER_KEY not found in $LITELLM_ENV_FILE" >&2
    exit 6
  fi
else
  HOST="${DISPATCH_HOST:-$DISPATCH_HOST_DEFAULT}"
  URL="http://${HOST}:${PORT}/api/generate"
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
REASONING_EFFORT="${DISPATCH_REASONING_EFFORT:-}"
GRAMMAR_FILE="${DISPATCH_GRAMMAR_FILE:-}"

if [ -n "$ENABLE_THINKING" ] && [ -n "$REASONING_EFFORT" ]; then
  echo "ERROR: DISPATCH_ENABLE_THINKING and DISPATCH_REASONING_EFFORT are two different controls for two different model generations — set only the one your model supports, never both at once." >&2
  exit 7
fi
if [ -n "$REASONING_EFFORT" ]; then
  case "$REASONING_EFFORT" in
    none|low|medium|high) ;;
    *)
      echo "ERROR: DISPATCH_REASONING_EFFORT must be one of: none low medium high (got '$REASONING_EFFORT')." >&2
      exit 7
      ;;
  esac
fi

python3 - "$MODEL" "$PROMPT_FILE" "$MODE" "$URL" "$BACKEND" "$OUT_FILE" "$CHECK_MODEL" "$NOTHINK" "$TEMPERATURE" "$TOP_P" "$TOP_K" "$MIN_P" "$PRESENCE_PENALTY" "$ENABLE_THINKING" "$GRAMMAR_FILE" "$LITELLM_MASTER_KEY" "$REASONING_EFFORT" <<'PY' > "$OUT_FILE"
import json, re, sys, urllib.request

(model, prompt_file, mode, url, backend, out_file, check_model, nothink,
 temperature, top_p, top_k, min_p, presence_penalty, enable_thinking,
 grammar_file, litellm_master_key, reasoning_effort) = sys.argv[1:18]
# litellm's response shape mirrors llama-server's own OpenAI-compatible
# shape exactly (choices[0].message, timings, usage) - checked live
# 2026-09-13, litellm passes the backend's own "timings" object through
# unchanged. Treated the same everywhere below except request headers
# (needs the router's own Authorization) and the cache override.
openai_shaped = backend in ("llamacpp", "litellm")
auth_headers = {"Authorization": f"Bearer {litellm_master_key}"} if backend == "litellm" else {}
with open(prompt_file, encoding="utf-8") as f:
    prompt = f.read()
grammar = None
if grammar_file:
    with open(grammar_file, encoding="utf-8") as f:
        grammar = f.read()


def check_loaded_model():
    if openai_shaped:
        check_url = url.rsplit("/v1/chat/completions", 1)[0] + "/v1/models"
        strict = True
    else:
        check_url = url.rsplit("/api/generate", 1)[0] + "/api/ps"
        strict = False
    try:
        check_req = urllib.request.Request(check_url, headers=auth_headers)
        with urllib.request.urlopen(check_req, timeout=5) as resp:
            data = json.load(resp)
        if openai_shaped:
            # llama-server can serve one model under several --alias names.
            # /v1/models reports one of them as "id" and the rest under
            # "aliases" — which one lands in "id" is not the first alias
            # argument, confirmed live 2026-09-12 (order-independent, this
            # server's own choice). Checking "id" alone false-failed every
            # dispatch to a model whose id happened to differ from the tag
            # passed here, even though the server was serving that exact
            # tag correctly under an alias. Check both. litellm's own
            # /v1/models has no "aliases" key at all (checked live
            # 2026-09-13) - .get("aliases") or [] just contributes nothing
            # there, which is correct: litellm's model_name IS what you
            # request, "id" alone is the whole answer for that backend.
            ids = []
            for m in data.get("data", []):
                if m.get("id"):
                    ids.append(m.get("id"))
                ids.extend(m.get("aliases") or [])
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

if openai_shaped:
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
    if reasoning_effort:
        # Top-level field, not chat_template_kwargs — the graded control
        # qwen3.8+ and llama-server itself understand directly (see the
        # DISPATCH_REASONING_EFFORT comment at the top of this file).
        body_dict["reasoning_effort"] = reasoning_effort
    if grammar:
        body_dict["grammar"] = grammar
    if backend == "litellm":
        # Per-request override, not a change to the router's own
        # production cache:True setting - see the litellm branch above
        # for why this must always be set for this backend.
        body_dict["cache"] = {"no-cache": True}
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
    url, data=body.encode(), headers={"Content-Type": "application/json", **auth_headers}
)
with urllib.request.urlopen(req, timeout=1800) as resp:
    data = json.load(resp)

choice = data["choices"][0] if openai_shaped else None
message = choice["message"] if choice else None
response = message["content"] if openai_shaped else data["response"]
# Reasoning models (e.g. DeepSeek-R1 via llama-server) may return the
# chain-of-thought in a separate `reasoning_content` field, distinct from
# `content` (the actual answer). If generation is truncated by the
# server's context window while still inside that reasoning phase,
# `content` is legitimately empty — not a model failure, a sizing bug.
# Surface this immediately instead of silently shipping an empty output.
reasoning_content = (message or {}).get("reasoning_content") if openai_shaped else None
finish_reason = choice.get("finish_reason") if choice else None

if openai_shaped:
    # llama-server includes a "timings" object on every non-streamed
    # response by default (no extra request flag needed) — real
    # generation speed, not estimated from wall-clock time here (which
    # would also count network/queue time). Added 2026-09-12: this data
    # existed in every response all along but was previously discarded.
    # litellm passes this same object through unchanged when a local
    # backend actually serves the request (checked live 2026-09-13) - but
    # a request that falls through to a cloud fallback tier gets no
    # "timings" at all (hosted OpenAI-compatible endpoints don't have
    # this llama.cpp-specific field), so both tok/s fields below come
    # back None for those responses. Not a bug - there is nothing to
    # report for a call this script's own dispatch never actually ran
    # against a llama.cpp backend.
    timings = data.get("timings") or {}
    tokens = {
        "prompt_tokens": data.get("usage", {}).get("prompt_tokens"),
        "completion_tokens": data.get("usage", {}).get("completion_tokens"),
        "finish_reason": finish_reason,
        "reasoning_content_chars": len(reasoning_content) if reasoning_content else 0,
        "prompt_tokens_per_second": timings.get("prompt_per_second"),
        "predicted_tokens_per_second": timings.get("predicted_per_second"),
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
