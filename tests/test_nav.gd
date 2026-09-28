extends SceneTree
## WHERE BACK GOES.
##
##   godot --headless --path . --script res://tests/test_nav.gd
##
## Pete, 15 Sep 2026, playing the game for the first time end to end: *"Pressing
## back in any popup brings you all the way to the main club instead of the
## previous screen."*
##
## Every one of fifteen screens carried a literal Back destination. That is right
## for most of them most of the time and wrong the moment a screen has two ways
## in — the fighter card returns to the roster whether you reached it from the
## roster, the market's free-agent grid or the staff room, and two of those three
## throw the player back to the clubhouse having lost their place.
##
## **A screen cannot know where it was opened from, so it must not be the thing
## that decides where Back goes.** These checks are about the trail that decides
## instead: that it remembers, that it forgets at the right moments, and — the
## one that matters most — that it can never leave a Back button doing nothing.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []

const SEASON := "res://scenes/Season.tscn"
const ROSTER := "res://scenes/Roster.tscn"
const MARKET := "res://scenes/Market.tscn"
const TITLE := "res://scenes/Title.tscn"


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — where back goes ===\n")
	_test_the_trail_remembers_the_way_in()
	_test_it_forgets_when_a_career_opens_or_closes()
	_test_it_cannot_grow_for_ever()
	_test_a_screen_that_reloads_itself_is_not_a_step()
	_test_the_fallback_still_works_with_no_trail()
	await _test_back_never_points_at_the_screen_you_are_on()
	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE WAY BACK HOLDS (%d checks)\n" % checks)
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


## THE TRAIL WITHOUT THE WIPE. `UiKit.go()` plays a sound and starts a scene
## change, neither of which a headless test can or should do; what it also does
## is push. This drives the push and the pop directly, which is the part under
## test — a check that needed a real scene tree would be a check that never ran.
var _fake: Array[String] = []

func _visit(path: String) -> void:
	## Stand in for "we are now on `path`, and we got here through `go()`".
	##
	## THROUGH `_push`, NOT INTO THE ARRAY. The first cut of this appended to
	## `UiKit._trail` directly, which meant every check below was driving a data
	## structure rather than the code that maintains it — and the cap check duly
	## reported 30 against a cap of 6 and was correct, because the capping had
	## never run. The lookup of "what screen am I on" is the only part a headless
	## test cannot do, so that is the only part that is stood in for.
	if not _fake.is_empty():
		UiKit._push(_fake[_fake.size() - 1])
	_fake.append(path)


func _pop() -> String:
	if UiKit.trail_depth() == 0:
		return ""
	var to: String = UiKit._trail[UiKit.trail_depth() - 1]
	UiKit._trail.remove_at(UiKit.trail_depth() - 1)
	if not _fake.is_empty():
		_fake.remove_at(_fake.size() - 1)
	return to


func _clear() -> void:
	UiKit.trail_reset()
	_fake.clear()


func _test_the_trail_remembers_the_way_in() -> void:
	## THE EXACT PATH FROM THE REPORT. Clubhouse, squad's roster, a fighter card.
	## Back from the fighter used to land on the roster by literal — right by
	## luck — and Back from the roster landed on the season screen, which is
	## where Pete found himself instead of where he had been.
	_clear()
	_visit(SEASON)
	_visit(ROSTER)
	_visit("res://scenes/Fighter.tscn")
	_ok(_pop() == ROSTER, "back from a fighter card returns to the list it was opened from",
		"three deep, popped to %s" % ROSTER.get_file())
	_ok(_pop() == SEASON, "and back again returns to the clubhouse, one step at a time",
		"not three steps at once, which is the bug")

	## THE SAME SCREEN, A DIFFERENT WAY IN. This is the case a literal cannot
	## get right, because the destination depends on something the destination
	## does not know.
	_clear()
	_visit(SEASON)
	_visit(MARKET)
	_visit("res://scenes/Fighter.tscn")
	_ok(_pop() == MARKET, "the same fighter card opened from the market returns to the market",
		"a literal 'Roster' would have thrown the player out of the market")
	notes.append("the trail: fighter -> roster or market, decided by the way in")


