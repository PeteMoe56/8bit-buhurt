class_name Jobs
extends RefCounted
## WHO WANTS YOU, and the arithmetic behind it.
##
## Retro Bowl's `s_team_interested` is four lines long and every one of them is
## doing work, so this is a translation rather than a design:
##
##   if team is the one you already have        -> no
##   if your rating is below the club's rating  -> no
##   if it is your boyhood club and year < 3    -> no
##   seed on (year + rating + club id); 1 in 4  -> no
##   otherwise                                  -> yes
##
## THE SECOND LINE IS THE WHOLE SYSTEM. You are offered clubs you OUT-RATE, which
## means the offer list is a ladder you climb rather than a lottery you enter,
## and a coach at reputation 20 is looking at the top of the country while a
## coach at 6 is looking at somebody else's mid-table. It also means a bad season
## — which halves the reputation — visibly shortens the list, without a single
## line of code about punishment.
##
## THE THIRD IS THE ONE I WOULD NOT HAVE WRITTEN. Your boyhood club is barred
## until your third season no matter how good you are. Offered in year one, the
## dream job is not a dream, it is a menu item. Held back three years, it is the
## thing you are playing toward.
##
## THE FOURTH KEEPS IT FROM BEING A CHECKLIST. One in four eligible clubs simply
## does not call, seeded so the list does not reshuffle while you look at it.
const DREAM_HELD_UNTIL_SEASON: int = 3
const ONE_IN: int = 4


## A CLUB'S RATING ON THE COACH'S OWN SCALE.
##
## Theirs compares `coach_rating` against `offense + defense`, both of which are
## already 1-20 quantities — the two numbers are in the same units and the
## comparison is direct. Ours are not: club power runs on the same 30-99 scale as
## a fighter's rating and reputation runs 1-20.
##
## So power is mapped onto the reputation scale using the PYRAMID'S OWN BOUNDS —
## the bottom of the weakest division to the top of the strongest — rather than
## against a pair of constants written here. The bands are tuning data and they
## have already moved once; a literal would have been wrong the next time they do.
static func standing_of(power: int) -> int:
	var lo: int = int((League.TIERS[0]["power"] as Array)[0])
	var hi: int = int((League.TIERS[League.TIERS.size() - 1]["power"] as Array)[1])
	if hi <= lo:
		return Coach.REP_MIN
	var t := float(power - lo) / float(hi - lo)
	return clampi(int(round(t * float(Coach.REP_MAX - Coach.REP_MIN))) + Coach.REP_MIN,
		Coach.REP_MIN, Coach.REP_MAX)


## Is this club interested in you? One rule, one place — the screen that lists
## the offers and any check that counts them must not each decide separately.
static func interested(coach: Coach, world, club_id: int) -> bool:
	if club_id == coach.club_id:
		return false
	var club: Dictionary = world.clubs[club_id]
	## A WORLDS GUEST IS NOT A CLUB YOU CAN RUN. Guests are tier -1 and live only
	## for one tournament — taking one put `player_tier()` at -1 and every table
	## lookup after it off the end of the pyramid.
	if bool(club.get("guest", false)) or int(club.get("tier", 0)) < 0:
		return false
	if coach.reputation < standing_of(int(club["power"])):
		return false
	if club_id == coach.favorite_club_id and world.season < DREAM_HELD_UNTIL_SEASON:
		return false
	## Seeded on the three things that make this offer this offer, so it is the
	## same answer every time the screen is drawn and a different answer next year.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("job:%d:%d:%d" % [world.season, coach.reputation, club_id])
	return rng.randi_range(0, ONE_IN - 1) != 0


## Everybody who wants you, best club first — because the list is a ladder and
## the top of it is the point of reading it.
static func offers(coach: Coach, world) -> Array[int]:
	var out: Array[int] = []
	for c in world.clubs:
		if interested(coach, world, int(c["id"])):
			out.append(int(c["id"]))
	out.sort_custom(func(a, b):
		return int(world.clubs[a]["power"]) > int(world.clubs[b]["power"]))
	return out
