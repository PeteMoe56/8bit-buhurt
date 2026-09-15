extends SceneTree
## A WHOLE CAREER, PLAYED HONESTLY, AT EVERY DIFFICULTY.
##
##   godot --headless --path . --script res://tools/probe_run.gd
##
## Pete, 15 Sep 2026: *"let's have you do some career Sims and lets find a good
## balance for the all the features and difficulties. There's a lot of career
## variables now."*
##
## ---------------------------------------------------------------------------
## WHAT MAKES THIS DIFFERENT FROM THE PROBES ALREADY HERE.
##
## `probe_climb.gd` walks fourteen seasons and tops the club up **120 credits a
## year** so that its three managers differ only in how they spend. That was the
## right fixture for its question — does spending do anything at all — and it is
## the wrong one for this, because a subsidy of 120 is roughly twice a Backyard
## club's whole income. It cannot see an economy.
##
## `probe_afford.gd` measures one year in one division with the club held at a
## stated standard. It answers "can a club at this level pay its bills" and
## cannot answer "does a career work", because a career is the climb.
##
## **This one spends only what it earns.** No top-ups. The manager is a policy —
## the obvious moves in the obvious order, which is what a competent player does
## — and the question is whether the game lets him get anywhere.
##
## ---------------------------------------------------------------------------
## WHAT IT REPORTS, AND WHY THESE FIVE.
##
##   TOP       the highest division reached, averaged. The headline: a career
##             that ends where it started is not a career.
##   YRS/UP    seasons per promotion. Retro Bowl's whole shape is "one good year
##             gets you up", and a ladder that takes eight is a wall.
##   BANK      what the club is sitting on at the end of an average year. A big
##             number means the sinks are too small or too throttled to absorb
##             the income; a number pinned at zero means the club is broke.
##   LOST      buildings shed because the summer bill could not be paid, per
##             career. This is Pete's *"you'll decline"* with a number on it —
##             it is the only failure state the economy has.
##   GAP       the club's rating minus the division leader's, at the end. Says
##             whether the squad kept pace with the company it climbed into.
##
## Nothing here changes a constant. It prints a table.

const YEARS := 20
const SEEDS: Array[int] = [4242, 90210, 31337, 777, 24601]
## HOW BIG A SURPLUS BUYS LEVELS AT ALL. Levels are the last thing on the list
## and this is the line above which they are worth having: enough left over that
## the club is not about to want it for a ground, a cap raise or a signing.
const LEVEL_FLOAT := 25
## WHAT A MANAGER KEEPS BACK FOR THE MARKET. A Backyard signing is 11 to 18
## credits and the market is the only road up the pyramid, so this is the last
## money the policy spends rather than the first.
const KITTY := 20
## HOW MANY MEN THE POLICY KEEPS ON THE BOOKS. Thirteen is what the game hands
## you at the start — eight who travel and five in reserve — so it is the squad
## the rest of the design is written against.
const SQUAD_WANT := 13


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — twenty seasons, spending only what it earns ===\n")
	print("%-13s %5s %6s %6s %7s %7s %6s %6s %6s %6s" % [
		"difficulty", "TOP", "yrs/up", "pos", "income", "spent", "bank", "lost",
		"gap", "cups"])
	for g in Grade.ORDER:
		_run(g)
	_books()
	print("")
	print("TOP    highest division reached (0 Backyard, 3 National), mean of %d careers"
		% SEEDS.size())
	print("yrs/up seasons per promotion — blank if the career never went up")
	print("pos    where it finished, 0.00 champions and 1.00 bottom of the division")
	print("income/spent  per season, off the club's own books")
	print("bank   credits in hand at the end of an average season")
	print("lost   buildings shed because a summer bill went unpaid, per career")
	print("gap    club rating minus the division leader's, at the end")
	print("")
	quit(0)


