extends SceneTree
## WHERE A PROMOTION IS ACTUALLY LOST.
##
##   godot --headless --path . --script res://tools/probe_pace.gd
##
## Pete, 15 Sep 2026: *"20 seasons is a bit much, that should be about 10 for an
## above average player."* `probe_shelf` has the competent manager reaching TOP
## 0.8 in twenty seasons — barely out of the Backyard Circuit — and the target is
## three promotions in ten.
##
## THE POINT OF THIS PROBE IS NOT TO CONFIRM THAT. It is to find out WHICH of the
## two possible causes it is, because they want opposite fixes:
##
##   THE SQUAD NEVER GETS BETTER   the club's rating flatlines or slides against
##                                 its division, in which case the market, the
##                                 money or the attrition is the problem.
##   THE SQUAD GETS BETTER AND     the rating keeps pace and the club still
##   THE TABLE IGNORES IT          finishes mid-table, in which case the problem
##                                 is between `power()` and the league table and
##                                 no amount of signing will fix it.
##
## `docs/ONE-NUMBER-15-SEP.md` already flagged the second as a suspicion —
## *"`pos` sits ~0.78 at the default grade, the club finishes bottom-half more
## often than its -5 rating gap suggests"* — and a suspicion is not a
## measurement. So this prints them side by side, season by season.
const YEARS := 20
const SEEDS: Array[int] = [4242, 90210, 31337, 777, 24601]
const LEVEL_FLOAT := 25
const KITTY := 20


## TWO MANAGERS, BECAUSE PETE'S TARGET IS ABOUT A GOOD ONE.
##
## *"Getting a team to go from whatever is lowest to 99 should be around 10
## seasons for great players."* A probe that only plays the obvious moves cannot
## answer that — it measures the floor of the design, not the ceiling. So the
## same twenty seasons are played twice:
##
##   COMPETENT   signs the man who is worth most over the next six years, starts
##               his best five, keeps the ground up. The obvious moves.
##   YOUTH       signs for the CEILING rather than the six-year average, cuts
##               the old rather than the weak, and spends its surplus buying
##               ceiling on men who have years to use it. Eats some mid-table
##               seasons on purpose.
##
## The gap between the two lines is what skill is worth in this game, which is a
## thing worth knowing on its own.
var youth: bool = false


func _initialize() -> void:
	print("\n######## THE OBVIOUS MOVES ########")
	youth = false
	_curve()
	print("\n######## PLAYING FOR THE CEILING ########")
	youth = true
	_curve()
	if not "--curve-only" in OS.get_cmdline_user_args():
		_table_vs_power()
	quit(0)


