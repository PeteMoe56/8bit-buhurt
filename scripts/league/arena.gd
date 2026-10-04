class_name Arena
extends RefCounted
## YOUR GROUND, and the thing every other number on the Clubhouse screen
## eventually points at.
##
## Pete, 10 Sep 2026: *"we want to be able to build and upgrade your own
## Arena/Stadium/Gym. Each upgrade unlocked via league advancement. You'll be
## able to run your own events from a demo that may raise a couple dollars all
## the way up to hosting the National Championship."*
##
## THIS REPLACES THE HOME GROUND FACILITY. That facility already said *"Host an
## event each season. Better ground, better gate"* — it was this feature in
## embryo, five levels of a progress bar with nothing behind it. Two systems for
## one idea is worse than either: the player would have had a Home ground level
## AND an arena level, both feeding the gate, and no way to reason about which
## one to spend on. So the facility is gone and the credits go here.
##
## UNLOCKED BY ADVANCEMENT, NOT BY MONEY. Every other purchase in the game is
## "have you got the credits"; this one is "have you earned the right", and that
## is the point of it. A Backyard club cannot buy a national arena at any price,
## which makes promotion worth something beyond a better fixture list.

## Each level: what it is called, the league tier you must have REACHED to build
## it, what it costs in credits, and how many people it holds.
##
## Capacity is the number that does the work. It sets the ceiling on every gate
## in the game AND the ceiling on how many fans a club can carry, and the whole
## event economy is written against it rather than against the level number — so
## adding a level later is data, not a re-balance.
##
## THE JUMP FROM REGIONAL TO NATIONAL IS MEANT TO BE FELT. Pete, 10 Sep 2026:
## the first four grounds stay small and club-sized, then the Arena is twelve
## thousand and the National Arena is eighty. A sport whose biggest room holds a
## thousand people has no top end to climb to; that step is the top end.
const LEVELS := [
	{
		"name": "Back field", "tier": 0, "cost": 0, "capacity": 40,
		"sells": "Lemonade and a bake sale", "take": 1.00,
		"blurb": "A rope, a rail and somebody's truck. It is a place to fight and that is all it is.",
	},
	{
		"name": "Club gym", "tier": 0, "cost": 6, "capacity": 120,
		"sells": "Coffee urn, brownies, a cookie jar", "take": 1.05,
		"blurb": "Mats, a roof and a coffee pot. Forty people can watch without standing in mud.",
	},
	{
		"name": "Fenced ground", "tier": 1, "cost": 12, "capacity": 400,
		"sells": "A burger truck and a coffee cart", "take": 1.10,
		"blurb": "A proper list, fencing all the way around and a gate you can take money at.",
	},
	{
		"name": "Sports hall", "tier": 1, "cost": 22, "capacity": 1200,
		"sells": "Hot food and a licensed bar", "take": 1.15,
		"blurb": "Seated, lit and warm. Clubs will travel to fight here.",
	},
	{
		"name": "Arena", "tier": 2, "cost": 38, "capacity": 12000,
		"sells": "Concession stands and beer on tap", "take": 1.20,
		"blurb": "Tiered stands, a marshal's box and a screen. This is where a season gets decided.",
	},
	{
		"name": "National Arena", "tier": 3, "cost": 60, "capacity": 80000,
		"sells": "Concourse bars and four franchises", "take": 1.25,
		"blurb": "The federation brings the National Championship here. The whole ambition, built.",
	},
]

