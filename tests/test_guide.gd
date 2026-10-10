extends SceneTree
## THE GUIDE'S PICTURE PAGES (10 Oct 2026) — every topic, every language.
##
##   godot --headless --path . --script res://tests/test_guide.gd
##
## Pete: "make the guide actually show pictures and explanations". A page is a
## picture with gold numbers on it and the same numbers down the right. A number
## with no line, a line with no number, or lines running off the panel in some
## language is the page lying, so all three are held for all ten topics in all
## nine languages.

const LOCALES := ["en", "es", "fr", "de", "it", "pt_BR", "pl", "uk", "ja"]
var scene: Node
var n := 0
var li := 0
var topic := 0
var bad: Array[String] = []
var seen := 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the Guide's pictures ===\n")
	Juice.set_enabled(false)
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	TranslationServer.set_locale(LOCALES[0])
	scene = load("res://scenes/Guide.tscn").instantiate()
	root.add_child.call_deferred(scene)


func _process(_d: float) -> bool:
	n += 1
	if n < 3:
		return false
	if n % 3 == 0:
		scene.set("tab", topic)
		scene.call("_rebuild")
		return false
	if n % 3 != 2:
		return false
	var loc: String = LOCALES[li]
	var marks := int(scene.get("drawn_marks"))
	var notes := int(scene.get("drawn_notes"))
	seen += 1
	if marks != notes:
		bad.append("%s topic %d: %d numbers on the picture, %d lines" % [loc, topic, marks, notes])
	if not bool(scene.get("notes_fit")):
		bad.append("%s topic %d: the numbered lines run off the panel" % [loc, topic])
	topic += 1
	if topic >= GuideScene.topics().size():
		topic = 0
		li += 1
		if li >= LOCALES.size():
			return _finish()
		TranslationServer.set_locale(LOCALES[li])
	return false


func _finish() -> bool:
	TranslationServer.set_locale("en")
	var ok := bad.is_empty() and seen == LOCALES.size() * GuideScene.topics().size()
	print("  %s  every page's numbers match its lines and fit, %d pages in %d languages — %s" % [
		"pass" if ok else "FAIL", seen, LOCALES.size(), "all hold" if ok else ", ".join(bad.slice(0, 6))])
	if ok:
		print("\nTHE GUIDE HOLDS (%d checks)\n" % seen)
		quit(0)
	else:
		print("\nFAIL: the Guide's pages\n\n1 FAILED\n")
		quit(1)
	return true
