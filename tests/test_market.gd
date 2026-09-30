extends SceneTree
## Contracts and the player market.
##
##   godot --headless --path . --script res://tests/test_market.gd
##
## Two things are being proved here and they are not the same thing.
##
## The first is that a CONTRACT is a contract: a fixed number that does not move
## when the man underneath it does. Before this existed the cap billed a
## fighter's live rating, so developing somebody made him more expensive the
## instant he improved and the salary cap punished exactly the thing the training
## ground is for.
##
## The second is that the MARKET closes the hole tools/probe_career.gd measured —
## a managed club sliding from 66 to 34 because every retirement was replaced by
## a walk-on nine points under the floor. A market that a club can use and still
## slide is a screen, not a system.
##
## EVERYTHING HERE USES `starting_club()`, NOT `player_club()`. The latter is the
## MELEE FIXTURE — a hand-written club rating 65 that exists so seeded bouts
## reproduce — and dropping it into a career is dropping a Regional-standard
## squad into a division whose band tops out at 46. It bills $8,134 against a
## $200 cap, so every signing and every re-signing is refused and the check is
## measuring an impossible club rather than the rule it was written for. That
## never mattered before, because nothing consumed the cap as a constraint until
## the market did.

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	SaveGame.set_namespace("market")
	print("\n=== 8-Bit Buhurt — contracts and the market ===\n")
	_test_a_deal_does_not_move_when_the_man_does()
	_test_the_fork_is_a_real_choice()
	_test_the_rookie_discount()
	_test_the_fee_is_by_band()
	_test_the_cap_is_the_wall()
	_test_out_of_contract_is_a_state_not_an_exit()
	_test_the_pool_is_the_same_after_a_reload()
	_test_the_cap_raise_has_no_ceiling()
	_test_a_refusal_names_a_door_that_opens()
	_test_the_shelf_spans_three_divisions()
	_test_selling_him_on()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE MARKET HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


## SELLING A MAN ON — three coarse buckets, and never for what he cost.
##
## Retro Bowl's answer, ported: a traded player there returns a draft pick in one
## of exactly three tiers by star rating, wide enough that a 3.9-star and a
## 2.0-star fetch the same thing. Ours returns credits on the same three, made by
## collapsing `BAND_NAME` in pairs — see `Market.trade_value`.
##
## THE FIRST CHECK IS THE ONE THAT MATTERS AND IT IS EXHAUSTIVE. The first cut of
## this feature read the TOP band of each pair and paid **19 credits for a man
## whose fee was 18** — buy a Star, sell him the same afternoon, bank a credit.
## The second cut fixed the top bucket and left the bottom one TIED at one credit
## each way, because `fee` and the sale both floored at 1. Neither was visible
## from any single example; both are obvious the moment every rating in the game
## is walked. **A market where a man can be bought and immediately sold at a
## profit is not a market, it is a printer.**
func _test_selling_him_on() -> void:
	var worst := {"gap": 99, "tier": -1, "rating": -1}
	for t in League.TIERS.size():
		for r in range(1, 100):
			var gap: int = Market.fee(r, t) - Market.trade_value(r, t)
			if gap < int(worst["gap"]):
				worst = {"gap": gap, "tier": t, "rating": r}
	notes.append("across every rating in every division the closest a sale comes to its own fee is %d CC (a %d in the %s)"
		% [int(worst["gap"]), int(worst["rating"]),
			League.tier_name(int(worst["tier"]))])
	_ok(int(worst["gap"]) >= 1,
		"a man never sells for what he cost",
		"walked all four divisions at every rating 1-99; the tightest margin is %d CC"
			% int(worst["gap"]))

	## AND THE BUCKETS ARE FLAT, which is the arbitrage rather than a rounding
	## artifact. Within a tier every man fetches the same money however good he
	## is, so the skill is selling the bottom of a bucket and keeping the top —
	## and the check is that a dearer man really does fetch the SAME, not merely
	## a similar amount.
	var flat := true
	var seen := 0
	for t in League.TIERS.size():
		var by_tier: Dictionary = {}
		for r in range(int(Market.shelf_of(t)[0]), int(Market.shelf_of(t)[1]) + 1):
			var k := Market.trade_tier(r, t)
			if by_tier.has(k) and int(by_tier[k]) != Market.trade_value(r, t):
				flat = false
			by_tier[k] = Market.trade_value(r, t)
		seen += by_tier.size()
	## The seam has to be worth gaming: somewhere in the game a man who costs
	## MORE to sign must fetch the same as one who costs less, or the buckets are
	## decoration.
	var seam := false
	for t in League.TIERS.size():
		for r in range(int(Market.shelf_of(t)[0]), int(Market.shelf_of(t)[1])):
			if Market.trade_value(r, t) == Market.trade_value(r + 1, t) \
					and Market.fee(r + 1, t) > Market.fee(r, t):
				seam = true
	notes.append("%d sale buckets across the four divisions, all flat, and a dearer man fetching the same as a cheaper one: %s"
		% [seen, "yes" if seam else "no"])
	_ok(flat and seam and Market.TRADE_TIERS.size() == 3,
		"three flat buckets, and the edges are worth reading",
		"every man in a bucket fetches the same money however dear he was to sign")


