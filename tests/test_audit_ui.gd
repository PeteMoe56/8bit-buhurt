extends SceneTree
## The 27 Sep 2026 audit's shell fixes: back, confirms, thumbs, drafts.
##
##   godot --headless --path . --script res://tests/test_audit_ui.gd

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — audit: the shell ===\n")
	await process_frame
	Juice.set_enabled(false)
	_test_confirm_needs_two_taps()
	_test_a_short_button_has_a_thumb_margin()
	await _test_back_closes_the_modal_first()
	await _test_back_on_the_title_backs_out_of_the_picker()
	await _test_a_typed_club_name_survives_a_rebuild()
	await _test_every_root_screen_answers_back()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE AUDIT HOLDS (%d checks)\n" % checks)
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


func _open(path: String) -> Node:
	var n: Node = (load(path) as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	await process_frame
	return n


func _test_confirm_needs_two_taps() -> void:
	UiKit.disarm()
	var first := UiKit.confirm("x")
	var second := UiKit.confirm("x")
	UiKit.confirm("a")
	var other := UiKit.confirm("b")
	_ok(not first and second and not other, "an irreversible button needs two taps on the same thing",
		"first %s, second %s, a-then-b %s" % [first, second, other])
	UiKit.disarm()


func _test_a_short_button_has_a_thumb_margin() -> void:
	var b := UiKit.button("Go", Vector2(10, 10), Vector2(120, 34), func(): pass)
	var slop := 0
	for c in b.get_children():
		if String(c.name).begins_with("HitSlop"):
			slop += 1
	var tall := UiKit.button("Go", Vector2(10, 10), Vector2(120, 52), func(): pass)
	var none := 0
	for c in tall.get_children():
		if String(c.name).begins_with("HitSlop"):
			none += 1
	_ok(slop == 2 and none == 0, "a short button gets a thumb margin, a tall one does not",
		"34 tall: %d strips; 52 tall: %d" % [slop, none])
	b.free()
	tall.free()


func _test_back_closes_the_modal_first() -> void:
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	var s: Node = await _open("res://scenes/Season.tscn")
	s.set("shop_open", true)
	s.set("tab", 1)
	var a: bool = s.call("go_back")
	var shop_after: bool = s.get("shop_open")
	var tab_after: int = s.get("tab")
	var b2: bool = s.call("go_back")
	_ok(a and not shop_after and tab_after == 1 and b2 and int(s.get("tab")) == 0,
		"back closes the shop, then returns to the Club tab",
		"shop %s -> tab %d -> tab %d" % [str(shop_after), tab_after, int(s.get("tab"))])
	s.queue_free()
	await process_frame


func _test_back_on_the_title_backs_out_of_the_picker() -> void:
	var t: Node = await _open("res://scenes/Title.tscn")
	t.call("_new_club", 1)
	var picking: int = t.get("picking")
	t.call("go_back")
	_ok(picking == 1 and int(t.get("picking")) == -1, "back leaves the town picker, not the screen",
		"picking %d -> %d" % [picking, int(t.get("picking"))])
	t.queue_free()
	await process_frame


func _test_a_typed_club_name_survives_a_rebuild() -> void:
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	var c: Node = await _open("res://scenes/Create.tscn")
	c.set("tab", 1)
	c.call("_rebuild")
	await process_frame
	var ed: LineEdit = c.get("club_name_edit")
	if ed == null:
		_ok(false, "a typed club name survives a rebuild", "no club name box on the Club tab")
		c.queue_free()
		return
	ed.text = "Typed Not Saved"
	ed.text_changed.emit("Typed Not Saved")
	c.call("_rebuild")
	await process_frame
	var again: LineEdit = c.get("club_name_edit")
	_ok(again != null and again.text == "Typed Not Saved", "a typed club name survives a rebuild",
		"box reads '%s'" % (again.text if again != null else "(none)"))
	c.queue_free()
	await process_frame


func _test_every_root_screen_answers_back() -> void:
	var missing: Array[String] = []
	for path in ["res://scenes/Start.tscn", "res://scenes/Title.tscn",
			"res://scenes/Season.tscn", "res://scenes/Melee.tscn"]:
		var n: Node = (load(path) as PackedScene).instantiate()
		if not n.has_method("go_back"):
			missing.append(path.get_file())
		n.free()
	_ok(missing.is_empty(), "the screens where back must not simply go back answer it themselves",
		"missing go_back: %s" % (", ".join(missing) if not missing.is_empty() else "none"))
