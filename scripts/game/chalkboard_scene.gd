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
## THE REBUILD (Pete, 29 Sep 2026, round 2): a big centred field, 44px men,
## one name field, a line saying what the shape does, Delete held back from
## the last formation.
const BOARD := Rect2(288.0, 92.0, 648.0, 376.0)
## How far up the list each mode shows. The formation band plus enough ground in
## front of it to see that there IS ground in front of it.
## 0.50, not 0.32: the legal band is the same 15%, drawn half as wide again.
const FORMATION_SPAN: float = 0.50
const LEFT_X := 24.0
const SLOT_Y := 128.0
const SLOT_H := 44.0
const SLOT_W := 240.0
const MARK_R := 22.0

var font: Font
var season: Season
var board: Chalkboard
var ui: CanvasLayer
var name_edit: LineEdit
## The name typed for the slot being edited, kept across rebuilds (Runs from,
## Unlock and Revert all rebuild the screen). Cleared when a slot is loaded.
var draft_name = null

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
## WHAT THE SLOT LOOKED LIKE WHEN IT WAS LOADED OR SAVED, so Save can sit dead
## until something changes (round 8: Save was gold before any edit).
var clean_sig := ""
## WHAT THE BOARD LOOKED LIKE WHEN THIS SLOT WAS OPENED, for the one question
## `clean_sig` cannot answer on a slot never saved: has anything been drawn?
var open_sig := ""
var save_b: Button


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	if Session.season == null:
		Session.season = Season.new(MeleeRosters.starting_club(), randi())
	season = Session.season
	board = season.board
	ui = CanvasLayer.new()
	add_child(ui)
	## CENTRED ON A WIDE PHONE (2 Oct 2026 playtest): see `UiKit.frame`.
	UiKit.frame(self, ui)
	_load_slot(0)
	_rebuild()


# ------------------------------------------------------------- working copy
func _load_slot(i: int) -> void:
	slot = i
	draft_name = null
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
	## A slot never saved is a change already; one on file starts clean.
	clean_sig = _sig() if i < _drawn() else ""
	open_sig = _sig()


## UNSAVED WORK IS NOT DROPPED ON ONE TAP (playtest, 4 Oct 2026: "I can't get to
## what I drew"). Another slot, the other tab or Revert loaded over the board
## and the drawing was gone without a word. Now the first press says so and the
## second goes ahead.
func _may_leave(key: String) -> bool:
	if slot >= _slots_owned() or _sig() == open_sig:
		return true
	if UiKit.confirm("board-leave:" + key):
		return true
	flash = UiKit.t("Not saved. Press again to drop the changes.")
	_rebuild()
	return false


func _sig() -> String:
	return "%s|%s|%d|%s" % [str(spots), str(routes), bind_to, str(draft_name)]


