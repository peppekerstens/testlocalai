#!/usr/bin/env bash
# Speed test on gaming-b650 next to llama-chat (1 slot). Runs in one ssh session.
P=$(ls /sys/class/drm/card1/device/hwmon/*/power1_average | head -1)
busy(){ curl -s --max-time 2 localhost:11434/slots | grep -q '"is_processing":true'; }
free_mib(){ echo $(( ($(cat /sys/class/drm/card1/device/mem_info_vram_total)-$(cat /sys/class/drm/card1/device/mem_info_vram_used))/1048576 )); }
echo "== llama-chat state: $(systemctl is-active llama-chat), free VRAM $(free_mib) MiB $(date -Is)"
sampler(){ while true; do echo "$(date +%s) $(cat $P) $(cat /sys/class/drm/card1/device/gpu_busy_percent) $(busy && echo chat-busy || echo chat-idle)"; sleep 1; done; }
summ(){ python3 - "$1" <<'PY'
import sys
r=[l.split() for l in open(sys.argv[1]) if len(l.split())==4]
w=[int(x[1])/1e6 for x in r]; c=sum(1 for x in r if x[3]=="chat-busy")
print(f"   samples {len(r)}, GPU power mean {sum(w)/len(w):.0f} W, max {max(w):.0f} W, llama-chat busy in {c} of {len(r)} samples")
PY
}
bench(){ name=$1; shift; echo "== llama-bench $name $(date -Is)"; sampler > /tmp/pw-$name.log & SP=$!; "$@" 2>&1 | grep -E "^\| [a-z]"; kill $SP; summ /tmp/pw-$name.log; }
bench bonsai env LD_LIBRARY_PATH=/opt/llama.cpp-prism /opt/llama.cpp-prism/llama-bench -m /opt/models/ternary-bonsai-2-27b-ptq1_0.gguf -ngl 99 -fa 1 -ctk q8_0 -ctv q8_0 -dev Vulkan0
bench qwen35-4b-gsq env LD_LIBRARY_PATH=/opt/llama.cpp /opt/llama.cpp/llama-bench -m /opt/models/qwen3.5-4b-gsq-q2kxl.gguf -ngl 99 -fa 1 -ctk q8_0 -ctv q8_0 -dev Vulkan0
http(){ name=$1 ctxs=$2 lib=$3 bin=$4 model=$5; ok=0
  for ctx in $ctxs; do echo "== http $name ctx $ctx $(date -Is)"
    LD_LIBRARY_PATH=$lib $bin --model $model --device Vulkan0 --host 127.0.0.1 --port 11500 -ngl 99 -fa on -c $ctx --cache-type-k q8_0 --cache-type-v q8_0 --parallel 1 --jinja --offline > /tmp/http-$name.log 2>&1 & SV=$!
    for i in $(seq 1 90); do curl -fsS localhost:11500/health >/dev/null 2>&1 && break; kill -0 $SV 2>/dev/null || break; sleep 2; done
    if curl -fsS localhost:11500/health >/dev/null 2>&1 && [ $(free_mib) -ge 1536 ]; then ok=1; break; fi
    echo "   ctx $ctx leaves $(free_mib) MiB free (< 1536) or failed: stop, try smaller"; kill $SV; wait $SV 2>/dev/null; sleep 3
  done
  [ $ok = 1 ] || { echo "   no context fits, skip"; return; }
  echo "   health $(curl -s localhost:11500/health) free VRAM $(free_mib) MiB $(grep -c 'failed to fit' /tmp/http-$name.log) fit-warnings"
  for mode in off low; do if [ $mode = off ]; then X='"chat_template_kwargs":{"enable_thinking":false}'; else X='"reasoning_effort":"low"'; fi
    curl -s --max-time 900 localhost:11500/v1/chat/completions -H 'Content-Type: application/json' -d "{\"messages\":[{\"role\":\"user\",\"content\":\"In two sentences: why does a bash script that loops over ssh commands sometimes stop after the first iteration?\"}],\"max_tokens\":12000,\"temperature\":0.2,$X}" | python3 -c "import json,sys;d=json.load(sys.stdin);m=d['choices'][0]['message'];t=d['timings'];print('   %s: finish %s, reasoning %d chars, pp %.1f tok/s, tg %.1f tok/s (%d tok) | %s'%(sys.argv[1],d['choices'][0]['finish_reason'],len(m.get('reasoning_content') or ''),t['prompt_per_second'],t['predicted_per_second'],t['predicted_n'],m['content'][:160].replace(chr(10),' ')))" $mode
    echo "   chat now: $(busy && echo busy || echo idle)"
  done
  kill $SV; wait $SV 2>/dev/null; sleep 3; }
http bonsai "262144 196608 131072" /opt/llama.cpp-prism /opt/llama.cpp-prism/llama-server /opt/models/ternary-bonsai-2-27b-ptq1_0.gguf
http qwen35-4b-gsq "262144 196608 131072 65536" /opt/llama.cpp /opt/llama.cpp/llama-server /opt/models/qwen3.5-4b-gsq-q2kxl.gguf
echo "== done $(date -Is), free VRAM $(free_mib) MiB"
