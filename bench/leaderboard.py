#!/usr/bin/env python3
"""Render data/leaderboard.json into docs/leaderboard.html.

Usage: python3 bench/leaderboard.py   (no arguments, stdlib only)

This is the ONLY thing that reads models/*/README.md prose for the
leaderboard -- it doesn't. The dashboard renders exclusively from
data/leaderboard.json, which a human/agent maintains by hand alongside
each README (see AGENTS.md's "After a test run, persist it" rule).
README prose stays free-form for nuanced human claims; this file is
the structured mirror the dashboard can render without guessing at
phrasing.

## Schema (data/leaderboard.json)

Top level:
  generated   -- ISO date this file was last hand-updated
  roles       -- every role from the root README's Roles table, in display order.
                 Each: {id, name, tests, state}
                 state: "active" (has real result rows) | "task-suite-only"
                 (built, no model run yet) | "scaffold" (not wired up)
  results     -- one entry per model+role actually tested. See below.
  referenceBaseline -- the claude-sonnet-5 validation entry (shown separately,
                 never ranked/steered)
  scaffold    -- entries for roles/models with no real run yet (e.g. visual)

Each `results[]` entry:
  model       -- display name, e.g. "qwen3.5:9b"
  modelSlug   -- directory name, e.g. "qwen3.5-9b" (models/<modelSlug>/)
  role        -- must match a roles[].id
  status      -- "good" | "warning" | "critical" | "neutral" -- drives the
                 status pill color. Neutral = in-progress/preliminary, not
                 part of the fixed good/warn/critical scale (see
                 docs/LANDSCAPE-COMPARISON.md's dataviz notes on why).
  statusLabel -- short human label shown in the pill, e.g. "Mixed -- strong"
  bare        -- {pass, total} the zero-shot baseline, or null if the
                 model's own README declines to give one clean fraction
                 (write the real reason into `finding` instead of inventing
                 a number the source doesn't state)
  current     -- the post-steering result, one of:
                   {pass, total, confirmed}      -- clean fraction
                   {pass, total, percent, ...}    -- a blended/derived % the
                                                      README itself computed
                                                      (not us) -- explain the
                                                      blend in barNote
                   {min, max, total, confirmed:false} -- still-flaky range,
                                                           rendered hatched
                   null                            -- no clean current number;
                                                        set currentNote instead
  currentNote -- free text shown where `current` can't be one number
  barNote     -- small caption under the bar (caveats, what "confirmed" means)
  closed      -- date the role's quality loop closed, if it has
  finding     -- the one-paragraph headline claim for the card
  detail      -- optional {summary, rows:[{term, def}]} rendered as a native
                 <details> disclosure (per-task/per-category breakdown)
  evidence    -- relative path into the repo (shown as text, not a live link --
                 this page doesn't know where the repo is hosted)

Adding a result: never compute a new percentage the source README doesn't
already state -- if a model's own README says "not comparable overall", set
current to null and put the real qualitative claim in currentNote/finding.
That's a deliberate rule, not a gap: `qwen3.5:2b`'s and `qwen2.5-coder`'s
entries below are the worked examples.
"""

import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
DATA_PATH = ROOT / "data" / "leaderboard.json"
OUT_PATH = ROOT / "docs" / "leaderboard.html"

