class_name Pad
## A CONTROLLER IN THE MENUS (Steam Deck, 4 Oct 2026).
##
## Every menu control in this game is already a Godot `Button` (UiKit.button), so
## Godot's own focus does the walking: the d-pad and the left stick are bound to
## ui_up/down/left/right out of the box and move focus to the nearest button in
## that direction. What it did NOT have:
##
##   - A and B. Godot's default map gives ui_accept and ui_cancel keys only. They
##     are added here, at launch, so no project file has to carry them.
##   - Something focused to start from. A screen builds with nothing focused, and
##     a direction with nothing focused does nothing. `AppLife` asks `pick()` for
##     a button the moment pad input arrives with nothing focused — including
##     right after a screen rebuilds under the focus, which is every press of
##     every tab in this game. It lands on the button with the same words, or the
##     one nearest where focus was, so a rebuild does not throw the player back to
##     the top of the screen.
##   - The drawn rows. A team sheet, a calendar, a slot list are drawn by hand
##     with a flat hit box over each row, and those hit boxes were taken out of
##     focus on purpose (a filled focus box would paint over the row). `row()`
##     puts them back in with a hollow gold frame instead.
##
## A screen may offer `pad_default() -> Control` to say where focus starts; the
## fallback is the first button in the tree that is not Back or Menu.

const FRAME_PX := 2

static var _setup_done := false


## Add the pad's buttons to the UI actions. Idempotent.
static func setup() -> void:
	if _setup_done:
		return
	_setup_done = true
	_add_button("ui_accept", JOY_BUTTON_A)
	_add_button("ui_cancel", JOY_BUTTON_B)
	## Shoulders step a screen's tabs (the season screen reads these).
	_ensure_action("pad_tab_prev")
	_add_button("pad_tab_prev", JOY_BUTTON_LEFT_SHOULDER)
	_ensure_action("pad_tab_next")
	_add_button("pad_tab_next", JOY_BUTTON_RIGHT_SHOULDER)


static func _ensure_action(a: String) -> void:
	if not InputMap.has_action(a):
		InputMap.add_action(a)


static func _add_button(action: String, button: JoyButton) -> void:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == button:
			return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = -1
	InputMap.action_add_event(action, ev)