func _run(grade: int) -> void:
	var tops: Array[float] = []
	var ups: Array[float] = []
	var income := 0.0
	var spent := 0.0
	var bank := 0.0
	var lost := 0.0
	var gaps: Array[float] = []
	var cups := 0.0
	var years := 0
	## WHERE THE CLUB ACTUALLY FINISHES, as a share of the division — 0.0 is
	## champions and 1.0 is bottom. A raw position cannot be averaged across
	## divisions of six and sixteen, and averaging it anyway is how a club that
	## came third of six and eighth of sixteen reads as "5.5th".
	var place := 0.0
	for seed_v in SEEDS:
		var s := Season.new(MeleeRosters.starting_club(), seed_v)
		Session.season = s
		s.set_grade(grade)
		var top := 0
		var promotions := 0
		var was := s.world.player_tier()
		for y in YEARS:
			_winter(s)
			_season(s)
			var field := maxi(2, League.club_count(s.world.player_tier()))
			place += float(s.position() - 1) / float(field - 1)
			## READ BEFORE THE ROLL, because `roll_over()` is where promotion
			## happens and where the summer is paid: the books are closed inside
			## it and the tier changes inside it.
			s.roll_over()
			var now := s.world.player_tier()
			if now > was:
				promotions += 1
			was = now
			top = maxi(top, now)
			var last: Dictionary = s.office.books_last
			income += float(ClubOffice.book_total(last.get("in", {})))
			spent += float(ClubOffice.book_total(last.get("out", {})))
			bank += float(s.office.credits)
			lost += float((s.last_upkeep.get("lost", []) as Array).size())
			lost += float((s.last_upkeep.get("lapsed", []) as Array).size())
			years += 1
		tops.append(float(top))
		ups.append(float(promotions))
		cups += float(_cups_won(s))
		gaps.append(float(_gap(s)))
	var n := float(maxi(1, years))
	var runs := float(SEEDS.size())
	var up_total := _sum(ups)
	print("%-13s %5.1f %6s %6.2f %7.1f %7.1f %6.0f %6.2f %6.1f %6.2f" % [
		Grade.name_of(grade), _sum(tops) / runs,
		"—" if up_total <= 0.0 else "%.1f" % (float(YEARS) * runs / up_total),
		place / n, income / n, spent / n, bank / n, lost / runs,
		_sum(gaps) / runs, cups / runs])


## ---------------------------------------------------------------- the manager
## THE WINTER, IN THE ORDER A PLAYER ACTUALLY DOES IT.
##
## Contracts first, because a man who walks costs more than anything else on the
## list; then the levels his men worked for, because an unspent level is training
## thrown away; then the kit, because a harness under the line cannot go out at
## all; then the ground; then growth with whatever is left.
##
## THE ORDER IS THE POLICY AND IT IS DELIBERATELY NOT OPTIMAL. A solver would
## tell us what the best possible manager can extract, which is not a thing any
## player is; this is the obvious moves in the obvious order, and if the game
## does not work for him it does not work.
func _winter(s: Season) -> void:
	for f in s.club.roster:
		if Contracts.can_extend(f):
			s.extend(f)
		else:
			s.resign(f)

	## AND REPLACE WHOEVER IS GONE. A summer takes retirements and walkouts; a
	## manager who does not sign is a manager whose squad is smaller every year.
	_market_moves(s)

	## THE LEVELS, AND THE FREE ONES FIRST. Two steps and they are in this order
	## for a reason the first cut of this probe got wrong: `buy_level()` REFUSES a
	## man who already has a level waiting — *"%s already has a level waiting.
	## Spend it."* — so a loop that buys-then-places breaks out on that refusal
	## and never places the level the man had earned by fighting. Every point the
	## squad worked for was being thrown away and the career was being charged for
	## the privilege.
	##
	## **A refusal that means "you do not need to pay for this" and a refusal that
	## means "you cannot have this" are not the same answer**, and a caller that
	## treats them alike loses the free one every time.
	for f in s.club.roster:
		_place_all(f)


## SPEND EVERY POINT HE HAS WAITING. `Career.level_up` places one; a man who
## fought a full season and was bought a level can be holding two.
static func _place_all(f: FighterCard) -> void:
	var guard := 0
	while Career.can_level(f) and not Career.at_ceiling(f) and guard < 6:
		guard += 1
		Career.level_up(f)


