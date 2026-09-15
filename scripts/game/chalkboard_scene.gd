extends Node2D
## THE CHALKBOARD. Where a player draws his own shapes and his own openings.
##
## Pete, 10 Sep 2026: *"Chalkboard - Formation will let the player position
## fighters behind the 15% line in any formation they want. Being able to save
## the formation and use it via drop down. Chalkboard - Plays will let the
## player draw the routes he wants his fighters to initially take. Plays can be
## check marked to be Formation dependent or universal."*
##
## DRAWN THE SAME WAY UP AS THE FIGHT. The melee runs rotated — the charge is
## across the screen, the line is up and down it — so the board does too. A
## planning screen whose picture does not match the one the plan happens on is
## a translation exercise, and the player would have to do it in his head every
## time he called the play.
##
## THE LINE IS PAINTED AND THE DRAG IS CLAMPED. A man cannot be dragged past
## 15% because there is nowhere past 15% to drop him, rather than because a
## message appears afterwards explaining what he did wrong. Tuning.formation_legal
## still vets the result on save — clamping is the UI being kind, not the rule.

enum Mode { FORMATION, PLAY }

## The PANEL is fixed, because the buttons hang off it. The FIELD inside it is
## not: it is drawn to the list's true proportions, and it shows only as much of
## the charge axis as the mode can reach. A formation editor that stretched 15%
## of the list across two thirds of the screen would have the player placing men
## against a picture of a shape he is not making — the one thing a positioning
## tool cannot do.
const BOARD := Rect2(292.0, 96.0, 640.0, 376.0)
## How far up the list each mode shows. The formation band plus enough ground in
## front of it to see that there IS ground in front of it.
const FORMATION_SPAN: float = 0.32
const LEFT_X := 24.0
const SLOT_Y := 150.0
const SLOT_H := 40.0
const SLOT_W := 250.0
const MARK_R := 13.0

var font: Font
var season: Season
var board: Chalkboard
var ui: CanvasLayer
var name_edit: LineEdit

var mode: int = Mode.FORMATION
var slot: int = 0
var flash := ""

## The working copy. Nothing is written to the Chalkboard until Save is hit, so
## backing out of a half-drawn shape costs a tap and not a formation.
var spots: Array = []
var routes: Array = []
var bind_to: int = Chalkboard.UNIVERSAL

var dragging: int = -1          ## which of the five is under the finger
var drawing: int = -1           ## which of the five is having a route drawn
var raw: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	if Session.season == null:
		Session.season = Season.new(MeleeRosters.starting_club(), randi())
	season = Session.season
	board = season.board
	ui = CanvasLayer.new()
	add_child(ui)
	_load_slot(0)
	_rebuild()


# ------------------------------------------------------------- working copy
func _load_slot(i: int) -> void:
	slot = i
	dragging = -1
	drawing = -1
	raw = PackedVector2Array()
	if mode == Mode.FORMATION:
		if i < board.formations.size():
			spots = []
			for v in board.formations[i]["spots"]:
				spots.append(Vector2(v))
		else:
			## A fresh slot opens on 2-1-2 rather than on an empty board. You
			## are editing a formation, not inventing the idea of one.
			spots = []
			for v in Tuning.FORMATIONS[Tuning.Formation.TWO_ONE_TWO]["spots"]:
				spots.append(Vector2(v))
	else:
		if i < board.plays.size():
			routes = []
			## THROUGH THE ACCESSOR. `board.routes_of(i)` has existed since the
			## board was written, bounds-checked, and this was the one place that
			## wanted it — reaching into `plays[i]["routes"]` by hand instead.
			for r in board.routes_of(i):
				var leg: Array[Vector2] = []
				for v in r:
					leg.append(Vector2(v))
				routes.append(leg)
			bind_to = int(board.plays[i]["formation"])
		else:
			routes = Chalkboard.blank_routes()
			bind_to = Chalkboard.UNIVERSAL


## Where the five stand while a play is being drawn: the shape the play is tied
## to, or the one the club is currently going out in. A route drawn from the
## wrong start is a route drawn for a different play.
func _play_spots() -> Array:
	if bind_to != Chalkboard.UNIVERSAL:
		return board.spots_for(bind_to)
	return board.spots_for(season.formation_id)


func _slots_owned() -> int:
	return board.formation_slots if mode == Mode.FORMATION else board.play_slots


func _drawn() -> int:
	return board.formations.size() if mode == Mode.FORMATION else board.plays.size()


