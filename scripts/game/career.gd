class_name Career
extends RefCounted
## AGE, POTENTIAL, XP AND RETIREMENT — a fighter's whole arc, in one file.
##
## Taken from Retro Bowl at Pete's instruction (10 Sep 2026) and then bent to the
## sport, because the NFL curve is not the buhurt curve and pretending otherwise
## would have produced the most generic system in the game.
##
## THE ONE IDEA WORTH HAVING: **there is no single peak age.** A gridiron player
## has one athletic prime and falls off it. A buhurt fighter has four, and they
## are years apart:
##
##   Gas        peaks at 24   the tank goes first and goes hardest
##   Strength   peaks at 28   roughly where a heavy athlete tops out
##   Base       peaks at 32   not being put down is mostly knowing how
##   Skill      peaks at 35   technique keeps compounding for a long time
##   Aggression never peaks   it is temperament, not an attribute
##
## So an old fighter is not a worse fighter, he is a DIFFERENT fighter: hard to
## put down, technically better than anyone on the field, and empty by the third
## round. Anyone who has stood on a list knows that man. The curve puts him in
## the game for free, and it means a club's decision about a 36-year-old is a
## real one rather than a sell-by date.
##
## It also lands on the roles this game already has. Rails need strength and
## base; Centers need skill; everybody needs gas. A club that ages out of the
## Flanker slots and into the Rails is a thing that will happen on its own.

## Peaks, by stat. Aggression is deliberately absent — see above.
const PEAK_STRENGTH: int = 28
const PEAK_BASE: int = 32
const PEAK_SKILL: int = 35
const PEAK_GAS: int = 24

## Where a generated fighter starts. A club fields men in their twenties and
## thirties; the reserve is where the twenty-year-olds are.
const AGE_MIN: int = 19
const AGE_MAX: int = 39


## HIS OWN PEAK, NOT THE SPORT'S. LATE_PEAK and BURNS_OUT move where the decline
## starts for one man, and every question about his age has to go through here or
## a Late Peak would stop declining in one calculation and keep declining in
## another — `decline_for` and `_raise_one` both read it.
static func peak_for(f: FighterCard, stat: int) -> int:
	return peak_of(stat) + int(FighterTrait.mod(f.trait_id, "peak", 0.0))


static func peak_of(stat: int) -> int:
	match stat:
		Stat.STRENGTH: return PEAK_STRENGTH
		Stat.BASE: return PEAK_BASE
		Stat.SKILL: return PEAK_SKILL
		Stat.GAS: return PEAK_GAS
		_: return 99          ## aggression: never


enum Stat { STRENGTH, BASE, SKILL, GAS, AGGRESSION }

const STATS: Array[int] = [Stat.STRENGTH, Stat.BASE, Stat.SKILL, Stat.GAS]


static func read_stat(f: FighterCard, stat: int) -> int:
	match stat:
		Stat.STRENGTH: return f.strength
		Stat.BASE: return f.base
		Stat.SKILL: return f.skill
		Stat.GAS: return f.gas
		_: return f.aggression


static func write_stat(f: FighterCard, stat: int, v: int) -> void:
	var x := clampi(v, 1, 99)
	match stat:
		Stat.STRENGTH: f.strength = x
		Stat.BASE: f.base = x
		Stat.SKILL: f.skill = x
		Stat.GAS: f.gas = x
		_: f.aggression = x


static func stat_name(stat: int) -> String:
	match stat:
		Stat.STRENGTH: return "Strength"
		Stat.BASE: return "Base"
		Stat.SKILL: return "Skill"
		Stat.GAS: return "Gas"
		_: return "Aggression"


# -------------------------------------------------------------------- decline
## HOW FAST THE FALL IS. `DECLINE_RATE x (age - peak)`, rounded, so the loss
## accelerates instead of arriving as a cliff:
##
##   one year past peak    0 points     nothing yet
##   two years past        1
##   five years past       2
##   ten years past        3
##
## Accelerating matters more than the rate does. A flat "lose one a year" makes
## every veteran identical and makes the decision about them arithmetic; a curve
## that bites slowly and then faster means a 34-year-old is a bargain and a
## 40-year-old is a problem, and the club has to work out which one it is
## holding. The rate itself is a first pass and wants a played season on it.
const DECLINE_RATE: float = 0.30


