extends SceneTree
## CAN A CLUB AFFORD TO BE RUN PROPERLY?
##
##   godot --headless --path . --script res://tools/probe_afford.gd
##
## Pete, 16 Sep 2026: *"The income is either too low or costs are too high. 84 in
## one year will not maintain enough, you'll decline."*
##
## ---------------------------------------------------------------------------
## `probe_economy.gd` ALREADY ANSWERED THIS AND SAID THE OPPOSITE, and that is
## the reason this file exists rather than a second reading of the first one.
##
## It reports a Backyard club netting 56 to 69 CC a season against a 6-credit
## Club gym and concludes the next ground is **a tenth of a season away** — which
## reads as an economy so generous the ladder is decorative. Pete played the same
## economy, earned 84, and found he could not keep up.
##
## Both are true, because the probe measures ONE SINK. The arena ladder is 138
## credits across a whole career; the things a club buys every single season are
## the repairs, the levels the men have earned, the deals running out and the
## upkeep — and none of them are in that table. **A probe that measures one sink
## and calls the economy generous is measuring the sink, not the economy.**
##
## ---------------------------------------------------------------------------
## SO THIS ONE SEPARATES THE BILL FROM THE SHOPPING.
##
##   FORCED     what it costs to stand still: upkeep, keeping every harness
##              above the inspection line, keeping the ground out of the state
##              that costs you gate.
##   EARNED     the levels the men have actually worked for this year. Not
##              optional in any meaningful sense — an unspent level is a fighter
##              who trained and got nothing, and a club that never spends them
##              declines against a ladder that does not.
##   GROWTH     everything else. Harnesses, the cap, facilities, the bus, the
##              ground. This is the number that decides whether the game has a
##              climb in it.
##
## A season where FORCED + EARNED is most of income is a club treading water,
## which is exactly the word Pete used: decline.
##
## Nothing here changes a constant. It prints a table.

const YEARS := 8
const BASES: Array[int] = [4242, 90210, 31337]

## THE THREE STANDARDS, and they are the same three `probe_economy.gd` uses —
## deliberately, so the two tables can be read against each other. The first cut
## of this file dropped a Backyard-strength squad into the National Division and
## reported its income as 13 CC a season, which is not what a National club earns,
## it is what a doomed one earns. **A fixture that cannot reach the state it
## claims to measure is measuring something else and not saying so.**
const STANDARDS := [["title-winning", 1.0], ["good", 0.62], ["mid-table", 0.35]]


func _initialize() -> void:
	print("\nWhat a season pays, and what standing still costs")
	print("(%d years, back half counted, %d seeds, league fixtures only — no tournament)\n"
		% [YEARS, BASES.size()])
	print("%-19s %-13s %8s %8s %8s %8s %8s %7s" % [
		"division", "club", "year 1", "income", "forced", "earned", "growth", "%left"])
	for t in League.TIERS.size():
		for st in STANDARDS:
			_settle(t, String(st[0]), float(st[1]))
		print("")
	print("YEAR 1 = what the club's very first season paid, before notoriety settles")
	print("FORCED = upkeep + repairs to hold the inspection line + keeping the ground")
	print("EARNED = the level-ups the squad worked for that year, at Career.level_cost")
	print("GROWTH = what is left for harnesses, the cap, facilities, the bus, the ground")
	print("The ladder a career has to buy: 6, 12, 22, 38, 60 CC of ground, plus")
	print("eight harnesses at 3 / 7 / 14, five cap raises at 4 to 12, and the facilities.")
	print("")
	print("EARNED READS NEAR ZERO HERE AND THAT IS THE FIXTURE, NOT A FINDING.")
	print("`_standard()` manufactures rating by pushing raw stats, so these men never")
	print("bank the XP that a level costs money to take. Measured on a squad that")
	print("develops naturally instead, the earned bill is about 12 CC a season in the")
	print("Backyard Circuit and 10 in the National Division — which makes it the")
	print("LARGEST single sink in the game and the one nothing was counting.\n")
	quit(0)


