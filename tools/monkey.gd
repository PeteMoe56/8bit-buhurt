extends SceneTree
## THE MONKEY. Drives the real game through its real screens by pressing random
## buttons, drawing random routes in fights and pressing Back, for a long time.
## It exists to find what no unit test reaches: a button that throws, a screen
## that strands the player, a state two screens disagree about.
##
##   godot --headless --fixed-fps 60 --path . --script res://tools/monkey.gd -- [steps] [seed]
##   bash tools/bb.sh monkey [steps] [seed]
##
## Any `SCRIPT ERROR` in its output is a bug. It also reports, itself:
##   STRANDED  a screen with no enabled button for 600 frames (not the fight)
##   STUCK     the same screen for 3000 steps with the season not moving
## and prints a line every season so a long run shows its progress.

var steps_wanted := 4000
var rng := RandomNumberGenerator.new()
var step := 0
var frames_here := 0
var here := ""
var steps_here := 0
var last_progress := ""
var no_progress_steps := 0
var problems: Array[String] = []
var seasons_seen := {}
var scenes_seen := {}
var presses := 0
var wait := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		steps_wanted = int(args[0])
	rng.seed = int(args[1]) if args.size() > 1 else 7
	seed(rng.seed)
	SaveGame.set_namespace("monkey%d" % rng.seed)
	Settings.path = "user://monkey%d_settings.cfg" % rng.seed
	Store.wallet_prefix = "monkey%d_" % rng.seed
	for i in SaveGame.SLOTS:
		SaveGame.delete(i)
	Juice.set_enabled(false)
	print("monkey: %d steps, seed %d" % [steps_wanted, rng.seed])
	change_scene_to_file("res://scenes/Start.tscn")


func _process(_delta: float) -> bool:
	var scene := current_scene
	if scene == null:
		return false
	var name: String = scene.scene_file_path.get_file()
	if name != here:
		here = name
		frames_here = 0
		steps_here = 0
		scenes_seen[name] = int(scenes_seen.get(name, 0)) + 1
	frames_here += 1
	if wait > 0:
		wait -= 1
		return false
	step += 1
	steps_here += 1
	_progress()
	if step >= steps_wanted:
		_finish()
		return true
	if name == "Melee.tscn":
		_fight(scene)
	else:
		_menu(scene)
	return false


## ------------------------------------------------------------------- menus
func _menu(scene: Node) -> void:
	var buttons := _buttons(scene)
	if buttons.is_empty():
		if frames_here > 600:
			_problem("STRANDED on %s: no enabled button for 600 frames" % here)
			AppLife.back_pressed()
			frames_here = 0
		return
	## Back now and then — never at the front door, where two backs quit.
	if here != "Start.tscn" and rng.randf() < 0.06:
		AppLife.back_pressed()
		wait = 2
		return
	## Type into a name box now and then.
	var edits := _edits(scene)
	if not edits.is_empty() and rng.randf() < 0.05:
		var e: LineEdit = edits[rng.randi() % edits.size()]
		var t: String = ["Ironside", "", "A Very Long Club Name That Runs On", "Ł ü é ß", "x"][rng.randi() % 5]
		e.text = t
		e.text_changed.emit(t)
		return
	var b: Button = _pick(buttons)
	presses += 1
	b.pressed.emit()
	wait = 1


## Buttons that move the season along are weighted up, or the monkey spends the
## night in the Settings screen.
func _pick(buttons: Array) -> Button:
	var weights: Array[float] = []
	var total := 0.0
	for b in buttons:
		var t: String = String(b.text).to_lower()
		var w := 1.0
		for k in ["fight", "sim it", "next", "continue", "play", "start a club", "take it",
				"end the season", "roll", "carry on", "back to the clubhouse", "anywhere"]:
			if t.find(k) != -1:
				w = 6.0
		weights.append(w)
		total += w
	var r := rng.randf() * total
	for i in buttons.size():
		r -= weights[i]
		if r <= 0.0:
			return buttons[i]
	return buttons[-1]


func _buttons(n: Node) -> Array:
	var out: Array = []
	_collect(n, out, _live_button)
	return out