## ------------------------------------------------------------ the counter
## WHAT THE GROUND SELLS, AND IT COMES WITH THE GROUND.
##
## Pete, 15 Sep 2026: *"Stadium damper could be food sales. Lemonade, bakery,
## brownies for back yard, progressing to real NFL beer sales and stuff at higher
## tiers (yes, we can add beer)."* Asked whether it should be bought separately
## or arrive with the level: **comes with the ground.**
##
## THAT IS THE RIGHT ANSWER AND IT IS WHY THIS IS TWO FIELDS RATHER THAN A
## SYSTEM. A second ladder beside the arena would be a second set of prices, a
## second upkeep bill, a second screen and a second thing to explain — for a
## decision that is always "yes, buy the food". The ground already IS the
## decision; this is what the ground is for.
##
## WHAT IT IS ACTUALLY DOING IS DAMPING THE SWING, which is Retro Bowl's stadium
## in our nouns. Theirs *"determines the amount of fan support you receive after
## each win, and lose after each loss"* — you spend the currency the meter
## produces to make the meter less volatile. Ours pays **per head, whatever the
## result**: a club that loses in front of a full house still sold them all a
## pint. The gate reads the band and swings with form; the counter reads the
## turnstile and does not.
##
## AND IT GROWS LIKE THE LOG OF THE CROWD, NOT LIKE THE CROWD.
##
## The first cut was credits-per-head, flat: three hundredths at a back field and
## a tenth at a National Arena. Eighty thousand people at a tenth of a credit is
## **8,400 CC a home meet** against a division that earns ninety-seven a season —
## the exact bug the ground retainer shipped with and this file already carries a
## page about. **A line that grows as fast as the crowd is the crowd, paid
## twice.**
##
## So `counter_take` is `K x heads^POW`, the same shape as the retainer, times a
## small multiplier for what the level is allowed to SELL. Both halves earn their
## place: more people come to a bigger ground, and a bar with a licence takes
## more off each of them than a biscuit tin does.
##
## Packed, that is 1 / 1 / 3 / 4 / 10 / 20 CC a home meet up the ladder —
## concessions are nothing at a rope and a rail and they are most of a matchday
## at a National Arena, exactly as they are in the sport.
## TUNED TWICE, BOTH TIMES OFF `tools/probe_run.gd` AND `probe_afford.gd`.
##
## At 0.42 a whole career's bar takings came to **2.0 credits a season** — a line
## on the finances page that was not worth the line. Raised, the exponent then
## had to come DOWN: at 0.28 a packed National Arena took 22 a meet, and across
## five home dates that was 110 credits a season, the single biggest line in the
## game and a bigger one than the gate it is supposed to steady.
##
## Packed, the ladder now runs **2 / 2 / 3 / 4 / 7 / 11** a home meet — a five-
## fold spread top to bottom rather than elevenfold, which is the right shape for
## a second income: the counter is meant to be the half that does not swing, not
## the half that decides the career.
const COUNTER_POW: float = 0.20
const COUNTER_K: float = 1.00
const MAX_LEVEL: int = 5


## WHAT THE COUNTER TOOK, given how many came through the door.
##
## HOME ONLY, and the caller enforces it: it is your bar or it is not. A club on
## the road takes a share of the gate — see `Venue.gate_share` — and none of the
## catering, which is the true and the simple rule.
static func counter_take(level: int, heads: int) -> int:
	if heads <= 0:
		return 0
	var lv: Dictionary = LEVELS[clampi(level, 0, MAX_LEVEL)]
	return int(floor(COUNTER_K * pow(float(heads), COUNTER_POW)
		* float(lv["take"])))


static func sells(level: int) -> String:
	return UiKit.t(String(LEVELS[clampi(level, 0, MAX_LEVEL)]["sells"]))

var level: int = 0

## ---------------------------------------------------------------- the state
## HOW WELL KEPT IT IS, 0 to 1, and it is a SECOND AXIS rather than a second
## level.
##
## Pete, 15 Sep 2026: *"can we use an overlay to make the best arena level look
## shitty? Like an overlay that adds trash outside the fighting area, cracks in
## the wood, and make it really crappy that you'll have to upgrade to clean and
## it raises your income but costs to maintain as it degrades?"*
##
## Yes, and it is the same shape the harness already has — which is the reason to
## do it this way rather than by adding more levels. A fighter has a GRADE he owns
## and a CONDITION it is in; a ground has a LEVEL the league lets him build and a
## CONDITION he keeps it in. One vocabulary, two objects, and a player who has
## learned the armorer's screen already understands this one.
##
## Level is earned by promotion and cannot be bought. Condition is bought and
## cannot be earned. Neither substitutes for the other: a spotless back field is
## still a back field, and a National Arena full of rubbish takes a back field's
## gate.
##
## AND IT IS WHY THE ARENA IS WORTH VISITING MORE THAN FIVE TIMES IN A CAREER.
## An upgrade path with six rungs is six decisions across twenty seasons; a
## ground that needs keeping is a decision every season, which is what makes it
## a place on the screen rather than a purchase.
var condition: float = 1.0

