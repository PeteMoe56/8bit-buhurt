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
## HOW MANY YEARS EITHER SIDE OF THE SPORT'S SCHEDULE ONE MAN CAN SIT.
##
## Four. Wide enough that a scouting report says something a birthday does not —
## gas can arrive anywhere from twenty to twenty-eight, skill from thirty-one to
## thirty-nine.
##
## THE ORDER MOSTLY SURVIVES AND SOMETIMES DOES NOT, and that is worth stating
## plainly rather than claiming otherwise: the sport's own peaks sit three or
## four years apart, so a spread of four lets an unusual man's base arrive after
## his skill. `probe_growth` prints one on the starting squad. That is a fighter
## whose hands came good before his footing, which is a real thing and reads as
## one — what a wider spread would produce is gas peaking after skill, and THAT
## would not be variation, it would be noise.
const PEAK_SPREAD: int = 4


## Drawn from his seed and the stat together, so one man is not uniformly early
## at everything — he is early at some of it, which is what a real fighter is.
## Derived rather than stored, so there is one number on the card instead of four
## that can disagree with each other.
static func peak_offset(f: FighterCard, stat: int) -> int:
	if f.peak_seed == 0:
		return 0
	## MIXED, NOT `hash() % 9`. The first cut formatted a string and took the
	## modulo of its hash, and `probe_growth` printed a thirteen-man squad in
	## which FOUR fighters carried the identical 22/32/28/32 and three more shared
	## 26/27/32/36. The low bits of a string hash on inputs that differ by a few
	## digits are not independent, and a modulo reads only the low bits.
	##
	## `LeagueWorld._hash2` exists for exactly this and says why in its own
	## header. Same shape here, and the shift throws away the bits that were
	## correlating. **A hash is not a random number until it has been mixed.**
	var x: int = (f.peak_seed * 2654435761) ^ ((stat + 1) * 40503)
	x = (x ^ (x >> 13)) * 1274126177
	return absi(x ^ (x >> 16)) % (PEAK_SPREAD * 2 + 1) - PEAK_SPREAD


static func peak_for(f: FighterCard, stat: int) -> int:
	return peak_of(stat) + peak_offset(f, stat) \
		+ int(FighterTrait.mod(f.trait_id, "peak", 0.0))


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
		Stat.STRENGTH: return UiKit.t("Strength")
		Stat.BASE: return UiKit.t("Base")
		Stat.SKILL: return UiKit.t("Skill")
		Stat.GAS: return UiKit.t("Gas")
		_: return UiKit.t("Aggression")


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
## AND THE STANDARD HE WAS REARED AGAINST, which this read nothing of until
## 15 Sep 2026.
##
## Pete, turning down a youth slot: *"training a new guy from a higher tier
## should surpass the older lower tier guy."* `tools/probe_growth.gd` says the
## tier gap already does that — a twenty-two year old from the division above
## passes a finished thirty year old **in season one, with no captain at all**,
## and one from your own division never passes him without coaching and takes
## seven seasons with it. That is exactly the weight he asked for.
##
## But it works through the man's RATING and not through his ceiling, because
## this function read `potential_room(age)` and nothing else. **Two
## twenty-two year olds rated 39 had identical prospects whether one of them had
## spent his career training against National fighters or against a back field.**
## So the rare case the market exists to create — the raw man from up the
## pyramid, cheap because his rating is low, who becomes something your division
## cannot produce — was not a thing that could happen.
##
## `standard` is the top of the band he was drawn from. A man already at it gets
## nothing extra; a man well under it gets room to grow INTO the company he has
## been keeping, up to `STANDARD_ROOM`, halved on the way in because being around
## good fighters is evidence about a man rather than a promise.
##
## IT IS ADDED AFTER THE ROLL AND NOT INTO ITS RANGE, and that is the difference
## between the rule meaning something and not. Widening the range leaves the draw
## uniform, so a raw man reared a division up is only better ON AVERAGE and any
## one of them can still roll a nothing ceiling — `probe_growth` had him passing
## the incumbent in season six against the local boy's season seven, which is
## noise wearing a rule's clothes. Evidence shifts an estimate; it does not
## merely widen it.
##
## AND IT FADES WITH AGE ON THE SAME CURVE THE ROOM DOES. A thirty-four year old
## rated 40 off a National shelf is a journeyman who was in the building, not a
## prospect, and handing him nine points of ceiling he has no years left to reach
## would make "reared up the pyramid" a laundering trick for old men.
const STANDARD_ROOM: int = 10


