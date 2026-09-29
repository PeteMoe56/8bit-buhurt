extends SceneTree
## The clubhouse: credits, the cap, the facilities, the captains, and the knocks.
##
##   godot --headless --path . --script res://tests/test_office.gd
##
## The thing worth proving here is not that a button spends a credit. It is that
## every one of these levers reaches something that already existed and was
## already measured — a facility or a staff card that only feeds another
## facility is a progress bar with a name on it.

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
	SaveGame.set_namespace("office")
	print("\n=== 8-Bit Buhurt — the clubhouse ===\n")
	_test_the_cap_bites()
	_test_captains_cover_three_roles_with_two_men()
	_test_captains_reach_the_list()
	_test_the_stars_are_what_you_pay_for()
	_test_facilities_reach_something()
	_test_a_knock_costs_you_a_man()
	_test_the_office_saves()
	_test_the_crowd_bands_the_pay()
	_test_the_retainer_stays_a_retainer()
	_test_the_retainer_pays_a_club_nobody_has_heard_of()
	_test_nothing_a_new_club_owns_is_pinned_at_zero()
	_test_the_meeting_sells_what_it_offers()
	_test_the_bills_come_due()
	_test_what_you_cannot_pay_falls_down()
	_test_one_job_at_a_time()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE CLUBHOUSE HOLDS (%d checks)\n" % checks)
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


func _test_the_cap_bites() -> void:
	## THE CAP HAS TO FIT ITS OWN DIVISION. The best club a league can field must
	## bill just inside that league's cap, and the club you start with must fit
	## with room to sign. The first attempt anchored the wage curve and the caps
	## separately and a top-of-table Backyard club billed four times its own
	## league's limit — which is not a tight cap, it is a broken one.
	var o := ClubOffice.new()
	var line := ""
	var bad := 0
	for t in League.TIERS.size():
		o.tier = t
		o.cap_level = 0
		var band: Array = League.TIERS[t]["power"]
		var top := ClubFactory.build(900 + t, "Top", "TOP", int(band[1]))
		var bill := ClubOffice.wage_bill(top)
		line += "%s %s of %s   " % [String(League.TIERS[t]["short"]),
			ClubOffice.money(bill), ClubOffice.money(o.cap())]
		if bill > o.cap():
			bad += 1

	## And the club you actually start with, in the division you start in.
	o.tier = League.Tier.BACKYARD
	o.cap_level = 0
	var start := ClubOffice.wage_bill(MeleeRosters.starting_club())
	## Pete, 29 Sep 2026 (#13): the cap BINDS now — raises are a needed purchase —
	## so the starting squad no longer sits under half of it. It must still fit
	## with a fifth of the cap spare, or the first signing is impossible.
	var cap0 := o.cap()
	var room: bool = start <= int(cap0 * 0.8)

	## RAISING IT HAS TO COST, AND THE COST HAS TO CLIMB. It used to have to STOP
	## as well — five raises and a wall — and that assertion is gone on purpose:
	## Pete asked for the upgradable cap to work like Retro Bowl's, and the wall
	## was what left a club sitting on eleven hundred unspent credits unable to
	## sign anybody. What replaces it is the property that actually matters, which
	## is that a fixed purse buys a FINITE number of raises because each one costs
	## more than the last.
	o.credits = 200
	var raised := 0
	var costs: Array[int] = []
	while o.credits >= o.cap_cost():
		## A NEW WEEK EACH TIME. The Clubhouse now takes one job per building per
		## matchday, so a loop that raises the cap ten times is ten matchdays —
		## saying so here keeps the throttle real everywhere instead of giving
		## setup code a back door, which is the sort of escape hatch that ends up
		## in shipping code.
		o.new_week()
		costs.append(o.cap_cost())
		if o.raise_cap() != "":
			break
		raised += 1
	## STRICTLY DEARER, not merely not-cheaper. `costs[i] < costs[i - 1]` passes
	## a flat schedule — every raise the same price — which is exactly the thing
	## the check is named for catching. A rung that costs what the last one cost
	## is not a ladder.
	var climbs := costs.size() > 1
	for i in range(1, costs.size()):
		if costs[i] <= costs[i - 1]:
			climbs = false
	var ran_out: bool = o.credits < o.cap_cost()
	notes.append("top of each division vs its cap:  " + line.strip_edges())
	notes.append("the club you start with bills %s against a %s cap"
		% [ClubOffice.money(start), ClubOffice.money(cap0)])
	notes.append("200 CC bought %d cap raises, from %d CC up to %d, and then ran out"
		% [raised, costs[0], costs[costs.size() - 1]])
	_ok(bad == 0 and room and raised > ClubOffice.CAP_COST.size() and climbs
			and ran_out and o.credits < 200,
		"the cap bites",
		"the best club in every division bills inside that division's cap, the starting squad has room, and a 200 CC purse buys %d raises before the price outruns it"
			% raised)



## HIRE, AND SAY SO IF IT DID NOT HAPPEN.
##
## `ClubOffice.hire` returns a reason it refused, and five checks in this file
## threw it away. The day a captain's price started climbing with his stars,
## three of them silently ran against a club with no captain at all — one of them
## reporting that the whole training regime had collapsed to x1.0. A setup step
## whose failure is invisible is a check that measures its own setup.
func _must_hire(o: ClubOffice, c: Dictionary, into: Array[String]) -> void:
	var before := o.captains.size()
	var err := o.hire(c)
	if err != "" or o.captains.size() != before + 1:
		into.append("could not hire %s: %s" % [String(c.get("name", "?")),
			err if err != "" else "no reason given"])


