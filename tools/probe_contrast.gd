extends SceneTree
func _initialize() -> void:
	print("kits:")
	for c in IconBank.KIT_COLOURS:
		print("  ", c.to_html(false), " luma=", "%.3f" % IconBank.luma(c))
	print("marks:")
	for c in IconBank.MARK_COLOURS:
		print("  ", c.to_html(false), " luma=", "%.3f" % IconBank.luma(c))
	var worst := 9.0
	for k in IconBank.KIT_COLOURS:
		for m in IconBank.MARK_COLOURS:
			var d: float = absf(IconBank.luma(k) - IconBank.luma(m))
			if d < worst:
				worst = d
			if d < IconBank.MIN_CONTRAST:
				print("  FAILS: ", k.to_html(false), " vs ", m.to_html(false), " d=", "%.3f" % d)
	print("worst pairing delta = ", "%.3f" % worst, "  threshold = ", IconBank.MIN_CONTRAST)
	quit(0)
