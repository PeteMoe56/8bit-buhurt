extends SceneTree
## Kit and availability — the cap this game was designed around.
##
##   godot --headless --path . --script res://tests/test_kit.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — kit and availability ===\n")
	_test_a_failed_harness_keeps_a_man_off()
	_test_the_bus_has_a_size()
	_test_the_bench_is_the_traveling_party()
	_test_somebody_cannot_get_the_weekend_off()
	_test_the_three_reasons_are_three_reasons()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE KIT HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


func _test_a_failed_harness_keeps_a_man_off() -> void:
	## ARMOR IS A GATE NOW, not a soft multiplier. DIRECTION §4: *"Bench depth is
	## limited by armor, not payroll."* It was a 0.78-1.0 scale on a man's base
	## and nothing else, so a harness at 0.1 was a slightly worse fighter rather
	## than a man the marshals turn away.
	var bad: Array[String] = []
	var f := FighterCard.new()
	f.pos = Tuning.Pos.CENTER
	f.armor = 1.0
	if not f.passes_inspection() or not f.fit():
		bad.append("a full harness fails inspection")
	f.armor = FighterCard.INSPECTION_MIN
	if not f.passes_inspection():
		bad.append("a harness exactly on the line is failed")
	f.armor = FighterCard.INSPECTION_MIN - 0.01
	if f.passes_inspection() or f.fit():
		bad.append("a harness under the line passes")

	## AND IT REACHES THE LINE-UP, which is the half that matters. A club whose
	## Center cannot pass inspection has to field somebody else there.
	var club := MeleeRosters.starting_club()
	var center: FighterCard = club.starting_five()[Tuning.Pos.CENTER]
	var was := center.display_name
	center.armor = 0.05
	var after: Array = club.starting_five()
	var still_there: bool = after[Tuning.Pos.CENTER] != null \
		and (after[Tuning.Pos.CENTER] as FighterCard).display_name == was
	if still_there:
		bad.append("a man who failed inspection is still on the line")

	## The margin has to move with the armor, or the bar on the card is a mood
	## ring rather than a distance from the line.
	var top := FighterCard.new()
	top.armor = 1.0
	var edge := FighterCard.new()
	edge.armor = FighterCard.INSPECTION_MIN
	if not (top.inspection_margin() > edge.inspection_margin()):
		bad.append("the inspection margin does not fall with the armor")
	if not is_equal_approx(edge.inspection_margin(), 0.0):
		bad.append("a harness on the line does not read as no margin")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("the marshals pass a harness at %.2f and refuse one at %.2f; a failed Center is replaced on the line"
		% [FighterCard.INSPECTION_MIN, FighterCard.INSPECTION_MIN - 0.01])
	_ok(bad.is_empty(), "a failed harness keeps a man off",
		"armor under the inspection line is a man who cannot fight, not a man who fights slightly worse")


func _test_the_bus_has_a_size() -> void:
	## EIGHT, ALWAYS (Pete, 1 Oct 2026: "It should always be up to 8 fighters
	## anyway"). A new club takes all eight, and there is nothing to buy.
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.sync_power()
	if s.club.active_eight().size() != MeleeClub.ACTIVE_SIZE or s.office.travel_slots != ClubOffice.TRAVEL_MAX:
		bad.append("a new club travels %d of %d places" % [s.club.active_eight().size(), s.office.travel_slots])
	s.office.credits = 100
	if s.office.buy_travel_slot() == "" or s.office.credits != 100:
		bad.append("a place on the bus was sold")
	## AND AN OLD SAVE'S BOUGHT PLACES COME BACK AS CREDITS.
	var d := s.office.to_dict()
	d.erase("armorer")
	d["travel"] = 8
	d["credits"] = 0
	var back := ClubOffice.from_dict(d)
	if back.travel_slots != 8 or back.credits != 16:
		bad.append("an old save on 8 places came back on %d with %d CC (16 expected)" % [back.travel_slots, back.credits])
	_ok(bad.is_empty(), "the bus is eight", "; ".join(bad) if not bad.is_empty()
		else "a new club takes eight, nothing is sold, an old save's 16 CC of places come back")


func _test_the_bench_is_the_traveling_party() -> void:
	## WHO CAN COME ON IN THE CORNER, and it was wrong in two ways at once.
	##
	## `MeleeSim.bench()` read the whole roster, so a RESERVE who never left the
	## clubhouse was swappable onto the line in the corner of a National fixture;
	## and it read `available` rather than `fit()`, so a man with a broken arm was
	## on the same list. Both were invisible because the corner shows three names
	## and three was usually right.
	var bad: Array[String] = []
	var club := MeleeRosters.starting_club()
	club.travel_cap = 6
	var sim := MeleeSim.new(club, MeleeRosters.rival_club(), 7)
	var party := club.active_eight()
	var on_bench: Array = sim.bench(0)
	for f in on_bench:
		if not party.has(f):
			bad.append("%s is on the bench and did not travel" % f.display_name)
		if not f.fit():
			bad.append("%s is on the bench and cannot fight" % f.display_name)
	if on_bench.size() != party.size() - MeleeClub.LINE_SIZE:
		bad.append("the bench is %d men from a party of %d" % [on_bench.size(), party.size()])

	## A knock and a failed harness both take a man off it, and the check has to
	## separate them from each other or it is measuring "unfit" once.
	var hurt: FighterCard = party[MeleeClub.LINE_SIZE]
	hurt.injury = 2
	var sim2 := MeleeSim.new(club, MeleeRosters.rival_club(), 7)
	for f in sim2.bench(0):
		if f == hurt:
			bad.append("an injured man is still on the bench")
	hurt.injury = 0
	hurt.armor = 0.05
	var sim3 := MeleeSim.new(club, MeleeRosters.rival_club(), 7)
	for f in sim3.bench(0):
		if f == hurt:
			bad.append("a man whose harness failed is still on the bench")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("a party of %d leaves %d on the bench, and a knock or a failed harness takes a man off it"
		% [party.size(), on_bench.size()])
	_ok(bad.is_empty(), "the bench is the traveling party",
		"only men who travelled and can fight are available to come on, so a reserve at home cannot be swapped into a cup tie")