## Save lights when the working copy differs from what is on file.
func _style_save() -> void:
	if save_b == null or not is_instance_valid(save_b):
		return
	var clean := _sig() == clean_sig
	if clean == save_b.disabled:
		return
	save_b.disabled = clean
	## GOLD ONLY WHILE THERE IS SOMETHING TO SAVE (checklist C3: never a dead
	## gold button).
	if clean:
		save_b.remove_meta("primary")
		UiKit.skin(save_b)
	else:
		UiKit.primary(save_b)


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
	ui.add_child(UiKit.selected(UiKit.button(UiKit.t("FORMATIONS"), Vector2(LEFT_X, 78), Vector2(144, 38), func():
		if mode != Mode.FORMATION and not _may_leave("formations"):
			return
		mode = Mode.FORMATION
		flash = ""
		_load_slot(0)
		_rebuild()), mode == Mode.FORMATION))
	ui.add_child(UiKit.selected(UiKit.button(UiKit.t("PLAYS"), Vector2(LEFT_X + 150, 78), Vector2(90, 38), func():
		if mode != Mode.PLAY and not _may_leave("plays"):
			return
		mode = Mode.PLAY
		flash = ""
		_load_slot(0)
		_rebuild()), mode == Mode.PLAY))
	ui.add_child(UiKit.corner_back("res://scenes/Season.tscn"))

	var owned := _slots_owned()
	for i in Chalkboard.SLOTS:
		var y := SLOT_Y + float(i) * (SLOT_H + 6.0)
		if i < owned and i == slot:
			## ONE NAME FIELD: the picked row IS the name. It used to be a row
			## showing the name and a second box above the board editing it.
			name_edit = LineEdit.new()
			UiKit.skin_edit(name_edit)
			name_edit.position = Vector2(LEFT_X, y)
			name_edit.size = Vector2(SLOT_W, SLOT_H)
			name_edit.max_length = 18
			name_edit.placeholder_text = UiKit.t("Name it")
			name_edit.text = draft_name if draft_name != null else _current_name()
			name_edit.text_changed.connect(func(t: String):
				draft_name = t
				_style_save())
			ui.add_child(name_edit)
		elif i < owned:
			var take := i
			## FLAT, AND THAT IS THE WHOLE OF #18 AND #19.
			##
			## Pete, 15 Sep 2026: *"Saved formation doesn't save or show up in
			## blank slot"*, and the same for plays. It saved perfectly. The row
			## drew its name perfectly. And then this — a full-size themed Button
			## with an EMPTY label — was added to the `ui` CanvasLayer, which sits
			## ABOVE the Node2D the row is drawn on, and painted a solid slab over
			## the name every time.
			##
			## The tell was in his own screenshot and read as a design choice: the
			## locked rows showed their text and the owned one was a blank blue
			## rectangle, because only the owned rows get one of these.
			##
			## This project has written down *"a scrim cannot cover a Button"*
			## four times. **It goes the other way too, and the other way is
			## worse** — a control that covers your drawing does not look broken,
			## it looks like a control, so nobody goes looking for the drawing.
			## The season screen's team sheet already solved it: draw the row,
			## put a FLAT hit box on top.
			var b := UiKit.button("", Vector2(LEFT_X, y), Vector2(SLOT_W, SLOT_H), func():
				if not _may_leave("slot%d" % take):
					return
				_load_slot(take)
				flash = ""
				_rebuild())
			ui.add_child(Pad.row(b))
		elif i == owned:
			## Only the NEXT slot is for sale. Four buy buttons in a column
			## would read as four separate things to want.
			var cost := board.slot_cost(owned)
			## A PURCHASE, SAID AS ONE (round 11: it looked like a slot): the
			## coin, the verb and the price, narrower than the rows it sits
			## among, and grey when the purse cannot cover it.
			var buy := UiKit.button(UiKit.t("Buy a slot · %d CC") % cost,
				Vector2(LEFT_X, y), Vector2(SLOT_W, SLOT_H), _unlock, "coin")
			buy.disabled = cost > season.office.credits
			ui.add_child(buy)

	if slot < owned:
		save_b = UiKit.button(UiKit.t("Save"), Vector2(BOARD.position.x, 486),
			Vector2(150, 42), _save)
		## Starts dead and plain; `_style_save` lights it the moment the board
		## differs from what is on file.
		save_b.disabled = true
		ui.add_child(save_b)
		_style_save()
		ui.add_child(UiKit.button(UiKit.t("Revert"), Vector2(BOARD.position.x + 158, 486),
			Vector2(130, 42), func():
				if not _may_leave("revert"):
					return
				_load_slot(slot)
				flash = ""
				_rebuild()))
		## DELETE STANDS APART, at the far end of the row, and cannot take the
		## last formation the club has drawn.
		if slot < _drawn():
			var del := UiKit.danger(UiKit.button(UiKit.t("Delete"), Vector2(BOARD.end.x - 120.0, 486),
				Vector2(120, 42), _delete))
			## NOT SHOWN AT ALL on the last formation (round 7: a disabled Delete
			## still read as a button).
			if not (mode == Mode.FORMATION and board.formations.size() <= 1):
				ui.add_child(del)
			else:
				del.free()
		if mode == Mode.PLAY:
			ui.add_child(UiKit.button(_bind_label(), Vector2(BOARD.position.x + 296, 486),
				Vector2(206, 42), _cycle_binding))
	queue_redraw()


