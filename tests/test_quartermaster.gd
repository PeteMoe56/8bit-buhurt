extends SceneTree
## THE HARNESS, AND WHAT IT IS ACTUALLY WORTH.
##
##   godot --headless --path . --script res://tests/test_quartermaster.gd
##
## Pete, 15 Sep 2026, choosing a direction for the Market: the quartermaster.
##
## Most of the mechanic was already in the game and had no screen — `armor`
## decays, multiplies base and gates inspection, and Direction §4 calls it the
## cap. What was missing was a grade of harness to buy, and an honest account of
## what any of it is worth. These checks hold both, and the second one matters
## more: **a shop that sells a number the game does not read is a shop that takes
## credits and gives nothing.**

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the quartermaster ===\n")
	_test_the_ladder_goes_up()
	_test_a_grade_caps_what_a_repair_can_reach()
	_test_better_kit_wears_slower()
	_test_buying_a_harness_hands_over_a_fresh_one()
	_test_the_armorer_makes_what_he_can()
	_test_the_ledger_is_the_squad()
	_test_what_armor_is_actually_worth()
	_test_a_simmed_event_costs_a_week()
	_test_sponsors_pay_for_kit_that_fights()
	_test_better_metal_lifts_the_fight_not_the_ceiling()
	_test_a_league_bout_pays_and_wears_who_fought()
	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE QUARTERMASTER HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


func _man() -> FighterCard:
	return MeleeRosters.starting_club().roster[0]


func _test_the_ladder_goes_up() -> void:
	var line: Array[String] = []
	var bad: Array[String] = []
	var grades := [Quartermaster.Grade.BORROWED, Quartermaster.Grade.SERVICEABLE,
		Quartermaster.Grade.FITTED, Quartermaster.Grade.TOURNAMENT]
	for i in grades.size():
		var g: int = grades[i]
		line.append("%s top %.2f wear x%.2f" % [Quartermaster.GRADE_NAME[g],
			Quartermaster.TOP[g], Quartermaster.WEAR[g]])
		if i == 0:
			continue
		var p: int = grades[i - 1]
		## EVERY RUNG IS BETTER ON BOTH AXES, or it is not a rung — a grade that
		## lasts longer but caps lower is a decision with a trick in it.
		if float(Quartermaster.TOP[g]) < float(Quartermaster.TOP[p]):
			bad.append("%s caps lower than %s" % [Quartermaster.GRADE_NAME[g],
				Quartermaster.GRADE_NAME[p]])
		if float(Quartermaster.WEAR[g]) >= float(Quartermaster.WEAR[p]):
			bad.append("%s wears no slower than %s" % [Quartermaster.GRADE_NAME[g],
				Quartermaster.GRADE_NAME[p]])
	_ok(bad.is_empty(), "every rung is better than the one below it, on both axes",
		"; ".join(line) if bad.is_empty() else "; ".join(bad))

	## AND NOBODY STARTS IN DANGER. Borrowed kit is never quite right; it is not
	## a club one bad week from being unable to field five.
	_ok(float(Quartermaster.TOP[Quartermaster.Grade.BORROWED])
		> FighterCard.INSPECTION_MIN + 0.3,
		"and the bottom rung is not a club in trouble",
		"borrowed caps at %.2f against an inspection line of %.2f"
			% [Quartermaster.TOP[Quartermaster.Grade.BORROWED], FighterCard.INSPECTION_MIN])

	## AND THE BOTTOM RUNG IS NOT MUCH OF A NERF.
	##
	## This said "nothing may wear faster than 1.00" until Pete ruled, 8 Oct 2026
	## (Harness #2): *"lower gear breaking quicker, and higher gear more
	## resilient."* Rust now wears a shade over the old game. The point of the old
	## rule still stands — a shop must not make the baseline a tax — so the line
	## holds at 1.10, and docs/harness-2 measured the club that never buys at
	## 0.00 seasons slower to its first title.
	var worst := 0.0
	for g in Quartermaster.WEAR.keys():
		worst = maxf(worst, float(Quartermaster.WEAR[g]))
	_ok(worst <= 1.10, "and no rung wears much faster than the game did before the shop",
		"the worst multiplier on the ladder is x%.2f" % worst)
	notes.append("the ladder: " + "; ".join(line))


