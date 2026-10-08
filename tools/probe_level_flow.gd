extends SceneTree
## WHERE THE LEVELS AND THE MONEY COME FROM, SEASON BY SEASON (8 Oct 2026).
##
##   godot --headless --path . --script res://tools/probe_level_flow.gd -- [seeds] [years] [base...]
##
## Bake-off #1 (AI-TEAM.md): testers say levels and money climb faster since
## 1.0.1. This runs the standard `ProbeManager` career (the `bb.sh score`
## player) and splits each season into the flows a verdict needs, so the SAME
## file can be run on two builds and diffed:
##
##   season_pts   stat points gained DURING the season by men on the books at
##                both ends (sessions, form, ageing — net)
##   lv           levels taken at the winter (ProbeManager spends every one,
##                through the automatic `Career.level_up` path)
##   lv_pts       stat points those levels added
##   unspent      levels still waiting after the winter
##   cc_in/out    the season's closed books (`books_last`), totals
##   top_in       the three biggest income lines
##   bank         credits at the end of the season
##
## Caveats a reader must carry: ProbeManager never calls `Career.level_into`
## (the manual path a player uses, changed in 1.0.1) and never buys harness, and
## reads hidden ceilings (ORACLE). Rows are one TSV line each, prefixed FLOW.

const BASES := [9001, 5150, 2718, 6060, 8123]


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var seeds: int = int(a[0]) if a.size() > 0 else 2
	var years: int = int(a[1]) if a.size() > 1 else 10
	var bases: Array = []
	for i in range(2, a.size()):
		bases.append(int(a[i]))
	if bases.is_empty():
		bases = BASES
	print("FLOW\tbase\tseed\tseason\ttier\tseason_pts\tlv\tlv_pts\tunspent\tcc_in\tcc_out\tbank\ttop_in")
	for b in bases:
		for i in seeds:
			_one(int(b), int(b) + i * 7919, years)
	quit(0)


static func _sum(f: FighterCard) -> int:
	return f.strength + f.base + f.skill + f.gas


static func _snap(s: Season) -> Dictionary:
	var d := {}
	for f in s.club.roster:
		d[f.get_instance_id()] = {"lv": f.level, "pts": _sum(f)}
	return d


static func _unspent(s: Season) -> int:
	var n := 0
	for f in s.club.roster:
		if Career.can_level(f) and not Career.at_ceiling(f):
			n += 1
	return n


func _one(base: int, seed_v: int, years: int) -> void:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	Session.season = s
	var m := ProbeManager.new()
	for y in years:
		var before_w := _snap(s)
		m.winter(s)
		var lv := 0
		var lv_pts := 0
		for f in s.club.roster:
			var k := f.get_instance_id()
			if before_w.has(k):
				lv += f.level - int(before_w[k]["lv"])
				lv_pts += _sum(f) - int(before_w[k]["pts"])
		var unspent := _unspent(s)
		var start := _snap(s)
		m.season(s)
		var season_pts := 0
		for f in s.club.roster:
			var k := f.get_instance_id()
			if start.has(k):
				season_pts += _sum(f) - int(start[k]["pts"])
		var tier := s.world.player_tier()
		s.roll_over()
		var bk: Dictionary = s.office.books_last
		var bin: Dictionary = bk.get("in", {})
		var bout: Dictionary = bk.get("out", {})
		var tin := 0
		for v in bin.values():
			tin += int(v)
		var tout := 0
		for v in bout.values():
			tout += int(v)
		var lines: Array = bin.keys()
		lines.sort_custom(func(x, z): return int(bin[x]) > int(bin[z]))
		var top: Array = []
		for j in mini(3, lines.size()):
			top.append("%s=%d" % [lines[j], int(bin[lines[j]])])
		print("FLOW\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s" % [base, seed_v, y + 1, tier,
			season_pts, lv, lv_pts, unspent, tin, tout, s.office.credits, ",".join(top)])
