class_name Playbook
## A PLAY, DRAWN. One renderer, shared by every screen that shows one.
##
## Pete, 13 Sep 2026, holding a Backyard Football playbook page: *"I feel like we
## can do a real playbook."* We can, and the reason is that the plays were
## already in the data — it just took looking at their screen to notice.
##
## A formation is five spots across the line. A strategy is a depth profile plus
## an optional lane, and `Tuning.plan_target` resolves the pair into a
## destination per man. A drawn play is five routes in the same coordinates. So a
## play card is not an illustration somebody has to draw and then keep in step
## with the sim — **it is the sim's own numbers, plotted.** Change a push value
## in `tuning.gd` and every card in the game redraws correctly, including the
## ones nobody has looked at since.
##
## THE AXES MATCH THE FIGHT SCREEN, which is the one thing here that could have
## quietly taught the wrong lesson. `melee_scene._to_screen` is
## `ORIGIN + Vector2(v.y, v.x) * SCALE` — the push axis runs across the screen and
## the lane axis runs down it, with lane 0 at the top. A card drawn the other way
## up would be the only place in the game where the fight points somewhere else.

enum Mode {
	SHAPE,      ## five men and nothing else — a formation picker
	STRATEGY,   ## an arrow per man, from his spot to where the push sends him
	PLAY,       ## the drawn route, leg by leg
}

## The deepest a card plots. Nothing in `STRATEGIES` pushes past 0.66 and
## `PLAY_MAX_Y` bounds a drawn route, so plotting the full length of the list
## would spend a third of every card on ground nobody reaches.
const DEPTH: float = 0.76
const DOT: float = 5.0
const LABEL_H: float = 19.0
const PAD := Vector2(7.0, 6.0)


## The ground a play is drawn on. Split out because the shape picker, the card
## and any future editor all want the same rectangle out of the same box.
static func pitch_of(r: Rect2, labelled: bool) -> Rect2:
	var body := Rect2(r.position, r.size - Vector2(UiKit.DROP_PX, UiKit.DROP_PX))
	return Rect2(body.position + PAD,
		body.size - PAD * 2.0 - Vector2(0.0, LABEL_H if labelled else 0.0))


## push 0..DEPTH across, lane 0..1 down. Inset so a dot on the edge still has its
## whole square inside the ground.
static func at(pitch: Rect2, push: float, lane: float) -> Vector2:
	return Vector2(
		pitch.position.x + 4.0 + (pitch.size.x - 10.0) * clampf(push / DEPTH, 0.0, 1.0),
		pitch.position.y + 6.0 + (pitch.size.y - 12.0) * clampf(lane, 0.0, 1.0))


static func arrow(ci: CanvasItem, a: Vector2, b: Vector2, col: Color) -> void:
	if a.distance_to(b) < 3.0:
		return
	ci.draw_line(a, b, col, 2.0)
	var d := (b - a).normalized()
	var p := Vector2(-d.y, d.x)
	ci.draw_line(b, b - d * 7.0 + p * 4.0, col, 2.0)
	ci.draw_line(b, b - d * 7.0 - p * 4.0, col, 2.0)


## THE CARD, on bare ground: a panel, and then the face of it.
##
## `data` is the strategy id in STRATEGY mode and the five routes in PLAY mode;
## it is ignored in SHAPE mode.
static func card(ci: CanvasItem, r: Rect2, spots: Array, mode: int, data,
		live: bool, label: String, font: Font, label_px: int = 14) -> void:
	UiKit.panel(ci, r)
	card_face(ci, r, spots, mode, data, live, label, font, label_px)


