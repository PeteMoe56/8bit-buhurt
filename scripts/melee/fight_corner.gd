class_name FightCorner
## THE CORNER (Pete, 2 Oct 2026: "start with E for both"). Every choice in a
## fight is made in one place: a quarter-wheel in the bottom corner, under the
## thumb. Three sides, one per act, the same three places every time.
##
## It has four states, and they are told apart by more than words:
##   wheel    a man YOU sent has reached an enemy. The fight stops; the hub is
##            Cancel. Blue sides.
##   bar      a man meets an enemy without your order (on his own, on a play).
##            The fight keeps running; his own pick is outlined in gold and the
##            gold band on the outer edge is his clock, draining.
##   waiting  he is clinched and not ready to act. Rust sides, darkened; the
##            band FILLS grey; CLINCHED over the pair.
##   ready    clinched and ready: the rust sides light up, his pick outlined.
## The mockups are the "Contact wheel options" artifact (option E).
##
## `Settings.fight_hand` mirrors it. `Settings.fight_controls == "classic"`
## turns it off and the guard triangle and the boxes over the man come back.

const RI := 126.0          ## the hub's edge; the sides start here (room for its words)
const RO := 300.0          ## the sides' outer edge: 174 px of thumb, room for the words (2 Oct)
const BAND := 10.0         ## the clock on the outer edge
const SPAN := 30.0         ## each side, in degrees
## WHAT EACH SIDE SAYS, from the outside in (Pete, 10 Oct 2026: "Bullrush, Hit,
## Break should be the biggest words there and the fall/chance/balance should be
## smaller. No explainers. Just put percentages closest to the dial center."):
##   the act's NAME, biggest, on the outside;
##   Hit's balance dent under it (the only side with a second number);
##   the act's ICON;
##   the CHANCE nearest the hub, with Bullrush's fall beside it in red, or
##   Break's "Free Teammate".
## Each line steps its size down until it fits its arc; `test_corner` holds every
## language at or above the floors below.
const NAME_R := 272.0
const SUB_R := 246.0
const MARK_R := 216.0
const CHANCE_R := 172.0
const NAME_PX := 24
const SUB_PX := 14
const CHANCE_PX := 17
const NAME_MIN := 18
const SUB_MIN := 11
const CHANCE_MIN := 13
## How much of a side's arc its words may fill before they step down a size.
const ARC_FILL := 0.86

const RUST := Color("7a3b2a")
const RUST_EDGE := Color("c0623f")
const RUST_DARK := Color("3f241b")
const RUST_HUB := Color("3a1f17")
const RED_SOFT := Color("ff9b84")


static func on() -> bool:
	return Settings.fight_controls == "corner"


static func right() -> bool:
	return Settings.fight_hand != "left"


## The corner itself, in the scene's frame: the device's own corner, so on a
## wide phone it sits in the gutter rather than over the fight.
static func point(v) -> Vector2:
	var y: float = v.SCREEN.y + v.off_y
	return Vector2(v.SCREEN.x + v.off_x, y) if right() else Vector2(-v.off_x, y)


## Side `i`'s span in degrees clockwise from up. Side 0 lies along the floor,
## side 2 stands up the wall, in either hand.
static func span(i: int) -> Vector2:
	return span_hand(i, right())


static func quadrant() -> Vector2:
	return Vector2(270.0, 360.0) if right() else Vector2(0.0, 90.0)


static func _pt(c: Vector2, r: float, deg: float) -> Vector2:
	var a := deg_to_rad(deg - 90.0)
	return c + Vector2(cos(a), sin(a)) * r


