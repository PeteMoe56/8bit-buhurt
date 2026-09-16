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
##   PART E   the one that decides whether a pipeline is needed at all: does a
##            YOUNG MAN FROM THE DIVISION ABOVE overtake an older starter from
##            this one, and when?
##   PART D   Pete's claim, checked: *"if you stick with the same guys, everyone
##            gets a raise and they all hit their individual peaks."* One squad,
##            two captains, nobody signed, nobody dropped, twelve seasons.
const SEASONS := 12


func _initialize() -> void:
	_arcs()
	_pipeline()
	_peaks()
	_settled()
	_catchup()
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
func _rng(age: int, rating: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("growth:%d:%d" % [age, rating])
	return rng


func _man(age: int, rating: int) -> FighterCard:
	var rng := _rng(age, rating)
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


## ------------------------------------------------------------------ PART E
## DOES THE TIER GAP DO THE WORK ON ITS OWN?
##
## Pete, 15 Sep 2026, turning down a youth slot: *"the age should already be an
## under-23 or so boost anyway. What more boost would they need to eventually
## catch up the old men and become starters if they're a higher tier? Like, the
## same tier pipeline shouldn't matter much in the same tier, but training a new
## guy from a higher tier should surpass the older lower tier guy."*
##
## That is a claim with a number in it and it has never been measured. `Market`
## draws a sixth of every shelf from the division above, and a man from up there
## carries that division's power band — so he arrives with a higher CEILING even
## when his rating today is lower. If that alone carries him past the incumbent,
## the pipeline needs no special pleading: it is just the market working, and a
## youth slot would be solving a problem the tiering already solves.
##
## THE INCUMBENT IS THE CONTROL and he is not a statue: he practises too, he is
## the one who starts, and he takes the fight XP. Both men are run through the
## same seasons in the same club. The row that matters is the SAME-TIER one —
## Pete's *"shouldn't matter much"* — because if the young man from your own
## division also sails past, the tier is not what is doing it.
const CATCHUP_SEASONS := 10


func _catchup() -> void:
	print("=== a young signing against the man he is behind ===\n")
	print("%-34s %7s %7s %8s" % ["", "starts", "ends", "passes him"])
	for grade in [0, 4]:
		for step in [0, 1, 2]:
			## THE INCUMBENT: thirty, at the top of the Backyard band, finished.
			var old_man := _man(30, 45)
			old_man.potential = old_man.overall() + 2
			## THE SIGNING: twenty-two, drawn at the middle of his own division's
			## band — his own for step 0, the one above for step 1 — with the
			## ceiling that band's men carry.
			## STEP 2 IS THE ONE THAT ISOLATES THE QUESTION. Steps 0 and 1 change
			## the man's RATING as well as where he came from, so the row for the
			## division above is partly just "he is better today". This one draws
			## him at the SAME rating as the local boy while telling
			## `roll_potential` he was drawn against the higher division's
			## standard — so the only difference left is the ceiling the tier gave
			## him, which is the half Pete's sentence is actually about.
			var band: Array = League.TIERS[mini(step, 1)]["power"]
			var mid := int(lerpf(float(band[0]), float(band[1]), 0.45))
			var kid := _man(22, 39 if step == 2 else mid)
			if step == 2:
				kid.potential = Career.roll_potential(
					_rng(22, 39), kid, int(League.TIERS[1]["power"][1]))
			var was := kid.overall()
			var passed := 0
			for y in CATCHUP_SEASONS:
				_season(old_man, grade, true)
				_season(kid, grade, false)
				if passed == 0 and kid.overall() > old_man.overall():
					passed = y + 1
			var who := "from his own division"
			if step == 1:
				who = "from the one above"
			elif step == 2:
				who = "raw, but reared one up"
			var coach := "no captain" if grade == 0 else "a %d-star captain" % grade
			print("%-34s %7d %7d %8s" % ["a 22-year-old %s, %s" % [who, coach],
				was, kid.overall(),
				("season %d" % passed) if passed > 0 else "never"])
			print("%-34s %7d %7d" % ["   the 30-year-old he is behind",
				45, old_man.overall()])
	print("")
	print("The signing sits in the RESERVE the whole time and the incumbent")
	print("starts every week, so this is the hard version of the question.")
	print("")
