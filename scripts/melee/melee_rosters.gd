class_name MeleeRosters
extends RefCounted
## Two clubs for the prototype. Fixtures, not content.
##
## STRENGTH AND BASE ARE KEPT IN THE SAME RANGE ON PURPOSE. The first pass gave
## every man a base ten points above his strength, because base was described as
## "the quiet stat that wins rounds" and got written up accordingly. The takedown
## formula reads `attacker.strength - defender.base`, so that made the term
## negative for nearly every pairing in the game: two evenly matched clubs could
## fight for four and a half minutes and put 0.1 men on the ground. A stat that
## sounds important in prose is not the same as one that is balanced.
##
## They exist to make the fight legible, so the five are deliberately unalike:
## the Rails are the biggest and hardest to move, the Flankers hit hardest, the
## Centers are the light, quick, fit ones (Pete, 10 Oct 2026: "Centers are like
## Harrison Smith, Flankers like Ray Lewis, Rails like a defensive lineman").
## If everyone is a 50 the readability question gets a dishonest answer.
##
## World rule inherited from Hedge Knight: real countries, fictional
## federations, clubs, fighters and armorers. Russia is excluded entirely.

const P := Tuning.Pos


static func _c(
	nm: String, no: int, pos: int,
	str_: int, base: int, skl: int, gas: int, agg: int, wt: int, armor: float = 1.0,
	active: bool = true
) -> FighterCard:
	var f := FighterCard.new()
	f.display_name = nm
	f.number = no
	f.pos = pos
	f.strength = str_
	f.base = base
	f.skill = skl
	f.gas = gas
	f.aggression = agg
	f.weight = wt
	f.armor = armor
	f.active = active
	## The hand-written fixtures predate the career layer and carry no ages of
	## their own. Rather than writing twenty-six numbers that would all be
	## guesses, each man is given an age DERIVED from his own card: a big
	## low-gas fighter reads as a veteran, a light high-gas one as a young man.
	## It is the same information the stats already carry, said in years, and it
	## means the fixtures age sensibly without a second table to keep in step.
	f.age = _age_from(f)
	f.potential = clampi(f.ability() + Career.potential_room(f.age) / 2, 1, 99)
	## A deal at the market rate, staggered off the shirt number so the fixtures
	## do not all expire in the same summer. Derived rather than rolled — these
	## are FIXTURES, and a fixture that changes between runs is not one.
	f.years = 1 + (no % Contracts.YEARS_NEW)
	f.wage_agreed = Contracts.offer(ClubOffice.wage(f), f.age)
	## AND HIS OWN AGEING CURVE, derived from the card rather than rolled, for the
	## same reason the age above is: these are FIXTURES, and a fixture that comes
	## out differently between runs is not one. Seeded off the name and shirt
	## number so no two men in a hand-written club share a curve and the same club
	## reproduces exactly.
	f.peak_seed = 1 + absi(hash("%s#%d" % [nm, no])) % 1_000_000
	return f


## Years read off the card. Gas is the tell — it is the first thing to go and
## the last thing a young fighter lacks.
static func _age_from(f: FighterCard) -> int:
	var youth := (float(f.gas) * 0.7 + float(f.strength) * 0.3) / 99.0
	return clampi(int(round(lerpf(38.0, 21.0, youth))), Career.AGE_MIN, Career.AGE_MAX)


## The player's club. Vance carries 34 gas on purpose: the post-fight report has
## to be able to say something true about the roster, and a tank that empties in
## the third round is the truest thing a buhurt club has.
static func player_club() -> MeleeClub:
	var cards: Array[FighterCard] = [
		_c("Ward", 1, P.RAIL_L, 78, 81, 55, 53, 44, 268),
		_c("Iles", 2, P.FLANK_L, 80, 62, 62, 67, 54, 216),
		_c("Kerrigan", 3, P.CENTER, 65, 66, 75, 78, 42, 191),
		_c("Vance", 4, P.FLANK_R, 88, 64, 50, 22, 68, 231, 0.82),
		_c("Ash", 5, P.RAIL_R, 77, 78, 58, 56, 54, 261),
		## THE BENCH. Three men — eight for a 5v5, Pete 10 Sep 2026 — one per role,
		## so every place on the line has cover. They sit AFTER the five because
		## starting_five() takes the first available man at each position, which
		## makes roster order the depth chart.
		_c("Doole", 6, P.RAIL_L, 71, 76, 52, 61, 49, 252),
		_c("Peake", 7, P.FLANK_L, 76, 60, 55, 69, 48, 209),
		_c("Marsh", 8, P.CENTER, 59, 60, 71, 76, 46, 184),
		## THE RESERVE. Never at an event, never in a club's rating — they exist in
		## the roster menu, where you train them, outfit them and promote them onto
		## the eight. Three of a possible five, so there is room to sign.
		_c("Ivey", 9, P.FLANK_R, 71, 55, 47, 60, 45, 207, 0.74, false),
		_c("Coll", 10, P.RAIL_R, 66, 70, 46, 49, 53, 243, 0.80, false),
		_c("Nesbit", 11, P.CENTER, 47, 50, 63, 71, 40, 173, 0.68, false),
	]
	return MeleeClub.build(
		## DETROIT AND NOT CROSS TIMBERS. The map is real now and a club from an
		## invented town is a club with no distance to anywhere — which is the
		## one thing `Cities` exists to give it. The player renames this at the
		## picker before he sees it; what matters is that the default is
		## somewhere.
		"Detroit Free Company", "DFC",
		IconBank.KIT_COLORS[0], IconBank.MARK_COLORS[0], 7, cards)


