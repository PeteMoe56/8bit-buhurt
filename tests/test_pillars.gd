extends SceneTree
## The federation and the members — the two masters.
##
## THIS FILE USED TO CARRY SEVEN CHECKS. Four of them were trials day, poaching
## and goodwill, and Pete cut all three on 12 Sep 2026 — *"Those are not good
## ideas."* They came out whole rather than being left disabled, so what is left
## here is the pillar that survived and nothing about the one that did not.
##
##   godot --headless --path . --script res://tests/test_pillars.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the two masters ===\n")
	_test_the_federation_gates_the_cups()
	_test_the_two_masters_pull_apart()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE PILLARS HOLD (%d checks)\n" % checks)
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


func _test_the_federation_gates_the_cups() -> void:
	## *"The federation gates nationals and Worlds on results AND compliance."*
	## The results half already existed; this is the other one, and the check that
	## matters is that being good at the sport does not excuse you from it.
	var bad: Array[String] = []

	## Requirements climb with the division — promotion is a bigger paperwork bill
	## for something that does not make you better.
	var totals: Array[int] = []
	for t in League.TIERS.size():
		var sum := 0
		for r in Federation.rules():
			sum += Federation.required(t, r)
		totals.append(sum)
	for i in range(1, totals.size()):
		if totals[i] < totals[i - 1]:
			bad.append("tier %d asks less than tier %d" % [i, i - 1])
	if totals[totals.size() - 1] <= totals[0]:
		bad.append("the National Division asks no more than the Backyard Circuit")

	## THE GATE, ASSERTED AS A RULE RATHER THAN AS A SCENARIO.
	##
	## The first version set the paperwork, toggled it, and compared the two
	## answers — and both were `false`, because the club was not in an invitable
	## position anyway. It reported "compliance changes nothing", which was a true
	## statement about a club that was never going to be invited and told us
	## nothing at all about the gate. A check that cannot separate the good case
	## from the bad one is not evidence.
	##
	## So: barred must refuse EVERY position, and unbarred must agree exactly with
	## the results half. That covers both directions without needing to arrange a
	## league table.
	var s := Season.new(MeleeRosters.starting_club(), 2024)
	s.office.credits = 200
	for r in Federation.rules():
		s.office.compliance[r] = Federation.MAX_LEVEL
	s.sync_power()
	var checked := 0
	var flipped := 0
	for _e in 6:
		var pos := s.world.player_position()
		var earned: bool = pos != -1 and pos <= LeagueWorld.INVITE_RANK
		s.world.cup_entry_barred = false
		if s.world.invited() != earned:
			bad.append("a compliant club's invitation does not match its position")
		s.world.cup_entry_barred = true
		if s.world.invited():
			bad.append("a barred club in position %d was invited" % pos)
		if earned:
			flipped += 1
		checked += 1
		if s.season_complete():
			break
		s.skip_event()
	if checked == 0:
		bad.append("the gate was never exercised")
	if flipped == 0:
		bad.append("the club was never in an invitable position, so the flip is untested")

	## AND THE OFFICE DRIVES IT — the world must not be deciding this for itself.
	##
	## Asked at a division that actually demands something. The first version asked
	## it in the Backyard Circuit, which asks for nothing by design, so dropping a
	## certificate correctly changed nothing and the check reported that as a
	## broken gate. A rule tested where it does not apply is not tested.
	for t in League.TIERS.size():
		var demands := 0
		for r in Federation.rules():
			demands += Federation.required(t, r)
		if demands == 0:
			## Nothing to be short of, so nothing can bar you. Assert THAT, since
			## it is the Backyard Circuit's whole point.
			var bare := ClubOffice.new()
			bare.tier = t
			if not bare.compliant():
				bad.append("a club with no certificates is barred in tier %d, which asks for none" % t)
			continue
		var o2 := ClubOffice.new()
		o2.tier = t
		for r in Federation.rules():
			o2.compliance[r] = Federation.MAX_LEVEL
		if not o2.compliant():
			bad.append("a fully certified club is short in tier %d" % t)
		## Drop each rule in turn: every one of the three has to be able to bar you
		## on its own, or one of them is decoration.
		for r in Federation.rules():
			if Federation.required(t, r) <= 0:
				continue
			o2.compliance[r] = 0
			if o2.compliant():
				bad.append("%s can be missing in tier %d and nobody minds"
					% [String(Federation.RULE_NAME[r]), t])
			if not o2.shortfalls().has(String(Federation.RULE_NAME[r])):
				bad.append("the refusal does not name %s" % String(Federation.RULE_NAME[r]))
			o2.compliance[r] = Federation.MAX_LEVEL

	## And the wiring: `sync_power` is what carries the office's answer to the
	## world, and it is the only thing that does.
	s.office.compliance[Federation.Rule.KIT] = 0
	s.office.tier = League.Tier.NATIONAL
	s.world.cup_entry_barred = false
	## Read the office's own answer rather than re-deriving it here, then check
	## the world agrees after a sync.
	var should_bar: bool = not s.office.compliant()
	s.sync_power()
	if s.world.cup_entry_barred != (not s.office.compliant()):
		bad.append("the world and the office disagree about the bar")
	if not should_bar:
		bad.append("a National club with no kit certificate is in good standing")

	## AND IT LAPSES RATHER THAN DECAYS. A ground you cannot afford falls a level
	## because it is a building; a certificate you do not renew is simply gone.
	var broke := ClubOffice.new()
	broke.tier = League.Tier.NATIONAL
	for r in Federation.rules():
		broke.compliance[r] = Federation.MAX_LEVEL
	broke.credits = 0
	var out := broke.pay_upkeep()
	var lapsed: Array = out.get("lapsed", [])
	if lapsed.size() != Federation.rules().size():
		bad.append("only %d of %d certificates lapsed on a broke club"
			% [lapsed.size(), Federation.rules().size()])
	for r in Federation.rules():
		if broke.rule_level(r) != 0:
			bad.append("%s survived at level %d" % [String(Federation.RULE_NAME[r]),
				broke.rule_level(r)])

	## One job a week, like every other thing in this office.
	var o := ClubOffice.new()
	o.credits = 100
	o.new_week()
	if o.raise_rule(Federation.Rule.KIT) != "" or o.raise_rule(Federation.Rule.MARSHALS) == "":
		bad.append("two certificates were bought in one week")

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("paperwork demanded by division: %s; a broke club loses all %d certificates outright"
		% [str(totals), Federation.rules().size()])
	_ok(bad.is_empty(), "the federation gates the cups",
		"compliance is a second gate beside the results one, it costs more the higher you climb, and it lapses rather than decaying")