## THE SHELF SPANS THREE DIVISIONS, AND A PLAYER CAN SEE WHICH.
##
## Pete, 15 Sep 2026: *"tier the free agents... A free agent won't bother being
## available if they aren't one league above or below the team's standing."*
## `Market._band_step` draws a third from below, half from your own and a sixth
## from above, and `tools/probe_shelf.gd` measured what comes out.
##
## Two things are held here and the second is the one that was missing for a day.
##
## The first is that the span is REAL: over a long run of summers a middle
## division has to put men on the shelf both under its floor and over its
## ceiling. A market drawn from one band is a shop.
##
## The second is that the span is VISIBLE. `step_word` is what the card prints,
## and it has to disagree with itself in the right places — blank at your own
## standard, "step up" above it, "depth" below. **A mechanic the player cannot
## see is not a mechanic, it is a random number**, and the market screen showed a
## rating and a price and neither of the two rules that produced them.
func _test_the_shelf_spans_three_divisions() -> void:
	## A MIDDLE DIVISION, because the ends of the ladder cannot span three: at
	## tier 0 the below-draw clamps up into your own band and at tier 3 the
	## above-draw clamps down, so asking either end for three divisions is asking
	## for a state the game does not have.
	var tier := 1
	var below := 0
	var above := 0
	var own := 0
	for season in range(1, 41):
		for f in Market.pool(4242, season, tier):
			match Market.step_of(f.overall(), tier):
				Market.Step.BELOW: below += 1
				Market.Step.ABOVE: above += 1
				_: own += 1
	notes.append("forty State League summers: %d men under the floor, %d at it, %d over it"
		% [below, own, above])
	_ok(below > 0 and above > 0 and own > below and own > above,
		"the shelf spans the division below, your own and the one above",
		"a middle division sees all three over forty summers, weighted to its own")

	## AND THE WORDS. Read off a rating against a band rather than off the draw,
	## so these are the exact strings the card puts in the header corner.
	var band: Array = League.TIERS[tier]["power"]
	var lo := int(band[0])
	var hi := int(band[1])
	_ok(Market.step_word(lo - 4, tier) == "backup"
			and Market.step_word((lo + hi) / 2, tier) == ""
			and Market.step_word(hi + 4, tier) == "step up",
		"the card's word for a man matches where he sits",
		"under the floor reads depth, inside it reads nothing, over it reads step up")

	## THE FEE BAND IS ON THE CARD TOO, and it is the half of the seam that does
	## the work: `BAND_SHARE` charges by bucket, so the skill is taking the man at
	## the TOP of a bucket. The screen printed the price and never the bucket.
	var names: Dictionary = {}
	for season in range(1, 41):
		for f in Market.pool(4242, season, tier):
			names[Market.band_name(f.overall(), tier)] = true
	_ok(names.size() >= 4,
		"a summer's shelf is not all one fee band",
		"forty summers of a State League shelf put men in %d of the %d bands"
			% [names.size(), Market.BAND_NAME.size()])