## ------------------------------------------------------------- what it wears
## WHAT A WHOLE SEASON TAKES OUT OF IT — a SEASON figure, divided by the fixture
## list, and not a per-week one.
##
## The per-week version was written first and it was wrong in a way that only
## shows up two leagues later. A Backyard season is five events and a National
## one is fifteen (`League.events_in_season` is `clubs - 1`), so a flat 6% a home
## meet wears a national ground THREE TIMES as fast as a backyard one: the ground
## would need doing once every two years at the bottom and twice a season at the
## top, and "how often is this a decision" would be a different question in every
## league for no reason anybody could name.
##
## Written as a season fraction, the rhythm is the same wherever you are —
## roughly a third of the way down a year, so a ground left alone goes Spotless →
## Well kept → Worn across two seasons and starts costing you. What changes with
## the league is what putting it right COSTS, which is `upkeep_cost()`, and that
## is the axis the league is supposed to move.
const WEAR_SEASON: float = 0.34

## HOW MUCH HARDER A HOME MEET IS THAN A QUIET WEEK. Four times, so a club with a
## home-heavy draw really does pay more for its ground than one that travels —
## the two still average to `WEAR_SEASON` across a typical fixture list, which is
## what `take_a_week` solves for.
const WEAR_HOSTED_SHARE: float = 4.0

## AND HOW MUCH OF A FIXTURE LIST IS TYPICALLY AT HOME — MEASURED, NOT ASSUMED.
##
## The first solve used a half, because a single round-robin is half home and
## half away and that is obviously right. It is not: `tools/probe_venue.gd`
## walked thirty real events and found **home 33%, away 37%, neutral 30%** — the
## cup ties are neutral ground (`venue_kind()` says so in as many words) and they
## are nearly a third of the calendar. Solving against a half meant every ground
## in the game wore 20% slower than the constant above claimed, which is the sort
## of quiet miss that gets discovered when somebody finally wonders why the
## number in the comment and the number on the screen disagree.
##
## **An assumption about another system's data is a measurement you have not
## taken yet.** This one is taken, it is one constant, and the probe that took it
## is in the repo.
const HOSTED_SHARE: float = 0.333

## BELOW THIS IT IS VISIBLY BAD, and the overlay says so. Not a cliff — the gate
## has been sliding the whole way down — just where a player should be able to
## SEE the problem without reading a number.
const SHABBY: float = 0.62

## AND BELOW THIS THE FEDERATION HAS WORDS. The retainer floor, so a neglected
## ground is a bad ground rather than a closed one; a club that cannot host at
## all has no way back, and that is a dead end rather than a difficulty.
const GATE_FLOOR: float = 0.45

## A BACK FIELD CANNOT GET SHABBY, and this is the honest version of a problem
## rather than a special case papering over one.
##
## Level 0 is *"a rope, a rail and somebody's truck"*. There is no wood to crack
## and no stand to sweep; the rubbish outside the fighting area is the field. Run
## the axis there anyway and it becomes a 1 CC charge to recover a 1 CC retainer
## — a maintenance system that is a straight loss at the exact point in a career
## where the player has the least room, which is worse than not having one.
##
## So the ground starts wearing when there is something there to wear. **A system
## that cannot pay for itself at a given level should not run at that level**,
## and saying so in one constant is better than tuning the numbers until the loss
## is small enough to miss.
const WEARS_FROM_LEVEL: int = 1


## --------------------------------------------------------------- what it pays
## THE RETAINER LIVES HERE NOW, with the condition that scales it.
##
## It was two functions on `ClubOffice` reading `arena.capacity()` and
## `arena.gate_scale()` — which is to say it was a fact about the ground, kept
## somewhere else, which this project has already been bitten by over the club's
## name, the canvas size and the engine version. `ClubOffice.gate_income()` still
## exists and is still what everything calls; it forwards.
##
## The exponent is the whole shape and it was expensively arrived at: see the
## long note over `ClubOffice.gate_income()` for the 284-CC-a-summer version and
## the paid-nothing version that followed it. At 0.30 it grows like the LOG of
## the crowd — 2 CC at a back field, 6 at a sports hall, 11 at an arena, 22 at a
## full National Arena.
const RETAINER_POW: float = 0.30
const RETAINER_K: float = 0.72


