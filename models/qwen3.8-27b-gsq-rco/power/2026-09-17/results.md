## gaming-b650 --ctx-size 524288 (per slot 262144)

Idle: GPU 8.0 W, CPU package 20.8 W

| mode | requests | completed | cut_at_limit | cap_failures | correct | prefill_tok_s | gen_tok_s | gpu_w_prefill | gpu_w_gen | cpu_w_mean | gpu_temp_max | reasoning_token_share | eur_per_m_prefill_wall | eur_per_m_gen_wall | eur_per_m_prefill_sensor | eur_per_m_gen_sensor | wh_per_completed_req_wall | eur_per_completed_req_wall |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| low | 5 | 4 | 1 | 0 | 3/3 | 925.2 | 38.7 | 283.7 | 296.5 | 27.7 | 99.0 | 0.39 | 0.032 | 0.805 | 0.026 | 0.654 | 2.917 | 0.00082 |
| medium | 4 | 3 | 1 | 0 | 2/2 | 954.0 | 38.7 | 289.4 | 296.8 | 27.8 | 99.0 | 0.36 | 0.032 | 0.805 | 0.026 | 0.654 | 3.88 | 0.00109 |
| off | 5 | 4 | 1 | 0 | 3/3 | 944.8 | 38.9 | 287.6 | 296.5 | 27.7 | 96.0 | 0.0 | 0.032 | 0.801 | 0.026 | 0.651 | 2.288 | 0.00064 |
| xhigh | 2 | 1 | 1 | 0 | - | 109.4 | 38.7 | 88.0 | 299.0 | 28.5 | 99.0 | 0.13 | 0.12 | 0.81 | 0.083 | 0.659 | 12.453 | 0.00349 |

## gaming-b650 --ctx-size 262144 (per slot 131072)

Idle: GPU 10.5 W, CPU package 20.1 W

| mode | requests | completed | cut_at_limit | cap_failures | correct | prefill_tok_s | gen_tok_s | gpu_w_prefill | gpu_w_gen | cpu_w_mean | gpu_temp_max | reasoning_token_share | eur_per_m_prefill_wall | eur_per_m_gen_wall | eur_per_m_prefill_sensor | eur_per_m_gen_sensor | wh_per_completed_req_wall | eur_per_completed_req_wall |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| off | 5 | 4 | 1 | 0 | 3/3 | 942.0 | 38.9 | 287.2 | 296.4 | 27.8 | 96.0 | 0.0 | 0.032 | 0.801 | 0.026 | 0.651 | 2.29 | 0.00064 |
| xhigh | 2 | 1 | 1 | 0 | - | 160.8 | 38.7 | 150.0 | 298.7 | 28.4 | 100.0 | 0.13 | 0.115 | 0.809 | 0.086 | 0.658 | 12.438 | 0.00348 |

## gaming-b650 --ctx-size 131072 (per slot 65536)

Idle: GPU 10.5 W, CPU package 20.5 W

| mode | requests | completed | cut_at_limit | cap_failures | correct | prefill_tok_s | gen_tok_s | gpu_w_prefill | gpu_w_gen | cpu_w_mean | gpu_temp_max | reasoning_token_share | eur_per_m_prefill_wall | eur_per_m_gen_wall | eur_per_m_prefill_sensor | eur_per_m_gen_sensor | wh_per_completed_req_wall | eur_per_completed_req_wall |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| off | 5 | 4 | 1 | 0 | 3/3 | 952.7 | 38.8 | 288.6 | 296.4 | 27.8 | 96.0 | 0.0 | 0.032 | 0.803 | 0.026 | 0.653 | 2.29 | 0.00064 |
| xhigh | 2 | 1 | 1 | 0 | - | 153.5 | 38.7 | 172.0 | 298.8 | 28.4 | 100.0 | 0.13 | 0.132 | 0.81 | 0.101 | 0.658 | 12.447 | 0.00349 |

## legion --ctx-size 245760 (per slot 245760)

