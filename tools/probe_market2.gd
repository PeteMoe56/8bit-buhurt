extends SceneTree
## WHAT CAN A CLUB ACTUALLY BUY, AND WHAT IS IT ALREADY HOLDING?
##
##   godot --headless --path . --script res://tools/probe_market2.gd
##
## `tools/probe_dev.gd` put a number on the training half: with the price and the
## throttle both removed, 245 levels over twelve seasons are worth **+4 club
## power**, because `power_exact()` is the mean of the STARTING FIVE and a level
## is one point on one of four stats — 0.05 of a club rating, and nothing at all
## if the man is a reserve or already at his ceiling.
##
## So training cannot climb the ladder and was never going to. The other road is
## the market, which is how every football manager actually goes up. This asks
## whether that road exists: what the starting squad is capable of, and what is
## on the shelf at each tier against what a club at that tier can pay.
func _initialize() -> void:
	print("\n=== the squad you are given ===\n")
	var club := MeleeRosters.starting_club()
	print("%-16s %4s %4s %5s %4s %s" % ["name", "now", "max", "head", "age", "in the five"])
	var five := club.starting_five()
	for f in club.roster:
		print("%-16s %4d %4d %5d %4d %s" % [f.display_name, f.overall(),
			f.potential, f.headroom(), f.age, "*" if five.has(f) else ""])
	print("\nclub power (mean of the five): %d" % club.power())
	print("the Backyard band is %s and its clubs drift to the middle of it"
		% str(League.TIERS[0]["power"]))

	print("\n=== and what is on the shelf ===\n")
	print("%-18s %5s %5s %5s %6s %7s %8s" % [
		"division", "best", "max", "age", "fee", "wage", "income/yr"])
	for t in League.TIERS.size():
		var s := Season.new(MeleeRosters.starting_club(), 4242)
		s.world.clubs[s.world.player_club]["tier"] = t
		s.world._new_season()
		s.office.tier = t
		var pool: Array = s.market()
		if pool.is_empty():
			print("%-18s   (nothing)" % League.tier_name(t))
			continue
		pool.sort_custom(func(a, b): return a.overall() > b.overall())
		var f: FighterCard = pool[0]
		print("%-18s %5d %5d %5d %6d %7s %8s" % [
			League.tier_name(t), f.overall(), f.potential, f.age,
			s.market_fee(f), ClubOffice.money(s.market_wage(f)),
			"~%d" % [[33, 66, 77, 97][t]]])
		## AND THE WHOLE LIST, because the top of it is not the interesting part —
		## what matters is whether there is anything a club can carry.
		var line: Array[String] = []
		for g in pool:
			line.append("%d/%d %dy %dCC" % [g.overall(), g.potential, g.age,
				s.market_fee(g)])
		print("      " + "  ·  ".join(line))
	print("")
	quit(0)