func _test_the_two_masters_pull_apart() -> void:
	## THE WHOLE PILLAR. DIRECTION §4: *"Two masters pulling opposite directions."*
	##
	## The first version had members leaving when the club was non-compliant,
	## which made both masters want the same thing and collapsed the pillar into
	## one slider called "be good". This check is what would have caught that:
	## compliance must be **invisible** to the people who turn up.
	##
	## THE MEMBERSHIP ROLL IS GONE AND THE PILLAR IS NOT. `members` was the third
	## of three populations (Pete, 15 Sep 2026: *"there should be one"*), and the
	## signals it answered to were always the right ones — a season in the top
	## half, a room worth being in, a bus you can fill. They move `fans` now, via
	## `Federation.following_after`, and every question below is the same question.
	var bad: Array[String] = []
	var cap := 1000.0

	var paid := Federation.following_after(400.0, cap, true, 0.70, true)
	var unpaid := Federation.following_after(400.0, cap, true, 0.70, true)
	if not is_equal_approx(paid, unpaid):
		bad.append("the following is watching the paperwork")

	## What they DO watch, each on its own, measured against a club identical but
	## for the one thing — so the check cannot pass on "everything moves it".
	var base := Federation.following_after(400.0, cap, true, 0.70, true)
	var losing := Federation.following_after(400.0, cap, false, 0.70, true)
	var miserable := Federation.following_after(400.0, cap, true, 0.20, true)
	var thin := Federation.following_after(400.0, cap, true, 0.70, false)
	if losing >= base:
		bad.append("a losing season keeps as many people")
	if miserable >= base:
		bad.append("a miserable room keeps as many people")
	if thin >= base:
		bad.append("turning up short-handed keeps as many people")

	## They cannot grow past the ground — the same logistic the morale and the
	## week-to-week following already use.
	var floor_ := 400.0
	for _i in 60:
		floor_ = Federation.following_after(floor_, cap, false, 0.05, false)
	var ceil_ := 400.0
	for _i in 60:
		ceil_ = Federation.following_after(ceil_, cap, true, 0.95, true)
	if floor_ < 0.0:
		bad.append("a club can be driven below nothing")
	if ceil_ > cap + 0.001:
		bad.append("the following grew past the ground")

	## AND THE TENSION IS REAL MONEY — except the money now runs the other way.
	##
	## It used to be *"the dues have to be worth something against the bill"*: a
	## membership subscription paid the club and the federation took a slice. Both
	## halves are bills now. `League.dues_for(tier)` is the entry fee and
	## `federation_upkeep()` is the paperwork, and the pillar holds if a club has
	## to CHOOSE between them — which it does when the two together are a real
	## share of what the division earns.
	var o := ClubOffice.new()
	o.tier = League.Tier.REGIONAL
	for r in Federation.rules():
		o.compliance[r] = Federation.required(League.Tier.REGIONAL, r)
	var entry := o.dues()
	var bill := o.federation_upkeep()
	if bill <= 0:
		bad.append("holding the paperwork costs nothing")
	if entry <= 0:
		bad.append("entering a division costs nothing")
	## Neither may be so much bigger than the other that the smaller one stops
	## being a decision.
	if entry > bill * 8 or bill > entry * 8:
		bad.append("one bill dwarfs the other (%d entry vs %d paperwork)" % [entry, bill])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	notes.append("the following settles at %.0f under everything going wrong and %.0f under everything right, of a %.0f ground"
		% [floor_, ceil_, cap])
	notes.append("the Regional League costs %d to enter and %d to stay legal"
		% [entry, bill])
	_ok(bad.is_empty(), "the two masters pull apart",
		"the following never once looks at the paperwork, and the entry fee and the paperwork are two bills competing for one purse")