## AND THE WEEK, run before every event: the things a club does between fights.
func _week(s: Season) -> void:
	var o := s.office
	## THE HARNESSES, worst first — a man who cannot pass inspection cannot go
	## out, which is worth more than any other credit on this list.
	var men: Array = s.club.roster.duplicate()
	men.sort_custom(func(a, b): return a.armor < b.armor)
	for f in men:
		if o.credits < 3:
			break
		o.repair_kit(f)
	## THE GROUND, once it is visibly going. Not every week: at `SHABBY` the
	## overlay is showing and the retainer has already slid, which is the point
	## a player would notice and act.
	if o.arena.shabby() and o.credits > o.arena.upkeep_cost() * 3:
		o.tidy_arena()
	## THE FREE LEVELS, ALWAYS. Placing a point a man earned by fighting costs
	## nothing and is pure gain; there is no version of a manager who leaves those
	## sitting.
	for f in s.club.roster:
		_place_all(f)

	## AND THEN GROWTH, IN THE ORDER OF WHAT IT IS WORTH, which is the last thing
	## this policy got wrong and the most instructive.
	##
	## The previous cut bought levels here, before anything else, and the books
	## came back: **36.9 of a 40.2-credit season went on "The squad" — 92 per
	## cent — and the club never built an arena in twenty years.** Levels are
	## cheap and always available, so a manager who buys them whenever he can
	## afford one never accumulates the twelve credits for a Fenced Ground, and
	## the gate stays at back-field money forever.
	##
	## Priced against what `probe_dev.gd` and `probe_market2.gd` measured:
	##
	##   a signing      11-18 CC   +3 to +6 club power
	##   an arena       6-22 CC    every home gate, forever
	##   a level        4-40 CC    +0.05 club power
	##
	## A level is worth about a hundredth of a signing and can cost more. So the
	## ground and the market come first and levels take what is left — and that
	## ordering is the single change that takes this manager from finishing 60%
	## down his division to competing in it.
	##
	## **This is also the finding, not just the fixture.** A player has no way to
	## know any of that: the level-up screen shows an XP bar and a price, which
	## reads like the upgrade it is not.
	## THE GROUND FIRST AND THE FACILITIES LAST, WITH A TRANSFER KITTY HELD BACK.
	##
	## The order was right and the reserve was not. `probe_run` measured a career
	## spending **8.3 credits a season on facilities and 0.2 on the squad** — the
	## manager was buying training grounds every week, so by the time the winter
	## came round there was never a signing's worth in the bank, and a signing is
	## worth three to six club power against a facility's nothing-you-can-measure.
	##
	## A player does not do that. He keeps a float for the market, because the
	## market is where a squad comes from. `KITTY` is roughly one Backyard signing
	## and it is held back from everything except the ground — the ground is the
	## one purchase that pays for itself.
	var float_ := _reserve(s)
	if o.credits > float_ + o.arena.next_cost():
		o.build_arena()
	if o.credits > float_ + KITTY + o.cap_cost():
		o.raise_cap()
	if o.credits > float_ + KITTY + o.travel_cost():
		o.buy_travel_slot()
	for fac in [ClubOffice.Facility.TRAINING, ClubOffice.Facility.INFIRMARY]:
		if o.credits > float_ + KITTY + o.facility_cost(fac):
			o.upgrade(fac)

	## AND THE LEVELS LAST, out of what a season did not need. The throttle is per
	## week, so a five-event season is five chances at a man.
	if o.credits > float_ + LEVEL_FLOAT:
		var by_cost: Array = s.club.roster.duplicate()
		by_cost.sort_custom(func(a, b): return Career.level_cost(a) < Career.level_cost(b))
		for f in by_cost:
			if o.credits <= float_ + LEVEL_FLOAT:
				break
			if o.buy_level(f) == "":
				_place_all(f)


## HOW MUCH A SENSIBLE MANAGER KEEPS BACK. The summer bill plus a season's
## repairs, roughly — a club that spends into its upkeep sheds a building, and
## that is a mistake a player makes once.
func _reserve(s: Season) -> int:
	return s.office.upkeep_bill() + 8


