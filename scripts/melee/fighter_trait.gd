class_name FighterTrait
## WHAT IS UNUSUAL ABOUT ONE MAN.
##
## Pete picked these fifty on 13 Sep 2026 out of a bank of fifty-two; Heavy Legs
## and Mercenary were the two left on the shelf.
##
## WHERE THEY CAME FROM. Not from Retro Bowl's player traits — those are loaded
## from a `Traits_CO.txt` that is not in the build we decompiled, and of the three
## functions that touch the list, every one of them only ever fetches `"name"`.
## `s_get_random_trait` sits directly beside `s_get_random_hometown` and is rolled
## the same way. On that evidence their player traits are biography.
##
## What IS derived is the SHAPE of their coach traits, which we already mirror in
## `ClubOffice.Trait`, and which are better than they look:
##
##   an ARRIVAL ONE-SHOT that fires once and is done      -> LATE_BLOOMER
##   a PER-WEEK MULTIPLIER rather than a flat bonus       -> SPONGE, KIT_MINDER
##   a NEGATION instead of a bonus — "toxic players have
##     no negative impact" beats "+5 morale"              -> THICK_SKIN
##   A COST WHEN HE LEAVES, which almost nobody copies    -> TALISMAN
##
## EVERY LINE NAMES THE THING IT MOVES. The map at the bottom of this file is not
## documentation, it is the specification — `Trait.SCOUT` shipped with a
## description and no code for a week because nothing tied the words to a call
## site, and `test_traits.gd` walks this map and fails on a trait whose hook is
## not reachable.
##
## APPENDED ONLY. A fighter carries his trait as an int in every save, so slotting
## a new one into the middle turns every Grinder in the country into an Anchor —
## the same renumbering trap `ClubOffice.Facility` has a paragraph about.

enum T {
	NONE,
	GRINDER,
	SLIPPERY,
	ANCHOR,
	BEAR,
	THIRD_MAN,
	READER,
	COLD_HANDS,
	WRESTLER,
	QUICK_OFF,
	FREIGHT,
	LOW_MAN,
	LANE_RUNNER,
	ROUTE_RUNNER,
	WANDERER,
	HEAD_DOWN,
	DEEP_TANK,
	QUICK_BREATHER,
	SECOND_WIND,
	ENGINE,
	BELLOWS,
	ROOTED,
	ROCK,
	LAST_MAN,
	GLASS,
	PROUD,
	CAPTAINS_VOICE,
	STEADY,
	FIRESTARTER,
	THICK_SKIN,
	TALISMAN,
	POISON,
	PRIMA_DONNA,
	HOMESICK,
	BIG_OCCASION,
	FLAT_TRACK,
	GRUDGE,
	IRON,
	KIT_MINDER,
	HEAVY_HANDS,
	LATE_PEAK,
	BRITTLE,
	BURNS_OUT,
	ROUGH_ON_KIT,
	SPONGE,
	CEILING_RAISER,
	LATE_BLOOMER,
	PLATEAUED,
	CHEAP,
	DRAW,
	LOYAL,
}


