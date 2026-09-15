extends SceneTree
## PLAY THE GAME AND SEE WHAT FALLS OVER.
##
##   godot --headless --path . --script res://tools/soak.gd
##
## Every other file in `tests/` asks whether a rule is right. This asks whether
## the whole thing survives being used: eight seasons of a career, every bout
## fought in the sim, every winter rolled, every cup tie played — and then looks
## at the state a player would be looking at.
##
## IT IS NOT A CHECK, IT IS A WALK. It prints what it finds and flags anything
## that looks wrong to a person rather than to an assertion — a squad that
## cannot field five, a wage bill nobody can pay, a club that stopped developing,
## a number that went somewhere it should not. The suite proves the rules; this
## finds the rules nobody wrote.
##
## ------------------------------------------------------------------------
## IT NOW PLAYS THE MANAGER, which is the half the first version left out.
##
## The first soak fought every bout and touched nothing else, and the career it
## produced was an eight-season decay: thirteen men to six, rating 31 to 20, out
## of the top three by season three and therefore out of the cups, with credits
## piling up unspent because nobody spent them. That is the correct shape for
## doing nothing — and it meant SEVEN OF THE EIGHT TIERS, every promotion, every
## invitational the pyramid gates on finishing position, the market, the staff
## room and every facility in the clubhouse were never reached at all.
##
## **A state nothing constructs is a state nothing tests**, and a passive walk
## constructs exactly one state: the bottom.
##
## So there is a policy below — `_manage()` — and it is deliberately a DULL one.
## It is not trying to be a good manager and it must not be tuned into one: it
## re-signs who it can, buys the cheapest thing it can afford in a fixed order,
## and takes the best man in the market who fits under the cap. A clever policy
## would hide the bugs a dull one walks straight into, and the point is the walk.
const SEASONS := 20

var flags: Array[String] = []
var tier_log: Array[String] = []
var spend: Dictionary = {}
## THE THREE WAYS TO RUN A CLUB, walked side by side.
##
## The first version of this tool had ONE policy, and every time it was changed
## the career came out differently — which meant the walk had stopped measuring
## the game and started measuring the policy. A tool you can tune until it agrees
## with you is not a measurement.
##
## So it runs three and prints all three. IDLE touches nothing, which is the
## floor the game must not fall through. THRIFTY signs one man a summer and banks
## the rest. SPENDER buys every upgrade it can afford, every summer. **If all
## three end in the same place there is no management game here**; if one climbs
## and another does not, the decisions are real.
enum Policy { IDLE, THRIFTY, SPENDER }
const POLICY_NAME := ["did nothing", "thrifty", "spender"]
var policy: int = Policy.THRIFTY

var _seen_broke: bool = false
var _seen_below_band: bool = false
var arc: Array = []


func _spent(what: String) -> void:
	spend[what] = int(spend.get(what, 0)) + 1


func _flag(s: String) -> void:
	flags.append(s)


var verdicts: Array[String] = []


func _init() -> void:
	for p in [Policy.IDLE, Policy.THRIFTY, Policy.SPENDER]:
		_walk(p)
	print("\n=== the three careers ===\n")
	for v in verdicts:
		print("  " + v)
	print("")
	quit()


