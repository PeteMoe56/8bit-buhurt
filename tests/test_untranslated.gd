extends SceneTree
## WHAT THE GAME DRAWS THAT NEVER WENT THROUGH THE STRING TABLE (28 Sep 2026).
##
##   godot --headless --path . --script res://tests/test_untranslated.gd
##
## Two checks. (1) Nothing drawn skips `UiKit.t()` (proper nouns aside).
## (2) Every key the screens asked `UiKit.t()` for is in locale/strings.csv —
## a wrapped string the extractor cannot see is as untranslatable as an
## unwrapped one.
##
## Godot's pseudolocalization wraps every string that passes through
## `TranslationServer` in [ ]. Every screen is then drawn with `UiKit`'s ledger
## on (and every button read off the tree): a drawn string with letters in it
## and no bracket anywhere never went through `UiKit.t()`, so no translation can
## ever reach it. Names from the world (clubs, fighters, captains, cities) are
## filtered out — those are proper nouns and stay as they are.

const SCREENS := [
	["res://scenes/Title.tscn", -1], ["res://scenes/Start.tscn", -1],
	["res://scenes/Settings.tscn", -1],
	["res://scenes/Season.tscn", 0], ["res://scenes/Season.tscn", 1],
	["res://scenes/Season.tscn", 2], ["res://scenes/Season.tscn", 3],
	["res://scenes/Season.tscn", 4], ["res://scenes/Roster.tscn", -1],
	["res://scenes/Fighter.tscn", -1], ["res://scenes/Market.tscn", -1],
	["res://scenes/Staff.tscn", -1], ["res://scenes/Coach.tscn", -1],
	["res://scenes/Records.tscn", -1],
	["res://scenes/Arena.tscn", -1], ["res://scenes/Chalkboard.tscn", -1],
	["res://scenes/Create.tscn", 0], ["res://scenes/Create.tscn", 1],
	["res://scenes/Create.tscn", 2], ["res://scenes/Bracket.tscn", -1], ["res://scenes/Calendar.tscn", -1],
	["res://scenes/Melee.tscn", -1],
]

var world: Season
var names := {}
var found := {}
var asked := {}
## Proper nouns and credits that are the same in every language.
const ALLOWED := ["8-BIT", "8-Bit Buhurt", "Buhurt Plate", "BUHURT", "English",
	"HeatleyBros — \"Game On\"", "COACH", "Coach",
	## The short-name box's hint is an example of three letters, not a word.
	"CLB"]


