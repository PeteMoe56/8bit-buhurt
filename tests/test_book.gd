extends SceneTree
## The playbook: what it lists, and what calling a card actually does.
##
##   godot --headless --path . --script res://tests/test_book.gd
##
## THE BOOK IS THE ONE SCREEN THAT READS THE CLUB'S OWN CONTENT. Every other
## panel in the fight is built out of constants — five slots, four strategies,
## three formations — and is therefore the same on every save. This one lists
## what the club has BOUGHT and DRAWN, so it is the first screen that can be
## wrong in a way only a particular save file shows: a formation slot unlocked
## and not listed, a play tied to a shape appearing under a different one, a
## drawn shape that lights up as live when the men are standing in a built-in.
##
## None of that is visible in a screenshot of a fresh season, which is the state
## every other check in the suite opens the game in.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []

## A drawn shape and two drawn plays, one of them tied to that shape.
const SHAPE_NAME := "Wedge"
const PLAY_ANY := "Crash"
const PLAY_TIED := "Wedge hook"


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the book ===\n")
	await _test_it_lists_what_the_club_owns()
	await _test_a_tied_play_stays_with_its_shape()
	await _test_calling_a_drawn_shape_stands_the_men_in_it()
	await _test_a_play_does_not_replace_the_push()
	await _test_every_card_draws()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE BOOK HOLDS (%d checks)\n" % checks)
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


## A CLUB THAT HAS BOUGHT ITS SLOTS AND USED THEM. The default season has neither,
## so a book test run against one is a test of the three built-ins — which is the
## case that already works.
func _season() -> Season:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	s.office.credits = 80
	s.board.unlock_formation(s.office)
	s.board.unlock_play(s.office)
	s.board.unlock_play(s.office)
	## A WEDGE, and every man behind the set-up line. `formation_legal` caps a
	## starting spot at 15% up the list — the first draft of this shape had the
	## Flankers at 16% and the Center at 22%, which the board refused, correctly,
	## and the test then reported as "the book lists three shapes" rather than as
	## the bad fixture it was.
	var spots: Array = [
		Vector2(0.16, 0.02), Vector2(0.33, 0.08), Vector2(0.50, 0.14),
		Vector2(0.67, 0.08), Vector2(0.84, 0.02),
	]
	var err := s.board.save_formation(0, SHAPE_NAME, spots)
	assert(err == "", "the drawn shape must be legal: " + err)
	var routes: Array = Chalkboard.blank_routes()
	routes[0] = [Vector2(0.16, 0.30), Vector2(0.30, 0.42)] as Array[Vector2]
	routes[2] = [Vector2(0.50, 0.40)] as Array[Vector2]
	var e2 := s.board.save_play(0, PLAY_ANY, routes, Chalkboard.UNIVERSAL)
	assert(e2 == "", "the universal play must be legal: " + e2)
	var e3 := s.board.save_play(1, PLAY_TIED, routes, s.board.formations[0]["id"])
	assert(e3 == "", "the tied play must be legal: " + e3)
	Session.season = s
	return s


func _open() -> Node:
	var n: Node = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(n)
	await process_frame
	await process_frame
	return n


func _names(rows: Array) -> Array:
	var out: Array = []
	for r in rows:
		out.append(String(r["name"]))
	return out


## THE THREE EVERYONE HAS, PLUS WHAT THIS CLUB DREW. A slot the player paid for
## and cannot see is the worst version of this bug, because the money is gone.
func _test_it_lists_what_the_club_owns() -> void:
	var s := _season()
	var scene := await _open()
	var shapes: Array = scene.call("_book_shapes")
	var names := _names(shapes)
	_ok(shapes.size() == Tuning.FORMATIONS.size() + 1,
		"the book lists every shape the club owns",
		"%d: %s" % [shapes.size(), ", ".join(names)])
	_ok(names.has(SHAPE_NAME), "including the drawn one", SHAPE_NAME)
	scene.queue_free()
	await process_frame


## A PLAY TIED TO A SHAPE APPEARS UNDER THAT SHAPE AND NOWHERE ELSE. It is the
## check mark Pete asked for, seen from the screen that has to honor it — and
## `Chalkboard.plays_for` is where it lives, so this is really asserting the book
## asks the right question rather than filtering on its own.
func _test_a_tied_play_stays_with_its_shape() -> void:
	var s := _season()
	var scene := await _open()
	var wedge_id := int(s.board.formations[0]["id"])
	var under_wedge := _names(scene.call("_book_calls", wedge_id))
	var under_212 := _names(scene.call("_book_calls", Tuning.Formation.TWO_ONE_TWO))
	_ok(under_wedge.has(PLAY_TIED) and not under_212.has(PLAY_TIED),
		"a tied play appears under its own shape only",
		"%s under %s, absent under 2-1-2" % [PLAY_TIED, SHAPE_NAME])
	_ok(under_wedge.has(PLAY_ANY) and under_212.has(PLAY_ANY),
		"a universal play appears under both", PLAY_ANY)
	_ok(under_212.size() == Tuning.STRATEGIES.size() + 1,
		"and the four pushes are always there",
		"%d cards: %s" % [under_212.size(), ", ".join(under_212)])
	scene.queue_free()
	await process_frame


