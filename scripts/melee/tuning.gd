class_name Tuning
extends RefCounted
## Every number in the melee, in one place.
##
## A balance pass is a diff of this file and nothing else. Numbers marked [C-n]
## are hard rules from docs/CONSTRAINTS.md and are asserted in tests/test_melee.gd.

# ------------------------------------------------------------------ the line
## Rail · Flanker · Center · Flanker · Rail. Pete's line, 10 Sep 2026.
## Rail and Flanker sit close together on each side; the Center is between the
## two pairs, and the gap either side of him is wider than the gap inside a pair.
## That spacing is the formation, so it is data, not a magic number in a loop.
enum Pos { RAIL_L, FLANK_L, CENTER, FLANK_R, RAIL_R }

const POS_NAME := {
	Pos.RAIL_L: "Rail",
	Pos.FLANK_L: "Flanker",
	Pos.CENTER: "Center",
	Pos.FLANK_R: "Flanker",
	Pos.RAIL_R: "Rail",
}

## Fraction of the list's width each position starts on.
const POS_X := [0.10, 0.27, 0.50, 0.73, 0.90]

## Who a fighter starts paired with. Rail and Flanker stick together on each
## side unless split — and splitting is not a command, it is what has HAPPENED
## once you draw one of them a path somewhere his partner is not.
const POS_PARTNER := [Pos.FLANK_L, Pos.RAIL_L, -1, Pos.RAIL_R, Pos.FLANK_R]

## THE ROLE, as distinct from the SLOT. There are five places on the line but
## only three jobs: a Rail is a Rail whichever side of the list he is standing
## on. This is what a backup covers and what "out of position" is measured
## against — a Rail filling the other Rail slot is not out of position, and
## treating him as though he were would make the depth chart nonsense.
enum Role { RAIL, FLANK, CENTER }

## ------------------------------------------------------------- the weapon
## TWO WEAPON CLASSES AND NO MORE (Pete, 14 Sep 2026): sword-and-shield and
## polearm. Buhurt has no thrusts — every strike is a swing — no dual-wielding,
## no war hammers or flails; shield punches are legal.
##
## What the difference is FOR in a management game is a line-up decision, so
## the effects are small and read through the same `tmod` door the traits use:
## a key with default 1.0 multiplies, a key with default 0.0 adds.
##   POLEARM  reach — he closes to contact from further out; hooks and sweeps —
##            better takedowns; no shield — easier to bullrush, and two hands on
##            a pole are worse in a clinch.
##   SWORD & SHIELD  the shield braces him against a bullrush and the punch is
##            a small edge on his own.
enum Weapon { SWORD_SHIELD, POLEARM }
const WEAPON_NAME := { Weapon.SWORD_SHIELD: "Sword & shield", Weapon.POLEARM: "Polearm" }
const WEAPON_SHORT := { Weapon.SWORD_SHIELD: "S&S", Weapon.POLEARM: "Pole" }
const WEAPON_MODS := {
	Weapon.SWORD_SHIELD: {"br_against": 1.05, "td_for": 0.0},
	Weapon.POLEARM: {"reach": 1.15, "td_for": 0.04, "br_against": 0.90, "escape": 0.90},
}
## Who carries a pole when a club is generated, by role: the rails hook from the
## end of the line, the centre anchors behind a shield.
const POLEARM_SHARE := { Role.RAIL: 40, Role.FLANK: 25, Role.CENTER: 10 }


static func weapon_mod(weapon: int, key: String):
	var row: Dictionary = WEAPON_MODS.get(weapon, {})
	return row.get(key, null)


static func weapon_name(weapon: int) -> String:
	return String(WEAPON_NAME.get(weapon, UiKit.t("Sword & shield")))
const POS_ROLE := [Role.RAIL, Role.FLANK, Role.CENTER, Role.FLANK, Role.RAIL]
const ROLE_NAME := { Role.RAIL: "Rail", Role.FLANK: "Flanker", Role.CENTER: "Center" }

# ------------------------------------------------------------------ the list
const TICK: float = 1.0 / 30.0
## THE LIST. `LIST_W` runs along the line, Rail to Rail; `LIST_H` runs along the
## charge, your rail to theirs. The screen draws it rotated, so LIST_H is the
## width you see.
##
## Widened from 320 to 760 on 10 Sep 2026 — Pete: *"Widen the arena a lot more.
## That should also add time to the rounds."* — then brought back 25% to 570,
## because 760 filled the frame edge to edge and left nowhere for the two clubs'
## banners to stand. Both halves of the original instruction still hold.
## A near-square list left gutters down both sides of a 16:9 screen, and it also
## made the charge almost nothing: two lines forty meters apart met in under six
## seconds and the whole round was one long grind. A real list is fought down its
## length, and giving it that length gives the round its shape back — a charge,
## a first contact, and then the fight.
##
## This is the one number in the file that invalidates the whole melee suite when
## it moves, so it moves once, deliberately, and everything is re-measured after.
const LIST_W: float = 300.0
const LIST_H: float = 570.0
const RAIL_INSET: float = 14.0

