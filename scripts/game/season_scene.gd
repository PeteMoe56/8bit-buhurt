extends Node2D
## The clubhouse: the hub everything else hangs off.
##
## Three tabs and a primary action, which is the shape a manager game settles on
## for a reason — the thing you came to do is one tap from opening the game, and
## everything else is one tap from that. Loosely Retro Bowl's shell; deliberately
## not its layout, and none of its vocabulary.
##
##   CLUB     the next fixture and the table you are trying to climb
##   SQUAD    the eight who travel, the reserve, and the moves between them
##   HONOURS  what the club has actually won
##
## Drawn with primitives on the same portrait 540x960 as the melee, so sprites
## drop in later without touching layout.

enum Tab { CLUB, SQUAD, MARKET, OFFICE, HONOURS }

## Landscape, 960x540. Four tabs across the top and two columns underneath —
## which is the layout the extra width is FOR: the fixture and the table are
## side by side instead of the table being pushed below the fold, and the squad
## screen shows the eight and the reserve at once instead of scrolling.
const TAB_Y := 72.0
const TAB_H := 34.0
const TAB_W := 160.0
## Where a tab's own content may start: below the tab strip and below the line
## the flash message is written on. Every tab used to pick its own top and the
## SQUAD one collided with the tab underline.
const CONTENT_Y := 132.0
const FLASH_Y := 122.0
const ROW_H := 22.0
## WHERE THE TABLE STARTS. The club tab is two columns — the fixture on the left
## and the division on the right — and with both pinned to their own edge the
## extra width on a handset opened as a hole down the MIDDLE of the screen
## rather than as margin at the sides. The split floats instead: 47.5% of the
## room to the fixture, the rest to the table, which lands on exactly 470 at
## 960 wide and keeps the proportion at 1170 and 1260.
const TABLE_SPLIT := 0.475


static func fixture_w() -> float:
	return (UiKit.span() - 24.0) * TABLE_SPLIT


static func table_x() -> float:
	return 48.0 + fixture_w()
## The header's purse and the frame it sits in. Read by `test_ink.gd`.
## THE PURSE AND THE MOOD RIDE THE RIGHT EDGE, beside the Menu button, rather
## than sitting at a fixed 604 with a growing hole between them and the corner.
## Kept as functions with the same 960-wide answers the constants had, so the
## `test_ink.gd` purse check and this screen still read one source.
const PURSE_W := 150.0
const PURSE_H := 38.0
const PURSE_SIZE: int = 20


static func purse_box() -> Rect2:
	return Rect2(UiKit.right_edge(356.0), 12.0, PURSE_W, PURSE_H)


static func purse_at() -> Vector2:
	return Vector2(UiKit.right_edge(338.0), 38.0)


const TABLE_Y := 140.0
## WHERE THE BUTTON ROW SITS — sixty-four pixels off the bottom of whatever
## canvas the game got. On every handset that is 476, the number this was before
## it moved, because a handset never changes the 540. A 4:3 tablet gets 720 of
## height and the row goes to the bottom of it instead of floating two-thirds
## up the screen with a third of a screen of nothing underneath.
const ACTION_INSET := 64.0


static func action_y() -> float:
	return UiKit.screen().y - ACTION_INSET

var font: Font
var season: Season
var ui: CanvasLayer
var tab: int = Tab.CLUB
var flash := ""
## The counter, open or shut. A modal on this screen for the same reason the
## fighter's meeting card is one: real money deserves a deliberate stop.
var shop_open := false
## The squad screen's whole interaction: pick a man, then pick who he trades
## places with. Two taps, no modal, and the second tap is on a list you are
## already looking at.
var picked: FighterCard = null


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	if Session.season == null:
		Session.season = Season.new(MeleeRosters.starting_club(), randi())
	season = Session.season
	ui = CanvasLayer.new()
	add_child(ui)
	_rebuild()


# ------------------------------------------------------------------ controls
## WHO LEFT. A squad that quietly loses two men over a summer and signs two
## strangers is the single most alarming thing that can happen without a message,
## and the player finds out three screens later when a name he does not know is
## standing at Rail. Retirements are named; the walk-ons are counted, because the
## point about them is that they are interchangeable.
func _winter_word() -> String:
	var w: Dictionary = season.last_winter
	if w.is_empty():
		return ""
	var gone: Array = w.get("retired", [])
	var walked: Array = w.get("walked", [])
	var took: Array = w.get("signed", [])
	if gone.is_empty() and walked.is_empty():
		return ""
	var s := ""
	if not gone.is_empty():
		s += "  %s retired" % String(gone[0]).split(" (")[0]
		if gone.size() > 1:
			s += " and %d more" % (gone.size() - 1)
		s += "."
	## A man who WALKED is the more alarming of the two and gets said separately,
	## because the player could have stopped it and a retirement he could not.
	if not walked.is_empty():
		s += "  %s left on a free" % String(walked[0]).split(" (")[0]
		if walked.size() > 1:
			s += " with %d more" % (walked.size() - 1)
		s += "."
	if not took.is_empty():
		s += "  %d walk-on%s signed." % [took.size(), "" if took.size() == 1 else "s"]
	return s


## THE CLUB CAME APART, said first and said loudly.
##
## Half a squad walking out to found a rival in your own division is the biggest
## thing that can happen to a save, and it happens in the summer alongside three
## other reports. A player who reads "2 walk-ons signed" and finds out in October
## that the club across town is full of his own men has been told nothing.
func _split_word() -> String:
	var sp: Dictionary = season.last_split
	if sp.is_empty():
		return ""
	var took: Array = sp.get("took", [])
	return "THE CLUB SPLIT. %d men walked out to found %s, who are in your division this season." % [
		took.size(), String(sp.get("club", "a rival"))]


## The summer's bills, said on the same line as the summer's result — because a
## building that fell down and was never mentioned is a bug the player will
## report as one, and because the bill and the finish are the two halves of the
## same sentence: this is the year you had and this is what it cost to keep what
## you own.
func _upkeep_word() -> String:
	var u: Dictionary = season.last_upkeep
	if u.is_empty():
		return ""
	var lost: Array = u.get("lost", [])
	if not lost.is_empty():
		return "  Could not keep the %s — it fell a level." % String(lost[0]).to_lower()
	var billed: int = int(u.get("billed", 0))
	return "" if billed <= 0 else "  Upkeep %d CC." % billed


func _rebuild() -> void:
	for c in ui.get_children():
		c.queue_free()
	## THE SHOP REPLACES THE SCREEN'S CONTROLS WHEN IT IS OPEN, rather than
	## sitting on top of them. **A scrim cannot cover a Button** — this project
	## has paid for that five times now, and the fifth was here: the early return
	## sat BELOW the tab row, so the modal covered the tabs in the drawing and
	## left all five of them live. A tap on CLUBHOUSE behind the shop changed the
	## tab under it and the player found out on the way back.
	##
	## So it is the first thing after the wipe. Nothing else on this screen is
	## built while the counter is open, and the only way out of it is the modal's
	## own Back — which is what a modal is.
	if shop_open:
		_shop_controls()
		queue_redraw()
		return
	## Five tabs across 960 with the Menu button on the right, so they narrow
	## rather than the row wrapping — a wrapped tab row on a landscape phone
	## screen eats the first line of every page behind it.
	## EACH TAB CARRIES ITS MARK. A row of five words all the same length is
	## parsed; a row of five marks is recognised, which on a phone held in one
	## hand is the whole difference. The names stay — an icon alone is a rebus.
	var names := ["CLUB", "SQUAD", "MARKET", "CLUBHOUSE", "HONOURS"]
	var marks := ["shield", "roster", "coin", "hall", "trophy"]
	for i in names.size():
		ui.add_child(UiKit.button(names[i], Vector2(24 + float(i) * (TAB_W + 6.0), TAB_Y),
			Vector2(TAB_W, TAB_H), func():
				tab = i
				picked = null
				_rebuild(), marks[i]))
	## MENU IS NOT BACK. It leaves the career, which is the end of a path rather
	## than a step back along one — a trail that survived it would send Back from
	## the front door into somebody's half-finished season.
	ui.add_child(UiKit.button("Menu", Vector2(UiKit.right_edge(98.0), 14), Vector2(78, 36), func():
		Session.autosave()
		UiKit.trail_reset()
		UiKit.go("res://scenes/Title.tscn"), "cog"))
	match tab:
		Tab.CLUB: _club_controls()
		Tab.SQUAD: _squad_controls()
		Tab.MARKET: _market_controls()
		Tab.OFFICE: _office_controls()
	queue_redraw()


