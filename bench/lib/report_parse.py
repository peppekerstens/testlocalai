#!/usr/bin/env python3
"""Shared parser for bench/report.sh's output format. Used by
bench/confirm.sh and bench/tier2-gate.sh so the parsing logic (and any
bug fix to it) lives in exactly one place, not copy-pasted per script.

The one real bug already found and fixed here (2026-08-04): a naive
"| `task` | PASS/FAIL |" regex over the whole file also matches
report.sh's own "## Comparison vs previous report" table (same shape
in its Previous/Current columns), silently returning the PREVIOUS run's
verdict instead of the current one for any task whose result changed.
Scoping strictly to the "## Results" section fixes it - verified against
a real report file, not assumed.
"""
import re


def parse_verdicts(path: str) -> dict[str, str]:
    """Return {task_name: 'PASS'|'FAIL'} from a report.sh report file,
    scoped strictly to the ## Results section."""
    text = open(path, encoding="utf-8").read()
    m = re.search(r"## Results\n(.*?)(?=\n## |\Z)", text, re.S)
    section = m.group(1) if m else ""
    verdicts: dict[str, str] = {}
    for m in re.finditer(r"\| `([^`]+)` \| (PASS|FAIL) \|", section):
        verdicts[m.group(1)] = m.group(2)
    return verdicts


def pass_rate(verdicts: dict[str, str]) -> tuple[int, int, float]:
    """Return (pass_count, total, rate) from a verdicts dict."""
    total = len(verdicts)
    passed = sum(1 for v in verdicts.values() if v == "PASS")
    rate = (passed / total) if total else 0.0
    return passed, total, rate