## EVERY REFUSAL THAT NAMES A DOOR HAS TO MEAN IT.
##
## `extend()` handles men with two or more years left, `resign()` handles men out
## of contract, and the man on his LAST year belongs to neither on purpose —
## `_test_the_fork_is_a_real_choice` explains why: if both doors took him, they
## would be one button with two prices and nobody would ever pick the dearer.
## His road is to let the deal run out and re-sign him out of contract, which is
## a state he sits in, visibly, for a whole season.
##
## That is fine. What was not fine is what the game SAID. `resign()` told every
## man still under contract to "Extend him instead", including the one man
## `can_extend` refuses — so the two refusals pointed at each other, and a
## manager who followed either did nothing at all. Both read like advice, which
## is what made it invisible: nothing errored, nothing looked stuck.
##
## **A refusal that names another door is a promise about that door.** This walks
## every legal length of deal and holds the game to it.
func _test_a_refusal_names_a_door_that_opens() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 24601)
	## A refusal here has to be about the DEAL and never the money, so the check
	## asserts the room rather than assuming it.
	var f: FighterCard = s.club.roster[0]
	## Since Pete's #13 (29 Sep) the cap BINDS — a starting club has little room —
	## so the test buys the room it needs in cap raises rather than assuming it.
	while ClubOffice.wage_bill(s.club) * 4 >= s.office.cap() and s.office.cap_level < 200:
		s.office.cap_level += 1
	_ok(ClubOffice.wage_bill(s.club) * 4 < s.office.cap(),
		"a starting club has room to renew anybody",
		"bill %d against a cap of %d" % [ClubOffice.wage_bill(s.club), s.office.cap()])
	var lied: Array[String] = []
	var open_now := 0
	var told := 0
	for years in range(0, Contracts.YEARS_MAX + 1):
		f.years = years
		var e: String = s.extend(f) if Contracts.can_extend(f) else "not offered"
		f.years = years
		var r := s.resign(f)
		if e == "" or r == "":
			open_now += 1
			continue
		## He cannot be renewed this winter. Then whatever he was told to do next
		## has to be a thing that works.
		told += 1
		if r.find("Extend him") >= 0:
			f.years = years
			if s.extend(f) != "":
				lied.append("%d years: sent to extend, which refused" % years)
		if e.find("Re-sign him") >= 0:
			f.years = years
			if s.resign(f) != "":
				lied.append("%d years: sent to re-sign, which refused" % years)
	_ok(lied.is_empty(), "every refusal that names the other door means it",
		"%d lengths renewable now, %d refused with advice%s" % [open_now, told,
			"" if lied.is_empty() else " — " + "; ".join(lied)])
	## AND THE LAST YEAR'S ROAD IS REAL — run the deal out, then re-sign. The
	## advice above is only honest if the state it points at arrives.
	f.years = 1
	Contracts.age_deals(s.club.roster)
	_ok(f.years == 0 and s.resign(f) == "",
		"and a deal run out can be re-signed the next winter",
		"one year -> out of contract -> re-signed")

func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


