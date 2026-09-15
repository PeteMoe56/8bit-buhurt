extends SceneTree
## THE ARENA and the events you put on in it.
##
##   godot --headless --path . --script res://tests/test_arena.gd
##
## The thing worth proving here is the GAMBLE. Pete asked for an event economy
## where *"you'll either lose a little money, break even, or win money"* — which
## is three outcomes, not a payout curve with a floor at zero. A tournament that
## cannot lose is a button, and a button is not a decision.
##
## So the checks are: the ladder is gated by the league and not by the wallet,
## all three outcomes actually occur, and the thing that decides which one you
## get is reputation rather than luck.

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	## Its own corner of user:// — these files run in parallel and there are
	## only three slots between all of them.
	SaveGame.set_namespace("arena")
	print("\n=== 8-Bit Buhurt — the arena ===\n")
	_test_the_league_gates_the_ladder()
	_test_the_ladder_costs_credits()
	_test_a_demo_cannot_lose()
	_test_a_tournament_can_lose()
	_test_the_ground_and_the_following_both_cap_the_house()
	_test_the_climb_feeds_the_following()
	_test_the_bid_is_a_start_of_year_decision()
	_test_you_can_pass_on_the_year()
	_test_the_bid_comes_round_every_year()
	_test_one_event_at_a_time()
	_test_the_badge_improves_with_the_ground()
	_test_the_arena_saves()
	_test_the_art_spec_matches_the_code()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE ARENA HOLDS (%d checks)\n" % checks)
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


func _test_the_league_gates_the_ladder() -> void:
	## THE POINT OF THE WHOLE FEATURE. Every other purchase in this game asks
	## "have you got the credits"; this one asks "have you earned the right", and
	## a Backyard club with a fortune must still be refused.
	var a := Arena.new()
	var rich := a.can_build(0, 9999)      ## Backyard, unlimited money
	a.level = 1
	var still := a.can_build(0, 9999)     ## next is Fenced ground, tier 1
	a.level = 5
	var top := a.can_build(3, 9999)
	_ok(rich == "" and still.find("promoted") != -1 and top.find("as far") != -1,
		"the league gates the ladder",
		"a Backyard club with 9999 credits is refused the Fenced ground: %s" % still)
	## And the tiers only ever go up, or the gate means nothing.
	var rising := true
	for i in range(1, Arena.LEVELS.size()):
		if int(Arena.LEVELS[i]["tier"]) < int(Arena.LEVELS[i - 1]["tier"]):
			rising = false
		if int(Arena.LEVELS[i]["capacity"]) <= int(Arena.LEVELS[i - 1]["capacity"]):
			rising = false
	_ok(rising, "the ladder only goes up",
		"six grounds, %d to %d capacity" % [
			int(Arena.LEVELS[0]["capacity"]), int(Arena.LEVELS[Arena.MAX_LEVEL]["capacity"])])


func _test_the_ladder_costs_credits() -> void:
	var a := Arena.new()
	a.level = 1
	var broke := a.can_build(1, 0)
	var afford := a.can_build(1, 99)
	_ok(broke.find("costs") != -1 and afford == "",
		"and it costs credits too",
		"promoted but skint is still refused: %s" % broke)


func _test_a_demo_cannot_lose() -> void:
	## The floor of the economy. A club with nothing must always have something
	## it can do that pays, or a bad run becomes unrecoverable.
	var s := _season()
	s.office.credits = 0
	var err := s.run_demo()
	var paid := s.office.credits
	_ok(err == "" and paid > 0 and ClubEvent.DEMO_COST == 0,
		"a demo cannot lose",
		"a broke club with a back field ran a demo for %d credits" % paid)


func _test_a_tournament_can_lose() -> void:
	## ALL THREE OUTCOMES HAVE TO EXIST. Pete: *"you'll either lose a little
	## money, break even, or win money."* A payout that cannot go negative is a
	## button, not a bet — so this sweeps a club's following against every budget
	## and asserts that the sign of the result actually changes.
	var losses := 0
	var evens := 0
	var wins := 0
	var line := ""
	var cap := int(Arena.LEVELS[4]["capacity"])
	## THE AXIS IS THE FOLLOWING NOW, not notoriety — there is one crowd number
	## and this sweeps it from a club nobody comes to up to one that sells the
	## place out. Same question, same shape, one population.
	for share in [0.05, 0.25, 0.60, 1.10]:
		line += "\n     following %4d: " % int(float(cap) * share)
		for b in ClubEvent.BUDGETS.size():
			var p := ClubEvent.preview(cap, float(cap) * share, b,
				ClubEvent.bid_cost(2))
			line += "%s %+d  " % [String(ClubEvent.BUDGETS[b]["name"]), int(p["net"])]
			if int(p["net"]) < 0:
				losses += 1
			elif int(p["net"]) == 0:
				evens += 1
			else:
				wins += 1
	notes.append("tournament net by following and budget:" + line)
	_ok(losses > 0 and wins > 0,
		"a tournament can lose",
		"%d losing, %d level, %d winning combinations across the sweep" % [losses, evens, wins])
	## And the worst case is a bruise, not a wipe-out — "lose a little money".
	var worst := 0
	for b in ClubEvent.BUDGETS.size():
		var p := ClubEvent.preview(int(Arena.LEVELS[0]["capacity"]), 0.0, b,
			ClubEvent.bid_cost(3))
		worst = mini(worst, int(p["net"]))
	var dearest: int = int(ClubEvent.BUDGETS[ClubEvent.BUDGETS.size() - 1]["cost"]) \
		+ ClubEvent.bid_cost(3)
	_ok(worst < 0 and worst >= -dearest,
		"and it loses a LITTLE",
		"the worst bid in the game is %d credits, and you cannot lose more than the %d you spent" % [
			worst, dearest])