func _test_a_grade_caps_what_a_repair_can_reach() -> void:
	var o := ClubOffice.new()
	o.credits = 500
	var f := _man()
	f.harness = Quartermaster.Grade.BORROWED
	f.armor = 0.40
	## TWENTY VISITS, each a separate week, so the throttle is not what stops it.
	for i in 20:
		o.repair_kit(f)
		o.new_week()
	## THE CAP IS A CEILING HE NEVER PASSES AND STOPS SHORT OF, and the second
	## half of that is new on 15 Sep 2026.
	##
	## `topped_out()` used a tolerance of 0.001 — any scratch at all was work the
	## armorer would take — and `kit_cost()` has a floor of one credit, so a club
	## of thirteen paid a standing charge every season for polishing things that
	## did not need polishing. `tools/probe_year1.gd` put the whole of a first
	## season's maintenance against an income of 17.8 CC. The tolerance is now
	## `WORTH_DOING`, about one hard week, and this check asserts BOTH ends: he
	## never goes past the grade, and he stops within a week of it rather than
	## chasing the last thousandth at a credit a go.
	var top: float = Quartermaster.TOP[Quartermaster.Grade.BORROWED]
	_ok(f.armor <= top + 0.001 and f.armor >= top - Quartermaster.WORTH_DOING
			- ClubOffice.KIT_STEP,
		"the armorer takes a borrowed harness up to its grade and no further",
		"twenty visits left it at %.2f, the grade caps at %.2f, and he stops "
			% [f.armor, top] + "within %.2f of it" % Quartermaster.WORTH_DOING)

	## AND THE REFUSAL SAYS WHICH OF THREE THINGS IT MEANS. Nothing worth doing,
	## nothing more at this grade, or nothing better in the world — because
	## "as good as borrowed gets" on a harness the screen beside it reads at 85%
	## is a small lie, and a player who catches one stops trusting the rest.
	var err := o.repair_kit(f)
	_ok(err.contains("fine") or err.contains(Quartermaster.name_of(f).to_lower()),
		"and the refusal says which kind of refusal it is",
		"'%s'" % err)

	## THE GRADE-NAMING REFUSAL IS STILL THERE, for a harness genuinely at its
	## ceiling — that one is the sales pitch for the next rung and it would be
	## easy to lose while widening the band above.
	f.armor = top
	var at_top := o.repair_kit(f)
	_ok(at_top.contains(Quartermaster.name_of(f).to_lower()),
		"and a harness actually at its ceiling is still sold the next one",
		"'%s'" % at_top)

	## THE BILL IS AGAINST HIS OWN CEILING TOO, or the armorer charges for work
	## he is about to refuse.
	##
	## MEASURED AT A READING BOTH GRADES CAN BE AT. The first cut compared a
	## borrowed harness AT ITS CEILING against plate at the same number, and the
	## gap between 0.90 and 1.00 rounds to the same 1 CC either way — so the check
	## was asking whether five credits can tell two tenths apart. It cannot, and
	## that was the check's fault and not the shop's.
	f.armor = 0.50
	f.harness = Quartermaster.Grade.BORROWED
	var as_borrowed := ClubOffice.kit_cost(f)
	f.harness = Quartermaster.Grade.TOURNAMENT
	var as_plate := ClubOffice.kit_cost(f)
	_ok(as_plate > as_borrowed,
		"and the same condition costs more to fix on better kit",
		"%d CC borrowed, %d CC in plate, both read 0.50" % [as_borrowed, as_plate])


func _test_better_kit_wears_slower() -> void:
	var a := _man()
	var b := _man()
	a.harness = Quartermaster.Grade.BORROWED
	b.harness = Quartermaster.Grade.TOURNAMENT
	_ok(Quartermaster.wear_scale(a) > Quartermaster.wear_scale(b) * 1.5,
		"club spares wear out far faster than tournament plate",
		"x%.2f against x%.2f" % [Quartermaster.wear_scale(a),
			Quartermaster.wear_scale(b)])