## WHAT A WELL-KEPT GROUND OF THIS SIZE PAYS ACROSS A SEASON.
func retainer_full() -> int:
	return int(floor(pow(maxf(1.0, float(capacity())), RETAINER_POW) * RETAINER_K))


## AND WHAT THIS ONE PAYS, in the state it is in.
func retainer() -> int:
	return int(floor(float(retainer_full()) * gate_scale()))


## HOW MUCH A GROUND MULTIPLIES WHAT A FIGHT IN IT IS WORTH.
##
## Pete, 15 Sep 2026: *"Money from matches is manipulated from condition of
## arena, so you may actually look forward to an opponent with a great stadium or
## roll your eyes from an opponent with a shitty arena."*
##
## THE COMMENT OVER `ClubOffice.gate_income()` HAS CLAIMED THIS SINCE SEPTEMBER —
## *"The events are where the arena earns"* — and the code did not do it. A fight
## paid `CROWD_PAY[band]`, a flat 1 to 6 off your own notoriety, and read nothing
## about the room it was fought in. The arena's entire contribution to the economy
## was a 2-to-21 CC annual retainer, which is why `probe_afford` found a National
## Arena's whole existence worth less than the membership subs.
##
## A STATIC FUNCTION OF THE LEVEL, because the caller needs it for grounds it
## does not own: an away day multiplies by the HOST's ground, and the host is a
## row in `LeagueWorld.clubs` with no `Arena` object behind it.
##
## 1.0 to 2.2 across the six. Deliberately not steeper: the band is already worth
## six to one top to bottom, and a second multiplier of the same size would make
## the National Division's gate thirty times the Backyard Circuit's, which is not
## a climb, it is two different games.
## 0.35 (was 0.24), Pete 29 Sep 2026 (#13): the ground "should be adding a
## noticeable amount of income". The gate is 55-64% of a club's income in every
## division, so this is the lever that is felt: a National Arena doubles and
## three-quarters a home gate instead of doubling and a fifth.
const GATE_PER_LEVEL: float = 0.35


static func gate_factor(level: int) -> float:
	return 1.0 + float(clampi(level, 0, MAX_LEVEL)) * GATE_PER_LEVEL


## THE SAME SLIDE FOR A GROUND WE DO NOT OWN. `gate_scale()` reads this object's
## own `condition`; a fixture list asking about somebody else's has a float and
## no arena, so the arithmetic lives here once and both roads take it.
static func condition_scale(condition: float) -> float:
	return lerpf(GATE_FLOOR, 1.0, clampf(condition, 0.0, 1.0))


## AND WHAT A GROUND IS WORTH IN ONE NUMBER, for a screen that wants to say
## "their place is worth going to" without printing two multipliers.
static func worth(level: int, condition: float) -> float:
	return gate_factor(level) * condition_scale(condition)


## IN WORDS, for the fixture list. The player is choosing nothing here — he
## cannot pick his opponents — so this is flavour that happens to be true, which
## is the only kind worth printing.
static func worth_word(level: int, condition: float) -> String:
	var w := worth(level, condition)
	## THE BANDS ARE SET SO A SPOTLESS BACK FIELD READS AS HONEST, not as thin.
	## `worth` is exactly 1.0 there — the bottom of both ladders, kept — and the
	## first cut put the "honest" gate at 1.05, so the whole Backyard Circuit was
	## described to the player as barely worth turning up to. A scale whose
	## baseline is an insult is a scale that is measuring from the wrong end.
	if w >= 1.85:
		return UiKit.t("a big day out")
	if w >= 1.40:
		return UiKit.t("a proper ground")
	if w >= 0.95:
		return UiKit.t("an honest ground")
	if w >= 0.70:
		return UiKit.t("a thin gate")
	return UiKit.t("barely worth the trip")


