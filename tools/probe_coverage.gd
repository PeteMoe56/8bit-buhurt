extends SceneTree
## WHAT MORE NAMES ON THE SHELF ARE WORTH — the other half of scouting.
##
##   bash tools/bb.sh probe coverage [seeds] [years]
##
## Football Manager's scouts pay two ways: they see a man truly, and they FIND
## more men. The first buys nothing here (probe_scouting); this measures the
## second: the same careers with 0, 3, 6 and 9 extra names on every shelf.

const BASES := [9001, 5150, 2718, 6060, 8123]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds: int = int(args[0]) if args.size() > 0 else 4
	var years: int = int(args[1]) if args.size() > 1 else 20
	print("\n=== extra names on the shelf: %d bases x %d seeds x %d seasons ===\n" % [BASES.size(), seeds, years])
	print("%-8s %-7s %8s %8s %8s %8s" % ["manager", "extra", "title", "t3", "power", "signed"])
	for youth in [false, true]:
		for extra in [0, 3, 6, 9]:
			Market.probe_extra = extra
			var t := 0.0
			var t3 := 0.0
			var p := 0.0
			var sg := 0.0
			var n := 0.0
			for b in BASES:
				for i in seeds:
					var s := Season.new(MeleeRosters.starting_club(), int(b) + i * 7919)
					Session.season = s
					var m := ProbeManager.new()
					m.youth = youth
					m.reading = ProbeManager.Read.MIDPOINT
					var won := years + 1
					var up := years + 1
					for y in years:
						sg += m.winter(s)
						m.season(s)
						if s.world.player_tier() >= 3 and up > years:
							up = y + 1
						if s.world.player_tier() >= League.TIERS.size() - 1 \
								and s.world.player_champion() and won > years:
							won = y + 1
						s.roll_over()
					t += won
					t3 += up
					p += s.club.power()
					n += 1.0
			print("%-8s %-7d %8.2f %8.2f %8.1f %8.1f" % ["youth" if youth else "plain",
				extra, t / n, t3 / n, p / n, sg / n])
	Market.probe_extra = 0
	quit(0)