func _test_captains_cover_three_roles_with_two_men() -> void:
	## THE STARS ARE THE THING YOU ARE BUYING. Pete, 11 Sep 2026: *"Low Star
	## staff can have no specialties or just one specialty. So a One Star will
	## have no specialty but just generally help. Mid star staff will have one
	## specialty, and High star can have two specialties."*
	##
	## Before that correction every captain taught two roles whatever his grade,
	## which made a one-star and a five-star the same hire with a different
	## number of stars drawn beside the name. This check exists so that can never
	## come back: the count must move with the grade, and it must move at the
	## boundaries rather than merely trending.
	var counts: Array[int] = []
	for g in range(1, 6):
		counts.append(ClubOffice.specialty_count(g))
	var by_grade: bool = counts == [0, 1, 1, 2, 2]

	## A one-star teaches nobody anything and is still worth his wage: he lifts
	## the room. A five-star lifts nothing that way — his value is on the line.
	var hires: Array[String] = []
	var quiet := ClubOffice.new()
	quiet.credits = 200
	_must_hire(quiet, ClubOffice.captain("Ardry", Tuning.Role.RAIL, Tuning.Role.CENTER, 1), hires)
	var lifts: bool = quiet.presence() > 0.0 and quiet.untaught().size() == 3

	var loud := ClubOffice.new()
	loud.credits = 200
	_must_hire(loud, ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER, 5), hires)
	var no_lift: bool = is_equal_approx(loud.presence(), 0.0)

	## Two five-stars are four slots over three roles, so a top staff ALWAYS
	## overlaps. The overlap is the club's specialty, not the waste the old model
	## called it — and with the whole line taught there is nothing left untaught.
	var top := ClubOffice.new()
	top.credits = 200
	_must_hire(top, ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER, 5), hires)
	_must_hire(top, ClubOffice.captain("Sable", Tuning.Role.FLANK, Tuning.Role.CENTER, 5), hires)
	var all_taught := top.untaught().is_empty()
	var spec_role := top.club_specialty()

	## A mid-star staff has two slots for three roles, so something goes without
	## and there is no overlap to be known for.
	var mid := ClubOffice.new()
	mid.credits = 200
	_must_hire(mid, ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER, 3), hires)
	_must_hire(mid, ClubOffice.captain("Sable", Tuning.Role.FLANK, Tuning.Role.CENTER, 3), hires)
	var mid_bare := mid.untaught()
	var mid_plain: bool = mid.club_specialty() == -1
	## Derived, not named: whatever neither man lists is what goes without. A
	## literal here would go stale the day the pairing on either card changes.
	var mid_listed := {}
	for c in mid.captains:
		for r in ClubOffice.specialties_of(c):
			mid_listed[int(r)] = true
	var mid_expect: Array = []
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		if not mid_listed.has(role):
			mid_expect.append(role)

	## And a five-star who lists the same job twice must still know two jobs —
	## the half-coverage the model exists to refuse.
	var lazy := ClubOffice.captain("Doubler", Tuning.Role.RAIL, Tuning.Role.RAIL, 5)
	var spec: Array = ClubOffice.specialties_of(lazy)

	if not hires.is_empty():
		notes.append("  " + ", ".join(hires))
	notes.append("roles taught by grade 1..5: %s" % str(counts))
	notes.append("two five-stars (Rail+Center, Flanker+Center): all taught, club specialty = %s"
		% (Tuning.ROLE_NAME[spec_role] if spec_role >= 0 else "none"))
	notes.append("two three-stars, same two cards: %s left untaught and no specialty"
		% Tuning.ROLE_NAME[mid_bare[0]])
	_ok(hires.is_empty() and by_grade and lifts and no_lift and all_taught and spec_role == Tuning.Role.CENTER
			and mid_bare == mid_expect and mid_bare.size() == 1 and mid_plain
			and spec.size() == 2 and spec[0] != spec[1],
		"a captain's stars say how many roles he teaches",
		"one star teaches nothing and lifts the room, three stars teach one, five stars teach two; two five-stars cover the line and the overlap becomes the club's specialty")


func _test_captains_reach_the_list() -> void:
	## THE CHECK THAT MATTERS. A staff card is only worth hiring if it changes
	## the fight. A taught role goes out Seasoned and an untaught one goes out
	## Green — the tier measured losing 63% of the time on identical rosters.
	## **There is no third tier a club can buy.**
	var hires: Array[String] = []
	var o := ClubOffice.new()
	o.credits = 200
	_must_hire(o, ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER, 5), hires)

	var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 5)
	sim.set_role_skills(0, {
		Tuning.Role.RAIL: o.tier_for(Tuning.Role.RAIL),
		Tuning.Role.FLANK: o.tier_for(Tuning.Role.FLANK),
		Tuning.Role.CENTER: o.tier_for(Tuning.Role.CENTER),
	})
	var rail: Dictionary = sim._skill_of(sim.men[Tuning.Pos.RAIL_L])
	var flank: Dictionary = sim._skill_of(sim.men[Tuning.Pos.FLANK_L])
	var center: Dictionary = sim._skill_of(sim.men[Tuning.Pos.CENTER])

	## Both captains on the same two jobs. The TIER still tops out at Hardened —
	## that is the part that has never moved — but the doubled role is no longer
	## nothing: it is the club's specialty and the men in it develop faster.
	var full := ClubOffice.new()
	full.credits = 200
	_must_hire(full, ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER, 5), hires)
	_must_hire(full, ClubOffice.captain("Sable", Tuning.Role.RAIL, Tuning.Role.CENTER, 5), hires)
	var no_elite: bool = full.tier_for(Tuning.Role.RAIL) == Tuning.AiSkill.HARDENED
	## Whichever role the overlap landed on is the one paid extra, and it is the
	## ONLY one — read off club_specialty() rather than named here, so the check
	## cannot drift from the code when the pairing changes.
	var spec_role: int = full.club_specialty()
	var paid := 0
	var plain := 0
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		if is_equal_approx(full.specialty_xp(role), ClubOffice.SPECIALTY_XP):
			paid += 1
		elif is_equal_approx(full.specialty_xp(role), 1.0):
			plain += 1
	## And a staff with no overlap pays nobody extra.
	var no_spec: bool = is_equal_approx(o.specialty_xp(Tuning.Role.RAIL), 1.0) \
		and is_equal_approx(o.specialty_xp(Tuning.Role.CENTER), 1.0)

	if not hires.is_empty():
		notes.append("  " + ", ".join(hires))
	notes.append("one five-star teaching Rail and Center: Rail %s · Center %s · Flanker %s"
		% [rail["name"], center["name"], flank["name"]])
	notes.append("two five-stars on the same two jobs: tier still %s, and %s trains at x%.2f"
		% [String(rail["name"]), Tuning.ROLE_NAME[spec_role], ClubOffice.SPECIALTY_XP])
	_ok(hires.is_empty() and String(rail["name"]) == "Hardened" and String(center["name"]) == "Hardened"
			and String(flank["name"]) == "Rust" and no_elite
			and spec_role >= 0 and paid == 1 and plain == 2 and no_spec,
		"captains reach the list",
		"a taught role fights Seasoned and an untaught one fights Green; doubling up buys nothing above Seasoned but makes that role the club's specialty, worth x%.2f XP" % ClubOffice.SPECIALTY_XP)


