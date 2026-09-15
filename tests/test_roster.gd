extends SceneTree
## The roster screen, the fighter screen, and the book behind them.
##
##   godot --headless --path . --script res://tests/test_roster.gd

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the roster ===\n")
	_test_every_man_has_exactly_one_card()
	_test_no_card_overlaps_another()
	_test_the_book_records_what_the_sim_counted()
	_test_the_book_survives_a_save()
	_test_stars_are_monotonic()
	_test_the_market_grid_does_not_collide()
	_test_the_regime_actually_trades_something()
	_test_a_record_outlives_its_holder()
	_test_a_mood_is_worth_something()
	_test_the_room_is_the_men_in_it()
	_test_a_toxic_man_costs_the_others_a_loss()
	_test_cutting_a_man_is_read_by_the_room()
	_test_a_squad_arrives_with_a_spread_of_moods()
	_test_nothing_on_a_card_runs_into_anything_else()
	_test_a_short_line_still_numbers_its_men()
	_test_a_squad_is_shaped_like_a_squad()
	_test_the_register_still_describes_the_code()
	_test_a_player_can_name_his_own_starters()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE ROSTER HOLDS (%d checks)\n" % checks)
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


## `_ready` is deferred to the first frame and a headless test never gets one,
## so the season is handed over directly. `_slots()` is the thing under test and
## it reads that field — this exercises the real function, not a stand-in.
func _screen() -> Node:
	var packed: PackedScene = load("res://scenes/Roster.tscn")
	var n: Node = packed.instantiate()
	root.add_child(n)
	n.set("season", Session.season)
	return n


func _test_every_man_has_exactly_one_card() -> void:
	## A roster that quietly drops a man is a roster that loses him. The screen
	## builds its cards and its hit boxes off ONE list, so this asserts that list
	## and the club agree about who is on the books.
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	var s := _screen()
	var slots: Array = s.call("_slots")
	var seen: Array = []
	var dupes := 0
	for slot in slots:
		var c = slot["card"]
		if seen.has(c):
			dupes += 1
		seen.append(c)
	var missing := 0
	for f in Session.season.club.roster:
		if not seen.has(f):
			missing += 1
	notes.append("%d cards for %d men on the books, %d duplicated, %d missing"
		% [slots.size(), Session.season.club.roster.size(), dupes, missing])
	_ok(dupes == 0 and missing == 0 and slots.size() == Session.season.club.roster.size(),
		"every man has exactly one card",
		"the card list and the roster are the same set of men")
	s.queue_free()


func _test_no_card_overlaps_another() -> void:
	## THE COLLISION CHECK, and this project has needed one.
	##
	## Buttons are built at absolute positions, so two of them landing on each
	## other is silent — the audit found a cup button sitting on the sixteenth
	## row of a National table, hiding a club in a relegation place. Cards are
	## drawn AND tapped, so an overlap here means a tap opens the wrong man.
	Session.season = Season.new(MeleeRosters.starting_club(), 777)
	var s := _screen()
	var slots: Array = s.call("_slots")
	var bad: Array[String] = []
	for i in slots.size():
		var a: Rect2 = slots[i]["rect"]
		if a.position.x < 0.0 or a.position.y < 0.0 \
				or a.end.x > UiKit.screen().x or a.end.y > UiKit.screen().y:
			bad.append("card %d is off screen" % i)
		for j in range(i + 1, slots.size()):
			var b: Rect2 = slots[j]["rect"]
			if a.intersects(b):
				bad.append("cards %d and %d overlap" % [i, j])
	## And nothing may sit on the footer, which is drawn over the top of them.
	for i in slots.size():
		var r: Rect2 = slots[i]["rect"]
		if r.end.y > UiKit.screen().y - 70.0:
			bad.append("card %d runs into the footer" % i)
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("%d cards, all on screen, none touching" % slots.size())
	_ok(bad.is_empty(), "no card overlaps another",
		"every card is inside the screen and clear of its neighbours and the footer")
	s.queue_free()


func _test_the_book_records_what_the_sim_counted() -> void:
	## The two numbers XP is paid on were counted and thrown away for the whole
	## life of this project. This asserts they are kept, and kept ACCURATELY —
	## the book has to equal what the sim saw, not merely be non-zero.
	var season := Season.new(MeleeRosters.starting_club(), 99)
	Session.season = season
	var before := {}
	for f in season.club.roster:
		before[f] = [f.bouts, f.downs, f.rounds_standing]
	var sim := season.begin_bout()
	sim.run_to_end()
	season.post_bout(sim)

	var wrong: Array[String] = []
	var counted := 0
	for m in sim.men:
		if m.team != 0 or m.card == null or not before.has(m.card):
			continue
		counted += 1
		var was: Array = before[m.card]
		if m.card.bouts != int(was[0]) + 1:
			wrong.append("%s fought once and his count moved by %d"
				% [m.card.display_name, m.card.bouts - int(was[0])])
		if m.card.downs != int(was[1]) + int(m.downs_caused):
			wrong.append("%s caused %d downs and the book says %d"
				% [m.card.display_name, int(m.downs_caused), m.card.downs - int(was[1])])
		if m.card.rounds_standing != int(was[2]) + int(m.rounds_standing):
			wrong.append("%s finished %d rounds standing and the book disagrees"
				% [m.card.display_name, int(m.rounds_standing)])
		if m.card.best_downs < int(m.downs_caused):
			wrong.append("%s's best afternoon is under what he just did" % m.card.display_name)
	if not wrong.is_empty():
		notes.append("  " + ", ".join(wrong))
	notes.append("%d men on the line, every one's book matches the sim" % counted)
	_ok(wrong.is_empty() and counted > 0, "the book records what the sim counted",
		"events, downs, rounds standing and the best afternoon all agree with the bout")