# ------------------------------------------------------------------ controls
func _rebuild() -> void:
	for c in ui.get_children():
		c.queue_free()
	name_edit = null

	## WIDE ENOUGH FOR THE WORD. At 124 these two fitted only because their
	## contents sat flush against the frame; giving every button ten pixels of
	## padding pushed FORMATIONS past its own box and Godot grew the control to
	## suit, straight through PLAYS beside it. A button narrower than its label
	## is now a test failure rather than a silent overlap.
	ui.add_child(UiKit.button("FORMATIONS", Vector2(LEFT_X, 72), Vector2(152, 34), func():
		mode = Mode.FORMATION
		flash = ""
		_load_slot(0)
		_rebuild()))
	ui.add_child(UiKit.button("PLAYS", Vector2(LEFT_X + 158, 72), Vector2(100, 34), func():
		mode = Mode.PLAY
		flash = ""
		_load_slot(0)
		_rebuild()))
	ui.add_child(UiKit.button("Back", Vector2(UiKit.right_edge(98.0), 14), Vector2(78, 36), func():
		Session.autosave()
		UiKit.back("res://scenes/Season.tscn")))

	var owned := _slots_owned()
	for i in Chalkboard.SLOTS:
		var y := SLOT_Y + float(i) * (SLOT_H + 6.0)
		if i < owned:
			var take := i
			ui.add_child(UiKit.button("", Vector2(LEFT_X, y), Vector2(SLOT_W, SLOT_H), func():
				_load_slot(take)
				flash = ""
				_rebuild()))
		elif i == owned:
			## Only the NEXT slot is for sale. Four buy buttons in a column
			## would read as four separate things to want.
			var cost := board.slot_cost(owned)
			ui.add_child(UiKit.button("Unlock — %d CC" % cost,
				Vector2(LEFT_X, y), Vector2(SLOT_W, SLOT_H), _unlock))

	if slot < owned:
		name_edit = LineEdit.new()
		name_edit.position = Vector2(BOARD.position.x, 48)
		name_edit.size = Vector2(300, 34)
		name_edit.max_length = 18
		name_edit.placeholder_text = "Name it"
		name_edit.text = _current_name()
		ui.add_child(name_edit)

		ui.add_child(UiKit.button("Save", Vector2(BOARD.position.x, 486),
			Vector2(150, 42), _save))
		ui.add_child(UiKit.button("Revert", Vector2(BOARD.position.x + 158, 486),
			Vector2(130, 42), func():
				_load_slot(slot)
				flash = ""
				_rebuild()))
		if slot < _drawn():
			ui.add_child(UiKit.button("Delete", Vector2(BOARD.position.x + 296, 486),
				Vector2(130, 42), _delete))
		if mode == Mode.PLAY:
			ui.add_child(UiKit.button(_bind_label(), Vector2(BOARD.position.x + 434, 486),
				Vector2(206, 42), _cycle_binding))
	queue_redraw()


func _current_name() -> String:
	if mode == Mode.FORMATION:
		return String(board.formations[slot]["name"]) if slot < board.formations.size() else ""
	return String(board.plays[slot]["name"]) if slot < board.plays.size() else ""


func _bind_label() -> String:
	if bind_to == Chalkboard.UNIVERSAL:
		return "Runs from: any shape"
	return "Runs from: %s" % UiKit.clip(board.formation_name(bind_to), 14)


## Pete's check mark, as a cycle rather than a checkbox plus a dropdown: every
## shape the club owns, then universal, then round again.
func _cycle_binding() -> void:
	var ids: Array = [Chalkboard.UNIVERSAL]
	for c in board.formation_choices():
		ids.append(int(c["id"]))
	var at := ids.find(bind_to)
	bind_to = ids[(at + 1) % ids.size()]
	flash = ""
	_rebuild()


func _unlock() -> void:
	var err := board.unlock_formation(season.office) if mode == Mode.FORMATION \
		else board.unlock_play(season.office)
	flash = UiKit.said(err) if err != "" else "Slot unlocked."
	if err == "":
		Session.autosave()
		_load_slot(_slots_owned() - 1)
	_rebuild()


func _save() -> void:
	var nm := name_edit.text if name_edit != null else ""
	var err := ""
	if mode == Mode.FORMATION:
		err = board.save_formation(slot, nm, spots)
	else:
		err = board.save_play(slot, nm, routes, bind_to)
	if err != "":
		flash = err
		_rebuild()
		return
	Session.autosave()
	flash = "Saved."
	_rebuild()


