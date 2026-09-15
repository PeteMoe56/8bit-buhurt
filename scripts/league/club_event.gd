class_name ClubEvent
extends RefCounted
## EVENTS YOU PUT ON YOURSELF, and the gamble in them.
##
## Pete, 10 Sep 2026: *"Schedule them. All but Nationals is separate from the
## league. Demos are unplayed and pay little, you can host your own tournament
## but it takes 2 weeks to set up and you can set the budget. # of fans,
## popularity and reputation and podium finish dictate the reward money. You'll
## either lose a little money, break even, or win money."*
##
## Two kinds and they are different DECISIONS, not two sizes of the same one.
##
##   DEMO         instant, unplayed, pays a little and always pays. A club with
##                no reputation and an empty week does this. It cannot lose.
##   TOURNAMENT   two matchdays of setup, a budget you choose, and a result you
##                do not control. It can absolutely lose.
##
## THE BUDGET IS THE WHOLE MECHANIC. It is not a fee — it is what you spend on
## bringing clubs in and getting people through the gate, and it comes back as
## attendance. Spend big into an empty reputation and you eat it; spend big when
## people already want to watch you and the house fills. That is the gamble, and
## it is the only place in this game where a player can lose credits by choosing
## to.
##
## Everything is in CREDITS. Pete settled that: one currency, and the dollars on
## the salary-cap screen stay what they are — a wage bill, not a bank balance.

enum Kind { DEMO, TOURNAMENT }

## THE BID IS A START-OF-YEAR DECISION. Pete, 10 Sep 2026: *"Let's make player
## made tournament a 'start of year' process. Between seasons, a part of it is
## Tournament Bid where you can choose a certain week in the season to hold your
## own tournament. Then it becomes a static event yearly based on available
## weeks, we can give like 3 options per year."*
##
## This replaces a mid-season booking with two matchdays of lead time, and it is
## a better shape for the same reason a real federation works this way: a club
## bids for a date on next year's calendar, and then spends the year living with
## the date it got.
##
## The three weeks are not interchangeable. A slot late in the season draws
## better because the table matters by then, and it costs more to secure for
## exactly that reason — so the bid is a bet on the season you are ABOUT to have,
## taken before you have had it.
##
## `at` is a fraction of the season, not a matchday, because a Backyard season is
## five events and a National one is fifteen. `prestige` multiplies the draw.
## ALL THREE DATES COST THE SAME. Pete, 10 Sep 2026: *"All dates cost the same,
## the cost just grows with the league they're in. It gives players the obvious
## choice to set it far off and during the season, upgrade it as much as
## possible, win as much as possible for more fans, and get notoriety."*
##
## The first version priced them differently and gave the late one a bigger
## draw, which turned the choice into a sum. It is a better decision without
## that: the value of a later date is entirely EMERGENT — it is however much club
## you can build between now and then. A date in the run-in beats one in the
## opening weeks only if you spend the year earning it, and is worse if you do
## not.
##
## `at` is a fraction of the season, not a matchday, because a Backyard season is
## five events and a National one is fifteen.
const SLOTS := [
	{
		"name": "Opening weeks", "at": 0.20,
		"blurb": "Soon. Whatever you have now is what you will be putting on.",
	},
	{
		"name": "Midseason", "at": 0.50,
		"blurb": "Half a season to build something worth coming to.",
	},
	{
		"name": "Run-in", "at": 0.85,
		"blurb": "A whole year of upgrades and results before anybody walks in.",
	},
]

## WHAT A DATE COSTS, by the division you are in. The federation charges what a
## date on ITS calendar is worth, not what you plan to do with it.
const BID_BY_TIER := [4, 9, 18, 34]


static func bid_cost(tier: int) -> int:
	return BID_BY_TIER[clampi(tier, 0, BID_BY_TIER.size() - 1)]


## The three dates on offer, resolved against the length of the season the player
## is actually in.
static func offers(events_in_season: int, tier: int) -> Array:
	var out: Array = []
	var cost := bid_cost(tier)
	for i in SLOTS.size():
		var sl: Dictionary = SLOTS[i]
		## Never the very first matchday and never past the last — a tournament
		## on the opening day has nothing to trade on, and one after the season
		## has finished never happens at all.
		var at := clampi(int(round(float(events_in_season) * float(sl["at"]))),
			1, maxi(1, events_in_season - 1))
		out.append({
			"slot": i, "name": String(sl["name"]), "event": at,
			"bid": cost, "blurb": String(sl["blurb"]),
		})
	return out


## What a demo pays, by arena level. Flat, small, and never negative — this is
## the floor of the economy, the thing a broke club does.
const DEMO_PAY := [1, 1, 2, 3, 5, 8]
## And what putting one on costs you: nothing. A demo is your own men in your own
## hall.
const DEMO_COST: int = 0