## WHAT THE RETAINER IS MULTIPLIED BY. Full at a well-kept ground, `GATE_FLOOR`
## at a ruin, straight line between.
##
## THE RETAINER AND NOT `crowd_pay()`, DELIBERATELY. The per-event gate is where
## the arena actually earns — 1 to 6 CC a fight off the notoriety band — and
## hanging condition on that as well would make neglect three or four times more
## expensive than it is here. It may well want to; that is an income decision,
## Pete has an open note that says *"the income is either too low or costs are
## too high"*, and **a balance change shipped in the same commit as a feature is
## a balance change nobody can attribute.** One at a time.
func gate_scale() -> float:
	return condition_scale(condition)


func shabby() -> bool:
	return condition < SHABBY


## IN THE CLUB'S OWN WORDS, for a screen. Five bands rather than a percentage,
## because "needs work" is a decision and "0.58" is arithmetic.
func condition_word() -> String:
	if condition >= 0.95:
		return UiKit.t("Spotless")
	if condition >= 0.80:
		return UiKit.t("Well kept")
	if condition >= SHABBY:
		return UiKit.t("Worn")
	if condition >= 0.35:
		return UiKit.t("Shabby")
	return UiKit.t("Falling apart")


## WHAT PUTTING IT RIGHT COSTS — priced against what the ground PAYS, not against
## an invented size ladder.
##
## The first cut was `missing * 6 * (1 + level * 0.8)`, and at a back field that
## billed 3 CC to recover a 2 CC retainer: the club was charged more to keep the
## ground than the ground was worth, at the bottom of the pyramid, where Pete has
## already said the money is too tight. **A cost that is not derived from the
## thing it is a cost OF will eventually exceed it.**
##
## Against the retainer it is the same proportion everywhere: a full season's
## grime costs about `WEAR_SEASON * UPKEEP_SHARE` — call it two fifths — of what
## the ground pays that year, against a gate slide of roughly the same size for
## leaving it. That near-tie is the point. Cleaning is not obviously right and
## neglect is not obviously wrong, and a decision a player can work out once and
## then stop thinking about is not a decision.
##
## A CLUB IS NEVER CHARGED FOR NOTHING. One credit is the floor, and a ground
## already spotless is refused rather than billed — see `ClubOffice.tidy_arena`.
const UPKEEP_SHARE: float = 1.2

func upkeep_cost() -> int:
	var missing := clampf(1.0 - condition, 0.0, 1.0)
	return maxi(1, int(ceil(missing * UPKEEP_SHARE * float(retainer_full()))))


## ONE WEEK OF WEATHER, AND WHETHER ANYBODY FOUGHT IN IT.
##
## `events` is the length of the season this week belongs to, passed in rather
## than looked up, because an `Arena` does not know what league it is in and
## should not learn: it is a ground, and the fixture list is the season's
## business. `Season._apply_regime` is the one place both the fought and the
## simmed path already meet, and it has the number.
func take_a_week(hosted: bool, events: int) -> void:
	if level < WEARS_FROM_LEVEL:
		return
	var n := maxi(1, events)
	## A HOSTED WEEK AND A QUIET ONE THAT AVERAGE TO THE SEASON FIGURE. With a
	## share of 4 the hosted week is 1.6x the mean and the quiet week 0.4x, so a
	## club that hosts exactly half its fixtures lands on `WEAR_SEASON` and one
	## that hosts more pays more. Solving for it here rather than writing 0.060
	## and 0.015 by hand is what keeps the two numbers agreeing when either moves
	## — **a number that has to agree with another number is a number that will
	## stop agreeing.**
	var mean := WEAR_SEASON / float(n)
	condition = clampf(condition - mean * (hosted_weight() if hosted
		else quiet_weight()), 0.0, 1.0)


## THE TWO WEIGHTS, SOLVED RATHER THAN TYPED. They have to satisfy two things at
## once — a hosted week is `WEAR_HOSTED_SHARE` times a quiet one, and the two of
## them mixed in the proportions a real calendar has come to exactly one average
## week — and writing them out as 2.0 and 0.5 by hand would be two numbers that
## have to agree with two constants and with each other. **A number that has to
## agree with another number is a number that will stop agreeing.**
##
##   q * (p * S + (1 - p)) = 1     and     h = S * q
##
## At S = 4 and p = 1/3 that is q = 0.5 and h = 2.0: a home meet costs twice an
## average week and a quiet one half, and a season of eleven events with three
## home ties comes to `WEAR_SEASON` on the nose.
static func quiet_weight() -> float:
	var p := clampf(HOSTED_SHARE, 0.0, 1.0)
	return 1.0 / maxf(0.001, p * WEAR_HOSTED_SHARE + (1.0 - p))


