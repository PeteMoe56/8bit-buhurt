extends SceneTree
## Dev tool: render the melee screen to PNG so "can you read the fight?" is
## answered with an image instead of an opinion. It has earned itself twice.
##
##   xvfb-run -a godot --path . --script res://tools/shot_melee.gd -- <frames> <out.png>

var want := 600
var out_path := "user://shot.png"
var n := 0
var scene: Node
var wheel_frames := 0


func _initialize() -> void:
	Settings.tips_enabled = false
	## A FIXED GLOBAL SEED, FIRST — `melee_scene._ready()` opens a standalone
	## exhibition with `_new_bout(randi())` and Godot seeds the global stream
	## randomly at startup, so without this the picture changes every run and the
	## tool cannot answer whether a CHANGE altered the screen. See shot_corner.gd.
	seed(20260914)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		want = int(args[0])
	if args.size() > 1:
		out_path = args[1]
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	## A headless window has no focus, and losing focus pauses the fight
	## (melee_scene._notification) — a capture tool must not be paused by that.
	if scene != null and bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 4:
		scene._pick_strategy(Tuning.Strategy.RUSH_LEFT)
	## THE PLANNING STAGE WAITS FOR READY (4 Oct 2026): press it, or every
	## capture is a picture of the men standing on their marks.
	if n > 4 and bool(scene.get("planning")):
		scene.call("_ready_up")
	## The corner waits for a click, so without this the bout never reaches
	## round two and every long capture is a picture of the corner.
	elif n > 4 and scene.screen == 2:
		scene._pick_strategy(Tuning.Strategy.RUSH_LEFT)
	## Draw a curved route onto an enemy a few frames before the capture, so the
	## shot shows what the player actually sees: the line, the highlight, and
	## the three options standing open.
	if want > 0 and n == want - 52:
		_draw_a_route()
	## Capture the moment the options are actually on screen, rather than
	## guessing a frame number and hoping.
	if want < 0:
		if scene.sim == null:
			return false
		## THE WHEEL (29 Sep): once it is up the fight is frozen, so wait a few
		## frames for it to be drawn rather than catching the frame it opened.
		if int(scene.get("wheel_man")) != -1:
			wheel_frames += 1
			if wheel_frames >= 4:
				var wi := root.get_texture().get_image()
				wi.save_png(out_path)
				print("wrote %s (wheel) at frame %d" % [out_path, n])
				return true
			return false
		for m in scene.sim.men:
			if m.team == 0 and m.prompt != null and not Tuning.contact_wheel:
				var im := root.get_texture().get_image()
				im.save_png(out_path)
				print("wrote %s (%dx%d) at frame %d" % [out_path, im.get_width(), im.get_height(), n])
				return true
		if n % 40 == 0:
			_draw_a_route()
		if n > 6000:
			print("no prompt appeared in 6000 frames")
			return true
		return false
	if n < want:
		return false
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("wrote %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
	return true


func _draw_a_route() -> void:
	var sim: MeleeSim = scene.sim
	if sim == null or sim.phase != MeleeSim.Phase.LIVE:
		return
	for m in sim.men:
		if m.team != 0 or not m.standing() or m.under_orders():
			continue
		var foe := -1
		var best := 1e9
		for e in sim.men:
			if e.team == 1 and e.standing():
				var d := m.pos.distance_to(e.pos)
				if d < best:
					best = d
					foe = e.idx
		if foe == -1:
			return
		var a: Vector2 = m.pos
		var b: Vector2 = sim.men[foe].pos
		var path: Array[Vector2] = []
		for i in range(1, 4):
			var t := float(i) / 4.0
			var p := a.lerp(b, t)
			p.x += sin(t * PI) * 42.0     ## an arc, not a straight line
			path.append(p)
		sim.give_order(m.idx, path, foe)
		return
