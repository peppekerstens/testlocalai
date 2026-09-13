#!/usr/bin/env bash
# Writes ONE data/leaderboard.json entry for <model>/<role>, from real
# sources only - never invents a number. Three steps, only the middle one
# calls a model:
#
#   1. Script only. Parses models/<model>/README.md's Overview-table row
#      for this role: status emoji, statusLabel, bare/current fractions,
#      closed date, the evidence anchor. Pure table parsing - the numbers
#      that matter never touch a model.
#   2. One litellm-router call (default: qwen3.5-9b-local - override with
#      LEADERBOARD_SYNC_MODEL). Given ONLY the role's own README subsection
#      and its latest report file, asked for exactly two things: a short
#      statusLabel and a one-paragraph finding. Told which numbers are
#      already known and to introduce no others.
#   3. Script only. Checks every number in the model's `finding` text
#      against the numbers step 1 already extracted (plus the closed
#      date). Any number that doesn't match stops the whole run before
#      anything is written - see "Failure path" below. If it checks out:
#      writes the entry, runs bench/leaderboard.py, then
#      bench/leaderboard-check.sh to confirm.
#
# `detail` (the optional per-task breakdown table) is NOT generated here -
# left for a human/Claude pass if wanted. This script only fills the
# fields the schema requires.
#
# Failure path: on a number mismatch, or if leaderboard-check.sh still
# reports this entry missing after step 3, nothing is written (or the
# just-written entry is left for review) and this script says exactly
# which number(s) it could not verify. It does not retry silently and
# does not guess.
#
# Usage: bash bench/leaderboard-sync.sh <model-slug> <role-id>
#   model-slug: directory name under models/, e.g. qwen3.5-9b
#   role-id   : must match one of data/leaderboard.json's roles[].id,
#               e.g. tool-use, extract, review, reasoner, documenter,
#               code-emitter, visual
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

SLUG="${1:?usage: leaderboard-sync.sh <model-slug> <role-id>}"
ROLE="${2:?usage: leaderboard-sync.sh <model-slug> <role-id>}"
README="models/$SLUG/README.md"
LITELLM_MODEL="${LEADERBOARD_SYNC_MODEL:-qwen3.5-9b-local}"
LITELLM_URL="${LEADERBOARD_SYNC_URL:-http://192.168.2.183:4000/v1/chat/completions}"

[ -f "$README" ] || { echo "ERROR: $README not found" >&2; exit 1; }

