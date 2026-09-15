extends SceneTree
## THE GROUND, AND THE STATE YOU KEEP IT IN.
##
##   godot --headless --path . --script res://tests/test_arena_condition.gd
##
## Pete, 15 Sep 2026: *"can we use an overlay to make the best arena level look
## shitty? Like an overlay that adds trash outside the fighting area, cracks in
## the wood, and make it really crappy that you'll have to upgrade to clean and
## it raises your income but costs to maintain as it degrades?"*
##
## The overlay is a drawing and a drawing is not what breaks. What breaks is the
## axis underneath it, and it breaks in three ways this file exists to catch:
##
##   THE RHYTHM. A per-week wear figure wears a fifteen-event ground three times
##   as fast as a five-event one, so "how often does this need doing" would be a
##   different question in every league. The figure is a SEASON fraction now and
##   these checks walk real seasons at both ends of the ladder to prove the pace
##   is the same.
##
##   THE PRICE. The first cut billed 3 CC to put right a ground that pays 2, at
##   the bottom of the pyramid, where Pete has already said the money is too
##   tight. **A cost that is not derived from the thing it is a cost OF will
##   eventually exceed it** — so upkeep is a share of the retainer and this file
##   checks it at every level rather than at the one somebody was looking at.
##
##   THE ROAD. `take_a_week` is called from `Season._apply_regime`, which is the
##   one place the fought path and the simmed path meet. If it were called from
##   `post_bout` instead, skipping your fixtures would keep your arena clean —
##   which is the harness bug this project already shipped once, in a costume.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the ground and its condition ===\n")
	_test_a_ground_wears_at_the_same_pace_in_every_league()
	_test_hosting_is_harder_on_it_than_traveling()
	_test_a_back_field_has_nothing_to_wear()
	_test_the_retainer_slides_and_has_a_floor()
	_test_upkeep_never_outruns_what_the_ground_pays()
	_test_the_ground_can_be_seen_to_once_a_week()
	_test_a_new_ground_arrives_new()
	_test_the_season_actually_wears_it_by_both_roads()
	_test_a_neglected_ground_stops_lifting_the_room()
	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE GROUND HOLDS (%d checks)\n" % checks)
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


## A ground at a stated level, spotless, with nothing else attached.
func _ground(level: int) -> Arena:
	var a := Arena.new()
	a.level = level
	a.condition = 1.0
	return a


## --------------------------------------------------------------------------
func _test_a_ground_wears_at_the_same_pace_in_every_league() -> void:
	## ONE FIXTURE IN THREE AT HOME, which is what `tools/probe_venue.gd` actually
	## found — home 33%, away 37%, neutral 30%, because the cup ties are neutral
	## ground and they are nearly a third of the calendar. The obvious assumption
	## was a half, and a half made every ground in the game wear 20% slower than
	## `WEAR_SEASON` says. **A check that reaches a state by a road the game does
	## not have is measuring a state the game cannot be in**, and "half the
	## fixtures are at home" was a road the game does not have.
	##
	## The four season lengths are the real ones: `League.events_in_season` is
	## `clubs - 1` and the tiers are 6, 8, 12 and 16 clubs.
	var line: Array[String] = []
	var worst := 0.0
	for tier in 4:
		var n := League.events_in_season(tier)
		var a := _ground(3)
		for i in n:
			a.take_a_week(i % 3 == 0, n)
		var fell := 1.0 - a.condition
		worst = maxf(worst, absf(fell - Arena.WEAR_SEASON))
		line.append("%d events -> %.3f" % [n, fell])
	## A SEASON WITH FIVE EVENTS CANNOT PUT EXACTLY A THIRD OF THEM AT HOME, so
	## the tolerance is about one week's worth of the shortest season rather than
	## zero. A check that demands a number a legal fixture list cannot produce is
	## a check that will be silenced rather than fixed.
	_ok(worst < 0.09,
		"a whole season costs the same fraction of a ground in every league",
		"%s (target %.2f, worst miss %.3f)"
			% [", ".join(line), Arena.WEAR_SEASON, worst])
	notes.append("season wear: " + ", ".join(line))

	## AND THE WEIGHTS ARE SOLVED, not typed — the check that the arithmetic in
	## `quiet_weight()` still satisfies the two things it is supposed to satisfy.
	var mix := Arena.HOSTED_SHARE * Arena.hosted_weight() \
		+ (1.0 - Arena.HOSTED_SHARE) * Arena.quiet_weight()
	_ok(absf(mix - 1.0) < 0.001,
		"and an average week is an average week, by the calendar the game has",
		"%.2f hosted and %.2f quiet mix to %.4f at %.0f%% home"
			% [Arena.hosted_weight(), Arena.quiet_weight(), mix,
				Arena.HOSTED_SHARE * 100.0])