## ------------------------------------------------------------ the curve
func _curve() -> void:
	print("\n=== the competent manager, season by season ===\n")
	print("%6s %6s %7s %7s %7s %7s %6s %6s %6s %6s %6s %6s" % [
		"season", "tier", "power", "leader", "mid", "finish", "up", "CC",
		"signed", "age", "ceil", "under"])
	var rows: Array = []
	for _y in YEARS:
		rows.append({"tier": 0.0, "power": 0.0, "lead": 0.0, "mid": 0.0,
			"pos": 0.0, "up": 0.0, "cc": 0.0, "sign": 0.0, "age": 0.0,
			"raise": 0.0, "under": 0.0, "n": 0.0})
	for seed_v in SEEDS:
		var s := Season.new(MeleeRosters.starting_club(), seed_v)
		Session.season = s
		var was := s.world.player_tier()
		for y in YEARS:
			var took := _winter(s)
			raised = 0
			_season(s)
			var t := s.world.player_tier()
			var r: Dictionary = rows[y]
			r["cc"] += float(s.office.credits)
			r["sign"] += float(took)
			r["raise"] += float(raised)
			## HOW MANY OF THE FIVE ARE BELOW THE DIVISION'S OWN FLOOR.
			##
			## Pete, 15 Sep 2026: *"When the team raises up a tier, so does the
			## tier of fighters in the free agency. So if they're holding onto
			## Tier one fighters, they're wrong."* `Season.market()` reads
			## `world.player_tier()` live, so the shelf and the fees both move up
			## the day a club is promoted — the mechanism is already there. This
			## is the other half of the sentence: whether the manager ACTS on it,
			## counted as men on the line who would not make the division's band.
			var floor_: int = int(League.TIERS[t]["power"][0])
			for c in s.club.starting_five():
				if c.overall() < floor_:
					r["under"] += 1.0
			var years := 0.0
			for f in s.club.starting_five():
				years += float(f.age)
			r["age"] += years / 5.0
			r["tier"] += float(t)
			r["power"] += float(s.club.power())
			r["lead"] += float(_leader(s))
			r["mid"] += float(_mid(s))
			## THE FINISH AS A FRACTION OF THE DIVISION, because the divisions are
			## six, eight, twelve and sixteen clubs and "fourth" means four
			## different things across them. 0.0 is champion, 1.0 is bottom.
			var tbl: Array = s.world.table(t)
			var pos := s.world.player_position()
			r["pos"] += float(pos - 1) / float(maxi(1, tbl.size() - 1))
			s.roll_over()
			if s.world.player_tier() > was:
				r["up"] += 1.0
			was = s.world.player_tier()
			r["n"] += 1.0
	for y in YEARS:
		var r: Dictionary = rows[y]
		var n: float = maxf(1.0, float(r["n"]))
		print("%6d %6.1f %7.1f %7.1f %7.1f %7.2f %6.1f %6.1f %6.1f %6.1f %6.1f %6.1f" % [
			y + 1, r["tier"] / n, r["power"] / n, r["lead"] / n, r["mid"] / n,
			r["pos"] / n, r["up"] / n, r["cc"] / n, r["sign"] / n, r["age"] / n,
			r["raise"] / n, r["under"] / n])
	print("")
	print("tier     0 Backyard, 3 National        power   the club's rating")
	print("leader   the best club in the division  mid     the division's median")
	print("finish   0.00 champion, 1.00 bottom     up      promotions that summer")
	print("CC       credits in hand at the final whistle")
	print("signed   men taken off the shelf that winter")
	print("age      mean age of the five who start")
	print("ceil     ceiling points bought that season")
	print("under    men ON THE LINE rating below the division's own floor")
	print("")


## ------------------------------------------------- does the table follow power?
## THE SECOND QUESTION, ASKED WITHOUT A MANAGER IN THE WAY.
##
## A club is planted at a stated rating against a division and the season is
## simmed. If the table follows the rating, a club rated above the leader wins
## the division most years. If it does not, the promotion problem is not an
## economy problem and no amount of money will touch it.
func _table_vs_power() -> void:
	print("=== where a club of a given rating actually finishes ===\n")
	print("%-19s %8s %8s %8s %8s" % ["division", "vs leader", "finish", "top two", "seasons"])
	for t in League.TIERS.size():
		for delta in [-6, 0, 6]:
			var pos := 0.0
			var up := 0.0
			var n := 0.0
			for seed_v in SEEDS:
				var s := _planted(t, delta, seed_v)
				for _y in 4:
					_season(s)
					var tbl: Array = s.world.table(s.world.player_tier())
					var p := s.world.player_position()
					pos += float(p - 1) / float(maxi(1, tbl.size() - 1))
					if p <= int(League.TIERS[s.world.player_tier()]["up"]):
						up += 1.0
					n += 1.0
					## Re-plant rather than roll over: the question is about ONE
					## rating against ONE division, and a promotion would move the
					## club out of the division being measured half way through.
					s = _planted(t, delta, seed_v + int(n))
			print("%-19s %8d %8.2f %7.0f%% %8d" % [
				League.tier_name(t) if delta == -6 else "", delta,
				pos / maxf(1.0, n), 100.0 * up / maxf(1.0, n), int(n)])
	print("")
	print("vs leader  the club's rating minus the best club's in that division")
	print("finish     0.00 champion, 1.00 bottom")
	print("top two    share of seasons finishing in a promotion place")
	print("")