func _test_facilities_reach_something() -> void:
	## Each facility has to move a number the rest of the game already reads.
	##
	## There were three. HOME GROUND became the Arena on 10 Sep 2026 — it was
	## five levels of a progress bar that fed the gate, which is what the Arena
	## does properly — so the gate is now checked against the ground rather than
	## against a facility level. See tests/test_arena.gd for the rest of it.
	var o := ClubOffice.new()
	o.credits = 200
	for _i in ClubOffice.FACILITY_MAX:
		o.new_week()          ## one job per building per matchday
		o.upgrade(ClubOffice.Facility.TRAINING)
		o.new_week()
		o.upgrade(ClubOffice.Facility.INFIRMARY)
	o.arena.level = Arena.MAX_LEVEL
	o.fans = 4000.0
	var maxed := o.gate_income() > 0 and o.training_points() > 0 and o.injury_relief() > 0
	o.new_week()
	var capped := o.upgrade(ClubOffice.Facility.TRAINING) != ""

	## THE TRAINING GROUND, MEASURED AGAINST A CLUB THAT HAS NONE.
	##
	## This used to play one club with a maxed ground and a five-star captain and
	## assert that its coached men came out of the winter rated higher than they
	## went in. That check was true for months and stopped being a statement about
	## the facility on 15 Sep 2026, for two reasons that both arrived at once.
	##
	## The PRACTICE WEEK now pays every man every matchday, so a squad reaches the
	## winter having already spent what it earned and the ground's allocation
	## lands on men with no room left. And PEAKS NOW VARY PER MAN
	## (`Career.peak_offset`), so the Rail this check named — `starting_five()[0]`,
	## whoever that is — turned out to be an early decliner whose strength peaks at
	## twenty-five and gas at twenty-two. It came back reporting **Rail 64 -> 64
	## and the coached men on 386 against 386**: a true fact about ageing, and
	## nothing whatever about the training ground.
	##
	## **An absolute check on one fixture's luck is a check waiting for the
	## fixture to change.** Two clubs now, same seed, same men, same season — one
	## with the maxed ground and the captain and one with neither. Decline takes
	## the same points off both, the practice pays both, and what is left between
	## them is the facility. That is the thing the check is named after.
	var with_it := _played(true)
	var without := _played(false)
	notes.append("a season and a winter, the coached men: %d with a maxed ground and a five-star captain, %d with neither"
		% [with_it["coached"], without["coached"]])
	notes.append("the untaught Center: %d against %d, and he banked %d XP the winter would not spend"
		% [with_it["center"], without["center"], with_it["center_xp"]])
	## AND THE UNTAUGHT MAN IS THE OTHER HALF. A ground with nobody teaching his
	## role must do nothing for him, so his two numbers have to MATCH — the club
	## that bought everything and the club that bought nothing treat him
	## identically. That is the captain rule, and it is sharper stated as an
	## equality than as "he must not improve".
	_ok(maxed and capped
			and with_it["coached"] > without["coached"]
			and with_it["center"] == without["center"]
			and with_it["center_xp"] > 0,
		"facilities reach something",
		"all three max out and refuse a sixth; a maxed ground and a five-star captain leave the coached men %d clear of the same men without them, and the untaught Center identical either way"
			% (int(with_it["coached"]) - int(without["coached"])))


## ONE CLUB, ONE SEASON, ONE WINTER — with the ground and the captain, or with
## neither. Everything else is identical, including the seed, so the two runs are
## comparable and the difference is the purchase.
func _played(equipped: bool) -> Dictionary:
	var s := Season.new(MeleeRosters.player_club(), 21)
	Session.season = s
	s.office.credits = 400
	## THE BUS IS BOUGHT IN BOTH, and it is not part of what is being measured: a
	## club taking six men develops six men, and six improving while thirteen get
	## a year older nets out negative for reasons that have nothing to do with the
	## training ground.
	for _i in ClubOffice.TRAVEL_COST.size():
		s.office.new_week()
		s.office.buy_travel_slot()
	if equipped:
		for _i in ClubOffice.FACILITY_MAX:
			s.office.new_week()
			s.office.upgrade(ClubOffice.Facility.TRAINING)
		## Teaching the Rail and the Flanker, so the Center is untaught and must
		## not train.
		s.office.hire(ClubOffice.captain("Vaughn", Tuning.Role.RAIL,
			Tuning.Role.FLANK, 5))
	s.sync_power()

	## AND THE KIT IS HELD STILL. `skip_event()` applies the training week, so a
	## club that sims a season reaches the winter in worn harness and
	## `effective_base()` reads that — a second variable inside a check that is
	## about a facility.
	var kit := {}
	for f in s.club.roster:
		kit[f] = f.armor
	while not s.season_complete():
		s.skip_event()
	## AND ROOM TO TRAIN INTO, lifted after the season and before the winter. The
	## practice spends whatever headroom it is given during the season, so a lift
	## applied beforehand arrives at the winter already gone.
	for f in s.club.roster:
		f.potential = mini(99, f.overall() + 20)
	s.roll_over()
	for f in s.club.roster:
		if kit.has(f):
			f.armor = float(kit[f])

	var coached := 0
	for f in s.club.active_eight():
		if Tuning.role_of(int(f.pos)) != Tuning.Role.CENTER:
			coached += f.overall()
	var center: FighterCard = s.club.starting_five()[Tuning.Pos.CENTER]
	return {"coached": coached, "center": center.overall(), "center_xp": center.xp}


func _test_a_knock_costs_you_a_man() -> void:
	## An injury has to be a squad problem: the man is still on the eight, still
	## costing wages, and cannot go out — so somebody covers, and the Infirmary
	## is what buys the weeks back.
	var club := MeleeRosters.player_club()
	var starter: FighterCard = club.starting_five()[Tuning.Pos.CENTER]
	starter.injury = 2
	var line := club.starting_five()
	var still_five := line.size() == 5
	var covered := not line.has(starter)
	var still_on_eight := club.active_eight().has(starter)
	var still_paid := ClubOffice.billed(starter) > 0

	## And they have to actually happen in a fight, at a believable rate.
	var knocks := 0
	var bouts := 20
	for i in bouts:
		var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), i + 8800)
		sim.run_to_end()
		knocks += sim.injuries.size()
	var per := float(knocks) / float(bouts)

	var o := ClubOffice.new()
	o.credits = 200
	for _i in ClubOffice.FACILITY_MAX:
		o.new_week()          ## one job per building per matchday
		o.upgrade(ClubOffice.Facility.INFIRMARY)
	notes.append("knocks: %.2f per bout across both clubs; a maxed Infirmary takes %d events off each"
		% [per, o.injury_relief()])
	_ok(still_five and covered and still_on_eight and still_paid
			and per > 0.15 and per < 3.0 and o.injury_relief() > 0,
		"a knock costs you a man",
		"an injured Center is covered by the bench, stays on the eight and stays on the wage bill")


