extends SceneTree
## LEAFING THROUGH THE BOOK (playtest report, 4 Oct 2026).
##
##   godot --headless --path . --script res://tests/test_book_nav.gd
##
## A tester: *"I can't get to what I drew, or select it as a starting point...
## when picking favorites and selection it's failing to scroll to where I can
## reach it. And when I do if I tap it the whole thing resets to the top with the
## original formation selected."*
##
## Every one of those was the book rebuilding itself on a tap: the panes came
## back scrolled to the top, the lit shape was the one the men stood in rather
## than the one tapped, and between rounds a tapped shape threw the book away
## and went back to the corner. And nothing carried the shape you fought in to
## the next bout. test_book.gd checks what the book LISTS; this checks that a
## player can GET to it.

var failures: Array[String] = []
var checks: int = 0
const SHAPE_NAME := "Wedge"
const PLAY_TIED := "Wedge hook"


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — leafing through the book ===\n")
	await process_frame
	await _test_a_tapped_shape_stays_open_and_lit(false)
	await _test_a_tapped_shape_stays_open_and_lit(true)
	await _test_starring_keeps_the_place()
	await _test_the_book_opens_at_the_chosen_shape()
	await _test_the_shape_you_fight_in_is_the_next_start()
	print("")
	if failures.is_empty():
		print("THE BOOK'S PAGES HOLD (%d checks)\n" % checks)
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


## Three built-ins plus four drawn shapes: the shape column has to scroll.
func _season() -> Season:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.office.credits = 400
	for k in 3:
		s.board.unlock_formation(s.office)
	s.board.unlock_play(s.office)
	var spots: Array = [
		Vector2(0.16, 0.02), Vector2(0.33, 0.08), Vector2(0.50, 0.14),
		Vector2(0.67, 0.08), Vector2(0.84, 0.02),
	]
	for k in s.board.formation_slots:
		var err := s.board.save_formation(k, "%s %d" % [SHAPE_NAME, k] if k > 0 else SHAPE_NAME, spots)
		assert(err == "", err)
	var routes: Array = Chalkboard.blank_routes()
	routes[2] = [Vector2(0.50, 0.40)] as Array[Vector2]
	var e := s.board.save_play(0, PLAY_TIED, routes, s.board.formations[s.board.formations.size() - 1]["id"])
	assert(e == "", e)
	Session.season = s
	return s


func _open() -> Node:
	var n: Node = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(n)
	await process_frame
	await process_frame
	n.call("_show_strategy_panel")
	await process_frame
	return n


func _settle() -> void:
	for k in 4:
		await process_frame


## The two scroll panes of the open book, left then right.
func _panes(scene: Node) -> Array:
	var box: Control = scene.get("panel_box")
	return box.find_children("*", "ScrollContainer", true, false)


func _shape_cards(scene: Node) -> Array:
	var panes := _panes(scene)
	if panes.is_empty():
		return []
	return (panes[0] as ScrollContainer).find_children("*", "Button", true, false)


func _lit(card: Button) -> bool:
	for c in card.get_children():
		if c is Playbook.Paint:
			return (c as Playbook.Paint).live
	return false


func _test_a_tapped_shape_stays_open_and_lit(between_rounds: bool) -> void:
	var s := _season()
	var scene := await _open()
	var where := "between rounds" if between_rounds else "before the charge"
	if between_rounds:
		scene.get("sim").phase = MeleeSim.Phase.CORNER
		scene.set("screen", 3)
	scene.call("_open_playbook")
	await _settle()
	var cards := _shape_cards(scene)
	var last: int = cards.size() - 1
	_ok(cards.size() == 3 + s.board.formations.size(), "the book lists all %d shapes %s" % [cards.size(), where],
		"%d cards" % cards.size())
	## Down to the last drawn shape, and tap it.
	var left: ScrollContainer = _panes(scene)[0]
	left.scroll_vertical = 100000
	await _settle()
	var was := left.scroll_vertical
	(cards[last] as Button).pressed.emit()
	await _settle()
	var box: Control = scene.get("panel_box")
	_ok(box.visible and not _panes(scene).is_empty(), "tapping a shape keeps the book open %s" % where,
		"panel %s, panes %d" % [box.visible, _panes(scene).size()])
	if _panes(scene).is_empty():
		scene.queue_free()
		await process_frame
		return
	left = _panes(scene)[0]
	_ok(was > 0 and absi(left.scroll_vertical - was) <= 2, "and the shape column stays where it was scrolled %s" % where,
		"scrolled %d before, %d after" % [was, left.scroll_vertical])
	cards = _shape_cards(scene)
	var lit: Array = []
	for i in cards.size():
		if _lit(cards[i]):
			lit.append(i)
	_ok(lit == [last], "and the shape tapped is the one lit %s" % where, "lit %s, tapped %d" % [str(lit), last])
	## Its tied play is on the right.
	var right: ScrollContainer = _panes(scene)[1]
	var names: Array = []
	for b in right.find_children("*", "Button", true, false):
		for c in b.get_children():
			if c is Playbook.Paint:
				names.append((c as Playbook.Paint).label)
	_ok(names.any(func(n): return String(n).ends_with(PLAY_TIED)), "and the play drawn for it is there to call %s" % where,
		str(names))
	scene.queue_free()
	await process_frame