func _walk(which: int) -> void:
	policy = which
	flags.clear()
	tier_log.clear()
	spend.clear()
	arc.clear()
	_seen_broke = false
	_seen_below_band = false
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	print("\n=== %d seasons, %s — the manager %s ===\n"
		% [SEASONS, s.club.display_name, POLICY_NAME[which]])
	var tier_was := s.world.player_tier()
	for year in SEASONS:
		## THE SUMMER, BEFORE THE FIRST BOUT. A manager signs and builds between
		## seasons, so the walk does too — and the very first summer matters most,
		## because a club that never buys a sixth travel slot never has a bench.
		_manage(s, year)
		var bouts := 0
		var cups := 0
		var guard := 0
		while not s.season_complete() and guard < 40:
			guard += 1
			## The real door: begin the bout, fight it, post it.
			## THE QUEUE FIRST, the way the season screen drains it — the bout
			## door does not enforce `blocked_by()` and never has.
			_drain_the_queue(s)
			var sim := s.begin_bout()
			if sim == null:
				s.skip_event()
				continue
			Session.season = s
			Session.bout = sim
			sim.run_to_end()
			s.post_bout(sim)
			Session.clear_bout()
			bouts += 1
			## And any cup tie he owes, the same way.
			var tie_guard := 0
			while s.pending_cup() != null and tie_guard < 8:
				tie_guard += 1
				s.sim_cup_tie()
				cups += 1
		_look(s, year, bouts, cups)
		var pos := s.world.player_position()
		## THE YEAR'S MONEY, MEASURED RATHER THAN REASONED ABOUT. Prize money,
		## the gate, the dues and the bills all land inside `roll_over()`, so the
		## only honest way to read the club's income is to bracket the call.
		var purse_before := s.office.credits
		s.roll_over()
		var earned := s.office.credits - purse_before
		## A SUMMER THAT COSTS MORE THAN IT PAYS is the shape of a club that
		## cannot recover, and it is invisible on the credits line because the
		## balance simply pins at zero. Measured once and flagged the first time
		## it happens, not every year after.
		if earned < 0 and not _seen_broke:
			_seen_broke = true
			_flag("season %d: the summer first COST money (%+d CC) — prize money and"
				% [year + 1, earned]
				+ " the gate stopped covering the bills, and a club with no credits"
				+ " cannot sign its way back out")
		var ages := 0
		var eight := s.club.active_eight()
		for f in eight:
			ages += f.age
		print("     summer: %+d CC (now %d) · eight rate %d, average age %d"
			% [earned, s.office.credits, s.club.power(),
				0 if eight.is_empty() else ages / eight.size()])
		var tier_now := s.world.player_tier()
		if tier_now != tier_was:
			var word := "UP to" if tier_now > tier_was else "DOWN to"
			tier_log.append("season %d: %s %s (finished %d)" % [year + 1, word,
				String(League.TIERS[tier_now]["name"]), pos])
			print("    >>> %s %s" % [word, String(League.TIERS[tier_now]["name"])])
			tier_was = tier_now
	print("")
	print("  climbed: %s" % ("never left the bottom rung"
		if tier_log.is_empty() else ", ".join(tier_log)))
	var bought: Array[String] = []
	for k in spend:
		bought.append("%s x%d" % [k, int(spend[k])])
	bought.sort()
	print("  spent on: %s" % ("nothing at all" if bought.is_empty()
		else ", ".join(bought)))
	if arc.size() >= 2:
		var a0: Array = arc[0]
		var a1: Array = arc[-1]
		print("  the arc: club %d -> %d, rivals %d -> %d, purse %d -> %d"
			% [int(a0[0]), int(a1[0]), int(a0[1]), int(a1[1]),
				int(a0[2]), int(a1[2])])
		## THE ONE SENTENCE A CAREER GAME HAS TO BE ABLE TO SAY. If the club ends
		## twenty seasons further from its rivals than it started, the loop runs
		## the wrong way and nothing else in the game can fix that.
		if int(a1[0]) - int(a1[1]) < int(a0[0]) - int(a0[1]):
			_flag("twenty managed seasons left the club %d behind its rivals, having"
				% (int(a1[1]) - int(a1[0]))
				+ " started %d ahead — the career runs downhill" % (int(a0[0]) - int(a0[1])))
	## THE TWO THINGS A CAREER GAME MUST NOT DO over twenty seasons: stand still,
	## or run out of things to buy. Either one is the ladder failing, not the club.
	if tier_log.is_empty():
		_flag("twenty seasons and the club never moved a rung in either direction")
	if bought.is_empty():
		_flag("twenty seasons and the clubhouse never sold the manager anything")
	print("")
	if flags.is_empty():
		print("  nothing looked wrong")
	else:
		for f in flags:
			print("  ? " + f)
	verdicts.append("%-10s  %s  ·  %s" % [POLICY_NAME[which],
		"climbed" if not tier_log.is_empty() else "never moved a rung",
		"club %d -> %d against rivals %d -> %d"
			% [int(arc[0][0]), int(arc[-1][0]), int(arc[0][1]), int(arc[-1][1])]
			if arc.size() >= 2 else "no arc"])