## A CLUB OF A STATED RATING, PLANTED IN A STATED DIVISION. Same swap that
## `probe_wallet.gd` uses to get there — the only move that leaves every
## division's club count the shape the world's own soak test insists on.
func _planted(tier: int, delta: int, seed_v: int) -> Season:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	Session.season = s
	var here: Array = s.world.clubs_in(tier)
	if not here.is_empty():
		var other: int = int(here[0])
		s.world.clubs[other]["tier"] = s.world.player_tier()
		s.world.clubs[s.world.player_club]["tier"] = tier
		s.world._new_season()
	s.office.tier = s.world.player_tier()
	var want: int = _leader(s) + delta
	for _pass in 60:
		var now: int = s.club.power()
		if now == want:
			break
		var step := 1 if now < want else -1
		for f in s.club.roster:
			f.strength = clampi(f.strength + step, 1, 99)
			f.base = clampi(f.base + step, 1, 99)
			f.skill = clampi(f.skill + step, 1, 99)
			f.gas = clampi(f.gas + step, 1, 99)
	## THE WORLD READS THE PLAYER'S RATING OUT OF ITS OWN CLUB TABLE when it sims
	## a fixture he is not in and when it drifts ratings — so a squad walked to a
	## number while the world still believes the old one is a club that is strong
	## on the roster screen and weak in the league. Kept in step here explicitly.
	s.world.clubs[s.world.player_club]["power"] = s.club.power()
	return s


func _leader(s: Season) -> int:
	var tbl: Array = s.world.table(s.world.player_tier())
	var best := 0
	for r in tbl:
		best = maxi(best, int(s.world.clubs[int(r["club"])]["power"]))
	return best


func _mid(s: Season) -> int:
	var tbl: Array = s.world.table(s.world.player_tier())
	var all: Array[int] = []
	for r in tbl:
		all.append(int(s.world.clubs[int(r["club"])]["power"]))
	all.sort()
	return all[all.size() / 2] if not all.is_empty() else 0


# ------------------------------------------------------------- the manager
## THE SAME POLICY `probe_run.gd` PLAYS, trimmed to what this probe needs. Kept
## here rather than imported because the two probes answer different questions
## and a shared manager is a shared assumption neither one is checking.
## THE SUMMER AFTER A PROMOTION IS NOT AN ORDINARY SUMMER.
##
## Pete, 15 Sep 2026: *"When the team raises up a tier, so does the tier of
## fighters in the free agency. So if they're holding onto Tier one fighters,
## they're wrong."* `Season.market()` reads `world.player_tier()` live, so the
## shelf and the fees both move the day a club goes up — the mechanism is there
## and the manager was not using it. `probe_pace` caught it plainly: at the
## promotion in season 18 the club's signings **fell to 0.8** while its bank rose
## to 68 credits. It went shopping LESS in the one summer it should have gone
## most.
##
## Two things make an ordinary summer wrong here. The reserve is sized off the
## dues, which just doubled, so the manager holds back more money at the moment
## it is worth least; and the bar for a signing is "better than my weakest
## starter", which is a bar set by the division he has just LEFT.
var was_tier: int = -1


func _winter(s: Season) -> int:
	var now := s.world.player_tier()
	var went_up: bool = was_tier >= 0 and now > was_tier
	was_tier = now
	for f in s.club.roster:
		if Contracts.can_extend(f):
			s.extend(f)
		else:
			s.resign(f)
	var took := _market(s, went_up)
	_staff(s)
	for f in s.club.roster:
		_place_all(f)
	## AND PUT THE BEST MEN ON THE LINE. Roster order is the depth chart and a
	## signing lands at the END of it, so a manager who does not do this signs
	## better men and never plays them — see `MeleeClub.best_line`.
	s.club.best_line()
	return took


static func _place_all(f: FighterCard) -> void:
	var g := 0
	while Career.can_level(f) and not Career.at_ceiling(f) and g < 6:
		g += 1
		Career.level_up(f)


