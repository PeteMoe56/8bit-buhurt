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
	"cup": "Fight the cup bout",
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
	var order_bad: Array[String] = []
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
					## AND THE ORDER ITSELF: bid, cup, dilemma, promotion. The
					## screen agreeing with the season is no use if the season's
					## own order moves (a mutation swapping two survived).
					var want_head := ""
					for pair in [["bid", s.bid_open()], ["cup", s.cup_pending()],
							["sendoff", SendOff.due(s)],
							["dilemma", not s.dilemma.is_empty()], ["promotion", s.promotion_offered()]]:
						if bool(pair[1]):
							want_head = String(pair[0])
							break
					if head != want_head:
						order_bad.append("pending %s: season says '%s', the order says '%s'" % [flags, head, want_head])
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
						"sendoff": s.answer_send_off()
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
	## A CARD AND PROMOTION AT ONCE. Since the calendar (30 Sep) a card is only
	## dealt on a league Saturday and the season ends weeks later, so play never
	## reaches this pair on its own any more — it is built: a finished season in
	## a promotion place with a card put on the table.
	var built := Season.new(MeleeRosters.starting_club(), 4242)
	var g := 0
	while not built.season_complete() and g < 60:
		g += 1
		match built.blocked_by():
			"bid": built.decline_bid()
			"dilemma": built.answer_dilemma(0)
			"cup": built.sim_cup_tie()
			_: built.skip_event()
	if built.bid_open():
		built.decline_bid()
	var bw := built.world
	bw.finalists[bw.player_tier()] = [bw.player_club, -1]
	built.dilemma = {"id": "van", "man": 0}
	var pair_head := built.blocked_by()
	if not built.promotion_offered():
		order_bad.append("the built season is not offered promotion")
	elif pair_head != "dilemma":
		order_bad.append("card and promotion pending: season says '%s', the order says 'dilemma'" % pair_head)
	_ok(order_bad.is_empty(), "and the season's own order is bid, cup, send-off, dilemma, promotion",
		"every blocked state checked" if order_bad.is_empty() else "; ".join(order_bad.slice(0, 4)))
	await _gold_step()
	await _bid_card_button()
	await _money_help()
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
	## A CLUB WHOSE GROUND THE DIVISION ABOVE WOULD REFUSE is offered the build
	## first, in gold (Pete, 1 Oct 2026: a "Build Now" at the promotion gate).
	if head == "promotion" and not s.ground_gap().is_empty():
		return UiKit.with_upkeep(UiKit.t("Build now · %d CC") % int(s.ground_gap()["total"]),
			s.office.arena_upkeep_at(Arena.level_for_tier(s.world.player_tier() + 1)))
	return String(FIRST_BUTTON[head])


## THE GOLD BUTTON IS THE NEXT REAL STEP (1 Oct novice report, Pete approved).
## Nothing blocked, first bout fought: a starter under the pass mark makes it
## "Fix kit"; else a ground short for the division above that can be built this
## week makes it "Build <next>"; otherwise the fight stays gold. Read off the
## real hub, one state at a time, and each step's button does what it says.
func _gold_step() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var g := 0
	while g < 40 and (not s.first_bout_done() or s.blocked_by() != ""):
		g += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"sendoff": s.answer_send_off()
			"cup": s.sim_cup_tie()
			"": s.skip_event()
			_: break
	var bad: Array[String] = []
	if s.blocked_by() != "" or s.season_complete() or s.ground_gap().is_empty():
		bad.append("no open week with a ground gap to test (blocked '%s')" % s.blocked_by())
	else:
		var man: FighterCard = s.club.active_eight()[0]
		var was := man.armor
		var purse := s.office.credits
		## 1. A starter the marshals would turn away.
		man.armor = FighterCard.INSPECTION_MIN - 0.1
		s.office.credits = 9999
		var got: String = await _first_button(s)
		if s.gold_step() != "kit" or got != UiKit.t("Fix kit"):
			bad.append("kit under the pass mark: step '%s', gold '%s'" % [s.gold_step(), got])
		## 2. Kit passes; the ground is short and the next level is affordable.
		man.armor = was
		var gap := s.ground_gap()
		var want := UiKit.with_upkeep(UiKit.t("Build %s · %d CC") % [UiKit.t(String(gap["next"])),
			int(gap["next_cost"])], s.office.arena_upkeep_next())
		got = await _first_button(s)
		if s.gold_step() != "build" or got != want:
			bad.append("ground short, purse full: step '%s', gold '%s', want '%s'" % [s.gold_step(), got, want])
		## 3. Short of the price: the fight is gold again.
		s.office.credits = int(gap["next_cost"]) - 1
		got = await _first_button(s)
		var opp := s.opponent_id()
		var fight := (UiKit.t("Fight: vs %s") % String(s.world.clubs[opp].get("short", "?"))) if opp >= 0 else ""
		if s.gold_step() != "" or (opp >= 0 and got != fight):
			bad.append("ground short, purse short: step '%s', gold '%s', want '%s'" % [s.gold_step(), got, fight])
		## 4. Pressing Build builds it, and the fight takes the gold back for the week.
		s.office.credits = 9999
		var lv := s.office.arena.level
		var n: Node = (load("res://scenes/Season.tscn") as PackedScene).instantiate()
		Session.season = s
		root.add_child(n)
		await process_frame
		n.set("ground_open", false)
		n.call("_rebuild")
		await process_frame
		for b in _buttons(n):
			if (b as Button).text == want:
				(b as Button).pressed.emit()
				break
		await process_frame
		if s.office.arena.level != lv + 1 or s.gold_step() == "build":
			bad.append("Build pressed: level %d -> %d, step now '%s'" % [lv, s.office.arena.level, s.gold_step()])
		n.queue_free()
		await process_frame
		s.office.credits = purse
	_ok(bad.is_empty(), "the gold button is the next real step: Fix kit, Build <next>, else the fight",
		"kit, ground, short purse and a pressed Build read off the hub" if bad.is_empty() else "; ".join(bad))


