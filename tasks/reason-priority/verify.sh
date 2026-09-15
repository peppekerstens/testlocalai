#!/usr/bin/env bash
# Reasoning check (archetype: severity-ranked triage, 3 items). Requires
# rank 1 to land on Issue B (the calm, technical, easy-to-underrate report)
# and forbids rank 1 landing on Issue A (the alarmist-but-lower-impact
# report) — the trap this task tests is surface urgency vs. actual impact,
# the same pattern already proven in extract-classify.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## reasoning: reason-priority"

RESULT=$(python3 - "$OUT" <<'PY'
import re, sys

text = open(sys.argv[1], encoding="utf-8").read()
low = text.lower()
fails = []

lines = [l.strip() for l in text.splitlines() if l.strip()]
rank_lines = {}
for l in lines:
    m = re.match(r'^\**\s*([123])[\.\)]\s*(.+)$', l)
    if m:
        rank_lines[m.group(1)] = m.group(2).lower()

for r in ("1", "2", "3"):
    if r not in rank_lines:
        fails.append(f"missing rank {r} line")

b_terms = ("issue b", "session-random", "same token", "same obfuscated token",
           "correlate", "session-replay", "replay")
a_terms = ("issue a", "search_tickets", "company 77", "company id 77", "500")
c_terms = ("issue c", "trailing newline", "describe_obfuscation_policy", "cosmetic")

if "1" in rank_lines:
    r1 = rank_lines["1"]
    if not any(t in r1 for t in b_terms):
        fails.append("rank 1 does not identify Issue B (the session-random cross-session leak)")
    if any(t in r1 for t in a_terms):
        fails.append("rank 1 fell for the alarmist-but-lower-impact Issue A report")
    if not any(t in r1 for t in ("no workaround", "all companies", "every company",
                                   "all clients", "critical")):
        fails.append("rank 1 does not justify with scope/no-workaround criteria")

if "2" in rank_lines:
    r2 = rank_lines["2"]
    if not any(t in r2 for t in a_terms):
        fails.append("rank 2 does not identify Issue A")
    if not any(t in r2 for t in ("workaround", "one company", "single company",
                                   "company 77", "company id 77")):
        fails.append("rank 2 does not justify with scope/workaround criteria")

if "3" in rank_lines:
    r3 = rank_lines["3"]
    if not any(t in r3 for t in c_terms):
        fails.append("rank 3 does not identify Issue C")

if fails:
    print("FAIL " + "; ".join(fails))
else:
    print("PASS")
PY
)

echo "- $RESULT"

if [[ "$RESULT" == PASS* ]]; then
  echo "VERDICT: PASS"
  exit 0
fi
echo "VERDICT: FAIL"
exit 1