# ----------------------------------------------------------------- the clock
## Pete, 10 Sep 2026: a real 5v5 is capped at five minutes, but Retro Bowl does
## not use a fifteen-minute NFL quarter either.
## 60 on 10 Sep 2026, then 120 once the list was widened — Pete's call. The clock
## is a backstop and the stop rule is what should actually end a round; a round
## that reaches the clock is a round that did not resolve, and those should be
## rare. Two minutes is a real 5v5's own order of magnitude rather than a mobile
## compromise, and with a shorter list the rounds resolve long before it.
const ROUND_TIME: float = 120.0
const ROUNDS: int = 3                   ## best of three — see BOUT_WINS
const BOUT_WINS: int = 2                ## take two rounds and the third is not fought
const CORNER_TIME: float = 20.0

## THE BENCH. Pete, 10 Sep 2026 — "you should be able to swap fighters between
## rounds from the bench anyway", taken from ACRTW. Two men per corner: enough
## that a gassed Rail is a decision, not so many that you re-cast the whole line
## every twenty seconds and the men on the list stop being yours.
const SWAPS_PER_CORNER: int = 2
## A man who sat the round out gets far more back than one who fought it. That
## gap IS the mechanic: the bench is a way of buying wind.
const BENCH_RECOVER: float = 0.62
## Filling a slot you are not listed for costs you. Without it the bench is just
## "field your five best" and Rail, Flanker and Center stop meaning anything.
const OUT_OF_POS: float = 0.94
const CHARGE_TIME: float = 2.0

# ------------------------------------------------------------- the stop rule
## Pete, 10 Sep 2026. Nobody gets back up, and a round ends when either
##
##   * a side is wiped                        — 5-0, 4-0, 3-0, 2-0, 1-0
##   * a side is on its last man and the       — 3-1, 4-1, 5-1
##     other still has three
##
## **2-1 and 1-1 stay in play** (Pete, 10 Sep 2026). That is what makes 1-0
## reachable: 2-1 keeps going, 2-0 or 1-1 follows, and 1-1 can only end 1-0.
##
## NINE is the ceiling on downs in one round, and a 1-0 is how you get there —
## the winner has lost four and the loser all five. Ten would mean every man on
## the list is down, and somebody is always left standing. Asserted in the suite.
const STOP_LEAD: int = 3                ## the "three" in three-to-one
const STOP_TRAIL: int = 1               ## his last man
const MAX_DOWNS_PER_ROUND: int = 9

# ------------------------------------------------------------------- moving
## Raised with the list, 30 -> 46 on 10 Sep 2026, and the reason matters. A list
## more than twice as long at the old pace put 29% of rounds on the clock — the
## extra time was going into WALKING, not fighting, which is the opposite of what
## widening it was for. At 46 a round runs 44s against the old 38s, so it is
## longer as Pete asked, and only 13% reach the clock, which is fewer unresolved
## rounds than the narrow list produced. Measured with tools/probe_pace.gd.
const SPEED_BASE: float = 46.0
const SPEED_PER_GAS: float = 0.28
const SPEED_EMPTY_FLOOR: float = 0.45
const BODY_RADIUS: float = 20.0
const GRAPPLE_GAP: float = 19.0          ## how far apart two men in a clinch stand
## How much a man wants to pile onto an opponent who is already tied up, before
## the strategy dial scales it. It is deliberately near zero at the neutral
## setting: at +70 the entire line converged on one man, every round cascaded,
## and a 90-second round was over in ten. Ganging is a STRATEGY, not a default.
const GANG_PULL: float = 25.0
const GANG_FLOOR: float = 20.0          ## subtracted, so a low-gang strategy actively avoids piles

## THE ROLES, FROM ACRTW'S OWN SPEC — Pete, 10 Sep 2026: *"Check ACRTW for role
## explanations."* `COMBAT_AI_DESIGN_SPEC.md` §6 has them written down properly,
## in the NFL analogy the sport's own people use:
##
##   **Rail**    the anchor of the shoulder pair — the line itself.
##   **Flanker** a linebacker: offence alongside his Rail. He CAN cover, but
##               covering is not the job. Rail and Flanker move as a bonded pair
##               until an advantage appears or a play splits them.
##   **Center**  a FREE SAFETY. He picks up the open, loose man and **screens
##               their reinforcements** — denying their help is a first-class
##               action and it is his before it is anybody's.
##
## Which is the same thing Pete said in one line — *"Centers are opportunists,
## not frontline"* — and it is the opposite of what I implemented an hour ago.
## I had the Center seeking men who were ALREADY TIED UP, on the reasoning that
## an opportunist wants a busy target. Wrong: a busy enemy is not going anywhere,
## and the man who decides the fight is the one still free to go and make it
## two-on-one somewhere else. **The Center's job is to be the reason their free
## man never arrives.**
##
## The pair bond is already built (PAIR_LEASH); this is the first time the Center
## does anything a Rail does not.
const CENTER_SEEKS_LOOSE: float = 30.0    ## the open man is his man
const CENTER_DENIES_HELP: float = 44.0    ## and most of all the one about to reinforce
const CENTER_AVOIDS_CLASH: float = 18.0   ## he is not the one who goes in first
## How close an enemy has to be to one of our engaged men to count as "about to
## help him". Generous, because the point is to intercept before he arrives.
const HELP_RANGE: float = 150.0