func _test_the_ground_and_the_following_both_cap_the_house() -> void:
	## THIS CHECK USED TO BE `fans and notoriety both matter` and it was about two
	## populations. There is one now — Pete, 15 Sep 2026: *"I don't like our 3
	## factors, there should be one"* — so the question it asks has changed and the
	## reason it exists has not.
	##
	## A house is capped twice, by the SEATS and by the PEOPLE, and neither cap
	## alone is the whole system. If the ground filled itself the feature would be
	## "buy the biggest one"; if the following filled any ground, the arena ladder
	## would be decoration.
	var big := int(Arena.LEVELS[5]["capacity"])
	var small := int(Arena.LEVELS[0]["capacity"])
	var packed := ClubEvent.attendance(big, float(big) * 1.25)
	var no_following := ClubEvent.attendance(big, 40.0)
	var no_ground := ClubEvent.attendance(small, float(big) * 1.25)
	_ok(packed == big and no_following <= 40 and no_ground == small,
		"the ground and the following both cap the house",
		"a full following in a National Arena draws %d of %d; forty people in the same room draw %d; the same following at a back field draws %d of %d"
			% [packed, big, no_following, no_ground, small])

	## THE 25% RULE. Pete: *"each level can have 25% over their max upgraded
	## arena… 25% of fans usually never come to events."* So a club at the fan
	## ceiling sells out AND turns a quarter away, which is the top of the whole
	## system and has to be reachable.
	var o := ClubOffice.new()
	o.arena.level = Arena.MAX_LEVEL
	o.fans = 1e9
	o._clamp_fans()
	var turned_away := int(o.fans) - o.attendance()
	_ok(is_equal_approx(o.fan_cap(), float(o.arena.capacity()) * 1.25)
			and o.attendance() == o.arena.capacity() and turned_away > 0,
		"a quarter of the fans never get in",
		"%d fans, %d seats, %d left outside" % [
			int(o.fans), o.attendance(), turned_away])

	## AND THE BAND READS THE HOUSE. The gate used to be banded off a fame number
	## that had nothing to do with how many people were in the room; it reads the
	## turnstile now, so **filling the ground you built is a band and building the
	## next one is the next band.** That is the relationship the arena screen has
	## always claimed and the economy never had.
	## A PACKED GROUND IS A PACKED GROUND WHATEVER ITS SIZE — every one of the six
	## reads band 5 when it is full, and that is the design rather than a bug: the
	## band asks *"did you fill it"* and the SIZE is `Arena.gate_factor`, which is
	## where the climbing lives. The first cut of this check banded absolute heads
	## and asserted the opposite; it pinned the whole bottom of the pyramid to
	## band 0 and a career's gate to 6.3 credits a season.
	##
	## So what has to be true is that a packed bigger ground PAYS MORE, which is
	## the two halves multiplying.
	var bands: Array[String] = []
	var last := -1
	var climbs := 0
	for lv in Arena.LEVELS.size():
		var c := ClubOffice.new()
		c.arena.level = lv
		c.fans = 1e9
		c._clamp_fans()
		var pay := c.crowd_pay()
		bands.append("%s band %d, %d CC" % [Arena.arena_name_of(lv),
			c.crowd_band(), pay])
		if pay > last:
			climbs += 1
		last = pay
	_ok(climbs >= 4, "and a packed bigger ground pays more than a packed smaller one",
		"filled, the six grounds pay: " + ", ".join(bands))