const NAME := {
	T.NONE: "None",
	T.GRINDER: "Grinder",
	T.SLIPPERY: "Slippery",
	T.ANCHOR: "Anchor",
	T.BEAR: "Bear",
	T.THIRD_MAN: "Third Man",
	T.READER: "Reader",
	T.COLD_HANDS: "Cold Hands",
	T.WRESTLER: "Wrestler",
	T.QUICK_OFF: "Quick Off",
	T.FREIGHT: "Freight",
	T.LOW_MAN: "Low Man",
	T.LANE_RUNNER: "Lane Runner",
	T.ROUTE_RUNNER: "Route Runner",
	T.WANDERER: "Wanderer",
	T.HEAD_DOWN: "Head Down",
	T.DEEP_TANK: "Deep Tank",
	T.QUICK_BREATHER: "Quick Breather",
	T.SECOND_WIND: "Second Wind",
	T.ENGINE: "Engine",
	T.BELLOWS: "Bellows",
	T.ROOTED: "Rooted",
	T.ROCK: "Rock",
	T.LAST_MAN: "Last Man",
	T.GLASS: "Glass",
	T.PROUD: "Proud",
	T.CAPTAINS_VOICE: "Captain's Voice",
	T.STEADY: "Steady",
	T.FIRESTARTER: "Firestarter",
	T.THICK_SKIN: "Thick Skin",
	T.TALISMAN: "Talisman",
	T.POISON: "Poison",
	T.PRIMA_DONNA: "Prima Donna",
	T.HOMESICK: "Homesick",
	T.BIG_OCCASION: "Big Occasion",
	T.FLAT_TRACK: "Flat Track",
	T.GRUDGE: "Grudge",
	T.IRON: "Iron",
	T.KIT_MINDER: "Kit Minder",
	T.HEAVY_HANDS: "Heavy Hands",
	T.LATE_PEAK: "Late Peak",
	T.BRITTLE: "Brittle",
	T.BURNS_OUT: "Burns Out",
	T.ROUGH_ON_KIT: "Rough on Kit",
	T.SPONGE: "Sponge",
	T.CEILING_RAISER: "Ceiling Raiser",
	T.LATE_BLOOMER: "Late Bloomer",
	T.PLATEAUED: "Plateaued",
	T.CHEAP: "Cheap",
	T.DRAW: "Draw",
	T.LOYAL: "Loyal",
}


## His own wording, in our nouns, so the card and the code cannot drift.
const BLURB := {
	T.NONE: "Nothing about him is unusual.",
	T.GRINDER: "Wins a grapple faster than his numbers say.",
	T.SLIPPERY: "Gets out of a grapple he is losing.",
	T.ANCHOR: "Very hard to put down once he is set.",
	T.BEAR: "His takedowns land.",
	T.THIRD_MAN: "Worth far more when he joins a pile than when he starts one.",
	T.READER: "Sees the grapple coming - you get longer to answer his prompt.",
	T.COLD_HANDS: "Takes the wrong option when you leave him to it.",
	T.WRESTLER: "Enters a grapple on his terms; opens it already ahead.",
	T.QUICK_OFF: "First to the line.",
	T.FREIGHT: "Bullrushes like a heavier man.",
	T.LOW_MAN: "Does not get moved.",
	T.LANE_RUNNER: "No penalty standing one slot off his own.",
	T.ROUTE_RUNNER: "Holds a drawn play after everyone else has stopped.",
	T.WANDERER: "Drifts off the shape the moment the plan lapses.",
	T.HEAD_DOWN: "Fast, and blind to a man on his flank.",
	T.DEEP_TANK: "Simply carries more.",
	T.QUICK_BREATHER: "Gets far more back in the corner.",
	T.SECOND_WIND: "Once a bout, refills to half the moment he empties.",
	T.ENGINE: "Never really gasses; never really recovers either.",
	T.BELLOWS: "Burns energy in a grapple like nobody else.",
	T.ROOTED: "Recovers his feet between hits.",
	T.ROCK: "A clean hit barely moves him.",
	T.LAST_MAN: "Fights harder as the side thins out.",
	T.GLASS: "Goes over easy.",
	T.PROUD: "Refuses the corner - never asks to come off.",
	T.CAPTAINS_VOICE: "The whole side holds its shape longer while he is standing.",
	T.STEADY: "His mood never falls past level.",
	T.FIRESTARTER: "Angry is worth double on him.",
	T.THICK_SKIN: "A toxic teammate does nothing to him.",
	T.TALISMAN: "Lifts the room while he is here. Guts it when he goes.",
	T.POISON: "Drags the room twice as hard.",
	T.PRIMA_DONNA: "Sours every event he does not start.",
	T.HOMESICK: "A different man away from your own ground.",
	T.BIG_OCCASION: "Turns up for cups and Worlds.",
	T.FLAT_TRACK: "Shrinks on the big days.",
	T.GRUDGE: "Fights above himself against one named club, forever.",
	T.IRON: "Comes back sooner than he should.",
	T.KIT_MINDER: "His harness lasts.",
	T.HEAVY_HANDS: "Wrecks the other man's harness.",
	T.LATE_PEAK: "Still improving when the rest are going.",
	T.BRITTLE: "Every knock costs an extra event.",
	T.BURNS_OUT: "Goes early.",
	T.ROUGH_ON_KIT: "Comes back with the harness in pieces.",
	T.SPONGE: "Trains faster than the man beside him.",
	T.CEILING_RAISER: "A big afternoon actually raises what he can become.",
	T.LATE_BLOOMER: "Banks a season of training the day he signs.",
	T.PLATEAUED: "What you signed is what you get.",
	T.CHEAP: "Signs under the going rate and re-signs the same.",
	T.DRAW: "People come to watch him.",
	T.LOYAL: "Will not leave in a split, and re-signs cheap.",
}

