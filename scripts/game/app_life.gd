class_name AppLife
extends Node
## THE APP'S OWN LIFE: pause, close, back and the screen wipe. One node, parented
## with the Juice layer (so it exists on every screen, headless included), and the
## only place any of this is handled.
##
## 1. SAVE WHEN THE APP LEAVES. A phone call, the home button, alt-tab, the window
##    closing: the season is written before the OS gets a chance to kill us. The
##    game already autosaves after every action; this covers the gap between the
##    last action and the kill.
## 2. BACK IS ONE HANDLER. Android's back gesture (and Esc on desktop) used to quit
##    the app from any screen, because Godot quits on back by default and nothing
##    answered it. `quit_on_go_back` is now off and every back lands here:
##      - the screen gets first say: if it has `go_back() -> bool` and returns
##        true, it handled it (closed a modal, held the fight, asked to quit);
##      - otherwise it is the screen's own Back: `UiKit.back()`.
## 3. NO TAPS DURING THE WIPE. A tap landing in the 130 ms cover between screens
##    still reached the old screen's buttons — a double-tapped Back skipped a
##    screen, and "Sim it" could fire after "Fight".

signal app_paused
signal app_resumed

static var _me: AppLife = null


static func node() -> AppLife:
	return _me if _me != null and is_instance_valid(_me) else null


func _enter_tree() -> void:
	_me = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	## A WINDOW THAT CHANGES SIZE LAYS THE SCREEN OUT AGAIN (playtest 30 Sep:
	## fullscreen left the title's buttons where the 960-wide window had put
	## them). Screens build their controls once, in `_ready`, against the canvas
	## they were born on; this hands them the new one.
	var r := get_tree().root
	if not r.size_changed.is_connected(_resized):
		r.size_changed.connect(_resized)


func _resized() -> void:
	## Deferred: the canvas size settles after the signal.
	call_deferred("_relayout")


func _relayout() -> void:
	var s := get_tree().current_scene
	if s == null:
		return
	for m in ["_rebuild", "_build"]:
		if s.has_method(m):
			s.call(m)
			break
	if s is CanvasItem:
		(s as CanvasItem).queue_redraw()


func _exit_tree() -> void:
	if _me == self:
		_me = null


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, \
		NOTIFICATION_WM_CLOSE_REQUEST:
			_leaving()
		NOTIFICATION_APPLICATION_RESUMED:
			app_resumed.emit()
			## THE STORE IS ASKED AGAIN (3 Oct 2026, audit): purchases that
			## finished while the app was away are only reported when asked.
			Store.on_resume()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			app_resumed.emit()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back_pressed()


func _leaving() -> void:
	app_paused.emit()
	## NOT MID-BOUT. A bout is posted when it ends; saving half of one would
	## write a season whose fixture has not been played yet, which it already is.
	if not Session.in_season():
		Session.autosave()


func _input(event: InputEvent) -> void:
	if Juice.wiping() and (event is InputEventMouseButton or event is InputEventScreenTouch
			or event is InputEventScreenDrag or event is InputEventKey):
		get_viewport().set_input_as_handled()
		return
	## ALT+ENTER AND F11, the PC habit (Steam, 3 Oct 2026).
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_F11
			or (event.keycode == KEY_ENTER and event.alt_pressed)) and Settings.is_desktop():
		get_viewport().set_input_as_handled()
		Settings.toggle_fullscreen()
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		back_pressed()


## THE BACK BUTTON, from anywhere. Public so the suite can press it.
static func back_pressed() -> void:
	if Juice.wiping():
		return
	var loop := Engine.get_main_loop()
	if not (loop is SceneTree):
		return
	var scene := (loop as SceneTree).current_scene
	if scene != null and scene.has_method("go_back"):
		if bool(scene.call("go_back")):
			return
	UiKit.back("res://scenes/Season.tscn" if Session.season != null
		else "res://scenes/Title.tscn")
