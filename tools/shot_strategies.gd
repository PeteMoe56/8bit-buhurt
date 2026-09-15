extends SceneTree
## Draw what each strategy tells the five to do: where each man is sent once the
## whistle goes. Lettered, not named, for the same reason the formations were.
##
##   xvfb-run -a godot --path . --script res://tools/shot_strategies.gd -- out.png
class Shape extends Node2D:
	var font: Font
	var idx := 0
	var origin := Vector2.ZERO

	func _draw() -> void:
		var w := 296.0
		var h := 224.0
		var o := origin
		draw_rect(Rect2(o, Vector2(w, h)), Color("241f1a"))
		draw_rect(Rect2(o, Vector2(w, h)), Color("3d352b"), false, 2.0)
		var pad := 12.0
		var gw := w - pad * 2.0
		var gh := h - pad * 2.0 - 24.0
		var g := Rect2(o + Vector2(pad, pad + 24.0), Vector2(gw, gh))
		draw_rect(g, Color("6b5c43").darkened(0.35))
		## Their rail is the right-hand edge; the halfway line is the middle.
		draw_line(g.position + Vector2(gw * 0.5, 0), g.position + Vector2(gw * 0.5, gh),
			Color("3c3529"), 1.0)

		var key = Tuning.STRATEGIES.keys()[idx]
		draw_string(font, o + Vector2(pad, 18), "%s" % char(65 + idx),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2d13c"))
		draw_string(font, o + Vector2(pad + 22, 18), String(Tuning.STRATEGIES[key]["name"]),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e8e4d8"))

		var start: Array = Tuning.FORMATIONS[Tuning.Formation.TWO_ONE_TWO]["spots"]
		for slot in 5:
			var z := Tuning.plan_target(key, slot, float(start[slot].x))
			var a := Vector2(g.position.x + gw * (float(start[slot].y) * 1.2),
				g.position.y + gh * float(start[slot].x))
			var b := Vector2(g.position.x + gw * float(z.y),
				g.position.y + gh * float(z.x))
			draw_line(a, b, Color("f2d13c") * Color(1, 1, 1, 0.55), 2.0)
			## Where he ends up.
			draw_rect(Rect2(b - Vector2(7, 7), Vector2(14, 14)), Color("c0392b"))
			draw_rect(Rect2(b - Vector2(7, 7), Vector2(14, 14)), Color("e8e4d8"), false, 1.0)
			## Where he started.
			draw_rect(Rect2(a - Vector2(4, 4), Vector2(8, 8)), Color("5d666f"))
			draw_string(font, b + Vector2(11, 5), Tuning.POS_NAME[slot],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("968c78"))


var n := 0
var out_path := "user://s.png"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_path = args[0]
	var font := ThemeDB.fallback_font
	var bg := ColorRect.new()
	bg.size = Vector2(960, 540)
	bg.color = Color("2e2a24")
	root.add_child(bg)
	for i in Tuning.STRATEGIES.size():
		var p := Shape.new()
		p.font = font
		p.idx = i
		p.origin = Vector2(16.0 + float(i % 3) * 310.0, 46.0 + float(i / 3) * 246.0)
		root.add_child(p)
	var title := Label.new()
	title.text = "    STRATEGIES  —  grey square is where he starts, red is where the plan sends him"
	title.position = Vector2(12, 10)
	root.add_child(title)

func _process(_d: float) -> bool:
	n += 1
	if n < 6:
		return false
	root.get_texture().get_image().save_png(out_path)
	print("wrote ", out_path)
	quit(0)
	return true
