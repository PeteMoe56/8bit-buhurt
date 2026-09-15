extends SceneTree
## The deck, and the number it moves.
##
##   godot --headless --path . --script res://tests/test_dilemma.gd
##
## Two rules hold this feature up and both are the kind that break silently.
##
## THE FIRST: every option costs something. A dilemma with a free answer is a
## quiz, and a player solves a quiz once and then stops reading — so a card
## written in one sitting with an option that nets out positive does not make the
## game easier, it deletes the feature. That is a property of fifteen hand-written
## dictionaries and it is asserted here rather than reviewed, because the next
## card somebody adds will be written in one sitting too.
##
## THE SECOND: morale has to be able to move both ways. It is what the deck spends
## and it is now what decides who waits for a club and who retires early, so a
## morale that pins at the floor makes every hard choice free and every struggling
## club unsalvageable.

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	SaveGame.set_namespace("dilemma")
	print("\n=== 8-Bit Buhurt — the deck ===\n")
	_test_every_option_costs_something()
	_test_a_card_blocks_the_matchday()
	_test_the_deck_does_not_repeat_itself()
	_test_the_card_survives_a_save()
	_test_morale_cannot_be_pinned()
	_test_a_card_cannot_break_a_clamp()
	_test_morale_reaches_something()
	_test_every_mood_stays_readable()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE DECK HOLDS (%d checks)\n" % checks)
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


func _test_every_option_costs_something() -> void:
	## THE RULE, swept over the whole deck. An option is free when nothing it does
	## points the wrong way — no credits out, no morale down, no notoriety lost, no
	## man hurt, no deal shortened, no raise given.
	##
	## `injury` and `wage` count as costs whichever way they point: a man out is a
	## man out, and a raise is money.
	var free: Array[String] = []
	var cards := 0
	var options := 0
	var texts_ok := true
	for card in Dilemma.CARDS:
		cards += 1
		## And while we are walking it: a card whose text names {man} but whose
		## `who` cannot find one, or a card with one option, is not a dilemma.
		if (card["options"] as Array).size() < 2:
			texts_ok = false
		if not String(card["text"]).contains("{") and not String(card["title"]).contains(" "):
			texts_ok = false
		for o in card["options"]:
			options += 1
			var fx: Dictionary = (o as Dictionary).get("fx", {})
			var costly := false
			for k in fx.keys():
				var v: float = float(fx[k])
				if v < 0.0 or String(k) == "injury" or (String(k) == "wage" and v > 1.0):
					costly = true
			if not costly:
				free.append("%s / %s" % [card["id"], o["label"]])
	notes.append("%d cards, %d options, every one of them priced" % [cards, options])
	if not free.is_empty():
		notes.append("  FREE: " + ", ".join(free))
	_ok(free.is_empty() and texts_ok and cards >= 10,
		"every option costs something",
		"no answer in the deck is strictly better than its neighbours, so no card has a solution")


func _test_a_card_blocks_the_matchday() -> void:
	## A dilemma the player can walk past is a notification. It joins the bid and
	## the cup in the queue the season screen already drains one at a time, and
	## answering it has to clear it — a card that survives its own answer would
	## lock the save.
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var guard := 0
	while s.dilemma.is_empty() and guard < 40:
		guard += 1
		if s.bid_open(): s.decline_bid()
		elif s.cup_pending(): s.sim_cup_tie()
		elif s.ready_to_roll(): s.roll_over()
		else: s.skip_event()
	## A CUP TIE OUTRANKS IT, and drawing a card is exactly the moment a cup can
	## also open — `skip_event` settles the matchday and deals the card in the
	## same call. So the queue is drained of everything that legitimately comes
	## first before the block is asserted, or this check is measuring the
	## ordering rather than the block. It failed on precisely that the first time
	## it ran, and the ordering it was tripping over is the correct one.
	while s.bid_open() or s.cup_pending():
		if s.bid_open(): s.decline_bid()
		else: s.sim_cup_tie()
	var blocked: bool = s.blocked_by() == "dilemma"
	var card := s.dilemma_card()
	var said := s.answer_dilemma(0)
	var cleared: bool = s.dilemma.is_empty() and s.blocked_by() != "dilemma"
	notes.append("drew \"%s\" after %d matchdays; answering it said: %s"
		% [card.get("title", "?"), guard, said])
	_ok(blocked and cleared and not card.is_empty()
			and String(card.get("body", "")).length() > 40,
		"a card blocks the matchday",
		"it queues with the bid and the cup, and answering it clears it")


