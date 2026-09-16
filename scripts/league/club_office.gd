class_name ClubOffice
extends RefCounted
## THE CLUBHOUSE: you are the owner, and these are the levers you actually pull.
##
## Modelled on Retro Bowl's front office at Pete's instruction (10 Sep 2026) —
## a cap bar, facility bars, staff cards, a credit balance — and deliberately
## not a copy of it. The differences are all places where buhurt is not the NFL:
##
##   * Two CAPTAINS, not a head coach and two coordinators. There is no offence
##     and defense in a melee — everybody does the same job in a different place
##     on the line — so a captain covers POSITIONS instead of a side of the ball.
##   * A captain covers TWO roles: a primary and a secondary. There are only
##     three roles, so **two captains cover all three and double up on one, and
##     that overlap is the club's focus.** Pete's rule, and it is a better one
##     than picking a focus off a menu because it falls out of who you hired.
##   * No draft picks, no trades. Fighters are signed and cut, and the reserve
##     is where they are developed.
##
## Everything here is plain data so it saves as plain data.

# ------------------------------------------------------------------- credits
## Retro Bowl calls them coaching credits and spends them on staff and
## facilities. Same currency shape, Pete's name for it (10 Sep 2026), and the
## same reason it works: a small integer you never have enough of is easier to
## reason about than a bank balance, and it keeps the club's books out of the
## way of the fight.
var credits: int = 8

# ------------------------------------------------------------- the salary cap
## A LITERAL CAP, Pete's call — and almost no money in it, which is his second
## call and the more important one: **"This isn't a rich sport by any means."**
##
## The Backyard Circuit runs on about **two hundred dollars a season**. Not two
## hundred thousand — two hundred. Fighters are not paid; that number is what a
## club actually spends keeping thirteen people in harness and on the road, and
## at the bottom of the pyramid it is somebody's weekend. The National Division
## reaches the high hundreds of thousands, and barely.
##
## So the cap is not a ladder of equal steps, it is a different order of
## magnitude in every division, and a wage curve steep enough to match:
##
##   rating 38    $3         a Backyard fighter, in every sense
##   rating 46    $14        top of that division
##   rating 58    $180
##   rating 70    $2,307
##   rating 86    $69,229
##
## The curve and the caps are anchored TOGETHER, on the top of each division's
## power band: the best club a division can field bills just inside that
## division's cap. The first attempt anchored them separately and a top-of-table
## Backyard club billed $793 against a $200 cap — four times its own league's
## limit, which is not a tight cap, it is a broken one.
##
##   Backyard  top rates 46, bills $182   cap $200
##   State     top rates 58, bills $2,340  cap $2,600
##   Regional  top rates 70, bills $29,991 cap $34,000
##   National  top rates 86, bills $899,977 cap $1,000,000
##
## Money that only becomes real at the top is the truest thing this game can say
## about the sport, and it makes the climb mean something a flat cap cannot: in
## the Backyard you are choosing between two fighters, and in the National
## Division you are choosing between a fighter and a facility.
const WAGE_A: float = 0.000794
const WAGE_B: float = 0.2126

## Per division, not per club. The federation sets what a league costs to be in.
const TIER_CAP := [200, 2600, 34000, 1000000]
## THE CAP RAISE HAS NO CEILING, at Pete's instruction — *"the upgradable salary
## cap"* — and Retro Bowl's works the same way: you can keep buying it, and the
## price keeps climbing, forever.
##
## It was five levels and a hard stop. Two separate measurements said that was
## wrong. tools/probe_economy.gd found the National Division earning 185 CC a
## season against a ladder it had already finished, with nothing left to buy;
## tools/probe_market.gd then found a club sitting on **1,100 unspent credits**
## while being unable to sign a single free agent, because the cap it had maxed
## out five raises ago had no room in it for anybody. One system had a surplus and
## the other had a shortage, and the same missing feature caused both.
##
## So: unbounded, and priced to bite. `CAP_COST_BASE x CAP_COST_GROWTH^level` —
## 4, 5, 7, 8, 11, 14, 17, 22, 28, 36, 46, 59 — so the first few are ordinary
## club business and the twentieth is a season's income. A sink with no ceiling
## and a rising price absorbs a surplus without ever becoming the obvious buy,
## which is exactly what the top of the pyramid needed.
const CAP_COST_BASE: float = 4.0
const CAP_COST_GROWTH: float = 1.28
## Kept because the screen and the old tests read it: the number of raises after
## which the cost is no longer in the hand-written table. It is not a limit.
const CAP_MAX_LEVEL: int = 5
## Each raise is a slice of your own division's cap rather than a fixed sum,
## because a fixed sum that matters in the Backyard is a rounding error at the top.
const CAP_STEP_FRACTION: float = 0.15
const CAP_COST := [4, 6, 8, 10, 12]

var cap_level: int = 0
## Which division's rules you are under. Season keeps it current.
var tier: int = 0


func cap() -> int:
	var base: int = TIER_CAP[clampi(tier, 0, TIER_CAP.size() - 1)]
	return int(round(float(base) * (1.0 + CAP_STEP_FRACTION * float(cap_level))))


## WHAT ONE FIGHTER WOULD COST TODAY — the market rate, not the bill.
##
## This used to be both, and that was the bug the contract layer exists to fix: a
## man who improved got more expensive the instant he improved, so developing
## somebody was self-defeating and the cap punished exactly what the training
## ground is for. It is now the price of a NEW deal and the figure the roster
## screen compares a man's actual wage against.
static func wage(card: FighterCard) -> int:
	return maxi(1, int(round(WAGE_A * exp(WAGE_B * float(card.overall())))))


## WHAT HE IS ACTUALLY ON. Falls back to the market rate for a card that has
## never been put on paper — a hand-written fixture, or anything built before
## contracts existed — so no code path can bill zero for a fighter.
## WHAT HE ACTUALLY COSTS. CHEAP and LOYAL sign under the going rate, and they
## do it here rather than at the point of signing so the discount survives a
## re-sign — a trait that only applied once would be a one-off, not a trait.
static func billed(card: FighterCard) -> int:
	var base := card.wage_agreed if card.wage_agreed > 0 else wage(card)
	return maxi(1, int(round(float(base)
		* FighterTrait.mod(card.trait_id, "wage", 1.0))))


static func wage_bill(club: MeleeClub) -> int:
	var total := 0
	for f in club.roster:
		total += billed(f)
	return total


## Money, written the way a club would write it. At the bottom of the pyramid
## every dollar is legible and at the top nobody counts them, so the format has
## to do both.
static func money(n: int) -> String:
	if n >= 1000000:
		return "$%.2fM" % (float(n) / 1000000.0)
	if n >= 10000:
		return "$%dk" % int(round(float(n) / 1000.0))
	if n >= 1000:
		return "$%.1fk" % (float(n) / 1000.0)
	return "$%d" % n


func over_cap(club: MeleeClub) -> int:
	return maxi(0, wage_bill(club) - cap())


func can_afford_wage(club: MeleeClub, card: FighterCard) -> bool:
	return wage_bill(club) + billed(card) <= cap()


func raise_cap() -> String:
	if _throttled(SLOT_CAP):
		return throttle_word("cap")
	var cost: int = cap_cost()
	if credits < cost:
		return "That costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_CLUB)
	cap_level += 1
	_mark(SLOT_CAP)
	return ""


## What the next raise costs. The hand-written table for the first few, then the
## curve — the table is kept because those five numbers were tuned against a
## Backyard club's income and the curve happens to agree with them.
func cap_cost() -> int:
	if cap_level < CAP_COST.size():
		return CAP_COST[cap_level]
	return maxi(1, int(round(CAP_COST_BASE * pow(CAP_COST_GROWTH, float(cap_level)))))


# ------------------------------------------------------------------ facilities
## Three, and each one has to change a number that already exists in the sim or
## the league — a facility that only feeds another facility is a progress bar
## with a name on it.
## HOME GROUND IS GONE, and it is gone rather than renamed. Its blurb was *"Host
## an event each season. Better ground, better gate"* — it was the Arena in
## embryo, five levels of a progress bar with nothing behind it. Keeping both
## would have given the player a Home ground level AND an arena level, both
## feeding the same gate, with no way to reason about which to spend on. The
## credits go to Arena now; see scripts/league/arena.gd.
##
## The remaining two keep their ORIGINAL enum values. Renumbering them would
## have turned every stored Training level into an Infirmary level in any save
## that survived the change — and the save version is bumped as well, so no save
## survives it, but a rule that only holds because of a second rule is not a
## rule.
enum Facility { TRAINING = 1, INFIRMARY = 2 }

const FACILITY_MAX: int = 5
const FACILITY_COST := [3, 5, 7, 9, 11]

const FACILITIES := {
	Facility.TRAINING: {
		"name": "Training ground",
		## SHORT ENOUGH FOR THE COLUMN IT IS DRAWN IN. At 58 characters this was
		## 462 pixels against a 440-pixel column, so the clubhouse clipped it to
		## "…Your captains dec." — which is worse than the shorter sentence,
		## because a clipped line reads as a bug and a short one reads as a line.
		"blurb": "Your captains improve fighters over the winter.",
		"effect": "%d stat points a season, spread over the squad",
	},
	Facility.INFIRMARY: {
		"name": "Infirmary",
		"blurb": "A knock keeps a man out of fewer events.",
		"effect": "-%d events off every injury",
	},
}

var facilities := { Facility.TRAINING: 0, Facility.INFIRMARY: 0 }


func level(f: int) -> int:
	return int(facilities[f])


func facility_cost(f: int) -> int:
	var l := level(f)
	return FACILITY_COST[l] if l < FACILITY_MAX else 0


func upgrade(f: int) -> String:
	if _throttled(str(f)):
		return throttle_word(String(FACILITIES[f]["name"]).to_lower())
	if level(f) >= FACILITY_MAX:
		return "%s cannot be improved further." % FACILITIES[f]["name"]
	var cost := facility_cost(f)
	if credits < cost:
		return "That costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_FACILITIES)
	facilities[f] = level(f) + 1
	_mark(str(f))
	return ""


## BUILDING THE GROUND LIVES HERE, not on the Arena screen.
##
## It used to be three lines inside `arena_scene._build()` — check, subtract,
## increment — which was fine right up until there was a rule that had to apply
## to every upgrade in the club. A rule enforced at one call site is a rule with a
## hole in it, and this codebase has already said so about two other things. The
## screen now asks the office, like the facilities and the cap already did.
func build_arena() -> String:
	if _throttled(SLOT_ARENA):
		return throttle_word("ground")
	var err := arena.can_build(tier, credits)
	if err != "":
		return err
	spend(arena.next_cost(), LINE_GROUND)
	arena.level += 1
	## A NEW GROUND ARRIVES NEW. Paying sixty credits for a National Arena and
	## being handed one with the last place's rubbish still in it would read as a
	## bug, and upgrading is not a laundering route anyway — the level is gated on
	## promotion and costs its full price either way.
	arena.built()
	_mark(SLOT_ARENA)
	return ""


# --------------------------------------------------------- one thing a week
## THE THROTTLE, and it is the last piece of Pete's item 7.
##
## Retro Bowl lets you improve one thing at a time and it is not a fussy rule, it
## is what stops a windfall from becoming an instant club. Without it, the moment
## a player banks a good tournament he buys the arena, both facilities and four
## cap raises on the same afternoon and arrives at the next matchday a different
## team — and every one of those decisions, which the whole Clubhouse exists to
## make interesting, gets made in one undifferentiated blur.
##
## ONE UPGRADE PER BUILDING PER MATCHDAY. Not one upgrade total: a club should
## still be able to mend the infirmary and raise the cap in the same week, because
## those are different decisions about different problems. What it cannot do is
## take the same building up three levels while nothing else in the world moves.
##
## Cleared by the season at the end of every matchday, so "a week" means the same
## thing here as it does everywhere else in this game.
var built_this_week: Dictionary = {}