func _test_the_climb_feeds_the_following() -> void:
	## THE FOLLOWING HAS TO ACTUALLY MOVE, and going up has to be a big part of
	## it — the pyramid is the fuel, which is what makes a small club small.
	##
	## It used to assert this about notoriety, with a per-tier win constant to
	## prove a win at National was worth more than one in the Backyard Circuit.
	## That constant is gone and it is not missed: a win at National is watched by
	## twelve thousand people instead of forty, and `fan_cap()` says so without a
	## ladder of its own. **A number that is implied by the ground does not need a
	## second table.**
	var o := ClubOffice.new()
	o.arena.level = 3
	var start := o.fans
	for i in 10:
		o.after_event(true, false)
	var ten_wins := o.fans - start
	var p := ClubOffice.new()
	p.arena.level = 3
	p.after_move(true)
	var promotion := p.fans - start
	_ok(ten_wins > 0.0 and promotion > 0.0,
		"the climb feeds the following",
		"ten wins at a sports hall move it %.0f; going up moves it %.0f"
			% [ten_wins, promotion])

	## AND A WIN IS WORTH MORE THE HIGHER YOU ARE, without a per-tier constant:
	## the gap to the ceiling is the ceiling, and the ceiling is the ground.
	var low := ClubOffice.new()
	var high := ClubOffice.new()
	high.arena.level = Arena.MAX_LEVEL
	var lo0 := low.fans
	var hi0 := high.fans
	low.after_event(true, false)
	high.after_event(true, false)
	_ok((high.fans - hi0) > (low.fans - lo0) * 10.0,
		"and a win at the top is worth more than a win at the bottom",
		"%.1f at a back field against %.1f at a National Arena"
			% [low.fans - lo0, high.fans - hi0])

	## Fans grow toward the ground and bleed when you stop winning.
	var f := ClubOffice.new()
	f.arena.level = 3
	var f0 := f.fans
	for i in 10:
		f.after_event(true, false)
	var grown := f.fans
	f.winter()
	var after_winter := f.fans
	_ok(grown > f0 * 3.0 and grown <= f.fan_cap() and after_winter < grown,
		"fans grow toward the ground, and bleed",
		"%d -> %d of a %d ceiling, then %d over the winter" % [
			int(f0), int(grown), int(f.fan_cap()), int(after_winter)])


func _test_the_bid_is_a_start_of_year_decision() -> void:
	## Pete, 10 Sep 2026: *"Let's make player made tournament a 'start of year'
	## process… you can choose a certain week in the season to hold your own
	## tournament… we can give like 3 options per year."*
	##
	## Three dates, answered before the first matchday, and both the date and
	## the budget paid on the spot — a season before the show. That gap is the
	## whole bet: you commit against the ground and the reputation you have TODAY
	## and find out next summer whether the year you had was good enough.
	var s := _season()
	s.office.credits = 40
	_ok(s.bid_open() and s.bid_offers.size() == 3,
		"three dates, every year",
		"the federation opened with %d on the table" % s.bid_offers.size())

	## They must be real, distinct matchdays inside the season, ordered, and
	## never the opening day — a tournament on matchday one has nothing to trade
	## on because nobody has played anything yet.
	var n := League.events_in_season(s.world.player_tier())
	var days: Array = []
	var ordered := true
	var dearer := true
	for i in s.bid_offers.size():
		var o: Dictionary = s.bid_offers[i]
		days.append(int(o["event"]))
		if i > 0:
			if int(o["event"]) < int(s.bid_offers[i - 1]["event"]):
				ordered = false
			## ALL THREE COST THE SAME NOW. Pete, 10 Sep 2026 — the price is the
			## division's, not the date's, so the only thing separating the three
			## is how much club you can build before the day arrives.
			if int(o["bid"]) != int(s.bid_offers[i - 1]["bid"]):
				dearer = false
	_ok(ordered and dearer and days[0] >= 1 and days[days.size() - 1] < n,
		"the dates are real and all cost the same",
		"matchdays %s of a %d-event season, all at %d credits" % [
			str(days), n, int(s.bid_offers[0]["bid"])])

	var offer: Dictionary = s.bid_offers[2]
	var spend := int(offer["bid"]) + int(ClubEvent.BUDGETS[1]["cost"])
	var err := s.take_bid(2, 1)
	_ok(err == "" and not s.bid_open() and s.booked != null
			and s.booked.due == int(offer["event"])
			and s.office.credits == 40 - spend,
		"taking a date spends it now",
		"%s cost %d up front and lands on matchday %d" % [
			String(offer["name"]), spend, int(offer["event"]) + 1])

	## And then it actually happens, on the day it was bought for.
	var guard := 0
	while not s.cup_pending() and guard < 20 and not s.season_complete():
		guard += 1
		s.skip_event()
	var opened := s.cup_pending()
	var ties := 0
	while s.cup_pending() and ties < 10:
		ties += 1
		s.sim_cup_tie()
	_ok(opened and s.booked == null and not s.last_show.is_empty(),
		"and it happens on the day you bought",
		"the draw came up on matchday %d: %s, %d in, net %+d" % [
			guard, String(s.last_show.get("kind", "?")),
			int(s.last_show.get("heads", 0)), int(s.last_show.get("net", 0))])