func _current_name() -> String:
	if mode == Mode.FORMATION:
		return String(board.formations[slot]["name"]) if slot < board.formations.size() else ""
	return String(board.plays[slot]["name"]) if slot < board.plays.size() else ""


func _bind_label() -> String:
	if bind_to == Chalkboard.UNIVERSAL:
		return UiKit.t("Runs from: any shape")
	return UiKit.t("Runs from: %s") % UiKit.clip(board.formation_name(bind_to), 14)


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
	## Buying opens the new slot, which would load over an unsaved board.
	if not _may_leave("unlock"):
		return
	var err := board.unlock_formation(season.office) if mode == Mode.FORMATION \
		else board.unlock_play(season.office)
	flash = UiKit.said(err) if err != "" else UiKit.t("Slot unlocked.")
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
	flash = UiKit.t("Saved.")
	clean_sig = _sig()
	open_sig = clean_sig
	_rebuild()


func _delete() -> void:
	## TWO TAPS (blind review, 29 Sep: Delete beside Save, one tap).
	if not UiKit.confirm("board-delete:%d:%d" % [mode, slot]):
		flash = UiKit.t("Tap Delete again to erase it for good.")
		_rebuild()
		return
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
	flash = UiKit.t("Deleted.")
	_load_slot(mini(slot, maxi(0, _slots_owned() - 1)))
	_rebuild()


# -------------------------------------------------------------------- input
func _span() -> float:
	return FORMATION_SPAN if mode == Mode.FORMATION else Tuning.PLAY_MAX_Y


## The drawn field: as tall as the panel, as wide as the list's real proportions
## make it at that height, centerd in the panel.
## HOW MUCH OF THE LIST IS SHOWN: as much as fills the panel at the list's true
## proportions (round 11: the field used a quarter of the board). What a man
## may be dragged to is still `_span()`; the rest is greyed, with their start
## line on it, so the empty ground is the ground between you and them.
func _view() -> float:
	var scale := BOARD.size.y / Tuning.LIST_W
	return minf(1.0, BOARD.size.x / (Tuning.LIST_H * scale))


func _field() -> Rect2:
	var scale := BOARD.size.y / Tuning.LIST_W
	var w: float = _view() * Tuning.LIST_H * scale
	return Rect2(BOARD.position.x + (BOARD.size.x - w) * 0.5, BOARD.position.y,
		w, BOARD.size.y)


## Normalised (x across the line, y out from your own rail) to screen, rotated
## exactly like the melee: y runs left to right, x runs top to bottom.
## THE MEN SIT INSIDE THE FRAME: positions map onto the field shrunk by a
## man's radius, so a man on the back rail is drawn whole rather than half off.
func _inner() -> Rect2:
	return _field().grow(-MARK_R)


func _to_screen(v: Vector2) -> Vector2:
	var f := _inner()
	return f.position + Vector2(v.y / _view() * f.size.x, v.x * f.size.y)


func _to_norm(p: Vector2) -> Vector2:
	var f := _inner()
	var d := p - f.position
	return Vector2(
		clampf(d.y / f.size.y, 0.02, 0.98),
		clampf(d.x / f.size.x * _view(), 0.0, _span()))


func _mark_at(p: Vector2) -> int:
	var five: Array = spots if mode == Mode.FORMATION else _play_spots()
	var best := -1
	var best_d := MARK_R + 6.0
	for i in five.size():
		var d := _to_screen(five[i]).distance_to(p)
		if d <= best_d:
			best_d = d
			best = i
	return best