func _test_hosting_is_harder_on_it_than_traveling() -> void:
	var host := _ground(3)
	var away := _ground(3)
	host.take_a_week(true, 10)
	away.take_a_week(false, 10)
	var h := 1.0 - host.condition
	var q := 1.0 - away.condition
	_ok(h > q, "a home meet takes more out of a ground than a quiet week",
		"%.4f hosted against %.4f quiet" % [h, q])
	## AND BY THE STATED RATIO, because the two numbers are solved for rather
	## than typed, and a solve that drifts is worse than two constants that do.
	_ok(q > 0.0 and absf(h / q - Arena.WEAR_HOSTED_SHARE) < 0.02,
		"and by exactly the share the constant names",
		"%.2fx against a stated %.2fx" % [h / maxf(q, 0.0001), Arena.WEAR_HOSTED_SHARE])


func _test_a_back_field_has_nothing_to_wear() -> void:
	var a := _ground(0)
	for i in 40:
		a.take_a_week(true, 5)
	_ok(a.condition >= 0.999,
		"a back field cannot go to seed, because there is nothing there to keep",
		"forty hosted weeks left it at %.3f" % a.condition)
	## AND THE ONE ABOVE IT CAN, so the exemption is a floor and not an off switch.
	var b := _ground(Arena.WEARS_FROM_LEVEL)
	b.take_a_week(true, 5)
	_ok(b.condition < 1.0, "and the level above it does wear",
		"%s fell to %.3f in one hosted week"
			% [String(Arena.LEVELS[Arena.WEARS_FROM_LEVEL]["name"]), b.condition])


func _test_the_retainer_slides_and_has_a_floor() -> void:
	var bad: Array[String] = []
	for lv in Arena.LEVELS.size():
		var a := _ground(lv)
		var full := a.retainer_full()
		a.condition = 0.0
		var ruin := a.retainer()
		## THE FLOOR IS A FLOOR AND NOT A CLOSURE. A ground nobody can earn from
		## is a career with no way back, which is a dead end rather than a
		## difficulty — and a multiplier that can legitimately reach zero
		## annihilates whatever it is applied to, which this project has already
		## paid for once in `gate_income`.
		if full > 0 and ruin <= 0 and full >= 3:
			bad.append("%s pays %d well kept and nothing at all wrecked"
				% [String(Arena.LEVELS[lv]["name"]), full])
		a.condition = 1.0
		if a.retainer() != full:
			bad.append("%s: a spotless ground does not pay its own full retainer"
				% String(Arena.LEVELS[lv]["name"]))
	_ok(bad.is_empty(), "the retainer slides with the state of the ground and lands on a floor",
		"every level" if bad.is_empty() else "; ".join(bad))

	## AND A SPOTLESS GROUND IS EXACTLY WHAT IT WAS BEFORE ANY OF THIS EXISTED.
	## These six are the retainer as it stood the day before the condition axis
	## was written — the formula moved files, and a formula that moves files is a
	## formula that quietly changes by one somewhere. If this fails, the retainer
	## moved, and every balance figure in the register is stale.
	##
	## The long note over `ClubOffice.gate_income()` says "2 at a back field, 6 at
	## a sports hall, 11 at an arena, 22 at a full National Arena". Two of those
	## four are a credit out: the arena pays 12 and the National Arena 21. The
	## numbers below are what the code does; the comment is what somebody worked
	## out by hand, and this is the note saying which one to believe.
	var want := [2, 3, 4, 6, 12, 21]
	var got: Array[int] = []
	for lv in Arena.LEVELS.size():
		got.append(_ground(lv).retainer_full())
	_ok(got == want, "and a well-kept ground pays what it always paid",
		"%s against %s" % [str(got), str(want)])
	notes.append("retainer by level: " + str(got))


