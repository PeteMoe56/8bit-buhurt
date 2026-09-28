extends SceneTree
## HOW OFTEN THE PLAYER WINS WORLDS, and every other trophy, over a career.
##
##   godot --headless --path . --script res://tools/probe_worlds.gd -- [seeds] [years] [base]
##
## `career_score`'s "worlds" column is every title the club lifts (league, cups
## and Worlds together); this separates them, so an endgame that is a procession
## can be told apart from a club that is simply winning its own league.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds: int = int(args[0]) if args.size() > 0 else 5
	var years: int = int(args[1]) if args.size() > 1 else 20
	var base: int = int(args[2]) if args.size() > 2 else 4242
	var by_kind := {}
	for i in seeds:
		var s := Season.new(MeleeRosters.starting_club(), base + i)
		Session.season = s
		var m := ProbeManager.new()
		for y in years:
			m.winter(s)
			m.season(s)
			s.roll_over()
		for h in s.honors():
			if int(h.get("champion", -1)) == s.world.player_club:
				var k := String(h.get("name", "?"))
				by_kind[k] = int(by_kind.get(k, 0)) + 1
		var league := 0
		for row in s.world.history:
			if int(row.get("tier", -1)) == League.TIERS.size() - 1 and int(row.get("position", 0)) == 1:
				league += 1
		by_kind["National title"] = int(by_kind.get("National title", 0)) + league
	var keys := by_kind.keys()
	keys.sort()
	for k in keys:
		print("%-28s %5.2f a career" % [k, float(by_kind[k]) / float(seeds)])
	quit(0)
