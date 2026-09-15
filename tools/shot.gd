extends SceneTree
## Dev tool: render the bout screen to a PNG so the readability question from
## milestone 1 ("ten figures, phone screen, portrait — can you read the fight?")
## can be answered without a device.
##
##   xvfb-run -a godot --path . --script res://tools/shot.gd -- <frames> <out.png>

var frames_wanted := 600
var out_path := "user://shot.png"
var n := 0
var scene: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		frames_wanted = int(args[0])
	if args.size() > 1:
		out_path = args[1]
	scene = load("res://scenes/Bout.tscn").instantiate()
	root.add_child(scene)


func _process(_delta: float) -> bool:
	n += 1
	if n < frames_wanted:
		return false
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("wrote %s (%dx%d) at frame %d" % [out_path, img.get_width(), img.get_height(), n])
	return true
