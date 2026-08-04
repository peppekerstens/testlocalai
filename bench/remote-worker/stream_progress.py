#!/usr/bin/env python3
"""Read claude -p --output-format stream-json from stdin, write concise
human-readable step progress to a live-tailable file (and echo to stdout)."""
import sys, json, datetime

progress_path = sys.argv[1] if len(sys.argv) > 1 else "progress.md"
step = 0
tool_names = {}  # tool_use_id -> name

def ts():
    return datetime.datetime.now(datetime.UTC).strftime("%H:%M:%S")

def emit(line):
    global step
    with open(progress_path, "a") as f:
        f.write(line + "\n")
    print(line, flush=True)

for raw in sys.stdin:
    raw = raw.strip()
    if not raw:
        continue
    try:
        ev = json.loads(raw)
    except json.JSONDecodeError:
        continue

    t = ev.get("type")

    if t == "assistant":
        for block in ev.get("message", {}).get("content", []):
            bt = block.get("type")
            if bt == "tool_use":
                step += 1
                name = block.get("name", "?")
                tool_names[block.get("id")] = name
                inp = block.get("input", {})
                desc = inp.get("description") or inp.get("command") or inp.get("file_path") or inp.get("prompt") or ""
                desc = str(desc)[:100]
                emit(f"[{ts()}] step {step}: {name} running... ({desc})")
            elif bt == "text" and block.get("text", "").strip():
                emit(f"[{ts()}] (note) {block['text'].strip()[:200]}")

    elif t == "user":
        for block in ev.get("message", {}).get("content", []):
            if block.get("type") == "tool_result":
                tuid = block.get("tool_use_id")
                name = tool_names.get(tuid, "?")
                is_err = block.get("is_error", False)
                status = "FAILED" if is_err else "done"
                emit(f"[{ts()}] step {step}: {name} {status}")

    elif t == "result":
        dur = ev.get("duration_ms", 0) / 1000
        cost = ev.get("total_cost_usd", 0)
        subtype = ev.get("subtype", "?")
        emit(f"[{ts()}] === RUN FINISHED ({subtype}, {dur:.1f}s, ${cost:.3f}) ===")