const PAIR_LEASH: float = 46.0          ## how far a Flanker drifts from his Rail
const WAYPOINT_HIT: float = 8.0         ## close enough to call a waypoint reached

# ------------------------------------------------------------------ prompts
## The prompt opens at this range and the AI answers it when the timer runs out.
## "The AI will choose unless you choose." — Pete, 10 Sep 2026.
const PROMPT_RANGE: float = 34.0
const PROMPT_TIME: float = 2.2
const CONTACT_RANGE: float = 24.0       ## where the chosen action actually resolves

enum Menu { APPROACH, GRAPPLED, THIRD_MAN }
enum Act { BULLRUSH, GRAPPLE, HIT, TAKEDOWN, HOLD, ESCAPE, BREAK }

const MENU_ACTS := {
	Menu.APPROACH: [Act.BULLRUSH, Act.GRAPPLE, Act.HIT],
	Menu.GRAPPLED: [Act.TAKEDOWN, Act.HOLD, Act.ESCAPE],
	Menu.THIRD_MAN: [Act.TAKEDOWN, Act.HIT, Act.BREAK],
}

## Pete's word, not the dossier's. The glossary calls this a "check"; he fights,
## and 02.17 locked Bullrush on 10 Sep 2026.
const ACT_NAME := {
	Act.BULLRUSH: "Bullrush",
	Act.GRAPPLE: "Clinch",
	Act.HIT: "Hit",
	Act.TAKEDOWN: "Takedown",
	Act.HOLD: "Hold",
	Act.ESCAPE: "Escape",
	Act.BREAK: "Break",
}

# ----------------------------------------------------------------- the maths
## Stability is what a Hit spends. It is not health — nobody is killed — it is
## how well a man is still standing over his own base. Everything that puts
## someone down reads it, which is what makes Hit an investment rather than a
## weak Bullrush.
const STABILITY_MAX: float = 1.0
const HIT_STABILITY: float = 0.08
const HIT_GAS: float = 0.05
const HIT_COOLDOWN: float = 1.1
const STABILITY_RECOVER: float = 0.050  ## per second, when not engaged

## Putting an armored man over his own base is HARD, and the first pass had it
## at 0.30 per attempt — which ended rounds in six seconds and made Hit, Hold
## and the 2-on-1 all pointless, because you could just keep trying. A fresh,
## well-based man should be close to immovable; everything that puts him down
## comes from wearing him out first. That is the whole reason Hit exists.
const TD_BASE: float = 0.13
const TD_PER_STR: float = 0.0040        ## attacker strength vs defender base
const TD_PER_SKL: float = 0.0020
const TD_STABILITY_W: float = 0.30      ## a wobbling man goes down much easier
const TD_GANG: float = 0.06             ## [the 2-on-1] third man on an occupied opponent

## EXPERIMENT SWITCHES FOR MORNING DECISION #10 (29 Sep 2026) — both OFF, so the
## game plays exactly as it did. `bb probe fightskill <n> sent` flips them to
## measure what a player's route is worth under each option; nothing in the
## game sets them. Static vars rather than consts only so a probe can.
##   sent_edge   added to the takedown and bullrush odds of a man the player SENT
##               (a thumb-drawn order, not a play), on the act his order ends in.
##   sent_walks  a sent man keeps walking while his question is open, instead of
##               standing at the range it came up at.
static var sent_edge: float = 0.0
static var sent_walks: bool = false
## AND FOR #11: a PAID session trains the five at the full weekly rate instead
## of PRACTICE_STARTER's quarter ("his week is mostly Saturday" is true of the
## free week, not of an extra one the club paid for). OFF.
static var session_full_week: bool = false
## And its price, scaled (1.0 = as shipped).
static var session_price_scale: float = 1.0
const TD_MIN: float = 0.05
const TD_MAX: float = 0.45
const TD_FAIL_EXPOSE: float = 1.2       ## seconds you are takeable after missing

const BR_BASE: float = 0.07
## Per POUND of difference. Was per kilogram at 0.0040; a pound is 0.4536 of a
## kilo, so the coefficient divides by the same factor and every bullrush
## resolves exactly as it did before the units changed. **A unit change that
## moves the balance is a balance change wearing a disguise.**
const BR_PER_LB: float = 0.00181
const BR_PER_BASE: float = 0.0028
const BR_STABILITY_W: float = 0.28
const BR_MIN: float = 0.05
const BR_MAX: float = 0.42
const BR_GAS: float = 0.09              ## a bullrush is expensive
const BR_FAIL_EXPOSE: float = 1.5       ## and missing one is worse than missing a takedown

const ESCAPE_BASE: float = 0.55
const ESCAPE_PER_SKL: float = 0.0030
const ESCAPE_GAS: float = 0.06
## Against a man who just missed. It was 0.30 against a 0.06 base, which made a
## single failed attempt very nearly a free down for the other side and turned
## every engagement into a coin flip decided by who swung first.
const EXPOSED_BONUS: float = 0.15

