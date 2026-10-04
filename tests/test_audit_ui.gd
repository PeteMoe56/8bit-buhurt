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
	await _test_stacked_buttons_share_the_gap()
	await _test_a_coach_mark_shows_once_and_holds_the_fight()
	await _test_the_wheel_explains_itself_once()
	await _test_back_closes_the_modal_first()
	await _test_a_typed_club_name_survives_a_rebuild()
	await _test_every_root_screen_answers_back()
	_test_the_string_table_is_whole()
	_test_every_language_has_its_letters()
	_test_drafts_never_ship()

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
	## 60, not 52: the floor is 56 since Pete's #4 (29 Sep).
	var tall := UiKit.button("Go", Vector2(10, 10), Vector2(120, 60), func(): pass)
	var none := 0
	for c in tall.get_children():
		if String(c.name).begins_with("HitSlop"):
			none += 1
	_ok(slop == 2 and none == 0, "a short button gets a thumb margin, a tall one does not",
		"34 tall: %d strips; 60 tall: %d" % [slop, none])
	b.free()
	tall.free()


## Pete's #4 (29 Sep): 56 px to hit, but a strip never reaches into the next
## button — two 34 px buttons 6 px apart split the gap 3 and 3.
func _test_stacked_buttons_share_the_gap() -> void:
	var host := Control.new()
	root.add_child(host)
	var a := UiKit.button("A", Vector2(10, 10), Vector2(120, 38), func(): pass)
	var b := UiKit.button("B", Vector2(10, 54), Vector2(120, 38), func(): pass)
	host.add_child(a)
	host.add_child(b)
	await process_frame
	await process_frame
	var a_bottom := 0.0
	var b_top := 0.0
	var a_top := 0.0
	for c in a.get_children():
		if String(c.name) == "HitSlopBottom": a_bottom = (c as Control).size.y
		if String(c.name) == "HitSlopTop": a_top = (c as Control).size.y
	for c in b.get_children():
		if String(c.name) == "HitSlopTop": b_top = (c as Control).size.y
	var gap := b.get_global_rect().position.y - a.get_global_rect().end.y
	_ok(absf(a_bottom - gap * 0.5) < 0.6 and absf(b_top - gap * 0.5) < 0.6 and a_top >= 11.0,
		"stacked buttons share the gap between them, and keep the full margin elsewhere",
		"gap %.0f: A's bottom strip %.1f, B's top strip %.1f, A's free top strip %.1f"
			% [gap, a_bottom, b_top, a_top])
	host.queue_free()
	await process_frame


## Pete's #5 (29 Sep): the first live fight shows "Send a fighter", the fight
## waits while it is up, and once dismissed it never shows again.
func _test_a_coach_mark_shows_once_and_holds_the_fight() -> void:
	var was_path := Settings.path
	var was_on := Settings.tips_enabled
	Settings.load_once()
	Settings.path = "user://test_tips.cfg"
	Settings.tips_enabled = true
	Settings.tips_seen.clear()
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	var first := await _live_fight()
	var sim: MeleeSim = first.get("sim")
	var t0 := sim.round_t
	for i in 10:
		if bool(first.get("paused")):
			first.call("_set_paused", false)
		await process_frame
	var shown := String(first.get("tip"))
	var held := is_equal_approx(sim.round_t, t0)
	first.call("_close_tip")
	var remembered := Settings.tips_seen.has("route")
	first.queue_free()
	await process_frame
	var again := await _live_fight()
	var t1 := (again.get("sim") as MeleeSim).round_t
	for i in 10:
		if bool(again.get("paused")):
			again.call("_set_paused", false)
		await process_frame
	var second := String(again.get("tip"))
	var runs := (again.get("sim") as MeleeSim).round_t > t1
	again.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.path = was_path
	Settings.tips_enabled = was_on
	Settings.tips_seen.clear()
	Session.season = null
	_ok(shown == "route" and held and remembered and second == "" and runs,
		"the route tip shows on the first fight, holds it, and never shows again",
		"first '%s', clock held %s, remembered %s, second fight '%s' and its clock runs %s" % [shown, held, remembered, second, runs])