func _test_it_forgets_when_a_career_opens_or_closes() -> void:
	## A CAREER IS NOT A STEP IN A PATH. Walking deep into a club and then
	## leaving by the Menu button must not leave a trail that Back can climb
	## from the front door into a half-finished season.
	_clear()
	_visit(SEASON)
	_visit(ROSTER)
	_visit("res://scenes/Fighter.tscn")
	UiKit.trail_reset()
	_ok(UiKit.trail_depth() == 0, "leaving a career cuts the trail",
		"three screens deep, then nothing")


func _test_it_cannot_grow_for_ever() -> void:
	## A TRAIL THAT ONLY GROWS is a slow leak in an object that lives for the
	## whole run, and it is also a Back button that takes forty presses. The cap
	## drops the OLDEST entry, so the steps a player can actually remember are
	## the ones that survive.
	_clear()
	_visit(SEASON)
	for i in 30:
		UiKit._push("res://step_%d.tscn" % i)
	_ok(UiKit.trail_depth() <= UiKit.TRAIL_MAX,
		"and it cannot grow past its cap",
		"%d after 30 moves, cap is %d" % [UiKit.trail_depth(), UiKit.TRAIL_MAX])
	_ok(UiKit._trail[UiKit.trail_depth() - 1] == "res://step_29.tscn",
		"and what it keeps is the most recent, not the oldest",
		"the last step in is the first step back")
	notes.append("the cap: %d, and it drops from the front" % UiKit.TRAIL_MAX)


func _test_a_screen_that_reloads_itself_is_not_a_step() -> void:
	## THE SEASON SCREEN REBUILDS ON EVERY TAB CHANGE. If that counted as a
	## step, Back from the roster would take five presses to leave the clubhouse
	## and the fix would be worse than the bug.
	_clear()
	UiKit._push(SEASON)
	UiKit._push(SEASON)
	UiKit._push(SEASON)
	_ok(UiKit.trail_depth() <= 2, "a screen pushing itself twice is one step, not two",
		"depth %d after three pushes of the same path" % UiKit.trail_depth())


func _test_the_fallback_still_works_with_no_trail() -> void:
	## EVERY EXISTING CALL SITE STILL SAYS SOMETHING TRUE. The argument stopped
	## being a destination and became a fallback, which means fifteen screens
	## needed no edit and a deep-linked screen behaves exactly as it did before
	## any of this — the safest possible shape for a change to navigation.
	_clear()
	_ok(UiKit.trail_depth() == 0, "an empty trail is the normal state on a fresh load",
		"nothing to pop, so `back(fallback)` goes to the fallback")

	## The rest of this check needs a real current screen, so it runs after a
	## frame in `_test_back_never_points_at_the_screen_you_are_on`.


## A TRAIL POINTING AT THE SCREEN YOU ARE ON falls back rather than going
## nowhere. Asked of a real screen in the tree: Settings is loaded the way a
## scene loaded "any other way" would be, the trail is left pointing at it, and
## Back must still leave.
func _test_back_never_points_at_the_screen_you_are_on() -> void:
	await process_frame
	Juice.set_enabled(false)
	change_scene_to_file("res://scenes/Settings.tscn")
	for i in 10:
		await process_frame
		if current_scene != null and current_scene.scene_file_path.ends_with("Settings.tscn"):
			break
	_clear()
	UiKit._trail.append("res://scenes/Settings.tscn")
	Juice.take_pending_scene()
	UiKit.back(TITLE)
	var went := Juice.take_pending_scene()
	_ok(went == TITLE, "a trail pointing at the current screen falls back instead",
		"on %s with the trail pointing at it, Back went to '%s'" % [
			current_scene.scene_file_path.get_file() if current_scene else "-", went])
	_clear()
	UiKit._trail.append(ROSTER)
	UiKit.back(TITLE)
	went = Juice.take_pending_scene()
	_ok(went == ROSTER, "and a trail pointing elsewhere is followed",
		"Back went to '%s'" % went)
	_clear()
