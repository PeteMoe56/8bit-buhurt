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
## Where each line of a side's words runs, from the corner (outermost first).
const NAME_R := 272.0
const CHANCE_R := 248.0
const EFFECT_R := 226.0
const MARK_R := 176.0
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
	if right():
		return Vector2(270.0 + SPAN * i, 300.0 + SPAN * i)
	return Vector2(90.0 - SPAN * (i + 1), 90.0 - SPAN * i)


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
## What one act will do, for its side: the chance it lands and what it does.
## `p` < 0 means no chance to show. The wheel's own numbers, from the sim.
static func read(v, m, act: int) -> Dictionary:
	var t = v.sim.men[m.prompt.target]
	var o: Dictionary = v.sim.contact_odds(m.idx, act, t.idx)
	var out: Dictionary = {"p": float(o["p"]), "effect": UiKit.t("puts him down"), "col": UiKit.INK}
	match act:
		Tuning.Act.HIT:
			out["p"] = 1.0
			## Shorter than the wheel's "his balance -9%": a side is 30 degrees wide.
			out["effect"] = UiKit.t("balance -%d%%") % int(round(float(o["dent"]) * 100.0))
		Tuning.Act.GRAPPLE:
			out["p"] = 1.0
			out["effect"] = UiKit.t("takedown %d%%") % int(round(float(o["p"]) * 100.0))
		Tuning.Act.BREAK:
			out["p"] = -1.0
			out["effect"] = UiKit.t("frees your man")
		Tuning.Act.HOLD:
			out["p"] = -1.0
			out["effect"] = UiKit.t("keeps him tied")
		Tuning.Act.ESCAPE:
			out["p"] = -1.0
			out["effect"] = UiKit.t("breaks free")
		Tuning.Act.BULLRUSH:
			if float(o["fall"]) > 0.0:
				out["effect"] = UiKit.t("fall %d%%") % int(round(float(o["fall"]) * 100.0))
				out["col"] = RED_SOFT
		Tuning.Act.TAKEDOWN:
			if m.prompt.menu == Tuning.Menu.GRAPPLED and Tuning.td_gate > 0.0 and t.stability > Tuning.td_gate:
				out["effect"] = UiKit.t("he is too steady")
				out["col"] = RED_SOFT
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
	var edge: Color = RUST_EDGE if clinch else v.COL_DIM
	var pick: int = m.prompt.choice if kind != "wheel" else -99
	## TWO PASSES: every side first, then every side's words, so no side's
	## edge is drawn through its neighbour's words.
	for i in acts.size():
		var act: int = acts[i]
		var s: Vector2 = span(i)
		var hot: bool = kind == "wheel" and act == v.wheel_hot
		var lit: bool = act == pick and not waiting
		var pts: PackedVector2Array = _ring(c, RI, RO, s.x + 0.6, s.y - 0.6)
		var body: Color = RUST_DARK if waiting else (UiKit.YOU if hot else fill)
		v.draw_colored_polygon(pts, body)
		var outline: PackedVector2Array = pts.duplicate()
		outline.append(pts[0])
		v.draw_polyline(outline, edge, 2.0)
	## The gold outline of his pick over the plain edges, so it is whole.
	for i in acts.size():
		if int(acts[i]) == pick and not waiting:
			var s2: Vector2 = span(i)
			var lit_pts: PackedVector2Array = _ring(c, RI, RO, s2.x + 0.6, s2.y - 0.6)
			lit_pts.append(lit_pts[0])
			v.draw_polyline(lit_pts, UiKit.YOU, 4.0)
	for i in acts.size():
		var act: int = acts[i]
		var s: Vector2 = span(i)
		var hot: bool = kind == "wheel" and act == v.wheel_hot
		var lit: bool = act == pick and not waiting
		var ink: Color = v.COL_DIM if waiting else (UiKit.BG if hot else UiKit.INK)
		var mid_a := (s.x + s.y) * 0.5
		## THE WORDS FOLLOW THE SIDE (Pete, 2 Oct 2026: options 4 and 5 — a bigger
		## corner, the words curved along each side's arc). Name on the outside,
		## the chance, then what it does; the mark sits straight in the side's
		## inner end. Nothing crosses an edge, in either hand.
		var r: Dictionary = read(v, m, act)
		arc_text(v, Tuning.act_name(act), c, NAME_R, mid_a, 16, ink)
		if float(r["p"]) >= 0.0:
			arc_text(v, UiKit.t("%d%% chance") % int(round(float(r["p"]) * 100.0)), c, CHANCE_R, mid_a, 13,
				v.COL_DIM if waiting else v._odds_col(float(r["p"])))
		arc_text(v, String(r["effect"]), c, EFFECT_R, mid_a, 12, v.COL_DIM if waiting else r["col"])
		var ip := _pt(c, MARK_R, mid_a)
		UiKit.icon(v, v._act_mark(act), ip - Vector2(16, 16), UiKit.YOU if lit else ink, 2)
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


## TEXT ALONG AN ARC, centred on `mid_deg` (degrees clockwise from up), reading
## clockwise with its tops facing out of the corner. It steps its size down
## (to 11) until it fits the side; past that it is cut, and a side's words are
## kept short enough that it never is in any language we ship.
static func arc_text(v, text: String, c: Vector2, r: float, mid_deg: float, size: int, col: Color) -> void:
	var font: Font = v.font
	var room := deg_to_rad(SPAN) * r * ARC_FILL
	var px := size
	while px > 11 and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x > room:
		px -= 1
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
