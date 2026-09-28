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
	["res://scenes/Records.tscn", -1], ["res://scenes/Federation.tscn", -1],
	["res://scenes/Arena.tscn", -1], ["res://scenes/Chalkboard.tscn", -1],
	["res://scenes/Create.tscn", 0], ["res://scenes/Create.tscn", 1],
	["res://scenes/Create.tscn", 2], ["res://scenes/Bracket.tscn", -1],
	["res://scenes/Melee.tscn", -1],
]

var world: Season
var names := {}
var found := {}
var asked := {}
## Proper nouns and credits that are the same in every language.
const ALLOWED := ["8-BIT", "8-Bit Buhurt", "Buhurt Plate", "BUHURT", "English",
	"HeatleyBros — \"Game On\"", "COACH", "Coach"]


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
	var checks := 2
	var fails: Array[String] = []
	print("  %s  every string drawn on %d screens went through the string table — %s" % [
		"pass" if keys.is_empty() else "FAIL", SCREENS.size(),
		"none escaped" if keys.is_empty() else "%d escaped (listed above)" % keys.size()])
	if not keys.is_empty():
		fails.append("%d drawn strings skip UiKit.t()" % keys.size())
	print("  %s  and every key they asked for is in locale/strings.csv — %d keys%s" % [
		"pass" if missing.is_empty() else "FAIL", asked.size(),
		"" if missing.is_empty() else ": missing " + ", ".join(missing.slice(0, 8))])
	if not missing.is_empty():
		fails.append("%d keys not in the CSV (run bb strings)" % missing.size())
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
	for reg in Cities.Region.values():
		for c in Cities.names(reg):
			names[Cities.full_name(c)] = true
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
	n.queue_free()
	await process_frame


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
	if not found.has(s):
		found[s] = {}
	found[s][where] = true