func _test_starring_keeps_the_place() -> void:
	var s := _season()
	var scene := await _open()
	scene.call("_open_playbook")
	scene.set("starring", true)
	scene.call("_show_playbook")
	await _settle()
	var right: ScrollContainer = _panes(scene)[1]
	right.scroll_vertical = 100000
	await _settle()
	var was := right.scroll_vertical
	var cards := right.find_children("*", "Button", true, false)
	(cards[cards.size() - 1] as Button).pressed.emit()
	await _settle()
	right = _panes(scene)[1]
	_ok(was > 0 and absi(right.scroll_vertical - was) <= 2, "starring a card low in the list keeps the list where it was",
		"scrolled %d before, %d after" % [was, right.scroll_vertical])
	_ok(s.board.live_favorites().size() == 1, "and the star took", "%d favorites" % s.board.live_favorites().size())
	scene.queue_free()
	await process_frame


func _test_the_book_opens_at_the_chosen_shape() -> void:
	var s := _season()
	var scene := await _open()
	var shapes: Array = scene.call("_book_shapes")
	var last: Dictionary = shapes[shapes.size() - 1]
	var calls: Array = scene.call("_book_calls", int(last["id"]))
	scene.call("_choose", last, calls[0])
	scene.call("_open_playbook")
	await _settle()
	_ok(int(scene.get("book_shape")) == shapes.size() - 1, "the book opens at the shape chosen",
		"book_shape %d of %d" % [int(scene.get("book_shape")), shapes.size()])
	var left: ScrollContainer = _panes(scene)[0]
	var cards := _shape_cards(scene)
	var card: Control = cards[cards.size() - 1]
	var top := card.position.y - left.scroll_vertical
	_ok(top >= -1.0 and top + card.size.y <= left.size.y + 1.0, "scrolled so its card is in view",
		"card at %.0f..%.0f of a %.0f pane" % [top, top + card.size.y, left.size.y])
	scene.queue_free()
	await process_frame


## THE STARTING POINT. A shape fought in is the shape the next bout opens in.
func _test_the_shape_you_fight_in_is_the_next_start() -> void:
	var s := _season()
	var scene := await _open()
	var shapes: Array = scene.call("_book_shapes")
	var drawn: Dictionary = shapes[shapes.size() - 1]
	scene.call("_call_from_book", drawn, {"kind": "push", "id": Tuning.Strategy.RUSH_LEFT, "name": "Rush left"})
	_ok(s.formation_id == int(drawn["id"]), "the drawn shape fought in becomes the club's starting shape",
		"formation_id %d, drawn %d" % [s.formation_id, int(drawn["id"])])
	scene.queue_free()
	await process_frame
	## A built-in, the other way: the next bout lights it, not 2-1-2.
	var built := Tuning.Formation.keys().size()
	var pick := -1
	for f in Tuning.FORMATIONS.keys():
		if int(f) != Tuning.Formation.TWO_ONE_TWO:
			pick = int(f)
	s.formation_id = pick
	var again := await _open()
	_ok(int(again.call("_live_shape_id")) == pick, "and a built-in starting shape is the one the next bout lights",
		"live %d, wanted %d (%d formations)" % [int(again.call("_live_shape_id")), pick, built])
	again.queue_free()
	await process_frame