static func roll_potential(rng: RandomNumberGenerator, f: FighterCard,
		standard: int = 0) -> int:
	var room := potential_room(f.age)
	var bonus := 0
	if standard > f.overall():
		bonus = mini(STANDARD_ROOM, (standard - f.overall()) / 2) \
			* room / maxi(1, POTENTIAL_GAP_MAX)
	return clampi(f.overall() + (rng.randi() % (room + 1)) + bonus,
		1, POTENTIAL_CEILING)


## A FREE AGENT'S CEILING, DRAWN WIDE — Pete, 28 Sep 2026: make the scouted range
## worth reading.
##
## `roll_potential` gives every man 0..room above himself, evenly. On a shelf that
## meant every young man looked roughly alike and knowing his real ceiling bought
## nothing (`tools/probe_scouting.gd`: the true number and the worst reading of it
## finished within 0.45 seasons of each other). The ceiling's own drift carries a
## man upward either way; what the GAP decides is how fast — `gain_for` pays a
## point per level plus one per three points of gap.
##
## So the shelf draws the gap on a skewed curve over a wider span: most men arrive
## near finished, a few arrive with twice the ordinary room. `talent` is a 0..1
## draw from the caller's hash, so this moves no random stream; squared, so the
## wide ones are rare. Mean gap is 0.6 x room (was 0.5), and the top quarter of
## the shelf has more room than anybody could before.
const FREE_AGENT_WIDE: float = 1.8


static func free_agent_potential(f: FighterCard, standard: int, talent: float) -> int:
	var room := potential_room(f.age)
	var bonus := 0
	if standard > f.overall():
		bonus = mini(STANDARD_ROOM, (standard - f.overall()) / 2) \
			* room / maxi(1, POTENTIAL_GAP_MAX)
	var gap := int(round(float(room) * FREE_AGENT_WIDE * talent * talent))
	return clampi(f.overall() + gap + bonus, 1, POTENTIAL_CEILING)


## WHAT HE WILL BE WORTH, WHICH IS NOT WHAT HE IS WORTH TODAY.
##
## Pete, 15 Sep 2026: *"The simulations need to run on potential, not immediate
## power. I may have a guy with a power of 55 maxed, but there's a guy for signing
## that's starting at 54 with a max of 60s. It's worth it to buy the guy with
## higher tier and potential."*
##
## He is right and the probes were wrong: every manager fixture in `tools/` sorted
## the shelf by `overall()` and compared against the weakest starter's `overall()`,
## so a finished 55 beat a 54 who becomes a 62. **A market read on today's number
## is a market that systematically buys the wrong man**, and it had been measuring
## the game's balance through that mistake.
##
## Two things decide how much of the gap a man actually closes, and BOTH are age:
##
##   the gap itself   `roll_potential` already shrinks with age, so an old man
##                    has little room in front of him to begin with.
##   the runway       and he has to be fighting to use it. `PEAK_SKILL` at 35 is
##                    the last peak to arrive; after it he is falling away from
##                    his ceiling, not climbing to it.
##
## That double-counting of age is deliberate rather than a mistake: a thirty-four
## year old with a 4-point gap will not close it, and one number saying so twice
## is closer to the truth than either alone. `PROJECT_YEARS` is how long a man
## fighting every week takes to reach his ceiling — five seasons, which is about
## what `probe_dev.gd` measured a regular starter doing.
const PROJECT_YEARS: float = 5.0


static func projected(f: FighterCard) -> int:
	var gap := maxi(0, f.potential - f.overall())
	if gap == 0:
		return f.overall()
	var runway := float(maxi(0, PEAK_SKILL - f.age)) / PROJECT_YEARS
	return f.overall() + int(round(float(gap) * clampf(runway, 0.0, 1.0)))


