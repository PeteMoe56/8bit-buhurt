extends SceneTree
## THE MARK, ON THE THREE SCREENS IT LANDS ON.
##
##   xvfb-run -a godot --path . --script res://tools/shot_brand.gd
##
## Front door, slot picker, and one dense menu — the last one being the whole
## question about the watermark. A logo on a title screen is easy; a logo behind
## a thirteen-row roster is the one that either works or eats the numbers, and
## the only way to know which is to photograph it behind the numbers.
var n := 0
var stage := 0
var scene: Node = null

const SHOTS := [
	["res://scenes/Start.tscn", -1, "brand_start"],
	["res://scenes/Title.tscn", -1, "brand_title"],
	["res://scenes/Season.tscn", 1, "brand_squad"],
	["res://scenes/Season.tscn", 3, "brand_clubhouse"],
]

func _initialize() -> void:
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	Session.season.decline_bid()

func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	n = 0
	if scene != null:
		root.get_texture().get_image().save_png(
			"res://shots/%s.png" % String(SHOTS[stage - 1][2]))
		print("wrote %s" % String(SHOTS[stage - 1][2]))
		scene.queue_free()
		scene = null
	if stage >= SHOTS.size():
		return true
	var row: Array = SHOTS[stage]
	scene = load(String(row[0])).instantiate()
	if int(row[1]) >= 0:
		scene.set("tab", int(row[1]))
	root.add_child(scene)
	if int(row[1]) >= 0 and scene.has_method("_rebuild"):
		scene.call("_rebuild")
	stage += 1
	return false
