#!/usr/bin/env python3
"""Per host / context / reasoning mode: join streamed request windows with 1 Hz power samples.
Prefill window = request start -> first token. Generation window = first token -> end (or hard stop).
Writes results.json and results.md in $POWER_BASE (default ~/llm-power)."""
import bisect, csv, glob, json, os, re, statistics as st
from difflib import SequenceMatcher

BASE = os.environ.get("POWER_BASE", os.path.expanduser("~/llm-power"))
PRICE = 0.28                                        # EUR per kWh (user value)
REST_W = {"gaming-b650": 35.0, "legion": 25.0}      # estimate: board, RAM, SSD, fans
PSU_EFF = 0.90                                      # estimate

def fnum(v):
    try: return float(v)
    except (TypeError, ValueError): return None

def r(x, n=1): return None if x is None else round(x, n)

class Power:
    """Piecewise-constant power: sample at ts holds for (prev_ts, ts]."""
    def __init__(self, path):
        rows = [{k: fnum(v) for k, v in row.items()} for row in csv.DictReader(open(path))]
        self.ts = [x["ts"] for x in rows]; self.rows = rows
    def energy(self, a, b, key):
        e = 0.0
        i = bisect.bisect_left(self.ts, a)
        while i < len(self.ts):
            lo = self.ts[i - 1] if i > 0 else self.ts[i] - 1.0
            hi = self.ts[i]
            ov = min(b, hi) - max(a, lo)
            if ov > 0: e += (self.rows[i][key] or 0.0) * ov
            if lo >= b: break
            i += 1
        return e
    def window(self, a, b): return [x for x in self.rows if a <= x["ts"] <= b]

def eur_per_m(joule, tokens): return joule / tokens * 1e6 / 3.6e6 * PRICE if tokens else None

results = {}
for cdir in sorted(glob.glob(f"{BASE}/raw/*/ctx*/")):
    h = cdir.split("/raw/")[1].split("/")[0]; ctx = int(re.search(r"ctx(\d+)", cdir).group(1))
    if not os.path.exists(cdir + "power.csv"): continue
    P = Power(cdir + "power.csv")
    ph = {}
    for l in open(cdir + "phases.jsonl"):
        d = json.loads(l); ph.setdefault(d["phase"], {})[d["event"]] = d["ts"]
    idle = P.window(ph["idle"]["start"] + 10, ph["idle"]["end"])
    res = {"idle_gpu_w": r(st.mean(x["gpu_w"] for x in idle)), "idle_cpu_w": r(st.mean(x["cpu_pkg_w"] for x in idle)),
           "props_n_ctx_slot": json.load(open(cdir + "props.json"))["default_generation_settings"]["n_ctx"],
           "modes": {}}
    for f in sorted(glob.glob(cdir + "*.jsonl")):
        mode = os.path.basename(f)[:-6]
        if mode == "phases": continue
        R = [json.loads(l) for l in open(f)]
        e = {"pre_gpu": 0, "pre_cpu": 0, "pre_s": 0, "pre_tok": 0, "gen_gpu": 0, "gen_cpu": 0, "gen_s": 0, "gen_tok": 0,
             "reas_tok": 0, "cont_tok": 0}
        for q in R:
            if q["error"]: continue
            if q["t_first"]:
                a, b = q["t_start"], q["t_first"]
                e["pre_gpu"] += P.energy(a, b, "gpu_w"); e["pre_cpu"] += P.energy(a, b, "cpu_pkg_w")
                e["pre_s"] += b - a; e["pre_tok"] += q["prompt_tokens"]
                a, b = q["t_first"], q["t_end"]
                gt = q["timings"]["predicted_n"] if q["completed"] and q["timings"] else \
                     q["stream_tokens_content"] + q["stream_tokens_reasoning"]
                e["gen_gpu"] += P.energy(a, b, "gpu_w"); e["gen_cpu"] += P.energy(a, b, "cpu_pkg_w")
                e["gen_s"] += b - a; e["gen_tok"] += gt
                e["reas_tok"] += q["stream_tokens_reasoning"]; e["cont_tok"] += q["stream_tokens_content"]
        rest = REST_W[h]
        pre_sensor = e["pre_gpu"] + e["pre_cpu"]; gen_sensor = e["gen_gpu"] + e["gen_cpu"]
        pre_wall = (pre_sensor + rest * e["pre_s"]) / PSU_EFF; gen_wall = (gen_sensor + rest * e["gen_s"]) / PSU_EFF
        comp = [q for q in R if q["completed"]]
        chk = [q for q in comp if q["correct"] is not None]
        rows = P.window(ph[mode]["start"], ph[mode]["end"])
        per_type = {}
        for t in ("gen", "prefill"):
            c = [q for q in comp if q["type"] == t]
            per_type[t] = {"completed": len(c),
                           "out_tokens_mean": r(st.mean(q["timings"]["predicted_n"] for q in c), 0) if c else None,
                           "sec_mean": r(st.mean(q["t_end"] - q["t_start"] for q in c)) if c else None}
        wall_s = sum(q["t_end"] - q["t_start"] for q in comp)
        comp_wall_j = sum((P.energy(q["t_start"], q["t_end"], "gpu_w") + P.energy(q["t_start"], q["t_end"], "cpu_pkg_w")
                           + rest * (q["t_end"] - q["t_start"])) / PSU_EFF for q in comp)
        res["modes"][mode] = {
            "requests": len(R), "completed": len(comp), "cut_at_limit": sum(1 for q in R if q["aborted"]),
            "cut_in_prefill": sum(1 for q in R if q["aborted"] and not q["t_first"]),
            "errors": sum(1 for q in R if q["error"]),
            "cap_failures": sum(1 for q in comp if q["finish_reason"] == "length"),
            "correct": f"{sum(1 for q in chk if q['correct'])}/{len(chk)}" if chk else "-",
            "gpu_w_mean": r(st.mean(x["gpu_w"] for x in rows)), "gpu_w_prefill": r(e["pre_gpu"] / e["pre_s"]) if e["pre_s"] else None,
            "gpu_w_gen": r(e["gen_gpu"] / e["gen_s"]) if e["gen_s"] else None,
            "cpu_w_mean": r(st.mean(x["cpu_pkg_w"] for x in rows)), "cpu_util_mean": r(st.mean(x["cpu_util_pct"] for x in rows)),
            "gpu_temp_max": max(x["gpu_temp_c"] for x in rows), "gpu_busy_mean": r(st.mean(x["gpu_busy_pct"] for x in rows)),
            "prefill_tok_s": r(e["pre_tok"] / e["pre_s"]) if e["pre_s"] else None,
            "gen_tok_s": r(e["gen_tok"] / e["gen_s"]) if e["gen_s"] else None,
            "prefill_tokens": e["pre_tok"], "gen_tokens": e["gen_tok"],
            "reasoning_token_share": r(e["reas_tok"] / (e["reas_tok"] + e["cont_tok"]), 2) if e["reas_tok"] + e["cont_tok"] else None,
            "per_type": per_type,
            "eur_per_m_prefill_sensor": r(eur_per_m(pre_sensor, e["pre_tok"]), 3),
            "eur_per_m_prefill_wall": r(eur_per_m(pre_wall, e["pre_tok"]), 3),
            "eur_per_m_gen_sensor": r(eur_per_m(gen_sensor, e["gen_tok"]), 3),
            "eur_per_m_gen_wall": r(eur_per_m(gen_wall, e["gen_tok"]), 3),
            "wh_per_completed_req_wall": r(comp_wall_j / 3600 / len(comp), 3) if comp else None,
            "eur_per_completed_req_wall": r(comp_wall_j / 3.6e6 * PRICE / len(comp), 5) if comp else None,
        }
    results.setdefault(h, {})[ctx] = res