## After a clinch breaks up, a man gives ground and gets his wind back before
## he goes again. Without it the melee is a continuous grind: everyone contacts
## at six seconds and nobody ever disengages, which put a 90-second round away
## in ten. Real fights ebb, and this is the ebb.
## 3.0 until 10 Sep 2026. Lengthened once the Center started intercepting loose
## men: engagements now start sooner and follow each other faster, and the round
## had compressed to 24 seconds. This is the ebb between grapples, so stretching it
## gives the round its shape back without touching the down economy — which is
## the part that was finally right.
const RECOVER_TIME: float = 4.4
const RECOVER_STEP: float = 0.55       ## fraction of his pace while giving ground
const RECOVER_STABILITY: float = 0.14  ## per second, recovering off the grapple

## Being in a grapple is work, and it costs you your base whether or not anybody
## is attempting anything. Without this the wear-down loop had no source of
## wear in an even fight — stability only fell to a Hit, Hit is not in the
## clinch menu, so two evenly matched clubs fought for four and a half minutes
## and put NOBODY on the ground. The stronger man grinds the other down faster,
## which is what makes strength and base matter every second rather than only
## at the moment of an attempt.
## HOW MUCH OF A MAN'S UNDOING YOU HAVE TO OWN TO BE CREDITED WITH HELPING —
## Pete, 13 Sep 2026: *"Assists can be 2nd most damage or effect on enemy."*
##
## Second-most is the rule; this is the floor under it, and it is the difference
## between a statistic and a participation count. At 15% a man who spent real
## time on the victim gets the credit and a man who landed one shot on his way
## past does not.
const ASSIST_SHARE: float = 0.15

## SECOND WIND — where it fires and what it gives back.
##
## `SECOND_WIND_AT` is the bottom of the tank and is deliberately not
## `GASSED_BELOW`: that is the band where a man is struggling and this is the
## point where he has nothing. A trait that fired at the gassed line would go off
## the first time anybody breathes hard, which is not once a bout, it is early.
const SECOND_WIND_AT: float = 0.04
const SECOND_WIND_TO: float = 0.50

## How far Heavy Hands can wreck a harness. A man at 0.80 of his base is a man
## in a beaten kit; a man at nothing is a trait deciding the afternoon by itself.
const HARNESS_FLOOR: float = 0.80


## HOW A MAN IS, IN A WORD — Pete, 13 Sep 2026: *"Change kit to condition: Fresh,
## Healthy, Tired, Beat Up, Injured."*
##
## A percentage is a number you compare; a word is a thing you decide about. The
## corner shows both, because the bar is for reading across five men at a glance
## and the word is for the one you are about to sub.
const CONDITION_BANDS: Array[float] = [0.85, 0.60, 0.30]
const CONDITION_WORDS: Array[String] = ["Fresh", "Healthy", "Tired", "Beat Up"]


static func condition_word(energy: float, fit: bool = true) -> String:
	if not fit:
		return UiKit.t("Injured")
	for i in CONDITION_BANDS.size():
		if energy >= CONDITION_BANDS[i]:
			return UiKit.t(CONDITION_WORDS[i])
	return UiKit.t(CONDITION_WORDS[CONDITION_WORDS.size() - 1])

const GRAPPLE_GRIND: float = 0.056       ## stability per second, at parity
const GRAPPLE_GRIND_GASSED: float = 1.45  ## multiplier once your tank is under GASSED_BELOW

const GRAPPLE_MIN: float = 1.6           ## before a break can be called
const BREAK_INACTIVE: float = 10.0      ## the marshal's "Break!" — glossary #30
const DOWN_HOLD: float = 1.2

# ------------------------------------------------------------------ injuries
## Going down in eighty pounds of steel occasionally costs you more than the
## round. Kept low on purpose: about 25 men hit the ground in a bout, so even a
## few per cent means most weekends produce one knock somewhere on the list,
## which is a squad problem rather than a disaster.
##
## A gassed man goes down badly, which is the sport's own folklore and is also
## the only lever here that the player can actually do something about.
## Measured at 0.028 first, which produced 0.08 knocks a bout — about one
## injury every three weekends across BOTH clubs, so a squad might see two in a
## season and the Infirmary would be a button nobody could feel. At 0.05 your
## own five pick up roughly a knock every four events, which is a bench problem
## a few times a year: often enough to matter, rare enough to be news.
const INJURY_CHANCE: float = 0.05
const INJURY_GASSED: float = 2.1
## Events missed, drawn from this. Mostly one, occasionally three, and the
## Infirmary takes events off the top.
const INJURY_LENGTH := [1, 1, 1, 1, 2, 2, 3]