func _test_the_deck_does_not_repeat_itself() -> void:
	## Not "never repeats" — a player should see a card again within a season. The
	## rule is that the armourer's bill does not land three matchdays running,
	## which is what makes a deck feel like a deck rather than a slot machine.
	var s := Season.new(MeleeRosters.starting_club(), 5150)
	var seen: Array[String] = []
	var worst := 99
	var guard := 0
	while seen.size() < 14 and guard < 400:
		guard += 1
		if not s.dilemma.is_empty():
			var id := String(s.dilemma["id"])
			var back := seen.size() - seen.rfind(id)
			if seen.has(id):
				worst = mini(worst, back)
			seen.append(id)
			s.answer_dilemma(0)
		elif s.bid_open(): s.decline_bid()
		elif s.cup_pending(): s.sim_cup_tie()
		elif s.ready_to_roll(): s.roll_over()
		else: s.skip_event()
	var distinct := {}
	for id in seen:
		distinct[id] = true
	notes.append("%d cards dealt, %d distinct, closest repeat %d apart (memory is %d)"
		% [seen.size(), distinct.size(), worst if worst < 99 else -1, Season.DILEMMA_MEMORY])
	_ok(seen.size() >= 10 and distinct.size() >= 6
			and (worst == 99 or worst > Season.DILEMMA_MEMORY),
		"the deck does not repeat itself",
		"nothing came back inside %d cards, and %d different situations turned up"
			% [Season.DILEMMA_MEMORY, distinct.size()])


func _test_the_card_survives_a_save() -> void:
	## The card on the table and the man it picked both have to come back — and
	## the man has to BE the man on the roster rather than a copy of him, or an
	## option that mends his harness mends nobody. Same trap the prospect had.
	const SLOT := 2
	SaveGame.delete(SLOT)
	var s := Season.new(MeleeRosters.starting_club(), 31337)
	var guard := 0
	while s.dilemma.is_empty() and guard < 40:
		guard += 1
		if s.bid_open(): s.decline_bid()
		elif s.cup_pending(): s.sim_cup_tie()
		elif s.ready_to_roll(): s.roll_over()
		else: s.skip_event()
	var id := String(s.dilemma.get("id", ""))
	var man := s.dilemma_man()
	SaveGame.save(s, SLOT)
	var back := SaveGame.load_slot(SLOT)
	SaveGame.delete(SLOT)

	var same: bool = back != null and String(back.dilemma.get("id", "")) == id \
		and back.blocked_by() == "dilemma"
	var identity: bool = back != null and back.dilemma_man() != null \
		and back.club.roster.has(back.dilemma_man()) \
		and back.dilemma_man().display_name == man.display_name
	## And the memory came with it, so a reload cannot deal the same card twice.
	var remembered: bool = back != null and back.dilemma_recent.has(id)
	notes.append("saved mid-card: \"%s\" about %s, and all three came back"
		% [id, man.display_name if man != null else "nobody"])
	_ok(same and identity and remembered,
		"the card survives a save",
		"the same card, the same man — the one on the roster, not a copy — and the deck's memory with it")