## THE SHAPE YOU TAP IS THE SHAPE THEY STAND IN, both ways round.
##
## `formation_spots` prefers `custom_spots` over the named formation whenever it
## has any, so a built-in that fails to CLEAR them is a fight that quietly runs
## the drawn shape while the HUD prints "2-1-2". That is the ordering trap
## `set_plan` already carries a paragraph about, and it is the reason the book
## goes through the sim instead of assigning the field.
func _test_calling_a_drawn_shape_stands_the_men_in_it() -> void:
	var s := _season()
	var scene := await _open()
	var shapes: Array = scene.call("_book_shapes")
	var drawn: Dictionary = {}
	var built: Dictionary = {}
	for sh in shapes:
		if String(sh["name"]) == SHAPE_NAME:
			drawn = sh
		elif built.is_empty():
			built = sh

	scene.call("_call_from_book", drawn, {"kind": "push",
		"id": Tuning.Strategy.RUSH_LEFT, "name": "Rush left"})
	var sim = scene.get("sim")
	var stood_drawn: bool = sim.custom_spots[0] != null \
		and sim.formation_spots(0)[2] == drawn["spots"][2]
	_ok(stood_drawn, "calling a drawn shape stands them in it",
		"center spot %s" % str(sim.formation_spots(0)[2]))

	scene.call("_call_from_book", built, {"kind": "push",
		"id": Tuning.Strategy.RUSH_LEFT, "name": "Rush left"})
	_ok(sim.custom_spots[0] == null
			and sim.formation_spots(0) == Tuning.FORMATIONS[int(built["id"])]["spots"],
		"and calling a built-in clears the drawn spots",
		"back to %s" % String(built["name"]))
	scene.queue_free()
	await process_frame


## ROUTES AND THE PUSH ARE BOTH LIVE, which is why the right pane has two
## sections rather than one list.
##
## A drawn play fires at the charge and expires after PLAN_TIME; the push is what
## the anchors read for the rest of the round. The sim takes both — `set_plan`
## carries spots and routes, and `strategies[team]` is read either way — so a
## play that reset the push would silently turn every drawn call into Rush left.
func _test_a_play_does_not_replace_the_push() -> void:
	var s := _season()
	var scene := await _open()
	var shapes: Array = scene.call("_book_shapes")
	var sim = scene.get("sim")

	scene.call("_call_from_book", shapes[0], {"kind": "push",
		"id": Tuning.Strategy.TURTLE_RIGHT, "name": "Turtle right"})
	var before: int = sim.strategies[0]
	var calls: Array = scene.call("_book_calls", int(shapes[0]["id"]))
	var play: Dictionary = {}
	for c in calls:
		if String(c["kind"]) == "play":
			play = c
			break
	_ok(not play.is_empty(), "there is a drawn play to call", String(play.get("name", "-")))
	scene.call("_call_from_book", shapes[0], play)
	_ok(sim.strategies[0] == before, "calling a play keeps the push you are on",
		"still %s" % String(Tuning.STRATEGIES[before]["name"]))
	_ok(sim.plays[0] != null, "and the routes went on", "%d route slots" % sim.plays[0].size())
	scene.queue_free()
	await process_frame


## EVERY CARD IN THE BOOK ACTUALLY PAINTS. `Playbook.card_face` walks five slots
## and indexes `data` in two of its three modes — a route array one man short, or
## a shape with four spots in it, is a card that throws mid-draw and takes the
## panel with it. Cheap to run, and it is the only check that touches the drawing.
func _test_every_card_draws() -> void:
	var s := _season()
	var img := Control.new()
	root.add_child(img)
	await process_frame
	var drawn_ok := 0
	for sh in s.board.formation_choices():
		var spots: Array = s.board.spots_for(int(sh["id"]))
		Playbook.card_face(img, Rect2(0, 0, 200, 120), spots, Playbook.Mode.SHAPE,
			null, false, String(sh["name"]), UiKit.body())
		drawn_ok += 1
		for st in Tuning.STRATEGIES.keys():
			Playbook.card_face(img, Rect2(0, 0, 200, 120), spots,
				Playbook.Mode.STRATEGY, st, true, "x", UiKit.body())
			drawn_ok += 1
		for p in s.board.plays_for(int(sh["id"])):
			Playbook.card_face(img, Rect2(0, 0, 200, 120), spots, Playbook.Mode.PLAY,
				p["routes"], false, String(p["name"]), UiKit.body())
			drawn_ok += 1
	_ok(drawn_ok >= 20, "every card in the book paints without throwing",
		"%d cards across %d shapes" % [drawn_ok, s.board.formation_choices().size()])
	notes.append("a full book is %d shapes and %d cards"
		% [s.board.formation_choices().size(), drawn_ok])
	img.queue_free()
	await process_frame
