# Mandatory dispatch overrides for qwen3.5:0.8b — sourced automatically
# by bench/loop.sh. See this model's README.md "Setup" section for the
# source/reasoning; keep this file and that prose in sync if either
# changes. Without DISPATCH_ENABLE_THINKING=false this model enters an
# unterminated thinking loop (real incident: finish_reason=length after
# 8177 completion tokens, empty final answer — see README/history.md).
export DISPATCH_ENABLE_THINKING=false
export DISPATCH_TEMPERATURE=1.0
export DISPATCH_TOP_P=1.0
export DISPATCH_TOP_K=20
export DISPATCH_PRESENCE_PENALTY=2.0
