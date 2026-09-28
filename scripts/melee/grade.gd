class_name Grade
## HOW HARD THE COUNTRY FIGHTS YOU — the difficulty setting, and the one number
## the sim reads because of it.
##
## Pete, 13 Sep 2026: *"There can be difficulty mode, and the enemy tiers are the
## leagues and the team overall numbers. Stats hold that. The difficulties can
## just be slight x1.05 or x.95 to what their overalls mean."*
##
## That is a two-layer model and it is the same one Total War ships: a CAMPAIGN
## layer, which is how good the opposition actually is (our pyramid, and the club
## power bands inside it), and a BATTLE layer, which is what their numbers mean
## when the fight starts. The leagues were already the first layer. This is the
## second, and it is deliberately the smaller of the two — a club that wins the
## National Division on FRIENDLY has still won the National Division.
##
## ONE SIGNED SCALE, DERIVED ONCE, READ THROUGH ONE DOOR.
##
## Retro Bowl does exactly this and it is worth writing down because it is the
## part that is easy to get wrong. Their match object carries a single
## `difficulty` scalar; the five settings resolve into it at kickoff (Easy 7,
## Medium 2, Hard -5, Extreme -5) and thirty-seven places downstream read the
## scalar, never the setting. We do the same: `MeleeSim.opp_scale` is a float,
## the grade resolves into it in `Season.begin_bout`, and the sim reads it
## through `Man.eff_*` and nowhere else. `test_grade.gd` greps for a direct card
## stat read inside the sim and fails on one, because a rule applied at two call
## sites is a rule with a hole in it.
##
## WHY MULTIPLICATIVE RATHER THAN ADDITIVE. Retro Bowl adds its scalar straight
## into the sum (`catching = (skill + attitude) * 0.5 + difficulty * 2`), which
## works because every club in the NFL is roughly as good as every other. Our
## pyramid spans a power band of 30 to 86. A flat +6 would be a fifth of a
## Backyard club and a fourteenth of a National one — it would quietly make the
## bottom of the game far harder than the top. A multiplier scales with the tier,
## which is what "what their overalls mean" actually means.
##
## IT APPLIES TO THE OPPOSITION ONLY, and never to your own men. Every screen in
## this game prints a two-digit overall next to a name, and reading those numbers
## is the entire activity — so a setting that silently changed what YOUR 74 meant
## would make the roster screen a liar. FRIENDLY makes them worse. It does not
## make you better.

## THE FIVE, and the names are ours.
##
## `Regime` already owns LIGHT/NORMAL/HARD, `AiSkill` owns RUST through LEGEND,
## `Mood` owns NORMAL through FINAL and `League.Tier` owns the pyramid — so a
## difficulty called "Hard" would be the fourth thing in this codebase wearing a
## word that already means something else. These come off the sport instead.
enum G { MATCHED, FRIENDLY, SANCTIONED, FULL_STEEL, HARD_LIST, CUSTOM }

const NAME := {
	G.MATCHED: "Matched",
	G.FRIENDLY: "Friendly",
	G.SANCTIONED: "Sanctioned",
	G.FULL_STEEL: "Full Steel",
	G.HARD_LIST: "The Hard List",
	G.CUSTOM: "Custom",
}

## Short enough for a pixel button. `UiKit.fit()` still measures.
const SHORT := {
	G.MATCHED: "MATCHED",
	G.FRIENDLY: "FRIENDLY",
	G.SANCTIONED: "SANCTIONED",
	G.FULL_STEEL: "FULL STEEL",
	G.HARD_LIST: "HARD LIST",
	G.CUSTOM: "CUSTOM",
}

## THE BLURB IS THE HONESTY. Retro Bowl's options screen says outright that
## EXTREME "makes all opponents play with a 5 star rating regardless of what
## their actual rating is" — the game tells you the printed number is not the
## number you are fighting. Ours says the same thing about THE HARD LIST, for the
## same reason: the alternative is XCOM's hidden aim assist, and this is a game
## where the numbers on the screen are the interface.
const BLURB := {
	G.MATCHED: "The country fights you as well as you have been fighting. "
		+ "Win and it hardens; lose and it eases. Starts gentle.",
	G.FRIENDLY: "They turn up, but nobody came to hurt anybody. "
		+ "An extra call from the corner and a longer breather between rounds.",
	G.SANCTIONED: "A properly sanctioned fight. Their numbers mean what they say.",
	G.FULL_STEEL: "They came to end it. One fewer call from the corner, "
		+ "and a shorter breather.",
	G.HARD_LIST: "Full Steel, and every club in the country fights at the top "
		+ "of its division whatever its rating says.",
	G.CUSTOM: "Your own dials. Set each one below.",
}

