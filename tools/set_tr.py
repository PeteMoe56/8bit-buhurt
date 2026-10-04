#!/usr/bin/env python3
"""Set translations in locale/strings.csv without hand-editing CSV.

    python3 tools/set_tr.py edits.json

edits.json: {"English key": ["es","fr","de","it","pt_BR","pl","uk","ja"], ...}
            or {"English key": {"de": "...", "fr": "..."}} to change some columns.
A key not yet in the table is appended (run `bb strings` after to reorder/prune).
Quoting is left to the csv module, so commas inside a translation are safe.
"""
import csv, io, json, sys

LANGS = ["es", "fr", "de", "it", "pt_BR", "pl", "uk", "ja"]
path = "locale/strings.csv"
edits = json.load(open(sys.argv[1], encoding="utf-8"))
rows = list(csv.reader(open(path, encoding="utf-8")))
head = rows[0]
col = {name: i for i, name in enumerate(head)}
seen = set()
for r in rows[1:]:
    if not r or r[0] not in edits:
        continue
    seen.add(r[0])
    while len(r) < len(head):
        r.append("")
    e = edits[r[0]]
    if isinstance(e, list):
        e = dict(zip(LANGS, e))
    for lang, val in e.items():
        r[col[lang]] = val
for k, e in edits.items():
    if k in seen:
        continue
    if isinstance(e, list):
        e = dict(zip(LANGS, e))
    r = [k, k] + [""] * (len(head) - 2)
    for lang, val in e.items():
        r[col[lang]] = val
    rows.append(r)
out = io.StringIO()
csv.writer(out, lineterminator="\n").writerows(rows)
open(path, "w", encoding="utf-8").write(out.getvalue())
print("set %d keys (%d new)" % (len(edits), len(edits) - len(seen)))