## THE CONTACT WHEEL'S CARD (1 Oct novice report, Pete approved): the first
## time the wheel opens, a one-time card says the sides are choices, that he
## chooses if you do not, what HOLD is, and what "N of M choices picked" counts.
## Once dismissed it never shows again, and its words fit the card in every
## language.
func _test_the_wheel_explains_itself_once() -> void:
	var was_path := Settings.path
	var was_on := Settings.tips_enabled
	Settings.load_once()
	Settings.path = "user://test_tips_wheel.cfg"
	Settings.tips_enabled = true
	Settings.tips_seen.clear()
	Settings.tips_seen.append("route")
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	var bad: Array[String] = []
	var first := await _live_fight()
	var before := String(first.get("tip"))
	await _open_wheel(first)
	var shown := String(first.get("tip"))
	if before != "":
		bad.append("a card ('%s') before the wheel opened" % before)
	if shown != "wheel":
		bad.append("the wheel opened and the card is '%s'" % shown)
	first.call("_close_tip")
	if not Settings.tips_seen.has("wheel"):
		bad.append("not remembered")
	first.queue_free()
	await process_frame
	var again := await _live_fight()
	await _open_wheel(again)
	if String(again.get("tip")) != "":
		bad.append("shown again: '%s'" % String(again.get("tip")))
	again.queue_free()
	await process_frame
	## The words, in every language, inside the card's six lines at its size.
	var MS = load("res://scripts/melee/melee_scene.gd")
	var was_loc := TranslationServer.get_locale()
	for loc in ["en", "es", "fr", "de", "it", "pt_BR", "pl", "uk", "ja"]:
		TranslationServer.set_locale(loc)
		var words: Array = MS._tip_words("wheel")
		var lines := UiKit.wrap(UiKit.body(), String(words[1]), 500.0 - 48.0, 14)
		if lines.size() > 6:
			bad.append("%s runs to %d lines" % [loc, lines.size()])
		if String(words[1]) == "" or (loc != "en" and String(words[1]).begins_with("Your man")):
			bad.append("%s is not translated" % loc)
	TranslationServer.set_locale(was_loc)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.path = was_path
	Settings.tips_enabled = was_on
	Settings.tips_seen.clear()
	Session.season = null
	_ok(bad.is_empty(), "the contact wheel's card shows the first time it opens, once, and fits",
		"shown on the first wheel, never again, six lines or fewer in nine languages" if bad.is_empty() else "; ".join(bad))


## The contact test_wheel opens: our man onto a free enemy, his prompt up.
func _open_wheel(scene: Node) -> void:
	var sim: MeleeSim = scene.get("sim")
	var us = sim.men[2]
	var them = sim.men[7]
	them.pos = Vector2(Tuning.LIST_W * 0.5, Tuning.LIST_H * 0.45)
	them.state = MeleeSim.State.CLOSING
	them.target = us.idx
	us.pos = them.pos + Vector2(-26, 0)
	var path: Array[Vector2] = []
	sim.give_order(us.idx, path, them.idx)
	sim._open_prompt(us, Tuning.Menu.APPROACH, them.idx)
	for i in 4:
		if bool(scene.get("paused")):
			scene.call("_set_paused", false)
		await process_frame


func _live_fight() -> Node:
	var m: Node = (load("res://scenes/Melee.tscn") as PackedScene).instantiate()
	root.add_child(m)
	await process_frame
	await process_frame
	m.call("_set_paused", false)
	(m.get("sim") as MeleeSim).phase = MeleeSim.Phase.LIVE
	m.set("screen", 2)
	await process_frame
	return m


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