func _season(s: Season) -> void:
	var guard := 0
	while not s.season_complete() and guard < 60:
		guard += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid":
					## HOST WHEN IT PAYS AND THE CLUB CAN CARRY IT. The preview is
					## honest about the net, so a manager who reads it takes the
					## date when the number is positive and he is not spending his
					## upkeep to do it.
					var took := false
					for i in 3:
						var p: Dictionary = s.bid_preview(i, 1)
						if int(p["net"]) > 0 and s.office.credits \
								> int(p["cost"]) + _reserve(s):
							if s.take_bid(i, 1) == "":
								took = true
								break
					if not took:
						s.decline_bid()
				"dilemma":
					s.answer_dilemma(0)
				"promotion":
					## TAKE IT WHEN THE CLUB CAN CARRY THE BIGGER BILL, stay down
					## when it cannot. Pete, 15 Sep 2026: *"A player may bust
					## through the season but want to stay a season and continue
					## building up their money."*
					##
					## The rule is the obvious one and it is the whole point of
					## the feature being a choice: go up if the club can pay the
					## new division's entry fee and still have something left.
					var t: Dictionary = s.promotion_terms()
					s.answer_promotion(s.office.credits
						>= int(t["dues_up"]) + _reserve(s))
				"cup":
					s.sim_cup_tie()
		if s.season_complete() and s.blocked_by() == "":
			break
		if s.season_complete():
			continue
		_week(s)
		s.skip_event()


func _cups_won(s: Season) -> int:
	var n := 0
	for h in s.honors():
		if int(h.get("champion", -1)) == s.world.player_club:
			n += 1
	return n


func _gap(s: Season) -> int:
	var tbl: Array = s.world.table(s.world.player_tier())
	if tbl.is_empty():
		return 0
	var top := int(s.world.clubs[int(tbl[0]["club"])]["power"])
	return int(s.world.clubs[s.world.player_club]["power"]) - top


static func _sum(a: Array[float]) -> float:
	var t := 0.0
	for x in a:
		t += x
	return t

## ------------------------------------------------------------ the transfers
## SIGN TO IMPROVE, NOT ONLY TO FILL A GAP. This is the half the first two cuts
## of the policy got wrong, and getting it wrong is what made the ladder look
## unclimbable.
##
## The measurements, in order:
##
##   `probe_dev.gd` — with the price and the throttle both removed, 245 levels
##   over twelve seasons are worth **+4 club power**. `power_exact()` is the mean
##   of the STARTING FIVE and a level is one point on one of four stats, so a
##   level is 0.05 of a club rating — and nothing at all on a reserve or on a man
##   already at his ceiling.
##
##   `probe_market2.gd` — the squad you are given has four of its five starters
##   within six points of their ceiling (Brand 37/38, Norrey 41/42), and the
##   Backyard shelf has a **44-rated 25-year-old with a ceiling of 55 for eleven
##   credits** against an income of thirty-three a season.
##
## So one signing is worth about a hundred levels, and the first version of this
## manager spent every credit on levels and only signed when somebody retired.
## **A policy that cannot see the cheapest road is a policy that measures the
## road it took.** It was not finding that the game was unclimbable; it was
## finding that training is not how you climb it, which is true of every football
## manager ever made and is a fact about the game rather than a fault in it.
##
## What this does now is what a player does: look at the list, look at your five,
## sign the man who is better than one of them.
func _market_moves(s: Season) -> int:
	var signed := 0
	var guard := 0
	while guard < 6:
		guard += 1
		var pool: Array = s.market()
		if pool.is_empty():
			break
		## BEST FIRST, because the fee is banded — within a band a better fighter
		## costs the same, which is the seam this market is built around and the
		## reason reaching high is usually right.
		pool.sort_custom(func(a, b): return a.overall() > b.overall())
		var took := false
		for f in pool:
			if s.office.credits <= _reserve(s) + s.market_fee(f):
				continue
			## IS HE BETTER THAN WHAT WE HAVE? Against the weakest of the five
			## when the squad is full, and against nothing at all when it is short
			## — a club with eleven men needs bodies before it needs upgrades.
			if s.club.roster.size() >= SQUAD_WANT and f.overall() <= _weakest(s) + 1:
				continue
			## MAKE ROOM FIRST, BOTH KINDS. `sign_from_market` refuses two
			## different ways and the first cut of this policy cut AFTERWARDS, so
			## neither refusal ever cleared:
			##
			##   "The books are full at 13. Cut somebody first."
			##   "Lowe wants $6 a week. That puts you $150 over the cap."
			##
			## The second is the one that matters and it is the relegation
			## trapdoor. `TIER_CAP` is [200, 2600, 34000, …] — thirteen times a
			## division — so a club that goes up, signs State League men to
			## survive and comes straight back down is carrying a wage bill
			## **seventy-five per cent over its new cap**, cannot sign anybody
			## ever again, and decays. `probe_ladder.gd` traced exactly that: up
			## in year 6, down in year 7, and then four seasons of refusals while
			## the squad fell from twelve men to six.
			##
			## A player facing that cuts his most expensive man. So does this.
			_make_room(s, f)
			if s.sign_from_market(f) != "":
				continue
			signed += 1
			took = true
			break
		if not took:
			break
	return signed