## THE BID CARD HAS A REAL BUTTON (1 Oct novice report, Pete approved): the gold
## words "Choose at the Arena >" read as a caption. A framed, visible button now
## sits inside the card, clear of its words, and leads to the Arena.
func _bid_card_button() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var g := 0
	while g < 20 and s.blocked_by() != "bid":
		g += 1
		s.skip_event()
	var bad: Array[String] = []
	if s.blocked_by() != "bid":
		bad.append("no bid on the table to look at")
	else:
		Session.season = s
		var n: Node = (load("res://scenes/Season.tscn") as PackedScene).instantiate()
		root.add_child(n)
		await process_frame
		n.set("ground_open", false)
		n.set("tab", 0)
		n.call("_rebuild")
		await process_frame
		var card := Rect2(24, SeasonScene.CONTENT_Y + 20.0, SeasonScene.fixture_w(), SeasonScene.FIXTURE_H)
		var found: Button = null
		for b in _buttons(n):
			if (b as Button).has_meta("bid_card"):
				found = b
		if found == null:
			bad.append("no button on the bid card")
		else:
			var r := found.get_global_rect()
			if found.flat or not found.is_visible_in_tree():
				bad.append("the card's button is flat or hidden")
			if found.text != UiKit.t("Choose at the Arena"):
				bad.append("it says '%s'" % found.text)
			if not card.encloses(r):
				bad.append("it sits outside the card: %s in %s" % [r, card])
			## Below the line of words above it (baseline CONTENT_Y + 20 + 70).
			if r.position.y < card.position.y + 74.0:
				bad.append("it overlaps the card's words (top %.0f)" % r.position.y)
			if found.pressed.get_connections().is_empty():
				bad.append("pressing it does nothing")
		n.queue_free()
		await process_frame
	_ok(bad.is_empty(), "the bid card has a real button to the Arena",
		"framed, inside the card, under its words" if bad.is_empty() else "; ".join(bad))


## A "?" BY THE CC (1 Oct novice report, Pete approved) opens the Guide on its
## Money page. It sits in the header clear of the purse box and the club's name,
## and pressing it lands on the Guide with Money open.
func _money_help() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	var bad: Array[String] = []
	var n: Node = (load("res://scenes/Season.tscn") as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	n.set("ground_open", false)
	n.call("_rebuild")
	await process_frame
	var q: Button = null
	for b in _buttons(n):
		if (b as Button).has_meta("money_help"):
			q = b
	if q == null or not q.is_visible_in_tree():
		bad.append("no '?' by the CC")
	else:
		var r := q.get_global_rect()
		if r.intersects(SeasonScene.purse_box()):
			bad.append("the '?' sits on the purse box")
		if r.end.y > 62.0:
			bad.append("the '?' hangs below the header")
		q.pressed.emit()
		var guide: Node = null
		for i in 30:
			await process_frame
			for c in root.get_children():
				if c is GuideScene:
					guide = c
			if guide != null:
				break
		if guide == null:
			bad.append("pressing it did not open the Guide")
		elif int(guide.get("tab")) != GuideScene.Topic.MONEY \
				or String(GuideScene.topics()[int(guide.get("tab"))]) != UiKit.t("Money"):
			bad.append("the Guide opened on page %d" % int(guide.get("tab")))
		if Session.guide_topic != -1:
			bad.append("the page request was not cleared")
		if guide != null:
			guide.queue_free()
	if is_instance_valid(n):
		n.queue_free()
	await process_frame
	_ok(bad.is_empty(), "a '?' by the CC opens the Guide on Money",
		"in the header, clear of the purse, lands on Money" if bad.is_empty() else "; ".join(bad))


## The button the club tab offers as the way forward: the gold (primary) one on
## the action row if there is one — since 30 Sep 2026 it sits bottom-right on
## every tab — else the leftmost, as the player sees it.
func _first_button(s: Season) -> String:
	Session.season = s
	var n: Node = (load("res://scenes/Season.tscn") as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	## THE MID-SEASON GROUND CARD sits over the hub when it is due; it has its
	## own Later. Read the row under it, as a player does after Later.
	n.set("ground_open", false)
	n.set("tab", 0)
	n.call("_rebuild")
	await process_frame
	var row_y: float = float(SeasonScene.action_y())
	var best: Button = null
	for b in _buttons(n):
		var btn := b as Button
		if not btn.is_visible_in_tree() or absf(btn.position.y - row_y) > 1.0:
			continue
		if best != null and best.has_meta("primary") and not btn.has_meta("primary"):
			continue
		if best == null or (btn.has_meta("primary") and not best.has_meta("primary")) \
				or btn.position.x < best.position.x:
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
