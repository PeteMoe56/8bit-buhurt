extends SceneTree
## HOW WIDE IS THIS LINE AT THIS SIZE (29 Sep 2026) — the translation fixer's
## ruler. One line per string on stdin-less args: `bb probe width <px> "a" "b" …`,
## prints the width of each in the game's body font, so a shorter translation is
## measured before it is written rather than after the ink sweep fails it.
func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var px := int(a[0]) if a.size() > 0 else 11
	var f := UiKit.body()
	for i in range(1, a.size()):
		var w := f.get_string_size(String(a[i]), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		print("%4d  %s" % [int(ceil(w)), a[i]])
	quit()
