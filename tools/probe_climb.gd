extends SceneTree
## CAN THE PLAYER GO UP AT ALL?
##
## The season-review shot needed a club in tier 2 to fill both its columns and
## could not get one: thirty seasons of spending on levels finished in the same
## division it started in. That is either a manager too dull to win or a ladder
## nobody can climb, and those are very different problems.
##
## So: the same walk, instrumented. Rating, finish and tier every year.
func _initialize() -> void:
	## THREE MANAGERS, and the third is the one Pete described. The walker is the
	## floor — he never renews a contract, so his squad drains to six men rated 21
	## in a division of forties and there is no road back. The spender buys levels
	## and places them. The KEEPER does what any player does in the first ten
	## seconds of a winter: he re-signs the men whose deals are running out.
	for spend in [0, 1, 2]:
		var s := Season.new(MeleeRosters.starting_club(), 90210)
		Session.season = s
		var line: Array[String] = []
		for year in 14:
			if spend == 2:
				## THE WINTER, THE WAY A PLAYER SPENDS IT. Extend whoever can be
				## extended, re-sign whoever is out of contract, cheapest first,
				## until the cap or the money runs out.
				s.office.credits += 120
				for f in s.club.roster:
					if Contracts.can_extend(f):
						s.extend(f)
					else:
						s.resign(f)
			if spend == 1:
				s.office.credits += 120
				## BUY THE XP, THEN PLACE THE POINT. Two steps, and the first
				## version of this probe only did the first — which is why its
				## spending column came back identical to its walking one. A
				## level that is bought and never placed changes nothing about a
				## man except that he is two credits poorer.
				for f in s.club.roster:
					for _i in 3:
						if s.office.buy_level(f) != "":
							break
						Career.level_up(f)
			var guard := 0
			while not s.season_complete() and guard < 40:
				guard += 1
				var q := 0
				while q < 8 and s.blocked_by() != "":
					q += 1
					match s.blocked_by():
						"bid": s.decline_bid()
						"dilemma": s.answer_dilemma(s.dilemma_card()["options"].size() - 1)
						"cup": s.sim_cup_tie()
				s.skip_event()
			var pos := s.position()
			var mine: int = int(s.world.clubs[s.world.player_club]["power"])
			var tbl := s.world.table(s.world.player_tier())
			var top := 0
			if not tbl.is_empty():
				top = int(s.world.clubs[int(tbl[0]["club"])]["power"])
			line.append("t%d p%d r%d/%d" % [s.world.player_tier(), pos, mine, top])
			s.roll_over()
		print(["WALK  ", "SPEND ", "KEEP  "][spend] + " | ".join(line))
	quit()