func _test_upkeep_never_outruns_what_the_ground_pays() -> void:
	## THE BUG THIS CHECK WAS WRITTEN FOR. The first pricing was
	## `missing * 6 * (1 + level * 0.8)` and at a back field it billed 3 CC to
	## recover a 2 CC retainer: the club paid more to keep the ground than the
	## ground was worth. Priced off the retainer it is the same proportion
	## everywhere, and this walks every level against a full season's grime.
	var bad: Array[String] = []
	var line: Array[String] = []
	for lv in Arena.LEVELS.size():
		var a := _ground(lv)
		a.condition = 1.0 - Arena.WEAR_SEASON
		var cost := a.upkeep_cost()
		var pays := a.retainer_full()
		line.append("%s: %d CC to clean, pays %d" % [
			String(a.arena_name()), cost, pays])
		if lv >= Arena.WEARS_FROM_LEVEL and cost >= pays:
			bad.append("%s costs %d to put right and pays %d"
				% [a.arena_name(), cost, pays])
	_ok(bad.is_empty(), "a season's grime always costs less than the ground earns",
		"every level that wears" if bad.is_empty() else "; ".join(bad))
	notes.append("upkeep: " + "; ".join(line))

	## A CLUB IS NEVER CHARGED FOR NOTHING, and never charged nothing either.
	var a := _ground(5)
	a.condition = 0.9999
	_ok(a.upkeep_cost() >= 1, "and a nearly-clean ground still costs a credit to finish",
		"%d CC at condition %.4f" % [a.upkeep_cost(), a.condition])
	## AND IT GROWS WITH THE MESS.
	var b := _ground(5)
	b.condition = 0.9
	var small := b.upkeep_cost()
	b.condition = 0.2
	_ok(b.upkeep_cost() > small, "and a wrecked one costs more than a dusty one",
		"%d CC against %d CC" % [b.upkeep_cost(), small])


func _test_the_ground_can_be_seen_to_once_a_week() -> void:
	var o := ClubOffice.new()
	o.arena.level = 4
	o.arena.condition = 0.5
	o.credits = 200
	var before := o.credits
	var err := o.tidy_arena()
	_ok(err == "" and o.arena.condition >= 0.999,
		"paying for the ground puts it right", "condition %.3f, %d CC spent"
			% [o.arena.condition, before - o.credits])
	_ok(before - o.credits > 0, "and it costs something",
		"%d CC" % (before - o.credits))

	## THE SAME WEEK AGAIN IS REFUSED, and refused in words — the throttle is
	## what stops a club with credits walking a ruin back to new in an afternoon
	## and turning the whole axis into a vending machine.
	o.arena.condition = 0.5
	var again := o.tidy_arena()
	_ok(again != "", "and it cannot be done twice in one week", "\"%s\"" % again)
	_ok(o.arena.condition < 0.999, "and the refusal did not quietly do it anyway",
		"condition still %.3f" % o.arena.condition)

	## A SPOTLESS GROUND IS REFUSED RATHER THAN BILLED.
	var p := ClubOffice.new()
	p.arena.level = 4
	p.credits = 200
	var spotless := p.tidy_arena()
	_ok(spotless != "" and p.credits == 200,
		"and a ground already spotless is turned away, not charged",
		"\"%s\", %d CC left" % [spotless, p.credits])

	## AND A CLUB THAT CANNOT AFFORD IT IS TOLD THE NUMBER.
	var q := ClubOffice.new()
	q.arena.level = 5
	q.arena.condition = 0.2
	q.credits = 0
	var broke := q.tidy_arena()
	_ok(broke.contains(str(q.arena.upkeep_cost())),
		"and a club that cannot pay is told what it would have cost",
		"\"%s\"" % broke)