const SLOT_ARENA: String = "arena"
const SLOT_TIDY: String = "tidy"
const SLOT_CAP: String = "cap"
const SLOT_TRAVEL: String = "travel"
const SLOT_BOOST: String = "boost"
const SLOT_RULE: String = "rule"


func _throttled(slot: String) -> bool:
	return bool(built_this_week.get(slot, false))


func _mark(slot: String) -> void:
	built_this_week[slot] = true


## The same throttle, reachable from outside. The demo button had no limit at
## all and handed out unbounded credits; it needed a per-week guard and did not
## need a second mechanism to go wrong independently of this one.
func done_this_week(slot: String) -> bool:
	return _throttled(slot)


func mark_this_week(slot: String) -> void:
	_mark(slot)


func new_week() -> void:
	built_this_week.clear()


## What the screen says when a button is grayed by the throttle. One sentence,
## and it names the rule rather than the state — "not this week" tells a player
## he is being refused; it does not tell him it will work next week.
## ---------------------------------------------------------- sitting him down
## A CREDIT SINK THAT BUYS A RELATIONSHIP, not a result — Pete, 13 Sep 2026:
## *"have a credit sink to 'negotiate' and raise his morale."*
##
## This is Retro Bowl's meeting, and their cost table is the interesting part.
## `s_get_meeting_cost_morale` prices it by the man's ATTITUDE BAND and by
## nothing else — not his rating, not his wage:
##
##   Toxic 4 · Bad 3 · Poor 3 · Ok 2 · Good 2 · Great 1 · Exceptional 1
##
## The worse his mood, the more it costs to move it. That is the opposite of the
## obvious design and it is right: rescuing a ruined relationship is expensive
## and topping up a good one is cheap. And because it ignores his rating, the
## price tells you about the RELATIONSHIP rather than about the asset — a star
## and a squad man cost the same to sit down with, which is true of people.
##
## Our seven bands are their seven bands (`FighterCard.morale_word`), so the
## table ports across unchanged.
const NEGOTIATE_COST := {
	"Toxic": 4, "Bad": 3, "Poor": 3, "Ok": 2, "Good": 2,
	"Great": 1, "Exceptional": 1,
}

## WHAT AN AFTERNOON WITH HIM IS WORTH. Through `morale_shift`, which scales by
## the room left — so the same conversation lifts a sour man a long way and a
## contented one barely at all. Combined with the cost table that makes rescuing
## somebody the better buy, which is the behavior worth rewarding.
const NEGOTIATE_LIFT: float = 0.14


static func negotiate_cost(card: FighterCard) -> int:
	return int(NEGOTIATE_COST.get(card.morale_word(), 2))


## ONE CONVERSATION A WEEK, PER MAN. On the same throttle the facilities use,
## because without it a club with credits could walk a toxic squad to delighted
## in an afternoon and morale would stop being a consequence of anything.
func negotiate(card: FighterCard) -> String:
	var slot := "neg:%s#%d" % [card.display_name, card.number]
	if _throttled(slot):
		return "You have already sat down with %s this week." % card.display_name
	var cost := negotiate_cost(card)
	if credits < cost:
		return "That costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_SQUAD)
	card.morale_shift(NEGOTIATE_LIFT)
	_mark(slot)
	return ""


## ---------------------------------------------------------- the armorer
## THE SECOND ROW OF RETRO BOWL'S MEETING CARD, which is where this came from —
## Pete, 14 Sep 2026, sending the screen over: MORALE / CONDITION / XP LEVEL /
## CONTRACT, each with a button and a price in credits beside it.
##
## Three of those four were already on the fighter screen. CONDITION was not, and
## it is the one with a hole under it: `armor` multiplies straight into
## `eff_base()`, it is taken off by the HARD regime every week, and until now the
## ONLY thing in the entire game that put any of it back was the luck of the
## dilemma deck dealing the armorer's bill. A stat that can only fall unless the
## game happens to deal you a card is the same shape as the ground retainer that
## paid nothing and the pulling power that collected seven per cent of itself:
## **a system the player cannot reach.**
##
## Priced off the damage rather than off the man, exactly as `negotiate` is
## priced off his mood rather than his rating: an armorer charges for the work
## in front of him and does not ask what the fighter is worth. The step is the
## same size as the deck's own best card (+0.16) so the two roads to a repaired
## harness agree with each other about what a repair IS.
const KIT_STEP: float = 0.16
## What a completely wrecked harness costs to put a step back into. A club at the
## bottom earns a handful of credits a season, so this has to be affordable at
## the bottom and trivial at the top — which is the same shape as NEGOTIATE_COST
## and for the same reason.
const KIT_COST_FULL: int = 5


## What the armorer wants for one visit, 1 CC at a scratch and KIT_COST_FULL at
## a harness that is falling apart.
## AGAINST HIS OWN CEILING, not against a perfect harness. A man in borrowed kit
## cannot be polished past 0.82, so charging him for the gap to 1.00 would be the
## armorer billing for work he is about to refuse to do.
static func kit_cost(card: FighterCard) -> int:
	var top := Quartermaster.ceiling(card)
	return clampi(int(ceil((top - card.armor) * float(KIT_COST_FULL))), 1, KIT_COST_FULL)


## BUY A MAN A BETTER HARNESS. One rung at a time, and no throttle — unlike a
## repair this is not a thing a club does every week, it is a thing a club does
## once per man and then lives with.
##
## THE NEW KIT ARRIVES FRESH, at the top of its own grade. Charging for
## tournament plate and handing over a rattling one would be a shop selling
## condition and delivering grade.
func buy_harness(card: FighterCard) -> String:
	var next := Quartermaster.next_grade(card)
	if next < 0:
		return "%s is already in tournament plate." % card.display_name
	var cost := Quartermaster.upgrade_cost(card)
	if credits < cost:
		return "That costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_KIT)
	card.harness = next
	card.armor = Quartermaster.ceiling(card)
	return ""


## ONE VISIT A WEEK, PER MAN, on the same throttle every other per-man purchase
## uses — without it a club with credits walks a wrecked squad back to new in an
## afternoon, which is the armorer as a vending machine rather than a decision.
func repair_kit(card: FighterCard) -> String:
	## AND THE REFUSAL SAYS WHICH KIND IT IS. "As good as it gets" on a borrowed
	## harness sitting at 0.82 reads as a bug; the player can see it is not full
	## and the armorer is telling him it is. Naming the grade turns a refusal
	## into the sales pitch for the next one.
	if Quartermaster.topped_out(card):
		## AND THE REFUSAL HAS TO BE TRUE. `topped_out` used to mean "within a
		## thousandth of his ceiling" and now means "within a hard week of it",
		## so a man at 0.85 of a 0.90 ceiling gets turned away — and telling him
		## his harness is "as good as borrowed gets" when the screen beside him
		## says 85% is the kind of small lie a player spots immediately and then
		## stops trusting every other refusal in the game.
		##
		## So there are three answers now, not two: nothing worth doing, nothing
		## MORE that can be done at this grade, and nothing better in the world.
		if card.armor < Quartermaster.ceiling(card) - 0.001:
			return "%s's kit is fine. Come back when there is something to do." \
				% card.display_name
		if Quartermaster.next_grade(card) < 0:
			return "%s's harness is as good as it gets." % card.display_name
		return "%s's %s harness is as good as %s gets. He needs better kit." % [
			card.display_name, Quartermaster.name_of(card).to_lower(),
			Quartermaster.name_of(card).to_lower()]
	var slot := "kit:%s#%d" % [card.display_name, card.number]
	if _throttled(slot):
		return "The armorer has already had %s's kit this week." % card.display_name
	var cost := kit_cost(card)
	if credits < cost:
		return "That costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_KIT)
	card.armor = clampf(card.armor + KIT_STEP, 0.0, Quartermaster.ceiling(card))
	_mark(slot)
	return ""


## ------------------------------------------------------------ extra reps
## THE THIRD ROW, and the function for it was written months ago and never
## called. `Career.level_cost` carries the comment *"BUYING ONE, which is their
## meeting — go through some extra reps on the training field"* — somebody had
## this exact screen in mind, wrote the price, and never wired the button.
##
## It buys the XP, not the point. Placing a level is a decision — which of five
## stats goes up — and that decision is the whole of the row above this one on
## the fighter screen. Buying the man to the bar and letting the player choose
## keeps both halves: the credits answer "can he improve", the buttons answer
## "at what".
func buy_level(card: FighterCard) -> String:
	if Career.at_ceiling(card):
		return "%s has nothing left to learn." % card.display_name
	if Career.can_level(card):
		return "%s already has a level waiting. Spend it." % card.display_name
	var slot := "reps:%s#%d" % [card.display_name, card.number]
	if _throttled(slot):
		return "%s has done his extra reps this week." % card.display_name
	var cost := Career.level_cost(card)
	if credits < cost:
		return "That costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_SQUAD)
	card.xp = Career.next_level_at(card)
	_mark(slot)
	return ""


## AND THE OTHER DOOR ON THE SAME MAN: pay to raise his CEILING.
##
## `buy_level` above moves a man up. This moves where he can get to, which is the
## job paid training now has — see `Career.RAISE_COST_PER` for why the two were
## the same thing and why that made the old one worthless.
##
## Throttled on the SAME slot as his extra reps, deliberately. They are one
## week's attention from one coaching staff on one fighter, and letting a club
## buy both every week would make the throttle a formality.
func raise_ceiling(card: FighterCard) -> String:
	if not Career.can_raise_ceiling(card):
		return "%s is as far along as a fighter his age gets." % card.display_name
	var slot := "reps:%s#%d" % [card.display_name, card.number]
	if _throttled(slot):
		return "%s has done his extra reps this week." % card.display_name
	var cost := Career.raise_cost(card)
	if credits < cost:
		return "That costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_SQUAD)
	Career.raise_ceiling(card)
	_mark(slot)
	return ""


static func throttle_word(what: String) -> String:
	return "The %s has already been worked on this week. One job at a time." % what


# ------------------------------------------------------------------- upkeep
## BUILDINGS COST MONEY TO KEEP. Pete, 10 Sep 2026: *"the ground decay, you'll
## want to have to maintain them."*
##
## Retro Bowl does this by decaying facilities a level a season and making you
## re-buy the step. Same loop here with the price written on it: every summer
## each building bills a fraction of what its CURRENT level cost to build, and
## anything the club cannot pay for drops a level.
##
## The fraction is the whole design. At 45%:
##
##   Training ground / Infirmary   2 CC a year at level 1, 5 at level 5
##   Club gym            3      Fenced ground      6
##   Sports hall        10      Arena             18
##   National Arena     27
##
## A fully built National club bills about 37 a summer against an income near
## 200, which sounds ignorable and is not, because THE BILL IS NOT THE PENALTY —
## the rebuild is. Skipping a 27-credit bill on the National Arena costs 60 to
## put back. That asymmetry is what makes maintenance a thing you do rather than
## a thing you weigh.
##
## And it is what finally makes RELEGATION hurt. A club that overbuilds and goes
## down keeps the bills of the division it left while earning the income of the
## division it landed in — the ground starts shedding levels, the fan cap falls
## with it, and the following it spent ten years building gets clamped down to
## the smaller house. Nothing else in this game punished overreach; the whole
## economy was one-way until this existed.
## CUT FROM 0.45 TO 0.28 ON 15 Sep 2026, and the reason is that the recurring
## bite is now charged twice.
##
## When this was written it was the ONLY standing cost in the game, and 45% of a
## building's price every summer was sized to be the thing that punishes
## overreach. Then the membership subscription stopped funding the club and
## `League.dues_for(tier)` started billing it — Pete, 15 Sep 2026: *"league dues
## at the start of a season, one in which you CAN go negative but it's a good
## bite."*
##
## `tools/probe_run.gd` measured what two bites came to: upkeep 10.3 credits a
## season against an income of 22.6, plus 6.2 of entry fee — **73% of everything
## the club earned, before it bought anything**, and five buildings lost per
## twenty-season career. Retro Bowl's equivalent is a facility decaying one level
## and costing that level to re-buy: 5 credits against a season of 16 to 70, so a
## tenth of their income where ours was nearly half.
##
## **A cost added beside an existing one has to be argued against the total, not
## against zero.**
const UPKEEP_FRACTION: float = 0.28