const ORDER: Array[int] = [G.MATCHED, G.FRIENDLY, G.SANCTIONED, G.FULL_STEEL, G.HARD_LIST, G.CUSTOM]
const DEFAULT: int = G.SANCTIONED

## ------------------------------------------------------------------ the table
## WHAT EACH GRADE IS WORTH — MEASURED, AND THE MEASUREMENT OVERTURNED THE READING.
##
## Pete's instinct was x1.05/x0.95. I argued it up to x1.08/x0.94 on the strength
## of what the games that do this actually spend:
##
##   Total War battle difficulty  AI melee attack x1.10 (Hard), x1.15 (Very Hard)
##                                 AI melee defense x1.20 at Very Hard
##   Civilization VI              AI +4 combat strength at Deity, on a 20-80 scale
##   Retro Bowl                   `catching += difficulty * 2` on a 1-100 stat,
##                                 a 24-POINT SWING between Easy and Hard against
##                                 a base of (skill + attitude) / 2
##
## Then `tools/probe_grade.gd` ran it, and x1.08 measured a **27.5% win rate
## against 44.5% at even**. x1.16 measured **9.5%**. He was closer than I was.
##
## The reason is a property of OUR sim that no amount of reading other games
## would have surfaced. Every one of those knobs moves one stat, or a few
## separately. Ours multiplies four contest stats AT ONCE, and a bout is five men
## over three rounds — so a six-percent edge is not applied once, it is applied
## to every contest in the fight and it compounds. A number that looks timid on
## paper lands as a landslide.
##
## The shipped numbers come off the curve rather than off anybody's nerve:
##
##   x0.96  60.7%      x1.00  46.7%      x1.04  35.3%      x1.08  27.5%
##
## which is +14 and -11 points against even — a real difference, and still the
## same career. `test_grade.gd` asserts the ends stay apart; the probe is how you
## re-tune them.
##
## AND THE STEPS CANNOT BE FINER THAN THIS. At N=150 the probe has x0.97 at 56.7%
## and x0.98 at 58.7% — the wrong way round, well inside the noise. Anything under
## about two points of multiplier is a number the game cannot tell apart from
## chance, which is what sets `STEP` below.
const STEEL: float = 1.04
const EASE: float = 0.96
## THE HARD LIST'S CEILING, capped. A State club rated 50 against its division's
## ceiling of 58 comes out at x1.16, and x1.16 measured a NINE PERCENT win rate —
## a grade that takes a club from winning half its fights to winning one in ten
## is not a setting, it is a different game. The rule still does its work on the
## clubs it was written for; it just stops at a number a career can survive.
const HARD_CAP: float = 1.08

## PAUSES AND THE CORNER — the half of this that is a rule change rather than a
## number, and on the evidence it is the half that will be felt.
##
## Slay the Spire's twenty Ascension levels are twenty NAMED modifiers and only
## six of them are stat multipliers; Retro Bowl's EXTREME shares its scalar with
## Hard and gets all of its extra bite from rules (`stiff_arm = 0`, `jumps = 0`,
## ratings pinned to the ceiling). A pure multiplier is the flattest difficulty
## knob there is. So the grade also moves the two things a corner is for: how
## many times you can stop the fight and think, and how long you get between
## rounds.
##
## The corner delta is four seconds on a twenty-second corner — a fifth of it,
## which is the difference between making two swaps and making one.
const CORNER_DELTA: float = 4.0

## "bills": what the grade does to the dues and the federation's renewals (Pete,
## 28 Sep 2026: difficulty reaches the money too). Buildings are not scaled —
## what a club chooses to own it pays for at full price on every grade.
const TABLE := {
	G.FRIENDLY: { "scale": EASE, "pauses": 1, "corner": CORNER_DELTA, "ceiling": false, "bills": 0.8 },
	G.SANCTIONED: { "scale": 1.0, "pauses": 0, "corner": 0.0, "ceiling": false, "bills": 1.0 },
	G.FULL_STEEL: { "scale": STEEL, "pauses": -1, "corner": -CORNER_DELTA, "ceiling": false, "bills": 1.2 },
	## SHARES FULL STEEL'S SCALAR, exactly as Retro Bowl's Extreme shares Hard's
	## -5. The top grade is not a steeper number, it is a rule: see `ceiling`.
	G.HARD_LIST: { "scale": STEEL, "pauses": -1, "corner": -CORNER_DELTA, "ceiling": true, "bills": 1.2 },
}