## THE MARKET, THE WAY A PLAYER WITH MONEY WORKS IT.
##
## The pool is six men and it is FIXED for the summer, so a loop that reads it
## five times reads the same six men five times. That is why `probe_pace`
## measured a club sitting on sixty-five credits it never spent: it was not
## refusing to buy, it had nothing on the board worth buying and no way to ask
## for a different board.
##
## `ClubOffice.refresh_market` is three credits. A club with real money turns the
## list over until something on it is a clear upgrade — that is what the button
## is FOR, and a manager who never presses it is a manager whose surplus does
## nothing. Bounded, because a probe that spins is a probe that hangs.
const LOOKS := 14
func _market(s: Season, went_up: bool = false) -> int:
	var took := 0
	var guard := 0
	while guard < LOOKS:
		guard += 1
		var pool: Array = s.market()
		if pool.is_empty():
			return took
		pool.sort_custom(func(a, b): return _value(a) > _value(b))
		var lo := 999
		for c in s.club.starting_five():
			lo = mini(lo, _value(c))
		## AND AFTER A PROMOTION THE BAR IS THE NEW DIVISION, not the old squad.
		## A man who beats your weakest starter is an upgrade on a club that has
		## just been outclassed; the question in this summer is whether he can
		## hold a place in the company you have joined.
		if went_up:
			lo = maxi(lo, int(League.TIERS[s.world.player_tier()]["power"][0]))
		var keep := s.office.upkeep_bill() + League.dues_for(s.office.tier) \
			+ (0 if went_up else 8)
		var hit := false
		for f in pool:
			if s.office.credits <= keep + s.market_fee(f):
				continue
			if s.club.roster.size() >= 13 and _value(f) <= lo + 1:
				continue
			_make_room(s, f)
			if s.sign_from_market(f) != "":
				continue
			took += 1
			hit = true
			break
		if not hit:
			if s.office.credits > keep + ClubOffice.REFRESH_COST * 4 \
					and s.office.refresh_market() == "":
				continue
			return took
		## AND AFTER A SIGNING, LOOK AGAIN — at a NEW list. The man just taken is
		## gone from the old one and the rest of it has already been judged, so
		## re-reading it is the same refusal twice. A club that can still afford a
		## second signing should be shown a second shelf.
		if s.office.credits > keep + ClubOffice.REFRESH_COST * 6:
			s.office.refresh_market()
	return took


## THE CAPTAINS, WHICH THIS PROBE DID NOT HIRE FOR TWENTY SEASONS.
##
## Pete's practice week — *"the better the coaches, the more you get out of
## practice"* — is a staff investment, and `ClubOffice.coaching()` returns 0 for
## a club with nobody on the payroll. So the first run after the practice was
## built measured a club that develops nobody and reported almost no change: the
## manager was doing none of the one thing the new system is entirely about.
## **A probe that does not use a system is not a measurement of that system.**
##
## Two captains, best grade the club can afford, covering different roles — five
## to seventeen credits each against a season's sixteen at the bottom, so it is a
## real early-career decision and not free.
func _staff(s: Season) -> void:
	var o := s.office
	while o.captains.size() < ClubOffice.MAX_CAPTAINS:
		var best: Dictionary = {}
		for slot in 4:
			var c := ClubOffice.offer(s.seed_value, s.world.season, slot)
			if ClubOffice.cost_of(c) > o.credits - League.dues_for(o.tier):
				continue
			## Prefer the man who teaches something nobody here teaches. A second
			## captain doubled onto the first one's roles leaves a third of the
			## squad with no coaching at all, which is the shape of squad this
			## probe spent twenty seasons proving does not develop.
			var fresh := 0
			for r in ClubOffice.specialties_of(c):
				if not o.taught(int(r)):
					fresh += 1
			var score: int = int(c.get("grade", 1)) + fresh * 3
			if best.is_empty() or score > int(best.get("score", -1)):
				best = {"cap": c, "score": score}
		if best.is_empty() or o.hire(Dictionary(best["cap"])) != "":
			return