## CUT UNTIL HE FITS, on both counts, and never below a bench.
##
## The dearest man out of the five goes first when it is the cap that blocks,
## and the worst man on the books goes when it is the roster size — those are
## two different problems and cutting the worst man does not fix a wage bill.
func _make_room(s: Season, want: FighterCard) -> void:
	var guard := 0
	while guard < 8 and s.club.roster.size() > 6:
		guard += 1
		var over: bool = ClubOffice.wage_bill(s.club) + s.market_wage(want) \
			> s.office.cap()
		var full: bool = s.club.roster.size() >= SQUAD_WANT
		if not over and not full:
			return
		var five: Array = s.club.starting_five()
		var go: FighterCard = null
		for c in s.club.roster:
			if five.has(c) and not over:
				continue          ## never cut a starter to make a squad slot
			if go == null:
				go = c
			elif over and ClubOffice.billed(c) > ClubOffice.billed(go):
				go = c
			elif not over and c.overall() < go.overall():
				go = c
		if go == null or s.release(go) != "":
			return


## THE WEAKEST MAN ON THE LINE — the bar a signing has to clear. Read off the
## five rather than off the whole book, because the five are what `power_exact()`
## averages and a better sixteenth man changes nothing.
func _weakest(s: Season) -> int:
	var five: Array = s.club.starting_five()
	if five.is_empty():
		return 0
	var lo := 999
	for f in five:
		lo = mini(lo, f.overall())
	return lo


## ---------------------------------------------------------------- the books
## AND WHERE THE MONEY WENT, by heading, across a whole career.
##
## The table above says the club spends 40 of its 42 credits a season and
## finishes 60% of the way down its division — so it is not hoarding and it is
## not winning, which means the spending is going somewhere that does not move
## the table. `probe_dev.gd` has already shown that levels are worth 0.05 club
## power each and `probe_market2.gd` that one signing is worth three to six.
##
## **A club that spends its whole income on the cheap thing cannot afford the
## thing that works.** This prints the split so that sentence has numbers.
func _books() -> void:
	print("")
	print("=== where a career's money goes, per season ===")
	print("")
	var in_ := {}
	var out := {}
	var years := 0
	for seed_v in SEEDS:
		var s := Season.new(MeleeRosters.starting_club(), seed_v)
		Session.season = s
		s.set_grade(Grade.DEFAULT)
		for y in YEARS:
			_winter(s)
			_season(s)
			s.roll_over()
			var last: Dictionary = s.office.books_last
			for k in (last.get("in", {}) as Dictionary).keys():
				in_[k] = float(in_.get(k, 0.0)) + float(last["in"][k])
			for k in (last.get("out", {}) as Dictionary).keys():
				out[k] = float(out.get(k, 0.0)) + float(last["out"][k])
			years += 1
	var n := float(maxi(1, years))
	print("  IN")
	for r in ClubOffice.book_rows(in_, ClubOffice.IN_ORDER):
		print("    %-18s %6.1f" % [String(r["line"]), float(r["cc"]) / n])
	print("  OUT")
	for r in ClubOffice.book_rows(out, ClubOffice.OUT_ORDER):
		print("    %-18s %6.1f" % [String(r["line"]), float(r["cc"]) / n])
	print("")