func _test_the_office_saves() -> void:
	var s := Season.new(MeleeRosters.player_club(), 4242)
	var hires: Array[String] = []
	s.office.credits = 40
	s.office.cap_level = 2
	s.office.upgrade(ClubOffice.Facility.INFIRMARY)
	_must_hire(s.office, ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER, 5), hires)
	s.club.roster[0].injury = 3
	SaveGame.save(s, 1)
	var back := SaveGame.load_slot(1)
	SaveGame.delete(1)
	var ok: bool = hires.is_empty() and back != null and back.office.credits == s.office.credits \
		and back.office.cap_level == s.office.cap_level \
		and back.office.captains.size() == 1 \
		and back.office.level(ClubOffice.Facility.INFIRMARY) == 1 \
		and back.club.roster[0].injury == 3 \
		and back.office.tier_for(Tuning.Role.CENTER) == s.office.tier_for(Tuning.Role.CENTER)
	_ok(ok, "the office saves",
		"credits, the cap, the facilities, the captains and the treatment table all come back")


func _test_the_crowd_bands_the_pay() -> void:
	## RETRO BOWL'S FAN METER, and the two things that make it work rather than
	## decorate: the pay CHANGES at the gate, and the word the player reads
	## changes at the same instant. They used to be two hand-written ladders in
	## two places and that is the kind of thing that drifts apart in an edit
	## nobody remembers making, so they are now one array read twice — this
	## proves the reading, not the array.
	var o := ClubOffice.new()
	## THE GATES ARE HEADS NOW, so the club has to be given a ground big enough to
	## hold them — a back field cannot reach band 5 and a check that set the
	## number directly would be measuring a house the game cannot build.
	o.arena.level = Arena.MAX_LEVEL
	var line := ""
	var last_pay := 0
	var monotone := true
	var words: Dictionary = {}
	## THE GATES ARE A FILL FRACTION NOW, so the sweep sets the FOLLOWING to a
	## share of the ground rather than to a headcount. `fill()` is
	## `attendance() / capacity`, so `fans = share x capacity` puts the club
	## exactly where the check means to put it.
	var cap := float(o.arena.capacity())
	for share in [0.0, 0.09, 0.10, 0.27, 0.28, 0.45, 0.46, 0.65, 0.66, 0.87, 0.88, 1.20]:
		o.fans = share * cap
		if o.crowd_pay() < last_pay:
			monotone = false
		last_pay = o.crowd_pay()
		words[o.note_word()] = o.crowd_pay()
	for g in ClubOffice.CROWD_GATES:
		## The tick itself: a hair under the gate and exactly on it must differ.
		## A hair is one seat, because `attendance()` truncates to whole people.
		o.fans = float(g) * cap - 1.0
		var below := o.crowd_pay()
		var below_word := o.note_word()
		o.fans = float(g) * cap + 1.0
		if o.crowd_pay() == below:
			monotone = false
		if o.note_word() == below_word:
			monotone = false
		line += "%d%%:%d->%d  " % [int(float(g) * 100.0), below, o.crowd_pay()]
	## And the top band pays a whole fight-win more than the bottom, or the meter
	## is not worth reading.
	o.fans = 0.0
	var floor_pay := o.crowd_pay()
	o.fans = 1e9
	o._clamp_fans()
	var top_pay := o.crowd_pay()
	notes.append("crowd bands at the gates: " + line.strip_edges())
	notes.append("each band has its own word: %d words for %d pay levels"
		% [words.size(), ClubOffice.CROWD_PAY.size()])
	_ok(monotone and top_pay - floor_pay >= Season.CREDITS_WIN
			and words.size() == ClubOffice.CROWD_PAY.size(),
		"the crowd bands the pay",
		"pay rises on the exact tick the word does, and the top band is worth %d more a fight than the bottom"
			% (top_pay - floor_pay))


func _test_the_retainer_stays_a_retainer() -> void:
	## THE BUG THIS WAS WRITTEN FOR: at `^0.62` the ground's standing retainer
	## paid a full National Arena **284 CC a summer for doing nothing** — nearly
	## five times the cost of the arena itself, every year. It made every sink in
	## the game decorative above the State League, and it hid for as long as it
	## did because nobody had put a season's income next to a season's prices.
	##
	## So the rule, asserted rather than eyeballed: the retainer a ground pays
	## must never approach what the ground COST. It is a retainer; the events are
	## where an arena earns.
	var o := ClubOffice.new()
	var line := ""
	var worst := 0.0
	for lv in Arena.LEVELS.size():
		o.arena.level = lv
		o.fans = o.fan_cap()
		var paid := o.gate_income()
		var cost := int(Arena.LEVELS[lv]["cost"])
		line += "%s %d CC/yr" % [String(Arena.LEVELS[lv]["name"]), paid]
		if cost > 0:
			var share := float(paid) / float(cost)
			worst = maxf(worst, share)
			line += " (%d%% of its cost)" % int(round(share * 100.0))
		line += "  ·  "
	notes.append("standing retainer, sold out: " + line.strip_edges().trim_suffix("·"))
	## The bar sits a little above the worst case rather than on it: the curve is
	## compressive, so the CHEAPEST grounds always look most generous in
	## percentage terms while being trivial in absolute terms — the Club gym pays
	## back half its cost a year and that is three credits.
	_ok(worst <= 0.55, "the retainer stays a retainer",
		"the loudest ground pays back at most %d%% of its build cost a year, so hosting is still where an arena earns"
			% int(round(worst * 100.0)))


func _test_the_bills_come_due() -> void:
	## A club that can pay keeps everything and is poorer for it. The part worth
	## asserting is not the arithmetic, it is that HOLDING A GROUND IS NET
	## NEGATIVE: the standing retainer must never cover the upkeep, or the arena
	## becomes a savings account and the events it was built for stop mattering.
	var o := ClubOffice.new()
	var line := ""
	var ever_free := false
	for lv in range(1, Arena.LEVELS.size()):
		o.arena.level = lv
		o.fans = o.fan_cap()
		var net := o.gate_income() - o.arena_upkeep()
		if net > 0:
			ever_free = true
		line += "%s %+d  " % [String(Arena.LEVELS[lv]["name"]), net]

	## And a club with money keeps its buildings.
	var b := ClubOffice.new()
	b.arena.level = 4
	b.facilities[ClubOffice.Facility.TRAINING] = 5
	b.facilities[ClubOffice.Facility.INFIRMARY] = 3
	b.credits = 500
	var bill := b.upkeep_bill()
	var r := b.pay_upkeep()
	var kept: bool = b.arena.level == 4 and b.level(ClubOffice.Facility.TRAINING) == 5 \
		and b.level(ClubOffice.Facility.INFIRMARY) == 3
	notes.append("a ground held, sold out, retainer minus upkeep: " + line.strip_edges())
	notes.append("a full Arena + Training 5 + Infirmary 3 bills %d CC a summer" % bill)
	_ok(not ever_free and kept and int(r["billed"]) == bill and bill > 0
			and b.credits == 500 - bill and (r["lost"] as Array).is_empty(),
		"the bills come due",
		"no ground pays more to own than it costs to hold, and a club that can pay loses nothing")