## THE STRING TABLE MATCHES THE GAME. The first extractor read UTF-8 as Latin-1,
## so every key with a dash or a middle dot was mojibake and could never match
## the string the game asks for. And a translation that drops or reorders a
## placeholder crashes the `%` that formats it.
func _test_the_string_table_is_whole() -> void:
	var f := FileAccess.open("res://locale/strings.csv", FileAccess.READ)
	if f == null:
		_ok(false, "the string table is whole", "locale/strings.csv did not open")
		return
	var head := f.get_csv_line()
	var re := RegEx.create_from_string("%[-+ 0#]*\\d*(?:\\.\\d+)?[a-zA-Z%]")
	var rows := 0
	var mangled: Array[String] = []
	var broken: Array[String] = []
	var dashed := false
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() < head.size() or r[0] == "":
			continue
		rows += 1
		if r[0].contains("\u00e2") or r[0].contains("\u00c2"):
			mangled.append(r[0])
		if r[0] == "Have it seen to \u2014 %d CC":
			dashed = true
		var want := re.search_all(r[0]).map(func(m): return m.get_string())
		for i in range(2, head.size()):
			if r[i] == "":
				continue
			if re.search_all(r[i]).map(func(m): return m.get_string()) != want:
				broken.append("%s: %s" % [head[i], r[0].left(30)])
	_ok(rows > 400 and dashed and mangled.is_empty() and broken.is_empty(),
		"the string table matches the game, placeholder for placeholder",
		"%d keys, %d mangled, %d translations with the wrong placeholders%s" % [rows,
			mangled.size(), broken.size(), "" if broken.is_empty() else ": " + ", ".join(broken.slice(0, 3))])


## EVERY LETTER EVERY LANGUAGE NEEDS IS A PIXEL LETTER. The body face had 81
## glyphs and no dash, so English itself drew its dashes in the phone's own smooth
## font. With LanaPixel behind every face, each column of the string table must
## be drawable by the body and title faces without the system's help.
func _test_every_language_has_its_letters() -> void:
	var f := FileAccess.open("res://locale/strings.csv", FileAccess.READ)
	var head := f.get_csv_line()
	var seen := {}
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() < head.size():
			continue
		for i in range(1, head.size()):
			for c in r[i]:
				seen[head[i] + c] = true
	var missing := {}
	for key in seen:
		var lang: String = String(key).left(-1)
		var ch: String = String(key).right(1)
		if ch.unicode_at(0) <= 32:
			continue
		for face in [UiKit.body(), UiKit.title()]:
			if not face.has_char(ch.unicode_at(0)):
				missing[lang] = String(missing.get(lang, "")) + ch
				break
	var langs := head.slice(1)
	_ok(missing.is_empty(), "every language's letters are in the game's pixel fonts",
		"%d languages checked%s" % [langs.size(), "" if missing.is_empty() else ": missing " + str(missing)])


## THE DRAFTS NEVER REACH A PLAYER BY THEMSELVES (28 Sep 2026). All nine are
## registered, so the gate is `Settings`: a release build offers only what ships
## and resolves everything else — even a saved choice of a draft — to English;
## a debug build offers the drafts, marked, and choosing one really translates.
func _test_drafts_never_ship() -> void:
	var was_path := Settings.path
	Settings.path = "user://audit_settings.cfg"
	Settings.release_rules = true
	Settings.language = "es"
	var rel_offered := Settings.offered()
	var rel_resolved := Settings.resolved()
	Settings.release_rules = false
	var dbg_offered := Settings.offered()
	Settings.set_language("es")
	var spoken := UiKit.t("Back")
	## The mark is itself translated: a Spanish reader sees "(borrador)".
	var marked := Settings.language_name("es")
	var mark := UiKit.t("  (draft)").strip_edges()
	Settings.set_language("")
	var english := UiKit.t("Back")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.path))
	Settings.path = was_path
	_ok(rel_offered == ["", "en"] and rel_resolved == "en"
		and dbg_offered.size() == 2 + Settings.DRAFTS.size()
		and spoken != "Back" and english == "Back" and marked.ends_with(mark) and mark != "(draft)",
		"drafts are offered only in a debug build, and never chosen for a player",
		"release offers %s and resolves a saved 'es' to '%s'; debug offers %d; Spanish 'Back' = '%s', named '%s'"
			% [str(rel_offered), rel_resolved, dbg_offered.size(), spoken, marked])