func _unhandled_input(event: InputEvent) -> void:
	## Into the scene's own frame: it is drawn shifted when centred (`UiKit.frame`).
	event = make_input_local(event)
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
	_style_save()
	UiKit.ground(self)
	## LITERAL TITLE, THE VOICE UNDER IT (Pete, 29 Sep 2026).
	UiKit.text(self, font, UiKit.t("PLAYBOOK"), Vector2(LEFT_X, 40), 26, UiKit.INK)
	UiKit.text(self, font, UiKit.t("Your shapes and your openings."), Vector2(LEFT_X, 62), 14, UiKit.DIM)
	UiKit.purse(self, font, season.office.credits, Vector2(UiKit.right_edge(), 40), 18, UiKit.YOU, 200)
	_draw_slots()
	_draw_board()
	## WHAT THIS SHAPE DOES, over the field; a message takes its place.
	var line := flash if flash != "" else _shape_words()
	## CENTRED OVER THE FIELD it describes (round 6: it floated at the panel's edge).
	UiKit.mid(self, font, line, Vector2(BOARD.position.x, 80.0), 14,
		UiKit.YOU if flash != "" else UiKit.INK, BOARD.size.x)
	## HOW TO USE THE BOARD (blind review, 29 Sep: "nothing tells the player
	## how to edit").
	var hw := SLOT_W
	var hy := SLOT_Y + float(Chalkboard.SLOTS) * (SLOT_H + 6.0) + 22.0
	if mode == Mode.FORMATION:
		UiKit.text_fit(self, font, UiKit.t("Drag a man to where he starts."), Vector2(LEFT_X, hy), 14, UiKit.DIM, hw)
		UiKit.text_fit(self, font, UiKit.t("The line is as far as he may go."), Vector2(LEFT_X, hy + 18.0), 14, UiKit.DIM, hw)
	else:
		UiKit.text_fit(self, font, UiKit.t("Drag from a man"), Vector2(LEFT_X, hy), 14, UiKit.DIM, hw)
		UiKit.text_fit(self, font, UiKit.t("to draw his route."), Vector2(LEFT_X, hy + 18.0), 14, UiKit.DIM, hw)
		UiKit.text_fit(self, font, UiKit.t("Tap a man to clear his."), Vector2(LEFT_X, hy + 36.0), 14, UiKit.DIM, hw)


## WHAT THE SHAPE DOES, in a line — a preset's own blurb, or read off the spots.
## y is depth out from your rail (0 back, 0.15 on the line), x across it.
func _shape_words() -> String:
	if slot >= _slots_owned():
		return UiKit.t("Buy a slot to start drawing.")
	if mode == Mode.PLAY:
		var n := 0
		for r in routes:
			if not (r as Array).is_empty():
				n += 1
		return UiKit.t("%d of 5 men have a route. The rest go on their own.") % n
	for k in Tuning.FORMATIONS:
		var same := true
		var pre: Array = Tuning.FORMATIONS[k]["spots"]
		for i in 5:
			if (pre[i] as Vector2).distance_to(spots[i]) > 0.01:
				same = false
		if same:
			return UiKit.t(String(Tuning.FORMATIONS[k]["blurb"]))
	return _describe(spots)


static func _describe(sp: Array) -> String:
	var ys: Array[float] = []
	for v in sp:
		ys.append((v as Vector2).y)
	var up := 0
	var back := 0
	for y in ys:
		if y >= 0.10:
			up += 1
		elif y <= 0.05:
			back += 1
	if up == 5:
		return UiKit.t("Everyone up on the line. First to contact, nobody behind.")
	if back == 5:
		return UiKit.t("Everyone on the back rail. They cross the list to you.")
	var left := (ys[0] + ys[1]) * 0.5
	var right := (ys[3] + ys[4]) * 0.5
	if left - right > 0.05:
		return UiKit.t("The left pair leads, the right pair waits.")
	if right - left > 0.05:
		return UiKit.t("The right pair leads, the left pair waits.")
	var pairs := (left + right) * 0.5
	if pairs - ys[2] > 0.05:
		return UiKit.t("Center held back behind the pairs. Nothing comes through the middle.")
	if ys[2] - pairs > 0.05:
		return UiKit.t("Center out in front of the pairs. He meets them first.")
	return UiKit.t("A flat line, all five level.")