func _test_morale_cannot_be_pinned() -> void:
	## THE BUG THIS WAS WRITTEN FOR. Morale used to add a flat swing per result,
	## so a club losing more than it won subtracted a little every week with
	## nothing pulling back, and thirty probe seasons under three different
	## policies ALL ended pinned at the floor. Harmless while nothing read it;
	## the same afternoon it started deciding who waits and who retires, it would
	## have put every struggling club in a spiral with no bottom.
	## THE PROPERTY IS RECOVERABILITY, not a numeric floor. A logistic approaches
	## its bound asymptotically, so five hundred straight losses reaching 0.02 is
	## the curve behaving, not the bug — the bug was that a club could get there
	## in one bad season and never come back. So: a realistic run of bad results,
	## then a realistic run of good ones, and the second has to undo the first.
	var o := ClubOffice.new()
	for _i in 30:
		o.morale_after(false, false)
	var floor_ := o.morale
	for _i in 10:
		o.morale_after(true, false)
	var recovered := o.morale
	for _i in 100:
		o.morale_after(true, false)
	var ceil_ := o.morale

	## And the equilibrium has to actually spread across the words the screen
	## uses, or the five names are four too many.
	var line := ""
	var spread: Array[float] = []
	for rate in [0.8, 0.6, 0.4, 0.2]:
		var c := ClubOffice.new()
		var wins := 0.0
		for i in 600:
			wins += rate
			var won: bool = wins >= 1.0
			if won:
				wins -= 1.0
			c.morale_after(won, false)
		spread.append(c.morale)
		line += "wins %d in 5: %.2f %s   " % [int(round(rate * 5.0)), c.morale, c.morale_word()]
	var widens: bool = spread[0] - spread[spread.size() - 1] > 0.35

	notes.append("a disastrous season (30 losses) drops morale to %.2f; ten wins bring it back to %.2f"
		% [floor_, recovered])
	notes.append("where it settles: " + line.strip_edges())
	_ok(recovered > floor_ + 0.15 and ceil_ <= 0.99 and widens,
		"morale cannot be pinned",
		"thirty straight losses are undone by ten wins (%.2f -> %.2f), and the settling point spans %.2f across the win rates"
			% [floor_, recovered, spread[0] - spread[spread.size() - 1]])


func _test_a_card_cannot_break_a_clamp() -> void:
	## Every effect goes through the office's own functions rather than writing
	## its fields, so a card is the one thing in the game that could push
	## notoriety past 125 or a balance below nothing — and cannot.
	var s := Season.new(MeleeRosters.starting_club(), 777)
	s.office.notoriety = ClubOffice.NOTORIETY_MAX
	s.office.credits = 1
	s.office.morale = 0.99
	var pushed := 0
	var broke := false
	for card in Dilemma.CARDS:
		for i in (card["options"] as Array).size():
			s.dilemma = {"id": String(card["id"]), "man": 0, "rival": "X"}
			s.answer_dilemma(i)
			pushed += 1
			if s.office.notoriety > ClubOffice.NOTORIETY_MAX or s.office.notoriety < 1.0 \
					or s.office.credits < 0 or s.office.morale > 1.0 or s.office.morale < 0.0 \
					or s.office.fans > s.office.fan_cap() + 0.001:
				broke = true
	notes.append("played all %d options against a maxed club: notoriety %.1f, %d CC, morale %.2f, %d fans of a %d cap"
		% [pushed, s.office.notoriety, s.office.credits, s.office.morale,
			int(s.office.fans), int(s.office.fan_cap())])
	_ok(not broke and pushed > 30,
		"a card cannot break a clamp",
		"every option in the deck fired against a club already at every ceiling, and nothing went out of bounds")