static func decline_for(age: int, stat: int) -> int:
	var over := age - peak_of(stat)
	return 0 if over <= 0 else int(round(DECLINE_RATE * float(over)))


## The same figure for a particular man, which is the one the winter uses.
static func decline_for_man(f: FighterCard, stat: int) -> int:
	var over := f.age - peak_for(f, stat)
	return 0 if over <= 0 else int(round(DECLINE_RATE * float(over)))


# ------------------------------------------------------------------ potential
## THE SECOND VISIBLE NUMBER. Retro Bowl shows a potential alongside the rating
## and it is the single most-read thing on their roster screen, because it turns
## every signing from "how good is he" into "how good is he GOING to be" — which
## is a question worth a decision, and the first one was not.
##
## Here it is a ceiling on `overall()`, not on any single stat. A fighter can
## rearrange himself under it however his training goes; what he cannot do is
## exceed it. Past his peaks he will fall away from it and never get back, which
## is what makes potential something you spend a career chasing rather than a
## number that resolves and then sits there.
##
## HOW WIDE THE GAP STARTS. A twenty-year-old is mostly unwritten; a
## thirty-five-year-old is what he is. The gap is drawn against how far the man
## is from the LAST peak to arrive (skill, at 35), so it closes on its own as he
## ages and nobody has to write a second age table.
const POTENTIAL_GAP_MAX: int = 18
const POTENTIAL_CEILING: int = 99


## The room a fighter of this age could still have in front of him, at most.
static func potential_room(age: int) -> int:
	var left := float(maxi(0, PEAK_SKILL - age)) / float(PEAK_SKILL - AGE_MIN)
	return int(round(float(POTENTIAL_GAP_MAX) * left))


## Roll a potential for a freshly generated fighter. Never below his rating —
## a potential under the current overall would say a man is already finished,
## which is what DECLINE is for and would be a second system saying it.
static func roll_potential(rng: RandomNumberGenerator, f: FighterCard) -> int:
	var room := potential_room(f.age)
	return clampi(f.overall() + (rng.randi() % (room + 1)), 1, POTENTIAL_CEILING)


## ONE SCARCE WAY TO RAISE IT, and this is it: the club names ONE fighter its
## prospect each winter, and that man gains this much. Not buyable, not
## repeatable within a year, and gated behind a Training ground the club had to
## build — so raising a ceiling costs a season of attention rather than credits.
##
## A second way was considered and cut. Anything you can buy in bulk stops being
## a ceiling and becomes a price, and then potential is just rating with extra
## steps.
const PROSPECT_GAIN: int = 3
const PROSPECT_GROUND: int = 3       ## Training ground level required


