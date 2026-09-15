extends SceneTree
var n := 0
func _initialize() -> void:
	var s: Node = load("res://scenes/Title.tscn").instantiate()
	root.add_child(s)
	## AFTER `_ready`, not before. `_new_club` rebuilds the UI and the CanvasLayer
	## it rebuilds does not exist until the node is in the tree.
	await process_frame
	s.call("_new_club", 0)
func _process(_d: float) -> bool:
	n += 1
	if n < 6:
		return false
	root.get_texture().get_image().save_png("res://shots/city_pick.png")
	print("done")
	return true
