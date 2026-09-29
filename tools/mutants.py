#!/usr/bin/env python3
"""MUTATION CHECK — does the suite notice when a rule breaks? (29 Sep 2026)

    python3 tools/mutants.py              every mutant in MUTANTS
    python3 tools/mutants.py 3 7          just those (1-based)
    bash tools/bb.sh mutants [n ...]      the same, through the toolbox

Each mutant is one deliberate break of a rule a player would notice: the file,
the exact text to replace, what to replace it with, and the test files that
ought to catch it. The file is restored after every run, whatever happens.
The fresh-eyes audit (28 Sep) found half of 26 such breaks got through; the
survivors it named are the first entries here, and every one must be CAUGHT.

A mutant whose `old` text is no longer in the file is reported STALE — the
code moved — so the table cannot quietly stop testing anything.
"""
import os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

MUTANTS = [
    ("round tie-break on downs flipped", "scripts/melee/melee_sim.gd",
     "winner = 0 if round_downs[0] > round_downs[1] else 1",
     "winner = 0 if round_downs[0] < round_downs[1] else 1", ["tests/test_rules.gd"]),
    ("takedown chance ignores how wobbly he is", "scripts/melee/melee_sim.gd",
     "c += (1.0 - d.stability) * Tuning.TD_STABILITY_W",
     "c += d.stability * Tuning.TD_STABILITY_W", ["tests/test_rules.gd"]),
    ("three-to-one stop off by one", "scripts/melee/melee_sim.gd",
     "elif trail <= Tuning.STOP_TRAIL and lead >= Tuning.STOP_LEAD:",
     "elif trail <= Tuning.STOP_TRAIL and lead > Tuning.STOP_LEAD:", ["tests/test_rules.gd"]),
    ("table margin tie-break inverted", "scripts/league/league.gd",
     "return margin_diff(a) > margin_diff(b)",
     "return margin_diff(a) < margin_diff(b)", ["tests/test_rules.gd"]),
    ("fitted harness priced above tournament", "scripts/league/quartermaster.gd",
     "Grade.FITTED: 7,", "Grade.FITTED: 30,", ["tests/test_rules.gd"]),
    ("prize money paid upside down", "scripts/league/season.gd",
     "top * lerpf(1.0, PURSE_TAIL, down)", "top * lerpf(PURSE_TAIL, 1.0, down)",
     ["tests/test_rules.gd"]),
    ("the infirmary makes knocks longer", "scripts/league/season_bouts.gd",
     "maxi(1, int(k[\"events\"]) - s.office.injury_relief()",
     "maxi(1, int(k[\"events\"]) + s.office.injury_relief()", ["tests/test_rules.gd"]),
    ("a level cup tie goes to the lower seed", "scripts/league/cup.gd",
     "m[\"winner\"] = int(m[\"a\"]) if entrants.find(int(m[\"a\"])) \\\n\t\t\t\t< entrants.find",
     "m[\"winner\"] = int(m[\"a\"]) if entrants.find(int(m[\"a\"])) \\\n\t\t\t\t> entrants.find",
     ["tests/test_rules.gd"]),
    ("the prospect's ceiling clamp removed", "scripts/league/season_winter.gd",
     "s.prospect.potential = mini(Career.POTENTIAL_CEILING,\n\t\t\ts.prospect.potential + Career.PROSPECT_GAIN)",
     "s.prospect.potential = s.prospect.potential + Career.PROSPECT_GAIN",
     ["tests/test_rules.gd"]),
    ("the fee priced on the next division's band", "scripts/league/market.gd",
     "BAND_SHARE[band_of(rating, tier)] * float(slack)",
     "BAND_SHARE[band_of(rating, mini(tier + 1, League.TIERS.size() - 1))] * float(slack)",
     ["tests/test_rules.gd"]),
    ("the queue asks promotion before the dilemma", "scripts/league/season.gd",
     "\tif not dilemma.is_empty():\n\t\treturn \"dilemma\"\n\t## AND THE LAST GATE OF THE YEAR: go up, or stay where you are.\n\tif promotion_offered():\n\t\treturn \"promotion\"",
     "\tif promotion_offered():\n\t\treturn \"promotion\"\n\tif not dilemma.is_empty():\n\t\treturn \"dilemma\"",
     ["tests/test_queue.gd"]),
    ("clinch answers land the moment they are tapped", "scripts/melee/melee_sim.gd",
     "\tif m.prompt.menu == Tuning.Menu.GRAPPLED and not clinch_ready(m):\n\t\treturn false",
     "", ["tests/test_clinch.gd"]),
    ("cup nights read the stale static again", "scripts/league/season_bouts.gd",
     "sim.big_occasion = s.mood() != UiKit.Mood.NORMAL",
     "sim.big_occasion = int(Session.bout_mood) != UiKit.Mood.NORMAL", ["tests/test_edges.gd"]),
    ("a dropped save field (records)", "scripts/game/save_game.gd",
     "\"records\": w.records.duplicate(true),", "\"records_x\": w.records.duplicate(true),",
     ["tests/test_edges.gd"]),
    ("the market shows every wage as affordable", "scripts/game/market_scene.gd",
     "var room: bool = season.office.can_afford_wage(season.club, f)", "var room: bool = true",
     ["tests/test_edges.gd"]),
    ## THE SECOND FRESH AUDIT'S OWN SET (29 Sep 2026, 4 AM): 14 of its 21 got
    ## through the suite before tests/test_loop.gd.
    ('relegation takes 2nd-last not last', 'scripts/league/league.gd',
     'sorted_rows.size() - 1 - i]["club"]',
     'sorted_rows.size() - 2 - i]["club"]', ["tests/test_loop.gd"]),
    ('knockout margin tie-break inverted', 'scripts/league/cup.gd',
     'm["winner"] = int(m["a"]) if ma > mb else int(m["b"])',
     'm["winner"] = int(m["a"]) if ma < mb else int(m["b"])', ["tests/test_loop.gd"]),
    ('prize purse shrinks with tier', 'scripts/league/season.gd',
     '(1.0 + float(maxi(0, tier)) * PURSE_TIER_STEP)',
     '(1.0 - float(maxi(0, tier)) * PURSE_TIER_STEP * 0.5)', ["tests/test_loop.gd"]),
    ('injuries never heal', 'scripts/league/season_bouts.gd',
     'f.injury -= 1',
     'f.injury -= 0', ["tests/test_loop.gd"]),
    ('simmed matchday pays no XP', 'scripts/league/season_bouts.gd',
     'f.xp += Season.XP_SIMMED',
     'f.xp += 0', ["tests/test_loop.gd"]),
    ('availability roll inverted', 'scripts/league/season_bouts.gd',
     'rng.randf() < Season.AVAILABILITY_CHANCE',
     'rng.randf() > Season.AVAILABILITY_CHANCE', ["tests/test_loop.gd"]),
    ('practice pays 1 XP', 'scripts/league/season_bouts.gd',
     'f.xp += maxi(1, int(round(got)))',
     'f.xp += maxi(1, int(round(got * 0.0)))', ["tests/test_loop.gd"]),
    ('tired men run faster', 'scripts/melee/melee_sim.gd',
     'v *= lerpf(Tuning.SPEED_EMPTY_FLOOR, 1.0, m.gas_frac())',
     'v *= lerpf(1.0, Tuning.SPEED_EMPTY_FLOOR, m.gas_frac())', ["tests/test_loop.gd"]),
    ('bench loses condition in the corner', 'scripts/melee/melee_sim.gd',
     '+ Tuning.BENCH_RECOVER',
     '- Tuning.BENCH_RECOVER', ["tests/test_loop.gd"]),
    ('bout level on rounds goes to fewer downs', 'scripts/melee/melee_sim.gd',
     'return 0 if downs[0] > downs[1] else 1',
     'return 0 if downs[0] < downs[1] else 1', ["tests/test_loop.gd"]),
    ('ground condition reset on load', 'scripts/league/club_office.gd',
     'clampf(float(d.get("arena_condition", 1.0)), 0.0, 1.0)',
     'clampf(1.0, 0.0, 1.0)', ["tests/test_loop.gd"]),
    ('Toxic morale band shrunk', 'scripts/melee/fighter_card.gd',
     'if morale >= 0.18:',
     'if morale >= 0.08:', ["tests/test_loop.gd"]),
    ('retirement starts at 27', 'scripts/game/career.gd',
     '\tif f.age < RETIRE_FROM:\n\t\treturn 0.0',
     '\tif f.age < RETIRE_FROM - 6:\n\t\treturn 0.0', ["tests/test_loop.gd"]),
    ('squad armour colour inverted', 'scripts/game/season_tab_squad.gd',
     'return UiKit.UP if a > 0.85 else',
     'return UiKit.UP if a < 0.85 else', ["tests/test_loop.gd"]),
]