# --------------------------------------------------------------- the gas tank
## WALKING IS FREE. Pete, 10 Sep 2026: *"do not have walking effect stamina."*
##
## It has been charged per second and then per meter, and both were wrong in the
## same way — they made crossing the list the thing that emptied a man, when
## what actually empties a man is being in a grapple with somebody. Armor is heavy
## to fight in, not heavy to stand up in. The tank is spent in GAS_GRAPPLE and in
## the things that cost a burst (a bullrush, an escape), and nowhere else.
##
## Left as a named constant at zero rather than deleted: three passes have now
## argued about this number, and the next person to wonder whether walking
## should cost gas deserves to find the answer rather than the absence of one.
const GAS_MOVE: float = 0.0
## Raised from 0.021 on 10 Sep 2026, the same day walking stopped costing
## anything. The two go together: if a grapple is the ONLY thing that empties a
## man then a grapple has to empty him, and at the old rate — set when crossing
## was also draining people — only 3.7 men a bout ran out and the post-fight
## report could name a gas problem in 15 bouts of 40. C-4 caught it, which is
## twice now that removing a gas source has quietly retired the tank.
const GAS_GRAPPLE: float = 0.058
const GAS_RECOVER: float = 0.022
const GAS_CORNER: float = 0.30
const GAS_STAT_DIV: float = 50.0
const GASSED_BELOW: float = 0.30

# ------------------------------------------------------------------ the corner
## Formation shapes the line; strategy is picked in the corner and is locked for
## the round (02.14). Offsets are in fractions of the list's height, applied to
## each position's starting depth.
## "Refused flank" was here until 10 Sep 2026, when Pete — seven years in the
## sport and on a federation board — said *"I don't even know what 'Refused
## flank' is."* It is a real term, out of military history, and it is not a term
## anybody on a list uses. Third time a borrowed word has been caught this way
## after "Bind" and "Carry", and the rule the register already carries applies:
## **where Pete would know it first-hand, his word wins.** "Staggered" describes
## the shape in a word anyone can read off the screen.
## THE SET-UP LINE. Pete, 10 Sep 2026: *"Don't start anyone more than 15% from
## the back rail, you can have the Center touching, but keep everyone back behind
## a 15% mark, you can probably mark it on the field."*
##
## So it is a rule rather than a per-formation choice, and it is DRAWN — the
## melee screen paints it at 15% of the charge axis on both sides, because a
## constraint the player has to infer from where the men happen to stand is not a
## constraint, it is a surprise.
##
## This is also the rule the Chalkboard will enforce when a player builds his own
## formation, so it lives here rather than inside any one shape.
const SET_UP_LINE: float = 0.15

## VECTOR2 IS 32-BIT. A player who drags a man exactly onto the painted line
## produces a y of 0.150000005960464, because that is the nearest float32 to
## 0.15, and comparing it against the 64-bit constant refuses the one placement
## the line is drawn to invite. So the checks below allow half a thousandth —
## smaller than a pixel at any sane list size, and far smaller than the
## thousandth the tests prove is still refused.
const SPOT_EPSILON: float = 0.0005

## A formation is FIVE SPOTS, not five depths.
##
## It used to be an array of depth offsets applied to a fixed lateral spacing,
## which meant every formation had the men in the same five columns and could
## only shuffle them forward and back. Pete's first correction — *"2-1-2, Flankers
## are a little closer to their Rails"* — is a LATERAL change, and the old shape
## could not express it. Spots can, and they are what a player-built formation
## has to be anyway.
##
##   x  across the line, 0 is your left rail and 1 is your right
##   y  out from your own back rail, 0 is touching it and SET_UP_LINE is the limit
enum Formation { TWO_ONE_TWO, DEPTH, STRONG_LEFT }

const FORMATIONS := {
	Formation.TWO_ONE_TWO: {
		"name": "2-1-2",
		"blurb": "Two, one, two. Each Flanker tucked in close to his Rail.",
		"spots": [
			Vector2(0.11, 0.12), Vector2(0.25, 0.12), Vector2(0.50, 0.12),
			Vector2(0.75, 0.12), Vector2(0.89, 0.12),
		],
	},
	Formation.DEPTH: {
		"name": "Depth",
		"blurb": "Center on the back rail, the pairs up on the line. Nothing comes through the middle.",
		"spots": [
			Vector2(0.11, 0.15), Vector2(0.26, 0.13), Vector2(0.50, 0.00),
			Vector2(0.74, 0.13), Vector2(0.89, 0.15),
		],
	},
	Formation.STRONG_LEFT: {
		"name": "Strong left",
		"blurb": "The left pair up and level, the right pair back and level. Pick a side and mean it.",
		"spots": [
			Vector2(0.11, 0.15), Vector2(0.25, 0.15), Vector2(0.50, 0.09),
			Vector2(0.74, 0.04), Vector2(0.89, 0.04),
		],
	},
}


## Every spot a formation puts a man on must be behind the set-up line. Checked
## rather than trusted, because the Chalkboard will let players write these.
static func formation_legal(spots: Array) -> String:
	if spots.size() != 5:
		return UiKit.t("A formation needs five spots.")
	for i in spots.size():
		var v: Vector2 = spots[i]
		if v.y < -SPOT_EPSILON or v.y > SET_UP_LINE + SPOT_EPSILON:
			return UiKit.t("%s is %.0f%% out; nobody starts past %.0f%%.") % [
				POS_NAME[i], v.y * 100.0, SET_UP_LINE * 100.0]
		if v.x < 0.02 - SPOT_EPSILON or v.x > 0.98 + SPOT_EPSILON:
			return UiKit.t("%s is off the list.") % POS_NAME[i]
	return ""