func _test_morale_reaches_something() -> void:
	## A number nothing reads is a progress bar with a name on it — this codebase
	## has already thrown a facility out for being one. Morale is what the deck
	## spends, so before the deck existed it had to start deciding something.
	## It decides two things, and both are asserted rather than assumed.
	var f := FighterCard.new()
	f.age = 36
	f.strength = 60 ; f.base = 60 ; f.skill = 60 ; f.gas = 60 ; f.aggression = 60
	f.potential = f.overall() + 6

	var happy_stay := Contracts.will_wait(f, 40.0, 70, 0.95)
	var sad_stay := Contracts.will_wait(f, 40.0, 70, 0.10)
	var happy_go := Career.retire_chance(f, 0.95)
	var sad_go := Career.retire_chance(f, 0.10)

	notes.append("a 36-year-old out of contract waits %d%% of the time at a happy club and %d%% at a miserable one"
		% [int(round(happy_stay * 100.0)), int(round(sad_stay * 100.0))])
	notes.append("and retires %d%% of winters versus %d%%"
		% [int(round(happy_go * 100.0)), int(round(sad_go * 100.0))])
	_ok(happy_stay > sad_stay + 0.10 and sad_go > happy_go + 0.05,
		"morale reaches something",
		"men wait for a happy club and retire early at a miserable one, so a season of hard answers shows up on the team sheet")


func _test_every_mood_stays_readable() -> void:
	## THE SKIN, and the one way a skin breaks that nobody notices until a player
	## is squinting at a Worlds final.
	##
	## Pete asked for tournaments to wear the normal menus "except stylized...
	## in a boss battle sort of way", so `UiKit` now swaps a whole palette and all
	## 218 places in this game that draw anything follow it. That is enormous
	## leverage and it is enormous blast radius: one dark ink on one dark ground
	## in one mood makes an entire screen unreadable, in a state the player only
	## reaches a few times a season.
	##
	## So every mood is measured rather than eyeballed, against the same luma rule
	## IconBank already uses to stop a club wearing a mark nobody can see. One
	## function for "can this be read on that", used by the kit and by the shell.
	##
	## It caught a mistyped hex on the first run — `"2c3away"` is not a colour,
	## and Godot's `Color(String)` takes it without complaint and returns black.
	var worst := 1.0
	var bad: Array[String] = []
	var line := ""
	for m in UiKit.PALETTES.keys():
		UiKit.set_mood(int(m))
		var bg := UiKit.BG
		## Every colour that carries TEXT has to read on the ground and on a
		## panel. UP, DOWN and YOU are included: a green that vanishes on violet
		## is a result the player cannot see.
		var pairs := {
			"ink": UiKit.INK, "dim": UiKit.DIM, "you": UiKit.YOU,
			"up": UiKit.UP, "down": UiKit.DOWN,
		}
		for k in pairs.keys():
			for ground in [bg, UiKit.PANEL]:
				var d: float = absf(_luma(pairs[k]) - _luma(ground))
				worst = minf(worst, d)
				if d < 0.30:
					bad.append("%s/%s %.2f" % [UiKit.mood_name(), k, d])
		line += "%s %.2f   " % [
			("NORMAL" if UiKit.mood_name() == "" else UiKit.mood_name()),
			absf(_luma(UiKit.DIM) - _luma(bg))]
	UiKit.set_mood(UiKit.Mood.NORMAL)

	## And every hex has to parse. A garbled string gives black, which passes a
	## naive "is it a Color" check and fails a human.
	var parsed := true
	for m in UiKit.PALETTES.keys():
		var pal: Dictionary = UiKit.PALETTES[m]
		for k in pal.keys():
			if String(k) == "name":
				continue
			var hex := String(pal[k])
			if hex.length() != 6 or not hex.is_valid_hex_number(false):
				parsed = false
				bad.append("unparseable %s/%s" % [m, k])

	notes.append("dimmest text against its ground, by mood: " + line.strip_edges())
	if not bad.is_empty():
		notes.append("  UNREADABLE: " + ", ".join(bad))
	_ok(bad.is_empty() and parsed and worst >= 0.30,
		"every mood stays readable",
		"five palettes, every text colour measured against both the ground and a panel; the tightest pair is %.2f apart"
			% worst)


## Perceptual-ish luma, the same weighting IconBank uses to decide whether a
## mark reads against a kit. One rule for "can this be read on that".
static func _luma(c: Color) -> float:
	return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
