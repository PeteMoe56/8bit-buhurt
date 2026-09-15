extends SceneTree
## THE FOUR ON THE CORNER, and the one way they could go quietly wrong.
##
##   godot --headless --path . --script res://tests/test_favorites.gd
##
## PETE'S SPEC, since the playbook pass: *"on the right side you have your four
## favorited plays."* The corner shipped showing four and nothing chose which
## four — it fell back to whatever came out of the live shape, which is a sensible
## default and is not the feature.

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the favorites ===\n")
	_test_a_star_goes_on_and_comes_off()
	_test_four_is_the_lot()
	_test_a_deleted_play_takes_its_star_with_it()
	_test_an_index_would_have_pointed_at_the_wrong_play()
	_test_they_survive_a_save()
	_test_the_four_can_be_put_in_order()
	_test_a_screen_can_actually_reorder_them()
	print("")
	if failures.is_empty():
		print("THE FAVORITES HOLD (%d checks)\n" % checks)
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


## FOUR SLOTS THE PLAYER CAN ORDER.
##
## Starred plays could be added and removed and never arranged, which is the one
## thing four slots want: the corner offers them in list order, so the first is
## the one a player reaches for under a clock, and until now that was whichever
## he happened to star first.
##
## Two taps rather than a drag — a drag needs a pointer the corner has no time
## for. The check is the property, not the implementation: moving one up and
## then down again is the list you started with, the ends refuse to walk off,
## and nothing is ever lost or duplicated by a move.
func _test_the_four_can_be_put_in_order() -> void:
	var c := _board()
	var sh := _shape()
	for n in ["Hammer", "Anvil", "Wedge"]:
		c.toggle_favorite(sh, "play", n)
	var before := _keys(c)
	_ok(before == ["Hammer", "Anvil", "Wedge"],
		"the list starts in the order they were starred", str(before))

	c.promote_favorite(2)
	_ok(_keys(c) == ["Hammer", "Wedge", "Anvil"],
		"one moves up", str(_keys(c)))
	c.demote_favorite(1)
	_ok(_keys(c) == before, "and back down again is where it started", str(_keys(c)))

	## THE ENDS DO NOT WALK OFF, and they do not error either — asking the top
	## one to go up is a thing a player will do every time he reaches the top.
	var top_err := c.promote_favorite(0)
	var bottom_err := c.demote_favorite(c.favorites.size() - 1)
	_ok(top_err == "" and bottom_err == "" and _keys(c) == before,
		"the ends hold, quietly",
		"top and bottom both refuse without a complaint and nothing moved")

	## AND NOTHING IS LOST OR DUPLICATED BY ANY MOVE. A swap that drops an entry
	## is a swap that loses a play, which is the failure worth checking for.
	var moves := 0
	for i in 12:
		if i % 2 == 0:
			c.promote_favorite(i % 3)
		else:
			c.demote_favorite(i % 3)
		moves += 1
	var after := _keys(c)
	after.sort()
	var want := before.duplicate()
	want.sort()
	_ok(after == want, "and %d moves lose nothing and duplicate nothing" % moves,
		"%s still holds the same three" % str(_keys(c)))
	## AN INDEX OFF THE END IS REFUSED rather than clamped: the screen and the
	## model are a frame apart and a play can be deleted between them.
	_ok(c.promote_favorite(99) != "" and c.demote_favorite(-1) != "",
		"an index that is not on the list is refused",
		"both come back with a sentence")
	print("   the order: %s" % ", ".join(_keys(c)))


## The favorites as keys, which is what the player sees in the corner.
func _keys(c: Chalkboard) -> Array:
	var out: Array = []
	for f in c.favorites:
		out.append(String(f["key"]))
	return out

## A board with room, three plays drawn for the same shape, in a known order.
func _board() -> Chalkboard:
	var c := Chalkboard.new()
	c.play_slots = 8
	c.formation_slots = 4
	var names := ["Hammer", "Anvil", "Wedge"]
	for i in names.size():
		var err := c.save_play(i, names[i], _routes(), Chalkboard.UNIVERSAL)
		if err != "":
			push_error("could not build the board: %s" % err)
	return c


## A legal set of five routes. `Tuning.play_legal` refuses blanks, and a test
## board built out of illegal plays is a test board with no plays on it.
func _routes() -> Array:
	var out: Array = []
	for i in 5:
		var leg: Array[Vector2] = [Vector2(0.5, 0.5), Vector2(0.5, 0.3)]
		out.append(leg)
	return out


func _shape() -> int:
	return int(Tuning.FORMATIONS.keys()[0])


func _test_a_star_goes_on_and_comes_off() -> void:
	var c := _board()
	var sh := _shape()
	_ok(not c.is_favorite(sh, "play", "Anvil"), "nothing is starred to begin with",
		"%d favorites" % c.favorites.size())
	_ok(c.toggle_favorite(sh, "play", "Anvil") == ""
		and c.is_favorite(sh, "play", "Anvil"), "a star goes on",
		"%d favorites" % c.favorites.size())
	_ok(c.toggle_favorite(sh, "play", "Anvil") == ""
		and not c.is_favorite(sh, "play", "Anvil"), "and the same tap takes it off",
		"%d favorites" % c.favorites.size())


