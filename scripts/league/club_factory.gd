class_name ClubFactory
extends RefCounted
## Turns a club rating into a club: eight fighters, five reserves, heraldry.
##
## The league carries a `power` number for every club in the country. That is
## enough to resolve a fixture on paper, and not remotely enough to FIGHT one —
## the melee needs eight men with positions, weights, tanks and armor. This is the
## bridge, and it has to be deterministic: the same club must field the same
## eight in October as it did in March, and a save that reloads with different
## men is not a save.
##
## Everything comes off a seed derived from the club's id, so no state is stored
## and nothing needs saving. Rebuild the club, get the same club.
##
## World rule inherited from Hedge Knight: real countries, fictional clubs,
## fighters and armorers. Russia is excluded entirely.

const SURNAMES := [
	"Aldous", "Barrow", "Calder", "Dain", "Ewart", "Fenn", "Garrick", "Hale",
	"Iver", "Joss", "Keld", "Lund", "Merrick", "Nash", "Orme", "Pike",
	"Quillan", "Rook", "Strand", "Tarrow", "Ulme", "Vane", "Wren", "Yates",
	"Ashby", "Brand", "Croft", "Dorn", "Ellis", "Frost", "Gale", "Harker",
	"Kerr", "Lowe", "Mear", "Nolan", "Orr", "Pell", "Reeve", "Salt",
	"Thorne", "Vint", "Ward", "Wexley", "Bracken", "Coyle", "Dunn", "Egan",
	"Falk", "Grimme", "Holt", "Innis", "Larkin", "Moss", "Norrey", "Poole",
]

## What each role is built out of. A Rail is heavy and hard to move, a Flanker is
## quick and technical, a Center is the immovable one — the same silhouette the
## fixture clubs have, because a league of identical men is a league of one club
## with different names on it.
##
## Offsets are points against the club's rating, and they must roughly cancel
## inside a role or the club would not come out at the rating it was asked for.
const ARCHETYPE := {
	Tuning.Role.RAIL:   { "str": 6, "base": 3, "skl": -8, "gas": -1, "agg": -4, "lb": [220, 251] },
	Tuning.Role.FLANK:  { "str": -6, "base": -8, "skl": 12, "gas": 8, "agg": 10, "lb": [185, 207] },
	Tuning.Role.CENTER: { "str": 5, "base": 10, "skl": -5, "gas": -4, "agg": -8, "lb": [243, 273] },
}

## The eight travel in this order, so roster order is the depth chart: five on
## the line, then one backup per role.
const LINE_SLOTS := [
	Tuning.Pos.RAIL_L, Tuning.Pos.FLANK_L, Tuning.Pos.CENTER,
	Tuning.Pos.FLANK_R, Tuning.Pos.RAIL_R,
]
const BACKUP_SLOTS := [Tuning.Pos.RAIL_L, Tuning.Pos.FLANK_L, Tuning.Pos.CENTER]
## And five more who never see an event.
const RESERVE_SLOTS := [
	Tuning.Pos.RAIL_R, Tuning.Pos.FLANK_R, Tuning.Pos.CENTER,
	Tuning.Pos.RAIL_L, Tuning.Pos.FLANK_L,
]

## How far below the line a club's own bench and reserve sit. A club whose
## thirteenth man is as good as his first is not a club, it is a stat block.
const BACKUP_DROP: int = 7
const RESERVE_DROP: int = 16


## `power` is the club rating the league carries. The club that comes back rates
## within a point or two of it — see `_tune_to`.
static func build(club_id: int, display_name: String, short_name: String, power: int) -> MeleeClub:
	var rng := RandomNumberGenerator.new()
	## Derived from the id alone, so this is stable across sessions and needs no
	## save data of its own.
	rng.seed = hash("club:%d" % club_id)

	var cards: Array[FighterCard] = []
	var no := 1
	for slot in LINE_SLOTS:
		cards.append(_fighter(rng, no, int(slot), power, 1.0))
		no += 1
	for slot in BACKUP_SLOTS:
		cards.append(_fighter(rng, no, int(slot), power - BACKUP_DROP, 0.94))
		no += 1
	for slot in RESERVE_SLOTS:
		var f := _fighter(rng, no, int(slot), power - RESERVE_DROP, rng.randf_range(0.62, 0.86))
		f.active = false
		## The reserve is where the young men are. Re-rolled rather than clamped
		## so the ceiling is re-drawn against the younger age — clamping the age
		## alone would have left a 20-year-old carrying a 36-year-old's room.
		f.age = rng.randi_range(Career.AGE_MIN, Career.PEAK_STRENGTH)
		f.potential = Career.roll_potential(rng, f)
		f.morale = roll_morale(rng)
		f.wage_agreed = Contracts.offer(ClubOffice.wage(f), f.age)
		cards.append(f)
		no += 1

	var club := MeleeClub.build(display_name, short_name,
		_field(rng), _icon_color(rng), _icon(rng), cards)
	_tune_to(club, power)
	return club