# --- Step 1: pure extraction, no model involved ------------------------
EXTRACT_JSON=$(python3 - "$SLUG" "$ROLE" "$README" <<'PY'
import json, pathlib, re, sys

slug, role, readme_path = sys.argv[1:4]
text = pathlib.Path(readme_path).read_text(encoding="utf-8")

leaderboard = json.load(open("data/leaderboard.json", encoding="utf-8"))
role_def = next((r for r in leaderboard["roles"] if r["id"] == role), None)
if role_def is None:
    print(json.dumps({"error": f"'{role}' is not a role id in data/leaderboard.json"}))
    sys.exit(0)
role_name = role_def["name"]  # e.g. "Tool-use"

# Model display name: the README's own H1, "# qwen3.5:9b — steering profile"
m = re.search(r"^#\s+(\S+)", text, re.M)
model_display = m.group(1) if m else slug

def parse_fraction(cell):
    """Returns a {pass/min/max, total, confirmed} dict from one cell's
    first N/M or N-M/M, or None if the cell has no fraction at all."""
    fm = re.search(r"(\d+(?:-\d+)?)/(\d+)", cell)
    if not fm:
        return None
    p, t = fm.group(1), fm.group(2)
    pct_m = re.search(r"\((\d+)%\)", cell)
    if "-" in p:
        d = {"min": int(p.split("-")[0]), "max": int(p.split("-")[1]), "total": int(t), "confirmed": False}
    else:
        d = {"pass": int(p), "total": int(t), "confirmed": ("stable" in cell or "Confirm" in cell)}
        if pct_m:
            d["percent"] = int(pct_m.group(1))
    return d

# Table layout varies per README (checked live, 2026-09-13: qwen3.5-9b/
# qwen3.5-4b use one combined "Pass rate (bare -> current)" column;
# minicpm5-2b uses separate "Bare" and "Steered" columns) - read the
# header row's own column names instead of assuming fixed positions, so
# both shapes (and any other reasonable one) parse correctly.
lines = text.splitlines()
header_idx = None
for i, line in enumerate(lines):
    if line.strip().startswith("|") and i + 1 < len(lines) and re.match(r"^\|[\s:-]+\|", lines[i + 1].strip()):
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if cells and cells[0].lower() == "role":
            header_idx = i
            headers = [c.lower() for c in cells]
            break
if header_idx is None:
    print(json.dumps({"error": f"no Overview table (Role/... header) found in {readme_path}"}))
    sys.exit(0)

row = None
for line in lines[header_idx + 2:]:
    if not line.strip().startswith("|"):
        break
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if cells and cells[0] == role_name:
        row = cells
        break
if row is None:
    print(json.dumps({"error": f"no Overview-table row found for role '{role_name}' in {readme_path}"}))
    sys.exit(0)
row = (row + [""] * len(headers))[:len(headers)]

def col(*name_fragments):
    for i, h in enumerate(headers):
        if all(frag in h for frag in name_fragments):
            return row[i]
    return ""

status_cell = col("status")
details_cell = col("detail")

status = "good" if "✅" in status_cell else "warning" if "⚠️" in status_cell else "critical" if "❌" in status_cell else "neutral"
status_label = re.sub(r"[✅⚠️❌]", "", status_cell).strip()
closed_m = re.search(r"\d{4}-\d{2}-\d{2}", status_cell)
closed = closed_m.group(0) if closed_m else None

combined_rate_cell = col("pass rate")
if combined_rate_cell:
    # One cell like "5/9 bare -> 8/9 stable (89%)": first fraction is
    # bare ONLY if an arrow follows a second fraction; otherwise there is
    # no bare number and the single fraction is current.
    has_arrow = ("→" in combined_rate_cell) or ("->" in combined_rate_cell)
    fractions = re.findall(r"\d+(?:-\d+)?/\d+", combined_rate_cell)
    if has_arrow and len(fractions) >= 2:
        bare = parse_fraction(fractions[0])
        current = parse_fraction(combined_rate_cell.split(fractions[0], 1)[1])
    else:
        bare = None
        current = parse_fraction(combined_rate_cell)
else:
    # Separate columns, e.g. minicpm5-2b's "Bare" / "Steered (...)".
    bare = parse_fraction(col("bare"))
    current = parse_fraction(col("steered")) or parse_fraction(col("current"))

# Evidence anchor: "[Tool-use role](#tool-use-role)" -> section heading text
anchor_m = re.search(r"\]\(#([a-z0-9-]+)\)", details_cell)
anchor = anchor_m.group(1) if anchor_m else None

# Pull the matching "## <Heading>" section body (to next "## " or EOF).
section_text = ""
if anchor:
    heading_pat = re.compile(r"^##\s+(.+)$", re.M)
    headings = list(heading_pat.finditer(text))
    for i, h in enumerate(headings):
        slug_h = re.sub(r"[^a-z0-9]+", "-", h.group(1).lower()).strip("-")
        if slug_h == anchor:
            start = h.end()
            end = headings[i + 1].start() if i + 1 < len(headings) else len(text)
            section_text = text[start:end].strip()
            break

# Latest matching report file, if any.
role_tag = {"documenter": "docs", "reasoner": "reason", "tool-use": "tool",
            "extract": "extract", "review": "review", "code-emitter": "code",
            "visual": "visual"}.get(role, role)
reports_dir = pathlib.Path(f"models/{slug}/reports")
candidates = sorted(reports_dir.glob(f"report-{role_tag}-*.md")) if reports_dir.exists() else []
report_text = candidates[-1].read_text(encoding="utf-8") if candidates else ""

# Allowed = the extracted counts, PLUS every number appearing in what the
# model is actually shown (section_text, report tail) - the model may
# faithfully cite a fact already in its input (e.g. "matches
# qwen3.8-27b's own result"), it just may not introduce a number absent
# from everything it read.
allowed_numbers = set()
for frac_dict in (bare, current):
    if frac_dict:
        allowed_numbers.update(str(v) for v in frac_dict.values() if isinstance(v, int))
if closed:
    allowed_numbers.update(re.findall(r"\d+", closed))
allowed_numbers.update(re.findall(r"\d+", section_text[:4000]))
allowed_numbers.update(re.findall(r"\d+", report_text[-2500:]))

print(json.dumps({
    "model_display": model_display,
    "role_name": role_name,
    "status": status,
    "statusLabel": status_label,
    "bare": bare,
    "current": current,
    "closed": closed,
    "evidence": f"models/{slug}/README.md#{anchor}" if anchor else f"models/{slug}/README.md",
    "section_text": section_text[:4000],
    "report_tail": report_text[-2500:],
    "allowed_numbers": sorted(allowed_numbers),
}))
PY
)