func _look(s: Season, year: int, bouts: int, cups: int) -> void:
	var fit := 0
	var best := 0
	var worst := 99
	var total := 0
	for f in s.club.roster:
		if f.fit():
			fit += 1
		best = maxi(best, f.overall())
		worst = mini(worst, f.overall())
		total += f.overall()
	var avg := 0 if s.club.roster.is_empty() else total / s.club.roster.size()
	var bill := ClubOffice.wage_bill(s.club)
	var cap := s.office.cap()
	## WHERE HE FINISHED is the number the whole pyramid turns on — `promoted()`
	## takes the top `up` of the sorted table and nothing else — so a walk that
	## does not print it cannot tell "never promoted" from "never close".
	##
	## `player_position()` IS ALREADY 1-BASED (it returns `i + 1`, and -1 for not
	## found). Adding one to it printed "7th of 6" for twenty straight seasons —
	## a position outside its own division, on every line, and it took reading the
	## function to notice rather than reading the output. Every consumer in the
	## game treats it correctly; only this tool did not.
	var pos := s.world.player_position()
	var tier := s.world.player_tier()
	var field := League.club_count(tier)
	## AND WHAT THE DIVISION IS FOR. A club can decay out of the BOTTOM of its
	## own tier's power band and go on playing there forever, which looks like a
	## losing streak and is actually a club that no longer belongs in the league
	## it is in. The band is the only thing that says which.
	var band: Array = League.TIERS[tier]["power"]
	var power := int(s.world.clubs[s.world.player_club]["power"])
	var rivals := 0
	var rival_total := 0
	for i in s.world.clubs.size():
		if i != s.world.player_club and int(s.world.clubs[i]["tier"]) == tier:
			rivals += 1
			rival_total += int(s.world.clubs[i]["power"])
	var rival_avg := 0 if rivals == 0 else rival_total / rivals
	arc.append([power, rival_avg, s.office.credits])
	## OUT OF HIS OWN DIVISION'S BAND. Every CPU club is pulled a quarter of the
	## way to its band's midpoint every summer and clamped six either side, so
	## the league it plays in holds its level by construction. The player's rating
	## is his roster and has no such floor — he can decay out of the bottom of the
	## BOTTOM tier and go on playing there forever, which on the table looks like
	## a losing streak and is really a club that no longer belongs in the only
	## league there is below it.
	if power < int(band[0]) and not _seen_below_band:
		_seen_below_band = true
		_flag("season %d: club power %d fell below its own division's floor of %d"
			% [year + 1, power, int(band[0])]
			+ " (rivals average %d) — there is no rung under this one" % rival_avg)
	print("s%-2d %-18s %s of %d · pw %2d (band %d-%d, rivals %2d) · %2d/%2d fit · %d-%d · %s/%s · %2d CC · %d ties"
		% [year + 1, String(League.TIERS[tier]["name"]),
			"?" if pos < 1 else str(pos), field,
			power, int(band[0]), int(band[1]), rival_avg,
			fit, s.club.roster.size(), worst, best,
			ClubOffice.money(bill), ClubOffice.money(cap), s.office.credits, cups])

	## ---- the things a player would notice
	if fit < 5:
		_flag("season %d: only %d fit men — cannot field five" % [year + 1, fit])
	if bill > cap:
		_flag("season %d: wage bill %s over a cap of %s" % [year + 1,
			ClubOffice.money(bill), ClubOffice.money(cap)])
	if s.office.credits < 0:
		_flag("season %d: credits went negative (%d)" % [year + 1, s.office.credits])
	## THE NUMBER IS THE CLUB'S OWN, not the game's maximum. There is no minimum
	## on the books, and the eight is not the target either — a club travels with
	## `office.travel_slots` men, so a Backyard side that has never bought a seat
	## travels six and SIX IS CORRECT. Flagging against ACTIVE_SIZE reported a
	## healthy club as broken for five straight seasons, which is a check telling
	## you about itself rather than about the game.
	if s.club.roster.size() < s.club.party_size():
		_flag("season %d: roster down to %d, short of a party of %d" % [year + 1,
			s.club.roster.size(), s.club.party_size()])
	## What the party size cannot tell you: whether the men in it can make a line
	## on the day. This is the one that bites — knocks and the work rota take two
	## out of a party of six and the club walks to the list with four.
	if s.club.starting_five().size() < MeleeClub.LINE_SIZE:
		_flag("season %d: cannot field a line — %d of %d" % [year + 1,
			s.club.starting_five().size(), MeleeClub.LINE_SIZE])
	if bouts == 0:
		_flag("season %d: no bouts were fought at all" % [year + 1])
	## Nobody should be at a rating the pyramid cannot contain, and nobody
	## should be stuck at the floor for a whole career.
	if best > 99 or worst < 1:
		_flag("season %d: a rating left the scale (%d-%d)" % [year + 1, worst, best])
	var grudges := 0
	var traits := 0
	for f in s.club.roster:
		if f.grudge_club >= 0:
			grudges += 1
		if f.trait_id != FighterTrait.T.NONE:
			traits += 1
	if year == SEASONS - 1:
		print("    %d men carry a trait, %d carry a grudge" % [traits, grudges])


