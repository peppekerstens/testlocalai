#!/usr/bin/env bash
# Visual check (archetype: multi-shape identification). Required tokens
# cover the three real shapes in fixture.png (red circle top-left, blue
# square center, green triangle bottom-right) — each needs both its color
# AND its shape word present, checked separately per shape so a lucky
# single match (e.g. "red" appearing once) can't satisfy two rows.
# Forbidden tokens catch hallucinated shapes/colors not in the image,
# the specific failure mode this task exists to guard against.
set -uo pipefail
OUT="$1"

if [ ! -f "$OUT" ]; then
  echo "VERDICT: FAIL — output file missing"
  exit 1
fi

echo "## visual: visual-basic"

TEXT_LOWER=$(tr '[:upper:]' '[:lower:]' < "$OUT")

FAILS=()

check_pair() {
  local label="$1" a="$2" b="$3"
  if [[ "$TEXT_LOWER" != *"$a"* ]] || [[ "$TEXT_LOWER" != *"$b"* ]]; then
    FAILS+=("missing $label ('$a' + '$b')")
  fi
}

check_pair "red circle" "red" "circle"
check_pair "blue square" "blue" "square"
check_pair "green triangle" "green" "triangle"

FORBIDDEN=("yellow" "purple" "orange" "pentagon" "star" "hexagon")
for tok in "${FORBIDDEN[@]}"; do
  if [[ "$TEXT_LOWER" == *"$tok"* ]]; then
    FAILS+=("forbidden token present: '$tok' (hallucinated shape/color)")
  fi
done

if [ "${#FAILS[@]}" -eq 0 ]; then
  echo "- PASS"
  echo "VERDICT: PASS"
  exit 0
fi

for f in "${FAILS[@]}"; do
  echo "- FAIL $f"
done
echo "VERDICT: FAIL"
exit 1