func _delete() -> void:
	var err := board.delete_formation(slot) if mode == Mode.FORMATION \
		else board.delete_play(slot)
	if err != "":
		flash = err
		_rebuild()
		return
	## A deleted shape must not stay picked for the next bout.
	if mode == Mode.FORMATION and board.formation_by_id(season.formation_id).is_empty() \
			and not Tuning.FORMATIONS.has(season.formation_id):
		season.formation_id = Tuning.Formation.TWO_ONE_TWO
	## A DELETE ABOVE THE SELECTION SLIDES IT ONTO A DIFFERENT PLAY.
	##
	## `play_index` is an INDEX, and `remove_at` shifts everything after it down
	## one — so with ["Crash", "Wheel", "Hold"] and Wheel called, deleting Crash
	## left index 1 pointing at Hold. The called play silently became a
	## different play, and the only guard was against running off the end. This
	## file's own header warns about exactly this for formations.
	if mode == Mode.PLAY:
		if season.play_index == slot:
			season.play_index = -1        ## the called play is the one deleted
		elif season.play_index > slot:
			season.play_index -= 1        ## it moved down with everything else
		if season.play_index >= board.plays.size():
			season.play_index = -1
	Session.autosave()
	flash = "Deleted."
	_load_slot(mini(slot, maxi(0, _slots_owned() - 1)))
	_rebuild()


# -------------------------------------------------------------------- input
func _span() -> float:
	return FORMATION_SPAN if mode == Mode.FORMATION else Tuning.PLAY_MAX_Y


## The drawn field: as tall as the panel, as wide as the list's real proportions
## make it at that height, centred in the panel.
func _field() -> Rect2:
	var scale := BOARD.size.y / Tuning.LIST_W
	var w: float = _span() * Tuning.LIST_H * scale
	return Rect2(BOARD.position.x + (BOARD.size.x - w) * 0.5, BOARD.position.y,
		w, BOARD.size.y)


## Normalised (x across the line, y out from your own rail) to screen, rotated
## exactly like the melee: y runs left to right, x runs top to bottom.
func _to_screen(v: Vector2) -> Vector2:
	var f := _field()
	return f.position + Vector2(v.y / _span() * f.size.x, v.x * f.size.y)


func _to_norm(p: Vector2) -> Vector2:
	var f := _field()
	var d := p - f.position
	return Vector2(
		clampf(d.y / f.size.y, 0.02, 0.98),
		clampf(d.x / f.size.x, 0.0, 1.0) * _span())


func _mark_at(p: Vector2) -> int:
	var five: Array = spots if mode == Mode.FORMATION else _play_spots()
	for i in five.size():
		if _to_screen(five[i]).distance_to(p) <= MARK_R + 10.0:
			return i
	return -1


func _unhandled_input(event: InputEvent) -> void:
	if slot >= _slots_owned():
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_press(event.position)
		else:
			_release(event.position)
	elif event is InputEventScreenDrag:
		_drag(event.position)


func _press(p: Vector2) -> void:
	if not _field().grow(22.0).has_point(p):
		return
	var i := _mark_at(p)
	if i == -1:
		return
	if mode == Mode.FORMATION:
		dragging = i
	else:
		drawing = i
		raw = PackedVector2Array([_to_screen(_play_spots()[i])])
	queue_redraw()


func _drag(p: Vector2) -> void:
	if mode == Mode.FORMATION and dragging != -1:
		var v := _to_norm(p)
		## THE CLAMP IS THE RULE MADE PHYSICAL. There is nowhere past the line
		## to put him down.
		spots[dragging] = Vector2(v.x, clampf(v.y, 0.0, Tuning.SET_UP_LINE))
		queue_redraw()
	elif mode == Mode.PLAY and drawing != -1:
		if raw[raw.size() - 1].distance_to(p) < 16.0:
			return
		raw.append(p)
		queue_redraw()


func _release(_p: Vector2) -> void:
	if mode == Mode.FORMATION:
		dragging = -1
	elif drawing != -1:
		var leg: Array[Vector2] = []
		## A drag is a hundred points and a play is allowed six, so the raw
		## line is thinned to its shape rather than truncated to its first
		## sixth — cutting it short would save a route that stops halfway
		## through the gesture the player actually made.
		if raw.size() > 1:
			var want: int = mini(Tuning.PLAY_MAX_POINTS, maxi(1, int(raw.size() / 6)))
			for k in want:
				var at := int(round(float(k + 1) / float(want) * float(raw.size() - 1)))
				var v := _to_norm(raw[at])
				leg.append(Vector2(v.x, clampf(v.y, 0.0, Tuning.PLAY_MAX_Y)))
		## A tap with no drag CLEARS that man's route. There is no other way to
		## take one back, and adding a second control for it would be a button
		## to undo a gesture.
		routes[drawing] = leg
		drawing = -1
		raw = PackedVector2Array()
		flash = ""
		queue_redraw()


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), UiKit.BG)
	UiKit.text(self, font, "CHALKBOARD", Vector2(LEFT_X, 40), 22, UiKit.YOU)
	UiKit.purse(self, font, season.office.credits,
		Vector2(LEFT_X, 122), 14, UiKit.DIM)
	_draw_slots()
	_draw_board()
	if flash != "":
		UiKit.text(self, font, flash, Vector2(BOARD.position.x, 92 - 8), 14, UiKit.DIM)