## What each building costs to keep this year. Rounded UP, so no level is ever
## free to hold — a bill of zero is a building that is not really maintained.
static func upkeep_of(build_cost: int) -> int:
	return 0 if build_cost <= 0 else int(ceil(float(build_cost) * UPKEEP_FRACTION))


## THE GROUND'S BILL IS DERIVED FROM WHAT THE GROUND PAYS, not from what it cost.
##
## The rule this has to satisfy has been in the register since the bills went in:
## **no ground is profitable to simply own.** Letting the retainer cover the
## upkeep turns the arena into a savings account and the events it was built for
## stop mattering.
##
## It used to satisfy that rule by coincidence — `45% of the build cost` happened
## to sit above `capacity^0.30 x 0.72` at every rung — and the moment
## `UPKEEP_FRACTION` came down to 0.28 the two ladders crossed and a National
## Arena paid 21 to own and cost 17 to hold. `test_office.gd` caught it on the
## first run, by name.
##
## **A rule kept by two numbers that happen to agree is a rule waiting for one of
## them to move.** So the bill reads the retainer and adds a margin that grows
## with the ground: 4 / 7 / 10 / 15 / 30 up the ladder, always more than it pays.
const UPKEEP_MARGIN: float = 0.14


func arena_upkeep() -> int:
	return arena.retainer_full() + maxi(1, int(ceil(
		float(Arena.LEVELS[arena.level]["cost"]) * UPKEEP_MARGIN)))


func facility_upkeep(f: int) -> int:
	var l := level(f)
	return 0 if l <= 0 else upkeep_of(FACILITY_COST[l - 1])


func upkeep_bill() -> int:
	var t := arena_upkeep()
	for f in facilities.keys():
		t += facility_upkeep(int(f))
	return t


## The summer bill. Returns what happened so the screen can say it plainly —
## a decay the player is not told about is a bug he will report as one.
##
## THE ARENA IS PAID FIRST because it is the thing that earns: letting the ground
## fall while a Training ground survives would cost the club its income to keep a
## coaching bonus, which is never the trade a player would have chosen. Anything
## still unpaid after that drops a level, and a ground that drops takes its fan
## cap down with it — see `_clamp_fans`.
func pay_upkeep() -> Dictionary:
	var billed: int = 0
	var lost: Array[String] = []

	var a := arena_upkeep()
	if a > 0:
		if credits >= a:
			spend(a, LINE_GROUND)
			billed += a
		elif arena.level > 0:
			arena.level -= 1
			lost.append(String(Arena.LEVELS[arena.level + 1]["name"]))

	for f in facilities.keys():
		var key := int(f)
		var c := facility_upkeep(key)
		if c <= 0:
			continue
		if credits >= c:
			spend(c, LINE_FACILITIES)
			billed += c
		else:
			facilities[key] = level(key) - 1
			lost.append(String(FACILITIES[key]["name"]))

	## AND THE FEDERATION'S BILL, which is different in kind from the two above
	## and so is charged differently. A ground or a facility you cannot afford
	## FALLS A LEVEL — it is a building and buildings decay. A certificate you do
	## not renew does not decay, it LAPSES: the level goes to nothing at all, and
	## a club that could not find three credits for its insurance is not
	## partially insured.
	var lapsed: Array[String] = []
	for r in Federation.rules():
		var lvl := rule_level(r)
		if lvl <= 0:
			continue
		var c: int = int(Federation.UPKEEP[r]) * lvl
		if credits >= c:
			spend(c, LINE_FEDERATION)
			billed += c
		else:
			compliance[r] = 0
			lapsed.append(String(Federation.RULE_NAME[r]))

	_clamp_fans()
	return {"billed": billed, "lost": lost, "lapsed": lapsed}


# ---------------------------------------------------------- the ground itself
## The arena, and the following that fills it. All of it lives here because the
## Clubhouse is where they are spent and earned, and because a save that carries
## an office carries a club's whole standing in one object.
var arena := Arena.new()

## THE FOLLOWING, AND IT IS THE ONLY CROWD NUMBER LEFT.
##
## Pete, 15 Sep 2026: *"I don't like our 3 factors, there should be one.
## Notoriety should be something of a coach trait."*
##
## THERE WERE THREE NUMBERS DOING ONE JOB. `notoriety` (1–125, the turnout
## percentage), `fans` (the following, capped by the ground) and `members` (who
## paid the dues) were three separate populations, three screens to explain them
## on, three save fields and three sets of tuning constants — all of them
## answering the same question, *how many people care about this club*.
##
## Retro Bowl has exactly one: a fan bar, and every credit in the game comes off
## it. Part 3 of the teardown put the comparison side by side and it is not close
## — their single meter is *"the first thing a player learns to read"* and ours
## was three meters nobody could tell apart.
##
## So: **the following is the number, and how many of them get in is the gate.**
## `fans` is a pool built over years and capped by the ground; `attendance()` is
## how many of them the ground can hold; the band reads attendance and pays the
## gate. One chain, four links, exactly theirs with our arena in the middle of it.
##
## WHERE NOTORIETY WENT. Onto the coach, where Pete put it — a reputation is a
## fact about the man and not about the club, so it follows him through a door
## and it now decides what the dilemma deck offers him rather than what the gate
## pays. See `Coach.reputation` and `Dilemma.deck_for`.
var fans: float = 12.0

## FANS GROW TOWARD THE GROUND YOU BUILT. Logistic rather than linear: a win adds
## a fraction of the GAP to the ceiling, so a small club grows slowly, a club
## that has just built a bigger ground grows fast into it, and nobody has to
## invent a per-division fan number. Upgrading the arena is what raises the
## ceiling, which is exactly the sink Pete asked for seen from the other side.
const FANS_WIN_GAP: float = 0.075
const FANS_DRAW_GAP: float = 0.025
const FANS_LOSS: float = -0.022
## Half of everyone who came is a fan afterwards.
const FANS_PER_HEAD: float = 0.5
## And they bleed. A club that stops winning stops filling seats — Pete's
## "bleeding slowly", and the reason a following is worth defending.
const FANS_DECAY: float = 0.94

## GOING UP BRINGS PEOPLE AND GOING DOWN LOSES THEM, as a fraction of the room
## left rather than a flat number — these replace `NOTE_PROMOTED` (+6) and
## `NOTE_RELEGATED` (−5), which moved a scale that no longer exists. A promotion
## is about a fifth of the way to the new ground's ceiling, which is a visible
## jump on a screen and still leaves the club something to earn.
const FANS_PROMOTED: float = 0.20
const FANS_RELEGATED: float = -0.12


func fan_cap() -> float:
	## A QUARTER MORE THAN THE GROUND HOLDS. Pete: *"each level can have 25% over
	## their max upgraded arena… 25% of fans usually never come to events."* So a
	## club at the ceiling sells out and turns people away, which is the top of
	## the whole system and is meant to be reachable.
	return float(arena.capacity()) * 1.25


## HOW MANY MORE THAN THE FOLLOWING TURN UP. This was `turnout()` and it was
## `notoriety / 125` — the second population dividing the first. With one number
## there is nothing to divide by: everybody who follows the club would come, and
## the ground is what decides how many get in.
##
## What is left is the DRAW trait, which is the only thing in the game that pulls
## people who do not already follow you. Additive, capped, and worth having a
## name for: a man who is worth an extra tenth of a house is a man you pick.
const DRAW_MAX: float = 1.60


func draw_scale() -> float:
	var extra := 0.0
	for f in _draws:
		extra += f
	return clampf(1.0 + extra, 1.0, DRAW_MAX)

## Set by the season from whoever travelled. Kept as a list rather than a sum so
## a squad with two of them is visibly two of them.
var _draws: Array[float] = []


func set_draws(eight: Array) -> void:
	_draws.clear()
	for f in eight:
		var d := FighterTrait.mod(f.trait_id, "turnout", 0.0)
		if d > 0.0:
			_draws.append(d)


## HOW MANY CAME, and it is the number the whole economy now reads.
##
## It used to be a read-out — *"the figure a screen shows when it wants to say
## how full the place looked"* — while `crowd_pay()` was banded off notoriety and
## `gate_income()` off capacity, so the one honest attendance figure in the game
## was the one thing nothing spent.
func attendance() -> int:
	return int(min(float(arena.capacity()), fans * draw_scale()))


## HOW FULL IT LOOKED, 0 to 1. Not what the gate reads — see `crowd_band()` for
## why — but what a screen says and what the overlay and the commentary want.
func fill() -> float:
	var c := float(arena.capacity())
	return 0.0 if c <= 0.0 else clampf(float(attendance()) / c, 0.0, 1.0)


## A RESULT, AND WHAT IT DOES TO THE FOLLOWING. `note_after` in the old money;
## the notoriety half of it is gone and the tier term with it, because a win at
## National is already worth more — it is watched by twelve thousand people
## instead of forty, and `attendance()` says so without a per-tier constant.
func after_event(won: bool, drew: bool) -> void:
	var gap := fan_cap() - fans
	if won:
		fans += gap * FANS_WIN_GAP
	elif drew:
		fans += gap * FANS_DRAW_GAP
	else:
		fans += fans * FANS_LOSS
	_clamp_fans()


## Up a division or down one, as a share of the room left.
func after_move(up: bool) -> void:
	if up:
		fans += (fan_cap() - fans) * FANS_PROMOTED
	else:
		fans += fans * FANS_RELEGATED
	_clamp_fans()


## A crowd turns up, and afterwards the club is bigger for it.
func crowd_came(heads: int) -> void:
	## FAN FAVORITE. He is the one they came to see, so the following grows
	## faster while he is here — and Retro Bowl's own wording adds the sting:
	## *"but takes a hit when fired."* See `release()` below; a trait with only an
	## upside is a purchase, not a decision.
	var gain := float(heads) * FANS_PER_HEAD
	if has_trait(Trait.FAN_FAVORITE):
		gain *= TRAIT_FANS
	fans += gain
	_clamp_fans()


## The summer. The following sags, which is what makes it something you defend
## rather than something you bank.
func winter() -> void:
	fans = maxf(0.0, fans * FANS_DECAY)
	_clamp_fans()


func _clamp_fans() -> void:
	fans = clampf(fans, 0.0, fan_cap())


## HOW BIG A CLUB THIS IS TO A FIGHTER DECIDING WHETHER TO WAIT, 0 to 1.
##
## AND IT IS THE ABSOLUTE SIZE OF THE HOUSE, not the fill — deliberately not the
## same number the gate reads.
##
## The gate asks *"did you fill the place"*, which is a question about this
## season and is the right question to pay on. A fighter deciding whether to wait
## for you is asking something else entirely: **how many people will watch me.**
## A packed back field is forty of them. If this read the band, a sold-out back
## field would out-pull a half-empty National Arena for a man's signature, which
## is the one thing about it nobody would believe.
##
## Log of the crowd against the biggest house in the country, so the climb from
## nobody to somebody is worth a real share of the curve — the property
## `test_office.gd` checks by name and the reason the old version carried a square
## root.
func pull() -> float:
	return clampf(log(1.0 + float(attendance())) / log(1.0 + BIGGEST_HOUSE),
		0.0, 1.0)


func note_word() -> String:
	return CROWD_WORD[crowd_band()]


