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
		Kind.NEUTRAL: return UiKit.t("Tournament ground")
		## At home he knows the room by name, because he bought it.
		Kind.HOME: return UiKit.t("%s, %s") % [host_arena, host_city] if host_city != "" \
			else host_arena
		## Away he knows the town and nothing else, which is true of an away day:
		## you know you are going to Holt. "Their ground, Holt" was the first
		## version and it said the same thing twice.
		_: return host_city if host_city != "" else UiKit.t("Their ground")


## The one line under it that says whose afternoon this is.
static func mood_line(kind: int, host_name: String) -> String:
	match kind:
		Kind.HOME: return UiKit.t("Your crowd.")
		Kind.NEUTRAL: return UiKit.t("Nobody's ground.")
		_: return UiKit.t("%s's crowd.") % host_name


## ---------------------------------------------------------------- the gate
## WHAT SHARE OF THE GATE COMES TO YOU, by where the afternoon is.
##
## Pete, 15 Sep 2026: *"We can have more money gained from home games, and less
## from away games."*
##
## THIS USED TO BE A BOOLEAN AND THE BOOLEAN WAS THE PROBLEM. `pays_the_gate`
## returned true at home and false everywhere else, on the reasoning that *"a
## club that took its gate on the road would be a club with no reason to build an
## arena"*. The reasoning is sound and the implementation overshot it: away and
## neutral paying NOTHING meant that in a Backyard season of five events with one
## or two at home, the entire crowd economy — notoriety, the bands, the meter,
## the turnout percentage, five screens of apparatus — was worth **1.4 credits a
## season**. `tools/probe_year1.gd` printed it as a line of the club's books next
## to eight credits of membership subs, and a player reading that table would
## conclude, correctly, that fighting does not pay.
##
## `tools/probe_venue.gd` measured the real calendar at home 33%, away 37%,
## neutral 30% — the cup ties are neutral ground and they are nearly a third of
## the year. So two thirds of a club's fights paid nothing at all.
##
## A SHARE KEEPS THE ARENA WORTH BUILDING and fixes the hole, because the thing
## that makes your own ground worth money is no longer that it is the only fight
## that pays — it is that home pays FULL and the take is multiplied by the ground
## it is fought in. Build a better arena and every home fight is worth more; let
## it go and every home fight is worth less.
const HOME_SHARE: float = 1.00

## AWAY IS NOT HALF A HOME GAME BY ACCIDENT. A visiting club takes a cut of the
## door and its own travelling support through it; it does not take the bar, the
## programme or the retainer. Just under half is the number that makes an away
## day worth going to and still makes you want the home draw.
const AWAY_SHARE: float = 0.45

## AND NEUTRAL SITS ABOVE AWAY, because a cup tie on the federation's ground is a
## bigger afternoon than a Tuesday at somebody's club — both sides are visitors
## and the house is full of people who came for the occasion.
const NEUTRAL_SHARE: float = 0.60


static func gate_share(kind: int) -> float:
	match kind:
		Kind.HOME: return HOME_SHARE
		Kind.NEUTRAL: return NEUTRAL_SHARE
		_: return AWAY_SHARE


## Kept, because eleven places ask it and all of them still mean "is this my
## afternoon" rather than "is there money in it". It is now a question about the
## venue and not about the wallet.
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
		return UiKit.t("at home")
	if miles <= NEAR_MILES:
		return UiKit.t("%s — a local run") % Cities.distance_word(miles)
	if miles >= FAR_MILES:
		return UiKit.t("%s — the other end of the country") % Cities.distance_word(miles)
	return Cities.distance_word(miles)