func _draw_slots() -> void:
	var owned := _slots_owned()
	for i in Chalkboard.SLOTS:
		var y := SLOT_Y + float(i) * (SLOT_H + 6.0)
		var r := Rect2(LEFT_X, y, SLOT_W, SLOT_H)
		if i >= owned:
			UiKit.panel(self, r, false)
			if i > owned:
				UiKit.text(self, font, "Locked", Vector2(LEFT_X + 12, y + 26), 14, UiKit.EDGE)
			continue
		UiKit.panel(self, r, i == slot)
		var nm := ""
		if mode == Mode.FORMATION:
			nm = String(board.formations[i]["name"]) if i < board.formations.size() else "— empty —"
		else:
			nm = String(board.plays[i]["name"]) if i < board.plays.size() else "— empty —"
		UiKit.text(self, font, UiKit.clip(nm, 20), Vector2(LEFT_X + 12, y + 26),
			16, UiKit.INK if i == slot else UiKit.DIM)
		if mode == Mode.PLAY and i < board.plays.size():
			var f := int(board.plays[i]["formation"])
			var tag := "any" if f == Chalkboard.UNIVERSAL else UiKit.clip(board.formation_name(f), 10)
			UiKit.right(self, font, tag, Vector2(LEFT_X + SLOT_W - 10, y + 26), 12, UiKit.EDGE, 120.0)


func _draw_board() -> void:
	var f := _field()
	draw_rect(f, Tuning.COL_GROUND)
	draw_rect(f, UiKit.FRAME, false, 2.0)
	## Your own back rail, on the left, because that is where it is in the fight.
	draw_line(f.position, f.position + Vector2(0, f.size.y), Tuning.COL_RAIL, 6.0)
	## The set-up line, painted rather than explained — and in formation mode the
	## ground past it is greyed, so the clamp under the finger has a reason on
	## screen before the finger ever finds it.
	var lx := f.position.x + Tuning.SET_UP_LINE / _span() * f.size.x
	if mode == Mode.FORMATION:
		draw_rect(Rect2(lx, f.position.y, f.end.x - lx, f.size.y), Color(0, 0, 0, 0.28))
	draw_line(Vector2(lx, f.position.y), Vector2(lx, f.end.y),
		Color(Tuning.COL_MARSHAL, 0.55), 2.0)
	UiKit.text(self, font, "15%", Vector2(lx + 6, f.position.y + 16), 12, Tuning.COL_MARSHAL)
	UiKit.right(self, font, "toward them →",
		Vector2(f.end.x - 8, f.end.y - 10), 12, UiKit.DIM, 160.0)

	if slot >= _slots_owned():
		UiKit.text(self, font, "Unlock a slot to start drawing.",
			f.position + Vector2(16, 40), 16, UiKit.DIM)
		return

	var five: Array = spots if mode == Mode.FORMATION else _play_spots()
	if mode == Mode.PLAY:
		for i in routes.size():
			_draw_route(five[i], routes[i], Tuning.COL_ROUTE)
		if drawing != -1 and raw.size() > 1:
			draw_polyline(raw, Color(Tuning.COL_ROUTE, 0.55), 3.0)
	for i in five.size():
		var at := _to_screen(five[i])
		var live: bool = (mode == Mode.FORMATION and dragging == i) or drawing == i
		draw_circle(at, MARK_R, UiKit.YOU if live else Tuning.COL_STEEL)
		draw_arc(at, MARK_R, 0.0, TAU, 20, Tuning.COL_STEEL_DARK, 2.0)
		UiKit.text(self, font, Tuning.POS_NAME[i].substr(0, 1),
			at + Vector2(-4, 5), 14, Tuning.COL_GROUND)


func _draw_route(from: Vector2, leg: Array, col: Color) -> void:
	if leg.is_empty():
		return
	var pts := PackedVector2Array([_to_screen(from)])
	for v in leg:
		pts.append(_to_screen(v))
	draw_polyline(pts, col, 3.0)
	var tip: Vector2 = pts[pts.size() - 1]
	draw_circle(tip, 5.0, col)
