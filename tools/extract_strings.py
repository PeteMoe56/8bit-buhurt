#!/usr/bin/env python3
"""Collect every UiKit.t("...") in the game into locale/strings.csv.

    python3 tools/extract_strings.py

The CSV is Godot's translation format: first column `keys` (the English text,
which is also the English translation), then one column per locale. Existing
translations are kept; keys no longer in the code are dropped; new keys get an
empty cell for every other language. Godot imports it on the next editor or
`--import` run and `project.godot` lists the generated .translation files.

Locales are the Play listing's nine. Add a column here to add a language.
"""
import csv, glob, os, re

LOCALES = ["en", "es", "fr", "de", "it", "pt_BR", "pl", "ru", "ja"]
OUT = "locale/strings.csv"
LIT = re.compile(r'UiKit\.t\("((?:[^"\\\n]|\\.)*)"\)')

def keys():
    found = []
    seen = set()
    for f in sorted(glob.glob("scripts/**/*.gd", recursive=True)):
        for m in LIT.finditer(open(f, encoding="utf-8").read()):
            k = bytes(m.group(1), "utf-8").decode("unicode_escape")
            if k not in seen:
                seen.add(k); found.append(k)
    return found

def main():
    old = {}
    if os.path.exists(OUT):
        with open(OUT, encoding="utf-8", newline="") as fh:
            for row in csv.DictReader(fh):
                old[row["keys"]] = row
    ks = keys()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="") as fh:
        w = csv.writer(fh, lineterminator="\n")
        w.writerow(["keys"] + LOCALES)
        for k in ks:
            prev = old.get(k, {})
            w.writerow([k] + [k if loc == "en" else prev.get(loc, "") for loc in LOCALES])
    done = {loc: sum(1 for k in ks if old.get(k, {}).get(loc)) for loc in LOCALES[1:]}
    print(f"{len(ks)} strings -> {OUT}; translated so far: " +
          ", ".join(f"{l} {n}" for l, n in done.items()))

if __name__ == "__main__":
    main()