func _test_a_deal_does_not_move_when_the_man_does() -> void:
	## THE WHOLE POINT OF A CONTRACT. Improve a fighter by twenty points and the
	## club's wage bill must not move a dollar — and the market rate must, because
	## the gap between the two IS the value of the deal.
	var s := Season.new(MeleeRosters.starting_club(), 1234)
	var f: FighterCard = s.club.roster[0]
	var bill_before := ClubOffice.wage_bill(s.club)
	var market_before := ClubOffice.wage(f)
	f.strength = mini(99, f.strength + 20)
	f.base = mini(99, f.base + 20)
	f.skill = mini(99, f.skill + 20)
	f.gas = mini(99, f.gas + 20)
	var bill_after := ClubOffice.wage_bill(s.club)
	var market_after := ClubOffice.wage(f)
	notes.append("improving a man by 20 in every stat: bill %s -> %s, his market rate %s -> %s"
		% [ClubOffice.money(bill_before), ClubOffice.money(bill_after),
			ClubOffice.money(market_before), ClubOffice.money(market_after)])
	_ok(bill_after == bill_before and market_after > market_before,
		"a deal does not move when the man does",
		"the bill is the contract and the contract did not change; his price today did")


func _test_the_fork_is_a_real_choice() -> void:
	## Extending early must be CHEAPER per year than waiting, or there is no fork;
	## and it must not be so much cheaper that extending on day one is free money,
	## which is what an uncapped per-year discount would have made it.
	var rate := 1000
	var one := Contracts.extension(rate, 28, 1)
	var four := Contracts.extension(rate, 28, 4)
	var late := Contracts.offer(rate, 28)
	var floor_ok: bool = float(four) / float(late) >= 0.60

	## And a man in his last year cannot be extended at all — otherwise "extend"
	## and "re-sign" are the same button with two prices and the player simply
	## picks the cheaper one.
	var last := FighterCard.new()
	last.years = 1
	var mid := FighterCard.new()
	mid.years = 3
	notes.append("on a $1,000 market rate: re-sign %d, extend with 1 year left %d, with 4 left %d"
		% [late, one, four])
	_ok(four < one and one < late and floor_ok
			and not Contracts.can_extend(last) and Contracts.can_extend(mid),
		"the fork is a real choice",
		"the more of the deal you tear up the cheaper it is, bottoming at %d%% of market — and the last year cannot be extended"
			% int(round(100.0 * float(four) / float(late))))


func _test_the_rookie_discount() -> void:
	## A man nobody has seen fight signs cheap, and that is what makes the reserve
	## worth filling. Asserted against AGE rather than against newness: a
	## thirty-three-year-old free agent is not a rookie however new he is to your
	## books, and pricing him like one would make the market a shop for veterans.
	var rate := 1000
	var kid := Contracts.offer(rate, Contracts.ROOKIE_AGE)
	var man := Contracts.offer(rate, Contracts.ROOKIE_AGE + 1)
	var old := Contracts.offer(rate, 34)
	notes.append("a $1,000 man at %d costs %d; at %d he costs %d; at 34, %d"
		% [Contracts.ROOKIE_AGE, kid, Contracts.ROOKIE_AGE + 1, man, old])
	_ok(kid < man and man == old and man == rate,
		"the rookie discount",
		"under %d he signs at %d%% of market and everybody older signs at market"
			% [Contracts.ROOKIE_AGE + 1, int(round(Contracts.ROOKIE_RATE * 100.0))])


func _test_the_fee_is_by_band() -> void:
	## PETE'S SEAM, item 8: *"coarse tiers somewhere, so there is a seam to game."*
	## The fee is charged by band, so within a band a better fighter costs the
	## same — and the check that matters is that the bands are WIDE enough for
	## that to be worth noticing. A band one rating point across is not a seam.
	var line := ""
	var widest := 0
	var found_equal := false
	for t in League.TIERS.size():
		var range_: Array = League.TIERS[t]["power"]
		var counts := {}
		for r in range(int(range_[0]), int(range_[1]) + 1):
			var b := Market.band_of(r, t)
			counts[b] = int(counts.get(b, 0)) + 1
		for b in counts.keys():
			widest = maxi(widest, int(counts[b]))
		## Two different ratings, same band, same fee.
		var lo := int(range_[0]) + 1
		var hi := lo
		while hi < int(range_[1]) and Market.band_of(hi + 1, t) == Market.band_of(lo, t):
			hi += 1
		if hi > lo and Market.fee(lo, t) == Market.fee(hi, t):
			found_equal = true
		line += "%s %d-%d both %d CC   " % [String(League.TIERS[t]["short"]) \
			if League.TIERS[t].has("short") else String(League.TIERS[t]["name"]).substr(0, 3),
			lo, hi, Market.fee(lo, t)]
	## And the fee must actually climb, or the bands are decoration.
	var climbs := true
	for i in range(1, Market.BAND_SHARE.size()):
		if Market.BAND_SHARE[i] <= Market.BAND_SHARE[i - 1]:
			climbs = false
	notes.append("same fee across a band: " + line.strip_edges())
	_ok(found_equal and climbs and widest >= 4,
		"the fee is by band",
		"the widest band is %d rating points across, so the man at the top of one is the signing to find"
			% widest)


