# bench/power: power, speed and cost measurement

Measures GPU and CPU power, prefill and generation speed, and energy cost per token for a `llama-server` host. It sweeps reasoning modes and `--ctx-size` values. First run and results: [`docs/POWER-AND-COST.md`](../../docs/POWER-AND-COST.md).

## What each script does

| Script | Runs on | Function |
|---|---|---|
| `sampler.py` | LLM host, as root | 1 Hz CSV: GPU W (amdgpu hwmon or `nvidia-smi`), GPU busy %, VRAM, temperature, CPU package W (RAPL), CPU %, memory |
| `start_sampler.sh` | LLM host, as root | Stops an old sampler and starts a new one in the background |
| `loadgen.py` | workstation | One streaming request stream with a hard stop. Alternates gen tasks and a 12k-token needle task. Fixed prompts and seeds per request index. Output caps per task and mode. |
| `run_host.sh` | workstation | Idle baseline, then one set per reasoning mode, then copies `power.csv` back |
| `setctx.sh` | LLM host, as root | Writes or removes a systemd drop-in with a new `--ctx-size` and restarts `llama-chat` |
| `sweep_host.sh` | workstation | For each context size: restart, wait for `/health`, run `run_host.sh`. Restores production at the end. |
| `analyze.py` | workstation | Joins request windows with power samples. Writes `results.json` and `results.md`. |

## Procedure

1. Stop `litellm-router` on LXC 109, so that no other client loads the hosts: `ssh lxc109 docker stop litellm-router`.
2. Make sure that both `llama-server` slots are idle: `curl -s http://<ip>:11434/slots`.
3. Start one sweep per host. The first context size must be the production value:

   ```bash
   export POWER_BASE=~/llm-power-$(date +%F)
   mkdir -p $POWER_BASE/raw
   bench/power/sweep_host.sh gaming-b650 192.168.2.186 qwen3.8-27b \
     "524288:off,low,medium,xhigh 262144:off,xhigh 131072:off,xhigh" > $POWER_BASE/raw/sweep-gaming-b650.log 2>&1 &
   bench/power/sweep_host.sh legion 192.168.2.133 qwen3.5-4b-gsq \
     "245760:off,on 122880:off,on 61440:off,on" > $POWER_BASE/raw/sweep-legion.log 2>&1 &
   ```

4. Wait for `SWEEP DONE` in both logs (about 21 minutes for gaming-b650 and 17 minutes for legion-t5).
5. Make sure that each log shows the restored production `n_ctx`.
6. Start `litellm-router` again: `ssh lxc109 docker start litellm-router`.
7. Run the analysis: `POWER_BASE=$POWER_BASE python3 bench/power/analyze.py`.

## Requirements and limits

- SSH aliases `gaming-b650` and `legion`, and `HOMELAB_PEPPE_SUDO_PASSWORD` in `~/.env` (sudo for the sampler and systemd).
- `PRICE`, `REST_W` and `PSU_EFF` in `analyze.py` are inputs. `REST_W` and `PSU_EFF` are estimates, because no wall meter is available.
- Sets are 120 s (`SET_S` in `run_host.sh`). A long reasoning request can fill a whole set, so xhigh gives few completed requests.
- The load generator uses one request stream. It does not measure 2 parallel slots.
