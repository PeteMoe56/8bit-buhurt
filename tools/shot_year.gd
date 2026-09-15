extends SceneTree
## THE SEASON REVIEW, WITH A YEAR ACTUALLY BEHIND IT.
##
##   xvfb-run -a godot --path . --script res://tools/shot_year.gd
##
## A shot of an empty review would prove the panel draws and nothing about the
## page, so this plays a season through before it looks — and changes the grade
## part-way, because the grade column is the whole reason the page exists and a
## column of nine identical words is a column nobody would have noticed was
## wrong.
var n := 0

func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 90210)
	Session.season = s
	s.office.credits = 40
	s.decline_bid()
	## A SEASON LONG ENOUGH TO FILL BOTH COLUMNS, reached the way the game
	## reaches it: by winning promotions. The first cut of this tool moved the
	## club's tier by writing `clubs[me]["tier"]` directly, which put it in a
	## division whose table did not contain it and threw on every draw — *a state
	## reached by a road the game does not have is a state the game cannot be
	## in*, and the shot would have been of a screen no player can open.
	var year := 0
	while s.world.player_tier() < 2 and year < 30:
		year += 1
		## AND IT HAS TO BE GOOD ENOUGH TO GO UP. Twenty-four walked seasons on a
		## starting roster finished season 25 still in the Backyard Circuit, which
		## is the same thing the career soak found in September: a manager who
		## never spends anything loses more than he wins. So this one spends —
		## through `buy_level`, the road the game actually has.
		s.office.credits += 120
		for f in s.club.roster:
			for _i in 3:
				if s.office.buy_level(f) != "":
					break
		_play(s, false)
		s.roll_over()
	print("reached tier %d in season %d" % [s.world.player_tier(), s.world.season])
	## THE LAST YEAR IS FOUGHT FOR REAL, with the grade moved under it — the
	## column exists to show a manager dropping the difficulty and climbing back,
	## and a page of one repeated word would prove nothing about it.
	_play(s, true)

	var scene: Node = load("res://scenes/Records.tscn").instantiate()
	## THE PAGE BEFORE THE TREE. `_ready()` builds the row off `page`, and setting
	## it afterwards meant calling `_build()` again on a node whose `_ready` had
	## not run yet — one null `ui` and a screenshot of the wrong tab.
	scene.set("page", 0)
	root.add_child(scene)

func _process(_d: float) -> bool:
	n += 1
	if n < 12:
		return false
	root.get_texture().get_image().save_png("res://shots/year.png")
	print("wrote year")
	return true


## One season, the way the season screen drains it: whatever is blocking first,
## then the bout. `fight` runs the real sim; otherwise the week is simulated,
## which is quick and is how the promotion years get walked.
func _play(s: Season, fight: bool) -> void:
	var weeks := 0
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
		if fight:
			if weeks == 3:
				s.grade = Grade.G.FRIENDLY
			elif weeks == 7:
				s.grade = Grade.G.FULL_STEEL
			var sim := s.begin_bout()
			if sim != null:
				Session.season = s
				Session.bout = sim
				sim.run_to_end()
				s.post_bout(sim)
				Session.clear_bout()
				weeks += 1
				continue
		s.skip_event()
		weeks += 1
