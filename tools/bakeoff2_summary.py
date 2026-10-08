#!/usr/bin/env python3
"""Means by policy from docs/bakeoff-2/{flow,scores}_policies.tsv. No judgement,
no filtering: every row counts. Writes docs/bakeoff-2/summary_by_policy.tsv."""
import csv, collections, os
d = os.path.join(os.path.dirname(__file__), "..", "docs", "bakeoff-2")
flow = list(csv.DictReader(open(os.path.join(d, "flow_policies.tsv")), delimiter="\t"))
sc = collections.defaultdict(list)
for line in open(os.path.join(d, "scores_policies.tsv")).read().splitlines()[1:]:
    p, b, l = line.split("\t")
    sc[p].append({k: float(v) for k, v in (kv.split("=") for kv in l.split())})
order = []
for r in flow:
    if r["policy"] not in order:
        order.append(r["policy"])
cols = ["policy", "flow_rows", "lv_winter_per_season", "lv_in_season_per_season", "lv_pts_winter_per_season",
        "harness_cc_per_season", "cc_in_per_season", "cc_out_per_season", "power_s12", "bank_s12", "tier_s12",
        "score_title", "score_t1", "score_t2", "score_t3", "score_power_s14", "score_cc", "score_titles_counter", "score_youth_title"]
out = [cols]
for p in order:
    rs = [r for r in flow if r["policy"] == p]
    last = [r for r in rs if r["season"] == "12"]
    m = lambda k, rr: sum(float(r[k]) for r in rr) / len(rr)
    s = sc[p]
    ms = lambda k: sum(x[k] for x in s) / len(s)
    out.append([p, len(rs)] + [round(v, 2) for v in [m("lv", rs), m("lv_season", rs), m("lv_pts", rs), m("harness_cc", rs),
        m("cc_in", rs), m("cc_out", rs), m("power", last), m("bank", last), m("tier", last),
        ms("title"), ms("t1"), ms("t2"), ms("t3"), ms("power"), ms("cc"), ms("worlds"), ms("youth_title")]])
with open(os.path.join(d, "summary_by_policy.tsv"), "w") as f:
    for row in out:
        f.write("\t".join(str(x) for x in row) + "\n")
print(open(os.path.join(d, "summary_by_policy.tsv")).read())