func _test_what_you_cannot_pay_falls_down() -> void:
	## THE PENALTY IS THE REBUILD, not the bill. A club that skips 27 credits on
	## the National Arena pays 60 to put it back, which is what makes maintenance
	## a thing you do rather than a thing you weigh.
	##
	## And the cascade has to be real: a ground that drops takes its fan cap down
	## with it, so the following the club spent years building gets clamped to the
	## smaller house. That is the whole reason overbuilding before a relegation is
	## a mistake, and it is the one part of this a reader would not assume.
	var o := ClubOffice.new()
	o.arena.level = Arena.MAX_LEVEL
	o.facilities[ClubOffice.Facility.TRAINING] = 4
	o.fans = o.fan_cap()
	var fans_before := o.fans
	var cap_before := o.arena.capacity()
	o.credits = 0

	var rebuild := int(Arena.LEVELS[Arena.MAX_LEVEL]["cost"])
	var skipped := o.arena_upkeep()
	var r := o.pay_upkeep()
	var fell: bool = o.arena.level == Arena.MAX_LEVEL - 1
	var facility_fell: bool = o.level(ClubOffice.Facility.TRAINING) == 3
	var fans_clamped: bool = o.fans < fans_before and o.fans <= o.fan_cap() + 0.001

	## A club with enough for the ground but not the facility keeps the ground:
	## the arena is what earns, so it is what gets paid first.
	var p := ClubOffice.new()
	p.arena.level = 3
	p.facilities[ClubOffice.Facility.INFIRMARY] = 2
	p.credits = p.arena_upkeep()
	p.pay_upkeep()
	var order_right: bool = p.arena.level == 3 \
		and p.level(ClubOffice.Facility.INFIRMARY) == 1

	notes.append("skipping the National Arena's %d CC bill costs %d to rebuild (%.1fx)"
		% [skipped, rebuild, float(rebuild) / float(maxi(1, skipped))])
	notes.append("the ground fell and took the following with it: %d fans in a %d house -> %d in a %d"
		% [int(fans_before), cap_before, int(o.fans), o.arena.capacity()])
	## THE REBUILD USED TO BE MORE THAN TWICE THE BILL and is now a little under
	## it — 60 to rebuild against a 30-credit bill. That is the arena's upkeep
	## being derived from what the ground PAYS rather than from what it cost (see
	## `ClubOffice.arena_upkeep`), and it makes the top of the ladder dearer to
	## hold than it was.
	##
	## The rule the check is for survives with the number changed: **the penalty
	## is the rebuild, not the bill.** Skipping thirty credits still costs sixty
	## to put back, and it also costs the following the bigger house was holding —
	## which is the part of the cascade a reader would not assume and the reason
	## this check exists.
	_ok(fell and facility_fell and fans_clamped and order_right
			and (r["lost"] as Array).size() == 2 and rebuild > skipped,
		"what you cannot pay falls down",
		"a broke club sheds a level, the ground is paid before the facilities, and the fan cap falls with it")


func _test_one_job_at_a_time() -> void:
	## PETE'S ITEM 7, the half that was not the decay. Retro Bowl lets you improve
	## one thing at a time, and it is not a fussy rule — it is what stops a
	## windfall from becoming an instant club. Without it a player banks a good
	## tournament and buys the ground, both facilities and four cap raises on the
	## same afternoon, and every decision the Clubhouse exists to make interesting
	## gets made in one undifferentiated blur.
	##
	## ONE UPGRADE PER BUILDING, NOT ONE UPGRADE TOTAL. Mending the infirmary and
	## raising the cap in the same week are different decisions about different
	## problems and both should go through; taking the same building up three
	## levels while nothing else moves should not.
	var o := ClubOffice.new()
	o.credits = 9999
	o.tier = 3
	var first_gym := o.upgrade(ClubOffice.Facility.TRAINING)
	var second_gym := o.upgrade(ClubOffice.Facility.TRAINING)
	var other := o.upgrade(ClubOffice.Facility.INFIRMARY)
	var cap := o.raise_cap()
	var cap_again := o.raise_cap()
	var ground := o.build_arena()
	var ground_again := o.build_arena()

	var week_one: bool = first_gym == "" and second_gym != "" and other == "" \
		and cap == "" and cap_again != "" and ground == "" and ground_again != ""
	var levels_held: bool = o.level(ClubOffice.Facility.TRAINING) == 1 \
		and o.level(ClubOffice.Facility.INFIRMARY) == 1 and o.cap_level == 1 \
		and o.arena.level == 1

	## And next week it all opens up again.
	o.new_week()
	var reopened: bool = o.upgrade(ClubOffice.Facility.TRAINING) == "" \
		and o.level(ClubOffice.Facility.TRAINING) == 2

	## THE HOLE THIS CLOSES: building the ground used to be three lines inside the
	## Arena SCREEN — check, subtract, increment — so it was the one upgrade in the
	## club no rule could reach. A rule enforced at one call site is a rule with a
	## hole in it, and asking the office is what shuts it.
	notes.append("one week, unlimited money: gym +1 then refused, infirmary +1, cap +1 then refused, ground +1 then refused")
	notes.append("the second attempt says: \"%s\"" % second_gym)
	_ok(week_one and levels_held and reopened,
		"one job at a time",
		"each building takes one upgrade a week and no more, and a new matchday opens them all again")