## REFUSED, NOT ROTATED. A list that quietly drops the oldest thing you put in it
## is a list you stop trusting, and four is a decision worth making.
func _test_four_is_the_lot() -> void:
	var c := _board()
	var sh := _shape()
	for st in Tuning.STRATEGIES.keys():
		if c.favorites.size() >= Chalkboard.MAX_FAVORITES:
			break
		c.toggle_favorite(sh, "push", str(int(st)))
	while c.favorites.size() < Chalkboard.MAX_FAVORITES:
		c.toggle_favorite(sh, "play", "Hammer")
	var err := c.toggle_favorite(sh, "play", "Wedge")
	_ok(err != "" and c.favorites.size() == Chalkboard.MAX_FAVORITES,
		"the fifth is refused rather than pushing the first out",
		"'%s', still %d" % [err, c.favorites.size()])


func _test_a_deleted_play_takes_its_star_with_it() -> void:
	var c := _board()
	var sh := _shape()
	c.toggle_favorite(sh, "play", "Wedge")
	_ok(c.live_favorites().size() == 1, "a starred play shows up live",
		"%d live" % c.live_favorites().size())
	## Find Wedge's index and remove it.
	var idx := -1
	for i in c.plays.size():
		if String(c.plays[i]["name"]) == "Wedge":
			idx = i
	c.delete_play(idx)
	_ok(c.live_favorites().is_empty() and c.favorites.is_empty(),
		"and a deleted play takes its star with it, pruned in place",
		"%d live, %d stored" % [c.live_favorites().size(), c.favorites.size()])


## THE BUG THIS DESIGN EXISTS TO PREVENT, demonstrated rather than asserted
## about.
##
## `plays_for` hands out each play's position in the list and `delete_play` uses
## `remove_at`, so deleting "Hammer" slides "Anvil" and "Wedge" down one. A
## favorite holding index 1 pointed at Anvil before and points at Wedge after —
## no error, no empty slot, just a different play under the same star.
##
## The check runs that arithmetic out loud and then shows the name key surviving
## the same delete pointing at what it always pointed at.
func _test_an_index_would_have_pointed_at_the_wrong_play() -> void:
	var c := _board()
	var sh := _shape()
	var before := c.plays_for(sh)
	var was_at_1 := String(before[1]["name"])
	c.toggle_favorite(sh, "play", was_at_1)
	c.delete_play(0)
	var after := c.plays_for(sh)
	var now_at_1 := String(after[1]["name"]) if after.size() > 1 else "(gone)"
	_ok(was_at_1 != now_at_1,
		"an index really would have moved under the star",
		"slot 1 was '%s', is now '%s'" % [was_at_1, now_at_1])
	var live := c.live_favorites()
	_ok(live.size() == 1 and String(live[0]["key"]) == was_at_1,
		"and the name key still points at the play the player starred",
		"'%s'" % String(live[0]["key"]))


func _test_they_survive_a_save() -> void:
	var c := _board()
	var sh := _shape()
	c.toggle_favorite(sh, "play", "Anvil")
	c.toggle_favorite(sh, "push", "0")
	var back := Chalkboard.from_dict(c.to_dict())
	_ok(back.favorites.size() == 2
		and back.is_favorite(sh, "play", "Anvil")
		and back.is_favorite(sh, "push", "0"),
		"they come back off a save", "%d favorites" % back.favorites.size())
	## A SAVE FROM BEFORE THEY EXISTED, which is every save anybody has.
	var old := c.to_dict()
	old.erase("favorites")
	_ok(Chalkboard.from_dict(old).favorites.is_empty(),
		"and a save written before favorites existed loads with none",
		"no key, no crash")
	## AND A HAND-EDITED ONE IS NOT TRUSTED.
	var junk := c.to_dict()
	junk["favorites"] = [{"shape": sh, "kind": "play", "key": "A"},
		{"nonsense": true}, {"shape": sh, "kind": "weird", "key": "B"},
		{"shape": sh, "kind": "play", "key": "C"},
		{"shape": sh, "kind": "play", "key": "D"},
		{"shape": sh, "kind": "play", "key": "E"}]
	var fixed := Chalkboard.from_dict(junk)
	var kinds_ok := true
	for f in fixed.favorites:
		if String(f["kind"]) != "push" and String(f["kind"]) != "play":
			kinds_ok = false
	_ok(fixed.favorites.size() <= Chalkboard.MAX_FAVORITES and kinds_ok,
		"and a hand-edited save is coerced and capped, not trusted",
		"%d favorites, every kind legal" % fixed.favorites.size())


## AND THERE IS A CONTROL FOR IT.
##
## `promote_favorite` and `demote_favorite` passed every check above for a week
## with nothing in the game calling either one — a tested verb no player can
## reach, which is the most convincing kind of dead code because the suite is
## green. **A function with no caller is not a feature, it is a question nobody
## answered.**
##
## The control is the strip under the playbook in starring mode, NOT the corner.
## The corner runs on a clock and its favorites sit in a two-by-two grid, which
## has four positions and no up or down; the strip has no clock and reads left to
## right in the same order the grid fills. This check holds that a screen calls
## the verb at all — where it lives is a design decision and this is not the
## place to pin it.
func _test_a_screen_can_actually_reorder_them() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/melee/melee_scene.gd")
	_ok(src.contains("promote_favorite("),
		"a screen calls the verb that moves one up the list",
		"the strip under the playbook, in starring mode")
	## AND THE STRIP IS ONLY THERE WHEN THERE IS SOMETHING TO ORDER. One chip
	## that cannot move is a control a player cannot tell from a broken one.
	_ok(src.contains("favs.size() < 2"),
		"and it does not draw a list of one",
		"ordering one favorite is not a thing that can be done")
