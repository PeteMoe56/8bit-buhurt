#!/usr/bin/env python3
"""THE JARGON AUDIT — layer 4 of the novice testing program (1 Oct 2026).

Reads the screens a persona bot saw, in the order it saw them, and for every
game term reports: where a new player first meets it, whether that screen says
what it means, and whether the Guide or a "?" popup does.

    python3 tools/novice/jargon.py <bot.jsonl> [more.jsonl ...] > jargon.md

A term is "explained here" when the first screen carries a definition line for
it ("RD: ...", "TERM is ...", "TERM means ...") or a "?" button. "In the Guide"
means a Guide page line names it. Judgement still has to read the table: this
finds where to look, it does not decide what is clear.
"""
import json, re, sys, os, csv

TERMS = [
    "CC", "$", "XP", "OVR", "POT", "RD", "MG", "PTS", "Base", "Gas", "Strength", "Skill",
    "Aggression", "Rail", "Flanker", "Center", "Rust", "Mild", "Hardened", "Stainless",
    "Titanium", "pass", "bye", "renown", "crowd", "HOLD", "SUB", "RUN", "SKIP ROUND",
    "prospect", "ceiling", "capped", "PEAK", "Journeyman", "Marquee", "backup", "step up",
    "foreign", "Backyard Circuit", "State League", "Regional League", "National Division",
    "invitational", "playoff", "Worlds", "Flying", "Restless", "Mutinous", "Toxic",
    "Light", "Hard", "session", "winter camp", "upkeep", "insurance", "salary cap",
    "gate", "bar", "dues", "Hall", "Meeting", "Leave at home", "specialty", "Clinch",
    "Bullrush", "Takedown", "Break", "Escape", "rating", "morale", "mood", "kit",
    "harness", "armorer", "captain", "regime", "knock", "AST", "DOWNS", "STANDING",
    "Matched", "Sanctioned", "Friendly", "Full Steel", "Hard List", "grade", "difficulty",
    "Squad man", "First team", "chalkboard", "formation", "strategy", "Rush left",
    "Turtle", "2-1-2", "Depth", "Strong left", "playbook", "favorites", "Walk out",
    "corner", "holds", "tabard", "honors", "Polearm", "Pole", "wages", "Re-sign",
    "Extend", "Trade", "Release", "reserve", "bench", "starters", "free agent",
    "Train this week", "Sim it", "level", "points to spend", "Infirmary",
    "Training ground", "Fenced ground", "Arena", "Sports hall", "Club gym", "Back field",
]
SKIP_SCENES = {"Guide"}


def guide_lines(root):
    src = open(os.path.join(root, "scripts/game/guide_scene.gd"), encoding="utf-8").read()
    lines = re.findall(r'UiKit\.t\("((?:[^"\\]|\\.)*)"\)', src)
    coach = open(os.path.join(root, "scripts/game/coach_scene.gd"), encoding="utf-8").read()
    i = coach.find("static func skill_help")
    lines += re.findall(r'UiKit\.t\("((?:[^"\\]|\\.)*)"\)', coach[i:i + 1500])
    return lines


def pat(term):
    if term == "$":
        return re.compile(r"\$")
    return re.compile(r"(?<![A-Za-z])" + re.escape(term) + r"(?![a-z])", re.I if term.islower() else 0)


def defines(lines, term):
    t = re.escape(term)
    rx = re.compile(r"(^|[\s·])" + t + r"\s*(:|=|—| is | means | are )", re.I)
    return any(rx.search(l) for l in lines)


def main():
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    guide = guide_lines(root)
    screens = []
    for path in sys.argv[1:]:
        persona = os.path.basename(path).split("_")[0]
        for line in open(path, encoding="utf-8"):
            e = json.loads(line)
            if e.get("t") == "screen":
                e["persona"] = persona
                screens.append(e)
    rows = []
    for term in TERMS:
        p = pat(term)
        first = None
        seen_on = set()
        explained_anywhere = None
        for s in screens:
            if s["scene"] in SKIP_SCENES:
                continue
            lines = list(s.get("texts", [])) + list(s.get("buttons", []))
            if any(p.search(l) for l in lines):
                seen_on.add(s["scene"])
                if first is None:
                    first = s
                if explained_anywhere is None and defines(lines, term):
                    explained_anywhere = s
        if first is None:
            continue
        flines = list(first.get("texts", [])) + list(first.get("buttons", []))
        here = defines(flines, term)
        q = "?" in first.get("buttons", [])
        in_guide = any(p.search(l) for l in guide)
        guide_def = defines(guide, term)
        rows.append({
            "term": term, "first": "%s (step %d, %s)" % (first["scene"], first["step"], first["persona"]),
            "here": "yes" if here else ("? on screen" if q else "no"),
            "later": ("%s" % explained_anywhere["scene"]) if (explained_anywhere and not here) else "",
            "guide": "defined" if guide_def else ("named" if in_guide else "—"),
            "screens": len(seen_on),
        })
    # Worst first: not explained where met, not defined in the Guide, seen on many screens.
    def rank(r):
        return (r["here"] == "yes", r["guide"] == "defined", -r["screens"])
    rows.sort(key=rank)
    print("| Term | First met | Explained there | Explained later on | Guide | Screens |")
    print("|---|---|---|---|---|---|")
    for r in rows:
        print("| %s | %s | %s | %s | %s | %d |" % (r["term"], r["first"], r["here"], r["later"] or "—",
              r["guide"], r["screens"]))
    n = len(rows)
    print()
    print("%d terms met. Explained where met: %d. Defined in the Guide: %d. Neither: %d." % (
        n, sum(r["here"] == "yes" for r in rows), sum(r["guide"] == "defined" for r in rows),
        sum(r["here"] != "yes" and r["guide"] != "defined" for r in rows)))


if __name__ == "__main__":
    main()
