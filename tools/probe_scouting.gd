extends SceneTree
## IS READING THE SCOUTING RANGE A SKILL?
##
##   bash tools/bb.sh probe scouting [seeds] [years]
##
## Pete's ruling of 27 Sep 2026: a stranger's ceiling shows as a range a captain
## narrows. That is only a decision if reading it well beats reading it badly.
## Four readers, same careers (the five check bases), both managers:
##
##   oracle     sees the true number — no player can; the ceiling of the skill
##   midpoint   takes the middle of the range — the sensible reading
##   optimist   takes the top — believes every scout's best case
##   pessimist  takes the bottom
##   ignore     reads no range: a stranger is worth what he is today
##   blind      reads the public range, as a club with no scout would
##
## `-- [seeds] [years] bargain` ranks the shelf by value for money.
##
## The skill edge is midpoint minus optimist; the price of the fog is oracle
## minus midpoint. If both are inside the noise the range is decoration.

const BASES := [9001, 5150, 2718, 6060, 8123]
var bargain := false
const NAMES := ["oracle", "midpoint", "optimist", "pessimist", "ignore", "blind"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seeds: int = int(args[0]) if args.size() > 0 else 4
	var years: int = int(args[1]) if args.size() > 1 else 20
	bargain = "bargain" in args
	print("\n=== reading the scouting range: %d bases x %d seeds x %d seasons ===\n" % [BASES.size(), seeds, years])
	print("%-10s %-10s %8s %8s %8s %8s" % ["manager", "reader", "title", "t3", "power", "signed"])
	for youth in [false, true]:
		for mode in NAMES.size():
			var title := 0.0
			var t3 := 0.0
			var power := 0.0
			var signed := 0.0
			var n := 0.0
			for b in BASES:
				for i in seeds:
					var r := _one(int(b) + i * 7919, years, youth, mode)
					title += r["title"]
					t3 += r["t3"]
					power += r["power"]
					signed += r["signed"]
					n += 1.0
			print("%-10s %-10s %8.2f %8.2f %8.1f %8.1f" % ["youth" if youth else "plain",
				NAMES[mode], title / n, t3 / n, power / n, signed / n])
	print("\n  title / t3: season first champion / first in the top division (%d = never)" % (years + 1))
	quit(0)


func _one(seed_v: int, years: int, youth: bool, mode: int) -> Dictionary:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	Session.season = s
	var m := ProbeManager.new()
	m.youth = youth
	m.reading = mode
	m.bargain = bargain
	var title := years + 1
	var t3 := years + 1
	var signed := 0
	for y in years:
		signed += m.winter(s)
		m.season(s)
		var t := s.world.player_tier()
		if t >= 3 and t3 > years:
			t3 = y + 1
		if t >= League.TIERS.size() - 1 and s.world.player_champion() and title > years:
			title = y + 1
		s.roll_over()
	return {"title": float(title), "t3": float(t3), "power": float(s.club.power()), "signed": float(signed)}