## ----------------------------------------------------------------- his age
## A SQUAD IS NOT A FLAT DRAW BETWEEN NINETEEN AND THIRTY-NINE.
##
## It was. `randi_range(AGE_MIN, AGE_MAX)` gives a 19-year-old and a 38-year-old
## exactly the same chance of being on the line, so every club in the country was
## a coin-flip between a young side and a retirement home — and since the eight
## that travels is the line plus the bench, with the young men parked in the
## reserve slots that get their own younger band, a club could quite easily
## field five men all past their peak and never see the three under twenty-five
## on its own books.
##
## A twenty-season walk turned that up as a starting eight averaging THIRTY-TWO
## against a learning par of twenty-six: a club whose whole traveling party was
## already on the downslope in season one, with its future on the bench earning
## no bout XP. Nothing was wrong with any single number; the DISTRIBUTION was
## wrong, and a distribution is not something any assertion in the suite was
## ever going to look at.
##
## The average of two draws is a triangle centerd on the middle of the range
## rather than a flat line across it — one cheap extra roll, no table, no tuning
## constants. It keeps both tails: a nineteen-year-old and a thirty-nine-year-old
## are still possible, just no longer as likely as a man in his prime. The mean
## lands near twenty-nine, which is a year past peak strength and three short of
## peak base — which is what a squad of grown men who fight in armor looks like.
static func roll_age(rng: RandomNumberGenerator) -> int:
	var a := rng.randi_range(Career.AGE_MIN, Career.AGE_MAX)
	var b := rng.randi_range(Career.AGE_MIN, Career.AGE_MAX)
	return int(round(float(a + b) * 0.5))


static func _fighter(rng: RandomNumberGenerator, no: int, slot: int,
		target: int, armor: float) -> FighterCard:
	var a: Dictionary = ARCHETYPE[Tuning.role_of(slot)]
	var f := FighterCard.new()
	f.display_name = SURNAMES[rng.randi() % SURNAMES.size()]
	f.number = no
	f.pos = slot
	## Strength and base stay in the same band on purpose. The takedown formula
	## reads `attacker.strength - defender.base`, so a generator that wrote base
	## consistently above strength would make that term negative for nearly every
	## pairing in the country and quietly stop anybody going down — which is
	## exactly what the hand-written fixtures did before they were rebalanced.
	f.strength = _stat(rng, target + int(a["str"]))
	f.base = _stat(rng, target + int(a["base"]))
	f.skill = _stat(rng, target + int(a["skl"]))
	f.gas = _stat(rng, target + int(a["gas"]))
	f.aggression = _stat(rng, target + int(a["agg"]))
	var lb: Array = a["lb"]
	f.weight = rng.randi_range(int(lb[0]), int(lb[1]))
	f.armor = clampf(armor, 0.0, 1.0)
	## AGE AND CEILING, drawn together. The reserve slots are handed a younger
	## band than the line is, which is the only place in the generator that says
	## anything about squad structure — and it is the right place, because a
	## reserve full of thirty-five-year-olds is not a reserve, it is a retirement
	## home. `roll_potential` then reads the age it was given, so a young man in
	## the reserve comes out with room in front of him for free.
	f.age = roll_age(rng)
	f.potential = Career.roll_potential(rng, f)
	f.morale = roll_morale(rng)
	## AND WHATEVER IS UNUSUAL ABOUT HIM, which for about half of them is nothing.
	## Rolled off this club's own stream so a squad is reproducible from its id,
	## and through `FighterTrait.roll` so a trait that is written but not yet
	## wired cannot reach a fighter — see PENDING in `fighter_trait.gd`.
	f.trait_id = FighterTrait.roll(rng.randi())
	## AND A DEAL, staggered. Every man on a three-year contract signed the same
	## summer means the whole squad expires together and the player faces one
	## catastrophic year in three with nothing to do in between. Spreading them at
	## generation is the cheapest possible fix and it makes the roster screen have
	## something on it every season.
	f.years = rng.randi_range(1, Contracts.YEARS_NEW)
	f.wage_agreed = Contracts.offer(ClubOffice.wage(f), f.age)
	return f


## ------------------------------------------------------- the replacement man
## RETRO BOWL'S "NONAME", and the reason it matters more than it looks.
##
## They hand you a free, bad, replacement-level player whenever a slot is empty.
## It is not a convenience feature — it is what gives every other number on the
## roster a meaning. A 62-rated fighter is not worth 62, he is worth 62 minus
## whatever you could have had for nothing, and without a floor to subtract from,
## "is he worth keeping" has no answer.
##
## It is also the safety net the career layer now needs. Men retire at the
## winter, and a club that came out of a summer with seven traveling fighters
## would simply be unable to field a line — a failure that does not surface until
## the player is standing at the next event.
##
## He is drawn at the BOTTOM of the division's own band and then some. In the
## Backyard Circuit that is somebody's mate who owns a helmet; in the National
## Division it is a competent fighter who is out of his depth, which is right —
## replacement level is relative to the room you are standing in.
const WALK_ON_DROP: int = 9