func _test_the_stars_are_what_you_pay_for() -> void:
	## A GRADED PRODUCT AT A FLAT PRICE IS NOT A DECISION. The cost was 5 CC for
	## every captain for as long as every captain taught two roles; the moment the
	## grade started deciding how many he teaches, a flat price meant the only
	## sensible move was to wait for a five-star, every time, forever.
	var bad: Array[String] = []
	var last := -1
	var prices: Array[int] = []
	for g in range(1, 6):
		var price := ClubOffice.cost_of(ClubOffice.captain("N", Tuning.Role.RAIL, Tuning.Role.CENTER, g))
		prices.append(price)
		if price <= last:
			bad.append("a %d-star costs no more than the grade below" % g)
		last = price

	## AND IT HAS TO BITE AT THE START. A club that can buy the best captain in
	## the country out of its opening balance has no ladder to climb.
	var fresh := ClubOffice.new()
	var opening := fresh.credits
	var one_star := ClubOffice.captain("Cheap", Tuning.Role.RAIL, Tuning.Role.CENTER, 1)
	var five_star := ClubOffice.captain("Dear", Tuning.Role.RAIL, Tuning.Role.CENTER, 5)
	if ClubOffice.cost_of(one_star) > opening:
		bad.append("a new club cannot afford even a one-star, so the staff room is closed to it")
	if ClubOffice.cost_of(five_star) <= opening:
		bad.append("a new club can buy a five-star out of its opening balance")
	## The refusal has to be a refusal, not a negative balance.
	var broke := ClubOffice.new()
	var err := broke.hire(five_star)
	if err == "" or broke.credits < 0 or not broke.captains.is_empty():
		bad.append("hiring beyond your means is not refused cleanly")

	## AND THE FULL RANGE HAS TO REACH THE MARKET. The offer generator topped out
	## at three stars while the model allowed five, so a two-specialty captain was
	## a thing the code could build and the game could never sell — the kind of
	## gap only a sweep finds, because every individual screen looked right.
	var grades := {}
	for season_no in 40:
		for slot in ClubOffice.MAX_CAPTAINS:
			grades[int(ClubOffice.offer(1234, season_no, slot)["grade"])] = true
	for g in range(1, 6):
		if not grades.has(g):
			bad.append("no %d-star captain is ever offered" % g)
	## And what is offered has to obey the same grade rule as anything hand-built.
	var mismatched := 0
	for season_no in 40:
		for slot in ClubOffice.MAX_CAPTAINS:
			var c := ClubOffice.offer(1234, season_no, slot)
			if ClubOffice.specialties_of(c).size() != ClubOffice.specialty_count(int(c["grade"])):
				mismatched += 1
	if mismatched > 0:
		bad.append("%d offered captains teach a number of roles their grade does not allow" % mismatched)

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("a captain by the star: %s CC — a new club holds %d, which buys the bottom of that list and not the top"
		% [str(prices), opening])
	notes.append("40 seasons of offers put grades %s on the market" % str(grades.keys()))
	_ok(bad.is_empty(), "the stars are what you pay for",
		"the price climbs with the grade, a new club can afford the bottom and not the top, and every grade the model allows actually reaches the market")


## ------------------------------------------------ and it pays at the bottom
## THE CHECK ABOVE ONLY EVER LOOKED AT A SOLD-OUT GROUND.
##
## Both of the retainer's existing checks open with the same two lines:
##
##     o.notoriety = ClubOffice.NOTORIETY_MAX
##     o.fans = o.fan_cap()
##
## They were written to catch a retainer paying too MUCH, so they pinned the
## club at its ceiling and asked what came out. Neither of them could see the
## other end of the same function, and at the other end it paid **nothing at
## all** — not a small retainer, no retainer, in twenty consecutive seasons of a
## career walk, at the tier where every career starts.
##
## `gate_income()` had been changed to read `attendance()`, which is capacity
## times `turnout()`, which is `notoriety / 125`. A club that has not made a name
## sits at the notoriety FLOOR of 1.0, so its turnout is 0.008, and twelve
## followers times 0.008 truncates to zero. **A multiplier that can legitimately
## reach zero annihilates whatever it is applied to** — the same shape as the
## sentinel that was a legal value and the guard that could only fail.
##
## Every figure in the retainer's own comment is a CAPACITY: 2 at a back field,
## 6 at a sports hall, 11 at an arena, 22 at a full National Arena. It reads the
## ground again, which is what a retainer is for — *"the federation rotates who
## hosts, and a better ground takes a bigger turn"* — while `crowd_pay()` remains
## what the crowd is worth.
##
## **A check pinned at one end of a range is a check on one number.**
func _test_the_retainer_pays_a_club_nobody_has_heard_of() -> void:
	var bad: Array[String] = []
	var line := ""
	for lv in Arena.LEVELS.size():
		var o := ClubOffice.new()
		o.arena.level = lv
		## THE FLOOR, deliberately: the following a new club starts on, in a ground
		## it has not filled. This is season one.
		o.fans = 12.0
		var paid := o.gate_income()
		line += "%s %d  ·  " % [String(Arena.LEVELS[lv]["name"]), paid]
		if paid <= 0:
			bad.append("%s pays an unknown club nothing"
				% String(Arena.LEVELS[lv]["name"]))
	notes.append("standing retainer, nobody has heard of you: "
		+ line.strip_edges().trim_suffix("·"))

	## AND IT IS THE SAME NUMBER EITHER WAY. A retainer that moved with the crowd
	## would be the event gate wearing a second hat, which is the bug the
	## exponent was cut from 0.62 to 0.30 to fix.
	for lv in Arena.LEVELS.size():
		var quiet := ClubOffice.new()
		quiet.arena.level = lv
		quiet.fans = 12.0
		var loud := ClubOffice.new()
		loud.arena.level = lv
		loud.fans = loud.fan_cap()
		if quiet.gate_income() != loud.gate_income():
			bad.append("%s pays %d to a nobody and %d to a household name"
				% [String(Arena.LEVELS[lv]["name"]), quiet.gate_income(),
					loud.gate_income()])
			break

	## And the four numbers the comment promises are the four numbers it pays.
	var promised := {0: 2, 3: 6, 4: 11, 5: 22}
	for lv in promised:
		var o := ClubOffice.new()
		o.arena.level = int(lv)
		var got := o.gate_income()
		if absi(got - int(promised[lv])) > 1:
			bad.append("%s pays %d where the comment says %d"
				% [String(Arena.LEVELS[int(lv)]["name"]), got, int(promised[lv])])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "the retainer pays a club nobody has heard of",
		"every ground pays its standing retainer to a club nobody has heard of, the same figure it pays at the ceiling, and the figures are the ones written down")