func _live_button(c: Node) -> bool:
	if not (c is Button):
		return false
	var b := c as Button
	## QUIT IN WHATEVER LANGUAGE IS UP: the monkey changes the language in
	## Settings, and an English-only check pressed "Salir" and ended the run.
	## ON THE FRONT DOOR ONLY: Spanish "Walk out" is also "Salir", and skipping it
	## everywhere left the monkey stood at the walk-out for good.
	if here == "Start.tscn" and (String(b.text) == "Quit" or String(b.text) == UiKit.t("Quit")):
		return false
	return not b.disabled and b.is_visible_in_tree()


func _edits(n: Node) -> Array:
	var out: Array = []
	_collect(n, out, func(c): return c is LineEdit and (c as LineEdit).is_visible_in_tree())
	return out


func _collect(n: Node, out: Array, want: Callable) -> void:
	for c in n.get_children():
		if want.call(c):
			out.append(c)
		_collect(c, out, want)


## ------------------------------------------------------------------- fights
func _fight(scene: Node) -> void:
	var sim = scene.get("sim")
	var screen: int = int(scene.get("screen"))
	## Buttons first (the book, FIGHT, the corner, the report's way out).
	var buttons := _buttons(scene)
	if screen != 2 or rng.randf() < 0.02:
		if not buttons.is_empty() and rng.randf() < 0.5:
			_pick(buttons).pressed.emit()
			presses += 1
			wait = 1
			return
		if screen == 2 or rng.randf() < 0.1:
			return
	## In the fight: sometimes draw a route, sometimes skip the round, sometimes pause.
	var roll := rng.randf()
	if roll < 0.02 and scene.has_method("go_back"):
		scene.call("go_back")
		scene.call("go_back")
	elif roll < 0.05 and scene.has_method("_skip_round"):
		scene.call("_skip_round")
	elif roll < 0.12 and sim != null:
		var mine: Array = []
		for m in sim.men:
			if m.team == 0 and m.standing():
				mine.append(m)
		if not mine.is_empty():
			var m = mine[rng.randi() % mine.size()]
			var from: Vector2 = scene.call("_to_screen", m.pos)
			var to: Vector2 = from + Vector2(rng.randf_range(-200, 200), rng.randf_range(-120, 120))
			scene.call("_press", from)
			scene.call("_extend", from.lerp(to, 0.5))
			scene.call("_extend", to)
			scene.call("_release", to)
	## A fight left alone for too long is skipped a round at a time.
	if frames_here > 20000 and scene.has_method("_skip_round"):
		scene.call("_skip_round")


## ------------------------------------------------------------------- bookkeeping
func _progress() -> void:
	var s: Season = Session.season
	var key := "%s|%s" % [here, ("%d:%d" % [s.world.season, s.world.event]) if s != null else "-"]
	if s != null and not seasons_seen.has(s.world.season):
		seasons_seen[s.world.season] = true
		print("  step %d: season %d, %s, %d CC, %d men" % [step, s.world.season,
			s.tier_name(), s.office.credits, s.club.roster.size()])
	if s != null and s.club.roster.size() < MeleeClub.LINE_SIZE:
		_problem("SQUAD UNDER FIVE at season %d event %d (%d men)" % [s.world.season,
			s.world.event, s.club.roster.size()])
	if key == last_progress:
		no_progress_steps += 1
		if no_progress_steps == 3000:
			_problem("STUCK on %s for 3000 steps (%s)" % [here, key])
	else:
		last_progress = key
		no_progress_steps = 0


func _problem(p: String) -> void:
	if problems.has(p):
		return
	problems.append(p)
	print("PROBLEM: " + p)


func _finish() -> void:
	var s: Season = Session.season
	print("")
	print("monkey done: %d steps, %d presses, seasons reached %d" % [step, presses,
		s.world.season if s != null else 0])
	var names: Array = scenes_seen.keys()
	names.sort()
	print("screens visited: " + ", ".join(names.map(func(k): return "%s x%d" % [k, scenes_seen[k]])))
	for i in SaveGame.SLOTS:
		SaveGame.delete(i)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Store.wallet_path()))
	if problems.is_empty():
		print("MONKEY HOLDS (%d checks)" % step)
		quit(0)
	else:
		print("%d PROBLEMS" % problems.size())
		quit(1)
