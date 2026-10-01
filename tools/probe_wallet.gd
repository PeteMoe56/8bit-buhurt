extends SceneTree
## WHAT A SEASON IS WORTH, DIVISION BY DIVISION.
##
##   godot --headless --path . --script res://tools/probe_wallet.gd
##
## `tools/probe_shelf.gd` found that a signing fee almost never refuses: 97-100%
## of every shelf is inside a club's reach at every rung. The reason is that
## The fee was FLAT across the pyramid — a Star cost 18 CC in the Backyard
## Circuit and 18 CC at National — while the money a club has plainly is not
## flat. So this measures the one number the fee has to be a fraction OF,
## because **a cost that is not derived from the thing it is a cost of will
## eventually exceed it, or stop mattering.** Here it stopped mattering.
##
## No manager, no policy, no spending. A club is placed at each rung at that
## division's own standard and the season is played out; what it prints is what
## came IN, and what was left after the bills the club could not avoid.
const SEASONS := 12
const SEEDS: Array[int] = [4242, 90210, 31337]


func _initialize() -> void:
	print("\n=== what a season is worth, by division ===\n")
	print("%-19s %7s %7s %7s %7s %8s" % [
		"division", "in", "upkeep", "dues", "slack", "a Star"])
	for t in League.TIERS.size():
		var income := 0.0
		var upkeep := 0.0
		var years := 0
		for seed_v in SEEDS:
			var s := _club_at(t, seed_v)
			for y in SEASONS:
				_season(s)
				var last: Dictionary = s.office.books_last
				income += float(ClubOffice.book_total(last.get("in", {})))
				var o: Dictionary = last.get("out", {})
				upkeep += float(o.get(ClubOffice.LINE_GROUND, 0)) \
					+ float(o.get(ClubOffice.LINE_FACILITIES, 0)) \
					+ float(o.get(ClubOffice.LINE_TRAVEL, 0))
				s.roll_over()
				years += 1
		var n := float(maxi(1, years))
		var dues := float(League.dues_for(t))
		var slack := income / n - upkeep / n - dues
		print("%-19s %7.1f %7.1f %7.1f %7.1f %8d" % [
			League.tier_name(t), income / n, upkeep / n, dues, slack,
			Market.fee(int(League.TIERS[t]["shelf"][1]), t)])
	print("")
	print("in       every credit the books took that season")
	print("upkeep   ground, facilities and travel — the bills a club cannot skip")
	print("slack    what is left to spend on the squad")
	print("a Star   the top ordinary fee band — now a share of the slack beside it,")
	print("         which is what League.TIERS[t][\"slack\"] was measured for")
	print("")
	quit(0)


## A CLUB PLACED AT A RUNG AT THAT RUNG'S OWN STANDARD. Not a Backyard club
## dropped into National — that measures a relegation, not a division.
func _club_at(tier: int, seed_v: int) -> Season:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	Session.season = s
	## WALK THE SQUAD TO THE DIVISION'S OWN STANDARD. Same method
	## `ClubFactory._tune_to` uses and for the same reason: `power()` is an
	## average of position averages with armor inside it, so generating around a
	## target and hoping lands several points off. This calls `power()` and stops,
	## which cannot drift out of agreement with it.
	var band: Array = League.TIERS[tier]["power"]
	var mid := int(lerpf(float(band[0]), float(band[1]), 0.5))
	for _pass in 40:
		var now: int = s.club.power()
		if now == mid:
			break
		var step := 1 if now < mid else -1
		for f in s.club.roster:
			f.strength = clampi(f.strength + step, 1, 99)
			f.base = clampi(f.base + step, 1, 99)
			f.skill = clampi(f.skill + step, 1, 99)
			f.gas = clampi(f.gas + step, 1, 99)

	## AND PUT HIM IN THE DIVISION, BY SWAPPING WITH SOMEBODY ALREADY IN IT.
	##
	## Three wrong roads were tried first and each one is instructive. Setting the
	## tier field alone leaves the club with tier 0's fixture list — one
	## division's calendar against another division's purse. Rolling the season
	## over to rebuild it crashes, because `roll_over` looks the player up in the
	## table of the division he finished in and he was never in it. And promoting
	## him honestly means winning, which is the thing being measured.
	##
	## A SWAP is the answer, because it is the only move that leaves the pyramid
	## the shape the world's own soak test insists on: every division keeps its
	## club count, nobody is invented, nobody vanishes. `_new_season` then rebuilds
	## the schedules and the tables from the tiers, which is exactly what it does
	## every summer — the fixture reaches for it directly only because there is no
	## public door onto "start a fresh season where everybody already is."
	var here: Array = s.world.clubs_in(tier)
	if not here.is_empty():
		var other: int = int(here[0])
		s.world.clubs[other]["tier"] = s.world.player_tier()
		s.world.clubs[s.world.player_club]["tier"] = tier
		s.world._new_season()
	s.office.tier = s.world.player_tier()

	## AND A GROUND TO MATCH. A National club in a back field is not a National
	## club — the gate is the biggest line in the books and it is set by the
	## ground, so leaving every rung at level 1 would measure one arena four times.
	var want := mini(tier + 2, Arena.LEVELS.size() - 1)
	while s.office.arena.level < want:
		s.office.arena.level += 1
	s.office.arena.condition = 1.0
	s.office.fans = s.office.fan_cap() * 0.6
	return s


func _season(s: Season) -> void:
	var guard := 0
	while guard < 60:
		guard += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid": s.decline_bid()
				"dilemma": s.answer_dilemma(0)
				"sendoff": s.answer_send_off()
				"cup": s.sim_cup_tie()
				"promotion": s.answer_promotion(false)
		if s.season_complete():
			break
		s.skip_event()