Idle: GPU 10.1 W, CPU package 3.1 W

| mode | requests | completed | cut_at_limit | cap_failures | correct | prefill_tok_s | gen_tok_s | gpu_w_prefill | gpu_w_gen | cpu_w_mean | gpu_temp_max | reasoning_token_share | eur_per_m_prefill_wall | eur_per_m_gen_wall | eur_per_m_prefill_sensor | eur_per_m_gen_sensor | wh_per_completed_req_wall | eur_per_completed_req_wall |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| off | 17 | 16 | 1 | 1 | 5/12 | 2431.6 | 102.8 | 190.3 | 195.7 | 14.0 | 72.0 | 0.0 | 0.008 | 0.197 | 0.007 | 0.159 | 0.478 | 0.00013 |
| on | 2 | 1 | 1 | 0 | - | 2518.1 | 87.7 | 185.9 | 198.8 | 14.6 | 72.0 | 0.93 | 0.008 | 0.235 | 0.006 | 0.189 | 0.556 | 0.00016 |

## legion --ctx-size 122880 (per slot 122880)

Idle: GPU 11.4 W, CPU package 3.1 W

| mode | requests | completed | cut_at_limit | cap_failures | correct | prefill_tok_s | gen_tok_s | gpu_w_prefill | gpu_w_gen | cpu_w_mean | gpu_temp_max | reasoning_token_share | eur_per_m_prefill_wall | eur_per_m_gen_wall | eur_per_m_prefill_sensor | eur_per_m_gen_sensor | wh_per_completed_req_wall | eur_per_completed_req_wall |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| off | 17 | 16 | 1 | 1 | 5/12 | 2434.3 | 102.8 | 192.0 | 195.3 | 14.1 | 72.0 | 0.0 | 0.008 | 0.197 | 0.007 | 0.159 | 0.478 | 0.00013 |
| on | 2 | 1 | 1 | 0 | - | 2490.6 | 87.8 | 189.8 | 198.8 | 14.7 | 73.0 | 0.93 | 0.008 | 0.235 | 0.006 | 0.189 | 0.559 | 0.00016 |

## legion --ctx-size 61440 (per slot 61440)

Idle: GPU 11.6 W, CPU package 3.1 W

| mode | requests | completed | cut_at_limit | cap_failures | correct | prefill_tok_s | gen_tok_s | gpu_w_prefill | gpu_w_gen | cpu_w_mean | gpu_temp_max | reasoning_token_share | eur_per_m_prefill_wall | eur_per_m_gen_wall | eur_per_m_prefill_sensor | eur_per_m_gen_sensor | wh_per_completed_req_wall | eur_per_completed_req_wall |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| off | 17 | 16 | 1 | 1 | 5/12 | 2417.8 | 103.1 | 192.2 | 195.5 | 14.0 | 72.0 | 0.0 | 0.008 | 0.197 | 0.007 | 0.158 | 0.479 | 0.00013 |
| on | 2 | 1 | 1 | 0 | - | 2384.7 | 87.8 | 182.5 | 198.4 | 14.4 | 73.0 | 0.93 | 0.008 | 0.234 | 0.006 | 0.189 | 0.547 | 0.00015 |

## Same request across context sizes

| host | mode | ctx A | ctx B | pairs | identical | similarity |
|---|---|---|---|---|---|---|
| gaming-b650 | off | 524288 | 262144 | 4 | 4 | 1.0 |
| gaming-b650 | xhigh | 524288 | 262144 | 1 | 1 | 1.0 |
| gaming-b650 | off | 524288 | 131072 | 4 | 4 | 1.0 |
| gaming-b650 | xhigh | 524288 | 131072 | 1 | 1 | 1.0 |
| legion | off | 245760 | 122880 | 16 | 16 | 1.0 |
| legion | on | 245760 | 122880 | 1 | 1 | 1.0 |
| legion | off | 245760 | 61440 | 16 | 16 | 1.0 |
| legion | on | 245760 | 61440 | 1 | 1 | 1.0 |