simil = []
for h in results:
    ctxs = sorted(results[h], reverse=True)
    for c in ctxs[1:]:
        for mode in results[h][c]["modes"]:
            A = {json.loads(l)["i"]: json.loads(l) for l in open(f"{BASE}/raw/{h}/ctx{ctxs[0]}/{mode}.jsonl")}
            B = {json.loads(l)["i"]: json.loads(l) for l in open(f"{BASE}/raw/{h}/ctx{c}/{mode}.jsonl")}
            common = [i for i in sorted(set(A) & set(B)) if A[i]["completed"] and B[i]["completed"]]
            if not common: continue
            sims = [SequenceMatcher(None, A[i]["content"][:4000], B[i]["content"][:4000]).ratio() for i in common]
            simil.append({"host": h, "mode": mode, "ctx_a": ctxs[0], "ctx_b": c, "pairs": len(common),
                          "identical": sum(1 for i in common if A[i]["content"] == B[i]["content"]),
                          "similarity_mean": round(st.mean(sims), 3)})
json.dump({"results": results, "cross_ctx": simil, "price_eur_kwh": PRICE, "rest_w": REST_W, "psu_eff": PSU_EFF},
          open(f"{BASE}/results.json", "w"), indent=1)

cols = ["requests", "completed", "cut_at_limit", "cap_failures", "correct", "prefill_tok_s", "gen_tok_s",
        "gpu_w_prefill", "gpu_w_gen", "cpu_w_mean", "gpu_temp_max", "reasoning_token_share",
        "eur_per_m_prefill_wall", "eur_per_m_gen_wall", "eur_per_m_prefill_sensor", "eur_per_m_gen_sensor",
        "wh_per_completed_req_wall", "eur_per_completed_req_wall"]
md = []
for h in results:
    for c in sorted(results[h], reverse=True):
        res = results[h][c]
        md.append(f"## {h} --ctx-size {c} (per slot {res['props_n_ctx_slot']})\n\nIdle: GPU {res['idle_gpu_w']} W, CPU package {res['idle_cpu_w']} W\n")
        md.append("| mode | " + " | ".join(cols) + " |"); md.append("|" + "---|" * (len(cols) + 1))
        for m, v in res["modes"].items():
            md.append(f"| {m} | " + " | ".join(str(v.get(k)) for k in cols) + " |")
        md.append("")
md.append("## Same request across context sizes\n\n| host | mode | ctx A | ctx B | pairs | identical | similarity |\n|---|---|---|---|---|---|---|")
for s in simil:
    md.append(f"| {s['host']} | {s['mode']} | {s['ctx_a']} | {s['ctx_b']} | {s['pairs']} | {s['identical']} | {s['similarity_mean']} |")
open(f"{BASE}/results.md", "w").write("\n".join(md) + "\n")
print("\n".join(md))