func _test_the_book_survives_a_save() -> void:
	## Version 9 added the book. A file that round-trips a man's career and
	## loses his record has taken away the only thing a long save is FOR.
	SaveGame.set_namespace("roster")
	var season := Season.new(MeleeRosters.starting_club(), 1234)
	var man: FighterCard = season.club.starting_five()[1]
	man.bouts = 57
	man.downs = 91
	man.rounds_standing = 130
	man.best_downs = 6
	man.knocks = 4
	man.honours = 2
	SaveGame.save(season, 0)
	var back := SaveGame.load_slot(0)
	SaveGame.delete(0)
	var found: FighterCard = null
	if back != null:
		for f in back.club.roster:
			if f.display_name == man.display_name:
				found = f
	var ok: bool = found != null and found.bouts == 57 and found.downs == 91 \
		and found.rounds_standing == 130 and found.best_downs == 6 \
		and found.knocks == 4 and found.honours == 2
	notes.append("saved and reloaded a book of 57 events and 91 downs: %s"
		% ("intact" if ok else "LOST"))
	_ok(ok, "the book survives a save",
		"every career counter round-trips at version %d" % SaveGame.VERSION)


func _test_stars_are_monotonic() -> void:
	## The star scale is what a player actually reads a man by, so it must never
	## rank two men the wrong way round: a better rating can never draw fewer
	## stars, and nothing may fall outside nought to five.
	var last := -1
	var bad: Array[String] = []
	for r in range(0, 100):
		var halves: int = clampi(int(round(float(r) / 10.0)), 0, 10)
		if halves < last:
			bad.append("rating %d draws fewer stars than %d" % [r, r - 1])
		if halves < 0 or halves > 10:
			bad.append("rating %d is off the scale" % r)
		last = halves
	notes.append("ratings 0-99 map to 0.0-5.0 stars without ever going backwards")
	_ok(bad.is_empty(), "stars are monotonic",
		"a better man never draws fewer stars, and nobody draws more than five")


func _test_the_market_grid_does_not_collide() -> void:
	## THE SAME CHECK AS THE ROSTER'S, ON THE SECOND GRID.
	##
	## The market grew a card grid an hour after the roster did, and the first
	## version's second row ran into the Back button — exactly the failure the
	## roster's check exists to catch, on a screen that check did not cover. A
	## rule enforced on one screen is a rule with a hole in it, so the rule moves
	## to wherever the grids are.
	Session.season = Season.new(MeleeRosters.starting_club(), 20260911)
	var packed: PackedScene = load("res://scenes/Market.tscn")
	var n: Node = packed.instantiate()
	root.add_child(n)
	n.set("season", Session.season)
	var slots: Array = n.call("_slots")
	var bad: Array[String] = []
	for i in slots.size():
		var a: Rect2 = slots[i]["rect"]
		if a.position.x < 0.0 or a.position.y < 0.0 \
				or a.end.x > UiKit.screen().x or a.end.y > UiKit.screen().y - 70.0:
			bad.append("card %d is off screen or in the footer" % i)
		for j in range(i + 1, slots.size()):
			if a.intersects(slots[j]["rect"]):
				bad.append("cards %d and %d overlap" % [i, j])
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("%d free-agent cards, all clear of each other and the footer" % slots.size())
	_ok(bad.is_empty(), "the market grid does not collide",
		"every free-agent card is on screen, clear of its neighbours and above the footer")
	n.queue_free()


func _test_the_regime_actually_trades_something() -> void:
	## THE REGIME WAS THREE WORDS ON A SCREEN for days — drawn, never settable,
	## read by nothing. Its numbers are now Retro Bowl's own, read out of the
	## shipped build, and this asserts all four of them actually differ, because
	## a trade where both sides are the same number is a slider with a label.
	var o := ClubOffice.new()
	o.credits = 100
	## ASSERT THE HIRE. It was `o.hire(...)` with the return thrown away, and the
	## day a captain's price started scaling with his stars the hire began failing
	## on the office's starting 8 CC — so this test ran against a club with NO
	## captain and reported x1.0/x1.0/x1.0 as if the regime had collapsed. A setup
	## step whose failure is silent is a test that measures the setup.
	var bad: Array[String] = []
	var hired := o.hire(ClubOffice.captain("Test", Tuning.Role.RAIL, Tuning.Role.CENTER, 3))
	if hired != "" or o.captains.is_empty():
		bad.append("the captain was never hired: %s" % hired)
	if not o.taught(Tuning.Role.RAIL):
		bad.append("the hired captain teaches nothing, so there is no regime to read")
	var role := Tuning.Role.RAIL
	var seen := {}
	for r in [ClubOffice.Regime.LIGHT, ClubOffice.Regime.NORMAL, ClubOffice.Regime.HARD]:
		o.set_regime(0, r)
		seen[r] = [o.regime_xp(role), o.regime_morale(role),
			o.regime_wear(role), o.regime_injury(role)]
	## Hard develops faster and costs more on every other axis. Light is the
	## mirror. If any pair ever collapses, the decision has gone.
	var light: Array = seen[ClubOffice.Regime.LIGHT]
	var normal: Array = seen[ClubOffice.Regime.NORMAL]
	var hard: Array = seen[ClubOffice.Regime.HARD]
	if not (float(light[0]) < float(normal[0]) and float(normal[0]) < float(hard[0])):
		bad.append("training does not climb Light -> Normal -> Hard")
	if not (float(light[1]) > float(hard[1])):
		bad.append("morale does not fall on Hard")
	if not (float(light[2]) > float(hard[2])):
		bad.append("armour does not wear on Hard")
	if not (float(light[3]) < float(normal[3]) and float(normal[3]) < float(hard[3])):
		bad.append("knock odds do not climb with the regime")
	## And the one that makes it bite: Hard is not a little riskier.
	if float(hard[3]) < float(normal[3]) * 3.0:
		bad.append("Hard is not meaningfully riskier than Normal")
	## A role nobody teaches is trained nobody's way.
	var o2 := ClubOffice.new()
	if o2.regime_for(Tuning.Role.CENTER) != ClubOffice.Regime.NORMAL:
		bad.append("an untaught role does not default to Normal")
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("regime: training x%.1f/%.1f/%.1f, knocks x%.2f/%.2f/%.2f"
		% [light[0], normal[0], hard[0], light[3], normal[3], hard[3]])
	_ok(bad.is_empty(), "the regime actually trades something",
		"Hard develops faster and costs morale, armour and bodies; Light is the mirror")