# ------------------------------------------------------------------------ XP
## EARNED BY DOING, NOT BY BEING PICKED. Retro Bowl pays XP for production and
## it is why their bench matters: a man who does nothing improves at nothing, so
## minutes are a resource you allocate. Ours reads the same two numbers the
## post-fight report already keeps — downs caused, and rounds finished on your
## feet — so nothing new has to be measured and nothing can drift out of step
## with what the player was shown after the bout.
##
## A man who is not in the eight earns nothing. That is the whole reserve
## problem stated as a rule, and it is the pressure that makes a squad a squad.
const XP_BOUT: int = 2
const XP_PER_DOWN: int = 3
const XP_PER_ROUND_STANDING: int = 1
## ----------------------------------------------------------------- levelling
## A MAN LEVELS WHENEVER HE HAS EARNED IT, not once a year in the summer.
##
## Pete, 13 Sep 2026: *"Winter shouldn't be the only time you can gain levels. Go
## see how Retro Bowl does it."* So we did, and their model is one line:
##
##     s_has_xp_gain:  round(xp + xp_gain) < xp_level * 100  ->  no level
##
## A player carries `xp`, a pending `xp_gain` from the last game, and an
## `xp_level`. The bar to the next level is **his current level times a hundred**,
## so it gets harder exactly as fast as he gets better, and it is checked whenever
## the card is looked at rather than at a season boundary. On crossing it:
##
##     xp = 1;  xp_level += 1;  attitude = clamp(attitude + 10, 1, 100)
##
## Three things worth taking. The threshold is LINEAR IN THE LEVEL, which is a
## decelerating curve without a table to maintain. The remainder is NOT carried
## over — he starts the next level near zero, so a huge afternoon cannot buy two
## levels at once. And **levelling up lifts his mood**, which we did not have and
## which is the cheapest good idea in their whole progression.
##
## THE SHAPE IS THEIRS. THE CAP IS OURS, AND WITHOUT IT THE PORT IS BROKEN.
##
## `level * 100` never stops rising, and that works for Retro Bowl because their
## XP income grows with production — a better player gains more yards and scores
## more, so he earns faster as the bar gets higher. Ours does not: `xp_for` pays
## the same 2 + 3 a down + 1 a round standing in season ten as in season one.
##
## Ported literally it walls a career. `tools/probe_levels.gd` measured it:
##
##   the winter it replaces     47 points over 8 seasons, overall 50 -> 61
##   level * 40, uncapped        6 levels,                overall 50 -> 51
##   level * 10, uncapped       14 levels,                overall 50 -> 53
##   min(level, 3) * 8          48 levels,                overall 50 -> 61
##
## So the bar rises and then STOPS, which is exactly what `XP_PER_POINT` already
## did — [8, 12, 18, 26, 40] and flat at 40 forever. The cap is not a fudge to
## hit a number; it is the same admission that constant income needs a constant
## bar, made twice in the same file by two different people.
##
## 8, then 16, then 24 and 24 and 24. Measured against the winter it replaces,
## because the rework was meant to move WHEN a man levels and not how far he
## climbs, and a rework that quietly halved a career would have been a balance
## change wearing a UX change's clothes.
const LEVEL_XP: int = 8
## RAISED FROM 3 TO 4 ON 15 Sep 2026. Pete: *"Let's lean more toward theirs."*
##
## Theirs does not cap at all — `xp_level * 100`, forever — and ours cannot go
## that far: `probe_levels` measured an uncapped bar at 14 levels and **+3
## overall across eight seasons** against the winter's 47 and +11. The cap is the
## admission that a rising bar needs a rising income.
##
## What changed is the income. `xp_for` reads the man's rating now, so a fighter
## who is getting better fills the bar faster — which buys exactly one more rung
## of bar before the wall. 8, 16, 24, 32, and flat at 32.
const LEVEL_BAR_CAP: int = 4
## WHAT A LEVEL DOES TO HIS MOOD, and theirs does not transfer at face value.
##
## Retro Bowl adds 10 to a 1-100 attitude, which looks like a tenth of our morale
## — but their levels are rare and our capped bar makes them frequent, six a
## season for a man who plays. At 0.10 a level the probe had a fighter at 0.96
## morale by his fourth season, which is not a happy man, it is a broken meter:
## nothing else in the club could move him after that.
##
## A twentieth instead. Still the best thing that happens to a man all month, and
## still visible against the regime and the room, without becoming the only input
## that matters.
const LEVEL_MORALE: float = 0.03
## WHAT IT COSTS TO BUY ONE — their meeting, *"extra reps on the training
## field"*, priced at `xp_level * 4`.
##
## Theirs reads the level because theirs IS the bar. Ours reads the BAR, because
## a capped bar means the level keeps counting up long after the difficulty stops
## — a man is level 25 in his fourth season here and would have cost 50 credits
## against a facility that costs 11. Cost tracks what he is actually being given.
const LEVEL_COST_DIV: int = 4

## WHAT A STAT POINT USED TO COST AT THE WINTER. Kept because `train_only` and
## the Training ground still hand out points directly — what is gone is XP being
## SPENDABLE only in the summer, which is what made a man's earned afternoons sit
## in a drawer for nine months.
const XP_PER_POINT: Array[int] = [8, 12, 18, 26, 40]


## What the next point costs a man who has already taken `taken` of them this
## winter. Past the table it stays at the last figure rather than going free,
## which is the kind of off-by-one that turns a soft cap into no cap.
static func xp_cost(taken: int) -> int:
	return XP_PER_POINT[mini(taken, XP_PER_POINT.size() - 1)]