func _club_controls() -> void:
	## THE DRAW, WHENEVER THERE IS ONE TO SEE — not only while a tie of yours is
	## unplayed. It used to be built inside the cup-tie branch, so being knocked
	## out took the bracket away at exactly the moment it got interesting, and
	## the champion line on that screen was unreachable code.
	##
	## MOVED TWICE NOW, AND THE SECOND MOVE WAS THE MISTAKE. It began in the
	## action row, where at National the table runs to sixteen clubs and row 16
	## sits at y=477-497 — so it hid the rank and name of a club in a relegation
	## place. It was moved to y=70 on the right, which is **the tab strip**, and
	## it covered the right half of the HONOURS tab on every screen that had a
	## cup to look at.
	##
	## The left column under the fixture card is the one region on this tab that
	## belongs to nothing: the table is on the right and the action row is below.
	## `test_layout.gd` now treats the tab strip as a no-go region, so the second
	## mistake cannot be made a third time.
	if season.viewable_cup() != null:
		ui.add_child(UiKit.button("The draw", Vector2(24, 276),
			Vector2(200, 44), func():
				Session.viewing_cup = season.viewable_cup()
				Session.autosave()
				UiKit.go("res://scenes/Bracket.tscn"), "trophy"))

	## A CUP TIE OUTRANKS EVERYTHING. It is put in front of the player before the
	## league fixture and before the end-of-season button, because a bracket
	## waiting on a result is the only thing on this screen that other clubs are
	## standing around for.
	## THE BID FIRST, before the cup and before the fixture. It is a start-of-year
	## decision and the season does not begin until it is answered.
	## ONE QUEUE, ASKED ONCE. `blocked_by()` is the season's own answer to "what
	## has to be dealt with before you can fight", and this screen used to
	## re-implement its order — bid, dilemma, cup here; bid, cup, dilemma there;
	## dilemma first in the drawing. Three orderings of one rule, and the only
	## thing keeping them agreeing was that nobody had hit the case where they
	## differ. The season is asked now.
	if season.bid_open():
		ui.add_child(UiKit.button("Tournament bid", Vector2(24, action_y()),
			Vector2(204, 46), func():
				Session.autosave()
				UiKit.go("res://scenes/Arena.tscn"), "gate"))
		ui.add_child(UiKit.button("Pass this year", Vector2(244, action_y()),
			Vector2(204, 46), func():
				season.decline_bid()
				Session.autosave()
				flash = "No tournament this year."
				_rebuild()))
		return
	if season.cup_pending():
		ui.add_child(UiKit.button("Fight the tie", Vector2(24, action_y()),
			Vector2(204, 46), _fight_cup))
		## THE DRAW, next to the tie. Carried open since section 22: the screen
		## could say who you were fighting and never who else was left, which is
		## the one thing a cup has that a league does not.
		ui.add_child(UiKit.button("Sim it", Vector2(244, action_y()), Vector2(204, 46), func():
			var c := season.pending_cup()
			var nm := c.cup_name
			var rnd := c.round_name()
			season.sim_cup_tie()
			Session.autosave()
			flash = "%s %s simulated." % [nm, rnd.to_lower()]
			_rebuild()))
		return
	## THE CARD ON THE TABLE, AFTER THE CUP. It used to be drawn before it, so
	## with a bracket waiting AND a card on the table the two screens disagreed
	## about which one you were being asked to deal with — `blocked_by()` said
	## "cup" and the buttons offered the dilemma. One queue, one order, and
	## `test_season.gd` now asserts the screen and the season agree.
	##
	## It is still the smallest of the three and the one the player is most
	## smallest of the three things that can block a matchday and the one the
	## player is most likely to want to read rather than clear, so it does not go
	## first — but it does go before the fight, because a dilemma you can walk
	## past is a notification.
	if not season.dilemma.is_empty():
		var card := season.dilemma_card()
		var opts: Array = card.get("options", [])
		var w: float = (UiKit.span(32.0) - float(maxi(0, opts.size() - 1)) * 12.0) / float(maxi(1, opts.size()))
		for i in opts.size():
			var o: Dictionary = opts[i]
			ui.add_child(UiKit.button(String(o["label"]),
				Vector2(24 + float(i) * (w + 12.0), action_y()), Vector2(w, 46), func():
					flash = season.answer_dilemma(i)
					Session.autosave()
					_rebuild()))
		return
	if season.season_complete():
		ui.add_child(UiKit.button("End the season", Vector2(24, action_y()),
			Vector2(424, 46), func():
				var was := season.position()
				var tier := season.tier_name()
				var tier_before := season.tier_name()
				season.roll_over()
				Session.autosave()
				## THE PALETTE FLASH, and only here. Two frames of white on a
				## promotion — the cheapest, most 8-bit trick there is, and the
				## whole reason it works is that it is RARE. A flash the player
				## sees twice an hour is an event; one he sees twice a minute is
				## a fault in the screen. A season that ended where it started
				## gets the ordinary confirm and nothing else.
				if season.tier_name() != tier_before:
					Juice.fanfare()
				## The split goes FIRST when there is one, because a squad walking
				## out is not a footnote to where you finished.
				var broke := _split_word()
				flash = broke if broke != "" else "%s, finished %s. Now in the %s.%s%s" % [
					tier, UiKit.ordinal(was), season.tier_name(),
					_winter_word(), _upkeep_word()]
				_rebuild()))
		return
	## THE TWO DROPDOWNS, next to the button that uses them. Pete asked for the
	## formation to be selectable "via drop down"; on a screen this size a cycle
	## button is the same thing with one fewer tap and no list to mis-hit, and
	## it shows what is selected without being opened.
	## AND IT IS A FORMATION HERE TOO. Pete renamed the playbook's column and the
	## word is the word: a game that calls the same thing a shape on one screen
	## and a formation on the next is asking the player to hold two names for it.
	## The clip drops to 10 so the label is no longer than "Shape:" plus 14 was —
	## `test_layout.gd` measures the outcome either way.
	ui.add_child(UiKit.button("Formation: %s" % UiKit.clip(
			season.board.formation_name(season.formation_id), 10),
		Vector2(24, action_y() - 54), Vector2(204, 40), func():
			var ids: Array = []
			for c in season.board.formation_choices():
				ids.append(int(c["id"]))
			var at := ids.find(season.formation_id)
			season.formation_id = ids[(at + 1) % ids.size()]
			## A play tied to the shape you just left stops being called, so it
			## is dropped here rather than silently not happening in the fight.
			if season.called_play() == null:
				season.play_index = -1
			Session.autosave()
			_rebuild()))
	ui.add_child(UiKit.button("Play: %s" % _play_label(),
		Vector2(244, action_y() - 54), Vector2(204, 40), func():
			## Only the plays that can actually be called from the shape you are
			## in. An unrunnable play offered in the list is a lie.
			var offered: Array = season.board.plays_for(season.formation_id)
			var idx: Array = [-1]
			for o in offered:
				idx.append(int(o["index"]))
			var at := idx.find(season.play_index)
			season.play_index = idx[(at + 1) % idx.size()] if at != -1 else -1
			Session.autosave()
			_rebuild()))
	ui.add_child(UiKit.button("Fight it", Vector2(24, action_y()), Vector2(204, 46), _fight))
	ui.add_child(UiKit.button("Sim it", Vector2(244, action_y()), Vector2(204, 46), func():
		season.skip_event()
		Session.autosave()
		flash = "Event simulated."
		_rebuild()))


## What the play button says. "None" is a real choice and reads as one.
func _play_label() -> String:
	if season.called_play() == null:
		return "none"
	return UiKit.clip(String(season.board.plays[season.play_index]["name"]), 12)


func _fight_cup() -> void:
	var sim := season.begin_cup_bout()
	if sim == null:
		flash = "Nothing to fight."
		_rebuild()
		return
	Session.autosave()
	Session.bout = sim
	Session.bout_is_cup = true
	## Captured BEFORE the fight, because posting the result resolves the tie and
	## the mood would be gone by the time the report is drawn.
	Session.bout_mood = season.mood()
	UiKit.go("res://scenes/Melee.tscn")


func _fight() -> void:
	var sim := season.begin_bout()
	if sim == null:
		season.skip_event()
		Session.autosave()
		flash = "Bye this event."
		_rebuild()
		return
	## Save BEFORE handing over. The bout is a scene change and a few minutes of
	## play; a save taken only on the way back would lose the whole event if the
	## app went away mid-fight.
	Session.autosave()
	Session.bout = sim
	Session.bout_is_cup = false
	Session.bout_mood = UiKit.Mood.NORMAL
	UiKit.go("res://scenes/Melee.tscn")


# --------------------------------------------------------------- squad moves
## ONE layout function, read by both the drawing and the hit boxes.
##
## They were computed separately and started 22 pixels apart, which put every
## invisible button over the gap above its own row: tapping a name selected the
## man above him, and the last row could not be tapped at all. Nothing headless
## can see that, and on a screen of drawn text with flat buttons on top it is
## invisible in a screenshot too — the only tell was that the two functions each
## did their own arithmetic. **If two pieces of code have to agree about a
## position, one of them should be asking the other.**
const SQUAD_ROW := 30.0
const RESERVE_X := 490.0

func _squad_rows() -> Array:
	var out: Array = []
	var five := season.club.starting_five()
	var y := CONTENT_Y + 26.0
	var bench_started := false
	for f in season.club.active_eight():
		var kind := "on the line" if five.has(f) else "bench"
		## Every group needs the gap its own header is written into. The bench had
		## none, so its label was drawn 26 pixels up into the last man on the line.
		if kind == "bench" and not bench_started:
			bench_started = true
			y += 28.0
		out.append({ "card": f, "y": y, "kind": kind, "x": 24.0 })
		y += SQUAD_ROW
	## The reserve stands in its own column rather than below, which is the
	## whole reason a landscape screen is worth having: the eight and the five
	## you might promote are visible at the same time, so the swap is a
	## comparison instead of a memory test.
	var ry := CONTENT_Y + 26.0
	for f in season.club.reserves():
		out.append({ "card": f, "y": ry, "kind": "reserve", "x": RESERVE_X })
		ry += SQUAD_ROW
	return out


func _squad_controls() -> void:
	## THE ROSTER, which is the same men laid out like the sport rather than
	## like a list — and the only place a fighter's own record can be read.
	## IT WAS SITTING ON THE HONOURS TAB. At y=70 with the tab strip at 72 this
	## button covered the right 112 pixels of the fifth tab, so on this tab the
	## label read "HONOURS" and the tap opened the roster. Shipped, invisible,
	## and found by `test_layout.gd` the first time it drove every tab instead of
	## only the default one.
	ui.add_child(UiKit.button("Roster", Vector2(736, action_y()), Vector2(200, 46), func():
		Session.autosave()
		UiKit.go("res://scenes/Roster.tscn"), "roster"))
	for row in _squad_rows():
		ui.add_child(_man_button(row["card"], float(row["y"]), float(row["x"])))
	if picked != null:
		## THE FORK, AS ONE BUTTON. Extend while the deal runs, re-sign once it has
		## not — and it is deliberately one control rather than two, because two
		## buttons with two prices means the player picks the cheaper one and
		## there is no decision left in it. The button shows the price it is
		## actually charging, and which of the two it is.
		var out_of_deal: bool = picked.years <= 0
		var deal_cost: int = season.resign_cost(picked) if out_of_deal \
			else season.extend_cost(picked)
		ui.add_child(UiKit.button(
			"%s  ·  %s/wk" % ["Re-sign" if out_of_deal else "Extend",
				ClubOffice.money(deal_cost)],
			Vector2(464, action_y()), Vector2(240, 46), func():
				var err := season.resign(picked) if out_of_deal else season.extend(picked)
				if err == "":
					flash = "%s: %s a week for %d years." % [picked.display_name,
						ClubOffice.money(ClubOffice.billed(picked)), picked.years]
					Session.autosave()
				else:
					flash = err
				_rebuild()))
		ui.add_child(UiKit.button("Cut " + UiKit.clip(picked.display_name, 14),
			Vector2(24, action_y()), Vector2(204, 46), func():
				var err := season.release(picked)
				flash = UiKit.said(err) if err != "" else "%s released." % picked.display_name
				if err == "":
					picked = null
					season.sync_power()
					Session.autosave()
				_rebuild()))
		## THE PROSPECT. One man a year, cashed at the winter, and the button
		## refuses rather than going quiet when the ground is not built for it —
		## a control that does nothing and says nothing is how a player concludes
		## the feature is broken.
		var ground := season.office.level(ClubOffice.Facility.TRAINING)
		ui.add_child(UiKit.button(
			"Clear" if season.prospect == picked else "Prospect",
			Vector2(244, action_y()), Vector2(204, 46), func():
				if season.prospect == picked:
					season.prospect = null
					flash = "%s is no longer your prospect." % picked.display_name
				elif ground < Career.PROSPECT_GROUND:
					flash = "A prospect needs a Training ground at %d. Yours is %d." % [
						Career.PROSPECT_GROUND, ground]
				else:
					season.prospect = picked
					flash = "%s is your prospect — +%d ceiling at the winter." % [
						picked.display_name, Career.PROSPECT_GAIN]
					Session.autosave()
				_rebuild()))