if echo "$EXTRACT_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if 'error' in d else 1)"; then
  echo "ERROR: $(echo "$EXTRACT_JSON" | python3 -c "import json,sys; print(json.load(sys.stdin)['error'])")" >&2
  exit 1
fi

echo "-> step 1 (script): extracted from $README"
echo "$EXTRACT_JSON" | python3 -c "import json,sys; d=json.load(sys.stdin); print(f\"   role={d['role_name']!r} status={d['status']} bare={d['bare']} current={d['current']} closed={d['closed']}\")"

# --- Step 2: one narrow model call --------------------------------------
PROMPT_FILE=$(mktemp)
python3 - "$EXTRACT_JSON" > "$PROMPT_FILE" <<'PY'
import json, sys
d = json.loads(sys.argv[1])
print(f"""You are writing ONE leaderboard entry for a local-LLM benchmark project.

Model: {d['model_display']}
Role: {d['role_name']}
Already-known numbers, do not introduce any other number: {', '.join(d['allowed_numbers']) or '(none)'}

README section for this role:
---
{d['section_text']}
---

Latest test report (tail):
---
{d['report_tail']}
---

Write exactly two lines, nothing else, no preamble:
STATUS_LABEL: <5-10 words, matches the README's own claim>
FINDING: <one paragraph, 2-3 sentences, the headline claim for this role, using ONLY the numbers listed above>
""")
PY

# litellm-router needs its master key - same .env every other ai-stack
# script reads (see ai-stack/litellm-router/render-env.sh).
LITELLM_ENV="${LEADERBOARD_SYNC_ENV:-$HOME/github/ai-stack/litellm-router/.env}"
[ -f "$LITELLM_ENV" ] || { echo "ERROR: $LITELLM_ENV not found - set LEADERBOARD_SYNC_ENV" >&2; exit 1; }
set -a; source "$LITELLM_ENV"; set +a

RESPONSE=$(curl -s -m 120 "$LITELLM_URL" -H "Authorization: Bearer $LITELLM_MASTER_KEY" -H 'Content-Type: application/json' \
  -d "$(python3 -c "import json,sys; print(json.dumps({'model': '$LITELLM_MODEL', 'messages': [{'role': 'user', 'content': open('$PROMPT_FILE', encoding='utf-8').read()}], 'temperature': 0.2, 'max_tokens': 300, 'reasoning_effort': 'none'}))")")
rm -f "$PROMPT_FILE"