# ---------------------------------------------------------------- retirement
## WHEN A MAN IS DONE. Rising with age, and steeper for a fighter who has already
## fallen a long way from what he was — the sport does not usually retire people
## at their best, it retires them once a season stops being fun.
##
## `RETIRE_FROM` is late on purpose. Buhurt is full of men in their late
## thirties; a game that pensioned them off at 32 would be describing a different
## sport. The hard stop exists only so a save cannot carry a 60-year-old.
const RETIRE_FROM: int = 33
const RETIRE_HARD: int = 46
const RETIRE_PER_YEAR: float = 0.055
const RETIRE_PER_FADED_POINT: float = 0.012


## How likely this man is to hang it up this winter, 0 to 1.
##
## `faded` is how far under his own potential he has sunk — a fighter who is
## eight points off his ceiling has had his last few seasons taken off him and
## knows it. Using potential rather than a remembered career-best keeps this
## readable from the card alone and means a save carries no extra history.
## MORALE IS THE THIRD TERM, and it is the second place morale reaches something
## real (the first is whether a man out of contract waits). A fighter in his late
## thirties at a club that is no fun retires a year or two early; the same man
## somewhere he is enjoying himself keeps going. That is the most ordinary true
## thing about the end of a career in this sport, and it costs one line.
##
## Centerd on 0.7, where a club starts, so a club that never thinks about morale
## is neither rewarded nor punished for it.
const RETIRE_PER_MOOD: float = 0.22


static func retire_chance(f: FighterCard, morale: float = 0.7) -> float:
	if f.age >= RETIRE_HARD:
		return 1.0
	if f.age < RETIRE_FROM:
		return 0.0
	var faded := maxi(0, f.potential - f.overall())
	var mood := 0.7 - clampf(morale, 0.0, 1.0)
	return clampf(float(f.age - RETIRE_FROM + 1) * RETIRE_PER_YEAR
		+ float(faded) * RETIRE_PER_FADED_POINT
		+ mood * RETIRE_PER_MOOD, 0.0, 1.0)


# --------------------------------------------------------------- the winter
## ONE MAN'S WINTER, in the order it has to happen in.
##
## Decline first, then improvement. The other way round lets a fighter buy back
## the point he is about to lose, which reads to a player as training doing
## nothing — he spent the XP, the number did not move, and no screen can explain
## why. This way a veteran's XP visibly SLOWS the fall instead of pretending to
## reverse it, which is both truer and easier to say out loud.
##
## `coached` is the captain rule that was already here: a role no captain covers
## does not train. It gates the improvement half only. Nobody needs a captain to
## get older.
##
## Returns what happened, so the screen can tell the player instead of moving
## numbers behind his back.
## A SECOND HELPING OF THE GROUND'S POINTS, after the winter has run.
##
## The share is worked out before anybody has aged, so points offered to a man
## who is already at his ceiling — or who was one point under it and took one —
## used to evaporate. `winter` reports how many it actually spent; the season
## counts the difference and brings it back here for whoever still has room.
## IS AGE ABOUT TO TAKE SOMETHING OFF HIM? Asked before the winter runs, so the
## season can offer training to a man who is at his ceiling today and will not be
## by the time the points are spent. Reads the same `decline_for` the winter
## does, at the age he is about to become — one source of truth for the fall.
static func will_decline(f: FighterCard) -> bool:
	for stat in STATS:
		if decline_for(f.age + 1, stat) > 0:
			return true
	return false


## ------------------------------------------------------------ the level bar
## What he needs banked for his next one. Linear in the level, as theirs is.
static func next_level_at(f: FighterCard) -> int:
	## The level term and the age term, in that order and in one place, because
	## this is the number every door charges and every bar measures against.
	return maxi(1, int(round(
		float(mini(maxi(1, f.level), LEVEL_BAR_CAP) * LEVEL_XP) * learn_rate(f))))


## ------------------------------------------------- and at the ceiling, money
## A MAN AT HIS CEILING TURNS A LEVEL INTO CREDITS.
##
## Straight from their build, and it is the cheapest good idea left in it:
## *"Maxed players convert further level-ups into credits."* Ours refused —
## `msg_MeetingLevelUpNotNeeded` in their nouns, *"%s has nothing left to learn"*
## in ours — and a refusal is a dead end on the one man you spent a career
## building. Every point of XP a thirty-four-year-old at his ceiling earns for
## the rest of his career was being thrown away.
##
## PRICED AT WHAT THE LEVEL WOULD HAVE COST, which makes the two doors agree
## about what a level IS: the club either pays that to push him or is paid it
## because he cannot be pushed. A different figure would be a second opinion.
##
## IT IS NOT A MONEY PRINTER, and the arithmetic says why rather than a clamp.
## He has to earn the whole bar to convert once, the bar rises with his level,
## and `learn_rate` makes it rise faster as he ages — so the man who converts is
## an old veteran filling a 32-point bar for a handful of credits, which is
## exactly the trickle it should be.
static func cashes_in(f: FighterCard) -> bool:
	return at_ceiling(f) and f.xp >= next_level_at(f)


