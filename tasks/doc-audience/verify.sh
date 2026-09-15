#!/usr/bin/env bash
# Doc-fidelity check (archetype: audience simplification). No exact-match —
# checks the three required facts survive in the model's own words, plus
# hard length/jargon constraints that force a genuine simplification
# instead of a near-verbatim copy of the technical passage.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## doc-fidelity: doc-audience"

RESULT=$(python3 - "$OUT" <<'PY'
import re, sys

text = open(sys.argv[1], encoding="utf-8").read()
low = text.lower()
fails = []

# Hard constraint: no sentence over 20 words.
sentences = [s.strip() for s in re.split(r'[.!?]+', text) if s.strip()]
if not sentences:
    fails.append("no sentences found")
for s in sentences:
    n = len(s.split())
    if n > 20:
        fails.append(f"sentence over 20 words ({n}): {s[:60]!r}...")

# Hard constraint: whole answer <= 100 words.
total_words = len(text.split())
if total_words > 100:
    fails.append(f"answer too long: {total_words} words (max 100)")

# Forbidden jargon.
for banned in ("api", "correlate", "tool call"):
    if banned in low:
        fails.append(f"forbidden jargon word present: {banned!r}")

# Required terms kept (they're the actual setting names, not jargon).
for kept in ("token", "consistent", "session-random"):
    if kept not in low:
        fails.append(f"missing required term: {kept!r}")

# Fact 1: consistent -> same token every time.
if not any(p in low for p in ("same token", "same value", "same stand-in",
                               "stays the same", "does not change",
                               "doesn't change", "unchanged")):
    fails.append("missing fact 1: consistent mode reuses the same token")

# Fact 2: session-random -> different token every time.
if not any(p in low for p in ("different every", "different each",
                               "new token", "brand-new", "brand new",
                               "changes every", "changes each")):
    fails.append("missing fact 2: session-random produces a different token each time")

# Fact 3: matching only safe in consistent mode.
has_session_random = "session-random" in low
has_no_match_claim = any(p in low for p in (
    "can't match", "cannot match", "can't compare", "cannot compare",
    "won't match", "will not match", "don't match", "do not match",
    "never be assumed", "never assume", "only when the mode is consistent",
    "only in consistent", "only if the mode is consistent",
))
if not (has_session_random and has_no_match_claim):
    fails.append("missing fact 3: matching tokens across requests only works in consistent mode")

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
