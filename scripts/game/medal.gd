class_name Medal
extends RefCounted
## THE MEDALS (Pete, 11 Oct 2026: "Do we have a trophy room? Might be a good
## place to put a history and a medal"). Drawn in code like the club marks:
## a ribbon and a disc, gold for a cup won, silver for runners-up, bronze for
## third. The History page of the record book is the trophy room.

const GOLD := Color("f2d13c")
const SILVER := Color("c9ccd1")
const BRONZE := Color("c27a3a")
const RIBBON := Color("3c5a9a")


## 1 gold, 2 silver, 3 bronze, 0 none, from a stored finish ("runners-up").
static func place_of(finish: String) -> int:
	match finish.to_lower():
		"champions": return 1
		"runners-up": return 2
		"third": return 3
	return 0


## [gold, silver, bronze] across the honours list.
static func counts(honors: Array, player_club: int) -> Array:
	var out := [0, 0, 0]
	for e in honors:
		var p := 1 if int(e.get("champion", -1)) == player_club and player_club >= 0 \
			else place_of(String(e.get("player", "")))
		if p > 0:
			out[p - 1] += 1
	return out


static func draw(ci: CanvasItem, at: Vector2, r: float, place: int) -> void:
	var col: Color = [GOLD, SILVER, BRONZE][clampi(place, 1, 3) - 1]
	var rb := maxf(1.0, roundf(r * 0.45))
	ci.draw_rect(Rect2(at.x - r * 0.8, at.y - r * 1.9, rb, r * 1.2), RIBBON)
	ci.draw_rect(Rect2(at.x + r * 0.8 - rb, at.y - r * 1.9, rb, r * 1.2), RIBBON)
	ci.draw_circle(at, r, col.darkened(0.35))
	ci.draw_circle(at, r - maxf(1.0, roundf(r * 0.25)), col)
