extends SceneTree
## A MOUSE, NOT A THUMB (Steam, 4 Oct 2026): the desktop words.
##
##   godot --headless --path . --script res://tests/test_pointer.gd
##
## On a desktop build every "Tap" a player reads is "Click". The swap is a table
## (`UiKit.POINTER_EN`) keyed by the English string, so the one way it breaks
## is a key that drifts away from the string the screen actually asks for — the
## table then quietly does nothing. These checks hold the table to the string
## table, hold the table to its own job, and hold the switch.
## The screens themselves are drawn in the desktop words by the language sweep
## ("pc" in run_tests.sh: test_ink and test_layout with RB_POINTER=1).

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the desktop words ===\n")
	_test_every_key_is_a_real_string()
	_test_no_instruction_still_says_tap()
	_test_the_switch()
	_test_every_language()
	print("")
	if failures.is_empty():
		print("THE DESKTOP WORDS HOLD (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


func _keys() -> Dictionary:
	var out := {}
	var f := FileAccess.open("res://locale/strings.csv", FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() > 0 and row[0] != "":
			out[row[0]] = true
	return out


func _test_every_key_is_a_real_string() -> void:
	var keys := _keys()
	var missing: Array = []
	for k in UiKit.POINTER_EN:
		if not keys.has(k):
			missing.append(k)
	_ok(missing.is_empty(), "every desktop key is in strings.csv",
		"%d of %d found%s" % [UiKit.POINTER_EN.size() - missing.size(), UiKit.POINTER_EN.size(),
		"" if missing.is_empty() else ", missing: " + str(missing)])
	var holes: Array = []
	for k in UiKit.POINTER_EN:
		if String(k).count("%") != String(UiKit.POINTER_EN[k]).count("%"):
			holes.append(k)
	_ok(holes.is_empty(), "the desktop words keep their blanks", str(holes))


## Every string that tells the player to TAP is in the table. The two that use
## the word and are not instructions are named here, so a new one is noticed.
func _test_no_instruction_still_says_tap() -> void:
	const NOT_AN_INSTRUCTION := [
		"Concession stands and beer on tap",
		"The hall is full by noon and the phone does not stop. Every man in the eight is a name in town tonight, and the whole room knows what comes next.",
	]
	var re := RegEx.create_from_string("(?i)\\b(tap|phone)\\b")
	var left: Array = []
	for k in _keys():
		if re.search(String(k)) != null and not UiKit.POINTER_EN.has(k) and not NOT_AN_INSTRUCTION.has(k):
			left.append(k)
	_ok(left.is_empty(), "no instruction still says tap", "%d left %s" % [left.size(), str(left)])
	var still: Array = []
	for k in UiKit.POINTER_EN:
		if re.search(String(UiKit.POINTER_EN[k])) != null:
			still.append(UiKit.POINTER_EN[k])
	_ok(still.is_empty(), "no desktop line says tap or phone", str(still))


func _test_the_switch() -> void:
	TranslationServer.set_locale("en")
	UiKit._pointer = 0
	_ok(UiKit.t("Tap to carry on") == "Tap to carry on", "a phone says tap", UiKit.t("Tap to carry on"))
	UiKit._pointer = 1
	_ok(UiKit.t("Tap to carry on") == "Click to carry on", "a desktop says click", UiKit.t("Tap to carry on"))
	_ok(UiKit.t("Sim it") == TranslationServer.translate("Sim it"), "a string with no desktop words is untouched",
		UiKit.t("Sim it"))
	TranslationServer.set_locale("pl")
	_ok(UiKit.t("Tap to carry on") != "Click to carry on", "a translation is not overruled by English",
		UiKit.t("Tap to carry on"))
	TranslationServer.set_locale("en")
	UiKit._pointer = -1


## ALL NINE SHIP (4 Oct 2026), so the desktop words are in all nine. Every
## translated desktop line is keyed by a real string, keeps its blanks, has lost
## its language's own word for a tap, and is what a desktop in that language reads.
func _test_every_language() -> void:
	const TAP := {
		"es": "(?i)\\btoca|t\u00f3calo", "fr": "(?i)\\btouche", "de": "(?i)tipp",
		"it": "(?i)\\btocca", "pt_BR": "(?i)\\btoque", "pl": "(?i)dotknij|stuknij",
		"uk": "(?i)\u0442\u043e\u0440\u043a\u043d|\u0442\u0438\u0441\u043d\u0438", "ja": "\u30bf\u30c3\u30d7",
	}
	var keys := _keys()
	var bad: Array = []
	for loc in Settings.SHIPPING:
		if loc == "en":
			continue
		if not UiKit.POINTER_L10N.has(loc):
			bad.append("%s: no table" % loc)
			continue
		var re := RegEx.create_from_string(String(TAP[loc]))
		for k in UiKit.POINTER_L10N[loc]:
			var v := String(UiKit.POINTER_L10N[loc][k])
			if not keys.has(k) or not UiKit.POINTER_EN.has(k):
				bad.append("%s: stray key %s" % [loc, k])
			elif String(k).count("%") != v.count("%"):
				bad.append("%s: blanks %s" % [loc, v])
			elif re.search(v) != null:
				bad.append("%s: still a tap: %s" % [loc, v])
	_ok(bad.is_empty(), "every shipping language has its desktop words", str(bad))
	TranslationServer.set_locale("pl")
	UiKit._pointer = 1
	var pl := UiKit.t("Tap to carry on")
	UiKit._pointer = 0
	var pl_phone := UiKit.t("Tap to carry on")
	TranslationServer.set_locale("en")
	UiKit._pointer = -1
	_ok(pl.begins_with("Kliknij") and pl != pl_phone, "a Polish desktop clicks, a Polish phone taps",
		"%s / %s" % [pl, pl_phone])
