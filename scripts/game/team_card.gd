class_name TeamCard
extends RefCounted
## EVERY CLUB, FOUR WAYS, OUT OF FIVE STARS. Pete, 1 Oct 2026: *"Remove scouting
## and just give each team a 4 category 5star system. Then if you click them or
## prior to fights, fight cards, you'll see info like the star ratings, overalls
## and W/L."*
##
## The four are the four a man is made of — Strength, Base, Skill, Gas — read
## off the club's five, on the game's one 1-99 scale, so a Backyard club and a
## European guest at the Kings Cup are stars on the same ruler. `UiKit.stars`
## draws ten points to a half star.
##
## Shown in three places: tap a club in the league table, the calendar's
## fixture popup, and the walk-out before every bout.

const CATS := ["strength", "base", "skill", "gas"]


static func cat_name(i: int) -> String:
	match i:
		0: return UiKit.t("Strength")
		1: return UiKit.t("Base")
		2: return UiKit.t("Skill")
	return UiKit.t("Gas")


## The four averages of a club's five, 1-99.
static func ratings(club: MeleeClub) -> Array[int]:
	var out: Array[int] = [0, 0, 0, 0]
	if club == null:
		return out
	var five: Array = club.starting_five()
	if five.is_empty():
		five = club.roster
	if five.is_empty():
		return out
	var sums := [0, 0, 0, 0]
	for f in five:
		sums[0] += int(f.strength)
		sums[1] += int(f.base)
		sums[2] += int(f.skill)
		sums[3] += int(f.gas)
	for i in 4:
		out[i] = int(round(float(sums[i]) / float(five.size())))
	return out


## The block: four rows, name and stars and the number. `cols` 1 or 2.
## Returns the height used.
static func draw_stars(ci: CanvasItem, font: Font, at: Vector2, club: MeleeClub,
		cols: int = 1, col_w: float = 200.0, px: int = 13) -> float:
	var r := ratings(club)
	var row_h := 22.0
	## THE STARS START AFTER THE LONGEST NAME, measured: "Strength" in a wide
	## language runs past any fixed stop.
	var lw := 0.0
	for i in 4:
		lw = maxf(lw, font.get_string_size(cat_name(i), HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x)
	lw += 8.0
	for i in 4:
		var cx := at.x + float(i % cols) * col_w
		var cy := at.y + float(i / cols) * row_h
		UiKit.text(ci, font, cat_name(i), Vector2(cx, cy), px, UiKit.DIM)
		UiKit.stars(ci, Vector2(cx + lw, cy - 9.0), r[i], UiKit.YOU, 11.0, 3.0)
		UiKit.text(ci, font, "%d" % r[i], Vector2(cx + lw + 5.0 * 11.0 + 6.0, cy), px, UiKit.INK)
	return float(int(ceil(4.0 / float(cols)))) * row_h


## THE CARD: who, where, how they stand, and the four. For a popup.
static func draw(ci: CanvasItem, font: Font, r: Rect2, s: Season, id: int) -> void:
	UiKit.panel(ci, r)
	var c: Dictionary = s.world.clubs[id]
	var club := s.club_for(id)
	var x := r.position.x + 24.0
	var y := r.position.y + 36.0
	UiKit.text_fit(ci, font, String(c["name"]).to_upper(), Vector2(x, y), 20, UiKit.YOU, r.size.x - 48.0)
	y += 24.0
	var t := int(c.get("tier", -1))
	var where := Cities.full_name(s.world.city_of(id))
	var div := League.tier_name(t) if t >= 0 else UiKit.t("From abroad")
	UiKit.text_fit(ci, font, UiKit.t("%s  ·  %s") % [div, where], Vector2(x, y), 13, UiKit.DIM, r.size.x - 48.0)
	y += 30.0
	UiKit.text(ci, font, UiKit.t("Rating %d") % int(c["power"]), Vector2(x, y), 16, UiKit.INK)
	if t >= 0:
		var rec := s.world.record_of(id)
		var pos := -1
		var rows := s.world.table(t)
		for i in rows.size():
			if int(rows[i]["club"]) == id:
				pos = i + 1
		UiKit.text_fit(ci, font, UiKit.t("%s in the table  ·  won %d, drew %d, lost %d") % [UiKit.ordinal(pos),
			int(rec["won"]), int(rec["drawn"]), int(rec["lost"])], Vector2(x + 150.0, y), 14, UiKit.INK,
			r.size.x - 48.0 - 150.0)
	y += 34.0
	draw_stars(ci, font, Vector2(x, y), club, 2, 230.0, 14)
