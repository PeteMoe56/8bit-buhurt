extends SceneTree
## WHY THE CLUB FALLS OFF A CLIFF.
##
## `probe_climb.gd`: a walked career's power reads 37, 37, 35, 30, 21 — and then
## 20 or 21 for ever, six of six, while the division's leader sits between 40 and
## 47. That is not a slope, it is a step, and a step has a cause.
##
## Power is the mean rating of the STARTING FIVE, so this asks what the five are
## made of each year: their ages, how many of them are men the player signed
## against men the club conjured to make up the numbers, and what the bench has
## left to promote.
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 90210)
	Session.season = s
	for year in 10:
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
		## THE KEEPER'S WINTER, now that the doors work: extend whoever can be
		## extended, re-sign the rest. With contracts watertight, whatever is
		## still draining the squad is not contracts.
		s.office.credits += 120
		for f in s.club.roster:
			if Contracts.can_extend(f):
				s.extend(f)
			else:
				s.resign(f)
		var five := s.club.starting_five()
		var ages := 0.0
		var rate := 0.0
		for f in five:
			ages += float(f.age)
			rate += float(f.rating())
		var bench_best := 0
		for f in s.club.bench():
			bench_best = maxi(bench_best, f.rating())
		var w := s.last_winter
		print("S%d  power=%2d  five: age %.1f rating %.1f  squad=%d bench_best=%d  retired=%d walked=%d signed=%d"
			% [s.world.season, s.club.power(), ages / 5.0, rate / 5.0,
				s.club.roster.size(), bench_best,
				(w.get("retired", []) as Array).size(),
				(w.get("walked", []) as Array).size(),
				(w.get("signed", []) as Array).size()])
		s.roll_over()
	quit()
