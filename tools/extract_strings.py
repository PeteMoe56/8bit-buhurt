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

LOCALES = ["en", "es", "fr", "de", "it", "pt_BR", "pl", "uk", "ja"]
OUT = "locale/strings.csv"
LIT = re.compile(r'UiKit\.t\("((?:[^"\\\n]|\\.)*)"\)')

## GDScript's escapes, and only those. `bytes(..).decode("unicode_escape")`
## read the UTF-8 as Latin-1 and turned every dash and middle dot into mojibake,
## so a key with a "—" in it could never match the string the game asks for.
ESC = re.compile(r'\\(u[0-9a-fA-F]{4}|.)')
def unescape(s):
    def one(m):
        c = m.group(1)
        if c[0] == "u" and len(c) == 5:
            return chr(int(c[1:], 16))
        return {"n": "\n", "t": "\t", '"': '"', "\\": "\\", "r": "\r"}.get(c, "\\" + c)
    return ESC.sub(one, s)

## LABEL HELPERS whose first argument is display text they translate themselves.
TN = re.compile(r'UiKit\.tn\(\s*"((?:[^"\\\n]|\\.)*)"\s*,\s*"((?:[^"\\\n]|\\.)*)"')
HELPER = re.compile(r'(?:\b_line|\b_fin_row|\b_stat|\b_book)\(\s*"((?:[^"\\\n]|\\.)*)"')

## DATA TABLES that hold display text and are translated where they are READ
## (`UiKit.t(String(TABLE[i]))`) — a `const` cannot call the translator. Every
## string value in the named declaration is a key; dictionary KEYS are not, and
## nor are values under the fields in SKIP_FIELDS (ids, paths, kinds).
TABLES = {
    "scripts/melee/grade.gd": ["NAME", "SHORT", "BLURB"],
    "scripts/melee/melee_scene.gd": ["NEWS_BAND"],
    "scripts/melee/fighter_trait.gd": ["NAME", "BLURB"],
    "scripts/league/club_office.gd": ["TRAIT_NAME", "TRAIT_BLURB", "REGIME_NAME", "FACILITIES", "CROWD_WORD"],
    "scripts/league/cup.gd": ["ROUND_NAMES"],
    "scripts/league/federation.gd": ["RULE_NAME"],
    "scripts/league/quartermaster.gd": ["GRADE_NAME"],
    "scripts/league/market.gd": ["BAND_NAME"],
    "scripts/league/league.gd": ["TIERS"],
    "scripts/league/arena.gd": ["LEVELS"],
    "scripts/game/create_scene.gd": ["STAT_LABEL", "STAT_BLURB"],
    "scripts/game/records_scene.gd": ["ROWS"],
    "scripts/game/settings_scene.gd": ["ROWS"],
    "scripts/league/venue.gd": ["NAME"],
    "scripts/league/dilemma.gd": ["CARDS", "FX_WORD"],
    "scripts/league/coach.gd": ["OFFER_BLURB"],
    "scripts/league/club_event.gd": ["SLOTS", "BUDGETS"],
    "scripts/game/season_tab_finances.gd": ["NET_WORD"],
    "scripts/game/icon_bank.gd": ["ICONS", "PACK_NAME"],
    "scripts/melee/tuning.gd": ["POS_NAME", "ROLE_NAME", "CONDITION_WORDS", "WEAPON_NAME", "STRATEGIES", "AI_SKILL"],
    "scripts/game/season_scene.gd": ["OFFICE_ROWS", "RESERVE_SORTS"],
    "scripts/game/ticker.gd": ["QUIPS"],
}
SKIP_FIELDS = {"key", "kind", "path", "id", "file", "art", "sound", "code", "short", "icon", "who", "rival"}
STR = re.compile(r'"((?:[^"\\\n]|\\.)*)"')

def table_keys(path, names):
    src = open(path, encoding="utf-8").read()
    out = []
    for nm in names:
        m = re.search(r'^(?:static\s+)?(?:const|var)\s+' + nm + r'\b[^=\n]*:?=\s*', src, re.M)
        if not m:
            continue
        i = m.end()
        opener = src[i]
        if opener not in "[{":
            continue
        closer = "]" if opener == "[" else "}"
        depth, j = 0, i
        while j < len(src):
            c = src[j]
            if c == '"':
                j += 1
                while src[j] != '"':
                    j += 2 if src[j] == "\\" else 1
            elif c == "#":
                while src[j] != "\n":
                    j += 1
            elif c in "[{(":
                depth += 1
            elif c in "]})":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        block = src[i:j + 1]
        block = re.sub(r'#[^\n]*', "", block)
        ## "a " + "b" across lines is one string at runtime, so it is one key.
        block = re.sub(r'"\s*\+\s*"', "", block)
        for sm in STR.finditer(block):
            after = block[sm.end():sm.end() + 3].lstrip()
            if after.startswith(":"):
                continue                      ## a dictionary key
            before = block[:sm.start()].rstrip()
            fm = re.search(r'"(\w+)"\s*:\s*$', before)
            if fm and fm.group(1) in SKIP_FIELDS:
                continue
            t = unescape(sm.group(1))
            if "res://" in t or not re.search(r"[A-Za-z\u00c0-\uffff]", t):
                continue
            out.append(t)
    return out

## SIMPLE CONSTANTS that name things drawn through UiKit.t(): `const LINE_X := "..."`.
## They stay English in data (the books are keyed on them, in the save) and are
## translated where drawn.
SIMPLE = {"scripts/league/club_office.gd": r"LINE_\w+"}

def simple_keys(path, pattern):
    src = open(path, encoding="utf-8").read()
    return [unescape(m.group(1)) for m in
            re.finditer(r'^const\s+' + pattern + r'\s*:?=\s*"((?:[^"\\\n]|\\.)*)"', src, re.M)]

def keys():
    found = []
    seen = set()
    def add(k):
        if k not in seen:
            seen.add(k); found.append(k)
    for f in sorted(glob.glob("scripts/**/*.gd", recursive=True)):
        src = open(f, encoding="utf-8").read()
        for m in LIT.finditer(src):
            add(unescape(m.group(1)))
        for m in TN.finditer(src):
            add(unescape(m.group(1))); add(unescape(m.group(2)))
        for m in HELPER.finditer(src):
            add(unescape(m.group(1)))
    for f, names in TABLES.items():
        if os.path.exists(f):
            for k in table_keys(f, names):
                add(k)
    for f, pat in SIMPLE.items():
        for k in simple_keys(f, pat):
            add(k)
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