## Take the bar and hand back the credits. Returns what it paid, or 0.
static func cash_in(f: FighterCard) -> int:
	if not cashes_in(f):
		return 0
	var paid := level_cost(f)
	f.xp -= next_level_at(f)
	f.level += 1
	return paid


## AT HIS CEILING HE STOPS. Retro Bowl says it in a sentence —
## `msg_MeetingLevelUpNotNeeded: "$playername has reached his potential."` — and
## it is the whole reason potential is the second number on the card.
static func at_ceiling(f: FighterCard) -> bool:
	return f.overall() >= f.potential


static func can_level(f: FighterCard) -> bool:
	return f.xp >= next_level_at(f) and not at_ceiling(f)


# ----------------------------------------------------------- the old dog
## HOW FAST HE LEVELS, BY AGE — Pete, 13 Sep 2026: *"I was talking about how fast
## he levels as in from Level 5 to level 6, leave the ability to gain all stats
## still. He's just slower at leveling his main level is all."*
##
## The first version of this read him wrong and priced each STAT by its own peak,
## which walled a thirty-year-old out of his own gas and turned one idea into
## four. The idea is simpler and better than what I built from it: **a man's
## level bar gets longer as he ages, and what he does with a level never
## changes.** Young people learn faster. Old dogs learn the same tricks, it just
## takes them awhile.
##
## That it is the BAR and not the stat list is what makes it a hook rather than a
## restriction. A veteran is not shut out of anything — he is behind a younger
## man in the only currency the career layer has, and the club decides whether
## the wait is worth what he already is.
##
## EIGHT PERCENT A YEAR, EITHER SIDE OF TWENTY-SIX:
##
##   19    x0.70   the floor — a kid climbs about a third faster
##   26    x1.00   par
##   32    x1.48
##   38    x1.96
##   39+   x2.00   the cap — twice as long as par, and no worse
##
## Twenty-six is par because it sits between the tank going (24) and strength
## topping out (28) — the last age at which a fighter is still improving at
## everything. The floor exists because a bar that keeps shrinking makes the
## nineteen-year-old the only signing worth making; the cap exists because past
## about forty the honest statement is "this is as slow as it gets".
##
## THIS STACKS WITH THE `xp` TRAIT MOD rather than duplicating it. Sponge and
## Plateaued scale what a man EARNS; this scales what a level COSTS. A young
## Sponge climbs fast twice over, which is what a rare trait on a rare age
## should do.
const LEARN_PAR: int = 26
const LEARN_STEP: float = 0.08
const LEARN_MIN: float = 0.70
const LEARN_MAX: float = 2.00


## The multiplier on his level bar. 1.0 at twenty-six.
static func learn_rate(f: FighterCard) -> float:
	return clampf(1.0 + LEARN_STEP * float(f.age - LEARN_PAR),
		LEARN_MIN, LEARN_MAX)


## The rate a man at par pays, as a figure rather than a literal 1.0 — the test
## asserts against this, so a change to the shape of the curve that accidentally
## moved par would be caught rather than agreed with.
static func learn_rate_par() -> float:
	var at_par := FighterCard.new()
	at_par.age = LEARN_PAR
	return learn_rate(at_par)


## IN A WORD, for the screen. Nothing at all near par — a label on every fighter
## is a label that says nothing about any of them.
static func learn_word(f: FighterCard) -> String:
	var r := learn_rate(f)
	if r <= 0.85:
		return "picks it up fast"
	if r >= 1.30:
		return "slow to learn"
	return ""


## WHICH STATS HAVE ROOM LEFT IN THEM. The 99 wall and nothing else: *"leave the
## ability to gain all stats still."* A level is a level whatever his age, and
## where it goes is the player's.
static func raisable(f: FighterCard) -> Array[int]:
	var out: Array[int] = []
	for stat in STATS:
		if read_stat(f, stat) < 99:
			out.append(stat)
	return out