## ------------------------------------------------------------------ the policy
## A DULL MANAGER, ON PURPOSE.
##
## Its job is to REACH STATES, not to win. Every line here is the obvious move a
## player makes without thinking — keep the men you have, buy the cheapest thing
## on the list, take the best man you can afford — and it is deliberately not
## tuned, because a policy clever enough to avoid the game's rough edges is a
## policy that walks around exactly what this tool exists to find.
##
## Order matters and is the order a person uses: keep, then build, then buy.
func _manage(s: Season, year: int) -> void:
	## ORDER IS THE WHOLE POLICY, and the walk proved it the expensive way.
	##
	## When `_buy_a_man` stopped after one signing, it ran out of money before it
	## reached the staff room by accident, and the club hired twelve captains
	## across twenty seasons and got promoted. Letting it spend to its ceiling —
	## forty-two signings — starved the staff room completely, and **an uncovered
	## role fights Green, which is a measured 63% loss rate**. The club that
	## bought twice as many men finished eleven points behind its rivals instead
	## of five and never climbed at all.
	##
	## That is the game working: coaching beats squad churn, and it is a nicer
	## lesson than most management games teach. It is also a policy bug — the
	## right order is the one a person uses. Keep what you have, build what lasts,
	## staff the room, and only then go shopping with what is left.
	if policy == Policy.IDLE:
		return
	_spend_the_levels(s)
	_keep_the_men(s)
	_keep_the_staff(s)
	_build_the_club(s)
	_staff_the_room(s)
	_set_the_regime(s)
	_mind_the_room(s)
	_pick_a_plan(s)
	_buy_a_man(s)
	## And the squad has to be a squad before the first bout, whatever the above
	## did to it — promotions off the eight, reserves up, nothing left short.
	_tidy_the_eight(s)


## 1. KEEP. An expiring man is re-signed and an extendable one extended, cheapest
## first, while the money lasts. `extend_cost`/`resign_cost` quote exactly what
## the taking call charges, so this never has to guess.
func _keep_the_men(s: Season) -> void:
	var jobs: Array = []
	for f in s.club.roster:
		if f.years <= 0:
			jobs.append([s.resign_cost(f), f, "resign"])
		## ONLY IN HIS LAST YEAR. The first policy extended every extendable man
		## every summer — a hundred and fifty extensions across twenty seasons,
		## most of them on deals with years still to run — and spent the club's
		## whole income on paperwork. It finished every year on four credits and
		## never bought anything, which read as a game with no economy when it was
		## a manager with no sense. *A dull policy is not a stupid one.*
		elif f.years == 1 and Contracts.can_extend(f):
			jobs.append([s.extend_cost(f), f, "extend"])
	jobs.sort_custom(func(a, b): return int(a[0]) < int(b[0]))
	for j in jobs:
		if int(j[0]) > s.office.credits:
			continue
		var err: String = s.resign(j[1]) if String(j[2]) == "resign" else s.extend(j[1])
		if err == "":
			_spent(String(j[2]))


## 2. BUILD. One pass down a fixed list, cheapest useful thing first, calling
## `new_week()` between purchases because the clubhouse throttles one upgrade per
## building per matchday and a summer is not a matchday.
##
## TRAVEL SLOTS COME FIRST and that is the one judgement in this file. A club
## that cannot put eight men on the coach has no bench, and the first soak found
## the crash that lives down that road — four men on the list. Everything else
## here is money; this one is whether there is a game.
func _build_the_club(s: Season) -> void:
	var o := s.office
	for pass_ in 3:
		o.new_week()
		if o.travel_slots < ClubOffice.TRAVEL_MAX and o.buy_travel_slot() == "":
			_spent("travel slot")
			continue
		o.new_week()
		if ClubOffice.wage_bill(s.club) > o.cap() * 0.8 and o.raise_cap() == "":
			_spent("wage cap")
			continue
		o.new_week()
		if o.upgrade(ClubOffice.Facility.INFIRMARY) == "":
			_spent("infirmary")
			continue
		o.new_week()
		if o.upgrade(ClubOffice.Facility.TRAINING) == "":
			_spent("training")
			continue
		o.new_week()
		if o.build_arena() == "":
			_spent("arena")
			continue
		## COMPLIANCE IS NOT OPTIONAL AT THE TOP. `invited()` gates the cups on
		## results AND certificates, so a club that climbs without buying rules
		## qualifies on the table and is turned away at the door — which would
		## look exactly like a broken cup and is in fact a manager not reading.
		o.new_week()
		var raised := false
		for r in o.shortfalls().size():
			if o.raise_rule(r) == "":
				_spent("federation rule")
				raised = true
				break
		if raised:
			continue
		break


