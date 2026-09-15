extends SceneTree
## Dev tool: every mark in the bank, drawn at badge size and at table size.
##
## A mark is only a mark if it reads. This renders the whole bank on one sheet
## so each one can be looked at rather than argued about, and it draws each twice
## — big, and at the 13-pixel size a league table actually uses, which is where
## a clever silhouette turns into a smudge.
##
##   xvfb-run -a godot --path . --script res://tools/shot_icons.gd -- <out.png>

var out_path := "user://icons.png"
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
		var font := ThemeDB.fallback_font
		draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), UiKit.BG)
		var per_row := 7
		for i in IconBank.count():
			var e: Dictionary = IconBank.ICONS[i]
			var col := i % per_row
			var row := int(i / per_row)
			var at := Vector2(84.0 + float(col) * 126.0, 92.0 + float(row) * 162.0)
			var kit: Color = IconBank.KIT_COLORS[i % IconBank.KIT_COLORS.size()]
			var mark: Color = IconBank.MARK_COLORS[i % IconBank.MARK_COLORS.size()]
			UiKit.badge(self, at, 40.0, kit, mark, int(e["id"]))
			## The same mark at league-table size, right beside it.
			UiKit.badge(self, at + Vector2(56, 30), 13.0, kit, mark, int(e["id"]))
			UiKit.text(self, font, String(e["name"]), at - Vector2(40, -62), 14, UiKit.INK)
			UiKit.text(self, font, "%s · %d cr" % [String(e["pack"]), int(e["cost"])],
				at - Vector2(40, -78), 11, UiKit.DIM)