func _test_buying_a_harness_hands_over_a_fresh_one() -> void:
	var o := ClubOffice.new()
	o.credits = 100
	## A FIVE-STAR ARMORER, so the metal is not what refuses (see below).
	o.armorer = Armorer.make(5, 1)
	var f := _man()
	f.harness = Quartermaster.Grade.BORROWED
	f.armor = 0.50
	var cost := Quartermaster.upgrade_cost(f)
	var err := o.buy_harness(f)
	_ok(err == "" and f.harness == Quartermaster.Grade.SERVICEABLE,
		"a club can buy a man up a grade", "%d CC%s" % [cost,
			"" if err == "" else " — " + err])
	## FRESH, AT THE TOP OF ITS GRADE. Charging for new kit and handing over a
	## rattling one would be a shop selling condition and delivering grade.
	_ok(f.armor >= Quartermaster.ceiling(f) - 0.001,
		"and it arrives at the top of its grade, not in the state the old one was",
		"bought at 0.50, arrived at %.2f" % f.armor)
	_ok(o.credits == 100 - cost, "and it is paid for",
		"%d CC left of 100" % o.credits)

	## AND THERE IS A TOP. A shop that keeps taking money for the same thing is
	## the worst failure a shop can have.
	f.harness = Quartermaster.Grade.TITANIUM
	_ok(o.buy_harness(f) != "" and Quartermaster.next_grade(f) < 0,
		"and titanium is the end of the ladder",
		"refused with a sentence rather than charging again")

	## A CLUB THAT CANNOT AFFORD IT IS REFUSED, not overdrawn.
	var poor := ClubOffice.new()
	poor.credits = 0
	var g := _man()
	g.harness = Quartermaster.Grade.BORROWED
	_ok(poor.buy_harness(g) != "" and g.harness == Quartermaster.Grade.BORROWED,
		"and a club with no credits buys nothing",
		"refused, and the harness did not change")


func _test_the_ledger_is_the_squad() -> void:
	var c := MeleeRosters.starting_club()
	for f in c.roster:
		f.harness = Quartermaster.Grade.BORROWED
		f.armor = 0.60
	c.roster[0].armor = 0.20            ## cannot pass inspection
	c.roster[1].armor = FighterCard.INSPECTION_MIN + 0.05   ## one bad week off it
	var led := Quartermaster.ledger(c.roster)
	_ok(int(led["failing"]) == 1, "the ledger counts the men who cannot go out",
		"%d failing of %d" % [led["failing"], led["men"]])
	_ok(int(led["at_risk"]) >= 1, "and the men who are one bad week from it",
		"%d at risk" % led["at_risk"])
	_ok(int(led["bill"]) > 0 and int(led["worn"]) == c.roster.size(),
		"and what it would cost to put the lot right",
		"%d CC across %d harnesses" % [led["bill"], led["worn"]])
	notes.append("the ledger: %d men, %d failing, %d CC to fix"
		% [led["men"], led["failing"], led["bill"]])