## The opposition. Better on paper and built the other way round — a monster
## Center with light flanks. Beating them is a formation problem.
static func rival_club() -> MeleeClub:
	var cards: Array[FighterCard] = [
		_c("Halvard", 1, P.RAIL_L, 75, 77, 54, 55, 47, 263),
		_c("Brandt", 2, P.FLANK_L, 84, 66, 64, 60, 64, 220),
		_c("Oster", 3, P.CENTER, 75, 68, 79, 82, 57, 202),
		_c("Lund", 4, P.FLANK_R, 78, 60, 58, 65, 51, 212),
		_c("Petit", 5, P.RAIL_R, 73, 75, 57, 54, 50, 254),
		## A better bench than yours, man for man, which is most of why they are the
		## stronger club on paper and all of why they are stronger in a third round.
		_c("Renard", 6, P.RAIL_L, 74, 76, 56, 58, 51, 259),
		_c("Kolb", 7, P.FLANK_L, 82, 64, 60, 63, 60, 218),
		_c("Ferrier", 8, P.CENTER, 68, 64, 74, 79, 54, 195),
		## A full reserve as well as a better bench. They are not beating you with
		## five men, they are beating you with a club.
		_c("Aubry", 9, P.FLANK_R, 80, 63, 56, 61, 53, 216, 0.86, false),
		_c("Serre", 10, P.RAIL_R, 70, 73, 55, 56, 48, 248, 0.90, false),
		_c("Maury", 11, P.CENTER, 56, 56, 67, 74, 45, 182, 0.78, false),
		_c("Vasseur", 12, P.FLANK_L, 75, 58, 53, 64, 50, 212, 0.71, false),
	]
	return MeleeClub.build(
		"Iron Crown Companions", "ICC",
		IconBank.MARK_COLORS[1], IconBank.KIT_COLORS[3], 6, cards)


static func validate() -> String:
	for c in [player_club(), rival_club()]:
		var err: String = c.line_legal()
		if err != "":
			return err
	return ""


## THE CLUB YOU ACTUALLY START WITH — and it is not `player_club()`.
##
## The player club as written above is a BALANCE FIXTURE: it rates 65, which is
## State League strength, and starting the player with it in a division whose
## band is 30-46 meant he began the game as by far the best club in it. That was
## invisible while the league only sorted on a rating, and impossible to miss the
## moment the salary cap became a division's rule — a 65-rated squad bills fifty
## thousand dollars against a Backyard cap of two hundred.
##
## So the fixture stays exactly as it is, because twelve melee checks are
## measured on it, and the season starts you with a club that belongs in the
## division you start in. Built by ClubFactory like everybody else's, so your
## club and the twelve you are playing against come out of the same machine.
## WHAT THE CLUB YOU INHERIT IS RATED, and it was a bare 38 in the middle of a
## constructor call. Pete, 15 Sep 2026: *"promotion out of backyard by season
## 2"* — which is a statement about the distance between this number and the
## Backyard Circuit's leader, so it is a balance figure and it belongs where the
## sweep can find it. `tools/sweep_plan.py` reads `const` declarations; a literal
## buried in an argument list is a tunable no instrument can see.
## 38 -> 50 on 27 Sep 2026 (the 16 Sep pacing package said 48; re-measured
## after the audit fixes and the re-written market proxies, 48 gave a title at
## 12.1 on the five check bases and 50 gives 11.3): the club you inherit
## can compete in the division you inherit it in.
const START_POWER: int = 50


## THE STARTING CLUB WITH ITS FOUR AT HOME, for a check or a probe that needs a
## reserve to exist (a career begins with eight, 1 Oct 2026).
static func starting_club_with_reserve() -> MeleeClub:
	var c := ClubFactory.build(0, "Detroit Free Company", "DFC", START_POWER, true)
	c.kit = IconBank.KIT_COLORS[0]
	c.icon_color = IconBank.MARK_COLORS[0]
	c.icon = 7
	return c


static func starting_club() -> MeleeClub:
	var c := ClubFactory.build(0, "Detroit Free Company", "DFC", START_POWER, true)
	c.kit = IconBank.KIT_COLORS[0]
	c.icon_color = IconBank.MARK_COLORS[0]
	## Diamond, not the Saltire: a red X on the badge read as a close button
	## on four screens (blind review round 3, 30 Sep 2026).
	c.icon = 7
	## EIGHT MEN AND NOBODY BEHIND THEM (Pete, 1 Oct 2026: "Start with 8 fighters
	## only"). The four reserve places are filled from the free agents.
	var eight: Array[FighterCard] = []
	for f in c.roster:
		if f.active:
			eight.append(f)
	c.roster = eight
	return c
