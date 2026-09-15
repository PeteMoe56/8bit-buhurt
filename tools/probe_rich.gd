extends SceneTree
## HOW FAR CAN A CLUB CLIMB IF MONEY IS NO OBJECT?
##
## Not a balance question — a photography one. Two screens now cannot be looked
## at (the National table's bands, the review's second column) because the game
## cannot put the player in a division that has them. Before reaching for a dev
## override, find out whether the ladder can be climbed at all with the doors the
## game already has and a budget the game will never hand out.
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 90210)
	Session.season = s
	var line: Array[String] = []
	for year in 40:
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
		s.office.credits += 3000
		## Raise the cap first — a rich club that cannot pay anybody is a poor one.
		for _c in 3:
			s.office.raise_cap()
		for f in s.club.roster:
			if Contracts.can_extend(f):
				s.extend(f)
			else:
				s.resign(f)
		## SIGN THE BEST MAN AVAILABLE, over and over, and refresh the market when
		## it runs dry. This is the most aggressive squad-building the game allows.
		var tries := 0
		while s.club.roster.size() < MeleeClub.SQUAD_MAX and tries < 30:
			tries += 1
			var best: FighterCard = null
			for f in s.market():
				if best == null or f.overall() > best.overall():
					best = f
			if best == null or s.sign_from_market(best) != "":
				break
		line.append("t%d p%d r%d n%d" % [s.world.player_tier(), s.position(),
			s.club.power(), s.club.roster.size()])
		s.roll_over()
	print("RICH " + " | ".join(line))
	quit()