## ------------------------------------------------- the number nobody checked
func _test_what_armor_is_actually_worth() -> void:
	## THIS CHECK DOES NOT ASSERT A BALANCE. It asserts that the figure is
	## WRITTEN DOWN, and prints it, because it is the one thing a shop built on
	## armor has to be honest about.
	##
	## `effective_base()` is `base * lerpf(0.78, 1.0, armor)` and base carries
	## 0.24 of a man's rating. So the whole legal armor range — from one notch
	## above failing inspection to a perfect harness — moves a man's rating by
	## about a point and a half. Repairing thirteen men before every event for
	## twenty-four events moved club power by zero (`tools/probe_kit.gd`).
	##
	## Inspection has teeth. The multiplier does not. Whether it SHOULD is a
	## balance decision with Pete's name on it; this is here so that the day
	## somebody widens that range, the number in `docs/PLAYTEST-15-SEP.md` is
	## wrong and this check says so.
	var f := _man()
	f.armor = FighterCard.INSPECTION_MIN
	var low := f.rating()
	f.armor = 1.0
	var high := f.rating()
	var worth := high - low
	_ok(worth < 3.0,
		"armor's whole legal range is still worth about a point and a half",
		"%.2f rating points from %.2f to 1.00 — if this fails, the balance moved and the docs are stale"
			% [worth, FighterCard.INSPECTION_MIN])

	## AND INSPECTION IS THE PART THAT BITES. Binary, and worth everything.
	f.armor = FighterCard.INSPECTION_MIN - 0.01
	_ok(not f.fit(), "and below the line he is worth nothing at all, which is the real cap",
		"a man who cannot pass inspection cannot go out, whatever he rates")
	notes.append("armor: %.2f rating points across its whole range; inspection is binary"
		% worth)


func _test_a_simmed_event_costs_a_week() -> void:
	## FIGHTING WORE YOUR ARMOR AND SIMMING DID NOT. `_apply_regime()` ran from
	## `post_bout` and not from `skip_event`, so twenty-four simmed events left a
	## squad on exactly the kit it started with — a discount for not playing the
	## game, and the kind of asymmetry a player finds by accident and then never
	## fights a bout again.
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var before := 0.0
	for f in s.club.active_eight():
		before += f.armor
	for i in 6:
		s.skip_event()
	var after := 0.0
	for f in s.club.active_eight():
		after += f.armor
	_ok(after < before, "six simmed events wear the harnesses of the men who travelled",
		"%.2f -> %.2f across the eight" % [before, after])


## THE ARMORER'S STARS ARE THE METAL (Pete, 1 Oct 2026): one star makes Rust and
## nothing better, and keeps a better harness only up to what Rust can be.
func _test_the_armorer_makes_what_he_can() -> void:
	var bad: Array[String] = []
	var o := ClubOffice.new()
	o.credits = 200
	var f := _man()
	f.harness = Quartermaster.Grade.BORROWED
	if o.buy_harness(f) == "" or f.harness != Quartermaster.Grade.BORROWED:
		bad.append("a one-star armorer made Mild")
	var g := _man()
	g.harness = Quartermaster.Grade.TOURNAMENT
	g.armor = 0.50
	for _i in 12:
		o.repair_kit(g)
		o.new_week()
	if g.armor > float(Quartermaster.TOP[Quartermaster.Grade.BORROWED]) + 0.001:
		bad.append("a one-star kept Stainless to %.2f, past what Rust can be" % g.armor)
	## Hiring: the division gate and the wage.
	o.tier = 0
	if o.hire_armorer(Armorer.make(4, 9)) == "":
		bad.append("a four-star came to the Backyard")
	var three := Armorer.make(3, 9)
	var before := o.credits
	if o.hire_armorer(three) != "" or o.armorer_cap() != Quartermaster.Grade.FITTED \
			or before - o.credits != Armorer.wage_of(three):
		bad.append("a three-star did not come, or did not charge his wage")
	if o.buy_harness(f) != "" or f.harness != Quartermaster.Grade.SERVICEABLE:
		bad.append("the three-star did not make Mild")
	_ok(bad.is_empty(), "the armorer makes and keeps what his stars say",
		"; ".join(bad) if not bad.is_empty() else "1 star: Rust only; 3 stars hired for %d CC and up to Hardened" % Armorer.wage_of(three))