## `draw` is how much of your following the promotion actually gets through the
## door; `take` is what each of them is worth once inside. Both, because either
## alone has been a trap before: a budget that only pulls people in stops paying
## the moment the ground is full, and one that only charges more does nothing for
## a club nobody turns out for.
const BUDGETS := [
	{"name": "Shoestring", "cost": 3, "draw": 0.72, "take": 0.85,
		"blurb": "Local clubs, hand-made posters, somebody's PA. Hard to lose much."},
	{"name": "Proper", "cost": 8, "draw": 1.00, "take": 1.00,
		"blurb": "Travel money for four visiting clubs and a real advertisement."},
	{"name": "All in", "cost": 18, "draw": 1.30, "take": 1.30,
		"blurb": "Name clubs, a stream and a week of promotion. Fill the house or wear it."},
]

## THE GATE IS COMPRESSIVE, and it has to be. Capacity runs 40 to 80,000 — two
## thousand to one — against an economy whose numbers are one to sixty credits. A
## straight per-head rate cannot serve both ends: at the rate that makes a
## national arena sane, every small ground rounds to a gate of ZERO, which is not
## "a small crowd pays a little", it is a feature that does not exist for most of
## the game.
##
## A power well under one closes that: two thousand to one in seats becomes about
## sixty to one in money, which a credit economy can express.
const GATE_K: float = 0.16
const GATE_POW: float = 0.58

## Finishing on the podium at your own event, in credits. Winning your own
## tournament is worth real money and it is also the only part of the payout the
## player can affect with his thumb.
const PODIUM := [6, 3, 1]

## Clubs in a hosted tournament. Eight, so the existing Cup machinery draws it
## without a special case and it is three rounds of fighting.
const FIELD: int = 8

var kind: int = Kind.DEMO
var budget: int = 0            ## index into BUDGETS, tournaments only
var slot: int = -1             ## which of the year's three dates was taken
var bid: int = 0               ## what securing the date cost
var due: int = -1              ## the world event number it lands on
var arena_level: int = 0       ## snapshot: the ground it was booked for
var cup: Cup = null            ## the draw, once it is running
var settled: bool = false
var report: Dictionary = {}    ## what happened, for the screen


# ------------------------------------------------------------------ booking
static func demo(world_event: int, arena: Arena) -> ClubEvent:
	var e := ClubEvent.new()
	e.kind = Kind.DEMO
	e.due = world_event
	e.arena_level = arena.level
	return e


## Take one of the year's offered dates. Everything is paid NOW — the bid and the
## budget both — and the show is a season away, which is what makes it a bet
## rather than a menu.
static func tournament(offer: Dictionary, arena: Arena, budget_i: int) -> ClubEvent:
	var e := ClubEvent.new()
	e.kind = Kind.TOURNAMENT
	e.budget = clampi(budget_i, 0, BUDGETS.size() - 1)
	e.slot = int(offer["slot"])
	e.bid = int(offer["bid"])
	e.due = int(offer["event"])
	e.arena_level = arena.level
	return e


## Everything the event cost you: the date and the promotion. Both were spent at
## the bid, and both have to come off the payout or the screen is lying about
## whether it was worth it.
func cost() -> int:
	return DEMO_COST if kind == Kind.DEMO else int(BUDGETS[budget]["cost"]) + bid


func kind_name() -> String:
	if kind == Kind.DEMO:
		return "Demo"
	if slot >= 0:
		return "%s, %s" % [String(SLOTS[slot]["name"]), String(BUDGETS[budget]["name"]).to_lower()]
	return "%s tournament" % String(BUDGETS[budget]["name"])


func events_away(world_event: int) -> int:
	return maxi(0, due - world_event)


# ------------------------------------------------------------------ the gate
## HOW FULL THE HOUSE GETS. Fans are the pool and the ground is the ceiling — see
## ClubOffice — and the budget buys a bit more of the pool through the door than
## would have come on their own.
##
## It clamps at the ground's capacity, which is the one hard rule: you cannot
## seat more people than you have seats, and the fan ceiling sits 25% above it
## precisely so a big club sells out and turns people away.
## THE NOTORIETY TERM IS GONE. It was `notoriety / 125` — a second population
## dividing the first — and with one crowd number there is nothing to divide by:
## everybody who follows the club would come, and the ground decides how many get
## in. `push` is what the event's budget pulls in over and above them, which is
## the only thing left that can beat the following.
static func attendance(capacity: int, fans: float, push: float = 1.0) -> int:
	return int(min(float(capacity), maxf(0.0, fans) * push))


static func gate(heads: int, take: float = 1.0) -> int:
	return int(floor(GATE_K * pow(maxf(0.0, float(heads)), GATE_POW) * take))


## An honest preview for the bid screen, so the player is choosing between
## numbers rather than between adjectives.
static func preview(capacity: int, fans: float, budget_i: int,
		bid_cost_: int = 0) -> Dictionary:
	var b: Dictionary = BUDGETS[clampi(budget_i, 0, BUDGETS.size() - 1)]
	var heads := attendance(capacity, fans, float(b["draw"]))
	var g := gate(heads, float(b["take"]))
	var spend := int(b["cost"]) + bid_cost_
	return {
		"heads": heads, "gate": g, "cost": spend,
		"net": g - spend,
		"best": g - spend + PODIUM[0],
	}