## An invisible hit box over each drawn row. Drawing the row myself and putting a
## flat button on top of it keeps the list looking like a list — a screen of
## themed Buttons reads as a form, and this is a team sheet.
func _man_button(f: FighterCard, y: float, x: float) -> Button:
	var b := UiKit.button("", Vector2(x, y - 20), Vector2(446, SQUAD_ROW - 2),
		_tap.bind(f))
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	return b


func _tap(f: FighterCard) -> void:
	if picked == null:
		picked = f
		flash = "Pick who %s trades places with." % f.display_name
		_rebuild()
		return
	if picked == f:
		picked = null
		flash = ""
		_rebuild()
		return
	## TWO KINDS OF SWAP, AND THE SCREEN NO LONGER REFUSES THE SECOND ONE.
	##
	## One on the bus and one in the clubhouse is a squad change: `swap_squad`.
	## TWO ON THE BUS is a depth-chart change — which men start and which sit on
	## the bench — and this used to answer it with *"Pick one from the eight and
	## one from the reserve"*, i.e. the screen told the player that the thing he
	## was trying to do was a mistake. It was not. It was the one thing the game
	## could not do at all: `starting_five()` reads roster order and nothing
	## could reorder the roster, so a man who ended up on the bench stayed there
	## whatever the player thought of him.
	##
	## Two in the RESERVE is still a no-op rather than a refusal — the reserve
	## has no order that means anything, so there is nothing to say and nothing
	## to do.
	## WHO WAS ON THE LINE BEFORE, so the message can say what actually changed.
	var five_before: Array = season.club.starting_five()
	var err := ""
	if picked.active and not f.active:
		err = season.club.swap_squad(picked, f)
	elif f.active and not picked.active:
		err = season.club.swap_squad(f, picked)
	elif picked.active and f.active:
		err = season.club.swap_order(picked, f)
	else:
		err = "Two in the reserve: bring one up to the eight first."
	if err == "":
		## REPORT WHAT CHANGED, NOT WHAT WAS TAPPED.
		##
		## The five is not a list the player edits — it is CHOSEN, by walking the
		## depth chart and taking the first fit man who covers each slot. So
		## swapping two entries can move somebody the player never touched: a
		## probe on the starting club swapped Calder for Quillan and promoted
		## Egan as well, because a Center arriving at the top of the chart
		## displaces the man who was covering that slot out of position.
		##
		## That is the model working, and a message saying "Calder and Quillan
		## swapped" while three names moved is the screen lying about it. So the
		## line is compared before and after and the message names the men who
		## actually came on and came off.
		var five_after: Array = season.club.starting_five()
		var came_on: Array[String] = []
		var came_off: Array[String] = []
		for m in five_after:
			if not five_before.has(m):
				came_on.append(String(m.display_name))
		for m in five_before:
			if not five_after.has(m):
				came_off.append(String(m.display_name))
		if came_on.is_empty():
			flash = "%s and %s swapped. The five is unchanged." % [
				picked.display_name, f.display_name]
		else:
			flash = "On: %s.  Off: %s." % [", ".join(came_on), ", ".join(came_off)]
		season.sync_power()
		Session.autosave()
	else:
		flash = err
	picked = null
	_rebuild()


# ---------------------------------------------------------------------- draw
func _draw() -> void:
	## THE OCCASION IS SET BEFORE ANYTHING IS DRAWN, and here rather than in
	## `_rebuild` — the palette has to be right for the whole frame, and a rebuild
	## does not happen on every frame. One line, and the entire shell changes
	## clothes: tabs, table, team sheet, market, clubhouse.
	var m: int = _forced if _forced >= 0 else season.mood()
	UiKit.set_mood(m)
	## THE SAME VALUE DRESSES THE ROOM AND SCORES IT. One read, two systems, and
	## no second piece of state that can disagree with the first about what
	## occasion this is — which is the whole reason the music was worth wiring
	## the same afternoon as the palette rather than later.
	Audio.for_mood(m)
	UiKit.ground(self)
	_header()
	## THE RULE UNDER THE HEADER, and it is the cheapest piece of flair in the
	## game — one CC0 strip, tiled from the middle so the gem lands centred, in
	## place of the 2px line that was there. It reads on every tab and costs one
	## call.
	UiKit.rule(self, UiKit.RULE_GEM, Vector2(0, 58), UiKit.screen().x, UiKit.FRAME)
	_banner()
	## The selected tab, marked under the buttons rather than on them, because a
	if shop_open:
		## AND NOT THE TAB'S UNDERLINE EITHER. `_rebuild` stopped building the tab
		## buttons under the modal; this used to draw the gold bar that marks
		## which one is current, which left a three-pixel underline floating over
		## an empty row — a mark pointing at a control that is not there.
		_draw_shop()
		return
	## Button's own styling is the one thing here that is not mine to draw.
	draw_rect(Rect2(24 + float(tab) * (TAB_W + 6.0), TAB_Y + TAB_H, TAB_W, 3), UiKit.YOU)
	if flash != "":
		UiKit.text(self, font, UiKit.clip(flash, 58), Vector2(24, FLASH_Y), 15, UiKit.YOU)
	match tab:
		Tab.CLUB: _draw_club()
		Tab.SQUAD: _draw_squad()
		Tab.MARKET: _draw_market()
		Tab.OFFICE: _draw_office()
		Tab.HONOURS: _draw_honours()


func _header() -> void:
	var w: Dictionary = season.world.clubs[season.world.player_club]
	draw_rect(Rect2(0, 0, UiKit.screen().x, 62), UiKit.PANEL)
	UiKit.badge(self, Vector2(38, 31), 20, season.club.kit,
		season.club.icon_colour, int(season.club.icon))
	UiKit.text(self, font, UiKit.clip(String(w["name"]), 28), Vector2(68, 28), 20, UiKit.INK)
	UiKit.text(self, font, "%s  ·  Season %d  ·  rating %d" % [
		season.tier_name(), season.world.season, int(w["power"])],
		Vector2(68, 50), 14, UiKit.DIM)
	## The credit balance rides in the header on every tab, the way Retro Bowl
	## keeps it in the corner. A currency you have to go and look up is one you
	## forget you have.
	## NAMED, BECAUSE SOMETHING ELSE HAS TO MEASURE THEM. `test_ink.gd` checks the
	## purse against this box at every magnitude a career can reach, and a check
	## that re-types the box's numbers is a second copy that will drift from the
	## first. The box was 118 wide and `4096 CC` needed 98 of the 94 it left —
	## four digits, which is a bank a player reaches in a couple of seasons.
	UiKit.panel(self, purse_box())
	UiKit.purse(self, font, season.office.credits, purse_at(), PURSE_SIZE, UiKit.YOU)
	UiKit.text(self, font, season.office.morale_word(), Vector2(UiKit.right_edge(194.0), 38), 16,
		UiKit.UP if season.office.morale >= 0.6 else
		(UiKit.DOWN if season.office.morale < 0.35 else UiKit.DIM))


# ------------------------------------------------------------------ CLUB tab
## THE TITLE CARD. Nothing on an ordinary Saturday; a band across the top of the
## screen when there is a cup tie in front of you, saying what the occasion is
## and who is in front of you.
##
## It is deliberately a BAND rather than a full-screen splash. A splash is a
## thing you dismiss and then never see again — this is the header of every
## screen for as long as the tie is live, so the player is reminded on the team
## sheet and in the clubhouse that the next fight is not a league fixture.
## A DEV OVERRIDE, and it is on the screen rather than in the tool because the
## tool cannot reach a Worlds final without simulating a dozen seasons. -1 means
## "ask the season", which is every case except a screenshot.
var _forced: int = -1


func set_script_mood(m: int) -> void:
	_forced = m
	queue_redraw()


func _banner() -> void:
	if UiKit.mood == UiKit.Mood.NORMAL:
		return
	## A GOLD FRAME, TOP AND BOTTOM, with the occasion written along the bottom
	## one in the ground colour — a ribbon, the way an 8-bit game labels a stage.
	##
	## It went at the TOP first, right-aligned, and was invisible: the header
	## already owns that strip with the balance, the morale word and the Menu
	## button, and `_header()` draws after this and simply painted over it. The
	## bottom strip below the action buttons is the only band on this screen that
	## belongs to nobody — which is why the ribbon lives there and why the top
	## band is a rule rather than a label.
	draw_rect(Rect2(0, 0, UiKit.screen().x, 6), UiKit.YOU)
	## SIXTEEN, NOT TWENTY. At twenty the ribbon started at y=520 and the action
	## row ends at 522 with its drop — two pixels of gold under every button on
	## a cup night. Nobody would have called it a bug and everybody would have
	## seen it.
	draw_rect(Rect2(0, UiKit.screen().y - 16, UiKit.screen().x, 16), UiKit.YOU)
	var line := UiKit.mood_name()
	var occ := season.occasion()
	if occ != "":
		line += "  ·  " + occ
	var w := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	UiKit.text(self, font, line, Vector2((UiKit.screen().x - w) * 0.5, UiKit.screen().y - 3.0), 13, UiKit.BG)


func _draw_club() -> void:
	## THE CARD TAKES THE WHOLE SCREEN when there is one, rather than sitting in
	## a corner of the fixture page. It is two hundred words of somebody's week
	## and three answers with real prices on them; squeezing it into a panel
	## beside the league table would say it is trivia, and then the player would
	## treat it as trivia.
	##
	## IT ASKS THE SEASON WHICH SCREEN THIS IS, rather than asking whether a card
	## exists. Those are not the same question and on 14 Sep 2026 they gave
	## different answers: the buttons were moved onto `blocked_by()` in section
	## 22 and the DRAWING was left reading `dilemma.is_empty()`, so a season that
	## opened with a bid AND a card on the table printed the card, its three
	## answers and their prices — over the tournament bid's two buttons. The
	## first shot of the priced options caught it, which is the whole reason to
	## take one: *a branch has two arms and a screenshot has one frame*, and this
	## frame was the arm nobody had looked at.
	if season.blocked_by() == "dilemma":
		_draw_dilemma()
		return
	_fixture()
	_last_event()
	_table()


## Which card the typer is part-way through. Without it the redraw restarted the
## typing every frame and the body never got past its first character.
var _typing_key: String = ""


