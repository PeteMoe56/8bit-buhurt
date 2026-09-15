extends SceneTree
## THE CHALKBOARD — drawn formations, drawn plays, and the rung they sit on.
##
##   godot --headless --path . --script res://tests/test_chalkboard.gd
##
## Two things are worth proving here and one of them is not obvious.
##
## The obvious one: a drawn shape and a drawn play have to reach the list, and
## the 15% rule has to hold against a player with a mouse.
##
## The one that matters: A PLAY MUST BE WORTH LESS THAN A THUMB. Pete's ladder
## is roster > thumb > tactics. If a called play opened menus and overrode a
## man's recovery the way a thumb-drawn route does, drawing four good plays once
## would buy the player everything that playing well is supposed to buy, for
## free, forever. So the gap is asserted, not assumed.

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	## Its own corner of user:// — these files run in parallel and there are
	## only three slots between all of them.
	SaveGame.set_namespace("chalkboard")
	print("\n=== Retro Buhurt — the chalkboard ===\n")
	_test_slots_cost_credits()
	_test_the_setup_line_holds_against_the_player()
	_test_a_drawn_formation_reaches_the_list()
	_test_a_play_walks_its_route()
	_test_a_play_is_not_a_thumb()
	_test_formation_dependent_plays()
	_test_deleting_a_formation_a_play_needs()
	_test_the_board_saves()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE CHALKBOARD HOLDS (%d checks)\n" % checks)
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


## A legal shape: everyone behind the line, spread across it.
func _shape(y: float = 0.10) -> Array:
	return [Vector2(0.10, y), Vector2(0.30, y), Vector2(0.50, y),
		Vector2(0.70, y), Vector2(0.90, y)]


func _test_slots_cost_credits() -> void:
	var b := Chalkboard.new()
	var o := ClubOffice.new()
	o.credits = 0
	var broke := b.unlock_formation(o)
	o.credits = 40
	var paid := ""
	var spent := 0
	for i in Chalkboard.SLOTS:
		var before := o.credits
		var err := b.unlock_formation(o)
		if err != "":
			paid = err
		spent += before - o.credits
	var full := b.unlock_formation(o)
	_ok(broke != "" and paid == "" and b.formation_slots == Chalkboard.SLOTS
			and full != "" and spent == 3 + 5 + 7 + 9,
		"four slots, bought",
		"%d credits for four; a fifth is refused (%s)" % [spent, full])
	## The second kind is bought separately — four formations do not hand you
	## four plays.
	var b2 := Chalkboard.new()
	var o2 := ClubOffice.new()
	o2.credits = 8
	b2.unlock_formation(o2)
	_ok(b2.play_slots == 0 and b2.save_play(0, "X", Chalkboard.blank_routes()) != "",
		"the two kinds are separate", "a formation slot does not unlock a play slot")


func _test_the_setup_line_holds_against_the_player() -> void:
	## The Chalkboard hands Tuning whatever the player dragged. This is the only
	## thing standing between a drawn formation and a line that sets up on the
	## halfway mark, so it is checked with the numbers a player would actually
	## produce by dragging rather than with obvious nonsense.
	var b := Chalkboard.new()
	var o := ClubOffice.new()
	o.credits = 40
	b.unlock_formation(o)
	var over := _shape()
	over[2] = Vector2(0.50, Tuning.SET_UP_LINE + 0.001)   ## one thousandth past
	var creep := b.save_formation(0, "Creep", over)
	var off := _shape()
	off[0] = Vector2(-0.05, 0.10)
	var wide := b.save_formation(0, "Off", off)
	var short_line := b.save_formation(0, "Four", [Vector2(0.1, 0.1), Vector2(0.3, 0.1),
		Vector2(0.5, 0.1), Vector2(0.7, 0.1)])
	var edge := b.save_formation(0, "Edge", _shape(Tuning.SET_UP_LINE))
	_ok(creep != "" and wide != "" and short_line != "" and edge == ""
			and b.formations.size() == 1,
		"the 15% line holds",
		"a thousandth past is refused; exactly on the line is legal")
	_ok(b.save_formation(1, "No slot", _shape()) != "",
		"an unbought slot refuses", "you cannot draw into a slot you have not paid for")