## AND WHAT HE IS WORTH TO A CLUB DECIDING TODAY, WHICH IS A NUMBER OF SEASONS
## AND NOT A NUMBER OF POINTS.
##
## The first cut of this was `lerp(projected, overall, 0.40)` — a blend of what
## he is and what he becomes — and `tools/probe_pace.gd` showed exactly how it
## fails. A competent manager buying on it signed one to two men every summer for
## twenty seasons and **his starting five aged from 27.7 to 31.8 and his club
## rating never moved.** He was sitting on fifty credits in a division where a
## Star costs eighteen. Nothing was refusing him. He was simply buying the best
## man on the board every time, and the best man on the board is always the
## oldest one, because a finished 49 beats a 42 who becomes a 52 on any blend
## weighted at all toward today.
##
## **A club does not buy a rating, it buys seasons of a rating.** So this walks
## the man forward through the game's OWN curves and averages what he actually
## gives you:
##
##   the climb       he closes his gap toward `potential` at the rate a regular
##                   starter closes it — `POTENTIAL_GAP_MAX` over `PROJECT_YEARS`,
##                   derived rather than typed so the two cannot drift apart.
##   the fall        `decline_for`, per stat against its own peak, averaged. The
##                   same function the winter uses, so a projection cannot
##                   disagree with what then happens to him.
##   the exit        `retire_chance` compounded year on year. A 35-year-old who
##                   is gone in two summers contributes two summers.
##
## Worked through, on a six-year horizon:
##
##   49 maxed, age 35   ->  worth 27   (declining, and gone about year three)
##   42 -> 52, age 23   ->  worth 48   (climbs to his ceiling and holds it)
##
## Which is the call Pete asked for, and the opposite of the one the old blend
## made. `projected()` above still exists because it is the honest answer to a
## different question — what will he BE — and that is the one the card shows.
const WORTH_HORIZON: int = 6
const CLIMB_PER_SEASON: float = float(POTENTIAL_GAP_MAX) / PROJECT_YEARS


static func worth(f: FighterCard) -> int:
	var rating := float(f.overall())
	var ceiling := float(f.potential)
	var age := f.age
	## How likely he is still here at all, compounded. Starts certain.
	var here := 1.0
	var total := 0.0
	for _y in WORTH_HORIZON:
		if rating < ceiling:
			rating = minf(ceiling, rating + CLIMB_PER_SEASON)
		var fell := 0.0
		for stat in STATS:
			fell += float(decline_for(age, stat))
		rating = maxf(0.0, rating - fell / float(STATS.size()))
		total += here * rating
		## The retirement roll happens at the WINTER, after the season he has just
		## given you — so it discounts the years AFTER this one, never this one.
		## Read at the default morale, because a man being valued on the market
		## has no club mood yet and guessing one would make the fee depend on how
		## the last fixture went.
		here *= 1.0 - _retire_at(age, ceiling - rating)
		age += 1
	return int(round(total / float(WORTH_HORIZON)))


## `retire_chance` without a FighterCard, because the walk above is projecting a
## man who does not exist yet at each of those ages. Same constants, same shape —
## it is the one function rather than a second copy of the rule.
static func _retire_at(age: int, faded: float) -> float:
	if age >= RETIRE_HARD:
		return 1.0
	if age < RETIRE_FROM:
		return 0.0
	return clampf(float(age - RETIRE_FROM + 1) * RETIRE_PER_YEAR
		+ maxf(0.0, faded) * RETIRE_PER_FADED_POINT, 0.0, 1.0)


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