## SPEND A LEVEL ON A STAT HE CHOSE — Pete, 13 Sep 2026: *"Players should be able
## to upgrade fighters stats anytime the +1 level/level up is available."*
##
## This is the version that replaced an automatic one. `level_up` used to call
## `_raise_one`, which picks the LOWEST stat under its peak — a sensible default
## and a terrible decision to take away from somebody: it means a club can never
## build a specialist, because every level a man earns goes into whatever he is
## worst at. The rule is still there and still right for the winter's training
## ground, which is the CLUB spending its own money on him. A level is his.
static func level_into(f: FighterCard, stat: int) -> Dictionary:
	if at_ceiling(f):
		return {"levelled": false, "reason": "ceiling"}
	if not raisable(f).has(stat):
		return {"levelled": false, "reason": "maxed"}
	if f.xp < next_level_at(f):
		return {"levelled": false, "reason": "not earned",
			"short": next_level_at(f) - f.xp}
	var before := f.overall()
	write_stat(f, stat, read_stat(f, stat) + 1)
	return _took(f, before, stat)


## TAKE ONE LEVEL, THE CLUB'S WAY. Kept for anything that has no player at the
## keyboard — a simulated club's men, and the drain of a save made before levels
## existed. It goes through `_raise_one` so the automatic path and the winter
## cannot disagree about which stat a point lands on.
static func level_up(f: FighterCard) -> Dictionary:
	var report := {"lost": 0, "gained": 0, "spent": 0, "ground": 0, "held": 0}
	if at_ceiling(f):
		return {"levelled": false, "reason": "ceiling"}
	var before := f.overall()
	if not _raise_one(f, {}, report):
		return {"levelled": false, "reason": "nothing to grow"}
	## THE REMAINDER IS KEPT. Theirs sets `xp = 1` on crossing, and at their income
	## that rounding is invisible; at ours an event is worth eleven against a bar
	## of twenty-four, so discarding it would bin something like a fifth of
	## everything every man earns. `drain` takes one level a bout instead, which is
	## the same intent — a monstrous afternoon must not buy two — stated in the
	## place where it costs nothing.
	return _took(f, before, -1)


## The bookkeeping both doors share: charge the bar, count the level, lift his
## mood. One body, because a level taken by the player and a level taken by the
## club have to cost and pay exactly the same.
static func _took(f: FighterCard, before: int, stat: int) -> Dictionary:
	f.xp -= next_level_at(f)
	f.level += 1
	## AND IT MAKES HIM HAPPIER, which is theirs and which we did not have. A man
	## who has just been told he is better than he was is a man who wants to play.
	f.morale_shift(LEVEL_MORALE)
	return {"levelled": true, "level": f.level, "was": before, "now": f.overall(),
		"name": f.display_name, "stat": stat}


## HOW MANY LEVELS ARE WAITING TO BE SPENT. The after-action report reads this;
## it no longer spends them.
## IS THERE A LEVEL HE CAN ACTUALLY PLACE?
##
## Not the same question as `levels_waiting`, and the difference is a man the
## game will produce on its own: a thirty-eight-year-old under his potential is
## still earning levels, and he is past the peak of all four stats, so there is
## nowhere to put one. The screen said "A LEVEL IS WAITING" and drew four dead
## buttons — a promise made by one function that a second function refuses, which
## is the shape of every bug this file has had.
##
## So the screen asks THIS, and the panel has a third thing to say.
##
## A man at 99 in all four has nowhere to put one — the only wall left.
static func can_place(f: FighterCard) -> bool:
	return can_level(f) and not raisable(f).is_empty()


static func levels_waiting(f: FighterCard) -> int:
	return 1 if can_place(f) else 0


## ONE LEVEL AN AFTERNOON, TAKEN AUTOMATICALLY. No longer called after a bout:
## a level is the player's to spend now, and the report says one is waiting. Kept
## for the clubs the player does not manage and for a save that predates levels.
static func drain(f: FighterCard) -> Array:
	var out: Array = []
	if not can_level(f):
		return out
	var r := level_up(f)
	if bool(r.get("levelled", false)):
		out.append(r)
	return out


