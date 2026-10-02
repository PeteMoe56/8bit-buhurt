extends SceneTree
## THE DRIVER — layer 3 of the novice testing program (1 Oct 2026). Holds the
## real game open and lets someone outside it play one tap at a time: an LLM
## playing a first-timer, looking at screenshots and thinking aloud.
##
##   xvfb-run -a godot --path . --resolution 960x540 --script res://tools/novice/drive.gd -- <dir> [seed]
##
## The game is PAUSED between commands, so a slow thinker does not lose a round.
## Commands go in <dir>/cmd.txt, one per write (the driver deletes it when read):
##
##   look                 just take a picture
##   press <n>            press button n from the last state's list
##   back                 the system Back
##   type <n> <text>      type into name box n
##   wait <frames>        let the game run (a fight, a timer); max 1800
##   drag <x1> <y1> <x2> <y2>   a finger drag on the fight (send a man)
##
## After each command the game runs a few frames, pauses, and writes
## <dir>/state_<k>.png and <dir>/state_<k>.json (scene, buttons with numbers,
## name boxes, the flash line), then <dir>/ready.txt holding k.

var dir := "/tmp/drive"
var k := 0
var settle := 0
var running := 0
var last_buttons: Array = []
var last_edits: Array = []


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		dir = String(a[0])
	var sd := int(a[1]) if a.size() > 1 else 11
	seed(sd)
	DirAccess.make_dir_recursive_absolute(dir)
	SaveGame.set_namespace("drive_%d" % sd)
	Settings.path = "user://drive_%d_settings.cfg" % sd
	Store.wallet_prefix = "drive_%d_" % sd
	for i in SaveGame.SLOTS:
		SaveGame.delete(i)
	Settings.tips_enabled = true
	Juice.set_enabled(false)
	change_scene_to_file("res://scenes/Start.tscn")
	settle = 8


func _process(_d: float) -> bool:
	if running > 0:
		running -= 1
		if running == 0:
			settle = 4
		return false
	if settle > 0:
		settle -= 1
		if settle == 0:
			paused = true
			_snapshot()
		return false
	var cmd_path := dir + "/cmd.txt"
	if not FileAccess.file_exists(cmd_path):
		return false
	var cmd := FileAccess.get_file_as_string(cmd_path).strip_edges()
	DirAccess.remove_absolute(cmd_path)
	if cmd == "quit":
		quit(0)
		return true
	paused = false
	_do(cmd)
	if running == 0:
		settle = 4
	return false


func _do(cmd: String) -> void:
	var p := cmd.split(" ", false)
	if p.is_empty():
		return
	match p[0]:
		"look":
			pass
		"press":
			var i := int(p[1]) if p.size() > 1 else -1
			if i >= 0 and i < last_buttons.size() and is_instance_valid(last_buttons[i]):
				var b: Button = last_buttons[i]
				if not b.disabled and b.is_visible_in_tree() \
						and layer_of(b) >= modal_layer(current_scene):
					b.pressed.emit()
		"back":
			AppLife.back_pressed()
		"type":
			var i := int(p[1]) if p.size() > 1 else -1
			var t := " ".join(p.slice(2))
			if i >= 0 and i < last_edits.size() and is_instance_valid(last_edits[i]):
				var e: LineEdit = last_edits[i]
				e.text = t
				e.text_changed.emit(t)
		"wait":
			running = clampi(int(p[1]) if p.size() > 1 else 60, 1, 1800)
		"drag":
			if p.size() >= 5 and current_scene != null and current_scene.has_method("_press"):
				var a := Vector2(float(p[1]), float(p[2]))
				var b2 := Vector2(float(p[3]), float(p[4]))
				current_scene.call("_press", a)
				current_scene.call("_extend", a.lerp(b2, 0.5))
				current_scene.call("_extend", b2)
				current_scene.call("_release", b2)


func _snapshot() -> void:
	k += 1
	var scene := current_scene
	var img := root.get_texture().get_image()
	img.save_png("%s/state_%d.png" % [dir, k])
	last_buttons = []
	last_edits = []
	if scene != null:
		_collect(scene)
	var bl: Array = []
	var veil := modal_layer(scene) if scene != null else -1000000
	for i in last_buttons.size():
		var b: Button = last_buttons[i]
		var r := b.get_global_rect()
		var t := String(b.text).strip_edges()
		if t == "" and b.has_meta("mark"):
			t = "[%s icon]" % String(b.get_meta("mark"))
		bl.append({"n": i, "label": t, "enabled": not b.disabled and layer_of(b) >= veil, "gold": b.has_meta("primary"),
			"x": int(r.position.x), "y": int(r.position.y), "w": int(r.size.x), "h": int(r.size.y)})
	var el: Array = []
	for i in last_edits.size():
		var e: LineEdit = last_edits[i]
		el.append({"n": i, "text": e.text, "hint": e.placeholder_text})
	var f = scene.get("flash") if scene != null else null
	var state := {"k": k, "scene": scene.scene_file_path.get_file() if scene != null else "",
		"buttons": bl, "name_boxes": el, "flash": String(f) if f != null else ""}
	var s: Season = Session.season
	if s != null:
		state["season"] = s.world.season
		state["event"] = s.world.event
	var fa := FileAccess.open("%s/state_%d.json" % [dir, k], FileAccess.WRITE)
	fa.store_string(JSON.stringify(state, "  "))
	fa.close()
	var r := FileAccess.open(dir + "/ready.txt", FileAccess.WRITE)
	r.store_string(str(k))
	r.close()


func _collect(n: Node) -> void:
	for c in n.get_children():
		if c is Button and (c as Button).is_visible_in_tree():
			last_buttons.append(c)
		elif c is LineEdit and (c as LineEdit).is_visible_in_tree():
			last_edits.append(c)
		_collect(c)


## A BUTTON UNDER A MODAL VEIL IS NOT THERE FOR A FINGER. The fight's tutorial
## card is a full-screen catch on a higher CanvasLayer; a tester pressing by
## number reached HOLD through it, which no thumb can (first-timer test, 1 Oct).
static func layer_of(n: Node) -> int:
	var p := n.get_parent()
	while p != null:
		if p is CanvasLayer:
			return (p as CanvasLayer).layer
		p = p.get_parent()
	return 0


static func modal_layer(root_n: Node) -> int:
	var best := -1000000
	var stack: Array = [root_n]
	var screen := UiKit.screen()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
			if c is Control and not (c is Button):
				var ctl := c as Control
				if ctl.is_visible_in_tree() and ctl.mouse_filter == Control.MOUSE_FILTER_STOP \
						and ctl.size.x >= screen.x * 0.9 and ctl.size.y >= screen.y * 0.9:
					best = maxi(best, layer_of(ctl))
	return best