## THE SECOND WAY, AND IT IS THE ONE CREDITS BUY.
##
## Pete, 15 Sep 2026, on the finding that no rational manager ever bought a
## level: *"Alright so let's fix that."*
##
## `tools/probe_shelf.gd` priced the old paid level honestly and it was worthless
## — **twenty-four bought levels moved a club 0.4 points** for about 290 credits,
## against a signing that moves it three to six for eleven. The reason was never
## the price. A bought level did the SAME JOB a fought level does, and the fought
## one is free: the club was paying for a thing the season hands out. *A purchase
## that duplicates something the game gives away is a purchase with no argument
## for itself at any price.*
##
## So paid training stops raising the RATING and raises the CEILING. What a man
## earns by fighting still moves him up; what the club buys moves where he can
## get to. That splits the two cleanly:
##
##   fighting   closes the gap to `potential`      free, automatic, his
##   training   opens a wider gap to close         credits, the club's choice
##
## And it makes training something signing cannot substitute for, which is the
## whole test the old version failed. A 24-year-old signed at 42 with a ceiling
## of 52 becomes a 62 if the club spends on him for a few winters — that man does
## not exist on any shelf, at any price, in any division.
##
## THE COMMENT ABOVE STILL STANDS AND THIS DOES NOT CONTRADICT IT. *"Anything you
## can buy in bulk stops being a ceiling and becomes a price"* — which is why
## this is one point at a time, throttled to one job a week like every other
## building, priced off how much ceiling the man already has, and hard-capped at
## what a man of his age could ever have had.
const RAISE_COST_PER: int = 2
const RAISE_STEP: int = 1
## What a man's ceiling moves on its own, per winter, once he has caught it. See
## the end of `winter()` — this is the free half of the same idea.
## FOUR, AND THE SIZE OF THIS NUMBER IS THE SIZE OF A CAREER.
##
## Everything else in development is already capable of about five rating points
## a season — `gain_for` pays up to five stat points a level and a starter earns
## four or five levels a year. What it cannot do is use them, because `level_up`
## stops at `potential` and the ceiling was only creeping up a point a winter. At
## one, a man grew about one point a year. **The ceiling was never a description
## of a fighter, it was the throttle on the whole game**, and Pete's *"1 point a
## season seems dismal as fuck"* is that throttle, felt from the outside.
##
## At four the ceiling leads and the man chases it, which is the right way round.
## It is still bounded twice and both bounds matter: `ceiling_limit` only offers
## a man the room his AGE still has — fifteen points at twenty-two, six at
## thirty, nothing at thirty-five — and this only fires for a man who has caught
## what was already in front of him. A career becomes a climb that slows and then
## stops, rather than a wall at twenty-five.
const CEILING_DRIFT: int = 4
## How near his ceiling a man has to be for it to move. See `winter()`.
const CEILING_NEAR: int = 4


## WHAT A MAN'S CEILING CAN NEVER EXCEED: what he is today plus the room a man
## of HIS AGE still has in front of him.
##
## It is a ROLLING headroom, not a lifetime cap, and that distinction is the
## whole of how a career reaches the top of the scale. A twenty-year-old rated 40
## can be trained toward 57; when he IS 57 the same rule offers him 74. He walks
## up the scale over a career instead of being told on his first day how good he
## is ever allowed to get. `potential_room` closes on its own with age, so the
## door shuts around thirty-five without a second age table saying so — and
## buying a point a winter can never walk a thirty-eight-year-old to 99, because
## by then it offers him nothing.
static func ceiling_limit(f: FighterCard) -> int:
	return clampi(f.overall() + potential_room(f.age), 1, POTENTIAL_CEILING)


static func can_raise_ceiling(f: FighterCard) -> bool:
	return f.potential < ceiling_limit(f)


## AND THE PRICE CLIMBS WITH THE CEILING HE ALREADY HAS, measured from where his
## division starts him rather than from zero — so the first winter on a young
## prospect is cheap and the last point before a man's limit is not.
static func raise_cost(f: FighterCard) -> int:
	var room := maxi(1, ceiling_limit(f) - f.overall())
	var done := maxi(0, f.potential - f.overall())
	return maxi(1, int(round(float(RAISE_COST_PER)
		* (1.0 + 1.5 * float(done) / float(room)) / learn_rate(f))))


## Raise it. Returns how much it moved, so a caller can say so.
static func raise_ceiling(f: FighterCard) -> int:
	var was := f.potential
	f.potential = mini(f.potential + RAISE_STEP, ceiling_limit(f))
	return f.potential - was


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
##
## FIVE, NOT EIGHT, AND THAT IS PETE'S "DISMAL AS FUCK" IN ONE NUMBER.
##
## The paragraph above is right that a constant income needs a constant bar, and
## it set the bar against *the winter it replaced* — a rework that deliberately
## changed WHEN a man levels and not how far he climbs. The trouble is that "how
## far he climbs" was itself never measured, and `tools/probe_growth.gd` finally
## did it: **a man banks about eleven XP an event and fights seven of them, so a
## 32-point bar is two and a bit levels a season.** Everything downstream was
## tuned against that without knowing it.
##
## At five the bar reads 5 / 10 / 15 / 20 and a starter takes four levels a year,
## which is what the rest of the development economy was already built for —
## `gain_for` pays up to five stat points a level and `CEILING_DRIFT` keeps four
## points of ceiling in front of him a winter. Those two were sized for a man who
## levels four or five times a season and were being fed one who levelled twice.
##
## It is deliberately NOT a doubling of XP income. Moving the bar moves one
## number; moving income moves what a down is worth, what a round standing is
## worth, what a simmed afternoon is worth and what a level costs to buy, all of
## which are priced against each other elsewhere in this file.
const LEVEL_XP: int = 5
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
	var paid := cash_value(f)
	f.xp -= next_level_at(f)
	f.level += 1
	return paid