## 3. BUY. Down the list, best first, taking everyone the club can afford and
## has room for. Not a squad-building strategy — a way of reaching
## `sign_from_market`, the fee, the cap refusal and the books-are-full refusal in
## a real career.
##
## IT USED TO STOP AFTER ONE, and that was the dull policy being stupid again.
## Once the ground retainer started paying, the club banked seventy credits
## against a wage bill of eighty-six inside a two-hundred cap — money and
## headroom sitting idle while it signed one man a year and drifted five points
## behind its rivals. A manager with seventy credits does not go home, and a walk
## that does measures a ladder nobody is actually trying to climb.
func _buy_a_man(s: Season) -> void:
	if policy == Policy.IDLE:
		return
	## AND ONLY MEN WHO WOULD ACTUALLY TRAVEL. The market sells to the tier, so
	## most of what it offers a mid-table club is worse than the men already on
	## its bench — and signing those is a fee and a wage for nothing, which is
	## precisely how forty-two signings made a club worse than twenty did.
	var bar := 0
	for f in s.club.active_eight():
		bar = f.overall() if bar == 0 else mini(bar, f.overall())
	for f in s.market():
		if s.market_fee(f) > s.office.credits:
			continue
		if f.overall() <= bar:
			continue
		var err := s.sign_from_market(f)
		if err == "":
			_spent("signing")
			## THRIFT IS A STRATEGY, and the walk found out it is the better one.
			## A club that signs once and banks the rest reached the State League;
			## the same club spending to its ceiling every summer never left the
			## bottom. Both are run, because a game where the two come out the
			## same is a game with no decision in it.
			if policy == Policy.THRIFTY:
				return
			continue
		## THE BOOKS ARE FULL is the one refusal worth acting on: cut the worst
		## man on the reserve and try the same signing again. A manager does this
		## without thinking and it is the only road to `release()`. Only when the
		## new man is actually better than the one going — a policy that churns
		## its reserve for the sake of it is not dull, it is daft.
		if err.begins_with("The books are full"):
			var worst: FighterCard = null
			for r in s.club.reserves():
				if worst == null or r.overall() < worst.overall():
					worst = r
			if worst == null or worst.overall() >= f.overall():
				continue
			if s.release(worst) == "":
				_spent("release")
				if s.sign_from_market(f) == "":
					_spent("signing")
			continue
		## Anything else — over the cap, short of credits — is the club's own
		## ceiling talking, and every man below this one on the list is dearer.
		return


## 4. STAFF. Two captains is the maximum and an uncovered role fights Green,
## which is a measured 63% loss rate — so this is not a luxury purchase and a
## walk that skips it is a walk through a game nobody would play.
func _staff_the_room(s: Season) -> void:
	var have: int = s.office.captains.size()
	if have >= ClubOffice.MAX_CAPTAINS:
		return
	for slot in 3:
		if s.office.captains.size() >= ClubOffice.MAX_CAPTAINS:
			return
		var c := ClubOffice.offer(s.world.seed_value if "seed_value" in s.world
			else 31337, s.world.season, slot, s.office.staff_refreshes
			if "staff_refreshes" in s.office else 0)
		if c.is_empty():
			continue
		if ClubOffice.cost_of(c) > s.office.credits:
			continue
		if s.hire_captain(c) == "":
			_spent("captain")


## 5. TIDY. Reserves up until the eight is full, because a man signed into the
## reserve does not travel and a man who does not travel is money spent on
## nothing — which is how the first version of this policy quietly built a club
## of thirteen that still fielded six.
func _tidy_the_eight(s: Season) -> void:
	var guard := 0
	while s.club.active_eight().size() < s.club.party_size() and guard < 20:
		guard += 1
		var up: FighterCard = null
		for f in s.club.reserves():
			if up == null or f.overall() > up.overall():
				up = f
		if up == null or s.club.set_active(up, true) != "":
			break
	s.sync_power()


