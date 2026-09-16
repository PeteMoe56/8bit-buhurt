extends SceneTree
## HOW FAST A FIGHTER ACTUALLY GETS BETTER, AND WHAT THE STAFF IS WORTH.
##
##   godot --headless --path . --script res://tools/probe_growth.gd
##
## Pete, 15 Sep 2026: *"The Coaches hold practices, the better the coaches, the
## more you get out of practice. Benched guys get more out of practices, but the
## fighters get a little practice and the fight XP... if you stick with the same
## guys, everyone gets a raise and they all hit their individual peaks."*
##
## Three things are being measured and they are separate questions:
##
##   PART A   one man's arc, by the age he was signed at. Does a career have a
##            shape — climb, plateau, fade — or is it a slope?
##   PART B   the same man on the line and on the bench, under a five-star
##            captain and under nobody. Is the pipeline real, and is the grade
##            on a hire card worth paying for?
##   PART C   the peaks themselves. Every fighter used to age to the same
##            schedule; this prints what a squad's curves now look like.
##   PART D   Pete's claim, checked: *"if you stick with the same guys, everyone
##            gets a raise and they all hit their individual peaks."* One squad,
##            two captains, nobody signed, nobody dropped, twelve seasons.
const SEASONS := 12


func _initialize() -> void:
	_arcs()
	_pipeline()
	_peaks()
	_settled()
	quit(0)


## ------------------------------------------------------------------ PART A
func _arcs() -> void:
	for age in [20, 24, 28]:
		var f := _man(age, 40)
		print("\n=== signed at %d, rated %d, ceiling %d ===" % [age, f.overall(), f.potential])
		print("%7s %5s %7s %7s %7s %8s" % [
			"season", "age", "rating", "ceiling", "levels", "gap left"])
		for y in SEASONS:
			var got := _season(f, 0, true)
			print("%7d %5d %7d %7d %7d %8d" % [y + 1, f.age, f.overall(),
				f.potential, got, maxi(0, f.potential - f.overall())])
	print("")


## ------------------------------------------------------------------ PART B
## THE PIPELINE, AND THE PRICE OF A CAPTAIN.
##
## A starter takes a quarter of a practice and a full afternoon; a reserve takes
## the whole practice and no afternoon. Whether that adds up to a pipeline is the
## question Pete's design turns on, and it is not answerable by reading the
## constants — `PRACTICE_STARTER` is 0.25 but a starter also earns fight XP, so
## which of them ends up ahead depends on the captain.
func _pipeline() -> void:
	print("=== a 21-year-old over %d seasons, by where he stands ===\n" % SEASONS)
	print("%-24s %8s %8s %8s" % ["", "rating", "ceiling", "levels"])
	for grade in [0, 3, 5]:
		for starts in [true, false]:
			var f := _man(21, 38)
			var got := 0
			for _y in SEASONS:
				got += _season(f, grade, starts)
			var who := "on the line" if starts else "in the reserve"
			var coach := "no captain" if grade == 0 else "a %d-star captain" % grade
			print("%-24s %8d %8d %8d" % ["%s, %s" % [who, coach], f.overall(),
				f.potential, got])
	print("")
	print("A reserve out-practises a starter four to one and the starter still")
	print("has the afternoon. Where they finish is the whole pipeline question.")
	print("")


## ------------------------------------------------------------------ PART C
func _peaks() -> void:
	print("=== the peaks a squad is carrying ===\n")
	print("%-10s %8s %8s %8s %8s" % ["fighter", "gas", "strength", "base", "skill"])
	var club := MeleeRosters.starting_club()
	for f in club.roster:
		print("%-10s %8d %8d %8d %8d" % [UiKit.clip(f.display_name, 10),
			Career.peak_for(f, Career.Stat.GAS),
			Career.peak_for(f, Career.Stat.STRENGTH),
			Career.peak_for(f, Career.Stat.BASE),
			Career.peak_for(f, Career.Stat.SKILL)])
	print("")
	print("the sport's own schedule: gas %d, strength %d, base %d, skill %d"
		% [Career.PEAK_GAS, Career.PEAK_STRENGTH, Career.PEAK_BASE, Career.PEAK_SKILL])
	print("")