## WHAT ONE CASH-IN PAYS: the level cost, with the level capped where the bar is
## capped. It paid the raw `level_cost`, and `level` goes up by one on every
## cash-in while the bar stops rising at LEVEL_BAR_CAP — so a squad of maxed
## veterans paid more every single winter, forever.
static func cash_value(f: FighterCard) -> int:
	return maxi(1, int(round(float(clampi(f.level, 1, LEVEL_BAR_CAP))
		* float(LEVEL_COST_PER) * learn_rate(f))))


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
		return UiKit.t("picks it up fast")
	if r >= 1.30:
		return UiKit.t("slow to learn")
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
		return {"levelled": false, "reason": UiKit.t("not earned"),
			"short": next_level_at(f) - f.xp}
	var before := f.overall()
	write_stat(f, stat, read_stat(f, stat) + 1)
	return _took(f, before, stat)


## TAKE ONE LEVEL, THE CLUB'S WAY. Kept for anything that has no player at the
## keyboard — a simulated club's men, and the drain of a save made before levels
## existed. It goes through `_raise_one` so the automatic path and the winter
## cannot disagree about which stat a point lands on.
## WHAT ONE LEVEL IS WORTH, AND IT IS NOT ALWAYS ONE POINT.
##
## A level was one stat point, always, which works out at about +0.23 of a man's
## rating — `rating()` weights the four stats at roughly a quarter each. At the
## four or five levels a season a starter earns, that is a fighter improving
## just over a point a year, and `tools/probe_pace.gd` measured what it does to
## a career: **a club climbing 0.4 rating points a season against division
## leaders eight to ten clear of it.** Pete wants the top flight reachable in
## about ten seasons; three promotions in ten years is nearer four points a
## season, and no amount of shopping closes a gap that arithmetic wide.
##
## So a level pays by HOW FAR HE HAS LEFT TO GO. A young man with a wide gap
## takes three points from one level; a man at his ceiling takes one and then
## stops, because `at_ceiling` is checked first. The accelerator is self-
## limiting — it cannot run away, it cannot lift anybody past `potential`, and
## it is worth nothing at all to the veteran it would have been worth most to
## under a flat rate.
##
## It is also what makes the OTHER training door matter. Paying to raise a man's
## ceiling (see `RAISE_COST_PER`) now widens the gap AND speeds the climb into
## it, so a club that invests in a twenty-three-year-old compounds twice. That
## is the thing a shelf cannot sell you at any price.
const GAIN_PER_GAP: int = 3
const GAIN_MAX: int = 5


## ONE POINT A LEVEL, FOR EVERYBODY (Pete, 1 Oct 2026: "Everyone should get
## +1, age only messes with experience gain speed"). The accelerator above was
## only ever on the automatic path — CPU clubs and old saves — while a level the
## player placed by hand paid +1, so the computer's men grew up to five times as
## fast as his. Age still sets how fast the bar fills (`learn_rate`).
static func gain_for(_f: FighterCard) -> int:
	return 1