## FLAWS ARE NOT BUGS. A trait pool with no downside is a stat wearing a nicer
## name; these are what make a cheap fighter a decision instead of a bargain.
## Fourteen of fifty, which is roughly the rate that makes a scouting report worth
## reading rather than a formality.
const FLAWS: Array[int] = [
	T.COLD_HANDS, T.WANDERER, T.HEAD_DOWN, T.BELLOWS, T.GLASS, T.PROUD,
	T.POISON, T.PRIMA_DONNA, T.HOMESICK, T.FLAT_TRACK, T.BRITTLE, T.BURNS_OUT,
	T.ROUGH_ON_KIT, T.PLATEAUED,
]


## ROLLED THE WAY A CAPTAIN'S IS — most men have nothing at all, and rare means
## rare. 6 is common, 3 uncommon, 1 rare; `NONE` carries the rest of the weight
## and carries most of it, because a squad where everybody is unusual is a squad
## where nobody is.
const NONE_WEIGHT: int = 150

const WEIGHT := {
	T.GRINDER: 6,
	T.SLIPPERY: 3,
	T.ANCHOR: 3,
	T.BEAR: 6,
	T.THIRD_MAN: 3,
	T.READER: 3,
	T.COLD_HANDS: 6,
	T.WRESTLER: 1,
	T.QUICK_OFF: 6,
	T.FREIGHT: 3,
	T.LOW_MAN: 3,
	T.LANE_RUNNER: 1,
	T.ROUTE_RUNNER: 3,
	T.WANDERER: 6,
	T.HEAD_DOWN: 3,
	T.DEEP_TANK: 6,
	T.QUICK_BREATHER: 3,
	T.SECOND_WIND: 1,
	T.ENGINE: 3,
	T.BELLOWS: 6,
	T.ROOTED: 6,
	T.ROCK: 3,
	T.LAST_MAN: 1,
	T.GLASS: 6,
	T.PROUD: 3,
	T.CAPTAINS_VOICE: 1,
	T.STEADY: 6,
	T.FIRESTARTER: 3,
	T.THICK_SKIN: 3,
	T.TALISMAN: 1,
	T.POISON: 6,
	T.PRIMA_DONNA: 3,
	T.HOMESICK: 3,
	T.BIG_OCCASION: 1,
	T.FLAT_TRACK: 3,
	T.GRUDGE: 1,
	T.IRON: 3,
	T.KIT_MINDER: 6,
	T.HEAVY_HANDS: 1,
	T.LATE_PEAK: 1,
	T.BRITTLE: 6,
	T.BURNS_OUT: 3,
	T.ROUGH_ON_KIT: 6,
	T.SPONGE: 6,
	T.CEILING_RAISER: 1,
	T.LATE_BLOOMER: 3,
	T.PLATEAUED: 6,
	T.CHEAP: 3,
	T.DRAW: 1,
	T.LOYAL: 1,
}