# ---------------------------------------------------------------- the fixture
func _man(age: int, rating: int) -> FighterCard:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("growth:%d:%d" % [age, rating])
	var f := ClubFactory.free_agent(rng, Tuning.Pos.CENTER, rating)
	f.age = age
	f.armor = 1.0
	f.potential = Career.roll_potential(rng, f)
	return f


## ONE SEASON, the way `Season` actually pays a man: a practice every week, and
## an afternoon on top of it if he started. Returns levels taken.
##
## The multipliers a real club stacks on a practice — the ground, the regime, the
## doubled specialty — are all 1.0 here on purpose. This measures the FLOOR, so
## the captain's grade is the only thing moving between the rows.
func _season(f: FighterCard, grade: int, starts: bool) -> int:
	var got := 0
	for _e in League.events_in_season(0):
		f.xp += maxi(1, int(round(Career.practice_xp(grade, starts))))
		if starts:
			f.xp += Career.xp_for(6, 3, f.overall())
		while Career.can_level(f) and not Career.at_ceiling(f):
			Career.level_up(f)
			got += 1
	Career.winter(f, false, 0)
	return got


## ------------------------------------------------------------------ PART D
## THE SETTLED SQUAD. Pete, 15 Sep 2026: *"if you stick with the same guys,
## everyone gets a raise and they all hit their individual peaks."*
##
## SIX SEASONS AND EACH MAN AT HIS BEST, and both of those are corrections to a
## first cut that ran twelve seasons and read the squad on the final whistle. It
## came back with Merrick on 20 and Orr on 7 and reported the claim false — which
## it was not. Nobody retires or is replaced in this fixture, so twelve seasons
## turns thirteen men into a squad aged 34 to 47, and asking whether a
## forty-seven year old is at his ceiling is asking the wrong question about a
## man who passed it six years ago.
##
## *"They all hit their individual peaks"* is a claim about whether a man ever
## gets there, so it is measured as one: his best rating across the run, and the
## season it happened in. The decline afterwards is a different system working
## correctly.
##
## Two four-star captains and nothing else — no signings, no releases, no ground,
## no regime. The practice week and the afternoons, and that is all.
const SETTLED_SEASONS := 6


func _settled() -> void:
	print("=== the same thirteen men, %d seasons, two four-star captains ===\n"
		% SETTLED_SEASONS)
	var club := MeleeRosters.starting_club()
	var was: Dictionary = {}
	var best: Dictionary = {}
	var best_year: Dictionary = {}
	for f in club.roster:
		was[f] = f.overall()
		best[f] = f.overall()
		best_year[f] = 0
	var grades := {Tuning.Role.RAIL: 4, Tuning.Role.FLANK: 4, Tuning.Role.CENTER: 4}
	for y in SETTLED_SEASONS:
		var five := club.starting_five()
		for _e in League.events_in_season(0):
			for f in club.roster:
				var starts: bool = five.has(f)
				f.xp += maxi(1, int(round(Career.practice_xp(
					int(grades[Tuning.role_of(int(f.pos))]), starts))))
				if starts:
					f.xp += Career.xp_for(6, 3, f.overall())
				while Career.can_level(f) and not Career.at_ceiling(f):
					Career.level_up(f)
		for f in club.roster:
			Career.winter(f, false, 0)
			if f.overall() > int(best[f]):
				best[f] = f.overall()
				best_year[f] = y + 1
		club.best_line()
	print("%-10s %5s %7s %7s %9s %7s %8s" % [
		"fighter", "age", "was", "best", "ceiling", "year", "got there"])
	var at_it := 0
	for f in club.roster:
		var got: bool = int(best[f]) >= f.potential - Career.CEILING_NEAR
		if got:
			at_it += 1
		print("%-10s %5d %7d %7d %9d %7d %8s" % [UiKit.clip(f.display_name, 10),
			f.age, int(was[f]), int(best[f]), f.potential,
			int(best_year[f]), "yes" if got else "no"])
	print("")
	print("%d of %d reached their own ceiling inside %d seasons. Club power %d."
		% [at_it, club.roster.size(), SETTLED_SEASONS, club.power()])
	print("")
