#!/usr/bin/env python3
"""One markdown table per batch of novice runs: persona, seasons, titles,
promotions, top tier, credits at the end, first milestones (1 Oct 2026).

    python3 tools/novice/summarize.py <run.jsonl> [...]
"""
import json, sys, os, collections

print("| run | seasons | promotions | relegations | top tier | Backyard titles | trophies | CC at end | peak CC | signings | first win | first promotion |")
print("|---|---|---|---|---|---|---|---|---|---|---|---|")
for path in sys.argv[1:]:
    ev = []
    for line in open(path, encoding="utf-8"):
        try:
            ev.append(json.loads(line))
        except ValueError:
            pass
    se = [e for e in ev if e.get("t") == "season_end"]
    ms = [e for e in ev if e.get("t") == "milestone"]
    end = next((e for e in ev if e.get("t") == "end"), {})
    promos = sum(1 for m in ms if m.get("kind") == "promoted")
    rel = sum(1 for m in ms if m.get("kind") == "relegated")
    trophies = [m for m in ms if m.get("kind") == "trophy"]
    by_titles = sum(1 for m in trophies if m.get("id") == "playoff:0")
    top = max([e.get("tier", 0) for e in se] + [end.get("tier", 0) or 0])
    fw = next((m.get("season") for m in ms if m.get("kind") == "first_win"), "—")
    fp = next((m.get("season") for m in ms if m.get("kind") == "first_promotion"), "—")
    ## SIGNINGS: presses on the market's Sign button (1 Oct, lane B: the gold
    ## bot signed nobody in 60 seasons and the table could not say so).
    signs = sum(1 for e in ev if e.get("t") == "press" and e.get("scene") == "Market"
                and str(e.get("label", "")).lower().startswith("sign"))
    peak = max([e.get("credits", 0) for e in se] or [0])
    print("| %s | %d | %d | %d | %d | %d | %d | %s | %s | %s | %s | %s |" % (
        os.path.basename(path).replace(".jsonl", ""), len(se), promos, rel, top, by_titles,
        len(trophies), end.get("credits", se[-1]["credits"] if se else "—"), peak, signs, fw, fp))
