class_name League
extends RefCounted
## The pyramid, the table, and the maths that move a club up or down it.
##
## Run like a real football pyramid — Pete, 10 Sep 2026 — and the tier names come
## from ACRTW, which already had this ladder: Backyard Circuit, State League,
## Regional League, National Division. Inherited rather than re-invented.
##
## WHY SOCCER RATHER THAN A PLAYOFF BRACKET. ACRTW resolves each tier with a
## top-2 final or a top-4 playoff. A pyramid with promotion and relegation is a
## better fit here for one reason: it gives a losing season consequences without
## ending the run. You do not get knocked out, you go down — and going down is a
## story that continues, which is exactly what a club manager wants and what a
## bracket cannot give you.

## Rounds are this game's goals. A bout is best-of-three rounds and can be drawn,
## so football's three-one-nil works without modification.
const WIN_POINTS: int = 3
const DRAW_POINTS: int = 1
const LOSS_POINTS: int = 0

enum Tier { BACKYARD, STATE, REGIONAL, NATIONAL }

## `up` and `down` MUST match between adjacent tiers or the pyramid leaks clubs:
## whatever a tier promotes, the tier above it must relegate. That invariant is
## asserted over a hundred simulated seasons in tests/test_league.gd, because a
## division that quietly gains a team every year is the kind of bug that only
## shows up in a save file two hours in.
const TIERS := [
	{
		"id": Tier.BACKYARD,
		"name": "Backyard Circuit",
		"short": "BYC",
		"clubs": 6,
		## TWO UP, NOT ONE, AND THE STATE LEAGUE SENDS TWO DOWN TO MATCH.
		##
		## This was *"champion only"* — the one division in the pyramid that
		## promoted a single club, and the one every career starts and spends its
		## first hours in. `tools/probe_run.gd` played a hundred twenty-season
		## careers with a manager who does every obvious thing and got **one
		## promotion every twenty seasons at the default grade**. Four divisions
		## to climb at that rate is a sixty-season career before anybody sees the
		## National Division, which is not a difficulty curve, it is a queue.
		##
		## Champion-only also made the Backyard Circuit the HARDEST division to
		## leave, which is precisely backwards: the bottom of a pyramid is where a
		## player is least equipped and least invested, and it was the rung with
		## the narrowest gate.
		##
		## THE PYRAMID STAYS BALANCED and that is why `down` moves with it. Tier 0
		## sends two up and receives two down; the State League sends two each way
		## and receives two from each side; every division above it already ran
		## 2-and-2. **A ladder where one rung has different arithmetic from the
		## others is a rung that will silently leak or gain a club**, which this
		## world's own soak test exists to catch.
		"up": 2,
		"down": 0,        ## the floor of the pyramid; nowhere to fall
		"power": [30, 46],
		"blurb": "Six clubs, a field and a rail. Win it and somebody notices.",
	},
	{
		"id": Tier.STATE,
		"name": "State League",
		"short": "STL",
		"clubs": 8,
		"up": 2,
		"down": 2,        ## two, to match the two the Backyard Circuit sends up
		"power": [40, 58],
		"blurb": "Proper marshals, proper armor inspection, and clubs that travel.",
	},
	{
		"id": Tier.REGIONAL,
		"name": "Regional League",
		"short": "REG",
		"clubs": 12,
		"up": 2,
		"down": 2,
		"power": [52, 70],
		"blurb": "The grind. Twelve clubs, eleven events, no easy weekends.",
	},
	{
		"id": Tier.NATIONAL,
		"name": "National Division",
		"short": "NAT",
		"clubs": 16,
		"up": 2,          ## not promoted — these are the Worlds berths
		"down": 2,
		"power": [64, 86],
		"blurb": "The top flight. Finish top two and the federation sends you to Worlds.",
	},
]


static func tier(t: int) -> Dictionary:
	return TIERS[t]


static func tier_name(t: int) -> String:
	return String(TIERS[t]["name"])


## ------------------------------------------------------------- the dues
## WHAT IT COSTS TO ENTER A DIVISION FOR A SEASON, billed the day it opens.
##
## Pete, 15 Sep 2026: *"I'm not liking the dues portion, that should more be a
## league dues at the start of a season, one in which you CAN go negative but
## it's a good bite."*
##
## THE DUES USED TO PAY THE CLUB. `Federation.dues_for(members)` was a standing
## subscription worth 24.4 credits a season across a career — **58% of every
## credit the club earned**, in a game about fighting, from a number the player
## could barely influence. `tools/probe_year1.gd` printed it next to a gate of
## 1.4 and the shape of the economy was on one line.
##
## Reversing it does three things at once, which is why it is the right change
## rather than a nerf:
##
##   IT MAKES THE GATE THE FAUCET. Take the biggest income line out and the
##   money has to come from somewhere people are watching. That is Retro Bowl's
##   whole economy and the thing Part 3 of the teardown said we were missing.
##
##   IT PRICES THE DIVISION. A division is now a thing you pay to be in, so a
##   bigger one is a bigger commitment rather than simply a better one — which is
##   what makes the choice below worth offering at all.
##
##   AND IT GIVES THE CLIMB A REASON TO WAIT. Pete: *"A player may bust through
##   the season but want to stay a season and continue building up their money,
##   train players, or whatever they wish, and staying in a cheaper league would
##   be beneficial."* Staying down is only a decision if going up costs money.
##
## Priced against what `tools/probe_run.gd` measured a division earning, at
## roughly a fifth of it: a bite that is felt every year and is not, on its own,
## the thing that ends a club.
const DUES := [6, 14, 24, 38]


