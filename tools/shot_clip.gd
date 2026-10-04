extends SceneTree
## A SHORT CLIP OF A REAL BOUT, frame by frame (4 Oct 2026, Steam store GIFs).
##
##   bash tools/bb.sh shot clip 960x540 <out_dir> [frames] [step]
##   (run with --fixed-fps 60 so every frame is one sim step of real time)
##
## The fight opens, the coach drags his number 1 onto the nearest enemy along a
## bend, lets go, and the bout runs. Every `step`th frame from the drag on is
## written as out_dir/f_0000.png. ffmpeg/PIL turn them into a GIF.

var out_dir := "/tmp/clip"
var frames := 360
var step := 2
var n := 0
var saved := 0
var scene: Node
var path_pts: Array[Vector2] = []

const START := 24
const DRAG_FRAMES := 30


func _initialize() -> void:
	Settings.tips_enabled = false
	seed(20260914)
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out_dir = String(a[0])
	if a.size() > 1:
		frames = int(a[1])
	if a.size() > 2:
		step = int(a[2])
	DirAccess.make_dir_recursive_absolute(out_dir)
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(scene)


func _plan_drag() -> void:
	var sim: MeleeSim = scene.sim
	## The centre man (#3): his run crosses the middle of the field, where it
	## reads best in a small GIF.
	var mine: Array = []
	for m in sim.men:
		if m.team == 0 and m.standing():
			mine.append(m)
	var us = mine[mini(2, mine.size() - 1)]
	var best = null
	var bd := INF
	for m in sim.men:
		if m.team != 0 and m.standing() and m.pos.distance_to(us.pos) < bd:
			bd = m.pos.distance_to(us.pos)
			best = m
	var a: Vector2 = scene._to_screen(us.pos)
	var b: Vector2 = scene._to_screen(best.pos)
	## A bend, so it reads as drawn by a hand and not a straight order.
	var bend := -(b - a).orthogonal().normalized() * 36.0
	for i in DRAG_FRAMES + 1:
		var t := float(i) / DRAG_FRAMES
		path_pts.append(a.lerp(b, t) + bend * sin(PI * t))


func _process(_d: float) -> bool:
	n += 1
	if bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 4:
		scene._pick_strategy(Tuning.Strategy.RUSH_LEFT)
	if n >= 6:
		scene.set("tip", "")
	if n == START:
		_plan_drag()
		scene._press(path_pts[0])
	elif n > START and n <= START + DRAG_FRAMES:
		scene._extend(path_pts[n - START])
		if n == START + DRAG_FRAMES:
			scene._release(path_pts[-1])
	if n >= START and (n - START) % step == 0:
		var img := root.get_texture().get_image()
		img.save_png("%s/f_%04d.png" % [out_dir, saved])
		saved += 1
	if n >= START + frames:
		print("wrote %d frames to %s" % [saved, out_dir])
		return true
	return false
