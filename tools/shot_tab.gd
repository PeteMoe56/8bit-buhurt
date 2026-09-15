extends SceneTree
var n := 0
var s: Node
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	s = load("res://scenes/Season.tscn").instantiate()
	root.add_child(s)
	s.set("tab", int(a[0]))
func _process(_d: float) -> bool:
	n += 1
	if n == 2:
		s.call("_rebuild")
	if n < 6: return false
	root.get_texture().get_image().save_png(String(OS.get_cmdline_user_args()[1]))
	print("wrote"); quit(0); return true