MODEL_TEXT=$(echo "$RESPONSE" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d['choices'][0]['message']['content'])
except Exception as e:
    print(f'ERROR: bad response from $LITELLM_MODEL: {e}', file=sys.stderr)
    sys.exit(1)
")

echo "-> step 2 ($LITELLM_MODEL): got a draft"

# --- Step 3: validate, then write, no other path to a written entry ----
python3 - "$EXTRACT_JSON" "$MODEL_TEXT" "$SLUG" "$ROLE" <<'PY'
import json, re, sys

extract = json.loads(sys.argv[1])
model_text = sys.argv[2]
slug, role = sys.argv[3], sys.argv[4]

label_m = re.search(r"STATUS_LABEL:\s*(.+)", model_text)
finding_m = re.search(r"FINDING:\s*(.+)", model_text, re.S)
if not label_m or not finding_m:
    print("FAIL: model output did not contain both STATUS_LABEL: and FINDING: lines")
    print("--- raw output ---")
    print(model_text)
    sys.exit(1)

status_label = label_m.group(1).strip()
finding = finding_m.group(1).strip()

found_numbers = set(re.findall(r"\d+", finding))
# A closed date's digits are legitimately allowed to appear split (year,
# month, day) even though allowed_numbers stores them as separate tokens
# already (see step 1) - no special-casing needed beyond that set.
unverified = found_numbers - set(extract["allowed_numbers"])
if unverified:
    print(f"FAIL: finding text contains number(s) not in the known set: {sorted(unverified)}")
    print(f"Known: {extract['allowed_numbers']}")
    print("--- draft finding, not written ---")
    print(finding)
    sys.exit(1)

# Task-name grounding: a real project task id may only be named if it
# actually appears in what the model was shown - catches e.g. naming
# "extract-basic" as a failure when only "extract-optional" was ever
# mentioned as one (a real hallucination this check was added for,
# found live 2026-09-13; a wrong-but-plausible task NAME carries no
# digit, so the number check above cannot see it).
import pathlib as _pl
real_task_ids = {p.name for p in _pl.Path("tasks").iterdir() if p.is_dir()}
grounded_text = extract["section_text"] + " " + extract["report_tail"]
named_tasks = {t for t in real_task_ids if t in finding}
ungrounded_tasks = {t for t in named_tasks if t not in grounded_text}
if ungrounded_tasks:
    print(f"FAIL: finding text names real task(s) never mentioned in what the model was shown: {sorted(ungrounded_tasks)}")
    print("--- draft finding, not written ---")
    print(finding)
    sys.exit(1)

# Known remaining gap, not fixed by either check above: a fabricated
# CLAIM with no wrong number and no wrong task name (e.g. "regressed on
# the logic task" when the source describes no regression at all) is not
# caught here. Both checks above are grounding checks on entities
# (numbers, task ids), not a general fact-check of every sentence.

entry = {
    "model": extract["model_display"],
    "modelSlug": slug,
    "role": role,
    "status": extract["status"],
    "statusLabel": status_label,
    "bare": extract["bare"],
    "current": extract["current"],
    "finding": finding,
    "evidence": extract["evidence"],
}
if extract["closed"]:
    entry["closed"] = extract["closed"]

data_path = "data/leaderboard.json"
data = json.load(open(data_path, encoding="utf-8"))
replaced = False
for i, r in enumerate(data["results"]):
    if r["modelSlug"] == slug and r["role"] == role:
        data["results"][i] = entry
        replaced = True
        break
if not replaced:
    data["results"].append(entry)

with open(data_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")

print(f"OK: entry {'replaced' if replaced else 'added'} for {slug}/{role}")
PY

echo "-> step 3 (script): regenerating and verifying"
python3 bench/leaderboard.py
echo "-> this model's full sync status (other roles may still be pending - that is not a failure of this run):"
bash bench/leaderboard-check.sh "$SLUG" || true
