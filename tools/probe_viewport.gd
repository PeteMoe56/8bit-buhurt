extends SceneTree
## WHAT `stretch/aspect = "expand"` ACTUALLY HANDS THE GAME.
##
## `root.size` is the WINDOW in pixels. The number every layout needs is the
## canvas-space visible rect, which is what the stretch system computes and what
## a `draw_rect` is measured in. They are not the same number and the difference
## is the whole bug.
var n := 0
func _initialize() -> void:
	root.add_child(Node2D.new())

func _process(_d: float) -> bool:
	n += 1
	if n < 3:
		return false
	print("window=%s  canvas_visible=%s  ratio=%.3f"
		% [str(DisplayServer.window_get_size()),
			str(root.get_visible_rect().size),
			root.get_visible_rect().size.x / root.get_visible_rect().size.y])
	return true