# ------------------------------------------------------ what a crowd is worth
## RETRO BOWL'S ONE GOOD TRICK, taken on Pete's instruction (10 Sep 2026).
##
## Their fan meter is not decoration: it BANDS the per-game payout. At a third
## full a game pays one credit, at two thirds two, above that three — so a run of
## wins is worth triple what the same run was worth in a bad year, and the meter
## is the first thing a player learns to read.
##
## Ours did none of that. Notoriety moved the gate ONCE A YEAR at roll-over and
## every fight paid a flat 2 credits regardless, which meant the number the whole
## arena system is built on never reached the wallet on a timescale anybody
## feels. The teardown found this and it is the single biggest thing they do
## better.
##
## So: every league fight pays `crowd_pay()` for putting on the show, and the
## result pays on top. A band is worth a whole fight-win, which is what makes it
## worth chasing.
##
## THE BANDS READ HOW FULL THE GROUND IS, which is Retro Bowl's bar exactly.
##
## Theirs: *"For each third of this bar that is filled either in full or in part,
## you will receive one coaching credit at the end of each game."* A percentage,
## not a headcount — and the stadium is a separate facility that does not move it.
##
## THE FIRST CUT OF THIS BANDED ABSOLUTE HEADS — 25 / 90 / 300 / 1,000 / 6,000 —
## and it looked right on paper: each gate just under a filled ground, so filling
## the place you built is a band and building the next one is the next band. What
## it actually did was pin the bottom of the pyramid to band 0 forever. A Backyard
## club is twelve people in a forty-seat field; forty people is a SOLD-OUT HOUSE
## and it was being paid the same 1 CC as an empty one. `tools/probe_run.gd`
## measured a whole career's gate at 6.3 credits a season.
##
## **A club that fills the ground it has is doing the thing the game is asking
## for, whatever size the ground is.** So the band is the fill, the SIZE of the
## house is `Arena.gate_factor` where it already lived, and the two multiply. A
## packed back field is a full house paying full band at back-field rates; a
## National Arena a third full is a poor turnout paying poorly at National rates.
##
## AND UPGRADING STILL COSTS YOU A BAND UNTIL YOU FILL IT, which is both true and
## the same thing their stadium does — a bigger ground does not instantly pay.
## `fan_cap()` moves the ceiling the moment it is built and the following grows
## into it at 7.5% of the gap a win, so it is about a season and a half of work
## rather than a wall.
const CROWD_GATES: Array[float] = [0.10, 0.28, 0.46, 0.66, 0.88]
const CROWD_WORD: Array[String] = ["Nobody", "Talked about", "A name locally",
	"Known across the state", "Known nationally", "A household name"]
## Band 0 still pays. A club nobody has heard of is the club that most needs a
## trickle, and zero here would mean a bad first season in the Backyard Circuit
## could not buy its way out of being bad — the failure mode Retro Bowl's own
## early game has and the one part of their economy not worth copying.
##
## EVERY GATE MOVES THE MONEY. The first draft paid [1, 1, 2, 3, 4, 5], so the
## first gate changed the word on the screen and nothing else: a club crossed the
## first gate, got told it was "Talked about", and was paid exactly what it was
## paid for being nobody. A meter with a dead segment in it teaches the player
## that the meter sometimes lies, and then he stops reading it. One pay level per
## band, no exceptions — test_office asserts the tick.
##
## The top band is worth 6 CC a fight against a win's 2, which is the Retro Bowl
## relationship and the point of the whole exercise: **who is watching matters
## more than who won.** A National club in front of a full house out-earns a
## Backyard champion six to one before a single result is counted.
## COMPRESSED FROM [1..6] TO [2..7], and the reason is what banding on FILL
## exposed rather than any change of intent.
##
## On the old fame ladder a club climbed through the bands once and stayed high;
## on this one a club that stops filling its ground **falls back down them**, and
## a career club sits around band 2 for years. At [1..6] band 2 was three
## sevenths of the top and a struggling club earned 3 CC a fight against costs
## that do not fall with it — `probe_run` measured a twenty-season career pinned
## at 0.85 of its division with two buildings lost.
##
## Retro Bowl's own bar is 1 / 2 / 3: **their bottom band is a third of their
## top, not a sixth.** Theirs can afford to be flat because they have no
## divisions; ours has `Arena.gate_factor` doing the climbing (1.0 to 2.2), so
## the band does not need to carry the whole spread and should not.
##
## The top still pays a whole fight-win more than the bottom, which is the
## property `test_office.gd` asserts and the reason the meter is worth reading.
const CROWD_PAY: Array[int] = [2, 3, 4, 5, 6, 7]
## Where the top band's meter fills to — a sold-out house, so a club at capacity
## reads full rather than reading "just started band 5" forever.
const CROWD_TOP: float = 1.0
## AND THE BIGGEST HOUSE IN THE COUNTRY, which is what `pull()` measures against.
const BIGGEST_HOUSE: float = 80000.0


## 0 to 5, and it is the index into both the word and the pay.
func crowd_band() -> int:
	var f := fill()
	var b := 0
	for g in CROWD_GATES:
		if f >= g:
			b += 1
	return b


## WHAT A FIGHT PAYS FOR BEING WATCHED, before the result is counted.
##
## THE BAND IS YOUR OWN HOUSE AND THE ROOM IS WHOSEVER IT IS. That split is the
## whole model and it is the honest one: the band is how many people you can put
## in a room, and the venue decides whose room it is and what share of the door
## comes back to you. So a big club at a tip takes a tip's share of a big crowd,
## and a small club that draws a National Arena takes more than it has ever seen.
##
## `kind` is the venue, `host_level` and `host_condition` are the GROUND IT IS
## FOUGHT IN — yours at home, theirs away, the federation's on neutral ground.
## Pete, 15 Sep 2026: *"you may actually look forward to an opponent with a great
## stadium or roll your eyes from an opponent with a shitty arena."*
##
## A FLOOR OF ONE, for the same reason band 0 pays at all: **a multiplier that
## can legitimately reach zero annihilates whatever it is applied to**, and this
## project has already lost twenty seasons of gate income to exactly that. A club
## nobody has heard of, away, at a ruin, still comes home with a credit.
func gate_for(kind: int, host_level: int, host_condition: float) -> int:
	return maxi(1, int(round(float(CROWD_PAY[crowd_band()])
		* Venue.gate_share(kind)
		* Arena.worth(host_level, host_condition))))


## THE OLD DOOR, kept for the screens that want "what is a home fight worth" as a
## headline figure rather than for a particular fixture. It is the club's own
## ground at home, which is the question those screens are actually asking.
func crowd_pay() -> int:
	return gate_for(Venue.Kind.HOME, arena.level, arena.condition)


## How far along the current band we are, 0 to 1 — the meter itself. The top band
## fills against the ceiling, so a club at 125 reads full rather than reading
## "just started band 5" forever.
func crowd_meter() -> float:
	var b := crowd_band()
	var lo: float = 0.0 if b == 0 else CROWD_GATES[b - 1]
	var hi: float = CROWD_TOP if b >= CROWD_GATES.size() else CROWD_GATES[b]
	if hi <= lo:
		return 1.0
	return clampf((fill() - lo) / (hi - lo), 0.0, 1.0)


## What the ground pays you just for existing: the federation rotates who hosts,
## and a better ground takes a bigger turn.
##
## IT IS MEANT TO BE SMALL AND IT WAS NOT. At `^0.62 x 0.22` a full National
## Arena paid **284 CC every summer for doing nothing** — nearly five times the
## cost of the arena itself, every year, forever. tools/probe_economy.gd found it
## the first time anybody put a season's income next to a season's prices: a
## National club earned 394 a year against a 60-credit ground, so every sink in
## the game was decorative above the State League and the crowd banding that was
## just added was 19% of an income it was supposed to drive.
##
## The exponent is the whole bug. At 0.62 this grows nearly as fast as the crowd
## does, so it is really "attendance, paid twice" — once here and once through
## the event gate, where it belongs. At **0.30** it grows like the LOG of the
## crowd: 2 CC at a back field, 6 at a sports hall, 11 at an arena, 22 at a full
## National Arena. A tenth of what it was at the top and almost unchanged at the
## bottom, which is the right shape for a retainer.
##
## The events are where the arena earns. That sentence was already in this
## comment and the code disagreed with it.
##
## ---------------------------------------------------------------------------
## AND IT DISAGREED WITH IT AGAIN, in the other direction, and paid NOTHING.
##
## Every figure in the paragraph above is a CAPACITY. 40 at a back field gives
## `40^0.30 x 0.72 = 2`; a sports hall's 1,200 gives 6; an arena's 12,000 gives
## 11; a National Arena's 80,000 gives 22. Those are the four numbers written
## down, and they are the four numbers the ground's own size produces.
##
## The function was reading `attendance()` — capacity multiplied by `turnout()`,
## which is `notoriety / 125`. A club that has not made a name yet sits at the
## notoriety FLOOR of 1.0, so its turnout is 0.008, and 12 followers times 0.008
## is 0.096, and `int()` of that is ZERO. Not a small gate: no gate, and no gate
## for as long as the club is unknown, which at the bottom of the pyramid is
## forever.
##
## A twenty-season walk found it as a column of noughts. Every other line in the
## summer ledger was doing something; this one paid 0 in all twenty years, and
## the club's entire income was its members' dues, which fall as it loses.
##
## **A multiplier that can legitimately reach zero annihilates whatever it is
## applied to.** That is the same shape as the sentinel that was a legal value
## and the guard that could only fail: the fault is never the number, it is that
## nothing downstream can tell "very small" from "not there".
##
## A RETAINER IS NOT A GATE. It is what the federation pays for the ground
## existing and being available to host — *"the federation rotates who hosts, and
## a better ground takes a bigger turn."* It is a fact about the GROUND. What the
## crowd is worth is `gate_for()`, paid at every fixture off the ATTENDANCE band
## and the venue's share, and that one already reads the crowd correctly, floors
## at 1 for a club nobody has heard of, and says in its own comment why: *"a club
## nobody has heard of is the club that most needs a trickle."*
## THE TWO CONSTANTS MOVED TO `Arena`, with the condition that scales them —
## `Arena.RETAINER_POW` and `Arena.RETAINER_K`. What a ground is worth is a fact
## about the ground, and this file had it because this file happened to be where
## the arithmetic was written. Everything below still forwards.


## THE RETAINER THE GROUND PAYS ACROSS A SEASON, and what state it is in now
## decides how much of it arrives.
##
## `arena.gate_scale()` is 1.0 at a spotless ground and 0.45 at a ruin, so a club
## that lets its ground go is earning a little over half what it built. That is
## the whole of Pete's *"it raises your income but costs to maintain as it
## degrades"* — the raise is the level, the cost is the upkeep, and the slide
## between them is this multiplier.
func gate_income() -> int:
	return arena.retainer()


## AND WHAT IT WOULD BE IF THE GROUND WERE KEPT. The finances screen shows both,
## because "you are losing four credits a season to rubbish" is an argument and
## "you earn eleven" is a number.
func gate_income_full() -> int:
	return arena.retainer_full()


## PUT THE GROUND RIGHT. One visit a week, like the armorer, and for the same
## reason: without a throttle a club with credits walks a ruin back to new in an
## afternoon and the whole axis becomes a vending machine.
func tidy_arena() -> String:
	if arena.condition >= 0.999:
		return "The ground is already spotless."
	if _throttled(SLOT_TIDY):
		return "The ground has already been seen to this week."
	var cost := arena.upkeep_cost()
	if credits < cost:
		return "That costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_GROUND)
	arena.condition = 1.0
	_mark(SLOT_TIDY)
	return ""


func training_points() -> int:
	return level(Facility.TRAINING) * 3


## WHAT THE TRAINING GROUND IS WORTH TO A WEEK'S PRACTICE, as a multiplier.
##
## The facility already hands out `training_points` at the winter — the club's
## one lump of directed coaching a year. Retro Bowl's equivalent does something
## else entirely and does it every week: *"Improving training facilities means
## players gain XP faster."* Both are worth having and they are not the same
## thing, so the ground now does both — a lump in the summer and a rate all
## season.
##
## Modest per level on purpose. At level 5 a week's practice is worth half again
## what it is in a shed, which is a reason to build and not a reason to build
## before anything else.
const GROUND_PRACTICE: float = 0.10


func practice_ground() -> float:
	return 1.0 + GROUND_PRACTICE * float(level(Facility.TRAINING))