static func dues_for(t: int) -> int:
	return int(DUES[clampi(t, 0, DUES.size() - 1)])


static func club_count(t: int) -> int:
	return int(TIERS[t]["clubs"])


## A single round-robin: everyone plays everyone once, so a season is N-1 events.
## Not a double one, and that is an authenticity call as much as a scope one —
## buhurt clubs travel to events, there is no home ground, and a home-and-away
## fixture list would be borrowing a structure the sport does not have. It also
## lands every tier inside the direction doc's 10-14 events: 5, 7, 11, 15.
static func events_in_season(t: int) -> int:
	return club_count(t) - 1


## A row. `rf`/`ra` are rounds for and against. `mf`/`ma` are MARGIN — the
## standing differential of every round, which is this sport's real measure of
## how convincingly you won. Pete, 10 Sep 2026: "Points are based on how many up
## vs how many down. So a 5-1 would be 4 points. A 1-0 would be one point."
##
## Margin is the tiebreak rather than rounds won, and it is a better one: two
## clubs on the same points and the same rounds are not equally good if one of
## them keeps winning 5-1 and the other keeps scraping 1-0.
##
## `lots` is the drawn-lots tiebreak: a number handed to each club at the start
## of a season and used only when everything else is level. It exists because
## the first version broke final ties on club id — and the player is club 0, so
## he won every tie in every division and floated to the top flight on a static
## rating. Real leagues draw lots for exactly this reason; a fixed ordering is
## never neutral, it just hides who it favours.
static func new_row(club_id: int, lots: int = 0) -> Dictionary:
	return {
		"club": club_id, "lots": lots, "played": 0, "won": 0, "drawn": 0, "lost": 0,
		"rf": 0, "ra": 0, "mf": 0, "ma": 0, "points": 0,
	}


static func apply_result(row: Dictionary, rounds_for: int, rounds_against: int,
		margin_for: int = 0, margin_against: int = 0) -> void:
	row["played"] = int(row["played"]) + 1
	row["rf"] = int(row["rf"]) + rounds_for
	row["ra"] = int(row["ra"]) + rounds_against
	row["mf"] = int(row["mf"]) + margin_for
	row["ma"] = int(row["ma"]) + margin_against
	if rounds_for > rounds_against:
		row["won"] = int(row["won"]) + 1
		row["points"] = int(row["points"]) + WIN_POINTS
	elif rounds_for < rounds_against:
		row["lost"] = int(row["lost"]) + 1
		row["points"] = int(row["points"]) + LOSS_POINTS
	else:
		row["drawn"] = int(row["drawn"]) + 1
		row["points"] = int(row["points"]) + DRAW_POINTS


static func round_diff(row: Dictionary) -> int:
	return int(row["rf"]) - int(row["ra"])


## The tiebreak Pete asked for: every round's standing differential, summed.
static func margin_diff(row: Dictionary) -> int:
	return int(row.get("mf", 0)) - int(row.get("ma", 0))


## League points, then MARGIN, then rounds won. Football's shape, but with
## margin where goal difference would sit — because a 5-1 and a 1-0 are both one
## win and they are not the same performance, and margin is the only number that
## knows the difference.
##
## Anything still level breaks on drawn lots, which is deterministic within a
## season — a table that reshuffles on reload is a bug report waiting to happen —
## without favouring any particular club.
static func sort_table(rows: Array) -> Array:
	var out := rows.duplicate()
	out.sort_custom(func(a, b):
		if int(a["points"]) != int(b["points"]):
			return int(a["points"]) > int(b["points"])
		if margin_diff(a) != margin_diff(b):
			return margin_diff(a) > margin_diff(b)
		if round_diff(a) != round_diff(b):
			return round_diff(a) > round_diff(b)
		if int(a["rf"]) != int(b["rf"]):
			return int(a["rf"]) > int(b["rf"])
		if int(a.get("lots", 0)) != int(b.get("lots", 0)):
			return int(a.get("lots", 0)) > int(b.get("lots", 0))
		return int(a["club"]) < int(b["club"]))
	return out