static func walk_on(rng: RandomNumberGenerator, slot: int, tier: int) -> FighterCard:
	var band: Array = League.TIERS[tier]["power"]
	var f := _fighter(rng, 0, slot, int(band[0]) - WALK_ON_DROP, rng.randf_range(0.55, 0.72))
	## Young, and with almost nothing in front of him. A free man who might
	## become good would make signing anybody else pointless — the whole value of
	## a floor is that it stays the floor.
	f.age = rng.randi_range(Career.AGE_MIN, Career.AGE_MIN + 4)
	f.potential = clampi(f.overall() + rng.randi_range(0, 4), 1, 99)
	## He is young, so the rookie rate applies and he is cheap as well as free —
	## which is the point. A walk-on is worth more than his rating says, and that
	## is exactly what makes "is this signing worth it" a question with an answer.
	f.years = Contracts.YEARS_NEW
	f.wage_agreed = Contracts.offer(ClubOffice.wage(f), f.age)
	f.active = false
	return f


## A MAN ON THE MARKET. Same generator as anybody else, drawn at a rating the
## caller chose rather than at a club's power — the pool is deliberately uneven,
## because a market where everything is an upgrade is a shop.
##
## His deal is NOT set here. What he costs is what the signing club offers him,
## and that is Contracts' business — writing a wage on him at generation would
## mean the rookie discount had already been applied by somebody who does not
## know how old the buyer thinks he is.
static func free_agent(rng: RandomNumberGenerator, slot: int, target: int) -> FighterCard:
	var f := _fighter(rng, 0, slot, target, rng.randf_range(0.70, 1.0))
	f.active = false
	f.years = 0
	f.wage_agreed = 0
	return f


static func _stat(rng: RandomNumberGenerator, mid: int) -> int:
	return clampi(mid + rng.randi_range(-5, 5), 1, 99)


## Nudge the whole club until it rates what the league says it rates.
##
## Generating stats around a target and hoping is not enough: `power()` is an
## average of position averages with armor inside it and a cover term on top, so
## the club that comes out of a naive generator lands several points off and the
## error grows with the archetype spread. Rather than trying to invert that
## formula — which would then have to be re-inverted every time the rating
## changes — this walks the club to the number and stops. Slow to write about,
## instant to run, and it cannot drift out of agreement with `power()` because
## it CALLS `power()`.
static func _tune_to(club: MeleeClub, target: int) -> void:
	for _pass in 24:
		var now := club.power()
		if now == target:
			return
		var step := 1 if now < target else -1
		for f in club.roster:
			f.strength = clampi(f.strength + step, 1, 99)
			f.base = clampi(f.base + step, 1, 99)
			f.skill = clampi(f.skill + step, 1, 99)
			f.gas = clampi(f.gas + step, 1, 99)


# ------------------------------------------------------------------ heraldry
static func _field(rng: RandomNumberGenerator) -> Color:
	return IconBank.KIT_COLORS[rng.randi() % IconBank.KIT_COLORS.size()]


## The contrast rule, enforced rather than hoped for. A mark that does not read
## at a glance is a mark that does not do its job, and the whole art direction
## rests on it.
static func _icon_color(rng: RandomNumberGenerator) -> Color:
	return IconBank.MARK_COLORS[rng.randi() % IconBank.MARK_COLORS.size()]


## CPU clubs wear anything in the bank. The bank is a shop for the PLAYER; the
## other forty-one clubs in the country have their own kit already.
static func _icon(rng: RandomNumberGenerator) -> int:
	return int(IconBank.ICONS[rng.randi() % IconBank.ICONS.size()]["id"])



## HOW HE ARRIVES.
##
## Most men turn up fine. About one in ten turns up already difficult, and those
## are the ones worth a second look: a toxic man hits harder and lasts longer
## than his rating says, and his rating is what he is priced on. The bargain in
## this game is a chip on somebody's shoulder.
##
## THE FIRST VERSION NEVER PRODUCED A TOXIC MAN AT ALL. It drew 0.62-0.92 and
## took 0.34 off one roll in ten, so the worst mood the generator could reach was
## 0.28 — and `FighterCard.toxic()` starts at 0.18. Every screen, every drag,
## every trade in the toxic band was code the player could not meet, and nothing
## said so: the squads looked fine, the fights ran, the numbers moved. It was
## caught by asking a generator for four thousand men and counting the tail,
## which is the only way that class of bug ever surfaces.
##
## So the sour roll is drawn on its own range rather than subtracted from the
## happy one. A number arrived at by arithmetic on another number is a number
## nobody is watching.
const SOUR_CHANCE: float = 0.10
const SOUR_LO: float = 0.05
const SOUR_HI: float = 0.40
const FINE_LO: float = 0.62
const FINE_HI: float = 0.92


static func roll_morale(rng: RandomNumberGenerator) -> float:
	if rng.randf() < SOUR_CHANCE:
		return SOUR_LO + rng.randf() * (SOUR_HI - SOUR_LO)
	return clampf(FINE_LO + rng.randf() * (FINE_HI - FINE_LO), 0.05, 0.99)