## THE FACE, without the panel, because a Button has already drawn one.
##
## This was two functions with the same forty lines in both of them for about a
## minute, which is the fault this codebase has a house rule about: a rule
## applied at two call sites is a rule with a hole in it, and a DRAWING applied
## at two call sites is a card that starts rendering differently on the screen
## nobody is looking at. One body, two doors.
static func card_face(ci: CanvasItem, r: Rect2, spots: Array, mode: int, data,
		live: bool, label: String, font: Font, label_px: int = 14) -> void:
	var body := Rect2(r.position, r.size - Vector2(UiKit.DROP_PX, UiKit.DROP_PX))
	## THE FACE GOES DARK FIRST. On a loose card the panel underneath is already
	## PANEL; on a Button it is the skin's blue fill, and the label band was the
	## only part of the card the pitch did not cover — so a play read as a diagram
	## sitting on a button instead of as a card. One fill, and the two doors agree
	## about what a card looks like.
	ci.draw_rect(body, UiKit.PANEL)
	if live:
		ci.draw_rect(body, UiKit.YOU, false, 3.0)
	else:
		ci.draw_rect(body, UiKit.FRAME, false, 1.0)

	var pitch := pitch_of(r, label != "")
	ci.draw_rect(pitch, UiKit.BG.lightened(0.05))
	## YOUR RAIL, at the left. Theirs is off the right edge — a card shows the
	## push, not the whole arena, which is why DEPTH stops at 0.76.
	ci.draw_rect(Rect2(pitch.position, Vector2(2.0, pitch.size.y)), UiKit.FRAME)
	## Two lane guides, so a Turtle shifting onto a rail reads as a shift rather
	## than as arrows that happen to lean.
	for k in 2:
		var gy := pitch.position.y + pitch.size.y * (0.33 + 0.34 * float(k))
		ci.draw_line(Vector2(pitch.position.x, gy), Vector2(pitch.end.x, gy),
			UiKit.EDGE, 1.0)

	var ink: Color = UiKit.INK if live else UiKit.DIM
	for slot in 5:
		var spot: Vector2 = spots[slot]
		var a := at(pitch, spot.y, spot.x)
		match mode:
			Mode.STRATEGY:
				var tgt := Tuning.plan_target(int(data), slot, spot.x)
				arrow(ci, a, at(pitch, tgt.y, tgt.x), ink)
			Mode.PLAY:
				## LEG BY LEG, from where he is standing. A drawn route is a path
				## and not a destination, so a card that plotted only the last
				## point would straighten a Rail's hook into a charge.
				var legs: Array = data[slot] if data != null and slot < data.size() else []
				var from := a
				for i in legs.size():
					var v: Vector2 = legs[i]
					var to := at(pitch, v.y, v.x)
					if i == legs.size() - 1:
						arrow(ci, from, to, ink)
					else:
						ci.draw_line(from, to, ink, 2.0)
					from = to
		## The Center is the man a Turtle wraps, so he is the one worth telling
		## apart at a glance.
		var col: Color = UiKit.YOU if slot == 2 else UiKit.INK
		ci.draw_rect(Rect2(a - Vector2(DOT, DOT), Vector2(DOT * 2.0, DOT * 2.0)), col)
		ci.draw_rect(Rect2(a - Vector2(DOT, DOT), Vector2(DOT * 2.0, DOT * 2.0)),
			UiKit.PANEL, false, 1.0)

	if label != "":
		UiKit.text(ci, font, UiKit.fit(font, label, label_px, body.size.x - 16.0),
			Vector2(body.position.x + 8.0, body.end.y - 5.0), label_px,
			UiKit.YOU if live else UiKit.INK)


## ------------------------------------------------------------------ the button
## A CARD YOU CAN PRESS.
##
## The diagram is painted by a child Control rather than by overriding the
## Button's own `_draw`, and that is deliberate: a Button paints its StyleBox
## from `_notification`, so a script `_draw` on the same node is a race with the
## engine's own drawing that happens to come out right today. A child draws after
## its parent, always, and `MOUSE_FILTER_IGNORE` keeps it out of the way of the
## press.
##
## It also keeps `test_layout.gd` honest without special-casing: the sweep
## collects Buttons, LineEdits and Sliders, so a decorative Control is invisible
## to it and cannot be reported as sitting on the button it belongs to.
static func card_button(size: Vector2, spots: Array, mode: int, data, live: bool,
		label: String, on_press: Callable, label_px: int = 14) -> Button:
	var b := Button.new()
	b.custom_minimum_size = size
	b.size = size
	UiKit.skin(b, 2.0)
	b.pressed.connect(func():
		Audio.play("tap")
		on_press.call())
	var art := Paint.new()
	art.spots = spots
	art.mode = mode
	art.data = data
	art.live = live
	art.label = label
	art.label_px = label_px
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	b.add_child(art)
	return b


class Paint extends Control:
	var spots: Array = []
	var mode: int = Mode.SHAPE
	var data = null
	var live := false
	var label := ""
	var label_px := 14

	func _draw() -> void:
		if spots.size() < 5:
			return
		## The button has already painted its own frame and drop, so the card
		## draws onto the face of it: same rectangle, no panel underneath.
		Playbook.card_face(self, Rect2(Vector2.ZERO, size + Vector2(UiKit.DROP_PX,
			UiKit.DROP_PX)), spots, mode, data, live, label, UiKit.body(), label_px)