## THE ONE THING ON THIS NODE THAT MOVES, AND FOR TWO YEARS IT DID NOT.
##
## `_draw()` on a CanvasItem runs when something asks it to, and the only two
## things that ever asked on this screen were `_rebuild()` and the dev mood
## override. So the dilemma's typewriter — the type_start, the per-frame
## advance, the blinking cursor, `type_skip` for a player who reads faster than
## the machine prints, and a comment above all of it explaining how it avoids
## restarting every frame — ran exactly once, at zero characters, and then the
## card sat there with an empty body until it was answered.
##
## Everything worked except the part that asks for the next frame. `Juice` was
## ticking: a probe read 115 of the card's 118 characters at frame 420 while the
## shot of that same frame showed a blank panel. **An animation on a canvas that
## only redraws on rebuild is a still frame** — and it is invisible to every
## check in the suite, because `test_ink.gd` calls `queue_redraw()` itself
## before it looks, which is the one thing the screen could not do for itself.
##
## Gated on the typer rather than on the screen, so a card that has finished
## printing goes still again and the rest of the game keeps costing nothing.
func _process(_delta: float) -> void:
	if season == null or tab != Tab.CLUB:
		return
	if season.blocked_by() != "dilemma":
		return
	var card := season.dilemma_card()
	if card.is_empty():
		return
	if not Juice.type_done("dilemma:" + String(card["title"])):
		queue_redraw()