## KIT SPONSORS (Pete, 8 Oct 2026, Harness #2). Paid per man in the line, by metal
## and condition; Rust earns nothing; fractions carry and survive a save.
func _test_sponsors_pay_for_kit_that_fights() -> void:
	var o := ClubOffice.new()
	o.credits = 0
	var line: Array = []
	for i in 5:
		var f := _man()
		f.harness = Quartermaster.Grade.BORROWED
		f.armor = 0.90
		line.append(f)
	Quartermaster.pay_sponsors(o, line)
	_ok(o.credits == 0 and o.harness_receipts == 0.0, "a line in rust earns no sponsor",
		"%d CC, %.2f carried" % [o.credits, o.harness_receipts])

	for f in line:
		f.harness = Quartermaster.Grade.TITANIUM
		f.armor = 1.0
	Quartermaster.pay_sponsors(o, line)
	## 5 x 0.65 = 3.25: three credits paid, a quarter carried.
	_ok(o.credits == 3 and absf(o.harness_receipts - 0.25) < 0.001,
		"a titanium line is paid whole credits and carries the change",
		"%d CC, %.2f carried" % [o.credits, o.harness_receipts])
	_ok(int(o.books_in.get(ClubOffice.LINE_SPONSOR, 0)) == 3,
		"and it lands on its own line in the books", str(o.books_in))

	## WORN KIT EARNS LESS: half the condition, half the sponsor.
	var worn := _man()
	worn.harness = Quartermaster.Grade.TITANIUM
	worn.armor = 0.5
	_ok(absf(Quartermaster.sponsor_rate(worn) - 0.325) < 0.001,
		"and kit that is not kept up earns less", "%.3f a bout" % Quartermaster.sponsor_rate(worn))

	## THE CHANGE IS SAVED, so a reload never loses part of a credit.
	var back := ClubOffice.from_dict(o.to_dict())
	_ok(absf(back.harness_receipts - 0.25) < 0.001, "and the change survives a save",
		"%.2f after the round trip" % back.harness_receipts)

	## EVERY RUNG EARNS MORE THAN THE ONE BELOW.
	var up := true
	for g in range(1, Quartermaster.SPONSOR_CC.size()):
		up = up and float(Quartermaster.SPONSOR_CC[g]) > float(Quartermaster.SPONSOR_CC[g - 1])
	_ok(up, "and every metal earns more than the one below it", str(Quartermaster.SPONSOR_CC))


## THE GRADE BONUS (Pete, 8 Oct 2026: "mild stat bonuses"). It lifts the fight
## number and never the growth ceiling (Pete, 8 Oct 2026: ceilings use stats
## without kit).
func _test_better_metal_lifts_the_fight_not_the_ceiling() -> void:
	var f := _man()
	f.armor = 1.0
	f.harness = Quartermaster.Grade.BORROWED
	var rust_base := f.effective_base()
	var rust_ab := f.ability()
	f.harness = Quartermaster.Grade.TITANIUM
	_ok(f.effective_base() > rust_base, "better metal lifts the base he fights with",
		"%.1f in rust, %.1f in titanium" % [rust_base, f.effective_base()])
	_ok(f.ability() == rust_ab, "and not the ability his ceiling is measured against",
		"%d both ways" % rust_ab)
	_ok(f.effective_base() <= rust_base * 1.15, "and the lift is mild",
		"+%.0f%%" % (100.0 * (f.effective_base() / rust_base - 1.0)))


## THE LEAGUE DOES THE SAME (Harness #2): a knock rests a man before the week's
## regime runs, so the sponsor and the wear are read off the bout, not the line
## left standing after it.
func _test_a_league_bout_pays_and_wears_who_fought() -> void:
	var season := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = season
	for f in season.club.roster:
		f.harness = Quartermaster.Grade.TITANIUM
		f.armor = 1.0
	var sim := season.begin_bout()
	sim.run_to_end()
	var stood := SeasonBouts.fought_line(season, sim)
	var before := {}
	for f in season.club.roster:
		before[f] = f.armor
	## HURT, forced rather than rolled, so the line rested before the regime is
	## guaranteed to differ from the line that fought.
	stood[0].injury = 3
	season.post_bout(sim)
	var wrong: Array[String] = []
	for f in season.club.roster:
		var dented: bool = float(f.armor) < float(before[f]) - 0.0001
		if stood.has(f) != dented:
			wrong.append(f.display_name)
	_ok(wrong.is_empty(), "a league bout wears the men who fought it and nobody else",
		"%d fought, wrong: %s" % [stood.size(), ", ".join(wrong) if not wrong.is_empty() else "none"])