func _draw_slots() -> void:
	var owned := _slots_owned()
	for i in Chalkboard.SLOTS:
		var y := SLOT_Y + float(i) * (SLOT_H + 6.0)
		var r := Rect2(LEFT_X, y, SLOT_W, SLOT_H)
		if i >= owned:
			UiKit.panel(self, r, false)
			if i > owned:
				UiKit.icon(self, "lock", Vector2(LEFT_X + 10, y + 14), UiKit.DIM)
				UiKit.text(self, font, UiKit.t("Locked"), Vector2(LEFT_X + 32, y + 28), 14, UiKit.DIM)
			continue
		if i == slot:
			continue    ## the name field sits here
		UiKit.panel(self, r, false)
		var nm := ""
		if mode == Mode.FORMATION:
			nm = String(board.formations[i]["name"]) if i < board.formations.size() else UiKit.t("— empty —")
		else:
			nm = String(board.plays[i]["name"]) if i < board.plays.size() else UiKit.t("— empty —")
		UiKit.text(self, font, UiKit.clip(nm, 20), Vector2(LEFT_X + 12, y + 28),
			16, UiKit.INK)
		if mode == Mode.PLAY and i < board.plays.size():
			var f := int(board.plays[i]["formation"])
			var tag := UiKit.t("any") if f == Chalkboard.UNIVERSAL else UiKit.clip(board.formation_name(f), 10)
			UiKit.right(self, font, tag, Vector2(LEFT_X + SLOT_W - 10, y + 28), 14, UiKit.DIM, 120.0)


func _draw_board() -> void:
	var f := _field()
	draw_rect(f, Tuning.COL_GROUND)
	draw_rect(f, UiKit.FRAME, false, 2.0)
	## Your own back rail, on the left, because that is where it is in the fight.
	draw_line(f.position, f.position + Vector2(0, f.size.y), Tuning.COL_RAIL, 6.0)
	## The set-up line, painted rather than explained — and in formation mode the
	## ground past it is grayed, so the clamp under the finger has a reason on
	## screen before the finger ever finds it.
	var lx := _to_screen(Vector2(0.0, Tuning.SET_UP_LINE)).x
	var limit_x := lx if mode == Mode.FORMATION else _to_screen(Vector2(0.0, Tuning.PLAY_MAX_Y)).x
	draw_rect(Rect2(limit_x, f.position.y, f.end.x - limit_x, f.size.y), Color(0, 0, 0, 0.28))
	## THEIR START LINE, faint, so the far side reads as the other club's ground.
	var tx := _to_screen(Vector2(0.0, 1.0 - Tuning.SET_UP_LINE)).x
	if tx < f.end.x - 4.0:
		draw_line(Vector2(tx, f.position.y), Vector2(tx, f.end.y), Color(UiKit.DOWN, 0.45), 2.0)
		UiKit.right(self, font, UiKit.t("their line"), Vector2(tx - 6, f.position.y + 16), 12,
			UiKit.DOWN, 120.0)
	draw_line(Vector2(lx, f.position.y), Vector2(lx, f.end.y),
		Color(Tuning.COL_MARSHAL, 0.55), 2.0)
	UiKit.text(self, font, UiKit.t("start line"), Vector2(lx + 6, f.position.y + 16), 12, Tuning.COL_MARSHAL)
	UiKit.right(self, font, UiKit.t("toward them →"),
		Vector2(f.end.x - 8, f.end.y - 10), 14, UiKit.DIM, 160.0)

	if slot >= _slots_owned():
		## Nothing to draw: the line over the field says to unlock a slot.
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
		## THE POSITION COLOURS the rest of the game uses (Rail green, Flanker
		## orange, Center purple); gold under the finger.
		var col: Color = UiKit.UP if i == 0 or i == 4 else (UiKit.POS_FLANK if i != 2 else UiKit.POS_CENTER)
		draw_circle(at, MARK_R, UiKit.YOU if live else col)
		draw_arc(at, MARK_R, 0.0, TAU, 32, Tuning.COL_STEEL_DARK, 2.0)
		UiKit.raw(self, font, at + Vector2(-MARK_R, 7), UiKit.t(String(Tuning.POS_NAME[i])).substr(0, 1),
			HORIZONTAL_ALIGNMENT_CENTER, int(MARK_R * 2.0), 20, Tuning.COL_GROUND)


func _draw_route(from: Vector2, leg: Array, col: Color) -> void:
	if leg.is_empty():
		return
	var pts := PackedVector2Array([_to_screen(from)])
	for v in leg:
		pts.append(_to_screen(v))
	draw_polyline(pts, col, 3.0)
	var tip: Vector2 = pts[pts.size() - 1]
	draw_circle(tip, 5.0, col)