func _initialize() -> void:
	await process_frame
	Juice.set_enabled(false)
	for k in ["replace_with_accents", "double_vowels", "fake_bidi", "override"]:
		ProjectSettings.set_setting("internationalization/pseudolocalization/" + k, false)
	ProjectSettings.set_setting("internationalization/pseudolocalization/expansion_ratio", 0.0)
	ProjectSettings.set_setting("internationalization/pseudolocalization/prefix", "[")
	ProjectSettings.set_setting("internationalization/pseudolocalization/suffix", "]")
	ProjectSettings.set_setting("internationalization/pseudolocalization/skip_placeholders", true)
	TranslationServer.pseudolocalization_enabled = true
	TranslationServer.reload_pseudolocalization()
	_world()
	for sc in SCREENS:
		await _sweep(String(sc[0]), int(sc[1]))
	## THE STATES A SCREEN ONLY REACHES BY PLAYING (29 Sep 2026): the fight
	## live, paused, in the corner and in its report, and the club tab with
	## each dilemma card up. Reached the way test_ink reaches them.
	for st in [1, 5, 2, 4]:
		await _sweep_fight(st)
	for c in Dilemma.CARDS:
		await _sweep_dilemma(String(c["id"]))
	TranslationServer.pseudolocalization_enabled = false
	TranslationServer.reload_pseudolocalization()
	print("\n=== 8-Bit Buhurt — nothing drawn escapes the string table ===\n")
	var keys := found.keys()
	keys.sort()
	for k in keys:
		print("     %-40s %s" % [", ".join((found[k] as Dictionary).keys()).left(40), k])
	var table := {}
	var f := FileAccess.open("res://locale/strings.csv", FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var r := f.get_csv_line()
		if r.size() > 0 and r[0] != "":
			table[r[0]] = true
	var missing: Array[String] = []
	for k in asked:
		if not table.has(k) and String(k).strip_edges() != "":
			missing.append(String(k))
	missing.sort()
	var checks := 3
	var fails: Array[String] = []
	var glued := _english_in_args()
	print("  %s  every string drawn on %d screens and states went through the string table — %s" % [
		"pass" if keys.is_empty() else "FAIL", SCREENS.size() + FIGHT_LABEL.size() + Dilemma.CARDS.size(),
		"none escaped" if keys.is_empty() else "%d escaped (listed above)" % keys.size()])
	if not keys.is_empty():
		fails.append("%d drawn strings skip UiKit.t()" % keys.size())
	print("  %s  and every key they asked for is in locale/strings.csv — %d keys%s" % [
		"pass" if missing.is_empty() else "FAIL", asked.size(),
		"" if missing.is_empty() else ": missing " + ", ".join(missing.slice(0, 8))])
	if not missing.is_empty():
		fails.append("%d keys not in the CSV (run bb strings)" % missing.size())
	print("  %s  and no translated sentence is filled with an English word — %s" % [
		"pass" if glued.is_empty() else "FAIL",
		"none in the source" if glued.is_empty() else ", ".join(glued.slice(0, 6))])
	if not glued.is_empty():
		fails.append("%d translated sentences take an English word as a value" % glued.size())
	print("")
	if fails.is_empty():
		print("THE STRING TABLE HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for x in fails:
			print("FAIL: " + x)
		print("\n%d FAILED\n" % fails.size())
		quit(1)


func _world() -> void:
	world = Season.new(MeleeRosters.starting_club(), 4242)
	world.world.season = 3
	world.office.credits = 60
	world.hire_captain(ClubOffice.captain("Vaughn", Tuning.Role.RAIL, Tuning.Role.CENTER,
		5, ClubOffice.Trait.PHYSIO))
	for c in world.world.clubs:
		names[String(c["name"])] = true
		names[String(c.get("short", ""))] = true
		names[LeagueWorld._city_of(String(c["name"]))] = true
	for f in world.club.roster:
		names[f.display_name] = true
	for f in world.market():
		names[f.display_name] = true
	for c in world.office.captains:
		names[String(c.get("name", ""))] = true
	names[world.club.display_name] = true
	names[MeleeRosters.rival_club().display_name] = true
	for slot in 4:
		names[String(world.staff_offer(slot).get("name", ""))] = true
	for c in world.staff_pool():
		names[String(c.get("name", ""))] = true
	## The armorers too (1 Oct 2026): yours and this season's five.
	names[String(world.office.armorer.get("name", ""))] = true
	for a in Armorer.pool(world.seed_value, world.world.season):
		names[String(a["name"])] = true
	names[world.coach.display_name] = true
	for reg in Cities.Region.values():
		for c in Cities.names(reg):
			names[Cities.full_name(c)] = true
	## The invitationals' names and towns are proper nouns too (1 Oct 2026).
	for si in LeagueWorld.INVITATIONAL_SETS.size():
		for slot in 2:
			names[world.world.invitational_name(si, slot)] = true
			names[world.world.invitational_name(si, slot).to_upper()] = true
			names[Cities.full_name(world.world.invitational_city(si, slot))] = true
	for w in world.world.calendar:
		if w.has("name"):
			names[String(w["name"])] = true
			names[String(w["name"]).to_upper()] = true
	for a in ALLOWED:
		names[a] = true


func _sweep(path: String, tab: int) -> void:
	Session.season = world
	Session.viewing_fighter = world.club.starting_five()[0]
	var n: Node = (load(path) as PackedScene).instantiate()
	root.add_child(n)
	if n.get("season") == null and "season" in n:
		n.set("season", world)
	await process_frame
	if tab >= 0 and "tab" in n:
		n.set("tab", tab)
		if n.has_method("_rebuild"):
			n.call("_rebuild")
	await process_frame
	UiKit.ledger_start()
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	await process_frame
	await process_frame
	var drawn := UiKit.ledger_stop()
	for k in UiKit.ledger_keys():
		asked[k] = true
	var label := path.get_file().get_basename() + ("" if tab < 0 else "/%d" % tab)
	for d in drawn:
		_check(String(d["text"]), label)
	for b in _buttons(n):
		_check(String(b.text), label + " (button)")
	for e in _edits(n):
		_check(String(e.placeholder_text), label + " (placeholder)")
	n.queue_free()
	await process_frame


func _collect(n: Node, label: String) -> void:
	UiKit.ledger_start()
	if n is CanvasItem:
		(n as CanvasItem).queue_redraw()
	await process_frame
	await process_frame
	var drawn := UiKit.ledger_stop()
	for k in UiKit.ledger_keys():
		asked[k] = true
	for d in drawn:
		_check(String(d["text"]), label)
	for b in _buttons(n):
		if (b as Button).is_visible_in_tree():
			_check(String(b.text), label + " (button)")
	## A text box's grey hint is drawn text too — "His name" was.
	for e in _edits(n):
		_check(String(e.placeholder_text), label + " (placeholder)")
	n.queue_free()
	await process_frame


const FIGHT_LABEL := {1: "fight", 5: "fight paused", 2: "corner", 4: "report"}

func _sweep_fight(state: int) -> void:
	seed(20260914)
	## The shared world, so its fighters and clubs are the names filtered out.
	Session.season = world
	Session.bout = null
	var n: Node = (load("res://scenes/Melee.tscn") as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	await process_frame
	var sim = n.get("sim")
	## Whoever the bout drew is a proper noun too: both clubs, both benches.
	for c in sim.clubs:
		names[String(c.display_name)] = true
		names[String(c.short_name)] = true
		for f in c.roster:
			names[String(f.display_name)] = true
	if state == 2:
		sim.skip_round()
		n.set("screen", 3)
		n.set("corner_done_for_round", -1)
		n.call("_show_strategy_panel")
	else:
		var sh = n.call("_shape_of", int(sim.formations[0]))
		n.call("_call_from_book", sh if sh is Dictionary else {},
			{"kind": "push", "id": int(sim.strategies[0]), "name": "hold"})
		await process_frame
		await process_frame
		if state == 5:
			n.call("_set_paused", true)
		elif state == 4:
			sim.run_to_end()
			if n.has_method("_show_report"):
				n.call("_show_report")
	await process_frame
	await _collect(n, "Melee/" + String(FIGHT_LABEL[state]))


func _sweep_dilemma(id: String) -> void:
	Session.season = world
	world.dilemma = {"id": id, "man": 0}
	var n: Node = (load("res://scenes/Season.tscn") as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	await process_frame
	await _collect(n, "dilemma " + id)
	world.dilemma = {}


func _edits(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is LineEdit:
			out.append(c)
		out.append_array(_edits(c))
	return out


func _buttons(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out


func _check(t: String, where: String) -> void:
	## WHAT WENT THROUGH THE TABLE IS CUT OUT, and what is left is checked. It
	## used to skip any string with a bracket in it, so a translated key with
	## English glued on — `[Reserve by ]age`, `[NOW is … ·  ]red = deal with it`
	## — passed as translated. Brackets nest when a translated word fills a
	## translated template, so they are peeled innermost first.
	var s := t
	var inner := RegEx.create_from_string("\\[[^\\[\\]]*\\]")
	var was := ""
	while was != s:
		was = s
		s = inner.sub(s, " ", true)
	## A paragraph wrapped over lines splits its pair: an unmatched `[` opens
	## text that runs off the end of this line, an unmatched `]` closes text
	## that began on an earlier one.
	if s.contains("["):
		s = s.left(s.find("["))
	if s.contains("]"):
		s = s.substr(s.rfind("]") + 1)
	s = s.strip_edges()
	## An art slot still drawing its path is a placeholder until the art lands.
	if s == "" or names.has(s) or s.begins_with("res://"):
		return
	## A name cut to fit ("Detroit Free Comp.") or a town with its state
	## ("Detroit, MI") is still a name.
	for nm in names:
		var n := String(nm)
		if n.length() > 3 and (n.begins_with(s.trim_suffix(".")) or s.begins_with(n + ",")):
			return
	## Money and counts: "43 CC", "$181 of $800", "-4 CC". CC is the currency's
	## name in every language.
	if RegEx.create_from_string("^[-+$0-9.,k/ ·%]*(CC)?[-+$0-9.,k/ ·%]*$").search(s) != null:
		return
	## Letters, not just digits, money and symbols.
	var letters := RegEx.create_from_string("[A-Za-z]{2,}")
	var probe := s
	for nm in names:
		if String(nm).length() > 2 and probe.contains(String(nm)):
			probe = probe.replace(String(nm), "")
	if letters.search(probe) == null:
		return
	## THE MIDDLE OF A WRAPPED PARAGRAPH (30 Sep 2026, the 14 px pass): a
	## sentence over three lines has a middle line with neither bracket. It is
	## translated if it is a piece of some key as the table renders it.
	if _inside_a_key(s):
		return
	if not found.has(s):
		found[s] = {}
	found[s][where] = true


## WHAT THE SWEEP CANNOT SEE (29 Sep 2026). A value put into a translated
## sentence lands inside its brackets, so `UiKit.t("morale %s") % "up"` reads as
## translated on screen and says "moral up" in Spanish. This reads the source:
## a string literal with letters among the values of a `UiKit.t(...) %` is an
## English word in a translated sentence. Dictionary keys (`e["name"]`,
## `.get("name"`) are not values and are cut out first.
func _english_in_args() -> Array[String]:
	var out: Array[String] = []
	var call := RegEx.create_from_string('UiKit\\.t\\("(?:[^"\\\\]|\\\\.)*"\\)\\s*%\\s*(\\[[^\\]]*(?:\\][^\\]\\n]*)*\\]|\\((?:[^()\\n]|\\([^()\\n]*\\))*\\)|"[^"\\n]*")')
	var wrapped := RegEx.create_from_string('UiKit\\.t\\("(?:[^"\\\\]|\\\\.)*"\\)')
	var sub := RegEx.create_from_string('\\[\\s*"[^"]*"\\s*\\]')
	var getter := RegEx.create_from_string('\\.(get|has|get_value)\\(\\s*"[^"]*"')
	var lit := RegEx.create_from_string('"((?:[^"\\\\]|\\\\.)*)"')
	var word := RegEx.create_from_string("[A-Za-z]{2,}")
	var comment := RegEx.create_from_string("##?[^\\n]*")
	for path in _scripts("res://scripts"):
		var src := FileAccess.get_file_as_string(path)
		for m in call.search_all(src):
			var a := m.get_string(1)
			a = comment.sub(a, "", true)
			a = wrapped.sub(a, "", true)
			a = sub.sub(a, "", true)
			a = getter.sub(a, "(", true)
			for l in lit.search_all(a):
				if word.search(l.get_string(1)) != null:
					out.append("%s:%d '%s'" % [path.get_file(),
						src.substr(0, m.get_start()).count("\n") + 1, l.get_string(1)])
	return out


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(d)))
	return out


var _rendered := ""


func _inside_a_key(frag: String) -> bool:
	if frag.length() < 8:
		return false
	if _rendered == "":
		var f := FileAccess.open("res://locale/strings.csv", FileAccess.READ)
		var parts: PackedStringArray = []
		f.get_csv_line()
		while not f.eof_reached():
			var row := f.get_csv_line()
			if row.size() > 0 and row[0] != "":
				parts.append(TranslationServer.translate(row[0]))
		_rendered = "\n".join(parts)
	return _rendered.contains(frag)