def run(tests):
    cmd = ["bash", "tools/run_tests.sh"] + tests
    p = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=1800)
    return "SUITE GREEN" in p.stdout, p.stdout


def main():
    pick = [int(a) for a in sys.argv[1:] if a.isdigit()]
    rows = []
    for n, (name, path, old, new, tests) in enumerate(MUTANTS, 1):
        if pick and n not in pick:
            continue
        full = os.path.join(ROOT, path)
        src = open(full, encoding="utf-8").read()
        if src.count(old) != 1:
            rows.append((n, name, "STALE", "old text found %d times in %s" % (src.count(old), path)))
            continue
        try:
            open(full, "w", encoding="utf-8").write(src.replace(old, new, 1))
            green, _ = run(tests)
        finally:
            open(full, "w", encoding="utf-8").write(src)
        rows.append((n, name, "SURVIVED" if green else "CAUGHT", ", ".join(os.path.basename(t) for t in tests)))
        print("%2d  %-9s %s" % (n, rows[-1][2], name), flush=True)
    caught = sum(1 for r in rows if r[2] == "CAUGHT")
    print("\n%d of %d caught" % (caught, len(rows)))
    for r in rows:
        if r[2] != "CAUGHT":
            print("  %s  #%d %s — %s" % (r[2], r[0], r[1], r[3]))
    sys.exit(0 if caught == len(rows) else 1)


if __name__ == "__main__":
    main()