func _test_a_new_ground_arrives_new() -> void:
	var o := ClubOffice.new()
	o.arena.level = 1
	o.arena.condition = 0.2
	o.tier = 3
	o.credits = 500
	var err := o.build_arena()
	_ok(err == "" and o.arena.level == 2 and o.arena.condition >= 0.999,
		"a ground you have just paid for is not handed over dirty",
		"level %d at condition %.3f" % [o.arena.level, o.arena.condition])


func _test_the_season_actually_wears_it_by_both_roads() -> void:
	## THE ROAD IS THE POINT. `_apply_regime` is where the fought path and the
	## simmed path meet, and a wear tick anywhere else would make skipping your
	## fixtures a way to keep your arena clean — which is precisely the harness
	## bug `test_quartermaster.gd` was written for, wearing a different hat.
	var s := Season.new(MeleeRosters.starting_club(), 91011)
	s.office.arena.level = 4
	s.office.arena.condition = 1.0
	for i in 4:
		s.skip_event()
	var simmed := s.office.arena.condition
	_ok(simmed < 1.0, "four simmed events wear the ground",
		"1.000 -> %.3f" % simmed)

	## AND THE RETAINER THE SEASON PAYS OUT HAS NOTICED.
	_ok(s.office.gate_income() <= s.office.gate_income_full(),
		"and the retainer the club is paid has come down with it",
		"%d CC against a well-kept %d CC"
			% [s.office.gate_income(), s.office.gate_income_full()])

	## THE OFFICE'S OWN TWO FUNCTIONS STILL ANSWER, because everything in the
	## game calls those and not the arena's — a forward that stops forwarding is
	## a silent zero, and this file has already read what a silent zero did to
	## twenty seasons of gate income.
	var o := ClubOffice.new()
	o.arena.level = 5
	o.arena.condition = 1.0
	_ok(o.gate_income() == o.arena.retainer()
			and o.gate_income_full() == o.arena.retainer_full()
			and o.gate_income_full() > 0,
		"and the office still answers for the ground it owns",
		"%d / %d" % [o.gate_income(), o.gate_income_full()])


func _test_a_neglected_ground_stops_lifting_the_room() -> void:
	## THE SECOND THING NEGLECT COSTS, and the reason it is here: at a small
	## ground the retainer slide is one credit, which is not a signal a player
	## will ever notice. Morale is.
	var kept := ClubOffice.new()
	kept.arena.level = 4
	kept.arena.condition = 1.0
	var gone := ClubOffice.new()
	gone.arena.level = 4
	gone.arena.condition = 0.2
	_ok(kept.ground_morale() > gone.ground_morale(),
		"a well-kept ground takes the edge off a bad weekend and a tip does not",
		"%.4f against %.4f" % [kept.ground_morale(), gone.ground_morale()])

	## AND NOTHING THAT WAS TRUE YESTERDAY IS WORSE TODAY. A spotless ground is
	## worth exactly what it was before the condition axis existed — **a feature
	## that nerfs the baseline to make its own upgrades look good is a feature
	## charging you to undo it.**
	var bad: Array[String] = []
	for lv in Arena.LEVELS.size():
		var o := ClubOffice.new()
		o.arena.level = lv
		if not is_equal_approx(o.ground_morale(),
				float(lv) * ClubOffice.MORALE_GROUND):
			bad.append("level %d: %.5f" % [lv, o.ground_morale()])
	_ok(bad.is_empty(), "and a spotless ground is worth what it always was",
		"every level" if bad.is_empty() else "; ".join(bad))