## ------------------------------------------------------------------- CUSTOM
## THE ADVANCED SETTINGS — Pete, 28 Sep 2026: *"a custom slider for these
## options with advanced settings."* Every dial the presets turn, each with its
## own range; the values live on the career (`Season.custom_grade`) and are
## handed to every function below, so there is no second copy to drift.
const CUSTOM_DEFAULT := { "scale": 1.0, "pauses": 0, "corner": 0.0, "ceiling": false, "bills": 1.0 }
## [min, max, step] per dial. The strength range is wider than the presets on
## purpose: a player who asks for x1.10 is asking for it.
const DIALS := {
	"scale": [0.90, 1.10, 0.02],
	"pauses": [-2, 2, 1],
	"corner": [-8.0, 8.0, 2.0],
	"bills": [0.5, 1.5, 0.1],
}


static func clamp_dial(key: String, v: float) -> float:
	if key == "ceiling":
		return 1.0 if v > 0.5 else 0.0
	var d: Array = DIALS.get(key, [v, v, 1.0])
	var stepped: float = snappedf(v, float(d[2]))
	return clampf(stepped, float(d[0]), float(d[1]))


static func _row(g: int, custom: Dictionary) -> Dictionary:
	if g == G.CUSTOM:
		var r := CUSTOM_DEFAULT.duplicate()
		for k in custom:
			r[k] = custom[k]
		return r
	return TABLE.get(g, TABLE[G.SANCTIONED])

## THE BASE CALL COUNT. Two, so SANCTIONED gives two and the grade moves it by
## one in either direction — a budget of one is still a decision and a budget of
## three is not yet a crutch.
const PAUSES_BASE: int = 2

## ------------------------------------------------------------------- MATCHED
## THE ONE THAT MOVES, and the reason it is allowed to exist.
##
## I argued against adaptive difficulty on the grounds that a career is a ledger:
## win three in a row, have the league quietly stiffen, and the table stops being
## a record of anything. That argument is wrong, and Retro Bowl is the proof —
## it is a career game with a permanent record and it ships adaptive as the FIRST
## option on the list. The difference from Resident Evil 4's hidden 1-10 rank is
## not the mechanism. It is that Retro Bowl's is a named setting the player chose
## and the options screen describes. Hidden is the problem; adaptive is not.
##
## Their adjustment, from the decompile:
##
##     loss                 suppress_difficulty += 1
##     win                  suppress_difficulty -= 1
##     win by more than 14   suppress_difficulty -= 1   (again)
##     tie                  nothing
##     clamp(-1, 10) normally; clamp(-5, 10) only once you have won a title
##
## Three things worth taking whole. It reads MARGIN, not just the result. It
## starts on the easy side (5 on a -5..10 scale) rather than in the middle. And
## the hardest band is GATED BEHIND A TROPHY — the game will not grade you up to
## its top setting until you have proved you can win one.
## TWO POINTS A STEP, because one is inside the noise — see the note on the
## multipliers above. Five bands, spanning exactly the fixed grades' range, so
## MATCHED can reach FRIENDLY at the bottom and FULL STEEL at the top and cannot
## wander outside the numbers that were actually measured.
const STEP: float = 0.02
const STEP_MIN: int = -2        ## x0.96, level with FRIENDLY
const STEP_MAX: int = 2         ## x1.04, level with FULL STEEL
## Until the cabinet has something in it, MATCHED will not go past here.
const STEP_MAX_UNPROVEN: int = 1
## Starts on the easy side of even, like theirs.
const STEP_START: int = -1


static func matched_scale(step: int) -> float:
	return 1.0 + float(clampi(step, STEP_MIN, STEP_MAX)) * STEP


## A bout's worth of movement. `won`/`lost` are rounds, so a 2-0 is our blowout —
## the same shape as their fourteen-point win, read off the thing our game
## actually scores.
static func matched_next(step: int, rounds_for: int, rounds_against: int,
		has_honor: bool) -> int:
	var s := step
	if rounds_for > rounds_against:
		s += 1
		if rounds_against == 0:
			s += 1
	elif rounds_for < rounds_against:
		s -= 1
	var top := STEP_MAX if has_honor else STEP_MAX_UNPROVEN
	return clampi(s, STEP_MIN, top)