CSS = """
  :root {
    color-scheme: light;
    --page:       #f6f5f1;
    --surface:    #fcfcfa;
    --surface-2:  #f2f0e9;
    --ink:        #14120d;
    --ink-2:      #55524a;
    --ink-muted:  #8c887d;
    --hairline:   #e4e1d8;
    --border:     rgba(20,18,13,0.10);
    --accent:     #B96A17;
    --accent-tint:#f1e2c9;
    --good:       #0ca30c;
    --good-tint:  #dff2df;
    --warning:    #b8790a;
    --warning-tint: #fcecc9;
    --serious:    #c14f27;
    --serious-tint: #fbe1d5;
    --critical:   #d03b3b;
    --critical-tint: #fbdede;
    --radius: 10px;
    --mono: ui-monospace, "Cascadia Code", "SF Mono", "Consolas", monospace;
    --sans: system-ui, -apple-system, "Segoe UI", sans-serif;
  }
  @media (prefers-color-scheme: dark) {
    :root:where(:not([data-theme="light"])) {
      color-scheme: dark;
      --page:       #0d0c0a;
      --surface:    #17150f;
      --surface-2:  #1e1c14;
      --ink:        #faf8f3;
      --ink-2:      #c7c2b3;
      --ink-muted:  #928d7d;
      --hairline:   #2b2820;
      --border:     rgba(255,255,255,0.10);
      --accent:     #F0A93E;
      --accent-tint:#3a2c14;
      --good:       #38c93d;
      --good-tint:  #17301a;
      --warning:    #fab219;
      --warning-tint: #3a2c0d;
      --serious:    #ec835a;
      --serious-tint: #3a2113;
      --critical:   #e66767;
      --critical-tint: #3a1414;
    }
  }
  :root[data-theme="dark"] {
    color-scheme: dark;
    --page: #0d0c0a; --surface: #17150f; --surface-2: #1e1c14;
    --ink: #faf8f3; --ink-2: #c7c2b3; --ink-muted: #928d7d;
    --hairline: #2b2820; --border: rgba(255,255,255,0.10);
    --accent: #F0A93E; --accent-tint: #3a2c14;
    --good: #38c93d; --good-tint: #17301a;
    --warning: #fab219; --warning-tint: #3a2c0d;
    --serious: #ec835a; --serious-tint: #3a2113;
    --critical: #e66767; --critical-tint: #3a1414;
  }
  :root[data-theme="light"] {
    color-scheme: light;
    --page: #f6f5f1; --surface: #fcfcfa; --surface-2: #f2f0e9;
    --ink: #14120d; --ink-2: #55524a; --ink-muted: #8c887d;
    --hairline: #e4e1d8; --border: rgba(20,18,13,0.10);
    --accent: #B96A17; --accent-tint: #f1e2c9;
    --good: #0ca30c; --good-tint: #dff2df;
    --warning: #b8790a; --warning-tint: #fcecc9;
    --serious: #c14f27; --serious-tint: #fbe1d5;
    --critical: #d03b3b; --critical-tint: #fbdede;
  }
  * { box-sizing: border-box; }
  body { margin: 0; background: var(--page); color: var(--ink); font-family: var(--sans); line-height: 1.5; }
  .wrap { max-width: 1180px; margin: 0 auto; padding: 40px 24px 80px; }
  header.top { display: flex; flex-wrap: wrap; justify-content: space-between; align-items: flex-end; gap: 24px; padding-bottom: 28px; border-bottom: 1px solid var(--hairline); margin-bottom: 28px; }
  .eyebrow { font-family: var(--mono); font-size: 12px; letter-spacing: 0.08em; text-transform: uppercase; color: var(--accent); margin: 0 0 8px; }
  h1 { font-size: clamp(28px, 4vw, 38px); margin: 0 0 10px; text-wrap: balance; letter-spacing: -0.01em; }
  .thesis { max-width: 62ch; color: var(--ink-2); margin: 0; font-size: 15px; }
  .stat-row { display: flex; gap: 28px; flex-wrap: wrap; }
  .stat { text-align: right; }
  .stat .n { font-family: var(--mono); font-size: 26px; font-variant-numeric: tabular-nums; color: var(--ink); display: block; }
  .stat .l { font-size: 11px; color: var(--ink-muted); text-transform: uppercase; letter-spacing: 0.06em; }
  .filters { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 28px; }
  .chip { font-family: var(--mono); font-size: 12.5px; border: 1px solid var(--border); background: var(--surface); color: var(--ink-2); padding: 7px 14px; border-radius: 999px; cursor: pointer; transition: background .15s, color .15s, border-color .15s; }
  .chip:hover { border-color: var(--accent); color: var(--ink); }
  .chip:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
  .chip[aria-pressed="true"] { background: var(--accent); border-color: var(--accent); color: #1a1206; font-weight: 600; }
  .chip .ct { color: inherit; opacity: .65; margin-left: 4px; }
  .role-group { margin-bottom: 36px; }
  .role-group.is-hidden { display: none; }
  .role-head { display: flex; align-items: baseline; gap: 10px; margin-bottom: 14px; }
  .role-head h2 { font-size: 17px; margin: 0; }
  .role-head .tests { font-family: var(--mono); font-size: 12px; color: var(--ink-muted); }
  .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 14px; }
  .card { background: var(--surface); border: 1px solid var(--border); border-radius: var(--radius); padding: 18px 18px 16px; display: flex; flex-direction: column; gap: 12px; }
  .card.is-empty { background: transparent; border-style: dashed; }
  .card-top { display: flex; justify-content: space-between; align-items: flex-start; gap: 10px; }
  .model-name { font-family: var(--mono); font-size: 14.5px; font-weight: 600; word-break: break-word; }
  .model-tag { display: block; font-family: var(--sans); font-size: 11.5px; color: var(--ink-muted); font-weight: 400; margin-top: 2px; }
  .pill { display: inline-flex; align-items: center; gap: 5px; font-size: 11px; font-weight: 600; padding: 4px 9px; border-radius: 999px; white-space: nowrap; }
  .pill .dot { width: 6px; height: 6px; border-radius: 50%; flex: none; }
  .pill.good { background: var(--good-tint); color: var(--good); }
  .pill.good .dot { background: var(--good); }
  .pill.warning { background: var(--warning-tint); color: var(--warning); }
  .pill.warning .dot { background: var(--warning); }
  .pill.serious { background: var(--serious-tint); color: var(--serious); }
  .pill.serious .dot { background: var(--serious); }
  .pill.critical { background: var(--critical-tint); color: var(--critical); }
  .pill.critical .dot { background: var(--critical); }
  .pill.neutral { background: var(--surface-2); color: var(--ink-muted); }
  .pill.neutral .dot { background: var(--ink-muted); }
  .bar-block { display: flex; flex-direction: column; gap: 5px; }
  .bar-labels { display: flex; justify-content: space-between; font-family: var(--mono); font-size: 11.5px; color: var(--ink-muted); }
  .bar-labels b { color: var(--ink); font-weight: 600; }
  .bar-track { position: relative; height: 10px; background: var(--surface-2); border-radius: 5px; overflow: visible; }
  .bar-fill { position: absolute; inset: 0 auto 0 0; height: 100%; border-radius: 5px; background: var(--accent); }
  .bar-fill.flat { background: var(--ink-muted); opacity: .55; }
  .bar-fill.range { background: repeating-linear-gradient(135deg, var(--accent), var(--accent) 4px, transparent 4px, transparent 8px); opacity: .8; }
  .bar-tick { position: absolute; top: -3px; width: 2px; height: 16px; background: var(--ink); opacity: .55; }
  .bar-note { font-size: 11px; color: var(--ink-muted); }
  .finding { font-size: 13px; color: var(--ink-2); margin: 0; }
  .finding b { color: var(--ink); }
  details.more { font-size: 12.5px; }
  details.more > summary { cursor: pointer; color: var(--accent); font-family: var(--mono); font-size: 11.5px; list-style: none; user-select: none; }
  details.more > summary::-webkit-details-marker { display: none; }
  details.more > summary::before { content: "\\25B8 "; }
  details.more[open] > summary::before { content: "\\25BE "; }
  .detail-table { margin-top: 8px; border-top: 1px solid var(--hairline); padding-top: 8px; display: grid; grid-template-columns: auto 1fr; gap: 4px 10px; font-size: 12px; }
  .detail-table dt { font-family: var(--mono); color: var(--ink-2); white-space: nowrap; }
  .detail-table dd { margin: 0; color: var(--ink-muted); }
  .empty-copy { color: var(--ink-muted); font-size: 13px; margin: auto 0; }
  .callout { background: var(--surface-2); border: 1px solid var(--border); border-radius: var(--radius); padding: 16px 18px; display: flex; gap: 14px; align-items: flex-start; margin-bottom: 36px; font-size: 13.5px; color: var(--ink-2); }
  .callout .model-name { flex: none; }
  footer { border-top: 1px solid var(--hairline); padding-top: 20px; margin-top: 20px; font-size: 12.5px; color: var(--ink-muted); display: flex; flex-wrap: wrap; justify-content: space-between; gap: 10px; }
  footer code { font-family: var(--mono); background: var(--surface-2); padding: 1px 5px; border-radius: 4px; }
  @media (prefers-reduced-motion: no-preference) {
    .chip, .card { transition: transform .15s ease, background .15s ease, border-color .15s ease; }
    .card:hover { transform: translateY(-1px); border-color: var(--border); }
  }
"""

