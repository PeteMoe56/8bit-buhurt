extends SceneTree
## Dev tool: one face, the other face, and the two of them together.
##
##   xvfb-run -a godot --path . --script res://tools/shot_mix.gd -- <out.png>

var out_path := "user://mix.png"
var n := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_path = String(args[0])
	root.add_child(Sheet.new())


func _process(_d: float) -> bool:
	n += 1
	if n < 6:
		return false
	root.get_texture().get_image().save_png(out_path)
	print("wrote ", out_path)
	quit(0)
	return true


class Sheet extends Node2D:
	var rail: Font
	var plate: Font

	const ROWS := [
		["11", "Merrick", "RAIL", "26", "12/13", "Steady"],
		["47", "Ulme", "FLANKER", "31", "10/13", "Toxic"],
		["8", "Coyle", "CENTER", "24", "13/13", "Exceptional"],
		["109", "Wexley", "RAIL", "29", "9/13", "Sour"],
	]
	const COLS := [24.0, 60.0, 172.0, 262.0, 300.0, 366.0]

	func _draw() -> void:
		rail = load("res://fonts/BuhurtRail-Regular.ttf") as Font
		plate = load("res://fonts/BuhurtPlate-Regular.ttf") as Font
		draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), UiKit.BG)
		_block(Vector2(16, 20), "ALL PLATE", plate, 16, plate, 8, plate, 8)
		_block(Vector2(490, 20), "ALL RAIL", rail, 16, rail, 8, rail, 8)
		_block(Vector2(16, 250), "PLATE HEADS, RAIL ROWS", plate, 16, plate, 8, rail, 8)
		_block(Vector2(490, 250), "PLATE HEADS, RAIL AT 16", plate, 16, plate, 8, rail, 16)

	func _block(at: Vector2, label: String, tf: Font, tp: int,
			hf: Font, hp: int, bf: Font, bp: int) -> void:
		draw_string(plate, at + Vector2(0, 10), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, UiKit.YOU)
		draw_string(tf, at + Vector2(0, 34), "Ironhold Company",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, tp, UiKit.INK)
		var y := at.y + 54.0
		var heads := ["#", "NAME", "POST", "AGE", "KIT", "MOOD"]
		for i in heads.size():
			draw_string(hf, Vector2(at.x + COLS[i], y), String(heads[i]),
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, hp, UiKit.DIM)
		y += float(bp) + 8.0
		for r in ROWS:
			for i in r.size():
				var col := UiKit.INK if i != 5 else UiKit.DIM
				draw_string(bf, Vector2(at.x + COLS[i], y), String(r[i]),
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, bp, col)
			y += float(bp) + 8.0
		y += 6.0
		draw_string(bf, Vector2(at.x, y), "39 · age 26 · Toxic · to 46",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, bp, UiKit.DIM)
		y += float(bp) + 6.0
		draw_string(bf, Vector2(at.x, y), "Purse 1,240 cr   W 7  L 2  D 1",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, bp, UiKit.DIM)