## ==========================================================================
## THE LEVERS THE FIRST WALKS NEVER PULLED
##
## Pete, 14 Sep 2026: *"what exactly all are you testing here, because there's
## still trainings, facilities upgrades, coaching levels and focuses, and
## whatever else we have that can help a team win."*
##
## The answer was: less than half of it. An audit of every verb a screen calls
## against every verb this tool called came back with the clubhouse and the
## squad covered, and **the training regimes, the kit, the captains' contracts,
## the morale lever, the matchday and the whole blocking queue never touched
## once.** Twenty-season careers, three policies, and every one of them ran on
## NORMAL with default tactics and an unanswered card on the table.
##
## So the claim "the ladder is climbable" was really "the ladder is climbable by
## a manager who ignores training, coaching contracts, kit, tactics and every
## card the game deals him." That is a weaker sentence than it sounded.


## ------------------------------------------------------------- the queue
## THE RULE LIVED IN THE VIEW, so nothing headless obeyed it.
##
## `Season.blocked_by()` says a bid, a cup tie or a dilemma has to be dealt with
## before the next matchday — and `season_scene.gd` is the ONLY thing in the
## project that ever asked. `begin_bout()` does not check it, so every walk,
## probe and save test has fought straight past the queue since the day it was
## written. The bid was never taken and never declined; the card on the table was
## dealt and never answered.
##
## That matters beyond tidiness. **A dilemma card is the only thing in the game
## outside the workshop that puts condition back into a man's armour** — the
## armourer's bill and its cousins are the kit economy — so a walk that never
## answers one is a walk where kit only ever goes one way.
func _drain_the_queue(s: Season) -> void:
	var guard := 0
	while guard < 8:
		guard += 1
		match s.blocked_by():
			"bid":
				## A DATE IS A REAL DECISION and the dull manager takes the
				## cheapest one it can cover, or passes. Declining is free and
				## has to be — a club that cannot afford a date must still be
				## able to get on with its season.
				var took := false
				for i in s.bid_offers.size():
					if s.take_bid(i, 0) == "":
						_spent("event date")
						took = true
						break
				if not took:
					s.decline_bid()
			"dilemma":
				## ANSWER IT, taking the option that costs no credits where there
				## is one — a skint club's honest answer — and otherwise the
				## first. Which option is right is a design question; that one is
				## ANSWERED is the thing being exercised.
				var card := s.dilemma_card()
				var opts: Array = card.get("options", [])
				var pick := 0
				for i in opts.size():
					var fx: Dictionary = (opts[i] as Dictionary).get("fx", {})
					if int(fx.get("cc", 0)) >= 0:
						pick = i
						break
				s.answer_dilemma(pick)
				_spent("dilemma answered")
			"cup":
				return          ## the bout loop plays these itself
			_:
				return


## ----------------------------------------------------------- the regime
## THE ONE CONTROL THAT IS FOUR DECISIONS.
##
##     XP       Light 0.6   Normal 1.0   Hard 1.5
##     morale  +0.015        0.0        -0.020   a week
##     armour  +0.10         0.0        -0.10    a week
##     knocks   0.10         0.20        1.00    multiplier on a knock landing
##
## `tools/probe_regimes.gd` ran the same club and the same seed for twenty
## seasons on each, and the spread is not subtle:
##
##     Light   power 30  armour 0.91  1 knock   line 5/5
##     Normal  power 23  armour 0.64  2 knocks  line 5/5
##     Hard    power  0  armour 0.43  5 knocks  line 4/5
##
## Hard for a whole career ends with a club that **cannot field five** — power
## reads 0 because `MeleeClub.power()` has nothing to average. That is the
## `REGIME_INJURY` table doing exactly what it says (every knock lands, always,
## against one in five on Normal) and it is a dead end with no road back, which
## is the same shape as the economy spiral the retainer fix closed.
func _set_the_regime(s: Season) -> void:
	var want := ClubOffice.Regime.NORMAL
	match policy:
		Policy.THRIFTY:
			## A THIN SQUAD RESTS. Light is the only setting that puts armour
			## back and it cuts knocks to a tenth, so a club that cannot cover a
			## knock trains light — which is what a real coach does in April.
			var fit := 0
			for f in s.club.roster:
				if f.fit():
					fit += 1
			want = ClubOffice.Regime.LIGHT if fit <= MeleeClub.LINE_SIZE + 2 \
				else ClubOffice.Regime.NORMAL
		Policy.SPENDER:
			want = ClubOffice.Regime.HARD
	for i in s.office.captains.size():
		if s.office.set_regime(i, want) == "":
			_spent("regime: " + ClubOffice.REGIME_NAME[want])