## ------------------------------------------------------------------- plays
## A PLAY IS FIVE DRAWN ROUTES, and it is the tactic rung of the ladder — under
## the thumb, over the strategy. Pete, 10 Sep 2026: *"Chalkboard - Plays will
## let the player draw the routes he wants his fighters to initially take."*
##
## Routes are normalised into the drawing team's OWN frame, exactly like a
## formation spot: x across the line from their left, y out from their own back
## rail toward the enemy. Team 1 mirrors both axes, so a play drawn by a club is
## the same play whichever end of the list it is fought from.
##
## A route's FIRST waypoint is not the man's starting spot. He starts on the
## formation spot and the route is where he goes from there, which is why a play
## can be universal: the same four waypoints mean something sane whether he set
## up on the rail or tucked in beside it.
const PLAY_MAX_POINTS: int = 6
## How far a route may reach. Half the list is a charge into their half; a route
## that could reach their back rail would be an order to run the whole fight,
## and the AI would never get the man back. See MeleeSim: a walked route expires
## into the strategy plan, and that expiry is the design.
const PLAY_MAX_Y: float = 0.62


## Every route a player draws is checked here rather than trusted, the same as a
## formation. Empty routes are legal and common — a play that moves two men and
## leaves three where they stand is a play.
static func play_legal(routes: Array) -> String:
	if routes.size() != 5:
		return UiKit.t("A play needs a route slot for each of the five.")
	var drawn := 0
	for i in routes.size():
		var r: Array = routes[i]
		if r.is_empty():
			continue
		drawn += 1
		if r.size() > PLAY_MAX_POINTS:
			return UiKit.t("%s's route has %d points; %d is the most.") % [
				POS_NAME[i], r.size(), PLAY_MAX_POINTS]
		for v in r:
			var p: Vector2 = v
			if p.x < 0.02 - SPOT_EPSILON or p.x > 0.98 + SPOT_EPSILON:
				return UiKit.t("%s's route leaves the list.") % POS_NAME[i]
			if p.y < -SPOT_EPSILON or p.y > PLAY_MAX_Y + SPOT_EPSILON:
				return UiKit.t("%s's route runs %.0f%% up the list; %.0f%% is as far as a play reaches.") % [
					POS_NAME[i], p.y * 100.0, PLAY_MAX_Y * 100.0]
	if drawn == 0:
		return UiKit.t("Nobody has been given a route.")
	return ""


## A STRATEGY IS AN OPENING PLAN, NOT A PERMANENT MODIFIER. Pete, 10 Sep 2026:
## it is "more where the team wants the fight to go, but once those strategies
## run their course, the AI tries to make best guess."
##
## So each one is a set of five places to be — a shape the team takes and drives
## from — and it expires. What happens after it expires is the whole difficulty
## curve; see AI_SKILL below.
##
## Zones are in that team's OWN frame: x runs 0 (their left) to 1 (their right),
## y runs 0 (their own rail) to 1 (the enemy rail). Team 1's frame is flipped on
## both axes, so "push the left rail" means each team's own left.
## PETE CUT THIS TO THREE on 10 Sep 2026. It was five, and two of them were the
## same idea twice: a rail push and a "strong side" lean are both *go that way*,
## and offering a player five buttons that are three decisions is how a corner
## screen stops being read at all.
##
## It also settled a name collision. "Strong left" was a FORMATION and a STRATEGY
## at the same time — Pete: *"Strong Left Formation, Let's do Rush Left, Rush
## Right as the strategy."* The formation keeps the name; the strategy is a Rush.
## Cut from five to three on 10 Sep 2026 and then corrected to four the same
## evening. It was five, and two of them were the same idea twice: a rail push
## and a "strong side" lean are both *go that way*, and a corner screen with five
## buttons that are three decisions stops being read.
##
## It also settled a name collision. "Strong left" was a FORMATION and a STRATEGY
## at the same time — Pete: *"Strong Left Formation, Let's do Rush Left, Rush
## Right as the strategy."*
enum Strategy { RUSH_LEFT, RUSH_RIGHT, TURTLE_LEFT, TURTLE_RIGHT }

## Seconds the plan drives the line before the AI is on its own. A plan also
## ends early once a team is down to two men, because the shape is gone.
const PLAN_TIME: float = 18.0
const PLAN_MIN_STANDING: int = 3

## How far back from the center line a side re-forms once its plan expires.
##
## IN UNITS, NOT AS A FRACTION OF THE LIST. It used to be fractions — 0.34 and
## 0.66 of LIST_H — and when the list went from 320 long to 760 those same
## fractions moved the two re-form lines from 102 units apart to 244. So a
## Seasoned side, which is the one that re-forms, started walking two and a half
## times as far to do it, burning the gas that walking cost at the time (GAS_MOVE is 0 now), while a Green
## side stood on its plan zone and kept its wind. **The difficulty curve
## inverted: Green beat Seasoned 61% of the time.**
##
## Same failure as the walking gas, one screen over: a constant expressed
## relative to something that changed size. 51 units is what 0.34 of the old list
## actually meant, so the geometry that was measured is the geometry that stays.
const REFORM_SETBACK: float = 51.0