## ------------------------------------------------------------------ the wiring
## ONE TABLE, NOT FORTY-ONE `if` STATEMENTS.
##
## Every wired trait is a set of named effects, and every call site asks the same
## question: `FighterTrait.mod(card.trait_id, "grapple_grind", 1.0)`. Adding a
## trait is editing this dict; it is not touching the sim.
##
## The alternative — an `if t == T.GRINDER` at each of twenty call sites — is the
## shape that produced the Scout: a trait can be added to the enum, given a
## blurb, shown on a card, and wired nowhere, and nothing anywhere says so.
## `test_traits.gd` asserts every key in here is read somewhere outside this file
## and that every WIRED trait has at least one, so a trait that does nothing
## cannot reach the roll.
##
## MULTIPLIERS DEFAULT TO 1.0 AND ADDITIONS TO 0.0, which is why a man with no
## trait costs nothing: `mod` returns the default without a dictionary lookup on
## the common path.
const MOD := {
	## ---- the grapple
	T.GRINDER: {"grapple_grind": 1.25},
	T.SLIPPERY: {"escape": 1.4},
	T.ANCHOR: {"td_against": -0.10},
	T.BEAR: {"td_for": 0.10},
	T.THIRD_MAN: {"td_gang": 1.6},
	T.READER: {"prompt_time": 0.8},
	T.COLD_HANDS: {"ai_tier_down": 1.0},
	## ---- the charge
	T.QUICK_OFF: {"charge_speed": 1.12},
	T.FREIGHT: {"weight_bonus": 18.0},
	T.LOW_MAN: {"br_against": 1.4},
	T.LANE_RUNNER: {"pos_forgiving": 1.0},
	T.ROUTE_RUNNER: {"plan_extra": 5.0},
	T.WANDERER: {"no_reform": 1.0},
	T.HEAD_DOWN: {"speed": 1.10, "exposed_against": 1.5},
	## ---- energy
	T.DEEP_TANK: {"tank": 1.12},
	T.QUICK_BREATHER: {"corner_recovery": 1.45},
	T.ENGINE: {"gassed_below": 0.6, "corner_recovery": 0.7},
	T.BELLOWS: {"gas_grapple": 1.35},
	## ---- staying up
	T.ROOTED: {"stability_recover": 1.4},
	T.ROCK: {"hit_stability_against": 0.72},
	T.GLASS: {"hit_stability_against": 1.35},
	## ---- the changing room
	T.CAPTAINS_VOICE: {"team_plan_extra": 4.0},
	T.STEADY: {"morale_floor": 0.5},
	T.FIRESTARTER: {"chip_strength": 11.0},
	T.THICK_SKIN: {"immune_toxic": 1.0},
	T.POISON: {"toxic_weight": 2.0},
	T.BIG_OCCASION: {"occasion": 1.07},
	T.FLAT_TRACK: {"occasion": 0.93},
	## ---- the body
	T.IRON: {"injury_events": -1.0},
	T.KIT_MINDER: {"wear": 0.6},
	T.ROUGH_ON_KIT: {"wear": 1.5},
	T.LATE_PEAK: {"peak": 3.0},
	T.BURNS_OUT: {"peak": -4.0},
	T.BRITTLE: {"injury_events": 1.0},
	## ---- learning
	T.SPONGE: {"xp": 1.2},
	T.PLATEAUED: {"xp": 0.6},
	T.CEILING_RAISER: {"ceiling_on_big": 1.0},
	T.LATE_BLOOMER: {"arrival_xp": 24.0},
	## ---- the wallet
	T.CHEAP: {"wage": 0.8},
	T.DRAW: {"turnout": 0.03},
	T.LOYAL: {"wage": 0.9, "no_split": 1.0},
	## ---- the eight that were written and not wired, now wired
	## WRESTLER opens a clinch with real wear, through `_wear`, so it counts
	## toward an assist like everything else done to a man.
	## 0.06 AND NOT 0.18. `probe_pending.gd` measured the first figure at +24.4
	## points of win rate on a five, against Grinder — the strongest thing already
	## shipped — at +17.8. A clinch entry is common and this is free, so 0.18 was
	## better than a free hit (`Tuning.HIT_STABILITY` is 0.08) on every one of
	## them. It sits just under a hit now.
	T.WRESTLER: {"grapple_open": 0.06},
	## SECOND WIND is a flag, not a number — where it fires and what it gives
	## back are `Tuning.SECOND_WIND_AT` and `_TO`, because a trait that carried
	## its own threshold would be a second gassed line nobody could find.
	T.SECOND_WIND: {"second_wind": 1.0},
	## LAST MAN at full effect with four of his side on the floor; nothing while
	## the five are up. `_rally` scales it.
	T.LAST_MAN: {"alone": 1.12},
	## PROUD is a refusal the corner has to honour, so it is a flag the screen
	## reads rather than anything the sim does.
	T.PROUD: {"no_sub": 1.0},
	## TALISMAN lifts everybody ELSE while he stands. `_rally` never gives it to
	## him, or he would be topping up his own numbers on top of the room's.
	## TALISMAN lifts everybody ELSE — in the dressing room, not on the field.
	##
	## Three in-fight levers were measured and every one was either enormous or
	## nothing: a multiplier on everything gave ONE man +12.2 points of win rate
	## and still +11.1 when cut from x1.05 to x1.02; stability recovery gave
	## +0.0; the corner gave -2.2, inside the noise. The figures are in the note
	## on `MeleeSim._rally`. Morale is bounded by construction and already has
	## measured effects all through the club layer, which is what a room-wide
	## trait needs.
	T.TALISMAN: {"room_morale": 0.05},
	## PRIMA DONNA sours an event he did not start — the season applies it, once,
	## at the point the eight is known.
	T.PRIMA_DONNA: {"benched_morale": -0.09},
	## GRUDGE against one named club, forever. `Season` names the club the first
	## time one beats him; the sim reads it off the card.
	T.GRUDGE: {"grudge": 1.10},
	## HOMESICK, at last. It waited eight passes for a fixture list that knew
	## where a bout was — see `Venue`. Away and neutral grounds both count as
	## away, because a neutral ground is not his either.
	T.HOMESICK: {"away": 0.93},
	## HEAVY HANDS wrecks harness. Applied to the men he actually fought, after
	## the bout, through the same `wear` figure the regime uses.
	T.HEAVY_HANDS: {"harness": 0.05},
}

