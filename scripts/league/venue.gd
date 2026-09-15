class_name Venue
extends RefCounted
## WHERE A BOUT IS FOUGHT, and what that is worth.
##
## PETE, 14 Sep 2026: *"we need to make arenas for home, away, and tournament
## games... It's actually fun running into these open spaces we didn't think
## about."*
##
## It was an open space in the exact sense that nothing was wrong — the game ran
## a full season without it. What it could not do was say where anybody was. Every
## event took the club's gate, every fixture read the same, and HOMESICK — *"a
## different man away from your own ground"* — had been sitting in the pending
## list for eight passes because the fixture list knew who played whom and not
## where.
##
## THREE KINDS, and they are three because they are three different afternoons:
##
##   HOME        your own arena, your own crowd, your gate
##   AWAY        their arena, their crowd, no gate for you
##   NEUTRAL     a cup or the Worlds — somebody else's ground, nobody's crowd
##
## THE CROWD IS THE ONLY THING THAT HANGS ON IT MECHANICALLY, plus Homesick.
## Pete's call, and it is the right one on the evidence: `grade.gd` measured a 4%
## opposition scale as a whole difficulty rung and `_rally` measured a room-wide
## multiplier at twelve points of win rate, so a "home advantage" multiplier in
## this sim would not be a nudge, it would be a handicap system nobody asked for.
## The crowd already has measured effects and a gate already has a number.

enum Kind { HOME, AWAY, NEUTRAL }

const NAME := {
	Kind.HOME: "Home",
	Kind.AWAY: "Away",
	Kind.NEUTRAL: "Neutral",
}

## The art slot each kind draws, and the reason the away and neutral grounds are
## single pieces rather than a ladder like the home arenas: the player builds his
## own arena through six tiers and looks at it all season, and he sees somebody
## else's for ninety seconds. Art budget goes where the eyes are.
const ART := {
	Kind.HOME: "",                      ## the club's own arena_0..5, by level
	Kind.AWAY: "venue_away",
	Kind.NEUTRAL: "venue_neutral",
}


## WHAT THE BANNER OVER THE SPLASH SAYS. The venue's own name where there is one
## — a club plays at a named ground, not at "Away".
static func title(kind: int, host_city: String, host_arena: String) -> String:
	match kind:
		## The tournament ground has no city — it is the federation's, and which
		## town it is in is not a thing the player has any relationship with.
		Kind.NEUTRAL: return "Tournament ground"
		## At home he knows the room by name, because he bought it.
		Kind.HOME: return "%s, %s" % [host_arena, host_city] if host_city != "" \
			else host_arena
		## Away he knows the town and nothing else, which is true of an away day:
		## you know you are going to Holt. "Their ground, Holt" was the first
		## version and it said the same thing twice.
		_: return host_city if host_city != "" else "Their ground"


## The one line under it that says whose afternoon this is.
static func mood_line(kind: int, host_name: String) -> String:
	match kind:
		Kind.HOME: return "Your crowd."
		Kind.NEUTRAL: return "Nobody's ground."
		_: return "%s's crowd." % host_name


## DOES THE GATE COME TO YOU? Only at home. A club that took its gate on the road
## would be a club with no reason to build an arena, which is the whole of the
## Arena screen.
static func pays_the_gate(kind: int) -> bool:
	return kind == Kind.HOME


## AND THE ONE TRAIT THAT READS IT — Homesick, and it is a RADIUS now rather
## than a flag.
##
## Pete, 14 Sep 2026: *"real US cities so they can have a radius with the
## 'homesick'."* The flat version was a 7% penalty whether the away day was
## ninety miles or two thousand, which is not what anybody means by homesick. The
## real thing is a sliding scale and now the map can express one.
##
##   under NEAR miles    nothing at all — this is a local derby
##   NEAR to FAR         the penalty comes on, straight-line
##   over FAR            the full trait, and no worse
##
## 120 miles is an afternoon in a van and 1,500 is a different part of the
## country; between them it is a scale. The cap exists because a man who is worse
## the further he goes with no floor is a man you cannot take to the Worlds, and
## the trait should make a club think about a squad, not forbid a fixture.
const NEAR_MILES: float = 120.0
const FAR_MILES: float = 1500.0


static func homesick_scale(card, kind: int, miles: float = FAR_MILES) -> float:
	if kind == Kind.HOME or card == null:
		return 1.0
	var full := FighterTrait.mod(card.trait_id, "away", 1.0)
	if is_equal_approx(full, 1.0):
		return 1.0
	var t := clampf((miles - NEAR_MILES) / (FAR_MILES - NEAR_MILES), 0.0, 1.0)
	return lerpf(1.0, full, t)


## What the screens say about the trip, for the man and for the club.
static func trip_word(miles: float) -> String:
	if miles < 1.0:
		return "at home"
	if miles <= NEAR_MILES:
		return "%s — a local run" % Cities.distance_word(miles)
	if miles >= FAR_MILES:
		return "%s — the other end of the country" % Cities.distance_word(miles)
	return Cities.distance_word(miles)
