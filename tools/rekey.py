#!/usr/bin/env python3
"""RENAME AN ENGLISH STRING EVERYWHERE, KEEPING ITS TRANSLATIONS (29 Sep 2026).

    python3 tools/rekey.py map.tsv        one "old<TAB>new" pair per line
    python3 tools/rekey.py --dry map.tsv  report only

The English text IS the key (`UiKit.t("...")`), so changing a word in English
means changing the key in every script that says it and in locale/strings.csv —
and without care the eight drafts lose that row and read blank. This does all
three at once: every exact "old" literal in scripts/**/*.gd becomes "new", the
CSV row's key and en column become "new", and the other columns are kept. Then
run tools/extract_strings.py as usual; it must report no new blanks.

An old key found in no script, or found more than once in the CSV, stops the
run before anything is written.
"""
import csv, glob, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def esc(s):
    return s.replace("\\", "\\\\").replace('"', '\\"')


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry = "--dry" in sys.argv
    pairs = []
    for line in open(args[0], encoding="utf-8"):
        line = line.rstrip("\n")
        if not line.strip() or line.startswith("#"):
            continue
        old, new = line.split("\t")
        pairs.append((old, new))
    files = glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True)
    src = {f: open(f, encoding="utf-8").read() for f in files}
    csv_path = os.path.join(ROOT, "locale", "strings.csv")
    rows = list(csv.reader(open(csv_path, encoding="utf-8")))
    bad = []
    for old, new in pairs:
        lit = '"%s"' % esc(old)
        n = sum(s.count(lit) for s in src.values())
        k = sum(1 for r in rows[1:] if r[0] == old)
        if n == 0 or k != 1:
            bad.append("%r: %d script uses, %d CSV rows" % (old, n, k))
        print("%3d uses  %s  ->  %s" % (n, old[:60], new[:60]))
    if bad:
        print("\nSTOPPED:\n  " + "\n  ".join(bad))
        sys.exit(1)
    if dry:
        return
    for old, new in pairs:
        lit, nlit = '"%s"' % esc(old), '"%s"' % esc(new)
        for f in src:
            src[f] = src[f].replace(lit, nlit)
        for r in rows[1:]:
            if r[0] == old:
                r[0] = new
                r[1] = new
    for f, s in src.items():
        if open(f, encoding="utf-8").read() != s:
            open(f, "w", encoding="utf-8").write(s)
    csv.writer(open(csv_path, "w", encoding="utf-8", newline="")).writerows(rows)
    print("\n%d keys renamed. Now: python3 tools/extract_strings.py" % len(pairs))


if __name__ == "__main__":
    main()