## A STRATEGY IS A DEPTH PROFILE. Pete, 10 Sep 2026: *"they go straight ahead
## unless the strategy calls for them to move differently. For these premade
## strategies, they should all be going straight except for Turtle."*
##
## So `push` is five numbers — how far up the list each man drives — and that is
## USUALLY THE WHOLE STRATEGY. Where he stands across the line comes from the
## formation, and he goes straight forward from it. A strategy that also carried
## lateral positions would quietly undo the formation the player just picked: a
## Rush drawn over Strong Left would drag the men back into standard lanes and
## the two screens would be fighting each other.
##
## `lane` is optional and only Turtle has it, because only Turtle is supposed to
## move anybody sideways.
##
## The first version of Rush got this wrong — Pete: *"Rush Left and Rush Right is
## where the name side goes forward further/faster than the other side, but
## they're still staying in their lanes going forward."* It had been written as a
## rail push, the whole line sliding across and driving up one edge. That is a
## different manoeuvre and it is not what a rush is. **An echelon, not a slide.**
##
## `push` is 0 at your own rail and 1 at theirs.
const STRATEGIES := {
	Strategy.RUSH_LEFT: {
		"name": "Rush left",
		"blurb": "The left of the line drives; the right comes on behind it. Everyone straight ahead.",
		"push": [0.66, 0.58, 0.48, 0.38, 0.30],
	},
	Strategy.RUSH_RIGHT: {
		"name": "Rush right",
		"blurb": "The right of the line drives; the left comes on behind it. Everyone straight ahead.",
		"push": [0.30, 0.38, 0.48, 0.58, 0.66],
	},
	## TURTLE, as Pete defines it (10 Sep 2026): *"all fighters make their way to
	## a protective shell around the center on one of the sides."*
	##
	## Two things in that sentence, and the first version had neither. It is a
	## SHELL AROUND THE CENTER — he is the core the other four wrap, not one of
	## five men in a clump — and it forms AGAINST A RAIL, not out in the open
	## middle where the old one sat. Pinning yourself to a rail means the shell
	## only has to face one way, which is the entire point of turtling and the
	## reason it is a real thing to do rather than a way to lose slowly.
	##
	## The Center sits deepest with the two Flankers at his shoulders and the two
	## Rails in front, which is the only arrangement where the man being
	## protected is actually behind the men protecting him. The man nearest the
	## rail is the one whose own side it is, so the two mirror by SLOT as well as
	## by position — a right-hand shell is not a left-hand shell with the x
	## values flipped and the same men in the same places.
	Strategy.TURTLE_LEFT: {
		"name": "Turtle left",
		"blurb": "Shell up around the Center against your left rail. Nobody gets round you; nobody scores either.",
		"lane": [0.14, 0.10, 0.15, 0.26, 0.28],
		"push": [0.44, 0.32, 0.24, 0.34, 0.44],
	},
	Strategy.TURTLE_RIGHT: {
		"name": "Turtle right",
		"blurb": "The same shell against your right rail. Pick the side they are not on.",
		"lane": [0.72, 0.74, 0.85, 0.90, 0.86],
		"push": [0.44, 0.34, 0.24, 0.32, 0.44],
	},
}


## Where the plan sends a man, in his own team's frame. `spot_x` is where the
## FORMATION stood him across the line, and it is the answer unless the strategy
## says otherwise — which is the rule Pete stated and the reason this is a
## function rather than a lookup.
static func plan_target(strategy: int, slot: int, spot_x: float) -> Vector2:
	var plan: Dictionary = STRATEGIES[strategy]
	var x: float = float(plan["lane"][slot]) if plan.has("lane") else spot_x
	return Vector2(x, float(plan["push"][slot]))


# ---------------------------------------------------------------- AI skill
## Pete, 10 Sep 2026, on the beginner tier: *"they can just do the strategy and
## try to stick with it, not knowing how to figure out the next steps like a new
## kid going through a motion but then once his taught direction stops, he
## doesn't know what to do."*
##
## That is the difficulty curve, and it is a behavior rather than a stat bonus.
## Nobody's numbers change between tiers — a Green club hits exactly as hard as
## an Elite one. What changes is whether anyone at home is thinking once the
## plan runs out. A difficulty that cheats with multipliers reads as unfair; one
## that is just worse at deciding reads as an opponent.
## GANGING IS NOT A TIER TRAIT, AND THE COMMENT ON GANG_PULL ALWAYS SAID SO:
## *"the pull is near zero at the neutral setting and the strategy dial is what
## turns it on."* It got wired to the AI tier anyway, and on the wide list that
## decided the fight — a side that avoids piles takes five clean fights in its
## own lanes while a side that seeks them walks across the arena and arrives
## gassed. It is 1.0 for everybody now and goes back to the strategy dial.
##
## SIX TIERS — Pete, 10 Sep 2026: **Rust, Experienced, Hardened, Elite, World,
## Legend.** They are how the league describes a CPU club's quality, so they run
## from a side that has been taught one thing to a side that has seen everything.
##
## `wear_read` is the ladder. It is the stability at or below which a side
## recognises a man is ready to be taken, and after the arena widened it is the
## only tier trait that still measures as an advantage — the others (improvising,
## hunting wear, escaping a losing hold) are all MOVEMENT and movement got long.
## They are kept because they are what the tiers MEAN, not because they pay.
##
## Only Rust fails to improvise. That is Pete's original description of the
## bottom rung: *"like a new kid going through a motion, but then once his taught
## direction stops, he doesn't know what to do."*
enum AiSkill { RUST, EXPERIENCED, HARDENED, ELITE, WORLD, LEGEND }