JS = """
  const chips = document.querySelectorAll('.chip');
  const groups = document.querySelectorAll('.role-group');
  chips.forEach(chip => {
    chip.addEventListener('click', () => {
      chips.forEach(c => c.setAttribute('aria-pressed', 'false'));
      chip.setAttribute('aria-pressed', 'true');
      const role = chip.dataset.filter;
      groups.forEach(g => {
        g.classList.toggle('is-hidden', role !== 'all' && g.dataset.role !== role);
      });
    });
  });
"""


def esc(s):
    if s is None:
        return ""
    return (str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def render_detail(detail):
    if not detail:
        return ""
    rows = "".join(
        f'<dt>{esc(r["term"])}</dt><dd>{esc(r["def"])}</dd>' for r in detail["rows"]
    )
    return (
        f'<details class="more"><summary>{esc(detail["summary"])}</summary>'
        f'<dl class="detail-table">{rows}</dl></details>'
    )


def render_bar(entry):
    """Returns bar-block HTML, or '' for a qualitative (no clean number) card."""
    bare = entry.get("bare")
    current = entry.get("current")
    note = entry.get("barNote", "")

    if bare is None and current is None:
        return ""

    bare_label = "no bare baseline stated"
    bare_pct = None
    if bare:
        bare_pct = round(100 * bare["pass"] / bare["total"])
        extra = f' ({bare_pct}%)' if "note" not in bare else ""
        bare_label = f'bare {bare["pass"]}/{bare["total"]}{extra}'
        if bare.get("note"):
            bare_label = f'bare {bare["note"]}'

    if current is None:
        # No clean current number -- flat bar at the bare position, real
        # claim lives in currentNote.
        fill_pct = bare_pct or 0
        cur_label = esc(entry.get("currentNote", "unresolved"))
        fill_class = "flat"
    elif "min" in current:
        fill_pct = round(100 * current["max"] / current["total"])
        tick_pct = bare_pct or 0
        cur_label = f'steered {current["min"]}-{current["max"]}/{current["total"]} (flaky)'
        fill_class = "range"
    elif current.get("percent") is not None:
        fill_pct = current["percent"]
        cur_label = esc(entry.get("currentNote") or f'current ~{fill_pct}%*')
        fill_class = ""
    else:
        fill_pct = round(100 * current["pass"] / current["total"])
        approx = "~" if current.get("approx") else ""
        cur_label = f'current {approx}{current["pass"]}/{current["total"]} ({approx}{fill_pct}%)'
        fill_class = "flat" if bare and current["pass"] == bare["pass"] else ""

    tick_pct = bare_pct if bare_pct is not None else 0
    note_html = f'<span class="bar-note">{esc(note)}</span>' if note else ""

    return (
        '<div class="bar-block">'
        f'<div class="bar-labels"><span>{esc(bare_label)}</span><b>{cur_label}</b></div>'
        '<div class="bar-track">'
        f'<div class="bar-fill {fill_class}" style="width:{fill_pct}%"></div>'
        f'<div class="bar-tick" style="left:{tick_pct}%"></div>'
        "</div>"
        f"{note_html}"
        "</div>"
    )


def render_card(entry):
    bar_html = render_bar(entry)
    detail_html = render_detail(entry.get("detail"))
    return (
        '<article class="card">'
        '<div class="card-top">'
        f'<div><span class="model-name">{esc(entry["model"])}</span>'
        f'<span class="model-tag">{esc(entry["role"])}</span></div>'
        f'<span class="pill {entry["status"]}"><span class="dot"></span>{esc(entry["statusLabel"])}</span>'
        "</div>"
        f"{bar_html}"
        f'<p class="finding">{esc(entry["finding"])}</p>'
        f"{detail_html}"
        "</article>"
    )


def render_role_section(role, results):
    entries = [r for r in results if r["role"] == role["id"]]
    if entries:
        cards = "".join(render_card(e) for e in entries)
    elif role["state"] == "scaffold":
        cards = (
            '<article class="card is-empty"><p class="empty-copy">'
            "Scaffold only. Model not downloaded, role not wired up yet."
            "</p></article>"
        )
    else:
        cards = (
            '<article class="card is-empty"><p class="empty-copy">'
            "Task suite built and blind-subagent-validated against the "
            "reference baseline — no real small-model run logged yet."
            "</p></article>"
        )
    return (
        f'<section class="role-group" data-role="{esc(role["id"])}">'
        '<div class="role-head">'
        f'<h2>{esc(role["name"])}</h2><span class="tests">{esc(role["tests"])}</span>'
        "</div>"
        f'<div class="grid">{cards}</div>'
        "</section>"
    )


def render_filters(roles, results):
    chips = ['<button class="chip" data-filter="all" aria-pressed="true">All roles</button>']
    for role in roles:
        n = sum(1 for r in results if r["role"] == role["id"])
        chips.append(
            f'<button class="chip" data-filter="{esc(role["id"])}">'
            f'{esc(role["name"])} <span class="ct">{n}</span></button>'
        )
    return "".join(chips)


def main():
    data = json.loads(DATA_PATH.read_text())
    roles = data["roles"]
    results = data["results"]

    model_slugs = {r["modelSlug"] for r in results} | {
        s.get("modelSlug", s["model"]) for s in data.get("scaffold", [])
    }
    active_roles = sum(1 for r in roles if r["state"] == "active")

    role_sections = "".join(render_role_section(role, results) for role in roles)

    ref = data["referenceBaseline"]
    callout = (
        '<div class="callout">'
        f'<span class="model-name">{esc(ref["model"])}</span>'
        f"<span>{esc(ref['note'])}</span>"
        "</div>"
    )

    html = f"""<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>testlocalai — steering leaderboard</title>
<style>{CSS}</style>
</head>
<body>
<div class="wrap">
  <header class="top">
    <div>
      <p class="eyebrow">testlocalai · not a scoreboard</p>
      <h1>Steering leaderboard</h1>
      <p class="thesis">
        Every row here is a model + role tested against this project's own task
        suite. The number that matters isn't who's on top — it's the gap
        between the <b style="color:var(--ink)">bare</b> tick and the
        <b style="color:var(--ink)">steered</b> fill: how much a documented
        prompt/decoding recipe actually moved a specific model. No fix
        found is reported as plainly as a fix that worked.
      </p>
    </div>
    <div class="stat-row">
      <div class="stat"><span class="n">{len(model_slugs)}</span><span class="l">models profiled</span></div>
      <div class="stat"><span class="n">{len(results)}</span><span class="l">model×role results</span></div>
      <div class="stat"><span class="n">{active_roles}&nbsp;/&nbsp;{len(roles)}</span><span class="l">roles with evidence</span></div>
    </div>
  </header>

  <nav class="filters" id="filters" aria-label="Filter by role">
    {render_filters(roles, results)}
  </nav>

  {role_sections}

  {callout}

  <footer>
    <span>
      Snapshot generated {esc(data["generated"])} from <code>data/leaderboard.json</code>
      (regenerate with <code>python3 bench/leaderboard.py</code>) — not a live
      feed. "bare" = zero-shot under this project's harness; "current" = after
      the quality loop's steering search (see <code>AGENTS.md</code>).
    </span>
    <span>How this differs from a leaderboard like PinchBench: <code>docs/LANDSCAPE-COMPARISON.md</code></span>
  </footer>
</div>
<script>{JS}</script>
</body>
</html>
"""
    OUT_PATH.write_text(html)
    print(f"wrote {OUT_PATH} ({len(results)} results, {len(model_slugs)} models)")


if __name__ == "__main__":
    main()