static func hosted_weight() -> float:
	return WEAR_HOSTED_SHARE * quiet_weight()


## A NEW GROUND ARRIVES NEW. Upgrading is not a way to launder a wrecked one —
## it costs the level's full price and the level is gated on promotion — but it
## would be strange to pay sixty credits for a National Arena and be handed one
## with the last place's rubbish still in it.
func built() -> void:
	condition = 1.0
	if level >= 1:
		Achievements.unlock("BREAKING_GROUND")
	if level >= MAX_LEVEL:
		Achievements.unlock("NATIONAL_ARENA")


func here() -> Dictionary:
	return LEVELS[clampi(level, 0, MAX_LEVEL)]


func arena_name() -> String:
	return arena_name_of(level)


## THE NAME OF A GROUND AT A GIVEN LEVEL, for a ground we do not own. The fixture
## list and the post-bout report both want to name the other club's place, and
## neither has an `Arena` object to ask.
static func arena_name_of(level: int) -> String:
	return UiKit.t(String(LEVELS[clampi(level, 0, MAX_LEVEL)]["name"]))


func capacity() -> int:
	return int(here()["capacity"])


func at_top() -> bool:
	return level >= MAX_LEVEL


func next() -> Dictionary:
	return LEVELS[level + 1] if not at_top() else {}


func next_cost() -> int:
	return int(next()["cost"]) if not at_top() else 0


## The league tier the NEXT build needs. The Clubhouse screen wants this even
## when the player cannot afford it yet, because "get promoted" is a different
## instruction from "save up" and he needs to know which one he is looking at.
func next_tier() -> int:
	return int(next()["tier"]) if not at_top() else -1


## THE GROUND COMES BEFORE THE DIVISION (Pete, 29 Sep 2026, #13): *"Arena
## building is mandatory to rising a league because the next league won't want
## to use your shittier arena."* It used to be the other way round — get
## promoted, then you may build — which made the arena a trophy for having
## risen rather than the thing you rise on. Now a club may build one division
## AHEAD of where it plays, and cannot be promoted without the ground for it.
const BUILD_AHEAD: int = 1


## The first level a division will play in: the lowest level whose tier is that
## division's. Tier 0 plays anywhere.
static func level_for_tier(t: int) -> int:
	for i in LEVELS.size():
		if int(LEVELS[i]["tier"]) >= t:
			return i
	return MAX_LEVEL


## Is this ground fit for that division?
func fit_for(t: int) -> bool:
	return level >= level_for_tier(t)


## Everything wrong with building the next one, in the order a player would fix
## it — the league first, because no amount of saving fixes that one.
func can_build(tier: int, credits: int) -> String:
	if at_top():
		return UiKit.t("%s is as far as a club can build.") % arena_name()
	var n := next()
	if tier + BUILD_AHEAD < int(n["tier"]):
		return UiKit.t("The %s is for clubs about to reach the %s. Climb a division first.") % [
			UiKit.t(String(n["name"])), League.tier_name(int(n["tier"]))]
	if credits < int(n["cost"]):
		return UiKit.t("The %s costs %d CC and you have %d.") % [
			String(n["name"]), int(n["cost"]), credits]
	return ""


## THE BADGE GETS BETTER WITH THE GROUND. Pete, 10 Sep 2026: *"each upgrade
## making the logo go from really shitty quality to NFL level details."*
##
## It is the club's OWN mark that improves, not a stock image — the same
## IconBank draw, rendered rough at a back field and crisp at a national arena.
## A player who picked the Wolf watches his wolf get sharper, which is a
## progression he owns; a stock logo getting better is a progression he watches.
##
## 0 is a rough paint job and 1 is a printed one.
func badge_quality() -> float:
	return float(level) / float(MAX_LEVEL)
