extends SceneTree
## Dev tool: the face, at every size the game is allowed to ask for.
##
## A layout you cannot see is a layout you cannot check, and a pixel face is the
## purest case of it — the difference between a crisp 16 and a smeared 17 does
## not show up in any number the engine will hand you. This draws the real
## strings at the real sizes so the import settings can be looked at.
##
##   xvfb-run -a godot --path . --script res://tools/shot_type.gd -- <out.png>

var out_path := "user://type.png"
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
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("wrote ", out_path)
	quit(0)
	return true


class Sheet extends Node2D:
	func _draw() -> void:
		var f := UiKit.body()
		draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), UiKit.BG)
		var y := 26.0
		draw_string(f, Vector2(20.0, y), "8-BIT BUHURT: COMBAT CLUB",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, UiKit.YOU)
		y += 34.0
		var lines := [
			"Merrick  Ulme  Coyle  Calder  Wexley",
			"39 · age 26 · Toxic",
			"FLANKER 10/13 · RAIL 12 · to 46",
			"PURSE 1,240 cr   W 7  L 2  D 1",
			"abcdefghijklmnopqrstuvwxyz",
			"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
			"0123456789 ()[]/%+-:;!?'\"·",
		]
		for px in [8, 16, 24]:
			draw_string(f, Vector2(20.0, y), "— size %d —" % px,
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, UiKit.DIM)
			y += 14.0
			for s in lines:
				draw_string(f, Vector2(20.0, y), String(s),
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, px, UiKit.INK)
				y += float(px) + 4.0
				if px > 8 and y > 470.0:
					break
			y += 10.0