## --------------------------------------------------------------- the one door
## WHAT THE SIM ACTUALLY GETS. Everything above resolves here, and this is the
## only function `Season` calls.
##
## `power` is the opposition's club power and `tier` its rung of the pyramid,
## both needed for the ceiling rule and ignored by every other grade.
static func scale_for(g: int, step: int, power: int, tier: int,
		custom: Dictionary = {}) -> float:
	if g == G.MATCHED:
		return matched_scale(step)
	var row: Dictionary = _row(g, custom)
	if not bool(row["ceiling"]):
		return float(row["scale"])
	## NEVER BELOW FULL STEEL. The ceiling rule on its own floors at 1.0 for a
	## club already at the top of its division — and a Worlds guest rated 90
	## against a National ceiling of 86 is above it — so THE HARD LIST was coming
	## out SOFTER than FULL STEEL against exactly the clubs it exists for. It is
	## Full Steel PLUS a rule, which is what its blurb promises, so it takes
	## whichever of the two is worse for you.
	return clampf(ceiling_scale(power, tier), float(row["scale"]),
		maxf(HARD_CAP, float(row["scale"])))


## THE HARD LIST, and it is Retro Bowl's Extreme translated rather than invented:
## `if (op_difficulty == 4) { team_defense = 15; rat_offense = 10; }` pins the
## opposition's ratings to the top of the scale whatever the club actually is.
##
## Ours pins to the top of ITS OWN DIVISION rather than to the top of the game,
## because the pyramid is the first difficulty layer and flattening it would
## delete it: a Backyard club fighting National-grade opposition is not a
## difficulty setting, it is a different game. So a Backyard side fights at 46
## and a National side at 86, and a club already at its division's ceiling fights
## at exactly its own rating — which is the honest answer, not a bug.
##
## It floors at 1.0. The grade is never allowed to make an opponent WEAKER than
## he is; that would be FRIENDLY wearing the hardest name on the list.
static func ceiling_scale(power: int, tier: int) -> float:
	## A WORLDS GUEST HAS NO RUNG. `world.clubs[id]["tier"]` is -1 for the sides
	## the federation flies in, and clamping that to 0 would hand them the
	## BACKYARD ceiling of 46 — which, against a guest rated in the eighties,
	## floors at 1.0 and quietly exempts the best clubs in the game from the
	## hardest grade. They take the top of the pyramid instead.
	var t := League.TIERS.size() - 1 if tier < 0 else clampi(tier, 0, League.TIERS.size() - 1)
	var top: float = float(League.TIERS[t]["power"][1])
	return maxf(1.0, top / maxf(1.0, float(power)))


## How many times you can stop the fight, at this grade.
static func pauses_for(g: int, step: int, bonus: int, custom: Dictionary = {}) -> int:
	var d := 0
	if g == G.MATCHED:
		## MATCHED earns its call count off the same number everything else reads,
		## so the setting cannot drift from the difficulty it is describing.
		var sc := matched_scale(step)
		d = -1 if sc > 1.02 else (1 if sc < 0.98 else 0)
	else:
		d = int(_row(g, custom)["pauses"])
	return maxi(0, PAUSES_BASE + d + bonus)


## How long the corner lasts, at this grade.
static func corner_time(g: int, custom: Dictionary = {}) -> float:
	if g == G.MATCHED:
		return Tuning.CORNER_TIME
	return Tuning.CORNER_TIME + float(_row(g, custom)["corner"])


## WHAT THE GRADE DOES TO THE DUES AND RENEWALS. MATCHED follows its own ladder
## across the same span as the presets: x0.8 at its easiest, x1.2 at its hardest.
static func bills_for(g: int, step: int, custom: Dictionary = {}) -> float:
	if g == G.MATCHED:
		return 1.0 + (matched_scale(step) - 1.0) * 5.0
	return float(_row(g, custom).get("bills", 1.0))


static func name_of(g: int) -> String:
	return String(NAME.get(g, NAME[DEFAULT]))


static func short_of(g: int) -> String:
	return String(SHORT.get(g, SHORT[DEFAULT]))


static func blurb_of(g: int) -> String:
	return String(BLURB.get(g, BLURB[DEFAULT]))