func _test_a_record_outlives_its_holder() -> void:
	## THE WHOLE POINT OF A RECORD. It is stored on the world with a name and a
	## season written down at the moment it happened, rather than scanned off the
	## current roster — a scan would lose everything a retired man ever set, which
	## is most of the history of any club worth having one.
	var w := LeagueWorld.new(31)
	w.season = 3
	var bad: Array[String] = []
	if not w.note_record("downs_event", 5, "Ellis", 3):
		bad.append("the first record was refused")
	if w.note_record("downs_event", 4, "Croft", 4):
		bad.append("a worse mark took the record")
	if not w.note_record("downs_event", 9, "Croft", 4):
		bad.append("a better mark did not take the record")
	if w.note_record("downs_event", 0, "Nobody", 5):
		bad.append("a nil mark was written down")
	var rec: Dictionary = w.records.get("downs_event", {})
	if int(rec.get("value", 0)) != 9 or String(rec.get("holder", "")) != "Croft":
		bad.append("the book does not hold the best mark and its holder")
	## And it survives the man leaving: nothing about the record reads the roster.
	if int(rec.get("season", 0)) != 4:
		bad.append("the season it was set was not kept")
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("the book keeps the best mark, its holder and the season, and refuses a nil")
	_ok(bad.is_empty(), "a record outlives its holder",
		"records are written when they happen and never scanned off a live roster")


# ------------------------------------------------------------------- morale
func _test_a_mood_is_worth_something() -> void:
	## THE TOXIC END IS A TRADE, NOT A PENALTY, and that is the whole reason it is
	## in the game. Retro Bowl's own tip screen: *"Players receive a +1 strength
	## buff if their morale is angry or toxic"* and *"Toxic players receive a +1
	## stamina buff."* The difficult man is the hardest man on your line. If this
	## check ever fails, morale has quietly become a stat you simply want high,
	## and the decision has gone with it.
	var bad: Array[String] = []
	var happy := FighterCard.new()
	happy.strength = 60
	happy.gas = 60
	happy.morale = 0.90
	var cross := FighterCard.new()
	cross.strength = 60
	cross.gas = 60
	cross.morale = 0.25          ## angry, not toxic
	var gone := FighterCard.new()
	gone.strength = 60
	gone.gas = 60
	gone.morale = 0.05           ## toxic

	if happy.fighting_strength() != happy.strength or happy.fighting_gas() != happy.gas:
		bad.append("a contented man does not fight at his card")
	if cross.fighting_strength() <= happy.fighting_strength():
		bad.append("an angry man does not hit harder")
	if cross.fighting_gas() != cross.gas:
		bad.append("angry buys gas, and it should not — only toxic does")
	if gone.fighting_strength() <= happy.fighting_strength():
		bad.append("a toxic man does not hit harder")
	if gone.fighting_gas() <= happy.fighting_gas():
		bad.append("a toxic man does not last longer")
	## And the tank the melee actually reads has to move with it, or the gas chip
	## is a number on a screen. `tank()` is what the sim burns through.
	if gone.tank() <= happy.tank():
		bad.append("the toxic man's tank is no bigger, so the chip reaches nothing")
	## The words must cover the whole range with no gap and no overlap: walk it.
	var probe := FighterCard.new()
	var words: Array[String] = []
	var v := 0.0
	while v <= 1.0001:
		probe.morale = clampf(v, 0.0, 1.0)
		var w := probe.morale_word()
		if w == "":
			bad.append("morale %.2f has no word" % v)
		if words.is_empty() or words[words.size() - 1] != w:
			if words.has(w):
				bad.append("the word '%s' comes back after leaving — the bands overlap" % w)
			words.append(w)
		v += 0.01
	if words.size() != 7:
		bad.append("%d words across the range, not the seven Retro Bowl uses" % words.size())
	## Toxic and angry have to be the BOTTOM of that walk, not a band in the middle.
	probe.morale = 0.0
	if not (probe.toxic() and probe.angry()):
		bad.append("the floor is not toxic")
	probe.morale = 1.0
	if probe.toxic() or probe.angry():
		bad.append("the ceiling is toxic")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("a 60/60 man: contented %d str %d gas · angry %d/%d · toxic %d/%d, tank %.2f vs %.2f"
		% [happy.fighting_strength(), happy.fighting_gas(),
			cross.fighting_strength(), cross.fighting_gas(),
			gone.fighting_strength(), gone.fighting_gas(), gone.tank(), happy.tank()])
	notes.append("the seven words, bottom to top: %s" % ", ".join(words))
	_ok(bad.is_empty(), "a mood is worth something",
		"an angry man hits harder, a toxic one hits harder and lasts longer, and the seven words cover the range once each")