## NOTHING IS PENDING. It was nine, then one, and the one was Homesick — which
## needed *"a home and an away, and this game has neither"*. Pete read that note
## and built the thing rather than the workaround: *"Looks like we just surfaced
## that we need to add the 'City' selectable for your team."* See `Venue`.
##
## THE LIST STAYS, EMPTY, and `test_traits.gd` still reads it. It is the honest
## version of a TODO and the mechanism is the point: a trait is wired or it is
## named here, and it can never quietly be neither. The next trait that needs
## something the game does not have goes in this array on the day it is written.
const PENDING: Array[int] = []


## The one door. `def` is what a man with no trait gets, so every call site reads
## the same shape whether or not anybody is unusual.
static func mod(t: int, key: String, def: float) -> float:
	if t == T.NONE or not MOD.has(t):
		return def
	var row: Dictionary = MOD[t]
	return float(row[key]) if row.has(key) else def


## A flag rather than a number — `pos_forgiving`, `no_reform`, `immune_toxic`.
static func flag(t: int, key: String) -> bool:
	return t != T.NONE and MOD.has(t) and MOD[t].has(key)


static func is_wired(t: int) -> bool:
	return t == T.NONE or (MOD.has(t) and not PENDING.has(t))


static func names() -> Array[String]:
	var o: Array[String] = []
	for k in NAME:
		o.append(String(NAME[k]))
	return o


static func name_of(t: int) -> String:
	return String(NAME.get(t, NAME[T.NONE]))


static func blurb_of(t: int) -> String:
	return String(BLURB.get(t, BLURB[T.NONE]))


static func is_flaw(t: int) -> bool:
	return FLAWS.has(t)


## Deterministic from a seed, like everything else a fighter is made of, so the
## man on the market does not change trait while you look at him.
##
## A PENDING TRAIT IS NEVER ROLLED. It is in the enum, it has a name and a blurb
## and it will show correctly the day it is wired — and until then no fighter in
## the country has it, because a trait that does nothing is worse on a card than
## no trait at all.
static func roll(seed_value: int) -> int:
	var total := NONE_WEIGHT
	for k in WEIGHT:
		if not PENDING.has(int(k)):
			total += int(WEIGHT[k])
	var n := absi(seed_value) % total
	if n < NONE_WEIGHT:
		return T.NONE
	n -= NONE_WEIGHT
	for k in WEIGHT:
		if PENDING.has(int(k)):
			continue
		n -= int(WEIGHT[k])
		if n < 0:
			return int(k)
	return T.NONE