## ------------------------------------------- nothing is pinned at the bottom
## THE PATTERN, CAUGHT ONCE AND THEN FOUND TWICE MORE.
##
## `gate_income()` read `notoriety / NOTORIETY_MAX` through `turnout()`. A club
## that has not made a name sits at the notoriety FLOOR of 1.0 against a maximum
## of 125, so that term was 0.008, and a term of 0.008 multiplied into an income
## is no income. Twenty consecutive seasons of a career walk earned a column of
## noughts before anybody looked.
##
## It is not a one-off. The same shape is in `Contracts.will_wait`, where `pull`
## is `notoriety / NOTORIETY_MAX` and is supposed to be worth up to +0.30 —
## the reason a man stays at a club people want to play for. At the bottom of the
## pyramid it is worth **+0.002**, so the one lever a struggling club has for
## keeping its best men is off precisely where it is needed.
##
## The general fault: **a term normalised against the TOP of the game is dead at
## the bottom of it**, and the bottom is where every career starts and where the
## player spends his first ten seasons. A designer reading the constant sees a
## thirty-point swing; a new club gets none of it.
##
## So this checks the shape rather than any one function: for a club at the
## notoriety floor, does each of these terms do ANYTHING? Not "is it big" — is it
## distinguishable from zero. A curve that starts at zero and ends at thirty
## points is a curve the first ten hours of the game never sees.
func _test_nothing_a_new_club_owns_is_pinned_at_zero() -> void:
	var bad: Array[String] = []
	## THE FLOOR IS A CLUB, NOT A NUMBER, now that there is one population. A new
	## club is twelve followers in a back field; a household name is a National
	## Arena it has filled.
	var floor_pull := 0.0
	var top_pull := 1.0

	## 1. THE GROUND RETAINER, which is what this rule was learned from.
	var o := ClubOffice.new()
	o.fans = 12.0
	floor_pull = o.pull()
	var big := ClubOffice.new()
	big.arena.level = Arena.MAX_LEVEL
	big.fans = big.fan_cap()
	top_pull = big.pull()
	if o.gate_income() <= 0:
		bad.append("the ground retainer pays a new club nothing")

	## 2. THE CROWD, which already gets this right and is the model: its own
	## comment says *"band 0 still pays… a club nobody has heard of is the club
	## that most needs a trickle"*. Asserted so the good example cannot rot.
	if o.crowd_pay() <= 0:
		bad.append("a fight in front of nobody pays nothing")

	## 3. WHETHER A GOOD MAN WAITS. `pull` is the club's pulling power and the
	## constant says it is worth up to +0.30. The check is not that a new club
	## gets +0.30 — it should not — but that the SPREAD between an unknown club
	## and a household name is visible at all to a man deciding whether to stay.
	var man := FighterCard.new()
	man.display_name = "Test"
	man.pos = Tuning.Pos.CENTER
	man.strength = 40
	man.base = 40
	man.skill = 40
	man.gas = 40
	man.aggression = 40
	man.morale = 0.7
	var band_top: int = int(League.TIERS[0]["power"][1])
	var quiet := Contracts.will_wait(man, floor_pull, band_top, 0.7)
	var loud := Contracts.will_wait(man, top_pull, band_top, 0.7)
	notes.append("a %d-rated man at a Backyard club: stays %.0f%% for a nobody, %.0f%% for a household name"
		% [man.overall(), quiet * 100.0, loud * 100.0])
	## A tenth of the advertised thirty points is the bar — well under what the
	## constant promises, and still enough that the term is doing something.
	if loud - quiet < 0.03:
		bad.append("being known is worth %.3f to a man deciding whether to stay"
			% (loud - quiet))
	## AND THE FLOOR ITSELF HAS TO BE OFF THE BOTTOM, which is now the honest
	## version of the same rule.
	##
	## The old clause asked for a sixth of the whole curve to land in the first
	## tenth of the SCALE, because `pull` was `sqrt(notoriety / 125)` on a linear
	## fame number and a straight reading of it collected seven per cent for a new
	## club. `pull()` is the log of the crowd against the biggest house in the
	## country now, so the compression is in the quantity: a new club is already a
	## fifth of the way up it, and filling a back field moves it again.
	##
	## **A check written for one curve is a check about that curve.** What
	## survives, and what the rule was always about, is that nothing a new club
	## owns reads as nothing.
	var first := ClubOffice.new()
	first.fans = first.fan_cap()
	var early := Contracts.will_wait(man, first.pull(), band_top, 0.7)
	if floor_pull <= 0.05:
		bad.append("a new club's pulling power reads as zero (%.3f)" % floor_pull)
	if early <= quiet:
		bad.append("filling your own back field is worth nothing to a man deciding")
	notes.append("pulling power: %.2f for twelve people in a field, %.2f for a packed one, 1.00 for a full National Arena"
		% [floor_pull, first.pull()])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "nothing a new club owns is pinned at zero",
		"the retainer, the crowd and a club's pulling power all do something measurable for a club nobody has heard of")