func _test_the_room_is_the_men_in_it() -> void:
	## THE CLUB FIGURE IS AN AVERAGE NOW, not a thing of its own — otherwise the
	## screen and the men disagree about how the place feels and both are right.
	## And it is the average of the EIGHT WHO TRAVEL: a reserve who never leaves
	## the club does not set the tone in the changing room.
	var bad: Array[String] = []
	var season := Season.new(MeleeRosters.starting_club(), 4242)
	var o := season.office
	o.sync_morale(season.club)
	var eight := season.club.active_eight()
	var total := 0.0
	for f in eight:
		total += f.morale
	if not is_equal_approx(o.morale, total / float(eight.size())):
		bad.append("the club figure is not the average of the eight")

	## Wreck one man's mood and the room must follow him down.
	var before := o.morale
	eight[0].morale = 0.02
	o.sync_morale(season.club)
	if o.morale >= before:
		bad.append("one man falling apart does not move the room")

	## A reserve at rock bottom must not.
	var reserve: FighterCard = null
	for f in season.club.roster:
		if not eight.has(f):
			reserve = f
			break
	if reserve == null:
		bad.append("the starting club has no reserve to test with")
	else:
		var held := o.morale
		reserve.morale = 0.02
		o.sync_morale(season.club)
		if not is_equal_approx(o.morale, held):
			bad.append("a reserve who never travels sets the tone anyway")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("the room: %.2f as the average of %d travelling; one man at rock bottom takes it to %.2f, a reserve at rock bottom takes it nowhere"
		% [before, eight.size(), o.morale])
	_ok(bad.is_empty(), "the room is the men in it",
		"club morale is the average of the eight who travel, moves when one of them does, and ignores a reserve")


func _test_a_toxic_man_costs_the_others_a_loss() -> void:
	## *"Toxic players bring down the attitudes of team mates after a loss."* —
	## Retro Bowl's own tip, and the sentence that makes a toxic man a DECISION:
	## he is fine while you are winning. This check has to separate the drag from
	## the ordinary morale hit of losing, or it is measuring the loss.
	var bad: Array[String] = []

	## Two identical clubs, one with a toxic man on the eight and one without,
	## both losing the same event. Read the CLEAN men only — the toxic man is
	## excluded from the drag, so including him would dilute what we are measuring.
	var clean := Season.new(MeleeRosters.starting_club(), 99)
	var poisoned := Season.new(MeleeRosters.starting_club(), 99)
	for f in poisoned.club.active_eight():
		f.morale = 0.70
	for f in clean.club.active_eight():
		f.morale = 0.70
	poisoned.club.active_eight()[0].morale = 0.05

	clean._after_event(0, 3)
	poisoned._after_event(0, 3)

	var clean_avg := 0.0
	var n := 0
	for f in clean.club.active_eight():
		if f.morale > 0.18:
			clean_avg += f.morale
			n += 1
	clean_avg /= float(maxi(1, n))
	var dirty_avg := 0.0
	var m := 0
	for f in poisoned.club.active_eight():
		if not f.toxic():
			dirty_avg += f.morale
			m += 1
	dirty_avg /= float(maxi(1, m))

	if dirty_avg >= clean_avg:
		bad.append("a toxic man on the eight costs a losing side nothing")

	## And he must cost nothing on a WIN — that is the half that makes him worth
	## keeping. Same two clubs, same starting point, a win instead.
	var w_clean := Season.new(MeleeRosters.starting_club(), 99)
	var w_dirty := Season.new(MeleeRosters.starting_club(), 99)
	for f in w_clean.club.active_eight():
		f.morale = 0.70
	for f in w_dirty.club.active_eight():
		f.morale = 0.70
	w_dirty.club.active_eight()[0].morale = 0.05
	w_clean._after_event(3, 0)
	w_dirty._after_event(3, 0)
	var wc := 0.0
	var wd := 0.0
	for i in w_clean.club.active_eight().size():
		if i == 0:
			continue
		wc += w_clean.club.active_eight()[i].morale
		wd += w_dirty.club.active_eight()[i].morale
	if not is_equal_approx(wc, wd):
		bad.append("the toxic man drags the room after a WIN, and he must not")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("after a loss, the clean men average %.3f with a toxic man on the eight and %.3f without; after a win the two rooms are identical"
		% [dirty_avg, clean_avg])
	_ok(bad.is_empty(), "a toxic man costs the others a loss",
		"he drags the room down after a defeat and costs nothing after a win, which is why you keep him")