## ------------------------------------------------------- an extra session
## WHAT A TEAM TRAINING SESSION COSTS. Pete, 15 Sep 2026: *"we can go with a
## 'team training' CC sink that may work."*
##
## `tools/probe_pace.gd` had a club ending every season with sixty to ninety
## unspent credits — there is more money in this economy than there are things
## worth buying with it — and the practice week gave the money somewhere to go
## that it could not reach: the captains are hired once, the ground is built
## once, and neither absorbs a surplus that arrives every week.
##
## A SHARE OF THE DIVISION'S SLACK, like the signing fee, so it means the same
## thing at every rung: 2 / 4 / 4 / 8 credits against a season's 16 / 33 / 37 /
## 67. Roughly a fifth of a season's spending money buys a full extra week's
## work for the whole squad, and the throttle keeps a windfall from buying a
## career — one session a matchday, the same rule every building here follows.
const SESSION_SHARE: float = 0.12
const SLOT_SESSION := "session"


func session_cost() -> int:
	return maxi(1, int(round(SESSION_SHARE
		* float(League.TIERS[clampi(tier, 0, League.TIERS.size() - 1)]["slack"]))))


## The money half only. `Season.run_session` does the work, because the squad is
## the season's and because a session that banked a promise in `built_this_week`
## would be a promise a reload loses — `built_this_week` is not saved, so a
## player who paid on Tuesday and closed the game would have bought nothing.
## Paying for a thing and having it happen is one step or it is a bug.
func charge_session() -> String:
	if _throttled(SLOT_SESSION):
		return "The squad has already had its extra session this week."
	var cost := session_cost()
	if credits < cost:
		return "A session costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_SQUAD)
	_mark(SLOT_SESSION)
	return ""


func injury_relief() -> int:
	return int(floor(float(level(Facility.INFIRMARY)) / 2.0))


# ------------------------------------------------------------------- captains
## A CAPTAIN TEACHES UP TO TWO ROLES, AND HIS STARS SAY HOW MANY.
##
## Pete, 11 Sep 2026: *"each captain can cover up to two positions in their
## leadership. Rail/Flanker, Rail/Center, Center/Flanker. Which will always make
## one position have an overlap, making it so the teams will have a 'specialty'.
## Low Star staff can have no specialties or just one specialty. So a One Star
## will have no specialty but just generally help. Mid star staff will have one
## specialty, and High star can have two specialties."*
##
## There are three jobs on a line — Rail, Flanker, Center. A role a captain
## specializes in is **taught**, a role no captain specializes in is **not**,
## and that half of it is binary: a man has been shown how to fight that
## position or he has not. What the grade changes is HOW MANY roles the man can
## show anybody — see specialty_count() — so the stars are the thing you are
## buying rather than a decoration next to the name.
##
## I built it wrong three times before this. First a primary worth 2 and a second
## worth 1, then head-counts with an Elite tier on top: both produced a role that
## could be half-taught or better-than-taught, and neither is a thing. Then every
## captain got two specialties regardless of grade, which made a one-star and a
## five-star identical hires.
##
## TWO FIVE-STAR CAPTAINS GIVE FOUR SLOTS OVER THREE ROLES, so a top staff always
## overlaps somewhere. That overlap is not waste — it is the club's **specialty**
## (club_specialty()), the job the place is known for, and men who stand in it
## develop faster. A captain who teaches nothing still lifts the room
## (presence()). There is no way to buy a role above Hardened.
## THE PRICE IS THE STARS. It was a flat 5 CC while every captain taught two
## roles whatever his grade, and a flat price with a graded product means the
## only sensible move is to wait for a five-star — the decision evaporates.
## A one-star is cheap and lifts the room; a five-star teaches two jobs and is
## most of a season's savings.
const CAPTAIN_COST: int = 5
const CAPTAIN_COST_PER_STAR: int = 3
## How long a new captain signs for, and what one more year costs. Extending is
## deliberately cheap against hiring: keeping the man you have should be the easy
## decision and finding a better one the expensive one.
const CAPTAIN_YEARS: int = 3
const CAPTAIN_EXTEND: int = 2
const MAX_CAPTAINS: int = 2
const SPECIALTIES: int = 2


static func cost_of(c: Dictionary) -> int:
	return CAPTAIN_COST + CAPTAIN_COST_PER_STAR * (int(c.get("grade", 1)) - 1)

## THE TRAINING REGIME, and these numbers are Retro Bowl's own.
##
## The field existed here for days as three words on a screen: drawn, never
## settable, and read by nothing. Pete: *"Look up how Retro Bowl uses Training
## Regime."* So rather than inventing a trade, it was read out of the shipped
## GameMaker build — `s_training_regime_effect_on_morale`, `s_get_training_reg`
## and the XP and condition paths, `training_reg_of` / `training_reg_df`,
## default 2.
##
## Their regime does FOUR things at once, which is why it is a real decision and
## not a slider:
##
## | | XP | morale a week | condition | injury odds |
## |---|---|---|---|---|
## | Light | ×0.6 | +0 to +2 | +10 on a big rest | 10% of base |
## | Normal | ×1.0 | — | — | 20% of base |
## | Hard | ×1.5 | −1 to −3 | −10 on a big rest | **100% of base** |
##
## The injury column is the one that makes it bite: Hard is not 50% riskier than
## Normal, it is **five times** riskier. Development is bought with bodies.
##
## WHAT CHANGES IN TRANSLATION: they split the regime by side of the ball,
## because their staff are an offensive and a defensive coordinator. Ours are
## CAPTAINS, and a captain covers roles rather than a side — so the regime is
## per captain and applies to the roles he teaches. Same shape, our taxonomy.
enum Regime { LIGHT, NORMAL, HARD }

const REGIME_NAME := { Regime.LIGHT: "Light", Regime.NORMAL: "Normal", Regime.HARD: "Hard" }
const REGIME_XP := { Regime.LIGHT: 0.6, Regime.NORMAL: 1.0, Regime.HARD: 1.5 }
## Morale a week, as a fraction of the 0-1 scale this game keeps it on. Theirs
## is 1-100 and moves 0..+2 or -1..-3; scaled, that is the same weight.
const REGIME_MORALE := { Regime.LIGHT: 0.015, Regime.NORMAL: 0.0, Regime.HARD: -0.020 }
## Armor condition a week. Theirs adds or removes 10 of 100 on a big rest.
const REGIME_WEAR := { Regime.LIGHT: 0.10, Regime.NORMAL: 0.0, Regime.HARD: -0.10 }
## And the multiplier on a knock actually landing.
const REGIME_INJURY := { Regime.LIGHT: 0.10, Regime.NORMAL: 0.20, Regime.HARD: 1.00 }


## WHICH REGIME APPLIES TO A ROLE. A role a captain teaches is trained his way;
## a role NOBODY teaches is trained nobody's way, which is Normal — the man is
## turning up and doing what he has always done.
func regime_for(role: int) -> int:
	for c in captains:
		if specialties_of(c).has(role):
			return int(c.get("regime", Regime.NORMAL))
	return Regime.NORMAL


func set_regime(index: int, regime: int) -> String:
	if index < 0 or index >= captains.size():
		return "There is no captain in that job."
	if regime < Regime.LIGHT or regime > Regime.HARD:
		return "That is not a regime."
	captains[index]["regime"] = regime
	return ""


## The four multipliers, by the role a man stands in.
func regime_xp(role: int) -> float:
	return float(REGIME_XP[regime_for(role)])


func regime_morale(role: int) -> float:
	return float(REGIME_MORALE[regime_for(role)])


func regime_wear(role: int) -> float:
	return float(REGIME_WEAR[regime_for(role)])


func regime_injury(role: int) -> float:
	return float(REGIME_INJURY[regime_for(role)])

## captains are dictionaries: name, specialties (two roles), grade (1-5), regime.
var captains: Array[Dictionary] = []


static func captain(nm: String, a: int, b: int, grade: int = 2,
		trait_: int = Trait.NONE) -> Dictionary:
	## HIS GRADE SAYS HOW MANY HE TEACHES. Two different roles at the top, one in
	## the middle, none at the bottom — and a captain who lists the same job
	## twice knows one job, which is the half-coverage the whole model exists to
	## refuse.
	var second: int = b if b != a else (a + 1) % 3
	var spec: Array = [a, second]
	spec.resize(specialty_count(grade))
	return {
		"name": nm, "specialties": spec, "grade": grade,
		"regime": Regime.NORMAL, "trait": trait_,
		## A CAPTAIN IS ON A DEAL, like everybody else at the club.
		## `msg_StaffExpiring`: *"Your $position's contract expires at the end of
		## this season."* Without it a five-star hired in season two is yours for
		## twenty years for five credits, and the staff room — the screen with the
		## sharpest decision in the game on it — is visited once and never again.
		"years": CAPTAIN_YEARS,
	}


## WHAT ELSE A CAPTAIN BRINGS, beyond the jobs he teaches.
##
## These are Retro Bowl's nine coach traits, and the thing worth saying about
## them is that I had them on the wrong object. I read "coach trait" and built
## them as properties of the PLAYER — your own nine perks, chosen at the start.
## The shipped build disagrees: every one of them is read off `staff_hire`, and
## every description is scoped — *"Instant morale boost for $pos players"*,
## *"Toxic players ($pos) have no negative impact on teammates"*. They belong to
## the man you hire, and they apply to the roles he covers.
##
## Which is a better system than the one I was about to write, because it makes
## the hire a real comparison: a four-star who teaches the two jobs you need
## against a three-star Physio whose men never gas. And it lands on the object
## that already has a scope — a captain's specialties are exactly the "$pos" the
## descriptions are talking about.
##
## A captain with no specialties (a one-star) applies his trait to NOBODY, which
## is the same rule as his teaching and keeps the grade honest: the stars buy
## reach, and a trait with no reach is worth nothing.
## TACTICIAN IS APPENDED, not inserted. Every captain in every save carries his
## trait as an int, so slotting a new one into the middle would silently turn
## every Physio in the country into a Likeable — the same renumbering trap the
## `Facility` enum has a paragraph about further up.
enum Trait {
	NONE, EXPERIENCE, TALENT_SPOTTER, MOTIVATOR, NEGOTIATOR,
	FAN_FAVORITE, PHYSIO, LIKEABLE, POSITIVE, SCOUT, TACTICIAN,
}

const TRAIT_NAME := {
	Trait.NONE: "None", Trait.EXPERIENCE: "Experience",
	Trait.TALENT_SPOTTER: "Talent Spotter", Trait.MOTIVATOR: "Motivator",
	Trait.NEGOTIATOR: "Negotiator", Trait.FAN_FAVORITE: "Fan Favorite",
	Trait.PHYSIO: "Physio", Trait.LIKEABLE: "Likeable",
	Trait.POSITIVE: "Positive", Trait.SCOUT: "Scout",
	Trait.TACTICIAN: "Tactician",
}

## Their own wording, in our nouns. Each one names the thing it moves so the
## screen does not have to explain a trait twice in two places.
const TRAIT_BLURB := {
	Trait.NONE: "No trait. He teaches, and that is all.",
	Trait.EXPERIENCE: "His men bank a point of training the day he arrives.",
	Trait.TALENT_SPOTTER: "His men gain ceiling the day he arrives.",
	Trait.MOTIVATOR: "His men lift the day he arrives.",
	Trait.NEGOTIATOR: "His men re-sign for less.",
	Trait.FAN_FAVORITE: "The following grows faster, and falls when he goes.",
	Trait.PHYSIO: "His men come out of the corner with more left.",
	Trait.LIKEABLE: "A toxic man of his drags nobody down.",
	Trait.POSITIVE: "His men train faster.",
	Trait.SCOUT: "More names on the free-agent list.",
	Trait.TACTICIAN: "One more call from the corner, every bout.",
}

## THE ARRIVAL TRAITS fire once, when he is hired. The rest are read every week.
const ARRIVAL_TRAITS: Array[int] = [Trait.EXPERIENCE, Trait.TALENT_SPOTTER, Trait.MOTIVATOR]