func _test_a_drawn_formation_reaches_the_list() -> void:
	## All the way through: drawn on the board, chosen by id, and standing on
	## that exact spot when the round starts. The id space is the thing under
	## test — built-ins and drawn shapes have to resolve by the same road.
	var season := _season()
	season.board.unlock_formation(season.office)
	var mine := _shape(0.02)
	mine[2] = Vector2(0.50, 0.14)
	season.board.save_formation(0, "Bunker", mine)
	var id := int(season.board.formations[0]["id"])
	season.formation_id = id
	var sim := season.begin_bout()

	var wrong := 0
	for m in sim.men:
		if m.team != 0:
			continue
		var want := Vector2(Tuning.LIST_W * mine[m.slot].x, Tuning.LIST_H * mine[m.slot].y)
		if m.pos.distance_to(want) > 0.01:
			wrong += 1
	_ok(wrong == 0 and id >= Chalkboard.CUSTOM_BASE
			and season.board.formation_name(Tuning.Formation.DEPTH) == "Depth",
		"a drawn shape reaches the list",
		"all five on their drawn spots; built-in ids still resolve by the same road")


func _test_a_play_walks_its_route() -> void:
	## A called play has to actually move men, and it has to EXPIRE. A route the
	## AI never gets back is not a play, it is remote control.
	var season := _season()
	season.board.unlock_play(season.office)
	var routes := Chalkboard.blank_routes()
	routes[Tuning.Pos.RAIL_L] = [Vector2(0.06, 0.40)] as Array[Vector2]
	routes[Tuning.Pos.RAIL_R] = [Vector2(0.94, 0.40)] as Array[Vector2]
	var err := season.board.save_play(0, "Both rails", routes)
	season.play_index = 0
	var sim := season.begin_bout()

	var rail := sim.men[Tuning.Pos.RAIL_L]
	var started := rail.pos
	var under_at_start := rail.under_orders()
	## Long enough for the route to be walked and handed back.
	var freed := false
	for _i in int(30.0 * 20.0):
		sim.tick()
		if not rail.under_orders():
			freed = true
			break
	_ok(err == "" and under_at_start and freed and rail.pos.distance_to(started) > 20.0,
		"a play walks and expires",
		"the Rail took his route and was handed back to the AI")
	_ok(Tuning.play_legal(Chalkboard.blank_routes()) != ""
			and Tuning.play_legal(_deep_route()) != "",
		"a route has limits",
		"an empty play and a route up the far end are both refused")


func _test_a_play_is_not_a_thumb() -> void:
	## THE LADDER. A thumb-drawn route opens the menu that lets a player pick
	## the action; a play does not, and a play does not count as thumb work
	## either — otherwise C-6's measurement of what the thumb is worth would be
	## measuring the Chalkboard.
	var season := _season()
	season.board.unlock_play(season.office)
	var routes := Chalkboard.blank_routes()
	for i in 5:
		routes[i] = [Vector2(0.5, 0.45)] as Array[Vector2]
	season.board.save_play(0, "All in", routes)
	season.play_index = 0
	var sim := season.begin_bout()
	var prompts := [0]
	sim.prompt_opened.connect(func(_i): prompts[0] += 1)
	for _i in int(30.0 * 45.0):
		sim.tick()
		if sim.phase == MeleeSim.Phase.OVER:
			break
	_ok(prompts[0] == 0 and sim.orders_issued == 0,
		"a play is not a thumb",
		"five men sent into the middle raised %d menus and %d thumb orders" % [
			prompts[0], sim.orders_issued])


