extends SceneTree
var n := 0
func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/Start.tscn")
	root.add_child(packed.instantiate())
func _process(_d: float) -> bool:
	n += 1
	if n < 8:
		return false
	root.get_texture().get_image().save_png("res://shots/start.png")
	print("wrote start")
	return true