static func _ring(c: Vector2, ri: float, ro: float, a0: float, a1: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var steps := maxi(4, int((a1 - a0) / 3.0))
	for k in steps + 1:
		pts.append(_pt(c, ro, a0 + (a1 - a0) * float(k) / float(steps)))
	for k in steps + 1:
		var a := a1 - (a1 - a0) * float(k) / float(steps)
		pts.append(c if ri <= 0.0 else _pt(c, ri, a))
	return pts


## What is under `p`: a side index 0-2, -1 for the hub, -2 for neither.
static func hit(v, p: Vector2) -> int:
	var c: Vector2 = point(v)
	var d: Vector2 = p - c
	var r: float = d.length()
	if r > RO + BAND:
		return -2
	if r < RI - 4.0:
		return -1
	var ang: float = fposmod(rad_to_deg(atan2(d.y, d.x)) + 90.0, 360.0)
	var q: Vector2 = quadrant()
	## The quadrant's edges, plus a few degrees of slack for a thumb at the floor or wall.
	if right():
		if ang < q.x - 6.0 and ang > 180.0:
			return -2
		if ang < 180.0 and ang > 6.0:
			return -2
		if ang <= 6.0:
			ang = 359.9
		ang = clampf(ang, q.x, q.y - 0.01)
	else:
		if ang > q.y + 6.0 and ang < 180.0:
			return -2
		if ang >= 180.0 and ang < 354.0:
			return -2
		if ang >= 354.0:
			ang = 0.0
		ang = clampf(ang, q.x, q.y - 0.01)
	for i in 3:
		var s: Vector2 = span(i)
		if ang >= s.x and ang < s.y:
			return i
	return -2


# ------------------------------------------------------------ whose choice
## THE MAN THE CORNER IS ASKING ABOUT, while the fight runs. Every man of ours
## with an open, unanswered question joins a queue in the order it opened; the
## corner shows the newest, and a tap on the hub moves to the next.
static func bar_man(v) -> int:
	if v.skipping or v.screen != v.Screen.FIGHT or v.wheel_man != -1:
		return -1
	var order: Array = v.corner_order
	var live: Array = []
	for i in order:
		if _asking(v, int(i)):
			live.append(int(i))
	for m in v.sim.men:
		if not live.has(m.idx) and _asking(v, m.idx):
			live.append(m.idx)
	v.corner_order = live
	if live.is_empty():
		return -1
	if live.has(int(v.corner_pick)):
		return int(v.corner_pick)
	return int(live.back())


static func _asking(v, idx: int) -> bool:
	var m = v.sim.men[idx]
	return m.team == 0 and m.prompt != null and not m.prompt.by_player and m.standing()


## A TICK UNDER THE THUMB (Pete, 2 Oct 2026): a short buzz when a side takes,
## a longer one when it is refused. The thumb is over the corner, so the hand
## is where the answer has to land. Phones only; nothing anywhere else.
const BUZZ_OK := 18
const BUZZ_NO := 70


static func buzz(ok: bool) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(BUZZ_OK if ok else BUZZ_NO)


static func next_man(v) -> void:
	var live: Array = v.corner_order
	if live.size() < 2:
		return
	var cur: int = bar_man(v)
	v.corner_pick = live[(live.find(cur) + 1) % live.size()]


## A tap while the fight runs. True if the corner took it.
static func press_bar(v, p: Vector2) -> bool:
	var idx: int = bar_man(v)
	if idx == -1:
		return false
	var h: int = hit(v, p)
	if h == -2:
		return false
	if h == -1:
		next_man(v)
		Audio.play("tap")
		return true
	var m = v.sim.men[idx]
	var acts: Array = Tuning.acts_for(m.prompt.menu)
	if v.sim.answer_prompt(idx, acts[h]):
		Audio.play("tap")
		buzz(true)
		v.corner_pick = -1
	else:
		## Not yet (a clinch still getting ready, a takedown on a steady man):
		## the same refusal every other "no" in the game makes.
		Audio.play("refuse")
		buzz(false)
	return true


# ------------------------------------------------------------ the words
## What one act's side shows: `p` the chance (< 0 for none), `fall` Bullrush's
## fall (< 0 for none), `sub` a small line under the name, `inner` words in the
## chance's place. The wheel's own numbers, from the sim.
static func read(v, m, act: int) -> Dictionary:
	var t = v.sim.men[m.prompt.target]
	var o: Dictionary = v.sim.contact_odds(m.idx, act, t.idx)
	var out: Dictionary = {"p": float(o["p"]), "fall": -1.0, "sub": "", "sub_col": UiKit.INK, "inner": ""}
	match act:
		Tuning.Act.HIT:
			out["p"] = 1.0
			out["sub"] = UiKit.t("-%d%% balance") % int(round(float(o["dent"]) * 100.0))
		Tuning.Act.GRAPPLE:
			out["p"] = 1.0
			out["sub"] = UiKit.t("takedown %d%%") % int(round(float(o["p"]) * 100.0))
		Tuning.Act.BREAK:
			out["p"] = -1.0
			out["inner"] = UiKit.t("Free Teammate")
		Tuning.Act.HOLD, Tuning.Act.ESCAPE:
			out["p"] = -1.0
		Tuning.Act.BULLRUSH:
			if float(o["fall"]) > 0.0:
				out["fall"] = float(o["fall"])
		Tuning.Act.TAKEDOWN:
			if m.prompt.menu == Tuning.Menu.GRAPPLED and Tuning.td_gate > 0.0 and t.stability > Tuning.td_gate:
				out["sub"] = UiKit.t("he holds firm")
				out["sub_col"] = RED_SOFT
	return out


# ------------------------------------------------------------ drawing
static func draw(v) -> void:
	if v.wheel_man != -1:
		_draw_corner(v, v.sim.men[v.wheel_man], "wheel")
		return
	var idx: int = bar_man(v)
	## The others waiting their turn get a small mark over them.
	for i in v.corner_order:
		if int(i) != idx:
			_mark(v, v.sim.men[int(i)], false)
	if idx == -1:
		return
	var m = v.sim.men[idx]
	var kind: String = "bar"
	if m.prompt.menu == Tuning.Menu.GRAPPLED:
		kind = "ready" if v.sim.clinch_ready(m) else "waiting"
	_draw_corner(v, m, kind)


## WHO IT IS FOR, on the field: his number over him in gold, or the clinch
## named over the pair in rust.
static func _mark(v, m, main: bool) -> void:
	var p: Vector2 = v._to_screen(m.pos)
	if m.prompt != null and m.prompt.menu == Tuning.Menu.GRAPPLED:
		var t = v.sim.men[m.prompt.target]
		var tp: Vector2 = v._to_screen(t.pos)
		v.draw_line(p, tp, RUST_EDGE, 4.0)
		if main:
			var mid: Vector2 = (p + tp) * 0.5
			var w: float = 92.0
			var r: Rect2 = Rect2(mid + Vector2(-w * 0.5, -54.0), Vector2(w, 22.0))
			v.draw_rect(r, RUST)
			v.draw_rect(r, RUST_EDGE, false, 2.0)
			UiKit.icon(v, "lock", r.position + Vector2(4, 3), UiKit.INK, 1)
			UiKit.mid(v, v.font, UiKit.t("CLINCHED"), r.position + Vector2(20, 16), 12, UiKit.INK, w - 22.0)
		return
	var col: Color = UiKit.YOU if main else Color(UiKit.YOU, 0.5)
	var tip: Vector2 = p + Vector2(0, -26.0)
	v.draw_colored_polygon(PackedVector2Array([tip + Vector2(-8, -10), tip + Vector2(8, -10), tip]), col)
	if main:
		UiKit.mid(v, v.font, UiKit.t("#%d") % _number(m), tip + Vector2(-20, -14), 13, UiKit.YOU, 40.0)


static func _number(m) -> int:
	return m.card.number if m.card != null else m.idx + 1


static func _draw_corner(v, m, kind: String) -> void:
	var c: Vector2 = point(v)
	var clinch := kind == "waiting" or kind == "ready"
	var waiting := kind == "waiting"
	var acts: Array = Tuning.acts_for(m.prompt.menu)
	if kind == "wheel":
		## The fight stopped: the dimmer, and the two men ringed — gold for
		## ours, red for his — with nothing drawn over either of them.
		v.draw_rect(Rect2(Vector2(-v.off_x, -v.off_y), UiKit.screen()), Color(0, 0, 0, 0.45))
		var t = v.sim.men[m.prompt.target]
		var up: Vector2 = v._to_screen(m.pos)
		var tp: Vector2 = v._to_screen(t.pos)
		v.draw_line(up, tp, v.COL_HOT, 2.0)
		v.draw_arc(up, 18.0, 0.0, TAU, 24, UiKit.YOU, 2.0)
		v.draw_arc(tp, 18.0, 0.0, TAU, 24, v.COL_HOT, 2.0)
	else:
		_mark(v, m, true)
	var fill: Color = RUST if clinch else UiKit.SELECT
	var edge: Color = RUST_EDGE if clinch else DIM
	var pick: int = m.prompt.choice if kind != "wheel" else -99
	var rows: Array = []
	for act in acts:
		var r: Dictionary = read(v, m, int(act))
		r["act"] = int(act)
		rows.append(r)
	draw_sides(v, c, rows, right(), fill, edge, waiting, pick, v.wheel_hot if kind == "wheel" else -99)
	## THE CLOCK, on the outer edge: draining while he can be overruled, filling
	## grey while a clinched man gets ready.
	var q: Vector2 = quadrant()
	if kind == "bar":
		## Against the clock it was OPENED with — READER's is longer (3 Oct 2026).
		var frac: float = clampf(m.prompt.t / maxf(0.01, m.prompt.dur), 0.0, 1.0)
		var a1: float = q.x + 90.0 * frac if right() else q.y
		var a0: float = q.x if right() else q.y - 90.0 * frac
		if frac > 0.0:
			v.draw_colored_polygon(_ring(c, RO + 3.0, RO + BAND, a0, a1), UiKit.YOU)
	elif waiting:
		var fill_f: float = clampf(1.0 - m.next_act / float(Tuning.ACT_CLINCH[1]), 0.0, 1.0)
		v.draw_colored_polygon(_ring(c, RO + 3.0, RO + BAND, q.x, q.y), Color(0, 0, 0, 0.5))
		if fill_f > 0.0:
			var b0: float = q.x if right() else q.y - 90.0 * fill_f
			var b1: float = q.x + 90.0 * fill_f if right() else q.y
			v.draw_colored_polygon(_ring(c, RO + 3.0, RO + BAND, b0, b1), v.COL_DIM)
	## THE SCORE IT COVERS (Screen Score #1, S25-2, Codex; Pete approved 8 Oct
	## 2026). The open wheel sits over the far side's STANDING and DOWNS and the
	## last fighter cards, so with the fight stopped the count you are deciding
	## against was hidden. A chip just above the wheel says it again, both sides.
	if kind == "wheel":
		var a = v.sim.clubs[0]
		var b = v.sim.clubs[1]
		var line := UiKit.t("%s %d · %s %d standing") % [a.short_name, v.sim.standing_count(0),
			b.short_name, v.sim.standing_count(1)]
		var cw: float = v.font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 16.0
		var cx0: float = (c.x - RO) if right() else (c.x + RO - cw)
		var chip := Rect2(cx0, c.y - RO - 30.0, cw, 24.0)
		v.draw_rect(chip, v.COL_PANEL)
		v.draw_rect(chip, v.COL_EDGE, false, 2.0)
		UiKit.raw(v, v.font, chip.position + Vector2(8.0, 17.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UiKit.INK)
	## THE HUB says what this is.
	var hub_hot: bool = kind == "wheel" and v.wheel_hot == -1
	v.draw_colored_polygon(_ring(c, 0.0, RI - 6.0, q.x, q.y),
		UiKit.YOU if hub_hot else (RUST_HUB if clinch else v.COL_PANEL))
	## The hub's words in a box its curve clears: 100 wide, 6 off the wall.
	var hx: float = c.x - 56.0 if right() else c.x + 56.0
	var box: Rect2 = Rect2(hx - 50.0, c.y - 80.0, 100.0, 80.0)
	if kind == "wheel":
		UiKit.mid(v, v.font, UiKit.t("Cancel"), Vector2(box.position.x, c.y - 34.0), 15, UiKit.BG if hub_hot else UiKit.INK, box.size.x)
	elif kind == "bar":
		UiKit.mid(v, v.font, UiKit.t("#%d") % _number(m), Vector2(box.position.x, c.y - 58.0), 16, UiKit.YOU, box.size.x)
		UiKit.mid(v, v.font, UiKit.t("his pick"), Vector2(box.position.x, c.y - 42.0), 12, v.COL_DIM, box.size.x)
		UiKit.mid(v, v.font, Tuning.act_name(m.prompt.choice), Vector2(box.position.x, c.y - 27.0), 13, UiKit.INK, box.size.x)
	else:
		UiKit.icon(v, "lock", Vector2(hx - 8.0, c.y - 78.0), UiKit.INK, 1)
		UiKit.mid(v, v.font, UiKit.t("CLINCH"), Vector2(box.position.x, c.y - 42.0), 14, UiKit.INK, box.size.x)
		UiKit.mid(v, v.font, UiKit.t("not ready") if waiting else UiKit.t("act now"),
			Vector2(box.position.x, c.y - 27.0), 12, v.COL_DIM if waiting else UiKit.YOU, box.size.x)
	## MORE THAN ONE MAN ASKING: how many, and that the hub moves between them.
	if kind != "wheel" and v.corner_order.size() > 1:
		UiKit.mid(v, v.font, UiKit.t("+%d · tap here") % (v.corner_order.size() - 1),
			Vector2(box.position.x, c.y - 12.0), 12, UiKit.YOU, box.size.x)


## THE THREE SIDES AND THEIR WORDS, for the fight and for the Guide alike (Pete,
## 10 Oct 2026: "why can't the wheel just be created the same as in game so it
## doesn't have to be a screenshot?"). `rows` is one Dictionary per side, in
## order, as `read` makes them plus "act". `rh` is the hand; `pick` the act
## outlined in gold, `hot` the one under the thumb (-99 for none).
static func draw_sides(v, c: Vector2, rows: Array, rh: bool, fill: Color, edge: Color,
		waiting: bool, pick: int, hot_act: int) -> void:
	## TWO PASSES: every side first, then every side's words, so no side's
	## edge is drawn through its neighbour's words.
	for i in rows.size():
		var act: int = int(rows[i]["act"])
		var s: Vector2 = span_hand(i, rh)
		var hot: bool = act == hot_act
		var pts: PackedVector2Array = _ring(c, RI, RO, s.x + 0.6, s.y - 0.6)
		var body: Color = RUST_DARK if waiting else (UiKit.YOU if hot else fill)
		v.draw_colored_polygon(pts, body)
		var outline: PackedVector2Array = pts.duplicate()
		outline.append(pts[0])
		v.draw_polyline(outline, edge, 2.0)
	## The gold outline of his pick over the plain edges, so it is whole.
	for i in rows.size():
		if int(rows[i]["act"]) == pick and not waiting:
			var s2: Vector2 = span_hand(i, rh)
			var lit_pts: PackedVector2Array = _ring(c, RI, RO, s2.x + 0.6, s2.y - 0.6)
			lit_pts.append(lit_pts[0])
			v.draw_polyline(lit_pts, UiKit.YOU, 4.0)
	for i in rows.size():
		var r: Dictionary = rows[i]
		var act: int = int(r["act"])
		var s: Vector2 = span_hand(i, rh)
		var hot: bool = act == hot_act
		var lit: bool = act == pick and not waiting
		var ink: Color = DIM if waiting else (UiKit.BG if hot else UiKit.INK)
		var mid_a := (s.x + s.y) * 0.5
		var dim: bool = waiting
		## THE WORDS FOLLOW THE SIDE (Pete, 2 Oct 2026), curved along its arc.
		arc_text(v, Tuning.act_name(act), c, NAME_R, mid_a, NAME_PX, ink)
		if String(r["sub"]) != "":
			arc_text(v, String(r["sub"]), c, SUB_R, mid_a, SUB_PX, DIM if dim else r["sub_col"])
		var ip := _pt(c, MARK_R, mid_a)
		UiKit.icon(v, act_mark(act), ip - Vector2(16, 16), UiKit.YOU if lit else ink, 2)
		var parts: Array = []
		if float(r["p"]) >= 0.0:
			parts.append(["%d%%" % int(round(float(r["p"]) * 100.0)),
				DIM if dim else odds_col(float(r["p"]))])
		if float(r["fall"]) > 0.0:
			parts.append(["/", DIM])
			parts.append(["%d%%" % int(round(float(r["fall"]) * 100.0)), DIM if dim else RED_SOFT])
		if not parts.is_empty():
			arc_parts(v, parts, c, CHANCE_R, mid_a, CHANCE_PX)
		if String(r["inner"]) != "":
			inner_text(v, String(r["inner"]), c, mid_a, DIM if dim else ink)


## The wheel's quiet colour (the fight screen's COL_DIM).
const DIM := Color("a59c8b")


## Side `i`'s span for a given hand (see `span`).
static func span_hand(i: int, rh: bool) -> Vector2:
	if rh:
		return Vector2(270.0 + SPAN * i, 300.0 + SPAN * i)
	return Vector2(90.0 - SPAN * (i + 1), 90.0 - SPAN * i)


## EACH MARK READS AS ITS WORD (review round 3: the round shield read as a
## target, and a padlock as anything but a clinch).
static func act_mark(act: int) -> String:
	match act:
		Tuning.Act.BULLRUSH: return "shield"
		Tuning.Act.GRAPPLE: return "fist"
		Tuning.Act.HIT: return "sword"
		Tuning.Act.TAKEDOWN: return "down"
		Tuning.Act.HOLD: return "lock"
		Tuning.Act.ESCAPE: return "boot"
		Tuning.Act.BREAK: return "gate"
	return "cursor"


## A chance's colour: green when likely, gold in the middle, red for a long shot
## (round 8: 5% in white read as neutral).
static func odds_col(p: float) -> Color:
	if p >= 0.6:
		return UiKit.UP
	if p >= 0.35:
		return UiKit.YOU
	return UiKit.DOWN.lightened(0.2)


## The size a line is drawn at on its arc: the asked size, stepped down until it
## fits the side. Public so `test_wheel` can hold every language to the floors.
static func arc_room(r: float) -> float:
	return deg_to_rad(SPAN) * r * ARC_FILL


static func arc_px(font: Font, text: String, r: float, size: int) -> int:
	var px := size
	while px > 9 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > arc_room(r):
		px -= 1
	return px


## TEXT ALONG AN ARC, centred on `mid_deg` (degrees clockwise from up), reading
## clockwise with its tops facing out of the corner. It steps its size down
## (to 11) until it fits the side; past that it is cut, and a side's words are
## kept short enough that it never is in any language we ship.
static func arc_text(v, text: String, c: Vector2, r: float, mid_deg: float, size: int, col: Color) -> void:
	var font: Font = v.font
	var px := arc_px(font, text, r, size)
	var w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var a := deg_to_rad(mid_deg - 90.0) - (w * 0.5) / r
	for ch in text:
		var cw: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var t := a + (cw * 0.5) / r
		var at := c + Vector2(cos(t), sin(t)) * r
		v.draw_set_transform(at, t + PI * 0.5, Vector2.ONE)
		v.draw_string(font, Vector2(-cw * 0.5, px * 0.35), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
		a += cw / r
	v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Words in the chance's place (Break's "Free Teammate"). One line if it fits at
## the chance's floor, otherwise split at its first space onto two arcs.
static func inner_lines(font: Font, text: String) -> Array:
	if arc_px(font, text, CHANCE_R, SUB_PX) >= CHANCE_MIN or not text.contains(" "):
		return [text]
	var k := text.find(" ")
	return [text.substr(0, k), text.substr(k + 1)]


static func inner_text(v, text: String, c: Vector2, mid_deg: float, col: Color) -> void:
	var lines := inner_lines(v.font, text)
	if lines.size() == 1:
		arc_text(v, text, c, CHANCE_R, mid_deg, SUB_PX, col)
		return
	arc_text(v, String(lines[0]), c, CHANCE_R + 9.0, mid_deg, SUB_PX, col)
	arc_text(v, String(lines[1]), c, CHANCE_R - 9.0, mid_deg, SUB_PX, col)


## Several pieces along one arc, each its own colour, sized together as one line.
static func arc_parts(v, parts: Array, c: Vector2, r: float, mid_deg: float, size: int) -> void:
	var font: Font = v.font
	var whole := ""
	for pc in parts:
		whole += String(pc[0])
	var px := arc_px(font, whole, r, size)
	var w: float = font.get_string_size(whole, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var a := deg_to_rad(mid_deg - 90.0) - (w * 0.5) / r
	for pc in parts:
		for ch in String(pc[0]):
			var cw: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
			var t := a + (cw * 0.5) / r
			var at := c + Vector2(cos(t), sin(t)) * r
			v.draw_set_transform(at, t + PI * 0.5, Vector2.ONE)
			v.draw_string(font, Vector2(-cw * 0.5, px * 0.35), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, px, pc[1])
			a += cw / r
	v.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
