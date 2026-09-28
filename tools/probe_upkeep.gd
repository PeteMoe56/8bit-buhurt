extends SceneTree
## WHAT A SENSIBLE CLUB LOSES TO UNPAID SUMMERS, by grade and by kind.
##
##   bash tools/bb.sh probe upkeep [seeds] [years]
##
## probe_run counted 4-15 losses a career, most at Friendly. That manager has its
## own policy; this plays the shared ProbeManager (the one pacing is measured
## with) at every grade and splits the count: a building that fell a level, a
## federation certificate that lapsed — and whether it happened the summer the
## club was promoted, which is when the bills jump.

const BASES := [9001, 5150, 2718, 6060, 8123]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds: int = int(args[0]) if args.size() > 0 else 2
	var years: int = int(args[1]) if args.size() > 1 else 20
	print("\n=== unpaid summers: %d bases x %d seeds x %d seasons, ProbeManager ===\n" % [BASES.size(), seeds, years])
	print("%-14s %8s %8s %8s %10s %10s %8s" % ["grade", "fell", "lapsed", "careers", "on promo", "in red", "title"])
	for g in Grade.G.values():
		var fell := 0.0
		var lapsed := 0.0
		var promo := 0.0
		var red := 0.0
		var title := 0.0
		var n := 0.0
		for b in BASES:
			for i in seeds:
				var r := _one(int(b) + i * 7919, years, int(g))
				fell += r["fell"]
				lapsed += r["lapsed"]
				promo += r["promo"]
				red += r["red"]
				title += r["title"]
				n += 1.0
		print("%-14s %8.2f %8.2f %8d %10.2f %10.2f %8.2f" % [Grade.name_of(int(g)), fell / n,
			lapsed / n, int(n), promo / n, red / n, title / n])
	print("\n  fell: a building down a level; lapsed: a federation certificate gone;")
	print("  on promo: losses in the summer of a promotion; in red: summers ending below 0 CC")
	quit(0)


func _one(seed_v: int, years: int, grade: int) -> Dictionary:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	Session.season = s
	s.set_grade(grade)
	var m := ProbeManager.new()
	var out := {"fell": 0.0, "lapsed": 0.0, "promo": 0.0, "red": 0.0, "title": float(years + 1)}
	for y in years:
		m.winter(s)
		m.season(s)
		if s.world.player_tier() >= League.TIERS.size() - 1 and s.world.player_position() == 1 \
				and out["title"] > years:
			out["title"] = float(y + 1)
		var was := s.world.player_tier()
		s.roll_over()
		var f := float((s.last_upkeep.get("lost", []) as Array).size())
		var l := float((s.last_upkeep.get("lapsed", []) as Array).size())
		out["fell"] += f
		out["lapsed"] += l
		if s.world.player_tier() > was:
			out["promo"] += f + l
		if s.office.credits < 0:
			out["red"] += 1.0
	return out