func _test_cutting_a_man_is_read_by_the_room() -> void:
	## Letting a menace go clears the air; letting a good man go does not. Both
	## directions, because a cut that only ever lifts morale is a free action.
	var bad: Array[String] = []

	var a := Season.new(MeleeRosters.starting_club(), 31337)
	## A RESERVE, not a benched man. `MeleeClub.cut` refuses anybody on the eight
	## — you swap him out first — and the first draft of this check picked a
	## backup, got the refusal, threw it away and then measured a room nobody had
	## left. Which is why the error is read now.
	var menace: FighterCard = null
	for f in a.club.roster:
		if not a.club.active_eight().has(f):
			menace = f
			break
	if menace == null:
		bad.append("no benched man to cut")
	else:
		menace.morale = 0.05
		for f in a.club.active_eight():
			if f != menace:
				f.morale = 0.60
		## THE SAME MEN BEFORE AND AFTER, captured by identity rather than by
		## re-reading `active_eight()`.
		##
		## This summed the travelling party on both sides of the cut, which was
		## fine while every club travelled eight — and the day a club's party
		## became a thing it buys (`ClubOffice.travel_slots`), the SET changed
		## under the measurement and the sum fell because there were fewer men in
		## it, not because anybody's morale moved. It read as "cutting a toxic man
		## does not clear the air", which is a false report of a real feature.
		var watched: Array[FighterCard] = []
		for f in a.club.active_eight():
			if f != menace:
				watched.append(f)
		var before := 0.0
		for f in watched:
			before += f.morale
		var err := a.release(menace)
		if err != "":
			bad.append("cutting the menace failed: %s" % err)
		var after := 0.0
		for f in watched:
			after += f.morale
		if after <= before - 0.0001:
			bad.append("cutting a toxic man does not clear the air")

	var b := Season.new(MeleeRosters.starting_club(), 31337)
	var liked: FighterCard = null
	for f in b.club.roster:
		if not b.club.active_eight().has(f):
			liked = f
			break
	var lifted := 0.0
	var dropped := 0.0
	if liked != null:
		liked.morale = 0.80
		for f in b.club.active_eight():
			if f != liked:
				f.morale = 0.60
		var watched_b: Array[FighterCard] = []
		for f in b.club.active_eight():
			if f != liked:
				watched_b.append(f)
		var before_b := 0.0
		for f in watched_b:
			before_b += f.morale
		var err_b := b.release(liked)
		if err_b != "":
			bad.append("cutting the liked man failed: %s" % err_b)
		var after_b := 0.0
		for f in watched_b:
			after_b += f.morale
		lifted = after_b
		dropped = before_b
		if after_b >= before_b:
			bad.append("cutting a man the room liked costs nothing")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("cutting a man the room liked: %.3f -> %.3f across the rest of them"
		% [dropped, lifted])
	_ok(bad.is_empty(), "cutting a man is read by the room",
		"releasing a toxic man lifts the rest and releasing a liked one costs you, so a cut is never free")


func _test_a_squad_arrives_with_a_spread_of_moods() -> void:
	## A GENERATED CLUB HAS TO HAVE A BOTTOM END, or the toxic half of the model
	## is code the player never meets. It also must not be all bottom end.
	var bad: Array[String] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 8675309
	var vals: Array[float] = []
	for _i in 4000:
		vals.append(ClubFactory.roll_morale(rng))
	var toxic := 0
	var angry := 0
	var lo := 2.0
	var hi := -1.0
	var probe := FighterCard.new()
	for v in vals:
		probe.morale = v
		if probe.toxic():
			toxic += 1
		if probe.angry():
			angry += 1
		lo = minf(lo, v)
		hi = maxf(hi, v)
	var toxic_rate := float(toxic) / float(vals.size())
	var angry_rate := float(angry) / float(vals.size())
	## A tail, not a coin flip. Loose bounds on purpose — this asserts the SHAPE,
	## not a number somebody will tune next week.
	if toxic_rate <= 0.0:
		bad.append("no man is ever generated toxic, so half the model is unreachable")
	if toxic_rate > 0.25:
		bad.append("a quarter of every squad arrives toxic, which is a mutiny rather than a tail")
	if angry_rate <= toxic_rate:
		bad.append("angry is not a wider band than toxic")
	if hi - lo < 0.30:
		bad.append("every generated man has much the same mood")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("4000 generated men: %.1f%% toxic, %.1f%% angry, moods from %.2f to %.2f"
		% [toxic_rate * 100.0, angry_rate * 100.0, lo, hi])
	_ok(bad.is_empty(), "a squad arrives with a spread of moods",
		"a generated club has a difficult tail the player will actually meet, and is not made of it")


