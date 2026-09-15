extends SceneTree
var want := 300
var out_path := "user://m.png"
var n := 0
var scene: Node
func _initialize() -> void:
	## A FIXED GLOBAL SEED, FIRST — `melee_scene._ready()` opens a standalone
	## exhibition with `_new_bout(randi())` and Godot seeds the global stream
	## randomly at startup, so without this the picture changes every run and the
	## tool cannot answer whether a CHANGE altered the screen. See shot_corner.gd.
	seed(20260914)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: want = int(args[0])
	if args.size() > 1: out_path = args[1]
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(scene)
func _process(_d: float) -> bool:
	n += 1
	if n == 4:
		scene._pick_strategy(Tuning.Strategy.RUSH_LEFT)
	elif n > 4 and scene.screen == 2:
		scene._pick_strategy(Tuning.Strategy.RUSH_LEFT)
	if n < want: return false
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("wrote ", out_path)
	quit(0)
	return true