## ------------------------------------------------- the staff room, kept on
## A CAPTAIN'S DEAL RUNS OUT and `age_captains()` lets him go in the summer,
## silently, before the winter's training. The walk hired twelve across twenty
## seasons and extended none of them — so it was paying to re-hire coaching it
## already had, and living through winters with a role untaught.
func _keep_the_staff(s: Season) -> void:
	for i in s.office.captains.size():
		if s.office.extend_captain(i) == "":
			_spent("captain extended")


## ------------------------------------------------------------ the room
## THE ONLY THING IN THE GAME THAT LIFTS MORALE ON PURPOSE, and no walk had ever
## used it. Morale drives the split fuse, contract refusals, and every man's
## effective stats — so a club that never spends on the room is a club running
## one of its systems open-loop.
func _mind_the_room(s: Season) -> void:
	if policy == Policy.IDLE:
		return
	if s.office.morale < 0.45 and s.boost_morale() == "":
		_spent("morale night")


## --------------------------------------------------------- the matchday
## EVERY BOUT IN EVERY WALK WAS FOUGHT ON DEFAULTS: no formation chosen, no play
## called, the grade left where it started. The chalkboard, the playbook and the
## difficulty are three of the biggest things a player touches and none of them
## had ever been moved by a tool.
func _pick_a_plan(s: Season) -> void:
	var shapes: Array = Tuning.FORMATIONS.keys()
	if shapes.is_empty():
		return
	## ONE SHAPE, HELD. The first version cycled a new formation every season so
	## that twenty seasons would see all of them — which is not a dull manager, it
	## is a manager with no plan, and the men are drilled for a different line
	## every year. Coverage of the formations belongs in `test_book.gd`, where it
	## costs nothing; a career walk should play the way a person plays.
	##
	## Which shape is chosen is deliberately not clever: the club's own default,
	## kept, so the walk is not quietly running a tactics experiment on top of
	## everything else it is measuring.
	if s.formation_id < 0 or not Tuning.FORMATIONS.has(s.formation_id):
		s.formation_id = int(shapes[0])
	_spent("a shape on the board")



## ------------------------------------------------------- the levels waiting
## THE DEVELOPMENT CHANNEL, AND NO WALK HAD EVER USED IT.
##
## `tools/probe_ledger.gd` splits a season's change into what ageing takes, what
## the training ground gives, what bout XP gives and what walks in or out of the
## door. Twelve seasons of it, and the bout-XP column read **zero every single
## year**.
##
## Not a bug. A LEVER. `_award_xp` banks the XP and then notes, on the report,
## *"has a level waiting — spend it on his card"* — because placing a level is a
## decision: which of his five stats goes up. The fighter screen offers the five
## buttons and `Career.level_into(man, stat)` takes one.
##
## So a man only improves by fighting if somebody opens his card and says where
## the improvement goes, and no headless walk had ever opened a card. Every
## career this project has ever measured was fought by a manager who let every
## level his men earned sit unspent, for twenty years.
##
## That is the single biggest thing the audit turned up, and it was hiding behind
## a dead function: `Career.drain()` exists, its own comment says it is *"called
## after every bout"*, and **nothing in the project calls it.** A comment
## asserting a call is not a call.
##
## Where the point goes is deliberately dull — the lowest of his raisable stats,
## so the walk is not quietly running a stat-priority experiment on top of
## everything else it measures.
func _spend_the_levels(s: Season) -> void:
	for f in s.club.roster:
		var guard := 0
		while Career.can_place(f) and guard < 10:
			guard += 1
			var options: Array = Career.raisable(f)
			if options.is_empty():
				break
			var pick: int = int(options[0])
			var lowest := 999
			for st in options:
				var v := Career.read_stat(f, int(st))
				if v < lowest:
					lowest = v
					pick = int(st)
			var r := Career.level_into(f, pick)
			if not bool(r.get("levelled", false)):
				break
			_spent("a level placed")
	s.sync_power()