const TRAIT_XP_BANKED: int = 8          ## Experience, on arrival
const TRAIT_CEILING: int = 3            ## Talent Spotter, on arrival
const TRAIT_MORALE: float = 0.10        ## Motivator, on arrival
const TRAIT_NEGOTIATOR: float = 0.85    ## Negotiator, on a re-signing
const TRAIT_FANS: float = 1.25          ## Fan Favorite, on the following
const TRAIT_PHYSIO: float = 0.06        ## Physio, on corner recovery
const TRAIT_POSITIVE_XP: float = 1.15   ## Positive, on training
## SCOUT, on the free-agent list. It said *"More men at the trials"* and pointed
## at a system that has since been cut (see register §46), which left a trait
## with a description and no code — the exact state the training regime sat in
## for a week before anybody noticed. It reaches the market instead, which is now
## the only inflow there is and is the better place for it anyway: the thing a
## scout is actually good at is finding a name nobody else has looked at.
const TRAIT_SCOUT_EXTRA: int = 3

## ---------------------------------------------------------------- TACTICIAN
## THE UPGRADE PATH FOR TACTICAL CALLS — Pete, 13 Sep 2026: *"you should be able
## to upgrade through either a rare coaching trait or facility upgrade."*
##
## It is the trait and not a facility, for three reasons. The facility list was
## cut down to two ON PURPOSE — see the note above `enum Facility`: "two
## facilities feeding the same gate, with no way to reason about which to spend
## on" — and adding a third walks back a decision made for a stated reason.
## Facilities are bought with credits, and a call you can buy is a call every
## player has by season three, which is not an upgrade, it is a delay. And a
## trait makes it a HIRE: a four-star Tactician against a three-star Physio whose
## men never gas is the comparison the staff room exists for.
##
## WHERE IT BENDS THE REACH RULE, said out loud rather than left to be noticed.
## Every other trait applies only to the roles its captain covers, and a call
## from the corner is not addressed to a role — you stop the fight, you do not
## stop the Rail. So the scoping clause that survives is the one that actually
## carries the rule's weight: `has_trait` already refuses a captain with no
## specialties, so a one-star Tactician is worth nothing, exactly like a one-star
## Physio. The stars still buy reach; reach just stops at "any" here instead of
## naming which.
const TRAIT_TACTICIAN_CALLS: int = 1
## RARE, as asked. He only turns up on the good coaches, and not often on those —
## roughly one offer in fifteen carries him.
const TACTICIAN_GRADE: int = 4
const TACTICIAN_ODDS: int = 6


static func trait_of(c: Dictionary) -> int:
	return int(c.get("trait", Trait.NONE))


## DOES ANY CAPTAIN BRING THIS TRAIT TO THIS ROLE? One question, one place. Every
## trait below is read through here, so a trait can never apply to a role its
## man does not cover — which is the rule that makes the one-star honest.
func trait_covers(t: int, role: int) -> bool:
	for c in captains:
		if trait_of(c) == t and specialties_of(c).has(role):
			return true
	return false


## And the same question with no role in mind, for the traits that are about the
## club rather than about a man — the following, the size of the market.
## HOW MANY EXTRA CALLS THE STAFF IS WORTH. Zero or one today; a sum rather than
## a bool so a second source of calls — if one is ever added — does not have to
## re-decide what "has a Tactician" means.
func extra_calls() -> int:
	return TRAIT_TACTICIAN_CALLS if has_trait(Trait.TACTICIAN) else 0


func has_trait(t: int) -> bool:
	for c in captains:
		if trait_of(c) == t and not specialties_of(c).is_empty():
			return true
	return false


## WHO IS ON THE MARKET. Deterministic from the club and the season so the offer
## on screen does not reshuffle while you look at it — a hire screen whose
## candidates change as you read them is unusable.
##
## THIS LIVED IN TWO SCREENS. season_scene.gd and staff_scene.gd each carried
## their own copy, and the day the grade range changed only one of them changed:
## the Office tab was still selling three-star captains while the Staff room sold
## five. A rule applied at two call sites is a rule with a hole in it.
const OFFER_NAMES: Array[String] = ["Vaughn", "Sable", "Rooke", "Hallam",
	"Crewe", "Ivers", "Mallory", "Orde"]


static func offer(seed_value: int, season_no: int, slot: int,
		refreshes: int = 0) -> Dictionary:
	var h := absi(hash("cap:%d:%d:%d:%d" % [seed_value, season_no, slot, refreshes]))
	var roles := [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]
	var a: int = roles[h % 3]
	var b: int = roles[(a + 1 + int(h / 3) % 2) % 3]
	## THE FULL FIVE STARS ARE ON THE MARKET, not three of them. The grade used to
	## top out at 3, which — once the grade decided how many roles a man teaches
	## — made a two-specialty captain a thing the code could build and the game
	## could never sell.
	var grade := 1 + int(h / 11) % 5
	## AND A TRAIT, on roughly half of them. Not all, because a man with no trait
	## has to be a real thing on the list or the trait is not a reason to pick
	## anybody — it is just a line every card happens to carry.
	var t: int = Trait.NONE
	if int(h / 7) % 2 == 0:
		t = 1 + int(h / 13) % (Trait.SCOUT)
	## AND THE RARE ONE, rolled separately rather than added to the common pool.
	## Dropping TACTICIAN into `% Trait.SCOUT` would have made it as common as
	## Physio, and "rare" was the word in the brief.
	if grade >= TACTICIAN_GRADE and int(h / 17) % TACTICIAN_ODDS == 0:
		t = Trait.TACTICIAN
	return captain(OFFER_NAMES[h % OFFER_NAMES.size()], a, b, grade, t)


static func specialties_of(c: Dictionary) -> Array:
	return c.get("specialties", [])


