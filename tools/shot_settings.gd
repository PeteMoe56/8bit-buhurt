extends SceneTree
func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/Settings.tscn")
	var s: Node = packed.instantiate()
	root.add_child(s)
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("res://shots/settings.png")
	print("shot written")
	quit(0)