func _test_the_cap_is_the_wall() -> void:
	## Credits get you to the table; the CAP decides whether you can sit down.
	## Both refusals have to be real and they have to say the number — a screen
	## that says "you cannot afford him" without one is telling the player to go
	## and do arithmetic somewhere else.
	var s := Season.new(MeleeRosters.starting_club(), 777)
	var pool := s.market()
	var dear: FighterCard = pool[0]
	s.office.credits = 0
	var broke := s.sign_from_market(dear)
	s.office.credits = 500
	## Squeeze the cap to nothing and the same signing must be refused for a
	## different reason and with a different sentence.
	s.office.tier = 0
	var capped := ""
	var guard := 0
	while capped == "" and guard < 3:
		guard += 1
		for f in s.club.roster:
			f.wage_agreed = maxi(f.wage_agreed, s.office.cap() / 6)
		capped = s.sign_from_market(s.market()[0])
	notes.append("with no credits: \"%s\"" % broke)
	notes.append("with no cap room: \"%s\"" % capped)
	_ok(broke != "" and broke.contains("CC") and capped != ""
			and capped.contains("cap"),
		"the cap is the wall",
		"a signing needs both, and each refusal names the number that stopped it")


func _test_out_of_contract_is_a_state_not_an_exit() -> void:
	## THE TWO-STAGE SHAPE, and it is the difference between a fair game and a
	## squad that quietly shrinks. A deal reaching zero must NOT remove anybody —
	## it puts him out of contract, visible on the team sheet, for a whole season.
	## Only a man who was already out of contract and whom nobody re-signed walks.
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	## A YOUNG MAN ON PURPOSE. The roster's veterans can retire over the winter
	## this check rolls through, and a test that sometimes measures a retirement
	## instead of an expiry is a test that fails for the wrong reason once a year.
	var man: FighterCard = s.club.roster[0]
	for f in s.club.roster:
		if f.age < Career.RETIRE_FROM - 4:
			man = f
			break
	man.years = 1
	var name_ := man.display_name
	_roll(s)
	var still_here: bool = s.club.roster.has(man) and man.years == 0

	## Re-sign him and he is safe; the roll-over after must leave him alone.
	var err := s.resign(man)
	var back_on: bool = err == "" and man.years == Contracts.YEARS_NEW
	if not (still_here and back_on):
		notes.append("  (%s: on the books %s, years %d, re-sign said \"%s\")"
			% [name_, "yes" if s.club.roster.has(man) else "NO", man.years, err])
	_roll(s)
	var kept: bool = s.club.roster.has(man)

	## And a man left alone eventually does go — run until somebody walks, so the
	## check proves the exit exists rather than only proving the grace does.
	var t := Season.new(MeleeRosters.starting_club(), 5150)
	var walked := 0
	for _y in 12:
		_roll(t)
		walked += (t.last_winter.get("walked", []) as Array).size()

	notes.append("a deal running out left %s on the books at 0 years; re-signed for %d he survived the next summer"
		% [name_, Contracts.YEARS_NEW])
	notes.append("a club that re-signs nobody lost %d men on frees over 12 seasons" % walked)
	_ok(still_here and back_on and kept and walked > 0,
		"out of contract is a state, not an exit",
		"an expiring deal costs you nothing this summer and everything the next one")