func _test_you_can_pass_on_the_year() -> void:
	## A club that cannot afford a date must still be able to get on with its
	## season, and passing has to be free.
	var s := _season()
	s.office.credits = 0
	var broke := s.take_bid(2, 2)
	s.decline_bid()
	_ok(broke != "" and not s.bid_open() and s.booked == null and s.office.credits == 0,
		"you can pass on the year",
		"a skint club is refused the date and passes for nothing: %s" % broke)


func _test_the_bid_comes_round_every_year() -> void:
	## It is a yearly ritual, not a one-off, and a promoted club is offered a
	## longer calendar with later dates in it.
	var s := _season()
	s.decline_bid()
	var guard := 0
	while not s.ready_to_roll() and guard < 40:
		guard += 1
		if s.cup_pending():
			s.sim_cup_tie()
		else:
			s.skip_event()
	s.roll_over()
	_ok(s.bid_open() and s.bid_offers.size() == 3,
		"the bid comes round every year",
		"a new season opened with %d dates back on the table" % s.bid_offers.size())


func _test_one_event_at_a_time() -> void:
	var s := _season()
	s.office.credits = 60
	s.take_bid(0, 0)
	var second := s.take_bid(0, 2)
	var demo := s.run_demo()
	_ok(second != "" and demo != "",
		"one event at a time",
		"a second bid is refused once the year's date is taken: %s" % second)


func _test_the_badge_improves_with_the_ground() -> void:
	var a := Arena.new()
	var rising := true
	var last := -1.0
	var line := ""
	for lvl in Arena.MAX_LEVEL + 1:
		a.level = lvl
		line += "%s %.0f%%  " % [a.arena_name(), a.badge_quality() * 100.0]
		if a.badge_quality() <= last:
			rising = false
		last = a.badge_quality()
	notes.append("badge quality: " + line.strip_edges())
	a.level = 0
	var bottom := a.badge_quality()
	a.level = Arena.MAX_LEVEL
	_ok(rising and is_equal_approx(bottom, 0.0) and is_equal_approx(a.badge_quality(), 1.0),
		"the badge improves with the ground",
		"rough at a back field, printed at a national arena")


func _test_the_arena_saves() -> void:
	var s := _season()
	s.office.credits = 60
	s.office.arena.level = 3
	s.office.fans = 900.0
	s.take_bid(2, 2)
	var due := s.booked.due
	SaveGame.save(s, 2)
	var back := SaveGame.load_slot(2)
	SaveGame.delete(2)
	_ok(back != null and back.office.arena.level == 3
			and is_equal_approx(back.office.fans, 900.0)
			and back.booked != null and back.booked.due == due
			and back.booked.budget == 2
			and not back.office.facilities.has(0),
		"the arena survives a save",
		"the ground, the following and the booking all came back; no Home ground key left")


func _season() -> Season:
	return Season.new(MeleeRosters.starting_club(), 88)


func _test_the_art_spec_matches_the_code() -> void:
	## `docs/ART.md` IS THE BRIEF SOMEBODY ELSE WORKS FROM.
	##
	## Pete is sourcing the artwork, which means the spec is not a note to
	## ourselves — it is an instruction to a third party, and a wrong path or a
	## wrong size in it costs somebody a render rather than a compile. So the two
	## have to agree, and "have to agree" has meant "somebody remembers" exactly
	## often enough in this project to stop trusting it.
	##
	## Same shape as the credits check: where a document restates data the code
	## already holds, assert the restatement.
	var text := ""
	var f := FileAccess.open("res://docs/ART.md", FileAccess.READ)
	if f != null:
		text = f.get_as_text()
		f.close()
	var bad: Array[String] = []
	if text == "":
		bad.append("docs/ART.md is missing or empty")
	for id in ArtBank.SLOTS:
		var slot: Dictionary = ArtBank.SLOTS[id]
		var rel := "art/" + String(slot["path"])
		if not text.contains(rel):
			bad.append("%s: ART.md never names %s" % [String(id), rel])
		var sz: Vector2 = slot["size"]
		## The size has to appear the way a person would write it, because a
		## person is the one reading it.
		var written := "%d × %d" % [int(sz.x), int(sz.y)]
		if not text.contains(written):
			bad.append("%s: ART.md never states %s" % [String(id), written])
	var take := ArtBank.stocktake()
	notes.append("art: %d of %d slots filled%s"
		% [take["have"], take["want"],
			"" if take["missing"].is_empty()
			else " — waiting on " + ", ".join(take["missing"] as Array)])
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "the art spec matches the code",
		"every slot the game looks for is named in docs/ART.md at its real path and size")