## ---------------------------------------------------------------- the spec
## WHERE EACH ONE LANDS. Read by `test_traits.gd`, not just by people.
##
## A hook marked [NEW] used to mean "needs something built in the sim before the
## trait can do anything". Ten of them carried that marker on 15 Sep 2026 and
## every one of the ten was wired and tested — `PENDING` was already empty, which
## is the machine-readable version of the same claim, and `is_wired()` reads it.
##
## So the list and the constant had been disagreeing for as long as it took to
## build them, with nothing to notice because only one of the two is read by
## anything. The markers are gone. **When a comment and a constant say different
## things about the same fact, the comment is the one that will be believed and
## the constant is the one that is true** — and here they now agree.
##
## If a trait is ever added ahead of its hook, put it in `PENDING` and let
## `is_wired()` keep it out of the roll. That is the mechanism; a marker in a
## comment never was.
##   GRINDER          GRAPPLE_GRIND x1.25 when he is the holder
##   SLIPPERY         _resolve ESCAPE: ESCAPE_PER_SKL x1.4
##   ANCHOR           _takedown_chance against him: TD_BASE -0.10
##   BEAR             _takedown_chance for him +0.10
##   THIRD_MAN        TD_GANG x1.6 when he is the helper
##   READER           PROMPT_TIME +0.8 on his menus
##   COLD_HANDS       _ai_choose drops a tier for him
##   WRESTLER         _enter_grapple seeds his grind at 0.15
##   QUICK_OFF        SPEED_BASE +12% while phase == CHARGE
##   FREIGHT          _bullrush_chance reads his weight +18lb
##   LOW_MAN          BR_PER_BASE against him x1.4
##   LANE_RUNNER      OUT_OF_POS waived at +-1 slot
##   ROUTE_RUNNER     his plan_t +5s past PLAN_TIME
##   WANDERER         _refresh_anchors ignores him
##   HEAD_DOWN        SPEED +10%, EXPOSED_BONUS against him x1.5
##   DEEP_TANK        card.tank() x1.12 via eff_tank
##   QUICK_BREATHER   _corner_recovery x1.45 for him
##   SECOND_WIND      tick: on gas_frac == 0, once per bout
##   ENGINE           GASSED_BELOW x0.6, corner recovery x0.7
##   BELLOWS          GAS_GRAPPLE x1.35
##   ROOTED           STABILITY_RECOVER x1.4
##   ROCK             HIT_STABILITY against him x0.72
##   LAST_MAN         +8% eff_base per standing man missing
##   GLASS            HIT_STABILITY against him x1.35
##   PROUD            blocked from swap_in unless injured
##   CAPTAINS_VOICE   team plan_t +4s while he is up
##   STEADY           morale floored at 0.5
##   FIRESTARTER      CHIP_STRENGTH 6 -> 11 when angry()
##   THICK_SKIN       the Likeable negation, at the man
##   TALISMAN         +0.06 club morale; -0.15 on sale
##   POISON           his toxic() effect x2
##   PRIMA_DONNA      morale -0.04 per bout benched
##   HOMESICK         -6% eff_base when not at home
##   BIG_OCCASION     +7% eff_base when bout_mood > NORMAL
##   FLAT_TRACK       -7% eff_base when bout_mood > NORMAL
##   GRUDGE           a stored club id on the card
##   IRON             INJURY_LENGTH -1 for him
##   KIT_MINDER       Workshop wear x0.6
##   HEAVY_HANDS      his hits take armor off the target
##   LATE_PEAK        Career.PEAK_BASE +3
##   BRITTLE          INJURY_LENGTH +1
##   BURNS_OUT        Career.PEAK_BASE -4
##   ROUGH_ON_KIT     Workshop wear x1.5
##   SPONGE           XP x1.2 - the Positive shape, at the man
##   CEILING_RAISER   potential +1 on a 3-down bout
##   LATE_BLOOMER     the Experience arrival one-shot
##   PLATEAUED        XP x0.6
##   CHEAP            billed() x0.8
##   DRAW             turnout +3% while on the eight
##   LOYAL            exempt from splinter_rosters