## Everything he has banked, taken at once — for a save loaded from a build that
## had no levels, where a man may be owed several.
static func drain_all(f: FighterCard) -> Array:
	var out: Array = []
	var guard := 40
	while can_level(f) and guard > 0:
		var r := level_up(f)
		if not bool(r.get("levelled", false)):
			break
		out.append(r)
		guard -= 1
	return out


## BUYING ONE, which is their meeting — *"go through some extra reps on the
## training field"*. Retro Bowl's `s_get_meeting_cost_levelup` is `xp_level * 4`
## credits, and the screenshot Pete sent on 14 Sep 2026 confirms it to the digit:
## XP LEVEL 5, Level Up, 20 CC.
##
## IT IS PRICED OFF THE LEVEL, NOT OFF THE BAR, and that is the correction.
##
## This read `next_level_at(f) / 4` — the BAR divided — and carried the sentence
## *"rising with the level for the same reason the XP bar does."* The bar does
## not rise. It deliberately stops: `min(level, 3) * 8` gives 8, 16, 24, 24, 24
## forever, because our XP income is flat where theirs grows with production, and
## an unbounded bar walls a career at three points of overall. That cap is right
## and it is explained at length in the register — and the PRICE inherited it by
## accident:
##
##     level   1   2   3   4   5   6   8  10  12  15
##     ours    2   4   6   6   6   6   6   6   6   6
##     theirs  4   8  12  16  20  24  32  40  48  60
##
## Flat at six from level three on. A club with credits buys every level for
## every man forever, and the one purchase that should get harder as a fighter
## gets good was the one that never did. **A cap that exists for one reason does
## not belong to every number that happens to read through it.**
##
## `LEVEL_COST_PER` is two rather than their four because our credit economy is
## smaller — a Backyard club nets eight to nineteen a season where theirs earns
## in tens — and the register is explicit that their early-game drought was the
## one thing deliberately not copied.
##
## THE AGE TERM IS OURS AND IT STAYS. A man slow to learn costs more to push,
## which is the same `learn_rate` the bar itself reads, and it is a better idea
## than a flat ladder: 10 CC for a 26-year-old at level five, 20 for a
## thirty-eight-year-old at the same level.
## 3 RATHER THAN 2, which is three quarters of theirs rather than half.
##
## Theirs is `xp_level * 4`. Ours was halved because our credit economy is
## smaller and their early-game drought is priced against a 99-cent button. Both
## of those are still true and neither argues for half specifically — and the bar
## is longer now, so a level is a rarer and larger thing than it was when the
## price was set. A rarer purchase that stayed cheap would be the one thing on
## the meeting card nobody has to think about.
const LEVEL_COST_PER: int = 3


static func level_cost(f: FighterCard) -> int:
	return maxi(1, int(round(float(maxi(1, f.level)) * float(LEVEL_COST_PER)
		* learn_rate(f))))


static func train_only(f: FighterCard, points: int) -> int:
	var report := {"lost": 0, "gained": 0, "spent": 0, "ground": 0, "held": 0}
	var g := 0
	while g < points and f.overall() < f.potential:
		if not _raise_one(f, {}, report):
			break
		g += 1
	return g


static func winter(f: FighterCard, coached: bool, ground_points: int) -> Dictionary:
	var report := {"lost": 0, "gained": 0, "spent": 0, "ground": 0, "held": 0}
	f.age += 1

	## THE FALL. Every stat is measured against its OWN peak, so the same winter
	## takes gas off a 26-year-old and skill off nobody. The losses are kept per
	## stat because the climb below is allowed to push back against them.
	var fell := {}
	for stat in STATS:
		var want := decline_for(f.age, stat)
		if want <= 0:
			continue
		var before := read_stat(f, stat)
		write_stat(f, stat, before - want)
		var took := before - read_stat(f, stat)
		fell[stat] = took
		report["lost"] = int(report["lost"]) + took

	if not coached:
		return report

	## THE CLIMB, AND IT IS ONE SOURCE NOW. The fighter's own XP used to be spent
	## here, in the summer, at a rising cost — which meant a man who had a
	## storming November found out about it in June. Levelling moved to the moment
	## it is earned (see `drain`, called after every bout), so what the winter does
	## is age him, take the decline off him, and hand out the TRAINING GROUND's
	## allocation, which is the club's investment rather than his own effort.
	##
	## `fell` still reaches `_raise_one`, so a ground point can hold back a loss
	## the winter just took — that was always the interesting half of this.
	var g := 0
	while g < ground_points and f.overall() < f.potential:
		if not _raise_one(f, fell, report):
			break
		g += 1
	report["ground"] = g
	report["gained"] = int(report["gained"]) + g
	return report