## Single round-robin by the circle method: fix one club, rotate the rest. Every
## club meets every other exactly once, and nobody sits out twice.
##
## THE PAIR IS `[A, B, HOST]` — Pete, 14 Sep 2026: *"we need to make arenas for
## home, away, and tournament games."* It was `[a, b]` for the whole life of this
## game, which is why Homesick had nowhere to be away from: the schedule knew who
## played whom and not where.
##
## THE HOST IS A THIRD ELEMENT AND NOT AN ORDERING, and that took one failed
## test to work out. Writing the pair as `[host, visitor]` reads better and
## reshuffles the world: `play_event` passes `pair[0]` and `pair[1]` into
## `quick_bout` in that order, so swapping them redraws every simulated result in
## every division — and a save made yesterday replays into a different season.
## New information rides alongside the old; it does not rearrange it.
##
## THE HOSTS ARE ASSIGNED AFTER THE SCHEDULE, GREEDILY, and the first version was
## a parity trick — `(round + slot) % 2` — which measured **0% to 89%** across
## ten clubs. The circle method rotates clubs through slots, so a rule keyed on
## the slot is not keyed on anybody: the fixed club sits at slot 0 all season and
## its opponent sits at slot n-1 all season, and both of them get the same answer
## every round.
##
## Being clever in the generator was the mistake. Walking the finished fixtures
## and handing each one to whichever club has hosted less is correct by
## construction, is three lines, and needs no argument about why it works.
## `home_share` measures the outcome anyway — a scheduling rule nobody measures
## is a rule that quietly gives one club every away day.
static func fixtures(club_ids: Array) -> Array:
	var ids := club_ids.duplicate()
	var bye := -1
	if ids.size() % 2 == 1:
		ids.append(bye)
	var n := ids.size()
	var rounds: Array = []
	for r in n - 1:
		var day: Array = []
		for i in n / 2:
			var a = ids[i]
			var b = ids[n - 1 - i]
			if a != bye and b != bye:
				day.append([a, b, a])
				## The host is filled in properly below; `a` is a placeholder so
				## the pair is the right shape while the schedule is built.
		rounds.append(day)
		var last = ids.pop_back()
		ids.insert(1, last)
	_share_the_hosting(rounds)
	return rounds


## Each fixture goes to whoever has hosted fewer so far. Ties go to the first
## club named, which is arbitrary and is why the result is measured rather than
## reasoned about.
static func _share_the_hosting(rounds: Array) -> void:
	var hosted := {}
	for day in rounds:
		for pair in day:
			var a := int(pair[0])
			var b := int(pair[1])
			var ha := int(hosted.get(a, 0))
			var hb := int(hosted.get(b, 0))
			var host := a if ha <= hb else b
			pair[2] = host
			hosted[host] = int(hosted.get(host, 0)) + 1


## WHAT SHARE OF HIS FIXTURES A CLUB HOSTS, out of a built schedule. The check
## reads this rather than trusting the parity trick above — a scheduling rule
## nobody measures is a rule that quietly gives one club every away day.
static func home_share(rounds: Array, club_id: int) -> float:
	var home := 0
	var all := 0
	for day in rounds:
		for pair in day:
			if int(pair[0]) != club_id and int(pair[1]) != club_id:
				continue
			all += 1
			if host_of(pair) == club_id:
				home += 1
	return 0.0 if all == 0 else float(home) / float(all)


## WHO HOSTS THIS FIXTURE. Reads the third element, and falls back to the first
## for a schedule saved before hosts existed — an old save should load into a
## season where somebody is at home, not one where nobody is.
static func host_of(pair: Array) -> int:
	return int(pair[2]) if pair.size() > 2 else int(pair[0])


## Who goes up and who goes down, as club ids. The table must already be sorted.
static func promoted(t: int, sorted_rows: Array) -> Array:
	var n := int(TIERS[t]["up"])
	var out: Array = []
	for i in mini(n, sorted_rows.size()):
		out.append(int(sorted_rows[i]["club"]))
	return out


static func relegated(t: int, sorted_rows: Array) -> Array:
	var n := int(TIERS[t]["down"])
	var out: Array = []
	for i in mini(n, sorted_rows.size()):
		out.append(int(sorted_rows[sorted_rows.size() - 1 - i]["club"]))
	return out


## The pyramid balances only if each tier relegates exactly as many as the tier
## below it promotes. Checked here rather than trusted, because the failure is
## silent and cumulative.
static func pyramid_balances() -> String:
	for i in TIERS.size() - 1:
		var below: int = int(TIERS[i]["up"])
		var above: int = int(TIERS[i + 1]["down"])
		if below != above:
			return "%s promotes %d but %s relegates %d" % [
				TIERS[i]["name"], below, TIERS[i + 1]["name"], above]
	if int(TIERS[0]["down"]) != 0:
		return "the bottom tier cannot relegate anyone"
	return ""