func _draw_dilemma() -> void:
	var card := season.dilemma_card()
	if card.is_empty():
		return
	var y := CONTENT_Y + 10.0
	UiKit.panel(self, Rect2(24, y, UiKit.span(), 300))
	UiKit.text(self, font, String(card["title"]).to_upper(), Vector2(48, y + 36), 20, UiKit.YOU)
	## The body wraps by hand rather than by a Label, because everything else on
	## this screen is drawn and a single themed Label in the middle of it reads
	## like a different program.
	## IT TYPES ITSELF IN, one character every second frame.
	##
	## This is the most era-correct thing on the whole juice list and it costs
	## nothing — but it is allowed HERE and nowhere else. A dilemma is the one
	## place in this game the player is reading a voice rather than a number,
	## and a roster or a league table that typed itself in would be a table you
	## cannot read. The rule is written down in JUICE.md as *never on numbers or
	## tables*, and this is the only screen that qualifies.
	##
	## Keyed on the card's own title, so a new dilemma types again and a redraw
	## of the same one carries on from where it was rather than restarting every
	## frame — which is what it did the first time I wired it, and what it
	## looked like was a stutter.
	var key := "dilemma:" + String(card["title"])
	if _typing_key != key:
		_typing_key = key
		Juice.type_start(key, String(card["body"]))
	var body := Juice.typed(key)
	var lines := _wrap(body, 74)
	var line_y := y + 78.0
	for line in lines:
		UiKit.text(self, font, line, Vector2(48, line_y), 16, UiKit.INK)
		line_y += 26.0
	## The cursor, blinking, at the end of what has arrived. Nothing in a retro
	## game is ever completely still, and a card that is still printing needs to
	## look like it is still printing rather than like it has stopped short.
	if not Juice.type_done(key) and not lines.is_empty():
		var last := String(lines[lines.size() - 1])
		var w := font.get_string_size(last, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
		if Juice.blink(18):
			UiKit.text(self, font, "_", Vector2(48.0 + w, line_y - 26.0), 16, UiKit.YOU)

	## Each answer's PRICE under its button, in the club's own words — and, since
	## 14 Sep 2026, in figures as well.
	##
	## THE COMMENT ABOVE THIS USED TO BE A CLAIM RATHER THAN A DESCRIPTION. It
	## said "each answer's PRICE" and the code drew the `blurb`, which is prose:
	## "All thirteen, done properly" implies a cost the way prose implies things,
	## and a player deciding between three cards was pricing them by tone.
	##
	## Pete sent Retro Bowl's press interview over, where every answer carries an
	## EFFECT box under it showing the face it will produce. Same idea, same
	## reason: *a dilemma whose costs are hidden until after the tap is a coin
	## flip with extra steps* — and that sentence was already sitting here.
	##
	## The sentence stays and the figures go under it. `Dilemma.costs()` decides
	## both what is shown and which way each figure moves, off one read of one
	## dictionary, so the words and the colours can never disagree.
	var opts: Array = card.get("options", [])
	var w: float = (UiKit.span(32.0) - float(maxi(0, opts.size() - 1)) * 12.0) / float(maxi(1, opts.size()))
	## A RULE BETWEEN THE VOICE AND THE PRICES. The body is somebody talking and
	## the block underneath is three columns of figures, and with nothing between
	## them a short card left a hundred and fifty pixels of nothing in the middle
	## of the panel and the answers read as though they had come loose from it.
	## The line says the bottom of this panel is a different kind of thing, which
	## is true — it is the only structure on the card that encodes something.
	UiKit.rule(self, UiKit.RULE_GEM, Vector2(48.0, action_y() - 104.0), UiKit.span(48.0), UiKit.FRAME)
	for i in opts.size():
		var o: Dictionary = opts[i]
		var x := 24.0 + float(i) * (w + 12.0)
		var by := action_y() - 66.0
		## Inset to the same ten pixels a button pads its own label by, so a
		## column of prose sits over its button rather than over the gap, and the
		## leftmost one stops touching the edge of the panel.
		for line in _wrap(String(o["blurb"]), int(w / 7.4)):
			UiKit.text(self, font, line, Vector2(x + 10.0, by), 13, UiKit.DIM)
			by += 18.0
		var bill: Array[Dictionary] = Dilemma.costs(o)
		## AN OPTION THAT ASKS NOTHING SAYS SO. A blank where the other two cards
		## have figures reads as a card the game forgot to price, which is the
		## opposite of what a free choice should feel like.
		if bill.is_empty():
			UiKit.text(self, font, "costs nothing", Vector2(x + 10.0, by + 2.0), 13, UiKit.DIM)
			continue
		## EACH FIGURE IN ITS OWN COLOUR, laid out by measuring what has already
		## been drawn rather than by joining a string — a single colour for the
		## row would have to pick one, and the answers worth thinking about are
		## the mixed ones.
		var fx := x + 10.0
		for j in bill.size():
			var e: Dictionary = bill[j]
			if j > 0:
				UiKit.text(self, font, " · ", Vector2(fx, by + 2.0), 13, UiKit.DIM)
				fx += font.get_string_size(" · ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
			var t := String(e["text"])
			UiKit.text(self, font, t, Vector2(fx, by + 2.0), 13,
				UiKit.UP if int(e["dir"]) > 0 else UiKit.DOWN)
			fx += font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x


## Greedy wrap at a word boundary. Good enough for a fixed-width panel and it
## keeps the drawing self-contained.
func _wrap(text: String, cols: int) -> Array[String]:
	var out: Array[String] = []
	var line := ""
	for word in text.split(" "):
		if line == "":
			line = word
		elif line.length() + 1 + word.length() <= cols:
			line += " " + word
		else:
			out.append(line)
			line = word
	if line != "":
		out.append(line)
	return out


## WHAT THE FIXTURE PANEL IS CALLED. One function, because the notch and the
## body are drawn in two places and a heading computed twice is a heading that
## eventually says two different things.
func _fixture_title() -> String:
	if season.bid_open():
		return "TOURNAMENT BID"
	var cup := season.pending_cup()
	if cup != null:
		return "%s  ·  %s" % [cup.cup_name.to_upper(), cup.round_name().to_upper()]
	if season.season_complete():
		return "SEASON COMPLETE"
	return "EVENT %d OF %d" % [season.world.event + 1,
		season.world.events_this_season()]


func _fixture() -> void:
	var y := CONTENT_Y + 20.0
	var r := Rect2(24, y, fixture_w(), 104)
	## THE HEADING GOES IN THE FRAME.
	##
	## It used to be the first line INSIDE the panel, which cost a line of the
	## panel's height to say something the panel already was. Cut into the top
	## rule it is furniture rather than content, the body starts higher, and a
	## rectangle becomes a labelled window — which is the single change that
	## stops an 8-bit menu reading like a web layout with a pixel font on it.
	UiKit.window(self, r, _fixture_title(), font)
	if season.bid_open():
		UiKit.text(self, font, "Three dates on offer", Vector2(44, y + 52), 22, UiKit.INK)
		## WRAPPED TO THE CARD. This ran 53 pixels past the fixture panel's right
		## edge — it is in the very first screenshot in `shots/`, clipped
		## mid-sentence, and nobody read it as a fault because a sentence that
		## stops at a panel edge looks like a sentence that stops.
		var by := y + 80.0
		for line in UiKit.wrap(font, "Pick a week to hold your own, or pass on the year.",
				fixture_w() - 40.0, 14):
			UiKit.text(self, font, String(line), Vector2(44, by), 14, UiKit.DIM)
			by += 18.0
		return
	var cup := season.pending_cup()
	if cup != null:
		var opp := season.cup_opponent()
		var o: Dictionary = season.world.clubs[opp]
		UiKit.text(self, font, UiKit.clip(String(o["name"]), 26),
			Vector2(44, y + 52), 22, UiKit.INK)
		var gap := int(season.world.clubs[season.world.player_club]["power"]) - int(o["power"])
		UiKit.text(self, font, "rating %d  ·  win or you are out" % int(o["power"]),
			Vector2(44, y + 80), 14, UiKit.UP if gap > 0 else UiKit.DOWN)
		return
	if season.season_complete():
		UiKit.text(self, font, "Finished %s of %d in the %s." % [
			UiKit.ordinal(season.position()), season.table().size(), season.tier_name()],
			Vector2(44, y + 52), 15, UiKit.DIM)
		UiKit.text(self, font, "The cups and the summer are next.",
			Vector2(44, y + 80), 14, UiKit.DIM)
		return
	var opp := season.opponent_id()
	if opp == -1:
		UiKit.text(self, font, "Bye", Vector2(44, y + 52), 22, UiKit.INK)
		return
	var o: Dictionary = season.world.clubs[opp]
	UiKit.text(self, font, UiKit.clip(String(o["name"]), 26), Vector2(44, y + 52), 22, UiKit.INK)
	var gap := int(season.world.clubs[season.world.player_club]["power"]) - int(o["power"])
	var word := "even" if absi(gap) <= 2 else ("favourites" if gap > 0 else "underdogs")
	UiKit.text(self, font, "rating %d  ·  you are %s by %d" % [int(o["power"]), word, absi(gap)],
		Vector2(44, y + 80), 14,
		UiKit.DIM if absi(gap) <= 2 else (UiKit.UP if gap > 0 else UiKit.DOWN))
	## HOW WELL THEY THINK, which the rating does not tell you.
	##
	## A division's AI tier decides whether the other corner improvises once its
	## plan runs out, hunts a wobbling man, makes the two-on-one or bails a
	## losing hold — Seasoned beats Green 63% on identical rosters. Your own
	## side's tiers are spelled out on the Clubhouse tab and the opponent's were
	## never shown anywhere, so the one number that explains why the same rating
	## feels harder two divisions up was invisible.
	UiKit.right(self, font, String(Tuning.AI_SKILL[season.ai_tier()]["name"]).to_upper(),
		Vector2(432, y + 28), 12, UiKit.YOU, 200)


func _last_event() -> void:
	var e := season.last_event()
	if e.is_empty():
		return
	var y := CONTENT_Y + 152.0
	if bool(e.get("bye", false)):
		UiKit.text(self, font, "Last event: bye", Vector2(28, y), 14, UiKit.DIM)
		return
	var rf := int(e["rf"])
	var ra := int(e["ra"])
	var word := "beat" if rf > ra else ("lost to" if rf < ra else "drew with")
	var col := UiKit.UP if rf > ra else (UiKit.DOWN if rf < ra else UiKit.DIM)
	UiKit.text(self, font, "Last: %s %s %d-%d (%+d)%s" % [word,
		UiKit.clip(String(season.world.clubs[int(e["opponent"])]["name"]), 22), rf, ra,
		int(e["margin"]), "" if bool(e["fought"]) else "  ·  simmed"],
		Vector2(28, y), 14, col)


func _table() -> void:
	var rows := season.table()
	var t := season.world.player_tier()
	var up := int(League.TIERS[t]["up"])
	var down := int(League.TIERS[t]["down"])
	var top_flight: bool = t == League.TIERS.size() - 1
	## THE STAT BLOCK HANGS OFF THE RIGHT EDGE, not off a fixed offset from the
	## table's left. It is one fixed-width string, so its width is the same every
	## row and on every screen — but where it BELONGS moves with the canvas, and
	## pinned at table_x() + 240 it left the numbers stranded mid-row on a handset
	## with the highlighted row running on past them.
	var stat_w := font.get_string_size("P  W  D  L   RD   MG  PTS",
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
	var stat_x := UiKit.right_edge(24.0) - stat_w
	UiKit.text(self, font, "P  W  D  L   RD   MG  PTS",
		Vector2(stat_x, TABLE_Y - 6), 12, UiKit.DIM)
	draw_rect(Rect2(table_x(), TABLE_Y, UiKit.screen().x - table_x() - 24, 1), UiKit.EDGE)
	for i in rows.size():
		var r: Dictionary = rows[i]
		var cid := int(r["club"])
		var y := TABLE_Y + 22.0 + float(i) * ROW_H
		var mine: bool = cid == season.world.player_club
		if mine:
			draw_rect(Rect2(table_x(), y - 15, UiKit.screen().x - table_x() - 24, ROW_H - 2), UiKit.PANEL)
		var edge := Color.TRANSPARENT
		if i < up:
			## The top flight promotes nobody — those two places are Worlds
			## berths, and colouring them green would promise a division above
			## the National that does not exist.
			edge = UiKit.YOU if top_flight else UiKit.UP
		elif down > 0 and i >= rows.size() - down:
			edge = UiKit.DOWN
		if edge != Color.TRANSPARENT:
			## THE WHOLE ROW, FAINTLY, AND THEN THE STRIPE.
			##
			## A four-pixel stripe marks a row; it does not group one. Sixteen
			## clubs in the National read as a ladder you count down, when what
			## the player is actually asking is which of three things his club is
			## in the middle of — going up, going down, or neither. Retro Bowl
			## bands its standings for the same reason.
			##
			## It has to cost NO HEIGHT: sixteen rows at 22 already end at 514 on
			## a 540 screen, so captions or gaps between the bands would push the
			## bottom club off the bottom of the division. A wash behind the rows
			## groups them for nothing, and the stripe stays for the exact edge.
			##
			## Drawn BEFORE the player's own highlight would be wrong — his row is
			## the one row that must read as his first and as a promotion place
			## second — so the wash goes down first and `mine` paints over it.
			if not mine:
				draw_rect(Rect2(table_x(), y - 15, UiKit.screen().x - table_x() - 24,
					ROW_H - 2), Color(edge.r, edge.g, edge.b, 0.10))
			draw_rect(Rect2(table_x(), y - 15, 4, ROW_H - 2), edge)
		var col := UiKit.YOU if mine else UiKit.INK
		UiKit.text(self, font, "%2d" % (i + 1), Vector2(table_x() + 12, y), 13, UiKit.DIM)
		UiKit.text(self, font, UiKit.clip(String(season.world.clubs[cid]["name"]), 24),
			Vector2(table_x() + 38, y), 13, col)
		UiKit.text(self, font, "%2d %2d %2d %2d  %+3d  %+3d  %2d" % [
			int(r["played"]), int(r["won"]), int(r["drawn"]), int(r["lost"]),
			League.round_diff(r), League.margin_diff(r), int(r["points"])],
			Vector2(stat_x, y), 13, col)


# ----------------------------------------------------------------- SQUAD tab
func _draw_squad() -> void:
	UiKit.text(self, font, "THE EIGHT WHO TRAVEL", Vector2(24, CONTENT_Y), 13, UiKit.DIM)
	UiKit.text(self, font, "RESERVE — never at an event", Vector2(RESERVE_X, CONTENT_Y), 13, UiKit.DIM)
	## The cap, where the decision is: every man on this screen costs against it.
	var bill := ClubOffice.wage_bill(season.club)
	var cap := season.office.cap()
	UiKit.right(self, font, "%s of %s" % [ClubOffice.money(bill), ClubOffice.money(cap)],
		Vector2(UiKit.right_edge(), CONTENT_Y), 13, UiKit.DOWN if bill > cap else UiKit.DIM, 300)
	var rows := _squad_rows()
	var last_kind := "on the line"
	for row in rows:
		var kind := String(row["kind"])
		var y := float(row["y"])
		var x := float(row["x"])
		## The line/bench split is otherwise carried only by a background shade,
		## which is not a label. Five men fight and three wait, and the screen
		## should say which is which.
		if kind == "bench" and last_kind == "on the line":
			UiKit.text(self, font, "BENCH — two may come on each corner",
				Vector2(24, y - 24), 12, UiKit.DIM)
		_man_row(row["card"], y, kind, x)
		last_kind = kind
	if season.club.reserves().is_empty():
		UiKit.text(self, font, "Nobody.", Vector2(RESERVE_X + 16, CONTENT_Y + 26), 15, UiKit.DIM)


## THE COLUMN STOPS, IN ONE PLACE.
##
## They used to be nine magic numbers scattered through `_man_row`, and two
## pairs of them overlapped: the wage, right-aligned into a 90-wide box, ran
## back through the AGE column, and the rating, right-aligned into a 60-wide
## box, ran back through the CONTRACT YEARS. On screen that read as
## `$3 2` with a rating printed through the middle of it.
##
## Nine fields in 446 pixels is the actual problem and no amount of nudging
## fixes it, so the name clip came down from 16 characters to 13 and every stop
## was re-planned against the widest string each field can produce. As a table
## it can be MEASURED — `test_layout.gd` walks these against the real font and
## fails if any two touch, which is the only way a row this tight stays honest.
##
## `to` is a right edge for right-aligned fields and a left edge for the rest.
## RE-CUT FOR THE REAL FACE, 14 Sep 2026. These stops were measured against
## `ThemeDB.fallback_font` and the game drew in it on sixteen screens; Buhurt
## Rail is 25 to 55 per cent wider at the same size, and the moment the face went
## in `position` ran 6px into `armour` and `age` ran 7px into `wage`.
##
## `test_layout.gd` said so, by name, on the first run — which is the entire
## reason `squad_columns()` hands back measured rects instead of the nine magic
## numbers this used to be. The check written for a bug that had already happened
## caught the same bug arriving from a completely different direction.
##
## Six pixels between every field and eight spare at the end. The name budget
## gave way from 130 to 100, because a clipped surname is a cosmetic loss and a
## wage printed through an age is a lie.
const SQUAD_W := 446.0
const COL_NUM := 8.0
const COL_NAME := 44.0
## The budget, not a character count. `COL_POS` minus a gap.
const COL_NAME_W := 100.0
const COL_POS := 150.0
const COL_ARMOR := 226.0
const COL_AGE := 272.0
const COL_WAGE_TO := 351.0
const COL_WAGE_BOX := 58.0
const COL_YEARS := 357.0
const COL_RATING_TO := 414.0
const COL_RATING_BOX := 40.0
const COL_POT_TO := 438.0
const COL_POT_BOX := 24.0


func _man_row(f: FighterCard, y: float, role: String, x: float) -> void:
	var w := SQUAD_W
	if picked == f:
		draw_rect(Rect2(x, y - 20, w, SQUAD_ROW - 2), UiKit.SELECT)
	elif role == "on the line":
		draw_rect(Rect2(x, y - 20, w, SQUAD_ROW - 2), UiKit.PANEL)
	var col := UiKit.INK if role != "reserve" else UiKit.DIM
	UiKit.text(self, font, "#%d" % f.number, Vector2(x + COL_NUM, y), 13, UiKit.DIM)
	## FITTED, NOT CLIPPED. The column is a pixel budget and the name is cut to
	## it — a thirteen-character count let a wide name run into the position.
	UiKit.text(self, font, UiKit.fit(font, f.display_name, 16, COL_NAME_W),
		Vector2(x + COL_NAME, y), 16, col)
	## An injury is the most important thing on a team sheet, so it goes where a
	## position would and takes the colour that means "deal with this".
	if f.injury > 0:
		UiKit.text(self, font, "OUT %d" % f.injury, Vector2(x + COL_POS, y), 13, UiKit.DOWN)
	else:
		UiKit.text(self, font, Tuning.pos_name(int(f.pos)), Vector2(x + COL_POS, y), 13, UiKit.DIM)
	## Kit is this game's salary cap and already costs him base, so it belongs on
	## the team sheet next to the rating it is quietly subtracting from.
	var armor_col := UiKit.UP if f.armor > 0.85 else (UiKit.DOWN if f.armor < 0.6 else UiKit.DIM)
	UiKit.text(self, font, "%3d%%" % int(round(f.armor * 100.0)),
		Vector2(x + COL_ARMOR, y), 13, armor_col)
	## AGE, and it is not decoration — see scripts/game/career.gd. Marked when he
	## is past the age at which not-being-put-down peaks and has fallen a way from
	## his own ceiling, because "he is 37 and eight off what he could have been"
	## is the entire argument for replacing him and the player should not have to
	## do that subtraction in his head.
	UiKit.text(self, font, "%d" % f.age, Vector2(x + COL_AGE, y), 13,
		UiKit.DOWN if f.fading() else UiKit.DIM)
	## WHAT HE IS ON, and how many summers it has left. The wage is the DEAL, not
	## the market rate — showing the market rate here is what the cap used to bill
	## and it is the thing the contract layer exists to separate. It turns red the
	## year the deal runs out, because that is the one piece of roster news that
	## cannot wait until the player happens to look.
	var deal_col := UiKit.DIM
	if f.years <= 0:
		deal_col = UiKit.DOWN
	elif f.years == 1:
		deal_col = UiKit.UP
	UiKit.right(self, font, ClubOffice.money(ClubOffice.billed(f)),
		Vector2(x + COL_WAGE_TO, y), 13, UiKit.DIM, COL_WAGE_BOX)
	UiKit.text(self, font, ("OUT" if f.years <= 0 else "%dy" % f.years),
		Vector2(x + COL_YEARS, y), 12, deal_col)
	## THE TWO NUMBERS, together. Retro Bowl's roster screen is read almost
	## entirely off rating-and-potential, and the pairing is why: neither one
	## answers "should I keep him" on its own. The ceiling is dimmed so the
	## rating still reads first at a glance.
	UiKit.right(self, font, "%d" % f.overall(), Vector2(x + COL_RATING_TO, y), 16, col,
		COL_RATING_BOX)
	UiKit.right(self, font, "%d" % f.potential, Vector2(x + COL_POT_TO, y), 12,
		UiKit.UP if f.headroom() >= 6 else UiKit.DIM, COL_POT_BOX)
	## The prospect wears a mark rather than a word — one man a year, and the
	## screen has no room for a sentence about him.
	if season.prospect == f:
		UiKit.text(self, font, "*", Vector2(x + 28, y), 16, UiKit.UP)


## THE SAME STOPS, AS RECTANGLES, FOR THE CHECK. A column table that only the
## drawing code knows about is a column table nothing can test, so this hands
## back what each field will actually occupy given the widest string it can
## produce and the font the screen is really using.
func squad_columns(f: Font, size_hint: int = 0) -> Array:
	var _unused := size_hint
	var out: Array = []
	var w := func(s: String, px: int) -> float:
		return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
	out.append({"name": "number", "rect": Rect2(COL_NUM, 0.0, float(w.call("#13", 13)), 18.0)})
	## The name can never exceed its budget, because `UiKit.fit` measures it.
	out.append({"name": "name", "rect": Rect2(COL_NAME, 0.0, COL_NAME_W, 18.0)})
	out.append({"name": "position", "rect": Rect2(COL_POS, 0.0, float(w.call("FLANKER", 13)), 18.0)})
	out.append({"name": "armour", "rect": Rect2(COL_ARMOR, 0.0, float(w.call("100%", 13)), 18.0)})
	out.append({"name": "age", "rect": Rect2(COL_AGE, 0.0, float(w.call("39", 13)), 18.0)})
	## Right-aligned: the widest string this field can produce, ending at its stop.
	var wage: float = w.call("$99.9k", 13)
	out.append({"name": "wage", "rect": Rect2(COL_WAGE_TO - wage, 0.0, wage, 18.0)})
	out.append({"name": "years", "rect": Rect2(COL_YEARS, 0.0, float(w.call("OUT", 12)), 18.0)})
	var rating: float = w.call("99", 16)
	out.append({"name": "rating", "rect": Rect2(COL_RATING_TO - rating, 0.0, rating, 18.0)})
	var pot: float = w.call("99", 12)
	out.append({"name": "ceiling", "rect": Rect2(COL_POT_TO - pot, 0.0, pot, 18.0)})
	return out


# ---------------------------------------------------------------- MARKET tab
## SIX MEN, A FEE AND A WAGE. The whole screen is one comparison the player has
## to make himself: is this man better than what I have, and can I carry him.
##
## The fee is drawn with its BAND NAME beside it, because that is the seam this
## market is built around — the fee is charged by band, so within a band a better
## fighter is free, and a player who never sees the band name will never notice
## that the 65 and the 61 cost the same six credits.
const MKT_ROW := 52.0
var market_pick: FighterCard = null


func _market_rows() -> Array:
	var out: Array = []
	var y := CONTENT_Y + 44.0
	for f in season.market():
		out.append({"card": f, "y": y})
		y += MKT_ROW
	return out


func _draw_market() -> void:
	UiKit.text(self, font, "FREE AGENTS — season %d" % season.world.season,
		Vector2(24, CONTENT_Y), 16, UiKit.YOU)
	var bill := ClubOffice.wage_bill(season.club)
	var cap := season.office.cap()
	UiKit.right(self, font, "wages %s of %s  ·  %d CC" % [
		ClubOffice.money(bill), ClubOffice.money(cap), season.office.credits],
		Vector2(UiKit.right_edge(), CONTENT_Y), 13,
		UiKit.DOWN if bill > cap else UiKit.DIM, 420.0)

	var rows := _market_rows()
	if rows.is_empty():
		UiKit.text(self, font, "Nobody left this summer. The list refreshes when the season rolls.",
			Vector2(24, CONTENT_Y + 60), 15, UiKit.DIM)
		return
	for row in rows:
		var f: FighterCard = row["card"]
		var y: float = row["y"]
		if market_pick == f:
			draw_rect(Rect2(20, y - 22, UiKit.span(20.0), MKT_ROW - 6), UiKit.SELECT)
		var fee := season.market_fee(f)
		var wage := season.market_wage(f)
		var room: bool = bill + wage <= cap
		var rich: bool = season.office.credits >= fee

		UiKit.text(self, font, UiKit.clip(f.display_name, 16), Vector2(30, y), 16, UiKit.INK)
		UiKit.text(self, font, Tuning.pos_name(int(f.pos)), Vector2(200, y), 13, UiKit.DIM)
		UiKit.text(self, font, "%d" % f.age, Vector2(300, y), 13, UiKit.DIM)
		## Rating and ceiling, the same pairing the team sheet uses — a market
		## that showed only the rating would hide the entire reason to sign a
		## 23-year-old.
		UiKit.text(self, font, "%d" % f.overall(), Vector2(348, y), 17, UiKit.INK)
		UiKit.text(self, font, "%d" % f.potential, Vector2(386, y), 12,
			UiKit.UP if f.headroom() >= 6 else UiKit.DIM)
		UiKit.text(self, font, Market.band_name(f.overall(), season.world.player_tier()),
			Vector2(430, y), 13, UiKit.DIM)
		UiKit.right(self, font, "%d CC" % fee, Vector2(640, y), 15,
			UiKit.INK if rich else UiKit.DOWN, 90)
		UiKit.right(self, font, "%s a week" % ClubOffice.money(wage), Vector2(UiKit.right_edge(160.0), y), 13,
			UiKit.DIM if room else UiKit.DOWN, 150)
		## And what he would do to the club, which is the number the player is
		## actually deciding on. Drawn last and on the right because it is the
		## conclusion, not the evidence.
		var delta := f.overall() - season.club.power()
		UiKit.right(self, font, "%+d" % delta, Vector2(UiKit.right_edge(70.0), y), 15,
			UiKit.UP if delta > 0 else UiKit.DIM, 70)


func _market_controls() -> void:
	## THE CARD GRID, in the action row rather than at y=70 — which is where the
	## tab strip is, and where this button had been sitting on top of HONOURS
	## since it was written. Same bug the Clubhouse tab's three links had.
	ui.add_child(UiKit.button("Free agents", Vector2(344, action_y()),
		Vector2(UiKit.right_edge() - 344.0, 46), func():
		Session.autosave()
		UiKit.go("res://scenes/Market.tscn")))

	for row in _market_rows():
		var f: FighterCard = row["card"]
		var b := UiKit.button("", Vector2(20, float(row["y"]) - 22), Vector2(UiKit.span(20.0), MKT_ROW - 6),
			func():
				market_pick = f
				flash = ""
				_rebuild())
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		ui.add_child(b)
	if market_pick != null:
		ui.add_child(UiKit.button("Sign %s  ·  %d CC" % [
			UiKit.clip(market_pick.display_name, 12), season.market_fee(market_pick)],
			Vector2(24, action_y()), Vector2(300, 46), func():
				var err := season.sign_from_market(market_pick)
				flash = UiKit.said(err) if err != "" else "%s signed." % market_pick.display_name
				if err == "":
					market_pick = null
					Session.autosave()
				_rebuild()))


# ---------------------------------------------------------------- OFFICE tab
## The front office, in the shape Retro Bowl uses and for the reason it works:
## every lever the owner has, on one screen, with what it costs written on the
## button. Bars rather than numbers, because "three of five" is a glance and
## "level 3" is a read.
const BAR_X := 24.0
const BAR_W := 300.0
const BAR_H := 26.0
const OFFICE_ROWS := [
	{ "label": "SALARY CAP", "kind": "cap" },
	## THE OTHER CAP, and the one this game was designed around — see
	## `ClubOffice.travel_slots`. It sits directly under the money one on purpose:
	## the two are the same kind of ceiling and a player should read them together.
	{ "label": "PLACES ON THE BUS", "kind": "travel" },
	{ "label": "TRAINING GROUND", "kind": ClubOffice.Facility.TRAINING },
	{ "label": "INFIRMARY", "kind": ClubOffice.Facility.INFIRMARY },
]


## The right column of the Clubhouse tab: three links, one under the other.
const NAV_X := 480.0
const NAV_W := 456.0
## THE CREST'S CORNERS NEED SOMEWHERE TO BE. The ornament is 24px in each
## corner, and drawn flush around buttons that already ran the full width they
## landed ON the buttons — a decorative bracket through the middle of "The
## staff". The frame keeps the full span and the buttons step inside it.
const NAV_PAD := 26.0
## FIVE ROWS IN THE SPACE FOUR HAD. The coaching-credits entry made this list
## five long, and at the old 50 the column grew fifty pixels and pushed "ON THE
## LIST" and its three role readouts down into the action row — a collision the
## ink sweep cannot see, because text over text is neither off the frame nor on
## a control nor off a panel. A screenshot saw it.
##
## 42 and a 36-high button gets five rows into 210 where four took 200, which is
## ten pixels rather than fifty, and leaves the block below where it was.
const NAV_ROW := 42.0
const NAV_BTN_H := 36.0
## Where the counter sits: under the four nav buttons, above the action row.
## The shop is a modal; this is the panel it draws in.
const SHOP_CARD := Rect2(200.0, 120.0, 560.0, 300.0)


func _office_row_y(i: int) -> float:
	return CONTENT_Y + 24.0 + float(i) * 86.0


func _office_controls() -> void:
	## The staff room and the book, both of which outgrew a tab.
	## THE THREE SCREENS THAT OUTGREW A TAB, in the right column that the captain
	## cards used to fill. They were at y=70, 116 and 162 — straight through the
	## HONOURS tab and then through the captain panel underneath it, which a
	## screenshot shows instantly and reasoning about coordinates never does.
	ui.add_child(UiKit.button("The staff", Vector2(NAV_X + NAV_PAD, CONTENT_Y + 28 + NAV_ROW * 0),
		Vector2(NAV_W - NAV_PAD * 2.0, NAV_BTN_H), func():
			Session.autosave()
			UiKit.go("res://scenes/Staff.tscn"), "helm"))
	ui.add_child(UiKit.button("The book", Vector2(NAV_X + NAV_PAD, CONTENT_Y + 28 + NAV_ROW * 1),
		Vector2(NAV_W - NAV_PAD * 2.0, NAV_BTN_H), func():
			Session.autosave()
			UiKit.go("res://scenes/Records.tscn"), "book"))
	## YOU. The only screen in the game that is not about the club, and it carries
	## a mark when somebody wants you — a job offer the player never notices is
	## the same as no job offer.
	var wanted: int = Jobs.offers(season.coach, season.world).size()
	ui.add_child(UiKit.button("Your career%s" % ("  ·  %d" % wanted if wanted > 0 else ""),
		Vector2(NAV_X + NAV_PAD, CONTENT_Y + 28 + NAV_ROW * 2), Vector2(NAV_W - NAV_PAD * 2.0, NAV_BTN_H), func():
			Session.autosave()
			UiKit.go("res://scenes/Coach.tscn"), "ladder"))
	## THE FEDERATION CARRIES ITS OWN WARNING. Being quietly not entered for the
	## cups is the most expensive thing that can happen to a club without a
	## message, and the player earns his place on the table where he can see it.
	var shorts := season.office.shortfalls()
	ui.add_child(UiKit.button("The federation%s" % ("  ·  BARRED" if not shorts.is_empty() else ""),
		Vector2(NAV_X + NAV_PAD, CONTENT_Y + 28 + NAV_ROW * 3), Vector2(NAV_W - NAV_PAD * 2.0, NAV_BTN_H), func():
			Session.autosave()
			UiKit.go("res://scenes/Federation.tscn"), "banner"))

	## THE COUNTER GETS ITS OWN SCREEN, reached from the nav list rather than
	## drawn into this tab.
	##
	## The first build put three price buttons straight into the clubhouse, under
	## the four nav buttons — and the screenshot showed them printing through the
	## crest ornament and through "ON THE LIST", because that column was already
	## full and nothing said so. That was the cheap fix; this is the right one.
	##
	## Real money deserves a deliberate stop anyway. A price that shares a row
	## with a coaching readout is a price somebody taps by accident.
	ui.add_child(UiKit.button("Coaching credits%s" % (
			"  ·  %d waiting" % Store.owed if Store.owed > 0 else ""),
		Vector2(NAV_X + NAV_PAD, CONTENT_Y + 28 + NAV_ROW * 4), Vector2(NAV_W - NAV_PAD * 2.0, NAV_BTN_H),
		func():
			shop_open = true
			_rebuild(), "coin"))

	var o := season.office
	for i in OFFICE_ROWS.size():
		var row: Dictionary = OFFICE_ROWS[i]
		var key: String = String(row["kind"]) if row["kind"] is String else ""
		var is_cap: bool = key == "cap"
		var is_travel: bool = key == "travel"
		var cost: int = o.cap_cost() if is_cap else (
			o.travel_cost() if is_travel else o.facility_cost(int(row["kind"])))
		if cost <= 0:
			continue
		var kind = row["kind"]
		ui.add_child(UiKit.button("%d CC" % cost,
			Vector2(BAR_X + BAR_W + 14.0, _office_row_y(i) + 10.0), Vector2(92, 34), func():
				var err: String = o.raise_cap() if is_cap else (
					o.buy_travel_slot() if is_travel else o.upgrade(int(kind)))
				flash = UiKit.said(err) if err != "" else "Improved."
				Session.autosave()
				_rebuild(), "coin"))

	## THE GROUND GETS ITS OWN SCREEN, because it is not a facility bar — it is a
	## picture of your club with your own badge painted on the floor of it, and a
	## diary. It sat in this list as "HOME GROUND" and was five levels of a
	## progress bar; that is exactly why it needed replacing.
	## THE ONLY LEVER ON MORALE. Everything else moves it at you — results, the
	## regime, a cut, a difficult man after a loss — and until this button there
	## was nothing the player could do about any of it on purpose.
	## AND IT SAYS WHEN IT CANNOT BE PRESSED. `can_boost()` folds the money and
	## the once-a-week throttle into one answer and had no caller — so the button
	## looked live every time and spent a tap to say no.
	## AND THE LABEL SAYS WHICH KIND OF NO IT IS. `can_boost()` folds the money
	## and the once-a-week throttle into one answer, which is the right shape for
	## a guard and the wrong shape for a label: "cannot" is not a reason, and a
	## player who is four credits short needs to hear something different from
	## one who has already had his night out. So the button asks the office both
	## questions and says which.
	var boost_label := "A night out  ·  %d CC" % season.office.boost_cost()
	if season.office.done_this_week(ClubOffice.SLOT_BOOST):
		boost_label = "A night out  ·  had one"
	elif not season.office.can_boost():
		boost_label = "A night out  ·  %d CC short" % (
			season.office.boost_cost() - season.office.credits)
	ui.add_child(UiKit.button(boost_label,
		Vector2(684, action_y()), Vector2(252, 46), func():
			var err := season.boost_morale()
			flash = UiKit.said(err) if err != "" else "The room lifted."
			Session.autosave()
			_rebuild(), "heart"))
	ui.add_child(UiKit.button("Arena", Vector2(464, action_y()), Vector2(204, 46), func():
		Session.autosave()
		UiKit.go("res://scenes/Arena.tscn"), "gate"))
	ui.add_child(UiKit.button("Chalkboard", Vector2(24, action_y()), Vector2(204, 46), func():
		Session.autosave()
		UiKit.go("res://scenes/Chalkboard.tscn"), "board"))
	ui.add_child(UiKit.button("Create", Vector2(244, action_y()), Vector2(204, 46), func():
		Session.autosave()
		UiKit.go("res://scenes/Create.tscn"), "anvil"))


## Who is available — one list, in ClubOffice, read by both screens that sell
## captains. It used to be a second copy of the same hash here.
func _offer(slot: int) -> Dictionary:
	return ClubOffice.offer(season.seed_value, season.world.season, slot,
		season.office.staff_refreshes)


## ---------------------------------------------------------------- the shop
## COACHING CREDITS, BOUGHT WITH MONEY. The only thing this game sells.
##
## Direction §8, superseded by Pete on 12 Sep 2026: premium at $4.99 with IAP
## for credits. There is no unlock product — nothing is locked, because the
## price of entry already happened.
##
## `Store` decides whether there is a counter at all; this only draws it. On
## desktop and on any build without the billing plugin the packs are not drawn
## and the reason is, because **a shop that shows a button it cannot honour is a
## shop that takes a tap and does nothing.**
func _shop_controls() -> void:
	var y := SHOP_CARD.position.y + SHOP_CARD.size.y - 62.0
	if Store.available():
		var packs := Store.PRODUCTS
		var pad := 24.0
		var pw: float = (SHOP_CARD.size.x - pad * 2.0 - 16.0) / float(maxi(1, packs.size()))
		for i in packs.size():
			var pk: Dictionary = packs[i]
			ui.add_child(UiKit.button("%d  ·  %s" % [int(pk["credits"]), String(pk["price"])],
				Vector2(SHOP_CARD.position.x + pad + float(i) * (pw + 8.0),
					SHOP_CARD.position.y + 150.0), Vector2(pw, 46),
				func(id = String(pk["id"])):
					var err := Store.buy(id)
					if err != "":
						flash = UiKit.said(err)
					else:
						## The grant is the store's callback, not this tap — a
						## shop that credits on the REQUEST credits a cancelled
						## purchase. What lands now is whatever is already owed.
						var got := Store.claim(season.office)
						flash = ("%d credits." % got) if got > 0 \
							else "Asked the store. Credits land when it answers."
						Session.autosave()
					_rebuild()))
		## THE BUTTON A PLAYER WHOSE MONEY WENT MISSING WILL LOOK FOR. For a
		## consumable there is nothing to re-own — the credits were spent — so
		## this asks the store for anything it charged for and never delivered.
		ui.add_child(UiKit.button("Restore a purchase",
			Vector2(SHOP_CARD.position.x + 24.0, y), Vector2(240, 44), func():
				Store.resolve_pending()
				var got := Store.claim(season.office)
				flash = ("%d credits." % got) if got > 0 \
					else "Asked the store for anything outstanding."
				Session.autosave()
				_rebuild()))
	ui.add_child(UiKit.button("Back",
		Vector2(SHOP_CARD.end.x - 184.0, y), Vector2(160, 44), func():
			shop_open = false
			_rebuild()))


func _draw_shop() -> void:
	draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(self, SHOP_CARD)
	UiKit.mid(self, font, "COACHING CREDITS",
		Vector2(SHOP_CARD.position.x, SHOP_CARD.position.y + 34.0), 19, UiKit.INK,
		SHOP_CARD.size.x)
	UiKit.mid(self, font, "Spent on levels, kit, the cap and the bus.",
		Vector2(SHOP_CARD.position.x, SHOP_CARD.position.y + 60.0), 12, UiKit.DIM,
		SHOP_CARD.size.x)
	UiKit.text(self, font, "In hand", Vector2(SHOP_CARD.position.x + 24.0,
		SHOP_CARD.position.y + 104.0), 13, UiKit.DIM)
	UiKit.right(self, font, "%d CC" % season.office.credits,
		Vector2(SHOP_CARD.end.x - 24.0, SHOP_CARD.position.y + 104.0), 15, UiKit.YOU, 200)
	if not Store.available():
		## The reason, in the middle, where the packs would have been.
		UiKit.mid(self, font, Store.closed_word(),
			Vector2(SHOP_CARD.position.x, SHOP_CARD.position.y + 170.0), 14,
			UiKit.EDGE.lightened(0.5), SHOP_CARD.size.x)
	elif Store.owed > 0:
		UiKit.right(self, font, "%d waiting" % Store.owed,
			Vector2(SHOP_CARD.end.x - 24.0, SHOP_CARD.position.y + 128.0), 12,
			UiKit.YOU, 200)


func _draw_office() -> void:
	var o := season.office
	## THE CREST GOES HERE AND ON THREE OTHER SCREENS. The clubhouse is the room
	## the player comes back to, the trophy cabinet, the bracket and the title —
	## four places, out of sixteen. Everywhere would be wallpaper.
	UiKit.ornament(self, UiKit.ORN_CREST,
		Rect2(NAV_X, CONTENT_Y, NAV_W, 28 + NAV_ROW * 4.0 + NAV_BTN_H + 12.0), UiKit.FRAME, 24.0)

	## NO HINT BAR, AND THAT IS SETTLED. `UiKit.hints()` was deleted on
	## 15 Sep 2026 — see the note where it used to live in `ui.gd`. It had never
	## been drawn on any screen, and the reason was structural rather than
	## forgetful: this tab's action row already runs to the bottom, so a footer
	## needs 26 pixels RESERVED across every screen that wants one. That is a
	## layout pass, not a call, and the screens have just been re-anchored to a
	## canvas that changes shape.
	for i in OFFICE_ROWS.size():
		var row: Dictionary = OFFICE_ROWS[i]
		var y := _office_row_y(i)
		var key: String = String(row["kind"]) if row["kind"] is String else ""
		var is_cap: bool = key == "cap"
		var label := String(row["label"])
		if key == "travel":
			## HOW MANY YOU CAN TAKE, and how many you actually have — two numbers
			## on one row, because a club with six places and five fit men has a
			## different problem from one with five places and nine fit men.
			var fit_men := 0
			for f2 in season.club.roster:
				if f2.fit():
					fit_men += 1
			UiKit.pair(self, font, label, "%d fit on books" % fit_men,
				Vector2(BAR_X, y), BAR_X + BAR_W, 13, 12, UiKit.DIM, UiKit.DIM)
			UiKit.meter(self, Rect2(BAR_X, y + 8, BAR_W, BAR_H),
				o.travel_slots - ClubOffice.TRAVEL_MIN,
				ClubOffice.TRAVEL_MAX - ClubOffice.TRAVEL_MIN, UiKit.YOU)
			UiKit.pair(self, font,
				"%d of %d" % [o.travel_slots, ClubOffice.TRAVEL_MAX],
				"a line and no more" if o.travel_slots <= ClubOffice.TRAVEL_MIN
					## SHORT ENOUGH FOR THE 220px IT IS GIVEN. The first version said
					## "2 swaps in the corner" and the screenshot printed "2 swaps
					## in the corn" — a right-aligned field clips from the right,
					## so the half that gets cut is the half carrying the meaning.
					else ("%d on the bench · %d swap%s" % [
						o.travel_slots - ClubOffice.TRAVEL_MIN,
						mini(o.travel_slots - ClubOffice.TRAVEL_MIN, Tuning.SWAPS_PER_CORNER),
						"" if mini(o.travel_slots - ClubOffice.TRAVEL_MIN, Tuning.SWAPS_PER_CORNER) == 1 else "s"]),
				Vector2(BAR_X, y + 54), BAR_X + BAR_W, 14, 12, UiKit.INK,
				UiKit.DOWN if o.travel_slots <= ClubOffice.TRAVEL_MIN else UiKit.DIM)
			continue
		if is_cap:
			UiKit.pair(self, font, label, "%s rules" % season.tier_name(),
				Vector2(BAR_X, y), BAR_X + BAR_W, 13, 12, UiKit.DIM, UiKit.DIM)
			var bill := ClubOffice.wage_bill(season.club)
			var cap := o.cap()
			UiKit.bar(self, Rect2(BAR_X, y + 8, BAR_W, BAR_H),
				float(bill) / float(maxi(1, cap)),
				UiKit.DOWN if bill > cap else UiKit.YOU)
			UiKit.pair(self, font,
				"%s of %s" % [ClubOffice.money(bill), ClubOffice.money(cap)],
				"%d raises · next %d CC" % [o.cap_level, o.cap_cost()],
				Vector2(BAR_X, y + 54), BAR_X + BAR_W, 14, 12,
				UiKit.DOWN if bill > cap else UiKit.INK, UiKit.DIM)
			continue
		var f := int(row["kind"])
		## A facility at level nought has no effect, and saying "-0 events off a
		## knock" is worse than saying nothing: it reads like a broken number
		## rather than like a thing you have not built.
		var effect := "not built"
		match f:
			ClubOffice.Facility.TRAINING:
				if o.training_points() > 0:
					effect = "%d points a winter" % o.training_points()
			ClubOffice.Facility.INFIRMARY:
				if o.injury_relief() > 0:
					effect = "-%d events off a knock" % o.injury_relief()
				elif o.level(f) > 0:
					effect = "one more level to help"
		## On the LABEL line, not under the bar. Under the bar it landed in the
		## same place as the blurb and the two strings printed through each other
		## — which a screenshot shows instantly and nothing else would.
		UiKit.pair(self, font, label, effect, Vector2(BAR_X, y),
			BAR_X + BAR_W, 13, 13, UiKit.DIM, UiKit.INK)
		UiKit.meter(self, Rect2(BAR_X, y + 8, BAR_W, BAR_H), o.level(f), ClubOffice.FACILITY_MAX,
			UiKit.UP if o.level(f) > 0 else UiKit.EDGE)
		## CLIPPED TO THE LEFT COLUMN. "Fighters improve over the winter. Your
		## captains decide who." is 462 pixels at this size and the column ends
		## at NAV_X — so it printed through "ON THE LIST" in the right column,
		## which is text over text and therefore invisible to every check in the
		## suite. A screenshot saw it.
		UiKit.text(self, font, UiKit.fit_px(font,
			String(ClubOffice.FACILITIES[f]["blurb"]), 13, NAV_X - BAR_X - 16.0),
			Vector2(BAR_X, y + 54), 13, UiKit.DIM)

	# ------------------------------------------------------------ the captains
	## THE CAPTAIN CARDS USED TO BE DRAWN HERE TOO, in full, with their own hire
	## and release buttons — a second copy of the Staff room on the tab next to
	## the link to it. Two screens showing the same two men, and two hire paths
	## that had to be kept in step by hand (they were not: only one of them fired
	## a new captain's arrival trait until this session).
	##
	## What belongs on this tab is the SUMMARY — which roles are going out
	## untaught — because that is the thing that sends you to the staff room. The
	## detail belongs where you act on it. Removing the duplicate is also what
	## made room for the three navigation buttons, which had been sitting on top
	## of the tab row and the captain panels.

	# --------------------------------------------------- what it means on the list
	## The whole justification for the staff screen, spelled out. A role nobody
	## covers goes out Green, which is a measured 63% loss rate — the player
	## should read that here, not work it out from a losing streak.
	## BELOW THE CREST, not through it. The ornament's bottom bracket reaches
	## `CONTENT_Y + 242` and this label sat at 250 — eight pixels of clearance
	## for a 24-pixel corner piece, so the bracket printed through "ON".
	## MEASURED OFF THE NAV LIST rather than written down, so a sixth button
	## moves this with it instead of printing through it.
	var y := CONTENT_Y + 28.0 + NAV_ROW * 4.0 + NAV_BTN_H + 26.0
	UiKit.text(self, font, "ON THE LIST", Vector2(NAV_X, y), 13, UiKit.DIM)
	## THREE CELLS ACROSS THE COLUMN, AND THE WORDS STACK INSIDE THEM.
	##
	## This was role and tier side by side at `480 + i * 156`, which fits exactly
	## as long as every tier is called "Rust". A club with taught roles says
	## **Hardened** — 88 pixels at 15px against the 80 the third cell had left —
	## and the word ran to x=962 of a 960-wide frame.
	##
	## It had been there since captains could teach, and the sweep could not see
	## it: the fixture that hires two captains was being deleted by the first
	## screen the sweep opened, so the clubhouse was only ever photographed with
	## nobody teaching anything. Fixing the fixture found this in one run.
	##
	## Stacked, the cell only has to hold the LONGER of the two words rather than
	## both plus a gap — and the pitch is measured off the canvas, so it is right
	## on a handset as well.
	var cells := (UiKit.right_edge() - NAV_X) / 3.0
	var i2 := 0
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		var tier: int = o.tier_for(role)
		var col := UiKit.DOWN if tier == Tuning.AiSkill.RUST else UiKit.UP
		var cx := NAV_X + float(i2) * cells
		UiKit.text(self, font, String(Tuning.ROLE_NAME[role]),
			Vector2(cx, y + 20), 13, UiKit.DIM)
		UiKit.text(self, font, UiKit.fit_px(font,
			String(Tuning.AI_SKILL[tier]["name"]), 15, cells - 10.0),
			Vector2(cx, y + 40), 15, col)
		i2 += 1
	## THE WARNING, and it is the only thing on this screen a player must act on.
	## Two captains have four specializations between them and there are three
	## roles, so leaving one untaught means two of them are teaching the same job.
	var bare := o.untaught()
	if bare.is_empty():
		UiKit.text(self, font, "Every role taught.", Vector2(NAV_X, y + 64), 13, UiKit.DIM)
	else:
		var names := ""
		for r in bare:
			names += ("" if names == "" else " and ") + String(Tuning.ROLE_NAME[r])
		## Two lines. One ran off the right edge and lost its last two words,
		## which on a warning is the half that says what to do about it.
		UiKit.text(self, font, "%s going out untaught." % names,
			Vector2(NAV_X, y + 64), 13, UiKit.DOWN)
		var doubled := ""
		for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
			if o.doubled(role):
				doubled = String(Tuning.ROLE_NAME[role])
		UiKit.text(self, font, "Both captains are teaching %s." % doubled
			if doubled != "" else "Hire a captain who teaches it.",
			Vector2(NAV_X, y + 82), 13, UiKit.DIM)

## The widest role name at the size the list draws them, so the skill column
## clears all three rather than clearing the first one.
func _role_col_w() -> float:
	var w := 0.0
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		w = maxf(w, font.get_string_size(String(Tuning.ROLE_NAME[role]),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x)
	return w


# --------------------------------------------------------------- HONOURS tab
func _draw_honours() -> void:
	var h := season.honours()
	var y := CONTENT_Y
	UiKit.text(self, font, "TROPHIES", Vector2(24, y), 13, UiKit.DIM)
	y += 30.0
	var any := false
	for i in range(h.size() - 1, maxi(-1, h.size() - 9), -1):
		var e: Dictionary = h[i]
		var won: bool = int(e["champion"]) == season.world.player_club
		var mine := String(e["player"]) != ""
		if not mine and not won:
			continue
		any = true
		UiKit.text(self, font, "S%d  %s" % [int(e["season"]), UiKit.clip(String(e["name"]), 22)],
			Vector2(40, y), 15, UiKit.INK)
		UiKit.right(self, font, "Champions" if won else String(e["player"]),
			Vector2(440, y), 15, UiKit.YOU if won else UiKit.DIM, 200)
		y += 26.0
	if not any:
		UiKit.text(self, font, "Nothing yet.", Vector2(40, y), 15, UiKit.DIM)

	y = CONTENT_Y
	UiKit.text(self, font, "SEASONS", Vector2(480, y), 13, UiKit.DIM)
	y += 30.0
	if season.world.history.is_empty():
		UiKit.text(self, font, "This is your first.", Vector2(496, y), 15, UiKit.DIM)
		return
	for i in range(season.world.history.size() - 1, maxi(-1, season.world.history.size() - 12), -1):
		var e: Dictionary = season.world.history[i]
		var tag := ""
		var col := UiKit.INK
		if bool(e.get("promoted", false)):
			tag = "  promoted"
			col = UiKit.UP
		elif bool(e.get("relegated", false)):
			tag = "  relegated"
			col = UiKit.DOWN
		UiKit.text(self, font, "S%d  %s" % [int(e["season"]),
			League.tier_name(int(e["tier"]))], Vector2(496, y), 15, UiKit.DIM)
		UiKit.right(self, font, "%s%s" % [UiKit.ordinal(int(e["position"])), tag],
			Vector2(UiKit.right_edge(), y), 15, col, 220)
		y += 26.0
