extends SceneTree
## Draw every formation's starting shape, LETTERED rather than named, so Pete can
## look at the geometry and say what it is — or that it should not exist.
##
##   xvfb-run -a godot --path . --script res://tools/shot_formations.gd -- out.png
##
## Same orientation as the fight: your rail on the left, theirs on the right, the
## five positions running down the screen.
class Shape extends Node2D:
	var font: Font
	var idx := 0
	var origin := Vector2.ZERO

	func _draw() -> void:
		var w := 430.0
		var h := 224.0
		var o := origin
		draw_rect(Rect2(o, Vector2(w, h)), Color("241f1a"))
		draw_rect(Rect2(o, Vector2(w, h)), Color("3d352b"), false, 2.0)

		## The ground: your half on the left, theirs on the right.
		var pad := 14.0
		var gw := w - pad * 2.0
		var gh := h - pad * 2.0 - 22.0
		var g := Rect2(o + Vector2(pad, pad + 22.0), Vector2(gw, gh))
		draw_rect(g, Color("6b5c43").darkened(0.35))
		draw_line(g.position + Vector2(gw * 0.5, 0), g.position + Vector2(gw * 0.5, gh),
			Color("3c3529"), 1.0)

		draw_string(font, o + Vector2(pad, 18), "%s" % char(65 + idx),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f2d13c"))

		var spots: Array = Tuning.FORMATIONS[Tuning.FORMATIONS.keys()[idx]]["spots"]
		## Their line, flat, for reference.
		for slot in 5:
			var ty := g.position.y + gh * float(Tuning.POS_X[slot])
			var tx := g.position.x + gw * 0.80
			draw_rect(Rect2(Vector2(tx - 7, ty - 7), Vector2(14, 14)), Color("5d666f"))

		## The set-up line, painted, because it is a rule and rules should be visible.
		var sl := g.position.x + gw * (Tuning.SET_UP_LINE * 1.6)
		draw_line(Vector2(sl, g.position.y), Vector2(sl, g.position.y + gh),
			Color("f2d13c") * Color(1, 1, 1, 0.5), 1.0)
		for slot in 5:
			var sp: Vector2 = spots[slot]
			var y := g.position.y + gh * sp.x
			var x := g.position.x + gw * (sp.y * 1.6)
			draw_rect(Rect2(Vector2(x - 10, y - 10), Vector2(20, 20)), Color("c0392b"))
			draw_rect(Rect2(Vector2(x - 10, y - 10), Vector2(20, 20)), Color("e8e4d8"), false, 1.0)
			var nm: String = Tuning.POS_NAME[slot]
			draw_string(font, Vector2(x + 16, y + 5), nm,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("968c78"))
		## The offsets, spelled out, because "a bit forward" is not a spec.
		var line := ""
		for slot in 5:
			line += "%.0f " % (float(spots[slot].y) * 100.0)
		draw_string(font, o + Vector2(pad + 30, 18),
			String(Tuning.FORMATIONS[Tuning.FORMATIONS.keys()[idx]]["name"])
			+ "   out from the rail  " + line.strip_edges(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("968c78"))


var n := 0
var out_path := "user://f.png"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_path = args[0]
	var font := ThemeDB.fallback_font
	var bg := ColorRect.new()
	bg.size = Vector2(960, 540)
	bg.color = Color("2e2a24")
	root.add_child(bg)
	for i in Tuning.FORMATIONS.size():
		var p := Shape.new()
		p.font = font
		p.idx = i
		p.origin = Vector2(28.0 + float(i % 2) * 456.0, 46.0 + float(i / 2) * 246.0)
		root.add_child(p)
	var title := Label.new()
	title.text = "    FORMATIONS  —  you on the left, them on the right; the yellow line is the 15% set-up limit"
	title.position = Vector2(20, 10)
	root.add_child(title)

func _process(_d: float) -> bool:
	n += 1
	if n < 6:
		return false
	root.get_texture().get_image().save_png(out_path)
	print("wrote ", out_path)
	quit(0)
	return true