static func level_up(f: FighterCard) -> Dictionary:
	var report := {"lost": 0, "gained": 0, "spent": 0, "ground": 0, "held": 0}
	if at_ceiling(f):
		return {"levelled": false, "reason": "ceiling"}
	var before := f.overall()
	if not _raise_one(f, {}, report):
		## NOTHING UNPEAKED LEFT — AND A LEVEL STILL HAS TO LAND SOMEWHERE.
		##
		## `_raise_one` only grows a stat a man is not yet past, so a fighter past
		## all four peaks and still under his potential used to come back "nothing
		## to grow" WITHOUT SPENDING THE BAR, while `can_level` went on saying
		## yes. `tools/probe_growth.gd` found it the hard way: a twenty-eight year
		## old sat in a `while can_level(f)` loop forever and hung the probe.
		##
		## WHERE THE FALLBACK GOES IS THE WHOLE POINT, and it took two attempts.
		## Putting it inside `_raise_one` broke `test_career`'s rule that **a
		## veteran holds but never reverses** — the winter would have handed a
		## forty-year-old training points that lifted him above where the season
		## started, which makes age optional. But `_raise_one` serves two callers
		## with genuinely different rules, and Pete settled the other one on 13
		## Sep 2026: *"leave the ability to gain all stats still. He's just slower
		## at leveling."* `level_into` has let a player put a level anywhere at any
		## age ever since.
		##
		## So the automatic path now matches the manual one — a level lands on his
		## lowest stat with room — and the WINTER, which is the club's training
		## and not his level, keeps refusing. Two rules, two places, neither
		## pretending to be the other.
		var open_ := raisable(f)
		if open_.is_empty():
			return {"levelled": false, "reason": UiKit.t("nothing to grow")}
		var pick: int = open_[0]
		for stat in open_:
			if read_stat(f, stat) < read_stat(f, pick):
				pick = stat
		write_stat(f, pick, read_stat(f, pick) + 1)
	## THE REST OF THE LEVEL'S WORTH. Re-checking `at_ceiling` between points
	## rather than counting them out in advance, because the first point can be
	## the one that finishes him and a level must never carry a man past his own
	## potential — that is the whole meaning of the number.
	for _extra in gain_for(f) - 1:
		if at_ceiling(f) or not _raise_one(f, {}, report):
			break
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


## HOW MANY LEVELS HE HAS BANKED: the bar walked forward on what he has, as far
## as the XP and his ceiling go. For the squad sheet's gold "+2" (1 Oct 2026).
static func levels_banked(f: FighterCard) -> int:
	if not can_place(f):
		return 0
	var xp := f.xp
	var lvl := f.level
	var room := maxi(1, (f.potential - f.overall()) * 4)
	var n := 0
	while n < 9 and n < room:
		var bar := maxi(1, int(round(float(mini(maxi(1, lvl), LEVEL_BAR_CAP) * LEVEL_XP) * learn_rate(f))))
		if xp < bar:
			break
		xp -= bar
		lvl += 1
		n += 1
	return n


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
		## HIS PEAK, NOT THE SPORT'S — and `decline_for_man` has said so in its own
		## comment (*"the one the winter uses"*) since the day it was written,
		## while the winter called `decline_for` and nothing noticed. A Late Peak
		## fighter was refused training on a stat he was past by his own schedule
		## and declined on it by everybody else's, which is the worst of both and
		## exactly backwards. **A comment that says where a function is called is
		## not a check that it is.**
		var want := decline_for_man(f, stat)
		if want <= 0:
			continue
		var before := read_stat(f, stat)
		write_stat(f, stat, before - want)
		var took := before - read_stat(f, stat)
		fell[stat] = took
		report["lost"] = int(report["lost"]) + took


	## THE CLUB'S OWN INVESTMENT ONLY RUNS IF THERE IS SOMEBODY TO RUN IT. This
	## was an early `return`; it is a branch now, because the ceiling drift below
	## belongs to every fighter and not only to the coached ones.
	if coached:
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

	## AND HE MAY HAVE OUTGROWN THE PROJECTION.
	##
	## LAST IN THE WINTER, AND OUTSIDE THE `coached` GATE. Both placements were
	## wrong once. Running it before the training-ground allocation gave that
	## allocation a ceiling the man had not earned yet, so `test_career` caught a
	## fighter AT his potential being handed twelve points of training — the
	## ceiling stopped binding, which is the one thing it is for. And gating it on
	## `coached` would mean a club with no coach has men who can never exceed a
	## number somebody wrote about them at nineteen. It is a conclusion drawn from
	## the season just finished, so it belongs after everything that season did.
	##
	## Pete, 15 Sep 2026: *"99 overall should be the top of the goal... 1 point a
	## season seems dismal as fuck."* `tools/probe_growth.gd` showed why it was:
	## a twenty-year-old reached his rolled ceiling in five seasons and then sat
	## there, unchanged, for the next seven — **potential was a wall a career hit
	## at twenty-five**, and a club could not pass it at any price.
	##
	## A scout's number written on a nineteen-year-old is a guess, and the sport
	## corrects it. A young man who is AT his ceiling and still fighting every
	## week is a man the club under-rated, so his ceiling moves — free, a few
	## points a winter, and only while he is young enough for `ceiling_limit` to
	## still offer him anything. That is what makes the paid door worth paying for
	## rather than the only door there is: training buys the same movement several
	## times a season instead of once.
	##
	## CLOSE ENOUGH COUNTS, and "at or above" did not. A man one point under his
	## ceiling gains a point in November and gives it back to the decline in
	## June, so he never technically CATCHES it — `probe_growth` had a fighter
	## pinned at 54 against a ceiling of 55 for four straight seasons with the
	## drift never once firing. Within `CEILING_NEAR` is what "he has caught his
	## own projection" actually looks like on a moving number.
	if f.potential - f.overall() <= CEILING_NEAR and can_raise_ceiling(f):
		f.potential = mini(f.potential + CEILING_DRIFT, ceiling_limit(f))
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