func _roll(s: Season) -> void:
	while not s.ready_to_roll():
		if s.bid_open(): s.decline_bid()
		elif s.cup_pending(): s.sim_cup_tie()
		else: s.skip_event()
	s.roll_over()


func _test_the_pool_is_the_same_after_a_reload() -> void:
	## The market is generated from the world seed and the season rather than
	## stored, so what a save carries is who has been TAKEN out of it. If the list
	## came back different the player would reload and find the man he was saving
	## for had never existed, which is the same class of bug as a table that
	## re-sorts on reload.
	const SLOT := 0
	SaveGame.delete(SLOT)
	var s := Season.new(MeleeRosters.starting_club(), 90210)
	s.office.credits = 200
	## THE BOOKS START FULL AT THIRTEEN, so a signing is always a replacement —
	## the same thing Create-A-Player ran into. Cutting a reserve first is what a
	## player does, and doing it here keeps this check about the POOL rather than
	## about the squad limit, which MeleeClub already enforces and tests.
	var spare: Array = s.club.reserves()
	if not spare.is_empty():
		s.club.cut(spare[spare.size() - 1])
	var before := s.market()
	var names := ""
	for f in before:
		names += "%s/%d," % [f.display_name, f.overall()]
	## Take one, so the save is carrying a pool that has been dug into.
	var took := ""
	for f in before:
		if s.sign_from_market(f) == "":
			took = f.display_name
			break
	var after_sign := s.market().size()

	SaveGame.save(s, SLOT)
	var back := SaveGame.load_slot(SLOT)
	SaveGame.delete(SLOT)
	var reloaded := ""
	if back != null:
		for f in back.market():
			reloaded += "%s/%d," % [f.display_name, f.overall()]
	var same_pool: bool = back != null and back.market().size() == after_sign
	## And the man who was signed must not be back on the list.
	var gone: bool = took != "" and not reloaded.contains(took + "/")

	notes.append("pool of %d, signed %s, %d left — and %d left after a reload"
		% [before.size(), took, after_sign, back.market().size() if back != null else -1])
	if took == "":
		notes.append("  (nothing was signed — the pool check never got going)")
	_ok(same_pool and gone and took != "" and names != "",
		"the pool is the same after a reload",
		"the list regenerates identically and the man already signed does not come back")


func _test_the_cap_raise_has_no_ceiling() -> void:
	## Pete asked for the upgradable cap to work like Retro Bowl's, and two
	## measurements said the five-level version was wrong: a National club earning
	## 185 CC a season with nothing left to buy, and a club sitting on 1,100
	## unspent credits unable to sign anybody because its maxed cap had no room.
	## One surplus, one shortage, one missing feature.
	var o := ClubOffice.new()
	o.tier = 3
	o.credits = 100000
	var base := o.cap()
	var costs: Array[int] = []
	for _i in 20:
		costs.append(o.cap_cost())
		o.new_week()          ## one job per building per matchday
		if o.raise_cap() != "":
			break
	## STRICTLY DEARER, not merely not-cheaper. `costs[i] < costs[i - 1]` passes
	## a flat schedule — every raise the same price — which is exactly the thing
	## the check is named for catching. A rung that costs what the last one cost
	## is not a ladder.
	var climbs := costs.size() > 1
	for i in range(1, costs.size()):
		if costs[i] <= costs[i - 1]:
			climbs = false
	var spent := 100000 - o.credits
	notes.append("twenty raises cost %d CC in total, the twentieth alone %d, and the cap went %s -> %s"
		% [spent, costs[costs.size() - 1], ClubOffice.money(base), ClubOffice.money(o.cap())])
	_ok(o.cap_level == 20 and climbs and o.cap() > base
			and costs[costs.size() - 1] > costs[0] * 4,
		"the cap raise has no ceiling",
		"twenty raises went through and the price kept climbing — a sink that absorbs a surplus without ever being the obvious buy")