func _test_nothing_on_a_card_runs_into_anything_else() -> void:
	## THE CARD COLLIDES WITH ITSELF, and the card-rect check above cannot see it.
	##
	## The line "41 · age 34" gained a mood, and on the first man on the roster it
	## came out "39 · age 26 · Exceptional" — which ran straight through the "to
	## 46" ceiling note drawn from the right edge of the same card. Both were
	## inside the card, so every geometric check in this file passed. What was
	## wrong was the WIDTH OF THE WORDS, and the only way to know that is to
	## measure the string in the font it is drawn in.
	##
	## So this walks every mood a man can be in, builds the note the card would
	## build, and measures it against the space the ceiling note leaves. It has to
	## cover all seven words rather than the one the test club happens to be in:
	## "Exceptional" is nine characters longer than "Ok" and it is the one that
	## broke.
	var font: Font = ThemeDB.fallback_font
	var bad: Array[String] = []
	var widest := ""
	var widest_px := 0.0

	## The card's own geometry, read from the screen rather than restated here.
	Session.season = Season.new(MeleeRosters.starting_club(), 777)
	var screen := _screen()
	var slots: Array = screen.call("_slots")
	var card_w := 0.0
	for sl in slots:
		if bool(sl.get("big", true)):
			card_w = maxf(card_w, float((sl["rect"] as Rect2).size.x))
	if card_w <= 0.0:
		card_w = (slots[0]["rect"] as Rect2).size.x

	var man := FighterCard.new()
	man.display_name = "Wexley"
	man.age = 34
	man.strength = 95
	man.base = 95
	man.skill = 95
	man.gas = 95
	## Ceiling above the rating, so the note on the right is "to 99" — the widest
	## thing that side can say, rather than the "capped" a maxed man would show.
	man.potential = 99
	var moods: Array[float] = [0.02, 0.15, 0.20, 0.30, 0.40, 0.56, 0.75, 0.90, 0.99]
	for m in moods:
		man.morale = m
		var flag := man.morale_flag()
		var note := ("%d  ·  age %d  ·  %s" % [man.overall(), man.age, flag]) if flag != "" \
			else ("%d  ·  age %d" % [man.overall(), man.age])
		## THE RIGHT NOTE IS MEASURED, NOT ASSUMED. The first version of this check
		## subtracted the 90px max-width the card passes to `UiKit.right` and
		## failed on a note that fits fine — 90 is a ceiling on that string, not
		## the room it takes. Measure what is actually drawn.
		##
		## Both halves sit 8px in from their own edge of the card, and the two
		## want a few pixels of air between them or they read as one string.
		var ceiling := "capped" if man.potential <= man.overall() else "to %d" % man.potential
		var right_px := font.get_string_size(ceiling, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		var room := card_w - 16.0 - right_px - 6.0
		var px := font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		if px > widest_px:
			widest_px = px
			widest = note
		if px > room:
			bad.append("'%s' is %.0fpx in a %.0fpx gap" % [note, px, room])

	## AND THE POSITIVE CONTROL. The bug this check exists for was the unflagged
	## word "Exceptional" on this line; if the measurement cannot fail on the
	## string that actually broke, it is not measuring anything.
	var broken := "%d  ·  age %d  ·  Exceptional" % [man.overall(), man.age]
	var broken_px := font.get_string_size(broken, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	var ceiling_px := font.get_string_size("to 99", HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	var caught: bool = broken_px > card_w - 16.0 - ceiling_px - 6.0
	if not caught:
		bad.append("the check does not fail on '%s', the string that broke" % broken)

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("the widest note any mood can produce is '%s' at %.0fpx, in a %.0fpx card"
		% [widest, widest_px, card_w])
	notes.append("and the string that broke it, '%s' at %.0fpx, is still caught: %s"
		% [broken, broken_px, "yes" if caught else "NO — the check has no teeth"])
	_ok(bad.is_empty(), "nothing on a card runs into anything else",
		"every one of the seven moods produces a note that clears the ceiling note on the same card")
	screen.queue_free()


func _test_the_register_still_describes_the_code() -> void:
	## WHERE A DOCUMENT RESTATES DATA THE CODE ALREADY HOLDS, ASSERT THE
	## RESTATEMENT. Same rule the credits screen and the art spec are held to.
	##
	## Section 43 of the register writes out the morale chips, the two bands, the
	## specialty ladder, the captain prices and the save version as figures in a
	## table. Every one of those is a constant a tuning session will move, and a
	## register that quietly stops being true is worse than no register: it is a
	## document somebody will act on.
	var text := ""
	var f := FileAccess.open("res://docs/REGISTER.md", FileAccess.READ)
	if f != null:
		text = f.get_as_text()
		f.close()
	var bad: Array[String] = []
	if text == "":
		bad.append("docs/REGISTER.md is missing or empty")

	## Built from the constants, never typed here — a literal in this file is the
	## same restatement problem one layer down.
	var probe := FighterCard.new()
	probe.morale = 0.5
	var want := {
		"the strength chip": "**+%d**" % FighterCard.CHIP_STRENGTH,
		"the gas chip": "**+%d**" % FighterCard.CHIP_GAS,
		"the angry band": "below %.2f" % _angry_edge(),
		"the toxic band": "below %.2f" % _toxic_edge(),
		"the specialty ladder": "0 / 1 / 1 / 2 / 2",
		"the specialty multiplier": "×%.2f" % ClubOffice.SPECIALTY_XP,
		"the captain prices": _price_ladder(),
		"the save version": "VERSION %d" % SaveGame.VERSION,
		"the sour range": "%.2f-%.2f" % [ClubFactory.SOUR_LO, ClubFactory.SOUR_HI],
		"the happy range": "%.2f-%.2f" % [ClubFactory.FINE_LO, ClubFactory.FINE_HI],
	}
	## And the ladder the register spells out has to be the one the code walks.
	var ladder: Array[int] = []
	for g in range(1, 6):
		ladder.append(ClubOffice.specialty_count(g))
	if str(ladder) != "[0, 1, 1, 2, 2]":
		bad.append("the specialty ladder is %s, and the register says 0 / 1 / 1 / 2 / 2"
			% str(ladder))

	for what in want:
		if not text.contains(String(want[what])):
			bad.append("%s: the register never states '%s'" % [what, String(want[what])])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("the register restates %d figures the code holds, and all of them still agree"
		% want.size())
	_ok(bad.is_empty(), "the register still describes the code",
		"every number section 43 writes out is the number the code is actually using")


## The two band edges, found by walking rather than restated — the constants are
## inside the predicates, which is where they belong.
func _angry_edge() -> float:
	var probe := FighterCard.new()
	var v := 0.0
	while v <= 1.0:
		probe.morale = v
		if not probe.angry():
			return snappedf(v, 0.01)
		v += 0.005
	return -1.0


func _toxic_edge() -> float:
	var probe := FighterCard.new()
	var v := 0.0
	while v <= 1.0:
		probe.morale = v
		if not probe.toxic():
			return snappedf(v, 0.01)
		v += 0.005
	return -1.0


func _price_ladder() -> String:
	var out: Array[String] = []
	for g in range(1, 6):
		out.append("%d" % ClubOffice.cost_of(
			ClubOffice.captain("N", Tuning.Role.RAIL, Tuning.Role.CENTER, g)))
	return " / ".join(out)


## ------------------------------------------------------ a club that is short
## FOUR MEN ON THE LIST IS A STATE THE GAME CAN REACH, and for a fortnight it
## was a state the sim could not survive.
##
## `starting_five()` is honest about coming up short: it returns a FOUR-long
## array rather than padding with nulls. The sim then numbered its men
## `team * 5 + i`, which was a fact for exactly as long as both sides fielded
## five. With four on one side, every man on the other carried an index one past
## himself — `partner`, `target`, the wear ledger and the assist credit are all
## lookups into `men` by `idx`, so each addressed the WRONG FIGHTER, silently,
## and the last man's index addressed nobody and crashed the bout.
##
## A party of six at the bottom of the pyramid reaches this on an ordinary
## weekend: one knock and one man who cannot get the time off. A soak found it
## in season four. Nothing in 497 checks had ever built a short line, because
## every one of them started from a healthy club — **a state nothing constructs
## is a state nothing tests.**
func _test_a_short_line_still_numbers_its_men() -> void:
	var bad: Array[String] = []
	var a := MeleeRosters.starting_club()
	var b := MeleeRosters.starting_club()
	## Put men out until the club can only raise four. Injury rather than a cut,
	## because that is the road a real club takes to get here.
	var guard := 0
	while a.starting_five().size() >= MeleeClub.LINE_SIZE and guard < 20:
		guard += 1
		for f in a.active_eight():
			if f.fit():
				f.injury = 3
				break
	var short_line := a.starting_five().size()
	if short_line >= MeleeClub.LINE_SIZE:
		bad.append("could not put the club under a line to test it")
	notes.append("a short line: %d men raised against a full five" % short_line)

	var sim := MeleeSim.new(a, b, 4242)

	## 1. EVERY INDEX ADDRESSES ITS OWN MAN. This is the whole bug in one line.
	for i in sim.men.size():
		if sim.men[i].idx != i:
			bad.append("man at %d carries idx %d" % [i, sim.men[i].idx])
			break
	## 2. And every index the sim stores is one it can look up.
	for m in sim.men:
		if m.partner < -1 or m.partner >= sim.men.size():
			bad.append("%s points at partner %d of %d" % [m.card.display_name,
				m.partner, sim.men.size()])
			break
		if m.target < -1 or m.target >= sim.men.size():
			bad.append("%s points at target %d of %d" % [m.card.display_name,
				m.target, sim.men.size()])
			break
	## 3. Both sides are still whole clubs, not one club and a remainder.
	var by_team := [0, 0]
	for m in sim.men:
		by_team[m.team] += 1
	if by_team[0] + by_team[1] != sim.men.size():
		bad.append("the men do not add up to the two sides")
	if by_team[1] != MeleeClub.LINE_SIZE:
		bad.append("the full side fielded %d" % by_team[1])

	## 4. AND THE BOUT ACTUALLY FINISHES. The crash was an out-of-bounds inside
	## `_put_down`, which only happens once somebody goes down — so building the
	## sim is not enough, it has to be fought.
	sim.run_to_end()
	## `is_over()`, NOT `finished()`. There is no `finished()` on `MeleeSim` and
	## there never was, so this line threw every run and this arm of the check
	## has never once been entered — `SCRIPT ERROR: Nonexistent function
	## 'finished'` scrolled past in a suite that then printed THE ROSTER HOLDS.
	## Found on 15 Sep by reading a log rather than its last line. **An error you
	## do not read is an error that did not happen**, and a green summary above a
	## thrown call is the most expensive way to learn it.
	if not sim.is_over():
		bad.append("a short-handed bout never reached an end")
	for m in sim.men:
		if m.target >= sim.men.size():
			bad.append("a target ran off the end of the list during the bout")
			break

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "a short line still numbers its men",
		"a club that can only raise four fights a bout to the end without addressing a man who is not there")


## ------------------------------------------------------- the shape of a squad
## A SQUAD IS NOT A FLAT DRAW BETWEEN NINETEEN AND THIRTY-NINE, and for a long
## time every club in the country was exactly that.
##
## `ClubFactory._fighter` used `randi_range(AGE_MIN, AGE_MAX)`, which gives a
## nineteen-year-old and a thirty-eight-year-old precisely the same chance of
## being on the line. The eight that travels is the line plus the bench — the
## reserve slots draw from their own younger band and do not travel — so a club
## could field five men all past their peak and never see the youngsters on its
## own books. A twenty-season career walk turned it up as a starting eight
## averaging THIRTY-TWO against a learning par of twenty-six.
##
## Nothing was wrong with any single number. **The DISTRIBUTION was wrong, and a
## distribution is not something any assertion in this suite was looking at** —
## every check here reads one club, and one club drawn from a flat band looks
## like a perfectly ordinary squad. It only shows up in the aggregate, so the
## check has to be written in the aggregate.
func _test_a_squad_is_shaped_like_a_squad() -> void:
	var bad: Array[String] = []
	var ages: Array[int] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	## The men who TRAVEL, across a lot of clubs. The reserve is excluded on
	## purpose: it has its own younger band by design, and averaging it in would
	## hide the thing being measured.
	for i in 120:
		var c := ClubFactory.build(1000 + i, "Test %d" % i, "T%d" % i,
			rng.randi_range(30, 80))
		for f in c.active_eight():
			ages.append(f.age)
	if ages.size() < 200:
		bad.append("only %d men to measure" % ages.size())
	var total := 0
	for a in ages:
		total += a
	var mean := float(total) / float(maxi(1, ages.size()))

	## 1. THE MEAN SITS IN THE PRIME BAND. Peak gas is 24 and peak skill is 35;
	## a squad of grown men who fight in armour averages somewhere in there, and
	## a flat draw across 19-39 lands at 29 too — so this alone is not the check,
	## it is the sanity rail under it.
	if mean < float(Career.PEAK_GAS) or mean > float(Career.PEAK_SKILL):
		bad.append("the travelling average is %.1f, outside the prime band %d-%d"
			% [mean, Career.PEAK_GAS, Career.PEAK_SKILL])

	## 2. AND IT IS CENTRED, which is the part a flat draw fails. Split the career
	## span into thirds: a triangle puts most of its men in the middle third, a
	## flat line puts exactly a third there. Anything at or under a half is flat.
	var span := Career.AGE_MAX - Career.AGE_MIN
	var lo_edge := Career.AGE_MIN + span / 3
	var hi_edge := Career.AGE_MAX - span / 3
	var young := 0
	var middle := 0
	var old := 0
	for a in ages:
		if a < lo_edge:
			young += 1
		elif a > hi_edge:
			old += 1
		else:
			middle += 1
	var mid_share := float(middle) / float(maxi(1, ages.size()))
	if mid_share <= 0.5:
		bad.append("only %d%% of travelling men are in the middle third — that is a flat draw"
			% int(round(mid_share * 100.0)))

	## 3. AND BOTH TAILS SURVIVE. A triangle is not a clamp: a nineteen-year-old
	## and a thirty-eight-year-old are rarer, not impossible, and a league with
	## no veterans in it is a different bug wearing the same fix.
	if young == 0:
		bad.append("no man under %d travels anywhere in the country" % lo_edge)
	if old == 0:
		bad.append("no man over %d travels anywhere in the country" % hi_edge)

	notes.append("%d travelling men across 120 clubs: average %.1f, %d%% young / %d%% prime / %d%% old"
		% [ages.size(), mean, int(round(100.0 * young / ages.size())),
			int(round(mid_share * 100.0)), int(round(100.0 * old / ages.size()))])
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "a squad is shaped like a squad",
		"the men who travel are concentrated in their prime rather than spread flat across a twenty-year career span, and both tails still exist")


## ------------------------------------------------- naming your own starters
## THE VERB THE SQUAD SCREEN NEVER HAD.
##
## Pete, playing the game end to end on 15 Sep 2026: *"No way to drag players
## into fighter slots. 'Pick who to trade places with' can just drop fighters
## from starts to bench without a way to add anyone to starters."*
##
## He is right and the cause is `starting_five()`: the five are CHOSEN, by
## walking `active_eight()` — which is roster order — and taking the first fit
## man who covers each slot. Roster order IS the depth chart, and until now
## nothing in the game could reorder it. `swap_squad` moved men between the bus
## and the clubhouse; there was no move at all inside the bus, so a man who ended
## up on the bench stayed there whatever the player thought of him.
func _test_a_player_can_name_his_own_starters() -> void:
	var c := MeleeRosters.starting_club()
	c.travel_cap = MeleeClub.ACTIVE_SIZE
	var eight := c.active_eight()
	var before := c.starting_five()
	var bench_man: FighterCard = eight[eight.size() - 1]
	_ok(not before.has(bench_man), "a man at the foot of the depth chart does not start",
		"%s is eighth of eight" % bench_man.display_name)

	var err := c.swap_order(before[0], bench_man)
	var after := c.starting_five()
	_ok(err == "" and after.has(bench_man),
		"and moving him up the chart puts him on the line",
		"%s started after one swap%s" % [bench_man.display_name,
			"" if err == "" else " — " + err])

	## AND IT IS REVERSIBLE, exactly. A reorder that cannot be undone is a
	## reorder a player will not use.
	c.swap_order(bench_man, before[0])
	var back := c.starting_five()
	var same := back.size() == before.size()
	for i in back.size():
		if i < before.size() and back[i] != before[i]:
			same = false
	_ok(same, "and swapping the pair back restores the line exactly",
		"the depth chart is the only state a reorder touches")

	## NOTHING ELSE MOVES. Position in the list is the only thing the verb says;
	## a reorder that quietly changed `active`, fitness or a contract would be a
	## squad edit wearing a sort's clothes.
	var kept := true
	for f in c.roster:
		if f.active != eight.has(f) and c.reserves().has(f) == eight.has(f):
			kept = false
	_ok(kept and c.active_eight().size() == eight.size(),
		"and the same eight are still travelling",
		"a reorder is not a squad change")

	## A MAN WHO IS NOT ON THE BOOKS IS REFUSED, like every other verb here.
	var stranger := MeleeRosters.starting_club().roster[0]
	_ok(c.swap_order(c.roster[0], stranger) != "",
		"a fighter who is not on this club cannot be ordered into it",
		"refused with a sentence, like every other verb on the club")
	notes.append("the depth chart: %s -> %s and back"
		% [before[0].display_name, bench_man.display_name])
