class_name Coach
extends RefCounted
## YOU.
##
## Every other system in this game belongs to the club: the roster ages, the
## office banks credits, the arena fills. Nothing belonged to the person playing.
## Twenty seasons of a well-run club read as twenty seasons rather than as a
## career, because there was no thread running through them that was yours.
##
## This is that thread. A reputation other clubs can see, a lifetime record that
## follows you when you leave, and — the part that makes it a career rather than
## a scoreboard — **the fact that you can leave.**
##
## REPUTATION IS RETRO BOWL'S `coach_rating`, read out of the shipped build
## rather than invented, and its shape is the interesting half. It does not
## decay by a point a year. It is **additive on success and multiplicative on
## failure**:
##
## | | |
## |---|---|
## | won your division | **+4** |
## | second | **+3** |
## | third | **+2** |
## | fourth | +0 |
## | anywhere below that | **× 0.5** |
##
## and on a cup run, by how far you got:
##
## | | |
## |---|---|
## | out in the first round | **+3** |
## | out in the quarters | **+4** |
## | out in the semis | **+5** |
## | lost the final | **+6** |
## | **won it** | **+8** |
##
## Halving is what makes the number mean something. A coach who climbs for six
## seasons and then finishes mid-table does not slip one rung, he loses half of
## what he built — so a reputation of 18 is evidence of sustained work rather
## than of having once been good. It also means the climb back is fast, because
## the additive gains are large against a halved base. Failure is expensive and
## recoverable, which is the same shape the morale logistic has.
##
## Clamped 1-20, which is theirs too.
const REP_MIN: int = 1
const REP_MAX: int = 20

## By finishing position in your division, best first. Past the end of this list
## the multiplier below applies instead.
const REP_BY_PLACE: Array[int] = [4, 3, 2, 0]
const REP_UNPLACED: float = 0.5

## By how far a cup run went, keyed on the number of clubs left when you went
## out — which is the same key `Cup.ROUND_NAMES` uses, so the two cannot drift.
## 1 means you were the last club standing.
const REP_BY_CUP_EXIT := { 1: 8, 2: 6, 4: 5, 8: 4, 16: 3 }

var display_name: String = "Coach"
var reputation: int = 1

## THE CLUB YOU ARE AT, and the one you grew up on. They are different numbers
## and the difference is a whole mechanic: your boyhood club will not come for
## you before your third season, however good you are. The dream job is held
## back deliberately — offered in year one it is not a dream, it is a menu.
var club_id: int = -1
var favorite_club_id: int = -1
var years_here: int = 0

## THE BOOK THAT FOLLOWS YOU. Clubs are left behind; this is not.
var seasons: int = 0
var wins: int = 0
var draws: int = 0
var losses: int = 0
var cups: int = 0
var promotions: int = 0
var relegations: int = 0
## Every club you have taken, oldest first, as {club, season_joined, season_left}.
var posts: Array[Dictionary] = []


func fought() -> int:
	return wins + draws + losses


func win_rate() -> float:
	var n := fought()
	return 0.0 if n == 0 else float(wins) / float(n)


func record_line() -> String:
	return "%d-%d-%d" % [wins, draws, losses]


## THE WORDS FOR A REPUTATION, anchored on the four job-offer messages Retro
## Bowl writes for the same number — "making waves", "growing", "widely
## acknowledged", "the most highly sought after coach in the league" — so the
## word on the screen and the letter that arrives say the same thing about you.
func standing() -> String:
	if reputation >= 16:
		return UiKit.t("Sought after")
	if reputation >= 11:
		return UiKit.t("Widely known")
	if reputation >= 6:
		return UiKit.t("Making waves")
	return UiKit.t("Unknown")


## Which of the four letters arrives, as an index. Same four bands as the words
## above, read off the same number, because two ladders for one quantity is the
## bug this project keeps finding.
func offer_tone() -> int:
	if reputation >= 16:
		return 3
	if reputation >= 11:
		return 2
	if reputation >= 6:
		return 1
	return 0


const OFFER_BLURB: Array[String] = [
	"Your raw talent is making waves. A few clubs are interested in taking you on.",
	"Your reputation is growing. The following clubs would have you as their captain-manager.",
	"Your reputation is widely acknowledged, and a number of clubs want you.",
	"Your experience and knowledge of the sport make you the most sought-after name in the country.",
]


func offer_blurb() -> String:
	return UiKit.t(OFFER_BLURB[offer_tone()])


# ------------------------------------------------------------------ the season
## WHERE THE DIVISION LEAVES YOU. `place` is 1-based.
##
## `tier` scales a placed finish: winning the National Division is worth more to
## a coach's name than winning the Backyard Circuit (it paid the same). +1 a rung
## on any placed finish above nought.
func after_division(place: int, tier: int = 0) -> void:
	if place >= 1 and place <= REP_BY_PLACE.size():
		var pts: int = REP_BY_PLACE[place - 1]
		reputation += pts + (maxi(0, tier) if pts > 0 else 0)
	else:
		## The halving. Rounded rather than floored, so a 5 becomes a 3 and not a
		## 2 — theirs rounds, and at this scale the difference is a whole band.
		reputation = int(round(float(reputation) * REP_UNPLACED))
	_clamp()


## HOW FAR A CUP RUN WENT. `left_standing` is the size of the round you went out
## in — 2 for the final, 1 if you won the thing.
func after_cup(left_standing: int) -> void:
	if REP_BY_CUP_EXIT.has(left_standing):
		reputation += int(REP_BY_CUP_EXIT[left_standing])
	_clamp()


func _clamp() -> void:
	reputation = clampi(reputation, REP_MIN, REP_MAX)


func note_result(won: bool, drew: bool) -> void:
	if drew:
		draws += 1
	elif won:
		wins += 1
	else:
		losses += 1


func note_season(promoted: bool, relegated: bool, won_cup: bool) -> void:
	seasons += 1
	years_here += 1
	if promoted:
		promotions += 1
	if relegated:
		relegations += 1
	if won_cup:
		cups += 1


# ------------------------------------------------------------------- the move
## TAKING A NEW JOB. The record follows you; the years at the club do not.
func take_post(new_club_id: int, season_no: int) -> void:
	if club_id >= 0 and not posts.is_empty():
		posts[posts.size() - 1]["season_left"] = season_no
	posts.append({
		"club": new_club_id, "season_joined": season_no, "season_left": -1,
	})
	club_id = new_club_id
	years_here = 0


func to_dict() -> Dictionary:
	return {
		"name": display_name, "rep": reputation, "club": club_id,
		"fav": favorite_club_id, "here": years_here, "seasons": seasons,
		"w": wins, "d": draws, "l": losses, "cups": cups,
		"up": promotions, "down": relegations, "posts": posts.duplicate(true),
	}


static func from_dict(d: Dictionary) -> Coach:
	var c := Coach.new()
	c.display_name = String(d.get("name", "Coach"))
	c.reputation = int(d.get("rep", 1))
	c.club_id = int(d.get("club", -1))
	c.favorite_club_id = int(d.get("fav", -1))
	c.years_here = int(d.get("here", 0))
	c.seasons = int(d.get("seasons", 0))
	c.wins = int(d.get("w", 0))
	c.draws = int(d.get("d", 0))
	c.losses = int(d.get("l", 0))
	c.cups = int(d.get("cups", 0))
	c.promotions = int(d.get("up", 0))
	c.relegations = int(d.get("down", 0))
	var p: Array = d.get("posts", [])
	for entry in p:
		c.posts.append(entry as Dictionary)
	return c