## WHAT A MAN IS WORTH TO THIS MANAGER. The competent one asks what he gives
## over the next six years; the youth one asks what he will BE and lets the club
## wait for it — which is the whole difference between the two careers below.
func _value(f: FighterCard) -> int:
	return Career.projected(f) if youth else Career.worth(f)


func _make_room(s: Season, want: FighterCard) -> void:
	var guard := 0
	while guard < 8 and s.club.roster.size() > 6:
		guard += 1
		var over: bool = ClubOffice.wage_bill(s.club) + s.market_wage(want) > s.office.cap()
		var full: bool = s.club.roster.size() >= 13
		if not over and not full:
			return
		var five: Array = s.club.starting_five()
		var go: FighterCard = null
		for c in s.club.roster:
			if five.has(c) and not over:
				continue
			if go == null:
				go = c
			elif over and ClubOffice.billed(c) > ClubOffice.billed(go):
				go = c
			elif not over and _value(c) < _value(go):
				go = c
		## AND THE SALE FUNDS THE SIGNING. `Season.release` pays now — see
		## `Market.trade_value` — so cutting the man the club has outgrown is part of
		## how it affords the man it wants, which is the whole of Pete's *"if they're
		## holding onto Tier one fighters, they're wrong"*. The order is already
		## right and it matters: room is made BEFORE `sign_from_market` is called, so
		## the credits are in hand when the fee is checked.
		if go == null or s.release(go) != "":
			return


var raised: int = 0


func _season(s: Season) -> void:
	var guard := 0
	while guard < 60:
		guard += 1
		var q := 0
		while q < 8 and s.blocked_by() != "":
			q += 1
			match s.blocked_by():
				"bid": s.decline_bid()
				"dilemma": s.answer_dilemma(0)
				"cup": s.sim_cup_tie()
				"promotion":
					var terms: Dictionary = s.promotion_terms()
					s.answer_promotion(s.office.credits >= int(terms["dues_up"]) + 12)
		if s.season_complete():
			break
		var o := s.office
		var men: Array = s.club.roster.duplicate()
		men.sort_custom(func(a, b): return a.armor < b.armor)
		for f in men:
			if o.credits < 3:
				break
			o.repair_kit(f)
		if o.arena.shabby() and o.credits > o.arena.upkeep_cost() * 3:
			o.tidy_arena()
		var keep := o.upkeep_bill() + League.dues_for(o.tier) + KITTY
		if o.credits > keep + o.arena.next_cost():
			o.build_arena()
		if o.credits > keep + LEVEL_FLOAT + o.cap_cost():
			o.raise_cap()
		## AND THE CEILINGS, out of what the week did not need. Youngest first,
		## because a point of ceiling on a man with ten seasons in front of him is
		## ten seasons of it and a point on a thirty-four-year-old is one — the
		## same reasoning `Career.worth` uses on the shelf, applied to the squad
		## already on the books.
		## THE EXTRA SESSION, FIRST OF THE WEEKLY SPENDS. Two to eight credits for
		## a full extra week's work on the whole squad is the best value in the
		## game and it is the one thing here that recurs, so it goes before the
		## ceilings rather than out of what they leave. Still behind the market's
		## reserve — a signing is worth more than any amount of training.
		if o.credits > keep + KITTY:
			s.run_session()

		## OUT OF THE TRUE SURPLUS, AND BEHIND THE MARKET.
		##
		## The first cut spent down to the bills here and the club got WORSE —
		## power slid 36.8 to 33 over twenty seasons, signings halved. This runs
		## every week and the market runs once a winter, so spending to the floor
		## here drained the bank before the shelf was ever looked at. A signing is
		## worth two to three club power and a ceiling point is worth a fifth of
		## one; the cheap thing that runs first eats the money for the dear thing
		## that runs later, every time. Same trap `probe_run` fell into with
		## facilities, same fix: hold the market's money back.
		if o.credits > keep + KITTY:
			var young: Array = s.club.roster.duplicate()
			young.sort_custom(func(a, b): return a.age < b.age)
			for f in young:
				if o.credits <= keep + KITTY:
					break
				if o.raise_ceiling(f) == "":
					raised += 1
		s.skip_event()
