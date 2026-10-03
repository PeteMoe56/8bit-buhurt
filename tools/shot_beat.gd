extends SceneTree
## THE END-OF-ROUND BEAT (3 Oct 2026): the field held with "END OF ROUND n" and
## the score, photographed half a second into the beat.
##
##   xvfb-run -a godot --path . --script res://tools/shot_beat.gd -- <out.png>

var out_path := "res://shots/beat.png"
var n := 0
var in_beat := 0
var scene: Node


func _initialize() -> void:
	Settings.tips_enabled = false
	seed(20260914)
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_path = args[0]
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if bool(scene.get("paused")):
		scene.call("_set_paused", false)
	if n == 4:
		scene._pick_strategy(Tuning.Strategy.RUSH_LEFT)
	## Straight to the round's end: the beat is what is being photographed,
	## not the fighting before it.
	if n == 40:
		scene.get("sim").skip_round()
	if float(scene.get("beat_t")) > 0.0:
		in_beat += 1
		if in_beat == 30:
			root.get_texture().get_image().save_png(out_path)
			print("wrote %s at frame %d" % [out_path, n])
			return true
	if n > 1500:
		print("no beat in 20000 frames")
		return true
	return false