const AI_SKILL := {
	AiSkill.RUST: {
		"name": "Rust",
		"improvises": false, "gang": 1.0, "wear_read": 0.14, "hunts_wear": false,
		"rescues": false, "escapes": false, "pace": 0.95,
	},
	AiSkill.EXPERIENCED: {
		"name": "Experienced",
		"improvises": true, "gang": 1.0, "wear_read": 0.34, "hunts_wear": false,
		"rescues": true, "escapes": false, "pace": 0.98,
	},
	AiSkill.HARDENED: {
		"name": "Hardened",
		"improvises": true, "gang": 1.0, "wear_read": 0.55, "hunts_wear": true,
		"rescues": true, "escapes": true, "pace": 1.0,
	},
	AiSkill.ELITE: {
		"name": "Elite",
		"improvises": true, "gang": 1.0, "wear_read": 0.66, "hunts_wear": true,
		"rescues": true, "escapes": true, "pace": 1.02,
	},
	AiSkill.WORLD: {
		"name": "World",
		"improvises": true, "gang": 1.0, "wear_read": 0.74, "hunts_wear": true,
		"rescues": true, "escapes": true, "pace": 1.04,
	},
	AiSkill.LEGEND: {
		"name": "Legend",
		"improvises": true, "gang": 1.0, "wear_read": 0.82, "hunts_wear": true,
		"rescues": true, "escapes": true, "pace": 1.06,
	},
}

## A third man arriving on an opponent who is already tied up has a freer shot
## than a man inside the grapple, so he finishes off a higher stability than his
## tier's own threshold.
const THIRD_MAN_BONUS: float = 0.15


# ------------------------------------------------------------------ club kit
## Kit and mark colors moved to IconBank on 10 Sep 2026, with the marks
## themselves. They are one decision and they belong in one file; a palette here
## and the shapes it colors over there is how the two drift.

# --------------------------------------------------------------------- 8-bit
const COL_GROUND: Color = Color("2e2a24")
const COL_LIST: Color = Color("6b5c43")
const COL_RAIL: Color = Color("3c3529")
const COL_STEEL: Color = Color("9aa3ad")
const COL_STEEL_DARK: Color = Color("5d666f")
const COL_DOWN: Color = Color("4a4038")
const COL_MARSHAL: Color = Color("f2d13c")
const COL_ROUTE: Color = Color("ffd23c")
const COL_ROUTE_HOSTILE: Color = Color("e05a3c")


static func pos_name(p: int) -> String:
	return UiKit.t(POS_NAME[p])


static func role_of(slot: int) -> int:
	return POS_ROLE[slot]


## Can a man listed at `card_pos` fill `slot` without the out-of-position cost?
static func covers(card_pos: int, slot: int) -> bool:
	return POS_ROLE[card_pos] == POS_ROLE[slot]


static func acts_for(menu: int) -> Array:
	return MENU_ACTS[menu]


static func act_name(a: int) -> String:
	return ACT_NAME[a]


# ------------------------------------------------------ the fight's small print
## Numbers that lived as literals inside `melee_sim.gd` until 27 Sep 2026 —
## moved here, VALUES UNCHANGED, so a sweep can see them and nobody has to read
## the sim to find one. A pair is [min, max] for `randf_range`.
const ACT_FIRST := [0.8, 1.6]        ## first action after the line is set
const ACT_AFTER := [1.6, 2.6]        ## next action after resolving one at contact
const ACT_CLINCH := [2.2, 3.4]       ## between actions inside a clinch
const ACT_BIND := [1.0, 1.8]         ## both men, the moment a clinch binds
const WALK_RECOVER: float = 0.35     ## gas recovered while CLOSING, vs 1.0 in RECOVER
const TD_EMPTY_TANK: float = 0.65    ## takedown chance at an empty tank (x at full)
const BR_EMPTY_TANK: float = 0.60    ## bullrush chance at an empty tank
const ESCAPE_MIN: float = 0.1
const ESCAPE_MAX: float = 0.9
## Targeting weights (score units are list units of distance).
const AI_SAME_LANE: float = 70.0
const AI_LANE_DRIFT: float = 0.85
const AI_WORN_BELOW: float = 0.6
const AI_HUNT_WORN: float = 40.0
const AI_LEASH_PULL: float = 1.6
## Decision thresholds (aggression and gas are 0-1; ratings are overall points).
const AI_RUSH_WOBBLY: float = 0.45
const AI_TIRED_GRAPPLE: float = 0.35
const AI_RUSH_AGG: float = 0.68
const AI_RUSH_WEIGHT: float = 4.0
const AI_TIE_UP_BETTER: int = 8
const AI_HIT_BELOW_AGG: float = 0.45
const AI_ESCAPE_GAS: float = 0.18
const AI_HOLD_BETTER: int = 10
const AI_TD_AGG: float = 0.75
const AI_TD_WOBBLY: float = 0.80