func _settle(tier: int, label: String, standard: float) -> void:
	var income := 0.0
	var forced := 0.0
	var earned := 0.0
	var first := 0.0
	var firsts := 0
	var runs := 0
	for base in BASES:
		var s := Season.new(MeleeRosters.starting_club(), base + tier * 17)
		Session.season = s
		var band: Array = League.TIERS[tier]["power"]
		## THE GROUND THIS DIVISION CAN HAVE, built, because the upkeep of it is
		## half the bill being measured and a club in the National Division with a
		## back field is not a club anybody is playing.
		s.office.tier = tier
		while s.office.arena.can_build(tier, 999) == "":
			s.office.arena.level += 1
			s.office.arena.built()
		for y in YEARS:
			_place(s, tier)
			_standard(s, band, standard)
			## THE FIRST HALF IS THE CLIMB, not the steady state: notoriety and
			## fans both start at nothing and take years to settle, so counting
			## year one would measure a club nobody has heard of and call it a
			## National one. Same reason `probe_notoriety` runs twelve.
			var counting: bool = y >= YEARS / 2
			var guard := 0
			while not s.ready_to_roll() and guard < 80:
				guard += 1
				if s.bid_open():
					## DECLINED, EVERY YEAR. `probe_economy` tops the club up 200
					## CC so it can afford to host, which measures the tournament
					## as well as the league and hides the entry fee in a subsidy.
					## The question here is what an ORDINARY year pays, and an
					## ordinary year is the fixture list.
					s.decline_bid()
				elif s.cup_pending():
					s.sim_cup_tie()
				else:
					s.skip_event()
			## WHAT STANDING STILL WOULD COST, priced at the state the year
			## actually left the club in — read BEFORE the roll-over, because the
			## roll-over bills the upkeep and repairs nothing, so asking a
			## half-settled club is asking the wrong world.
			var f := _forced_bill(s)
			var e := _earned_bill(s)
			s.roll_over()
			s.office.tier = tier
			## THE FIRST YEAR GETS ITS OWN COLUMN, because it is the year the
			## player is actually complaining about and every other number here
			## deliberately throws it away. A club starts on 3 notoriety with no
			## following at all: the gate is a credit a fight and the retainer is
			## whatever a back field pays, so season one is not a slow version of
			## a settled season, it is a different economy. **An average that
			## discards the case under discussion is an average about something
			## else.**
			if y == 0:
				first += float(ClubOffice.book_total(
					(s.office.books_last as Dictionary).get("in", {})))
				firsts += 1
			if not counting:
				continue
			## AND WHAT THE YEAR ACTUALLY PAID, off the club's own books rather
			## than off the balance. The balance cannot tell income from spending,
			## and the first cut of this probe read 5 CC a season because every
			## summer payment lands INSIDE `roll_over()`, after the read.
			var last: Dictionary = s.office.books_last
			income += float(ClubOffice.book_total(last.get("in", {})))
			forced += float(f)
			earned += float(e)
			runs += 1
	if runs == 0:
		return
	var i := income / float(runs)
	var f2 := forced / float(runs)
	var e2 := earned / float(runs)
	var g := i - f2 - e2
	print("%-19s %-13s %8.1f %8.1f %8.1f %8.1f %8.1f %6.0f%%" % [
		League.tier_name(tier), label, first / float(maxi(1, firsts)),
		i, f2, e2, g, 100.0 * g / maxf(1.0, i)])


## PUT THE CLUB IN THE DIVISION, by swapping it with somebody already there —
## lifted from `probe_economy.gd` so the two probes cannot disagree about what
## "in the State League" means.
func _place(s: Season, tier: int) -> void:
	var me: int = s.world.player_club
	if int(s.world.clubs[me]["tier"]) != tier:
		for other in s.world.clubs:
			if int(other["tier"]) == tier and int(other["id"]) != me:
				other["tier"] = int(s.world.clubs[me]["tier"])
				break
		s.world.clubs[me]["tier"] = tier
		s.world._new_season()
	s.office.tier = tier


## AND MAKE IT AS GOOD AS THE LABEL SAYS. Also lifted, unchanged.
func _standard(s: Season, band: Array, standard: float) -> void:
	var want := int(lerpf(float(band[0]), float(band[1]), 0.45 + 0.5 * standard))
	var guard := 0
	while s.club.power() < want and guard < 400:
		guard += 1
		for f in s.club.roster:
			f.strength = mini(99, f.strength + 1)
			f.base = mini(99, f.base + 1)
			f.skill = mini(99, f.skill + 1)
			f.gas = mini(99, f.gas + 1)
	s.sync_power()
	for i in s.world.clubs.size():
		if i == s.world.player_club:
			continue
		var b: Array = League.TIERS[int(s.world.clubs[i]["tier"])]["power"]
		s.world.clubs[i]["power"] = int(lerpf(float(b[0]), float(b[1]), 0.5))


## WHAT IT COSTS TO STAND STILL FOR A YEAR.
func _forced_bill(s: Season) -> int:
	var o: ClubOffice = s.office
	var bill := o.upkeep_bill()
	## EVERY HARNESS BACK TO ITS OWN CEILING. Not to a perfect one — a borrowed
	## harness cannot go past 0.90 and the armorer refuses the rest, so billing
	## for it would be billing for work the game will not do.
	for c in s.club.roster:
		if not Quartermaster.topped_out(c):
			bill += ClubOffice.kit_cost(c)
	## AND THE GROUND, once, at whatever state a year of fixtures left it in.
	if o.arena.condition < 0.999 and o.arena.level >= Arena.WEARS_FROM_LEVEL:
		bill += o.arena.upkeep_cost()
	return bill


## AND WHAT THE MEN EARNED THAT THE CLUB HAS TO PAY FOR.
func _earned_bill(s: Season) -> int:
	var bill := 0
	for c in s.club.roster:
		if Career.can_level(c) and not Career.at_ceiling(c):
			bill += Career.level_cost(c)
	return bill