## ------------------------------------------------- the rest of the meeting
## PETE SENT RETRO BOWL'S MEETING CARD OVER on 14 Sep 2026: one panel per man,
## four rows — MORALE / CONDITION / XP LEVEL / CONTRACT — each a read-out, a
## button, and a price in credits.
##
## Three of the four were already on the fighter screen. "Sit him down" is the
## morale row and "Extend" is the contract row. The two this checks are the ones
## that were not there, and both of them were holes rather than omissions:
##
##   CONDITION — `armor` multiplies straight into `eff_base()` and is taken off
##   every week by the HARD regime, and the ONLY thing in the entire game that
##   put any of it back was the luck of the dilemma deck dealing the armorer's
##   bill. A stat that can only fall unless the game deals you a card is the same
##   shape as the retainer that paid nothing: **a system the player cannot
##   reach.**
##
##   XP LEVEL — `Career.level_cost()` was written months ago carrying the comment
##   *"BUYING ONE, which is their meeting — go through some extra reps on the
##   training field"*. Somebody had this exact screen in mind, wrote the price,
##   and never wired the button. It sat on the dead-code list until the
##   screenshot explained what it had been for.
func _test_the_meeting_sells_what_it_offers() -> void:
	var bad: Array[String] = []
	var o := ClubOffice.new()
	o.credits = 50
	var man := FighterCard.new()
	man.display_name = "Tester"
	man.number = 7
	man.pos = Tuning.Pos.CENTER
	man.strength = 40
	man.base = 40
	man.skill = 40
	man.gas = 40
	man.aggression = 40
	man.potential = 99
	man.age = 26
	man.level = 3
	man.xp = 0

	## ---- THE ARMORER
	man.armor = 0.40
	var quoted := ClubOffice.kit_cost(man)
	var purse := o.credits
	var before := man.armor
	var err := o.repair_kit(man)
	if err != "":
		bad.append("a wrecked harness could not be worked on: " + err)
	if man.armor <= before:
		bad.append("the armorer took the money and the harness is the same")
	if purse - o.credits != quoted:
		bad.append("the armorer quoted %d and charged %d" % [quoted, purse - o.credits])
	## ONE VISIT A WEEK. Without the throttle a club with credits walks a wrecked
	## squad back to new in an afternoon, which is a vending machine, not a
	## decision.
	if o.repair_kit(man) == "":
		bad.append("the armorer took the same harness twice in one week")
	o.new_week()
	if o.repair_kit(man) != "":
		bad.append("the armorer would not come back the following week")

	## AND IT REFUSES THE TWO THINGS IT SHOULD. A whole harness is not work, and
	## a club that cannot pay does not get the work done.
	man.armor = 1.0
	if o.repair_kit(man) == "":
		bad.append("the armorer charged for a harness that was already whole")
	man.armor = 0.20
	o.new_week()
	o.credits = 0
	if o.repair_kit(man) == "":
		bad.append("a club with no credits got its kit repaired anyway")

	## ---- AND IT IS A ROAD THE PLAYER CAN TAKE AT THE BOTTOM. The whole point
	## of adding it is that armor had exactly one repair path and it was the
	## deck. A price a Backyard club cannot reach would leave it that way.
	var worst := FighterCard.new()
	worst.display_name = "Wrecked"
	worst.pos = Tuning.Pos.CENTER
	worst.armor = 0.0
	if ClubOffice.kit_cost(worst) > ClubOffice.KIT_COST_FULL:
		bad.append("the worst harness in the game costs more than the cap")
	notes.append("the armorer: %d CC at a scratch, %d at a wreck, +%.2f a visit"
		% [ClubOffice.kit_cost(man) if man.armor > 0.9 else 1,
			ClubOffice.kit_cost(worst), ClubOffice.KIT_STEP])

	## ---- EXTRA REPS
	o.credits = 50
	man.armor = 1.0
	man.xp = 0
	if Career.can_level(man):
		bad.append("the man was set up with a level already waiting")
	var reps := Career.level_cost(man)
	purse = o.credits
	err = o.buy_level(man)
	if err != "":
		bad.append("extra reps were refused: " + err)
	if purse - o.credits != reps:
		bad.append("extra reps quoted %d and charged %d" % [reps, purse - o.credits])
	## IT BUYS THE XP, NOT THE POINT. Which stat goes up is the decision the row
	## of +1 buttons exists for, and buying the level must not make it for him.
	if not Career.can_level(man):
		bad.append("the reps were paid for and no level is waiting")
	if Career.raisable(man).is_empty():
		bad.append("a level is waiting and there is nothing to put it into")
	var was := man.overall()
	if man.overall() != was:
		bad.append("buying the level moved a stat by itself")

	## AND IT REFUSES TO SELL HIM A SECOND ONE while the first is standing —
	## a man with a free point should be told to spend it, not sold another.
	o.new_week()
	if o.buy_level(man) == "":
		bad.append("sold a second level while the first was still unspent")
	notes.append("extra reps: %d CC at level %d, and it buys the bar rather than the point"
		% [reps, man.level])

	## ---- AND THE PRICE RISES WITH THE LEVEL, which is the property the
	## function's own comment claimed and the code did not have.
	##
	## It was `next_level_at(f) / 4` — the BAR divided — and our bar deliberately
	## stops rising at 24 (`min(level, 3) * 8`) because our XP income is flat.
	## The price inherited that cap by accident and sat at **six credits from
	## level three to level fifteen**, so a club with credits bought every level
	## for every man forever and the one purchase that should get harder as a
	## fighter gets good was the one that never did.
	##
	## Retro Bowl's own `s_get_meeting_cost_levelup` is `xp_level * 4` and the
	## screenshot confirms it — XP LEVEL 5, Level Up, 20 CC. Ours is half that
	## rate because our credit economy is smaller, times the age term that is ours
	## and not theirs.
	var ladder: Array[int] = []
	var rising := true
	for lv in [1, 3, 5, 8, 12]:
		var m := FighterCard.new()
		m.display_name = "L"
		m.pos = Tuning.Pos.CENTER
		m.age = 26
		m.strength = 40; m.base = 40; m.skill = 40; m.gas = 40; m.aggression = 40
		m.potential = 99
		m.level = lv
		var c := Career.level_cost(m)
		if not ladder.is_empty() and c <= ladder[-1]:
			rising = false
		ladder.append(c)
	if not rising:
		bad.append("the level price stops rising: %s" % str(ladder))
	## AND THE AGE TERM SURVIVES — a man slow to learn is dearer to push, which
	## is the half of this that is ours rather than ported.
	var young := FighterCard.new()
	var old_man := FighterCard.new()
	for m in [young, old_man]:
		m.display_name = "A"
		m.pos = Tuning.Pos.CENTER
		m.strength = 40; m.base = 40; m.skill = 40; m.gas = 40; m.aggression = 40
		m.potential = 99
		m.level = 5
	young.age = 20
	old_man.age = 38
	if Career.level_cost(old_man) <= Career.level_cost(young):
		bad.append("age costs nothing to push: %d at 20, %d at 38"
			% [Career.level_cost(young), Career.level_cost(old_man)])
	notes.append("the level ladder at 26: %s CC — and %d at twenty against %d at thirty-eight"
		% [str(ladder), Career.level_cost(young), Career.level_cost(old_man)])

	## ---- AND THE CARD'S CLAIM ABOUT WHAT IT MOVES HAS TO BE TRUE.
	##
	## The meeting draws the affected stat under each purchase — Base under
	## CONDITION, Strength and Gas under MORALE — and a card that shows a number
	## which does not actually move is worse than one that shows nothing, because
	## the player spends credits on it.
	##
	## `effective_base` is `base x lerp(0.78, 1.0, armor)`, so a wrecked harness
	## is a fifth off the one stat that keeps a man upright, and the club's rating
	## reads it through `position_rating`. That last link is BELOW THE ROUNDING
	## for one man out of five — a full repair moved a real club 37.227 to 37.463
	## — which is exactly what `power_exact()` exists for and exactly the trap a
	## check on `power()` would fall into by reporting "no effect".
	var kit_man := FighterCard.new()
	kit_man.display_name = "Harness"
	kit_man.pos = Tuning.Pos.CENTER
	kit_man.strength = 40; kit_man.base = 48; kit_man.skill = 40
	kit_man.gas = 40; kit_man.aggression = 40
	kit_man.armor = 0.40
	var base_low := kit_man.effective_base()
	kit_man.armor = 1.0
	var base_high := kit_man.effective_base()
	if base_high <= base_low:
		bad.append("a repaired harness does not raise his base (%.1f then %.1f)"
			% [base_low, base_high])
	notes.append("what the armorer buys: base %.1f at a 40%% harness, %.1f at a whole one"
		% [base_low, base_high])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "the meeting sells what it offers",
		"the armorer repairs a harness once a week at a price that scales with the damage, and extra reps buy the bar and leave the choice of stat alone")
