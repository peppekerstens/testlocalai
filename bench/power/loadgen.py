#!/usr/bin/env python3
"""One sequential streaming request stream against llama-server (no litellm), with a hard stop.
Usage: loadgen.py HOST_IP MODEL REASONING(off|on|low|medium|xhigh) SECONDS OUT.jsonl
Requests alternate: even i = gen task, odd i = prefill (needle) task. At the deadline the open
request is aborted (connection closed, llama-server cancels it). Prompts and seeds are
deterministic per request index, so request i is identical across context sizes."""
import http.client, json, random, re, sys, threading, time

ip, model, reasoning, dur, out = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4]), sys.argv[5]
WORDS = ("router firewall packet latency cluster storage backup kernel module driver thermal voltage "
         "memory cache token context model inference batch queue socket service daemon config").split()
GEN_TASKS = [
    ("Explain why DNS resolution can fail intermittently in a home network with two resolvers, and list diagnosis steps.", None),
    ("A homelab has 3 servers that draw 85 W, 120 W and 240 W. They run 24 hours a day for 30 days. "
     "Electricity costs EUR 0.28 per kWh. What is the total electricity cost in euros? "
     "End your reply with a last line 'ANSWER: <number>' rounded to 2 decimals.", "89.71"),
    ("Design a backup strategy for a two-node Proxmox cluster with 2 TB of data and one offsite target.", None),
    ("A request has a 12000-token prompt, processed at 850 tokens per second. Then the server generates 1500 tokens "
     "at 38 tokens per second. How many seconds does the request take in total? "
     "End your reply with a last line 'ANSWER: <number>' rounded to 1 decimal.", "53.6"),
]
# Output caps = 4x the upper estimate of a good answer (user decision 2026-09-17).
# A request that reaches its cap (finish_reason "length") counts as a failure in the report.
CAPS_OFF = {0: 10000, 1: 2400, 2: 12000, 3: 2400, "needles": 600}
CAPS_REASONING = {0: 40000, 1: 16000, 2: 48000, 3: 16000, "needles": 32000}

def kwargs():
    if reasoning == "off": return {"enable_thinking": False}
    if reasoning == "on": return {"enable_thinking": True}
    return {"enable_thinking": True, "reasoning_effort": reasoning}

def prefill_prompt(i):
    rng = random.Random(1000 + i)
    words = [rng.choice(WORDS) for _ in range(12000)]
    codes = [f"E{rng.randint(1000, 9999)}" for _ in range(5)]
    for pos, code in zip(sorted(rng.sample(range(500, 11500), 5)), codes):
        words[pos] = f"ERROR code={code}"
    q = ("List every ERROR code in this log in order of appearance. "
         "End your reply with a last line 'ANSWER: <code>,<code>,...' with no spaces.")
    return f"[run {i}] Log:\n{' '.join(words)}\n\n{q}", ",".join(codes)

def check(content, expected):
    if expected is None: return None
    m = re.findall(r"ANSWER:\s*(?:EUR|€)?\s*([^\n]+)", content or "")
    if not m: return False
    return m[-1].strip().rstrip(".").replace(" ", "").replace("€", "") == expected

def post(path, body, timeout=60):
    c = http.client.HTTPConnection(ip, 11434, timeout=timeout)
    c.request("POST", path, json.dumps(body), {"Content-Type": "application/json"})
    r = json.loads(c.getresponse().read()); c.close(); return r

f = open(out, "w"); t_deadline = time.time() + dur; i = 0
while time.time() < t_deadline:
    if i % 2 == 0:
        g = (i // 2) % len(GEN_TASKS); task_key = g
        content, expected = f"[run {i}] {GEN_TASKS[g][0]}", GEN_TASKS[g][1]
    else:
        task_key = "needles"; content, expected = prefill_prompt(i)
    messages = [{"role": "user", "content": content}]
    prompt = post("/apply-template", {"messages": messages, "chat_template_kwargs": kwargs()})["prompt"]
    prompt_tokens = len(post("/tokenize", {"content": prompt, "add_special": True})["tokens"])
    body = {"model": model, "messages": messages, "temperature": 0.7, "seed": 42 + i, "cache_prompt": False,
            "stream": True, "chat_template_kwargs": kwargs(),
            "max_tokens": (CAPS_OFF if reasoning == "off" else CAPS_REASONING)[task_key]}
    st = {"t_first": None, "n_content": 0, "n_reasoning": 0, "text": [], "reas": [], "finish": None,
          "timings": None, "error": None, "done": False}
    conn = http.client.HTTPConnection(ip, 11434, timeout=None)

    def reader():
        try:
            conn.request("POST", "/v1/chat/completions", json.dumps(body), {"Content-Type": "application/json"})
            resp = conn.getresponse()
            for raw in resp:
                line = raw.decode("utf-8", "replace").strip()
                if not line.startswith("data:"): continue
                data = line[5:].strip()
                if data == "[DONE]": break
                ev = json.loads(data)
                if ev.get("timings"): st["timings"] = ev["timings"]
                for ch in ev.get("choices", []):
                    d = ch.get("delta", {})
                    if d.get("reasoning_content"):
                        st["n_reasoning"] += 1; st["reas"].append(d["reasoning_content"])
                    if d.get("content"):
                        st["n_content"] += 1; st["text"].append(d["content"])
                    if (d.get("reasoning_content") or d.get("content")) and st["t_first"] is None:
                        st["t_first"] = time.time()
                    if ch.get("finish_reason"): st["finish"] = ch["finish_reason"]
            st["done"] = True
        except Exception as e:
            st["error"] = repr(e)

    t0 = time.time()
    th = threading.Thread(target=reader, daemon=True); th.start()
    th.join(max(0.0, t_deadline - time.time()))
    aborted = th.is_alive()
    if aborted:
        try: conn.sock.shutdown(2)
        except Exception: pass
        conn.close(); th.join(5)
    t1 = time.time()
    text, reas = "".join(st["text"]), "".join(st["reas"])
    rec = {"i": i, "type": "gen" if task_key != "needles" else "prefill", "task": task_key, "reasoning": reasoning,
           "max_tokens": body["max_tokens"], "prompt_tokens": prompt_tokens,
           "t_start": t0, "t_first": st["t_first"], "t_end": t1, "aborted": aborted,
           "completed": st["done"] and not aborted, "error": None if aborted else st["error"],
           "finish_reason": st["finish"], "timings": st["timings"],
           "stream_tokens_content": st["n_content"], "stream_tokens_reasoning": st["n_reasoning"],
           "expected": expected, "correct": check(text, expected) if st["done"] and not aborted else None,
           "content": text, "reasoning_text": reas}
    f.write(json.dumps(rec) + "\n"); f.flush(); i += 1