## Is this a key or pad press that moves or uses focus? Mouse and touch are not:
## they point at what they want.
static func is_nav(event: InputEvent) -> bool:
	if not (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return false
	for a in ["ui_up", "ui_down", "ui_left", "ui_right", "ui_accept", "ui_focus_next", "ui_focus_prev"]:
		if event.is_action_pressed(a, false, true):
			return true
	return false


## A DRAWN ROW'S HIT BOX, back in the focus chain, framed instead of filled.
static func row(b: Button) -> Button:
	b.flat = true
	b.focus_mode = Control.FOCUS_ALL
	var sb := UiKit.focus_ring(1.0)
	b.add_theme_stylebox_override("focus", sb)
	return b


## Every button a pad could land on: on screen, enabled, focusable — and, when a
## modal is up, only the ones drawn after it. A modal in this game is a control
## laid over the whole screen to catch taps (the captain market, a confirm); the
## buttons under it are still "visible", and a d-pad would walk straight into them.
static func candidates(root: Node) -> Array[Control]:
	var flat: Array[Control] = []
	if root == null:
		return flat
	_collect(root, flat)
	var screen := root.get_viewport().get_visible_rect().size if root.is_inside_tree() else Vector2(960, 540)
	var cut := -1
	for k in flat.size():
		var c := flat[k]
		if c.mouse_filter == Control.MOUSE_FILTER_STOP and c.focus_mode == Control.FOCUS_NONE:
			var r := c.get_global_rect()
			if r.size.x >= screen.x * 0.9 and r.size.y >= screen.y * 0.9:
				cut = k
	var out: Array[Control] = []
	for k in range(cut + 1, flat.size()):
		var c := flat[k]
		if c is BaseButton and c.focus_mode != Control.FOCUS_NONE and not (c as BaseButton).disabled:
			out.append(c)
	return out


static func _collect(n: Node, out: Array[Control]) -> void:
	if n is CanvasLayer and not (n as CanvasLayer).visible:
		return
	if n is CanvasItem and not (n as CanvasItem).visible:
		return
	if n is Control and String(n.name).begins_with("HitSlop"):
		return
	if n is Control:
		var c := n as Control
		if c is BaseButton or (c.mouse_filter == Control.MOUSE_FILTER_STOP and c.focus_mode == Control.FOCUS_NONE):
			out.append(c)
	for ch in n.get_children():
		_collect(ch, out)


## THE D-PAD, BY GEOMETRY. Godot's own focus neighbours only search inside the
## control a button sits under, and every button in this game sits straight on a
## CanvasLayer with no control above it — so its neighbour search found nothing,
## and a d-pad press went nowhere. This finds the next button in a direction from
## where they are on screen: ahead of the focused one, nearest along the way,
## with sideways drift costing three times as much (so down means down the
## column, not across to the far side of the screen).
static func neighbor(from: Control, dir: Vector2, all: Array[Control]) -> Control:
	var a := from.get_global_rect()
	var best: Control = null
	var bs := INF
	for c in all:
		if c == from:
			continue
		var b := c.get_global_rect()
		var along: float
		var across: float
		if dir.x != 0.0:
			along = (b.position.x - a.end.x) if dir.x > 0.0 else (a.position.x - b.end.x)
			if (b.get_center().x - a.get_center().x) * dir.x <= 1.0:
				continue
			across = maxf(0.0, maxf(b.position.y - a.end.y, a.position.y - b.end.y))
		else:
			along = (b.position.y - a.end.y) if dir.y > 0.0 else (a.position.y - b.end.y)
			if (b.get_center().y - a.get_center().y) * dir.y <= 1.0:
				continue
			across = maxf(0.0, maxf(b.position.x - a.end.x, a.position.x - b.end.x))
		var s := maxf(along, 0.0) + 3.0 * across
		## Overlapping lanes first: a button straight ahead beats a nearer one off
		## to the side, by a fixed margin.
		if across > 0.0:
			s += 40.0
		if s < bs:
			bs = s
			best = c
	return best


## Where focus should go when there is none: the same words as last time, else
## the nearest to where it was, else the screen's own choice, else the first
## button that is not a way out.
static func pick(scene: Node, last_text: String, last_pos: Vector2) -> Control:
	var all := candidates(scene)
	if all.is_empty():
		return null
	if last_text != "":
		for c in all:
			if c is Button and (c as Button).text == last_text:
				return c
	if last_pos != Vector2.INF:
		var best: Control = null
		var bd := INF
		for c in all:
			var d := c.get_global_rect().get_center().distance_squared_to(last_pos)
			if d < bd:
				bd = d
				best = c
		return best
	if scene.has_method("pad_default"):
		var c = scene.call("pad_default")
		if c is Control and all.has(c):
			return c
	var outs := [UiKit.t("Back"), UiKit.t("Menu")]
	for c in all:
		if not (c is Button and outs.has((c as Button).text.strip_edges())):
			return c
	return all[0]


## STEAM'S KEYBOARD FOR A TEXT FIELD, on a Steam Deck or in Big Picture. Valve's
## Deck Verified asks that a game never leave a pad player at a text box with no
## way to type. Does nothing anywhere Steam is not running.
static func on_screen_keyboard(e: LineEdit) -> void:
	var s := Achievements.steam()
	if s == null or not is_instance_valid(e):
		return
	if s.has_method("isSteamRunningOnSteamDeck") and not bool(s.call("isSteamRunningOnSteamDeck")) \
			and not (s.has_method("isSteamInBigPictureMode") and bool(s.call("isSteamInBigPictureMode"))):
		return
	var r := e.get_global_rect()
	if s.has_method("showFloatingGamepadTextInput"):
		s.call("showFloatingGamepadTextInput", 0, int(r.position.x), int(r.position.y),
			int(r.size.x), int(r.size.y))
