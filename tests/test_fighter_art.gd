extends SceneTree
## THE FIGHTER SPRITE WEARS THE CLUB'S KIT (6 Oct 2026).
##
##   godot --headless --path . --script res://tests/test_fighter_art.gd
##
## The sprite is a mask in nine key colours. If a single key pixel survives the
## bake it shows on the list as raw magenta, green or blue — so every opaque pixel
## of the shipped frame has to be either a key or the outline, and none of them
## may still be a key afterwards.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the fighter sprite ===\n")
	_test_the_frame_is_all_keys()
	_test_the_bake_leaves_no_key()
	print("")
	if failures.is_empty():
		print("THE SPRITE HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


func _keys() -> Array:
	return FighterArt.palette(Color.BLACK, Color.BLACK).map(func(p): return p[0])


func _src() -> Image:
	var tex: Texture2D = ArtBank.get_slot("body_idle")
	if tex == null:
		return null
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	return img


func _test_the_frame_is_all_keys() -> void:
	var img := _src()
	_ok(img != null, "the idle frame is in the project", "art/fighter/body_idle.png")
	if img == null:
		return
	_ok(img.get_size() == Vector2i(24, 32), "at 24 × 32", str(img.get_size()))
	var stray := 0
	var soft := 0
	var feet := false
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a == 0.0:
				continue
			if c.a < 1.0:
				soft += 1
				continue
			if y == img.get_height() - 1:
				feet = true
			if not _keys().any(func(k): return FighterArt._match(c, k)):
				stray += 1
	_ok(stray == 0, "every opaque pixel is a key colour or the outline", "%d strays" % stray)
	_ok(soft == 0, "no half-transparent pixels", "%d soft" % soft)
	_ok(feet, "the feet stand on the bottom row", "")


func _test_the_bake_leaves_no_key() -> void:
	var img := _src()
	if img == null:
		return
	var kit := Color8(196, 52, 40)
	var second := Color8(235, 230, 220)
	var out := FighterArt.bake(img, kit, second, false)
	var left := 0
	var kit_px := 0
	for y in out.get_height():
		for x in out.get_width():
			var c := out.get_pixel(x, y)
			if c.a < 1.0:
				continue
			if FighterArt._match(c, kit):
				kit_px += 1
			for k in _keys():
				if k != FighterArt.K_BLACK and FighterArt._match(c, k):
					left += 1
	_ok(left == 0, "baked in a club's colours, no key colour is left", "%d left" % left)
	_ok(kit_px > 20, "and the kit colour is on him", "%d kit pixels" % kit_px)
	var m := FighterArt.bake(img, kit, second, true)
	_ok(m.get_pixel(0, 0) == out.get_pixel(23, 0) and m.get_pixel(5, 20) == out.get_pixel(18, 20),
		"the away side is the same man mirrored", "")
