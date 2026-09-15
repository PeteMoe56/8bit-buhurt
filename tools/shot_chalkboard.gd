extends SceneTree
## Dev tool: render the Chalkboard, with a shape and a play already drawn, so
## the screen can be looked at rather than reasoned about.
##
##   xvfb-run -a godot --path . --script res://tools/shot_chalkboard.gd -- <mode> <out.png>

var mode := "formation"
var out_path := "user://chalkboard.png"
var n := 0
var scene: Node


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mode = String(args[0])
	if args.size() > 1:
		out_path = String(args[1])
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.office.credits = 60
	var b := s.board
	b.unlock_formation(s.office)
	b.unlock_formation(s.office)
	b.unlock_play(s.office)
	b.unlock_play(s.office)
	b.save_formation(0, "Bunker", [Vector2(0.10, 0.02), Vector2(0.28, 0.02),
		Vector2(0.50, 0.13), Vector2(0.72, 0.02), Vector2(0.90, 0.02)])
	b.save_formation(1, "Wide", [Vector2(0.04, 0.15), Vector2(0.24, 0.10),
		Vector2(0.50, 0.06), Vector2(0.76, 0.10), Vector2(0.96, 0.15)])
	var r := Chalkboard.blank_routes()
	r[Tuning.Pos.RAIL_L] = [Vector2(0.06, 0.30), Vector2(0.14, 0.52)] as Array[Vector2]
	r[Tuning.Pos.FLANK_L] = [Vector2(0.30, 0.34), Vector2(0.22, 0.54)] as Array[Vector2]
	r[Tuning.Pos.CENTER] = [Vector2(0.50, 0.28)] as Array[Vector2]
	b.save_play(0, "Left rail crash", r, int(b.formations[0]["id"]))
	var u := Chalkboard.blank_routes()
	u[Tuning.Pos.RAIL_R] = [Vector2(0.90, 0.34), Vector2(0.70, 0.50)] as Array[Vector2]
	b.save_play(1, "Right pinch", u, Chalkboard.UNIVERSAL)
	s.formation_id = int(b.formations[0]["id"])
	Session.season = s
	scene = load("res://scenes/Chalkboard.tscn").instantiate()
	root.add_child(scene)


func _process(_d: float) -> bool:
	n += 1
	if n == 2 and mode == "play":
		scene.mode = 1
		scene._load_slot(0)
		scene._rebuild()
	if n < 8:
		return false
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("wrote ", out_path, " ", img.get_width(), "x", img.get_height())
	quit(0)
	return true