func _test_formation_dependent_plays() -> void:
	## Pete's check mark. A play drawn for one shape must not run out of
	## another, and it must not be an error either — it simply is not called.
	var season := _season()
	season.board.unlock_formation(season.office)
	season.board.unlock_play(season.office)
	season.board.unlock_play(season.office)
	season.board.save_formation(0, "Bunker", _shape(0.02))
	var id := int(season.board.formations[0]["id"])
	var routes := Chalkboard.blank_routes()
	routes[Tuning.Pos.CENTER] = [Vector2(0.5, 0.35)] as Array[Vector2]
	season.board.save_play(0, "Bunker break", routes, id)
	season.board.save_play(1, "Anywhere", routes, Chalkboard.UNIVERSAL)

	season.formation_id = Tuning.Formation.TWO_ONE_TWO
	season.play_index = 0
	var not_called = season.called_play()
	season.play_index = 1
	var always = season.called_play()
	season.formation_id = id
	season.play_index = 0
	var called = season.called_play()
	var offered: Array = season.board.plays_for(id)
	var offered_212: Array = season.board.plays_for(Tuning.Formation.TWO_ONE_TWO)
	_ok(not_called == null and always != null and called != null
			and offered.size() == 2 and offered_212.size() == 1,
		"formation-dependent vs universal",
		"the bound play is offered in its own shape only; the universal one always")


func _test_deleting_a_formation_a_play_needs() -> void:
	## Silently unbinding would hand the player a plan that no longer means what
	## he drew. Refuse, and say which play is holding it.
	var b := Chalkboard.new()
	var o := ClubOffice.new()
	o.credits = 40
	b.unlock_formation(o)
	b.unlock_play(o)
	b.save_formation(0, "Bunker", _shape(0.02))
	var id := int(b.formations[0]["id"])
	var routes := Chalkboard.blank_routes()
	routes[0] = [Vector2(0.2, 0.3)] as Array[Vector2]
	b.save_play(0, "Bunker break", routes, id)
	var refused := b.delete_formation(0)
	b.delete_play(0)
	var now := b.delete_formation(0)
	_ok(refused.find("Bunker break") != -1 and now == "" and b.formations.is_empty(),
		"a formation in use will not delete",
		"refused by name until the play that needs it is gone")


func _test_the_board_saves() -> void:
	## Ids have to survive the round trip, or a reloaded save re-points every
	## bound play at whatever shape happens to be sitting in that index.
	var season := _season()
	season.board.unlock_formation(season.office)
	season.board.unlock_formation(season.office)
	season.board.unlock_play(season.office)
	season.board.save_formation(0, "Bunker", _shape(0.02))
	season.board.save_formation(1, "Wide", _shape(0.14))
	var id := int(season.board.formations[1]["id"])
	var routes := Chalkboard.blank_routes()
	routes[Tuning.Pos.FLANK_R] = [Vector2(0.8, 0.2), Vector2(0.6, 0.4)] as Array[Vector2]
	season.board.save_play(0, "Cut in", routes, id)
	season.formation_id = id
	season.play_index = 0

	SaveGame.save(season, 2)
	var back := SaveGame.load_slot(2)
	SaveGame.delete(2)
	var b: Chalkboard = back.board
	var same_shape: bool = b.spots_for(id)[2] == season.board.spots_for(id)[2]
	var route: Array = b.plays[0]["routes"][Tuning.Pos.FLANK_R]
	_ok(back != null and b.formations.size() == 2 and b.play_slots == 1
			and int(b.formations[1]["id"]) == id and same_shape
			and int(b.plays[0]["formation"]) == id and route.size() == 2
			and route[1] == Vector2(0.6, 0.4) and back.formation_id == id
			and back.called_play() != null,
		"the board survives a save",
		"two shapes, one bound play, ids intact and still called")


func _deep_route() -> Array:
	var r := Chalkboard.blank_routes()
	r[0] = [Vector2(0.5, 0.90)] as Array[Vector2]
	return r


func _season() -> Season:
	var s := Season.new(MeleeRosters.starting_club(), 77)
	s.office.credits = 60
	return s
