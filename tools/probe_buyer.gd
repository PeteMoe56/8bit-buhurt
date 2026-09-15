extends SceneTree
## CAN A MANAGER WHO ACTUALLY MANAGES CLIMB?
##
## Pete, 14 Sep 2026: a losing career *"can be turned around by spending CC
## currency, bringing the difficulty down, or just fighting better/smarter."*
## Every walk this project has measured so far has been the first of those and
## none of the rest, and the answer keeps coming back the same: the club sinks.
##
## But the walkers were not managers. `probe_keep.gd` found a keeper sitting on
## 1,359 unspent credits while his squad fell to six men — he renewed everybody
## and never signed anybody, because nothing in the probe knew the market was
## there. So: the same career, with the one habit every player has in the first
## ten seconds of a winter. Sign the best man you can afford. Keep the squad up.
##
## If this club climbs, the ladder is climbable and every previous number was a
## floor under a manager who was not playing. If it does not, the ladder is the
## problem.
const SQUAD_WANT: int = 10

func _initialize() -> void:
	for buy in [true]:
		var s := Season.new(MeleeRosters.starting_club(), 90210)
		Session.season = s
		var line: Array[String] = []
		var signed := 0
		for year in 45:
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
			## THE WINTER. Renew first — a man you let walk is a man you then have
			## to buy — then fill the books back up from the market, best first.
			for f in s.club.roster:
				if Contracts.can_extend(f):
					s.extend(f)
				else:
					s.resign(f)
			if buy:
				var tries := 0
				while s.club.roster.size() < SQUAD_WANT and tries < 12:
					tries += 1
					var best: FighterCard = null
					for f in s.market():
						if best == null or f.overall() > best.overall():
							best = f
					if best == null:
						break
					if s.sign_from_market(best) != "":
						break
					signed += 1
			line.append("t%d p%d r%d n%d" % [s.world.player_tier(), s.position(),
				s.club.power(), s.club.roster.size()])
			s.roll_over()
		print(("BUY  " if buy else "KEEP ") + " | ".join(line) + "   signed=%d" % signed)
	quit()