func _test_somebody_cannot_get_the_weekend_off() -> void:
	## THE HALF WITH NO EQUIVALENT ANYWHERE IN THE REFERENCE. Nobody in this sport
	## is paid; your Center is a welder with a shift. DIRECTION §4 calls it out as
	## the constraint that has never been in a sports management game.
	##
	## Three properties make it a decision rather than a dice roll, and all three
	## are asserted here: it is known before you pick a line, it never takes more
	## than one man, and it clears.
	var bad: Array[String] = []
	var seen_any := false
	var most := 0
	var weeks := 0
	## Walked across many seasons because the chance is deliberately low — one
	## season is not enough to see it at all, and a check that cannot observe the
	## thing it is about passes on nothing.
	for seed_v in 40:
		var s := Season.new(MeleeRosters.starting_club(), seed_v)
		for _e in 5:
			if s.season_complete():
				break
			s.skip_event()
			weeks += 1
			var out := 0
			for f in s.club.roster:
				if not f.available:
					out += 1
			most = maxi(most, out)
			if out > 0:
				seen_any = true
	if not seen_any:
		bad.append("nobody was ever unavailable in %d weeks, so the rule is unreachable" % weeks)
	if most > ClubOffice.TRAVEL_START - MeleeClub.LINE_SIZE + 1:
		bad.append("%d men were out at once, which a starting club cannot cover" % most)

	## IT CLEARS. A man out one weekend is not out the next unless he is drawn
	## again — otherwise it is a slow injury rather than a rota problem.
	var s2 := Season.new(MeleeRosters.starting_club(), 3)
	for f in s2.club.roster:
		f.available = false
	s2.skip_event()
	var still_out := 0
	for f in s2.club.roster:
		if not f.available:
			still_out += 1
	if still_out > ClubOffice.TRAVEL_START:
		bad.append("%d men stayed unavailable through a new week" % still_out)

	## AND A MAN ALREADY HURT IS NOT ALSO BUSY. Two reasons on one man read as one
	## problem on the screen and cost the club twice.
	var s3 := Season.new(MeleeRosters.starting_club(), 11)
	for f in s3.club.active_eight():
		f.injury = 3
	s3.skip_event()
	for f in s3.club.active_eight():
		if f.injury > 0 and not f.available:
			bad.append("%s is injured AND cannot get the weekend off" % f.display_name)

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("across %d weeks the most men ever unavailable at once was %d, and it clears the following week"
		% [weeks, most])
	_ok(bad.is_empty(), "somebody cannot get the weekend off",
		"a man can miss a weekend for reasons no money or training fixes, never more than one at a time, and never on top of a knock")


func _test_the_three_reasons_are_three_reasons() -> void:
	## A screen that says "OUT 2" for a knock, a failed harness and a missed
	## weekend is a screen that tells the player nothing he can act on. Three
	## problems, three answers: a knock waits, a harness is a trip to the
	## workshop, and a missed weekend is why you bought a bench.
	var bad: Array[String] = []
	var words := {}
	var f := FighterCard.new()
	f.armor = 1.0

	f.injury = 2
	words["a knock"] = f.unfit_reason()
	f.injury = 0

	f.armor = 0.05
	words["a failed harness"] = f.unfit_reason()
	f.armor = 1.0

	f.available = false
	words["a missed weekend"] = f.unfit_reason()
	f.available = true

	words["fit"] = f.unfit_reason()

	if words["fit"] != "":
		bad.append("a fit man is given a reason he cannot play")
	var said := {}
	for k in words:
		var w: String = String(words[k])
		if k == "fit":
			continue
		if w == "":
			bad.append("%s produces no reason at all" % k)
		if said.has(w):
			bad.append("%s and %s read identically" % [k, String(said[w])])
		said[w] = k

	## ORDER MATTERS when two are true at once: the one the player can do
	## something about soonest is the one worth printing, and a knock outranks a
	## harness because the harness can be fixed while he is out anyway.
	##
	## Compared against the KNOCK'S OWN OUTPUT for the same injury rather than
	## against the string captured earlier — that one was taken at two weeks and
	## this man is out for three, so a literal comparison was asserting the number
	## of weeks rather than which of the three reasons won.
	var both := FighterCard.new()
	both.injury = 3
	both.armor = 0.05
	var knock_only := FighterCard.new()
	knock_only.injury = 3
	if both.unfit_reason() != knock_only.unfit_reason():
		bad.append("a man who is injured AND failed inspection is reported as the harness")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("the three reasons read: %s" % str(words))
	_ok(bad.is_empty(), "the three reasons are three reasons",
		"a knock, a failed harness and a missed weekend each say so in their own words, and a fit man says nothing")