## WHERE A POINT OF TRAINING GOES, and this is the function that decides whether
## the four peak ages are a design or a decoration.
##
## The first version simply raised the man's LOWEST stat, which is the rule the
## winter used before any of this existed. tools/probe_career.gd played a career
## out and the result was damning: by 32 the fighter read **68 / 68 / 68 / 67**.
## Training had sanded every fighter in the game into the same shape, the four
## peaks canceled out, and "an old fighter is a different fighter, not a worse
## one" — the entire claim the career layer exists to make — was false in the
## only place it could be checked.
##
## The fix is a rule, not a weighting: **you cannot train a stat you are past the
## peak of.** A 30-year-old's work goes into base and skill because gas and
## strength are behind him, and that is the veteran the design promised, arrived
## at honestly instead of by a fudge factor. Under the peak, the lowest stat
## still wins, so a club still trains its weaknesses and the winter is still
## reproducible from a save without rolling anything.
##
## AND PAST EVERY PEAK, TRAINING HOLDS THE LINE. A man past all four has nothing
## left to grow, and wasting his XP would make a veteran's production worthless
## at exactly the age a club is deciding whether to keep him. Instead a point
## buys back one of the points this winter took off him — never more than it
## took, so training visibly SLOWS the fall and never reverses it. That
## distinction is the difference between a system a player can read and one that
## quietly hands back what it just took.
static func _raise_one(f: FighterCard, fell: Dictionary, report: Dictionary) -> bool:
	var best := -1
	var low := 100
	for stat in STATS:
		if f.age > peak_for(f, stat):
			continue
		var v := read_stat(f, stat)
		if v < low and v < 99:
			low = v
			best = stat
	if best >= 0:
		write_stat(f, best, low + 1)
		return true

	## Nothing left to grow. Hold what the winter took, worst loss first, and
	## only up to what it took.
	var held := -1
	var most := 0
	for stat in STATS:
		var lost_here := int(fell.get(stat, 0))
		if lost_here > most and read_stat(f, stat) < 99:
			most = lost_here
			held = stat
	if held < 0:
		return false
	write_stat(f, held, read_stat(f, held) + 1)
	fell[held] = most - 1
	report["held"] = int(report["held"]) + 1
	return true


## What a bout was worth to one man. Read straight off the numbers the report
## already shows him.
## AND IT SCALES WITH THE MAN, which is the half of Retro Bowl's model we did
## not have. Pete, 15 Sep 2026, on levelling: *"Let's lean more toward theirs."*
##
## `s_has_xp_gain` works against a bar of `xp_level * 100` — linear in the level,
## forever — and it works because **their XP income grows with production**: a
## five-star quarterback throws for four thousand yards where a one-star throws
## for twelve hundred, so a better player fills a longer bar in the same season.
##
## Ours read `2 + 3 a down + 1 a round standing` and nothing else. A better
## fighter does cause more downs, so it was never entirely flat — but not nearly
## enough to carry a bar that rises with the level, which is exactly why
## `probe_levels` measured an uncapped bar walling a career at **+3 overall** and
## why `LEVEL_BAR_CAP` exists.
##
## `rating` closes that gap directly: a 65-rated man earns a third again what a
## 50-rated one does for the same afternoon, so the bar can go on rising longer
## before the cap has to catch it. Modest on purpose — this is the term that
## makes the rich richer, and a steep one would turn a career into a runaway.
const XP_RATING_BASE: float = 50.0
const XP_RATING_PULL: float = 0.60


static func xp_for(downs_caused: int, rounds_standing: int,
		rating: int = int(XP_RATING_BASE)) -> int:
	var raw := XP_BOUT + XP_PER_DOWN * downs_caused \
		+ XP_PER_ROUND_STANDING * rounds_standing
	var scale := 1.0 + (float(rating) / XP_RATING_BASE - 1.0) * XP_RATING_PULL
	return maxi(1, int(round(float(raw) * clampf(scale, 0.5, 2.0))))