## ---------------------------------------------------------------- practice
## THE WEEK BETWEEN FIGHTS, WHICH THIS GAME DID NOT HAVE.
##
## Pete, 15 Sep 2026: *"The Coaches hold practices, the better the coaches, the
## more you get out of practice. Benched guys get more out of practices, but the
## fighters get a little practice and the fight XP... Let's not give them a lot,
## but if you stick with the same guys, everyone gets a raise and they all hit
## their individual peaks."*
##
## `tools/probe_pace.gd` had found the hole from the other side: only the
## starting five earned anything, so the three on the bench and the five in
## reserve improved by exactly zero for their whole careers and a club could not
## build a pipeline at all. The first patch handed the bench a share of the
## STARTERS' fight XP, which fixed the arithmetic and said something untrue —
## that a man on the bench is paid a fraction of an afternoon he did not have.
##
## A practice is its own source and it belongs to the coach. That reading also
## matches the reference: Retro Bowl's Training Facility is *"players gain XP
## faster"* and its `Likeable` coordinator is a flat +5% XP a game — development
## there is a rate the staff sets, not a reward for the men who played.
##
## THE BENCH GETS MORE, AND THAT IS THE WHOLE MECHANIC. A starter spends his
## week recovering and his Saturday fighting; a reserve spends the week in the
## hall with the captain. So the reserve out-practises him four to one and the
## starter still finishes ahead on the day — which is what makes a squad a
## pipeline rather than a queue. Leave a young man on the bench for three
## seasons and he arrives; leave him there for eight and he has passed the man
## in front of him.
## THE STARS ARE THE WHOLE NUMBER, AND THE FLOOR IS DELIBERATELY NEARLY NOTHING.
##
## `probe_growth` sized these. A starter banks about twenty-five XP a week — a
## quarter practice plus an afternoon — so the question is what fraction of that
## a reserve should see. At 1.4 a star the answer was a fifth, and twelve seasons
## on the bench under the best captain in the game left a man on 53 while the men
## in front of him reached 73. **A pipeline that produces fighters twenty points
## short is not a pipeline, it is a waiting room.**
##
## At 2.6 a five-star captain gets a reserve to roughly sixty per cent of a
## starter's week: enough that a young man kept for four or five seasons arrives
## able to play, never enough that sitting him is better than playing him. And
## the floor stays at two, which is close to nothing on purpose — **a club with
## nobody teaching develops nobody**, and that is the sentence that makes the
## grade on a hire card worth paying for.
const PRACTICE_BASE: float = 2.0        ## a week with nobody teaching him
const PRACTICE_PER_GRADE: float = 2.6   ## and what each of a captain's stars adds
const PRACTICE_STARTER: float = 0.25    ## his week is mostly Saturday


## What one week is worth to one man. `grade` is his captain's stars for the role
## he stands in, 0 if nobody teaches it — see `ClubOffice.coaching`.
static func practice_xp(grade: int, starts: bool) -> float:
	var raw := PRACTICE_BASE + PRACTICE_PER_GRADE * float(maxi(0, grade))
	return raw * (PRACTICE_STARTER if starts else 1.0)


static func xp_for(downs_caused: int, rounds_standing: int,
		rating: int = int(XP_RATING_BASE)) -> int:
	var raw := XP_BOUT + XP_PER_DOWN * downs_caused \
		+ XP_PER_ROUND_STANDING * rounds_standing
	var scale := 1.0 + (float(rating) / XP_RATING_BASE - 1.0) * XP_RATING_PULL
	return maxi(1, int(round(float(raw) * clampf(scale, 0.5, 2.0))))