## WHAT A CAPTAIN TEACHES, IN WORDS, for every screen that prints it. A one-star
## teaches nothing, and the three screens drawing his card each printed the
## heading "Teaches" over an empty space — which reads as a bug rather than as
## the man's actual job. He has one: he is good in a changing room.
static func teaches_list(c: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for r in specialties_of(c):
		out.append(String(Tuning.ROLE_NAME[int(r)]))
	if out.is_empty():
		out.append("Nothing · lifts the room")
	return out


static func teaches_line(c: Dictionary) -> String:
	return " + ".join(teaches_list(c))


func hire(c: Dictionary) -> String:
	if captains.size() >= MAX_CAPTAINS:
		return "You already have two captains. Release one first."
	var price := cost_of(c)
	if credits < price:
		return "%s costs %d CC and you have %d." % [String(c.get("name", "A captain")), price, credits]
	spend(price, LINE_SQUAD)
	captains.append(c)
	return ""


## WHAT HE DOES ON THE DAY HE WALKS IN. Three of the nine fire once, at the
## hiring, and they are the reason a hire is felt immediately rather than in
## March. Separated from `hire()` because `hire` knows about money and this knows
## about the squad — and because the office does not hold the roster, the season
## does. See `Season.hire_captain`, which is the only caller of both.
func arrival_effect(c: Dictionary, club) -> Dictionary:
	var t := trait_of(c)
	var touched: Array[String] = []
	if not ARRIVAL_TRAITS.has(t) or specialties_of(c).is_empty():
		return {"trait": t, "men": touched}
	for f in club.roster:
		if not specialties_of(c).has(Tuning.role_of(int(f.pos))):
			continue
		match t:
			Trait.EXPERIENCE:
				f.xp += TRAIT_XP_BANKED
			Trait.TALENT_SPOTTER:
				f.potential = clampi(f.potential + TRAIT_CEILING, 1, 99)
			Trait.MOTIVATOR:
				f.morale_shift(TRAIT_MORALE)
		touched.append(f.display_name)
	return {"trait": t, "men": touched}


## LETTING A CAPTAIN GO, and what the place makes of it.
const FANS_LOST_FAVORITE: float = 0.80


## THE SUMMER, FOR THE STAFF. Everybody loses a year; anybody on zero has gone.
## Returns the names that left, so the summer can say so — a captain who
## disappears silently is a line that starts fighting Green in March for reasons
## the player never sees.
func age_captains() -> Array[String]:
	var gone: Array[String] = []
	var keep: Array[Dictionary] = []
	for c in captains:
		var years := int(c.get("years", CAPTAIN_YEARS)) - 1
		c["years"] = years
		if years <= 0:
			gone.append(String(c.get("name", "A captain")))
		else:
			keep.append(c)
	captains.clear()
	for c in keep:
		captains.append(c)
	return gone


func extend_captain(i: int) -> String:
	if i < 0 or i >= captains.size():
		return "There is no captain in that job."
	if credits < CAPTAIN_EXTEND:
		return "Another year costs %d CC and you have %d." % [CAPTAIN_EXTEND, credits]
	spend(CAPTAIN_EXTEND, LINE_SQUAD)
	captains[i]["years"] = int(captains[i].get("years", 0)) + 1
	return ""


func release(i: int) -> void:
	if i < 0 or i >= captains.size():
		return
	## The crowd's man walks and takes a fifth of the following with him. This is
	## the half of Fan Favorite that makes him a decision rather than a bonus:
	## hiring him is cheap and sacking him is not.
	if trait_of(captains[i]) == Trait.FAN_FAVORITE and not specialties_of(captains[i]).is_empty():
		fans = maxf(0.0, fans * FANS_LOST_FAVORITE)
		_clamp_fans()
	captains.remove_at(i)


## HOW GOOD THE MAN TEACHING THIS ROLE IS — 0 if nobody does, otherwise his
## stars. Pete, 15 Sep 2026: *"The Coaches hold practices, the better the
## coaches, the more you get out of practice."*
##
## `taught()` below has answered this question as a BOOL since the day captains
## were written, and every caller inherited that: a one-star and a five-star
## taught a role identically, and the grade a player paid for reached nothing at
## all except how many roles the man covered. Retro Bowl's Training Facility is
## *"players gain XP faster"* — a multiplier, not a switch — and the grade is
## ours. The best of them wins rather than the sum: two captains on one role is
## already worth something (see `club_specialty`), and adding their stars would
## make doubling up the dominant move on every hire screen.
func coaching(role: int) -> int:
	var best := 0
	for c in captains:
		if specialties_of(c).has(role):
			best = maxi(best, int(c.get("grade", 1)))
	return best


## Is anybody teaching this role? That is the only question there is.
func taught(role: int) -> bool:
	for c in captains:
		if specialties_of(c).has(role):
			return true
	return false


## How many captains specialize in it. Only ever used to point out that two of
## them are teaching the same job while another goes without.
func doubled(role: int) -> bool:
	var n := 0
	for c in captains:
		if specialties_of(c).has(role):
			n += 1
	return n > 1


## THE THING THE CAPTAINS DO. A man's AI tier is set by whether his role is
## taught — not by a difficulty setting, not by his own stats.
##
## Two rungs of the six, because a role is taught or it is not. An untaught role
## goes out **Rust** — it does the opening plan and then stands on its zone,
## which is exactly what Pete described — and a taught one goes out **Hardened**.
## The four rungs above are the league's, not the player's: they describe how
## good a CPU club is, and you climb to meet them rather than buying them.
func tier_for(role: int) -> int:
	return Tuning.AiSkill.HARDENED if taught(role) else Tuning.AiSkill.RUST


## The roles going out untaught — the warning, and the only thing on the staff
## screen the player has to act on.
func untaught() -> Array:
	var out: Array = []
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		if not taught(role):
			out.append(role)
	return out


# -------------------------------------------------------- the federation
## WHAT THE CLUB HOLDS, BY RULE. The arithmetic is all in `Federation`; what lives
## here is the state, because this is the object that holds a purse.
##
## `members` USED TO LIVE HERE AND IS GONE. It was the third of the three
## populations — see the note over `fans` — and it was the one with the weakest
## claim, because the only thing it did was pay dues. Pete, 15 Sep 2026: *"I'm not
## liking the dues portion, that should more be a league dues at the start of a
## season."* So the money goes the other way now: the federation BILLS the club,
## the bill is `League.dues_for(tier)`, and there is no membership roll behind it.
##
## What the members used to react to — a winning season, a room worth being in, a
## club that can fill its own bus — now moves `fans`, which is the one population
## left and the one the player already watches.
var compliance := {
	Federation.Rule.KIT: 0,
	Federation.Rule.MARSHALS: 0,
	Federation.Rule.INSURANCE: 0,
}


func rule_level(r: int) -> int:
	return int(compliance.get(r, 0))


func rule_cost(r: int) -> int:
	return Federation.raise_cost(rule_level(r))


func raise_rule(r: int) -> String:
	if rule_level(r) >= Federation.MAX_LEVEL:
		return "%s is already at the top standard." % String(Federation.RULE_NAME[r])
	if _throttled(SLOT_RULE):
		return throttle_word("the paperwork")
	var cost := rule_cost(r)
	if credits < cost:
		return "%s costs %d CC and you have %d." % [
			String(Federation.RULE_NAME[r]), cost, credits]
	spend(cost, LINE_FEDERATION)
	compliance[r] = rule_level(r) + 1
	_mark(SLOT_RULE)
	return ""


func compliant() -> bool:
	return Federation.compliant(compliance, tier)


func shortfalls() -> Array[String]:
	return Federation.shortfalls(compliance, tier)


func federation_upkeep() -> int:
	return Federation.upkeep_of(compliance)


# ------------------------------------------------------------------ the purse
## WHERE THE MONEY CAME FROM, and it is the whole answer to item 25.
##
## Pete, 15 Sep 2026: *"No income weekly ever. You're set to lose and you'll die
## out if you don't win."*
##
## Measured first (`tools/probe_purse.gd`), because the sentence is checkable: a
## club walked from the first event earns **8 -> 92 CC across three seasons**,
## about 21 in the first and 28 by the third. So income exists and the sentence
## is not literally true.
##
## What IS true is that none of it is ever shown. It arrives as +1 and +2 after
## an event and a lump at the season roll, against a purse in the header that
## simply reads a different number than it did a moment ago. **A club that cannot
## see itself earning is a club that is not earning, as far as the player is
## concerned** — and that is a screen problem, not a balance one, so it gets a
## screen fix and the balance stays where it is until Pete says otherwise.
##
## Every credit in passes through `take()` and says what it was for. Nothing here
## changes an amount.
const PURSE_KEEP: int = 6

## Newest first: {"what": String, "cc": int, "when": String}.
var purse_log: Array = []


## MONEY IN, WITH A REASON. Returns the amount so a caller can still read it.
##
## `line` IS THE HEADING IT GOES UNDER and `what` is what actually happened.
## They are different questions: the log wants "Finished 3rd", the books want
## "Prize money", and a screen that groups by the exact wording of an event ends
## up with a ledger of one-line categories nobody can read.
func take(cc: int, what: String, when_: String = "", line: String = "") -> int:
	if cc == 0:
		return 0
	credits += cc
	purse_log.push_front({"what": what, "cc": cc, "when": when_})
	while purse_log.size() > PURSE_KEEP:
		purse_log.pop_back()
	_book(books_in, line if line != "" else what, cc)
	return cc


## ------------------------------------------------------------------ the books
## WHERE THE MONEY WENT, BY HEADING, FOR A YEAR AT A TIME.
##
## Pete, 15 Sep 2026: *"Make Honors a finances page to show balance breakdowns"*
## — and, before that, *"The income is either too low or costs are too high. 84
## in one year will not maintain enough, you'll decline."*
##
## THE SECOND SENTENCE IS WHY THIS IS A MODEL AND NOT A SCREEN. `probe_economy`
## reports a Backyard club netting sixty-odd credits a season against a six-credit
## Club gym and concludes the ladder is a tenth of a season away. Pete played the
## same build and could not keep up. Both readings are honest, because the probe
## measures the ARENA and the club's money actually goes on repairs, levels,
## contracts and upkeep — none of which anything in this project could total,
## because money left the club in twenty-three separate places and said nothing
## on the way out.
##
## `take()` has said what every credit IN was for since the purse log went in.
## This is the other half, and the asymmetry is the whole bug: **a ledger with
## one side is a ledger.**
##
## Cleared at the roll-over, with the closing year kept as `books_last` so the
## screen can say "and last year" — a breakdown with nothing to compare it to is
## a list of numbers.
var books_in: Dictionary = {}
var books_out: Dictionary = {}
var books_last: Dictionary = {}

## THE HEADINGS. Seven out and six in, which is few enough to read at a glance
## and specific enough to act on: a player who sees half his year going on Kit
## knows to buy harnesses, and one who sees it going on The squad knows he is
## carrying men he cannot afford.
const LINE_GROUND := "The ground"
const LINE_FACILITIES := "Facilities"
const LINE_KIT := "Kit and harness"
const LINE_SQUAD := "The squad"
const LINE_FEDERATION := "The federation"
const LINE_TRAVEL := "Travel"
const LINE_CLUB := "The club"

const LINE_GATE := "The gate"
const LINE_PRIZE := "Prize money"
## Kept only so an old save's books still have a heading for the line they
## were written with. Nothing produces it any more — the federation bills the
## club now and that lands under `LINE_FEDERATION`.
const LINE_DUES := "Members' dues"
const LINE_CUP := "Tournaments"
const LINE_STORE := "Bought credits"
## THE BAR AND THE FOOD. Its own line and not folded into the gate, because the
## whole reason it exists is that it behaves differently — the gate swings with
## form and the counter does not — and a player who cannot see them apart cannot
## see that.
const LINE_COUNTER := "The counter"

## The order they are shown in, which is the order they matter in rather than
## the order they were written. Anything not on the list is drawn after it, so a
## heading added later shows up rather than disappearing.
const OUT_ORDER: Array[String] = [LINE_SQUAD, LINE_KIT, LINE_GROUND,
	LINE_FACILITIES, LINE_TRAVEL, LINE_FEDERATION, LINE_CLUB]
const IN_ORDER: Array[String] = [LINE_GATE, LINE_COUNTER, LINE_PRIZE,
	LINE_GROUND, LINE_CUP, LINE_STORE]


static func _book(books: Dictionary, line: String, cc: int) -> void:
	books[line] = int(books.get(line, 0)) + cc


## MONEY OUT, WITH A REASON — the mirror of `take()`, and the reason every
## `credits -= x` in this project is now a call.
##
## It does NOT check affordability. Every caller already does, in its own words,
## with its own refusal ("That costs %d CC and you have %d") — and a second check
## here would either duplicate those messages or silently swallow a bug. What
## this does is take the money and write it down.
func spend(cc: int, line: String) -> int:
	if cc == 0:
		return 0
	credits -= cc
	_book(books_out, line, cc)
	return cc


## THE YEAR SO FAR, as [{line, cc}] in the order above, biggest headings first
## within the leftovers. `which` is `books_in` or `books_out`.
static func book_rows(books: Dictionary, order: Array[String]) -> Array:
	var out: Array = []
	for line in order:
		if books.has(line) and int(books[line]) != 0:
			out.append({"line": line, "cc": int(books[line])})
	var rest: Array[String] = []
	for k in books.keys():
		if not order.has(String(k)) and int(books[k]) != 0:
			rest.append(String(k))
	rest.sort_custom(func(a, b): return int(books[a]) > int(books[b]))
	for k in rest:
		out.append({"line": k, "cc": int(books[k])})
	return out


static func book_total(books: Dictionary) -> int:
	var t := 0
	for k in books.keys():
		t += int(books[k])
	return t


## CLOSE THE YEAR. Called from the roll-over, once, after every summer payment
## and every summer bill — so `books_last` is a WHOLE season and the open books
## are a season in progress. Two halves of a year in one column would be the
## most misleading table on the screen.
func close_books() -> void:
	books_last = {"in": books_in.duplicate(), "out": books_out.duplicate()}
	books_in = {}
	books_out = {}


## What the last event or roll paid, in the club's own words. Empty when nothing
## has been earned yet, which is a true thing to say on day one.
func purse_lines() -> Array:
	return purse_log.duplicate()


func purse_since(when_: String) -> int:
	var t := 0
	for row in purse_log:
		if String(row.get("when", "")) == when_:
			t += int(row["cc"])
	return t


## WHAT THE FEDERATION WANTS TO LET YOU ENTER, billed at the start of a season.
##
## The other direction from what `dues()` used to be. It was members × 1 CC and
## it paid the club — 24.4 credits a season across a career, **58% of all income**
## on the books, which made a standing subscription the biggest earner in a game
## about fighting. Now it is a cost, it scales with the division, and a club can
## go into the red paying it.
func dues() -> int:
	return League.dues_for(tier)


# --------------------------------------------------------------- the levers
## FOUR SMALL THINGS OFF THE SHIPPED BUILD, and the first one is the important
## one: morale now has somewhere to SPEND.
##
## `msg_BoostMorale`: *"Do you want to arrange a morale boosting event for $num
## coach credits?"* Per-man morale went in with results, regimes, captains and
## cuts all pushing it around, and not one thing the player could do about it on
## purpose. A system you can only watch is a read-out; this is the lever that
## makes it a system.
##
## It is deliberately weak per credit and throttled to once a week. A morale
## button you can mash is a morale button that deletes the toxic bottom end, and
## that bottom end is the half Pete asked for.
const BOOST_COST: int = 4
const BOOST_MORALE: float = 0.12


func boost_cost() -> int:
	return BOOST_COST


func can_boost() -> bool:
	return credits >= BOOST_COST and not done_this_week(SLOT_BOOST)


## THE OFFICE HOLDS THE MONEY AND THE THROTTLE; the SEASON holds the men. This
## returns whether the money and the week were there, and `Season.boost_morale`
## does the lifting — same division of labour as the captain's arrival traits.
func take_boost() -> String:
	if done_this_week(SLOT_BOOST):
		return throttle_word("the club")
	if credits < BOOST_COST:
		return "A night out costs %d CC and you have %d." % [BOOST_COST, credits]
	spend(BOOST_COST, LINE_CLUB)
	_mark(SLOT_BOOST)
	return ""


## REFRESHING A LIST. `msg_FreeAgentReset` and `msg_StaffReset`: *"Do you wish to
## refresh the free agent list for $num coaching credits?"*
##
## Both lists in this game are deterministic from the season and the slot, which
## is right — a hire screen that reshuffles while you read it is unusable — and
## it also means a bad crop is a bad crop for a whole year with nothing to do
## about it. The refresh is the answer: the list stays fixed until you PAY to
## turn it over, so it is stable and it is not a dead end.
const REFRESH_COST: int = 3

## How many times each list has been turned over. It feeds the hash, so a
## refreshed list is a genuinely different draw rather than a reshuffle of the
## same men, and it is small enough to save without thinking about it.
var staff_refreshes: int = 0
var market_refreshes: int = 0


func refresh_staff() -> String:
	if credits < REFRESH_COST:
		return "Putting the word out costs %d CC and you have %d." % [REFRESH_COST, credits]
	spend(REFRESH_COST, LINE_CLUB)
	staff_refreshes += 1
	return ""


func refresh_market() -> String:
	if credits < REFRESH_COST:
		return "Putting the word out costs %d CC and you have %d." % [REFRESH_COST, credits]
	spend(REFRESH_COST, LINE_CLUB)
	market_refreshes += 1
	return ""


# ------------------------------------------------------------ kit and travel
## THE CAP THIS GAME WAS SUPPOSED TO HAVE.
##
## DIRECTION §4, written before a line of code: *"Salary cap -> kit and
## availability. Nobody is paid. The cap isn't money-per-player, it's how many
## bodies you can put on a plane and how many harnesses you own that pass
## inspection. Bench depth is limited by armor, not payroll. This constraint has
## never been in a sports management game and it is completely true to the
## sport."*
##
## And the game shipped a money cap — the literal Retro Bowl mechanic the
## paragraph exists to replace — because a wage bill was the thing that was easy
## to port. The money cap stays, because by now it is load-bearing and it does
## read as the federation's ceiling on what a club may spend. What was missing is
## the half that is actually about buhurt, and it is two numbers:
##
##   TRAVEL SLOTS   how many men you can put on a plane. You start with a LINE
##                  AND NOTHING BEHIND IT — five — and buy your way to eight.
##   INSPECTION     a harness under `FighterCard.INSPECTION_MIN` does not pass the
##                  marshals, and a man who does not pass does not fight.
##
## The first makes the bench a purchase rather than a given, which is what makes
## the corner's two swaps a thing you EARNED. The second makes the Workshop load
## bearing: armor was a soft multiplier on a man's base and nothing else, so
## repairs were somewhere to put spare credits. Now it is the difference between
## having five men and having four.
const TRAVEL_MIN: int = MeleeClub.LINE_SIZE
const TRAVEL_MAX: int = MeleeClub.ACTIVE_SIZE

## WHERE A CLUB STARTS: a line and one man behind it.
##
## The first version started everybody at the bare five, which is what the
## direction document literally says and was wrong in play for a reason that only
## showed up once it ran. The corner allows two swaps; a club traveling five can
## make none, so the entire corner layer — the screen, the two swaps, the bench
## recovery, all of it — was dead until the first purchase. A mechanic the player
## cannot touch in his first season is not a progression, it is a locked door.
##
## Six is the smallest number that leaves the corner working. The seventh and
## eighth places are the purchase, and they are what turn one swap into the two
## the corner was designed around.
const TRAVEL_START: int = MeleeClub.LINE_SIZE + 1
## Rising, like every other ladder in this office.
const TRAVEL_COST := [6, 10]

var travel_slots: int = TRAVEL_START


func travel_cost() -> int:
	var step := travel_slots - TRAVEL_START
	if step < 0 or step >= TRAVEL_COST.size():
		return 0
	return int(TRAVEL_COST[step])


func buy_travel_slot() -> String:
	if travel_slots >= TRAVEL_MAX:
		return "You can already take a full eight."
	if _throttled(SLOT_TRAVEL):
		return throttle_word("the travel budget")
	var cost := travel_cost()
	if credits < cost:
		return "Another place costs %d CC and you have %d." % [cost, credits]
	spend(cost, LINE_TRAVEL)
	travel_slots += 1
	_mark(SLOT_TRAVEL)
	return ""


# -------------------------------------------------------------------- morale
## 0-1. Moves with results and with the ground you train on. It is a read-out
## rather than a lever, which is what keeps it honest — you cannot buy it.
var morale: float = 0.7


## MORALE IS LOGISTIC, not an accumulator, and it had to become one the moment
## anything started reading it.
##
## It used to add a flat swing per result. tools/probe_dilemma.gd played thirty
## seasons under three different policies and **every one of them ended pinned at
## 0.05** — the floor — because a club losing more than it wins subtracts a little
## every week and there was nothing pulling the other way. That was harmless while
## morale was a read-out nobody read. It stopped being harmless the same afternoon
## morale started deciding who waits for you and who retires early: a struggling
## club would have been permanently at maximum penalty, bleeding fighters it could
## never keep, in a spiral with no bottom and no way out.
##
## So the swing is scaled by the ROOM LEFT IN THE DIRECTION IT IS GOING — the same
## shape `FANS_WIN_GAP` already uses a few lines up. It cannot reach either end,
## and it settles at an equilibrium set by how often the club wins:
##
##   wins 4 in 5    settles near 0.82   Flying
##   wins 3 in 5    0.63                Good
##   wins 2 in 5    0.43                Fine
##   wins 1 in 5    0.22                Poor
##
## which is the spread the five words were written for and which the flat version
## never actually produced.
const MORALE_WIN: float = 0.08
const MORALE_LOSS: float = -0.07
const MORALE_GROUND: float = 0.006


func morale_after(won: bool, drew: bool) -> void:
	var swing := MORALE_WIN if won else (0.0 if drew else MORALE_LOSS)
	## A better ground takes the edge off a bad weekend, which is exactly what
	## Retro Bowl's stadium does and is true of a real club: people forgive more
	## when the place is warm. It reads the ARENA now that the Home ground
	## facility is gone — same idea, and now it is the same number the crowd and
	## the gate are reading too.
	## AND A GROUND THAT HAS GONE TO SEED STOPS DOING IT. Scaled by condition, so
	## this is the second thing neglect costs and the first one a player at a
	## small ground can feel — the retainer at a club gym is three credits and the
	## slide on it is one, which is not a signal. Note the shape: at condition 1.0
	## it is exactly the number it has always been and at level 0 it is zero
	## either way, so nothing that was true yesterday is worse today. **A feature
	## that nerfs the baseline to make its own upgrades look good is a feature
	## charging you to undo it.**
	swing += ground_morale()
	morale_shift(swing)


## WHAT THE GROUND IS WORTH TO THE ROOM, in one place. `Season` adds the same
## number to every man's own swing a few lines after this runs, and it did so by
## writing the formula out a second time — **a number that has to agree with
## another number is a number that will stop agreeing**, and this one had
## already started: the club figure was about to learn about condition and the
## per-man one was not.
func ground_morale() -> float:
	return float(arena.level) * MORALE_GROUND * clampf(arena.condition, 0.0, 1.0)


## Every move on morale goes through here, dilemmas included, so nothing can add
## a flat amount and walk it into the wall the logistic exists to prevent.
##
## THE CLUB FIGURE IS NOW AN AVERAGE, not a thing in its own right. It is still
## shifted directly by anything that has no particular man in mind — a dilemma
## about the brewery, a bad season — and `Season` pushes the same move through
## every fighter and then re-derives this from them, so the two never disagree
## about how the room feels.
func morale_shift(d: float) -> void:
	var room: float = (1.0 - morale) if d > 0.0 else morale
	morale = clampf(morale + d * room, 0.02, 0.99)


## Re-read the club's mood off the men who are actually at the event. A reserve
## who never travels does not set the tone in the changing room.
func sync_morale(club) -> void:
	var eight: Array = club.active_eight()
	if eight.is_empty():
		return
	var total := 0.0
	for f in eight:
		total += f.morale
	morale = clampf(total / float(eight.size()), 0.02, 0.99)


## HOW MANY ROLES A CAPTAIN TEACHES, and it is his grade that says.
##
## Pete, 11 Sep 2026: *"Low Star staff can have no specialties or just one
## specialty. So a One Star will have no specialty but just generally help. Mid
## star staff will have one specialty, and High star can have two specialties."*
##
## Every captain used to get exactly two regardless of grade, which made the
## star rating decoration — a one-star and a five-star taught the same number of
## jobs and the only difference was the number of stars drawn next to the name.
static func specialty_count(grade: int) -> int:
	if grade <= 1:
		return 0
	if grade <= 3:
		return 1
	return 2


## A captain who teaches nothing is not useless. He is the man who is good in a
## changing room: everybody lifts a little, nobody is shown anything new.
const PRESENCE_MORALE := 0.012


func presence() -> float:
	var lift := 0.0
	for c in captains:
		if specialties_of(c).is_empty():
			lift += PRESENCE_MORALE * float(int(c.get("grade", 1)))
	return lift


## THE CLUB'S SPECIALTY — the role two captains BOTH teach.
##
## Pete: *"each captain can cover up to two positions... which will always make
## one position have an overlap, making it so the teams will have a specialty."*
## Two men teaching one job is not the waste the old screen called it; it is
## what a club becomes known for.
func club_specialty() -> int:
	var seen := {}
	for c in captains:
		for r in specialties_of(c):
			var k := int(r)
			if seen.has(k):
				return k
			seen[k] = true
	return -1


## What the doubled role is worth. Men who stand in it develop faster — the club
## has two people who know that job and one of them is always watching.
const SPECIALTY_XP := 1.25


func specialty_xp(role: int) -> float:
	var mult := SPECIALTY_XP if club_specialty() == role else 1.0
	## POSITIVE stacks on top of the specialty rather than replacing it. Two
	## different things are true — two men teach this job, and one of them is good
	## to be around — and a max() would quietly throw the smaller one away.
	if trait_covers(Trait.POSITIVE, role):
		mult *= TRAIT_POSITIVE_XP
	return mult


## THE WORDS ARE ANCHORED ON WHERE MORALE ACTUALLY SETTLES, which is a thing
## that could only be known once it settled anywhere. Under the old flat swing it
## drifted to a wall and four of these five names were unreachable; under the
## logistic the equilibria measured out at 0.85, 0.60, 0.47 and 0.26 for clubs
## winning four, three, two and one in five — and against thresholds written for
## the old behavior, a club winning four fixtures in five read "Good" and
## "Flying" was still unreachable.
##
## So the boundaries are set just under each measured equilibrium. A club that
## wins most weeks is Flying, a good one is Good, a mid-table one is Fine, and
## the bottom of the division is Restless — which is what the five words were for.
func morale_word() -> String:
	if morale >= 0.80:
		return "Flying"
	if morale >= 0.56:
		return "Good"
	if morale >= 0.38:
		return "Fine"
	if morale >= 0.20:
		return "Restless"
	return "Mutinous"


# -------------------------------------------------------------------- saving
func to_dict() -> Dictionary:
	return {
		"credits": credits, "cap_level": cap_level, "morale": morale, "tier": tier,
		"travel": travel_slots,
		"compliance": compliance.duplicate(),
		"staff_refreshes": staff_refreshes, "market_refreshes": market_refreshes,
		"facilities": facilities.duplicate(),
		"captains": captains.duplicate(true),
		"arena": arena.level, "arena_condition": arena.condition,
		"fans": fans,
		## THE BOOKS TRAVEL WITH THE SAVE. A finances page that resets every time
		## the player closes the app is a finances page that can only ever show
		## the current week, which is not a year and is not what it is for.
		"books_in": books_in.duplicate(), "books_out": books_out.duplicate(),
		"books_last": books_last.duplicate(true),
	}


static func from_dict(d: Dictionary) -> ClubOffice:
	var o := ClubOffice.new()
	o.credits = int(d.get("credits", 0))
	o.cap_level = int(d.get("cap_level", 0))
	o.tier = int(d.get("tier", 0))
	o.morale = float(d.get("morale", 0.7))
	o.travel_slots = clampi(int(d["travel"]), TRAVEL_MIN, TRAVEL_MAX)
	## HARD KEYS, not defaults. These decode into something FALSE rather than into
	## a gap — see the VERSION note in save_game.gd — and the version gate above is
	## what stops an old file ever reaching here.
	for k in d.get("compliance", {}):
		if o.compliance.has(int(k)):
			o.compliance[int(k)] = clampi(int(d["compliance"][k]), 0, Federation.MAX_LEVEL)
	o.staff_refreshes = int(d.get("staff_refreshes", 0))
	o.market_refreshes = int(d.get("market_refreshes", 0))
	o.arena.level = clampi(int(d.get("arena", 0)), 0, Arena.MAX_LEVEL)
	## DEFAULTED TO SPOTLESS. A save written before a ground could get dirty was
	## a save whose ground was, by definition, in perfect order.
	o.arena.condition = clampf(float(d.get("arena_condition", 1.0)), 0.0, 1.0)
	## SOFT KEYS, deliberately: every save written before the books existed has
	## none of these, and an empty ledger on an old career is the truth — nothing
	## was recorded, so nothing is claimed. A hard key here would refuse to load
	## every save in existence to gain a column of zeroes.
	o.books_in = (d.get("books_in", {}) as Dictionary).duplicate()
	o.books_out = (d.get("books_out", {}) as Dictionary).duplicate()
	o.books_last = (d.get("books_last", {}) as Dictionary).duplicate(true)
	o.fans = maxf(0.0, float(d.get("fans", 12.0)))
	for k in d.get("facilities", {}):
		## Only the two that still exist. A stored HOME_GROUND level from an
		## older shape is dropped rather than added back as a key nothing reads.
		if o.facilities.has(int(k)):
			o.facilities[int(k)] = int(d["facilities"][k])
	o.captains.clear()
	for c in d.get("captains", []):
		o.captains.append((c as Dictionary).duplicate(true))
	return o
