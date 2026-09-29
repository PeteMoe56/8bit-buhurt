extends SceneTree
## ONE QUEUE, AND THE SCREEN SHOWS ITS HEAD (29 Sep 2026).
##
##   godot --headless --path . --script res://tests/test_queue.gd
##
## `Season.blocked_by()` is the one answer to "what has to be dealt with before
## the next matchday": bid, cup, dilemma, promotion, in that order. The club tab
## said in a comment that it asked that answer — and then asked each question
## itself, promotion first, so a season that ended with a cup tie still to fight
## offered the promotion choice while the season said "cup". The comment also
## said `test_season.gd` asserted the two agree. Nothing did.
##
## This plays real careers and, every time the season is blocked, opens the real
## club tab and reads the button it offers against what the season says is next.
## Each combination of pending things is checked once, so the file stays quick.

var failures: Array[String] = []
var checks: int = 0

## What the tab's first action button says for each head of the queue.
const FIRST_BUTTON := {
	"promotion": "Take it",
	"bid": "Tournament bid",
	"cup": "Fight the tie",
	"": "End the season",
}
const BASES := [4242, 9001, 2718, 6060]
const SEASONS := 8


func _initialize() -> void:
	await process_frame
	Juice.set_enabled(false)
	print("\n=== 8-Bit Buhurt — the queue ===\n")
	var seen := {}
	var shown := 0
	var both := 0
	var bad: Array[String] = []
	for b in BASES:
		var s := Season.new(MeleeRosters.starting_club(), int(b))
		Session.season = s
		var m := ProbeManager.new()
		for y in SEASONS:
			m.winter(s)
			var guard := 0
			while guard < 80:
				guard += 1
				var q := 0
				while q < 10:
					q += 1
					var head := s.blocked_by()
					var ended := head == "" and s.season_complete()
					if head == "" and not ended:
						break
					var flags := "%s%s%s%s" % [
						"B" if s.bid_open() else "-", "C" if s.cup_pending() else "-",
						"D" if not s.dilemma.is_empty() else "-",
						"P" if s.promotion_offered() else "-"]
					if flags.count("-") <= 2:
						both += 1
					var key := head + "/" + flags
					if not seen.has(key):
						seen[key] = true
						shown += 1
						var got: String = await _first_button(s)
						var want := _expected(s, head)
						if got != want:
							bad.append("%s (pending %s): screen offers '%s', season wants '%s'"
								% [head if head != "" else "end", flags, got, want])
					if ended:
						break
					match head:
						"bid": s.decline_bid()
						"dilemma": s.answer_dilemma(0)
						"cup": s.sim_cup_tie()
						"promotion": s.answer_promotion(true)
				if s.season_complete() and s.blocked_by() == "":
					break
				s.skip_event()
			s.roll_over()
	_ok(bad.is_empty() and shown >= 4,
		"the club tab offers what the season says comes next",
		"%d states checked across %d careers x %d seasons, %d with two or more pending%s"
			% [shown, BASES.size(), SEASONS, both, "" if bad.is_empty() else ": " + "; ".join(bad)])
	print("")
	if failures.is_empty():
		print("THE QUEUE HOLDS (%d checks)\n" % checks)
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


func _expected(s: Season, head: String) -> String:
	if head == "dilemma":
		var opts: Array = s.dilemma_card().get("options", [])
		return String((opts[0] as Dictionary)["label"]) if not opts.is_empty() else ""
	return String(FIRST_BUTTON[head])


## The leftmost button on the action row of the club tab, as the player sees it.
func _first_button(s: Season) -> String:
	Session.season = s
	var n: Node = (load("res://scenes/Season.tscn") as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	n.set("tab", 0)
	n.call("_rebuild")
	await process_frame
	var row_y: float = float(SeasonScene.action_y())
	var best: Button = null
	for b in _buttons(n):
		var btn := b as Button
		if not btn.is_visible_in_tree() or absf(btn.position.y - row_y) > 1.0:
			continue
		if best == null or btn.position.x < best.position.x:
			best = btn
	var got := best.text if best != null else "(none)"
	n.queue_free()
	await process_frame
	return got


func _buttons(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is Button:
			out.append(c)
		out.append_array(_buttons(c))
	return out
