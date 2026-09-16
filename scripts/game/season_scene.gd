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
##   FINANCES where the money came from, where it went, and the ground
##
## Drawn with primitives on the same portrait 540x960 as the melee, so sprites
## drop in later without touching layout.

enum Tab { CLUB, SQUAD, MARKET, OFFICE, FINANCES }

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
## HOW TALL THE FIXTURE CARD IS. Named because the thing under it measures itself
## from `CONTENT_Y` rather than from the card's foot, so the two have to be read
## together by whoever changes either.
const FIXTURE_H := 118.0


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
	if sim_asking:
		_sim_controls()
		queue_redraw()
		return
	## Five tabs across 960 with the Menu button on the right, so they narrow
	## rather than the row wrapping — a wrapped tab row on a landscape phone
	## screen eats the first line of every page behind it.
	## EACH TAB CARRIES ITS MARK. A row of five words all the same length is
	## parsed; a row of five marks is recognised, which on a phone held in one
	## hand is the whole difference. The names stay — an icon alone is a rebus.
	var names := ["CLUB", "SQUAD", "ARMORER", "CLUBHOUSE", "FINANCES"]
	var marks := ["shield", "roster", "armor", "hall", "purse"]
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
	## The tape's own control goes with the tab's, so leaving the club tab takes
	## it down and nothing has to remember to.
	_tape_label = null
	_tape_clip = null
	if tab == Tab.CLUB and season.blocked_by() == "":
		_tape_build()
	match tab:
		Tab.CLUB: _club_controls()
		Tab.SQUAD: _squad_controls()
		Tab.MARKET: _market_controls()
		Tab.OFFICE: _office_controls()
		Tab.FINANCES: _finances_controls()
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
	## it covered the right half of the HONORS tab on every screen that had a
	## cup to look at.
	##
	## THE THIRD MOVE, AND THE SECOND COMMENT THAT WAS WRONG. The note above used
	## to end *"the left column under the fixture card is the one region on this
	## tab that belongs to nothing"*, and put the button at y=276. `_last_event()`
	## draws its line at `CONTENT_Y + 152` — which is 284. So the region belonged
	## to something, the button covered *"Last: beat Milwaukee Free Company 2-0
	## (+6) · simmed"* on every screen with a live cup, and the screenshot of the
	## fixture panel on 16 Sep caught it with half the sentence sticking out.
	##
	## **A comment that describes a region as empty is a comment, not a check.**
	## The genuinely free band is under the schedule and above the action row:
	## five rows of fixtures end at 418 and the action row starts at 476.
	if season.viewable_cup() != null:
		ui.add_child(UiKit.button("The draw", Vector2(24, action_y() - 52.0),
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
	if season.promotion_offered():
		var pt: Dictionary = season.promotion_terms()
		## SHORT LABELS. "Take the State League" and "Stay in the Backyard Circuit
		## · save 8 CC" are 218 and 280 pixels of text in 240- and 300-pixel
		## buttons, and both spilled over their own edges on the first render. The
		## division names are on the card six lines above; the buttons only have to
		## say which way.
		ui.add_child(UiKit.button("Take it",
			Vector2(24, action_y()), Vector2(200, 46), func():
				season.answer_promotion(true)
				flash = "Up to the %s." % String(pt["to"])
				Session.autosave()
				_rebuild(), "up"))
		ui.add_child(UiKit.button("Stay down  ·  save %d CC"
				% (int(pt["dues_up"]) - int(pt["dues_now"])),
			Vector2(240, action_y()), Vector2(260, 46), func():
				season.answer_promotion(false)
				flash = "Staying in the %s another year." % String(pt["from"])
				Session.autosave()
				_rebuild(), "shield"))
		return

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
	## ---------------------------------------------- the fixture's action row
	## THE FORMATION AND PLAY SLOTS ARE GONE FROM HERE — Pete, item 20 of the
	## 15 Sep playtest: *"We can find something else to put in the formation and
	## play slot. That should be a pop up for 'Sim it' and Fight should eventually
	## go to the pre-fight screen anyway."*
	##
	## He is describing a redundancy. `Fight it` leads to the walk-out and then to
	## BEFORE THE CHARGE, which is a screen whose entire job is choosing a shape
	## and a play with the men and their condition in front of you. Choosing them
	## HERE, on a card that shows a league table, is the same decision taken
	## earlier with less information — and then taken again ten seconds later.
	##
	## **A decision offered twice is a decision the player makes once and then
	## has to remember he already made.** The pre-fight screen keeps it, because
	## that is where the evidence is.
	ui.add_child(UiKit.button("Fight it", Vector2(24, action_y()),
		Vector2(204, 46), _fight, "crossed"))
	## AND SIM ASKS FIRST. It is the one button on this screen that spends a
	## fixture and cannot be undone — the result is written, the week ticks, kit
	## wears — and it sat one accidental thumb away from the button beside it.
	ui.add_child(UiKit.button("Sim it", Vector2(244, action_y()), Vector2(204, 46),
		func():
			sim_asking = true
			_rebuild(), "clock"))


## THE SIM CONFIRM, AS A MODAL RATHER THAN A TAP.
##
## Same shape as the shop: it REPLACES this screen's controls rather than sitting
## over them, because a scrim cannot cover a Button and this project has paid for
## that five times.
func _sim_controls() -> void:
	ui.add_child(UiKit.button("Sim it", Vector2(SIM_CARD.position.x + 28.0,
		SIM_CARD.position.y + SIM_CARD.size.y - 62.0), Vector2(220, 46), func():
			sim_asking = false
			season.skip_event()
			Session.autosave()
			flash = "Event simulated."
			_rebuild(), "clock"))
	ui.add_child(UiKit.button("Go back", Vector2(SIM_CARD.position.x
		+ SIM_CARD.size.x - 248.0, SIM_CARD.position.y + SIM_CARD.size.y - 62.0),
		Vector2(220, 46), func():
			sim_asking = false
			_rebuild()))


func _draw_sim_ask() -> void:
	UiKit.panel(self, SIM_CARD)
	var o := String(season.world.clubs[season.opponent_id()]["name"]) \
		if season.opponent_id() >= 0 else "nobody yet"
	UiKit.text(self, font, "SIM THIS ONE?", Vector2(SIM_CARD.position.x + 28.0,
		SIM_CARD.position.y + 46.0), 20, UiKit.YOU)
	UiKit.text(self, font, "The marshals run it without you. The result stands.",
		Vector2(SIM_CARD.position.x + 28.0, SIM_CARD.position.y + 76.0), 14, UiKit.INK)
	UiKit.text(self, font, "Your men still take the week: kit wears, the room moves.",
		Vector2(SIM_CARD.position.x + 28.0, SIM_CARD.position.y + 98.0), 13, UiKit.DIM)
	UiKit.text(self, font, "Against %s." % o,
		Vector2(SIM_CARD.position.x + 28.0, SIM_CARD.position.y + 124.0), 13, UiKit.EDGE)


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
## Where the heading row's baseline goes below the section title.
const SQUAD_HEAD_Y := 22.0
## HOW FAR THE FIRST MAN SITS BELOW THE SECTION TITLE. It was 26, which is the
## gap a list needs; a TABLE needs room for its heading as well, and both columns
## read this so neither can be moved without the other.
##
## AND IT WAS 40, WHICH PUT THE FIRST MAN'S BOX ON TOP OF THE HEADING. Pete,
## 15 Sep 2026: *"Both Calder and Norrey are pressing up heavy against the top of
## the Fighter/Role."* He is naming row one of each column, and the arithmetic
## says why it is exactly those two: a row's background is drawn at `y - 20` and
## stands `SQUAD_ROW - 2` tall, so the first row's box began at `CONTENT_Y + 20`
## — two pixels ABOVE the heading baseline at `SQUAD_HEAD_Y`. Every other row
## has a row above it to sit against; row one had a heading, and it was sitting
## on it.
##
## Fifty puts six pixels of air under the heading's baseline. The gap is DERIVED
## from `SQUAD_HEAD_Y` rather than written down beside it, so the heading and the
## first row cannot be moved apart by editing one of them — which is how they got
## two pixels into each other in the first place.
const SQUAD_TOP := SQUAD_HEAD_Y + 28.0


## WHERE THE KEY SITS: under the last man and clear of the action row, measured
## rather than written down. The eight are five on the line, a 28-pixel bench
## header and three on the bench; on a taller canvas the action row moves and a
## key at a fixed 452 would have been left stranded in the middle of the screen.
static func _squad_key_y() -> float:
	var last := CONTENT_Y + SQUAD_TOP + SQUAD_ROW * 8.0 + 28.0
	return minf(last + 16.0, action_y() - 22.0)

func _squad_rows() -> Array:
	var out: Array = []
	var five := season.club.starting_five()
	## CONTENT_Y + 40 AND NOT + 26, because the column heading now sits between
	## the section title and the first man. Both columns move together and both
	## read the same constant, so the reserve cannot end up fourteen pixels out
	## of step with the eight.
	var y := CONTENT_Y + SQUAD_TOP
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
	var ry := CONTENT_Y + SQUAD_TOP
	for f in _reserve_sorted():
		out.append({ "card": f, "y": ry, "kind": "reserve", "x": RESERVE_X })
		ry += SQUAD_ROW
	return out


## ------------------------------------------------------- ordering the reserve
## Pete, item 21 of the 15 Sep playtest: *"Squad screen needs sort by and
## min/max for skills/age/cost/whatever else."*
##
## IT SORTS THE RESERVE AND NOT THE EIGHT, and that is the whole design decision
## on this screen rather than an omission.
##
## `MeleeClub.starting_five()` picks the five by walking roster order and taking
## the first fit man who covers each slot — **roster order IS the depth chart**,
## which is what made `swap_order()` the fix for item 22. So the left column is
## not an arbitrary list that happens to be in an order: it is the order, it is
## information, and sorting it by wage would be sorting away the one thing it
## says. A screen that let you re-sort it would also have to decide whether
## tapping two men then swaps their DISPLAY places or their real ones, and there
## is no answer to that a player would guess right.
##
## The reserve has no such order. Nothing reads it, nothing depends on it, and it
## is the list a player is actually scanning when he asks "who is my best
## nineteen-year-old". So it sorts, and the eight stays the depth chart.
const RESERVE_SORTS := [
	{"key": "rating", "word": "rating"},
	{"key": "age", "word": "age"},
	{"key": "wage", "word": "wage"},
	{"key": "ceiling", "word": "ceiling"},
]


func _reserve_sorted() -> Array:
	var out: Array = season.club.reserves().duplicate()
	match String(RESERVE_SORTS[reserve_sort % RESERVE_SORTS.size()]["key"]):
		"age":
			## YOUNGEST FIRST, because the reason to sort a reserve by age is to
			## find the man worth waiting for, not the one about to retire.
			out.sort_custom(func(a, b): return a.age < b.age)
		"wage":
			out.sort_custom(func(a, b):
				return ClubOffice.billed(a) > ClubOffice.billed(b))
		"ceiling":
			out.sort_custom(func(a, b): return a.potential > b.potential)
		_:
			out.sort_custom(func(a, b): return a.overall() > b.overall())
	return out


## THE SPREAD OF THE WHOLE BOOK, which is the "min/max" half of item 21.
##
## Not a filter. Thirteen men is a list you read, not a set you query — a filter
## on a squad this size hides men to save scrolling that is not happening. What a
## player actually wants from "min/max" is the SHAPE: how old is this club, how
## far apart are the best and worst, what does the top earner cost. Three pairs
## on one line answer that, and they answer it about every man on the books
## rather than about whichever column is on screen.
func _squad_spread() -> String:
	var r: Array = season.club.roster
	if r.is_empty():
		return ""
	var lo_age := 99
	var hi_age := 0
	var lo_rat := 99
	var hi_rat := 0
	for f in r:
		lo_age = mini(lo_age, f.age)
		hi_age = maxi(hi_age, f.age)
		lo_rat = mini(lo_rat, f.overall())
		hi_rat = maxi(hi_rat, f.overall())
	## TWO PAIRS, NOT THREE. The third was the top wage and it did not fit: the
	## heading leaves 259 pixels and the three-pair line wanted 280, so `fit_px`
	## cut it to "top ." — which `test_ink.gd` would have failed on its next run,
	## because copy the game wrote itself is not allowed to lose its tail.
	##
	## The wage is the least of the three anyway. Total wages against the cap are
	## already on the right of this same line, which is the number that decides
	## anything; what one man costs is on his own row.
	return "age %d-%d  ·  rated %d-%d" % [lo_age, hi_age, lo_rat, hi_rat]


func _squad_controls() -> void:
	## THE ROSTER, which is the same men laid out like the sport rather than
	## like a list — and the only place a fighter's own record can be read.
	## IT WAS SITTING ON THE HONORS TAB. At y=70 with the tab strip at 72 this
	## button covered the right 112 pixels of the fifth tab, so on this tab the
	## label read "HONORS" and the tap opened the roster. Shipped, invisible,
	## and found by `test_layout.gd` the first time it drove every tab instead of
	## only the default one.
	ui.add_child(UiKit.button("Roster", Vector2(UiKit.right_edge(200.0), action_y()),
		Vector2(200, 46), func():
			Session.autosave()
			UiKit.go("res://scenes/Roster.tscn"), "roster"))
	## ONE BUTTON THAT CYCLES, not four that are three-quarters wrong at any
	## moment. The action row has three places on it and the sort is the least of
	## them; a segmented control would cost the width of the roster button to say
	## something the heading already says.
	## THE ROW BELONGS TO THE PICKED MAN WHEN THERE IS ONE.
	##
	## `Reserve by` sits at x=24 and `Free agents` at x=544, and both were added
	## UNCONDITIONALLY — while picking a fighter adds Trade at x=24 and the
	## contract fork at x=464. Two overlaps, and both were invisible for the life
	## of the screen: Trade is added later so it wins the tap and draws on top, and
	## the only symptom was that **the reserve could not be re-sorted while a man
	## was selected** and the right-hand button showed a bare "s" sticking out
	## from under Extend.
	##
	## `shots/trade.png` is the first thing that ever rendered this tab with a
	## fighter picked. `test_layout.gd` measures controls against controls and
	## would have caught it on sight — it drives every tab and never drove this
	## STATE, which is the gap it has now closed.
	##
	## Both come back the instant he is deselected. Sorting the reserve and going
	## to the shelf are things you do when you are not in the middle of a decision
	## about one man, which is why hiding them costs nothing.
	var sw := String(RESERVE_SORTS[(reserve_sort + 1) % RESERVE_SORTS.size()]["word"])
	if picked == null:
		ui.add_child(UiKit.button("Reserve by %s" % sw,
			Vector2(24, action_y()), Vector2(200, 46), func():
				reserve_sort = (reserve_sort + 1) % RESERVE_SORTS.size()
				_rebuild(), "roster"))

	## THE FREE AGENTS LIVE HERE NOW.
	##
	## They used to be the MARKET tab, which also carried a button labelled "Free
	## agents" that opened a second and better screen of the same men — Pete's
	## *"there's a tab within a tab"*, item 5 of the 15 Sep playtest. Two views of
	## one thing, one of them a worse version of the other, reached by a control
	## named after the tab you were already standing on.
	##
	## Signing a man is a SQUAD decision, so it is reached from the squad, and the
	## tab it vacated became the armorer's — the one mechanic in this game that
	## Direction calls the cap and that had no screen at all.
	if picked == null:
		ui.add_child(UiKit.button("Free agents",
			Vector2(UiKit.right_edge(416.0), action_y()), Vector2(200, 46), func():
				Session.autosave()
				UiKit.go("res://scenes/Market.tscn"), "coin"))

	## THE CLUB'S RECORD, which is where the HONORS tab went.
	##
	## Pete, 15 Sep 2026: *"Throw Honors into Squad and a team history page."*
	## The trophies and the season-by-season are now a page on the Records screen
	## — the club's other records already live there — and this is the door to it
	## from the squad, which is the screen a player is on when he wonders what
	## this lot have actually done.
	##
	## ONLY WHEN NOBODY IS PICKED. The action row has three places and the picked
	## state already wants all three for Cut, Prospect and Extend; a fourth button
	## underneath one of those is a button that works until it does not.
	if picked == null:
		ui.add_child(UiKit.button("Club record", Vector2(244, action_y()),
			Vector2(204, 46), func():
				Session.autosave()
				Session.records_page = Records.Page.HISTORY
				UiKit.go("res://scenes/Records.tscn"), "trophy"))
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
			Vector2(468, action_y()), Vector2(256, 46), func():
				var err := season.resign(picked) if out_of_deal else season.extend(picked)
				if err == "":
					flash = "%s: %s a week for %d years." % [picked.display_name,
						ClubOffice.money(ClubOffice.billed(picked)), picked.years]
					Session.autosave()
				else:
					flash = err
				_rebuild()))
		## AND THE BUTTON SAYS WHAT HE FETCHES, because letting a man go is a
		## PRICE now and not just a decision — see `Market.trade_value`. The three
		## buckets are coarse on purpose and a player can only read the edges if
		## the number is in front of him at the moment he is deciding; a sale
		## whose value he discovers in the ledger afterwards is a mechanic he
		## never games.
		##
		## Nothing for a man out of contract, and the label says "Cut" then rather
		## than naming a price of zero — the distinction is real (his deal has run
		## out and nobody is paying you for a man who can walk in the summer) and
		## "Trade · 0 CC" reads as a bug.
		var worth := season.trade_value(picked)
		## WIDER THAN THE ROW'S OTHER BUTTONS, and deliberately.
		##
		## "Trade Calder · 3 CC" is about 195 pixels of text and the row's standard
		## button is 204, so it filled its own edges — and a National Marquee man
		## with a long name and a 33-credit price would have run straight past
		## them. `Prospect` and `Extend` do not name the man and do not need to;
		## this one does, because it is the only control on the screen that both
		## costs a fighter and pays money, and "which man" is the thing a player
		## checks before pressing it. The 56 pixels of dead space between Extend
		## and Roster paid for it.
		var who := UiKit.clip(picked.display_name, 10 if worth > 0 else 14)
		ui.add_child(UiKit.button(("Trade %s  ·  %d CC" % [who, worth])
				if worth > 0 else ("Cut " + who),
			Vector2(24, action_y()), Vector2(232, 46), func():
				var gone := picked.display_name
				var err := season.release(picked)
				flash = UiKit.said(err) if err != "" else (
					"%s traded for %d CC." % [gone, worth] if worth > 0
					else "%s released." % gone)
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
			Vector2(272, action_y()), Vector2(180, 46), func():
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
	## game — one CC0 strip, tiled from the middle so the gem lands centerd, in
	## place of the 2px line that was there. It reads on every tab and costs one
	## call.
	UiKit.rule(self, UiKit.RULE_GEM, Vector2(0, 58), UiKit.screen().x, UiKit.FRAME)
	_banner()
	## The selected tab, marked under the buttons rather than on them, because a
	if sim_asking:
		_draw_sim_ask()
		return
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
		Tab.FINANCES: _draw_finances()


func _header() -> void:
	var w: Dictionary = season.world.clubs[season.world.player_club]
	draw_rect(Rect2(0, 0, UiKit.screen().x, 62), UiKit.PANEL)
	UiKit.badge(self, Vector2(38, 31), 20, season.club.kit,
		season.club.icon_color, int(season.club.icon))
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
	## one in the ground color — a ribbon, the way an 8-bit game labels a stage.
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
	_schedule()
	_table()
	_tape_draw_ground()


## ------------------------------------------------------------- what is left
## THE SPACE THE FORMATION AND PLAY BUTTONS LEFT. Pete, item 20: *"Maybe the
## schedule, and a couple other things."*
##
## The card said what is happening this week and the table said where everybody
## stands, and nothing anywhere said what is COMING — which is the one thing a
## manager plans against. Five rows, home and away marked, the current one lit.
func _schedule() -> void:
	var rest: Array = season.world.remaining_fixtures(5)
	if rest.is_empty():
		return
	## UNDER THE LAST RESULT, which sits at `CONTENT_Y + 152`. The first cut put
	## this at 150 and the heading printed straight through *"Last: beat Oklahoma
	## City Guard 2-0"* — two blocks in one column, written in two functions,
	## neither of which knew the other's height. Same shape as the clubhouse,
	## twice, today.
	var y := CONTENT_Y + 186.0
	UiKit.text(self, font, "WHAT IS LEFT", Vector2(24, y), 13, UiKit.DIM)
	y += 24.0
	for i in rest.size():
		var r: Dictionary = rest[i]
		var opp := int(r["opponent"])
		var home: bool = bool(r["home"])
		var nm := "a bye" if opp < 0 \
			else String(season.world.clubs[opp]["name"])
		## THE CURRENT MATCHDAY IS LIT and the rest are quiet, so the eye finds
		## "now" without reading the numbers.
		var col := UiKit.INK if i == 0 else UiKit.DIM
		## H AND A AS A MARK IN THE MARGIN, not "home" and "away" as words at the
		## end of the row.
		##
		## Pete, 15 Sep 2026: *"Let's have the Home and Away games notated."* They
		## were notated — in twelve-pixel EDGE grey, right-aligned past the club's
		## name, which is where the eye goes last. A one-letter mark in its own
		## column at the left is read at a glance down the list, which is what a
		## fixture list is for: **a fact you have to hunt for on a five-row list
		## is a fact that is not on the list.**
		if opp >= 0:
			UiKit.text(self, font, "H" if home else "A", Vector2(28, y), 13,
				UiKit.YOU if home else UiKit.EDGE.lightened(0.4))
		## AND WHAT THE AFTERNOON IS WORTH, which is the new half. The gate is
		## multiplied by the ground it is fought in, so a trip to somebody's
		## Sports hall pays better than a home tie in a back field — and a fixture
		## list that does not say so is hiding the one thing that now makes an
		## away day interesting.
		##
		## THE GROUND'S NAME AND THE FIGURE, not the figure and an adjective. The
		## first cut printed "1 CC · a thin gate" on all five rows, because in the
		## Backyard Circuit every club really is on a back field and the words
		## were all the same word — **a column that says the same thing on every
		## row is a column carrying no information.** The NAME differs from the
		## first season (a back field, a club gym, somebody's fenced ground) and
		## it teaches the player the map, which is what makes a fixture list worth
		## reading ahead. The adjective lives on the fixture panel, once, where
		## there is room for it to mean something.
		var tail := ""
		if opp >= 0:
			var gr: Dictionary = season.ground_of(
				season.world.player_club if home else opp)
			tail = "%s  ·  %d CC" % [Arena.arena_name_of(int(gr["level"])),
				season.gate_for_fixture(opp, home)]
		UiKit.pair(self, font, "%d.  %s" % [int(r["event"]),
			UiKit.clip_px(font, nm, 13, 150.0)], tail,
			Vector2(46, y), fixture_w() - 16.0, 13, 12, col, UiKit.EDGE)
		y += 20.0


## ------------------------------------------------------------------ the tape
## Pete, item 20: *"Definitely need a Ticker across the bottom full of humor and
## results."*
##
## ON THE CLUB TAB AND NOWHERE ELSE. It is a results service, and this is the
## screen where a player is looking at results — put on every tab it would be a
## moving object beside a roster somebody is reading, which is the thing the
## juice rules exist to prevent.
##
## IT IS A CONTROL, NOT DRAWN INK, AND THAT IS NOT A STYLE CHOICE.
##
## The first cut drew it with `UiKit.text` and a moving x, with a comment saying
## it could run off both ends because the y was fixed inside the strip and there
## was "nothing to clip". `test_ink.gd` failed it on the next run: *'Pittsburgh
## Club and Oklahoma City Guard are level...' at 955,944 runs to 2003,955* — a
## two-thousand-pixel string on a nine-hundred-pixel canvas, which is exactly
## what that check exists to forbid and exactly what the comment had waved away.
##
## The tempting fix was an exemption. **An exemption written for one screen is a
## hole for every other one** — that sentence was written into this suite six
## hours ago, about a hole that hid two of Pete's bugs, and it applies here.
##
## So the tape is really clipped: a `Control` with `clip_contents` on, a `Label`
## inside it that moves. Nothing is drawn outside the strip because nothing CAN
## be, the ledger never sees it because it is not ink, and the screen stops
## needing a redraw every frame to move a string — the Label moves itself.
var _tape: String = ""
var _tape_key: String = ""
var _tape_clip: Control = null
var _tape_label: Label = null
const TAPE_H := 22.0


func _tape_build() -> void:
	var key := "%d:%d" % [season.world.season, season.results.size()]
	if key != _tape_key or _tape_label == null:
		_tape_key = key
		## BUILT ONCE AN EVENT, NOT ONCE A FRAME. `Ticker.line_for()` joins a
		## dozen strings; at sixty frames a second that is a thousand joins for a
		## thing that changes eight times a season.
		_tape = Ticker.line_for(season)
	if _tape == "":
		return
	var y := UiKit.screen().y - TAPE_H
	_tape_clip = Control.new()
	_tape_clip.position = Vector2(0, y)
	_tape_clip.size = Vector2(UiKit.screen().x, TAPE_H)
	_tape_clip.clip_contents = true
	_tape_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tape_label = Label.new()
	_tape_label.text = _tape
	_tape_label.add_theme_font_override("font", font)
	_tape_label.add_theme_font_size_override("font_size", 12)
	_tape_label.add_theme_color_override("font_color", UiKit.DIM)
	_tape_label.position = Vector2(UiKit.screen().x, 3)
	_tape_clip.add_child(_tape_label)
	ui.add_child(_tape_clip)


func _tape_draw_ground() -> void:
	if _tape == "":
		return
	var y := UiKit.screen().y - TAPE_H
	draw_rect(Rect2(0, y, UiKit.screen().x, TAPE_H), UiKit.PANEL)
	draw_line(Vector2(0, y), Vector2(UiKit.screen().x, y), UiKit.FRAME, 1.0)


var _tape_t: float = 0.0


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
	## THE TAPE ASKS FOR ITS OWN FRAMES, which is the lesson of the note above:
	## an animation on a canvas that only redraws on rebuild is a still frame.
	## It runs only on the club tab, only when there is no card in the way, and
	## it is the second thing in this game allowed to move by itself.
	## THE TAPE MOVES ITSELF. A Label's position, not a redraw — the screen does
	## not need a new frame to slide a control, and asking for one every frame to
	## move a decoration is how a ticker ends up costing more than the fight.
	if _tape_label != null and _tape_label.is_inside_tree():
		_tape_t += _delta
		var w := _tape_label.size.x
		_tape_label.position.x = Ticker.offset(_tape_t, w, UiKit.screen().x)
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
	## dictionary, so the words and the colors can never disagree.
	var opts: Array = card.get("options", [])
	var w: float = (UiKit.span(32.0) - float(maxi(0, opts.size() - 1)) * 12.0) / float(maxi(1, opts.size()))
	## A RULE BETWEEN THE VOICE AND THE PRICES. The body is somebody talking and
	## the block underneath is three columns of figures, and with nothing between
	## them a short card left a hundred and fifty pixels of nothing in the middle
	## of the panel and the answers read as though they had come loose from it.
	## The line says the bottom of this panel is a different kind of thing, which
	## is true — it is the only structure on the card that encodes something.
	UiKit.rule(self, UiKit.RULE_GEM, Vector2(48.0, action_y() - 104.0), UiKit.span(48.0), UiKit.FRAME)
	## AND A KEY TO THE TWO WORDS NOBODY CAN GUESS.
	##
	## Pete, item 16 of the 15 Sep playtest: *"No idea what room or name mean."*
	## They are the squad's morale and the club's notoriety, and the card has been
	## printing `room -5` and `name +3` since the deck was written without either
	## word appearing anywhere else in the game. `kit`, `CC` and `crowd` explain
	## themselves; these two do not.
	##
	## On the rule rather than under the figures, because it is a legend and not
	## a fourth column — and read out of `Dilemma.FX_WORD` so that renaming a
	## currency renames its own key instead of leaving a caption behind.
	## SHORT ENOUGH FOR THE RULE IT SITS ON. The first wording ran to 440 pixels
	## in the 420 it was given and printed "how well you are kn" — a legend that
	## needs its own legend.
	UiKit.right(self, font, "%s = the squad's mood   ·   %s = your renown"
		% [Dilemma.FX_WORD["morale"], Dilemma.FX_WORD["note"]],
		Vector2(UiKit.right_edge(48.0), action_y() - 110.0), 12, UiKit.EDGE, 400.0)
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
		## EACH FIGURE IN ITS OWN COLOR, laid out by measuring what has already
		## been drawn rather than by joining a string — a single color for the
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
	## THE PROMOTION OFFER OUTRANKS EVERYTHING, because it is the only decision in
	## the game that changes which division you are in.
	if season.promotion_offered():
		return "PROMOTION"
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
	## 118 AND NOT 104. The card grew a line — where the fight is, in what ground,
	## and what the gate is worth — and the first cut drew it at `y + 98` inside a
	## 104-tall box, so the sentence sat ON the bottom rule. A line added to a
	## panel sized for the lines it already had is the same bug this project has
	## now shipped on the clubhouse, the settings screen and here.
	var r := Rect2(24, y, fixture_w(), FIXTURE_H)
	## THE HEADING GOES IN THE FRAME.
	##
	## It used to be the first line INSIDE the panel, which cost a line of the
	## panel's height to say something the panel already was. Cut into the top
	## rule it is furniture rather than content, the body starts higher, and a
	## rectangle becomes a labelled window — which is the single change that
	## stops an 8-bit menu reading like a web layout with a pixel font on it.
	UiKit.window(self, r, _fixture_title(), font)
	if season.promotion_offered():
		## GO UP, OR STAY WHERE YOU ARE.
		##
		## Pete, 15 Sep 2026: *"If you qualify for the next league, you can choose
		## to advance, or stay within your league next season. A player may bust
		## through the season but want to stay a season and continue building up
		## their money, train players, or whatever they wish, and staying in a
		## cheaper league would be beneficial."*
		##
		## BOTH BILLS ON THE CARD, because that is the whole decision and a player
		## should not have to go and find the second number on another page. The
		## division is a thing you pay to be in now, so "stay down" is a saving
		## with a figure on it rather than a button that wastes a year.
		var t: Dictionary = season.promotion_terms()
		UiKit.text(self, font, "Up to the %s" % String(t["to"]),
			Vector2(44, y + 52), 22, UiKit.UP)
		## FITTED TO THE CARD. "You finished 1st. The place is yours if you want
		## it." is 430 pixels at 14px against a 436-pixel panel, and the first
		## render lost the last two words — copy the game wrote itself is not
		## allowed to lose its tail.
		UiKit.text(self, font, UiKit.fit_px(font,
			"Finished %s. The place is yours if you want it."
				% UiKit.ordinal(season.position()), 13, fixture_w() - 40.0),
			Vector2(44, y + 80), 13, UiKit.DIM)
		UiKit.pair(self, font,
			"%s costs %d a season" % [String(t["to"]), int(t["dues_up"])],
			"you have %d" % int(t["in_hand"]),
			Vector2(44, y + 104), 24.0 + fixture_w() - 20.0, 12, 12,
			UiKit.EDGE.lightened(0.35),
			UiKit.UP if int(t["in_hand"]) >= int(t["dues_up"]) else UiKit.DOWN)
		return
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
	var word := "even" if absi(gap) <= 2 else ("favorites" if gap > 0 else "underdogs")
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

	## ------------------------------------------------- where, and what it pays
	## Pete, 15 Sep 2026: *"Let's have the Home and Away games notated."*
	##
	## THE PANEL THAT SAYS WHO YOU ARE FIGHTING DID NOT SAY WHERE. The schedule
	## underneath it carried a grey "home"/"away" and this — the card the player
	## actually looks at, the one with the rating and the odds on it — said
	## nothing at all about the venue. The one screen where the question is live
	## was the one screen with no answer on it.
	##
	## AND THE GROUND IS ON IT, because the gate now reads the room: a trip to a
	## club with a Sports hall pays better than a home tie in a back field, and
	## *"you may actually look forward to an opponent with a great stadium or roll
	## your eyes from an opponent with a shitty arena"* only works if the screen
	## tells you which one this is before you tap FIGHT.
	var g: Dictionary = season.gate_now()
	var kind := int(g["kind"])
	var where := String(Venue.NAME[kind]).to_upper()
	UiKit.text(self, font, where, Vector2(44, y + 28), 12,
		UiKit.YOU if kind == Venue.Kind.HOME else UiKit.DIM)
	UiKit.pair(self, font,
		"%s  ·  %s" % [Arena.arena_name_of(int(g["level"])),
			Arena.worth_word(int(g["level"]), float(g["condition"]))],
		"%d CC at the gate" % int(g["cc"]),
		Vector2(44, y + 104), 24.0 + fixture_w() - 20.0, 12, 12,
		UiKit.EDGE.lightened(0.35),
		UiKit.UP if int(g["cc"]) >= season.office.crowd_pay() else UiKit.DIM)


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
			## berths, and coloring them green would promise a division above
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
	## THE HEADING CARRIES THE SPREAD, because there is nowhere else for it.
	##
	## It went on its own line at `CONTENT_Y + 18` first, which is eight pixels
	## above the first man's baseline — so it printed under "#1 Calder" and was
	## invisible. The heading line has three hundred spare pixels between the end
	## of the words and the reserve column, and a summary belongs beside the thing
	## it summarises anyway.
	UiKit.pair(self, font, "THE EIGHT WHO TRAVEL", _squad_spread(),
		Vector2(24, CONTENT_Y), RESERVE_X - 16.0, 13, 12, UiKit.DIM, UiKit.EDGE)
	## THE RESERVE SAYS HOW IT IS ORDERED, because it is the only list on this
	## screen whose order is a choice rather than a fact.
	UiKit.text(self, font, "RESERVE — by %s" % String(
		RESERVE_SORTS[reserve_sort % RESERVE_SORTS.size()]["word"]),
		Vector2(RESERVE_X, CONTENT_Y), 13, UiKit.DIM)
	## The cap, where the decision is: every man on this screen costs against it.
	var bill := ClubOffice.wage_bill(season.club)
	var cap := season.office.cap()
	UiKit.right(self, font, "%s of %s" % [ClubOffice.money(bill), ClubOffice.money(cap)],
		Vector2(UiKit.right_edge(), CONTENT_Y), 13, UiKit.DOWN if bill > cap else UiKit.DIM, 300)
	## THE HEADINGS, over both columns, before any man is drawn.
	_squad_head(24.0, CONTENT_Y + SQUAD_HEAD_Y)
	if not season.club.reserves().is_empty():
		_squad_head(RESERVE_X, CONTENT_Y + SQUAD_HEAD_Y)

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
		UiKit.text(self, font, "Nobody.",
			Vector2(RESERVE_X + 16, CONTENT_Y + SQUAD_TOP), 15, UiKit.DIM)

	## AND THE KEY, for the three things a column heading cannot say.
	##
	## Headings name the fields; they do not explain the COLORS, and this screen
	## colors five of them. A player who sees one man's age in red and another's
	## in grey has been told something and has no way to find out what — which is
	## the same complaint as the unlabelled numbers, one layer down.
	##
	## One line, and only the three that carry a decision. The fourth and fifth
	## (a green kit percentage, a dimmed reserve name) mean "this is fine" and
	## "this man is not in the eight", and a key that explains the absence of a
	## problem is a key nobody finishes reading.
	UiKit.text(self, font, "NOW is what he is, MAX what he could be  ·  "
		+ "red = deal with it  ·  green = room to grow",
		Vector2(24, _squad_key_y()), 11, UiKit.EDGE.lightened(0.25))


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
## in `position` ran 6px into `armor` and `age` ran 7px into `wage`.
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
	## position would and takes the color that means "deal with this".
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
## EACH COLUMN NOW CARRIES ITS OWN HEADING AND ITS OWN ALIGNMENT, and that is
## the fix for Pete's *"Player has no idea what the numbers mean of the
## fighters."*
##
## Nine unlabelled fields is not a dense table, it is a cipher: a row reads
## `#4 Calder FLANKER 92% 27 $4.1k 3y 61 68` and there is nothing anywhere on
## the screen that says which of those two trailing numbers is what he is and
## which is what he could be. Every one of them was explained in a comment in
## `_man_row`, which is the one place the player cannot see.
##
## THE HEADING LIVES IN THE SAME TABLE AS THE STOP, so a column cannot be moved
## without its label coming with it and a label cannot claim a field the row does
## not draw. `test_layout.gd` already walks these rects for collisions; putting
## the heading here means the heading is walked too.
func squad_columns(f: Font, size_hint: int = 0) -> Array:
	var _unused := size_hint
	var out: Array = []
	var w := func(s: String, px: int) -> float:
		return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
	## THE HEADING GETS ITS OWN MEASURED RECT, and that turned out to matter on
	## the first screenshot: the four fields on the right hold tiny values —
	## `$3`, `3y`, `40`, `44` — so their rects are sized to the widest value they
	## could ever hold, which is narrower than the WORD that names them. Drawn at
	## the data's own stops the row read `WAGEDEALNOWMAX`.
	##
	## So the heading has its own stop per column, its width is measured from the
	## label at the size it is actually drawn, and `test_layout.gd` walks these
	## for collisions exactly as it walks the data rects. **A label that does not
	## fit where its column does is a column with no label.**
	var hw := func(s: String) -> float:
		return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			SQUAD_HEAD_PX).x
	var lhead := func(label: String, at: float) -> Rect2:
		return Rect2(at, 0.0, float(hw.call(label)), 14.0)
	var rhead := func(label: String, to: float) -> Rect2:
		var wd: float = float(hw.call(label))
		return Rect2(to - wd, 0.0, wd, 14.0)

	out.append({"name": "number", "head": "#", "align": "left",
		"rect": Rect2(COL_NUM, 0.0, float(w.call("#13", 13)), 18.0),
		"head_rect": lhead.call("#", COL_NUM)})
	## The name can never exceed its budget, because `UiKit.fit` measures it.
	out.append({"name": "name", "head": "FIGHTER", "align": "left",
		"rect": Rect2(COL_NAME, 0.0, COL_NAME_W, 18.0),
		"head_rect": lhead.call("FIGHTER", COL_NAME)})
	out.append({"name": "position", "head": "ROLE", "align": "left",
		"rect": Rect2(COL_POS, 0.0, float(w.call("FLANKER", 13)), 18.0),
		"head_rect": lhead.call("ROLE", COL_POS)})
	out.append({"name": "armor", "head": "KIT", "align": "left",
		"rect": Rect2(COL_ARMOR, 0.0, float(w.call("100%", 13)), 18.0),
		"head_rect": lhead.call("KIT", COL_ARMOR)})
	out.append({"name": "age", "head": "AGE", "align": "left",
		"rect": Rect2(COL_AGE, 0.0, float(w.call("39", 13)), 18.0),
		"head_rect": lhead.call("AGE", COL_AGE)})
	## Right-aligned: the widest string this field can produce, ending at its stop.
	var wage: float = w.call("$99.9k", 13)
	out.append({"name": "wage", "head": "PAY", "align": "right",
		"rect": Rect2(COL_WAGE_TO - wage, 0.0, wage, 18.0),
		"head_rect": rhead.call("PAY", COL_WAGE_TO)})
	## `YR` AND NOT `DEAL`. Six pixels separate the wage's stop from the years'
	## and no four-letter word survives that; the field says `3y` and `OUT`, so
	## the two letters are the whole of the information anyway.
	out.append({"name": "years", "head": "YR", "align": "left",
		"rect": Rect2(COL_YEARS, 0.0, float(w.call("OUT", 12)), 18.0),
		"head_rect": lhead.call("YR", COL_YEARS)})
	var rating: float = w.call("99", 16)
	out.append({"name": "rating", "head": "NOW", "align": "right",
		"rect": Rect2(COL_RATING_TO - rating, 0.0, rating, 18.0),
		"head_rect": rhead.call("NOW", COL_RATING_TO)})
	var pot: float = w.call("99", 12)
	## MAX RIDES THE END OF THE ROW rather than the ceiling's own stop. There are
	## eight spare pixels at 446 and this label needs six of them to clear `NOW`;
	## the alternative was a third abbreviation nobody would read.
	out.append({"name": "ceiling", "head": "MAX", "align": "right",
		"rect": Rect2(COL_POT_TO - pot, 0.0, pot, 18.0),
		"head_rect": rhead.call("MAX", SQUAD_W)})
	return out


## HOW BIG THE HEADING TYPE IS. Small, and smaller than anything in the row it
## labels, because a heading that competes with its own data is a heading that
## makes the table harder to read rather than easier.
const SQUAD_HEAD_PX: int = 11


## THE HEADING ROW, drawn from the column table so it cannot drift from it.
##
## `NOW` AND `MAX` RATHER THAN `RTG` AND `POT`. The pair is the whole reason the
## roster screen works — neither number answers "should I keep him" on its own —
## and two abbreviations a player has to learn do not deliver that; two words he
## already knows do. Same reason `KIT` is not `ARM`: this game has a harness and
## an armorer, and the word on the team sheet should be the word on the shop.
func _squad_head(x: float, y: float) -> void:
	var cols: Array = squad_columns(font, SQUAD_HEAD_PX)
	for c in cols:
		var label := String(c.get("head", ""))
		if label == "":
			continue
		## DRAWN AT ITS OWN RECT'S LEFT EDGE, left-aligned, whatever the column's
		## alignment is. The rect was already solved for — a right-aligned draw
		## here would solve for it a second time and the two would disagree the
		## day somebody changed the size.
		var hr: Rect2 = c["head_rect"]
		UiKit.text(self, font, label, Vector2(x + hr.position.x, y),
			SQUAD_HEAD_PX, UiKit.EDGE.lightened(0.35))
	## AND THE HAIRLINE UNDER IT, which is what turns nine words into a table
	## header rather than a tenth row of small text.
	draw_line(Vector2(x, y + 6.0), Vector2(x + SQUAD_W, y + 6.0),
		UiKit.FRAME, 1.0)


# ---------------------------------------------------------------- MARKET tab
## SIX MEN, A FEE AND A WAGE. The whole screen is one comparison the player has
## to make himself: is this man better than what I have, and can I carry him.
##
## The fee is drawn with its BAND NAME beside it, because that is the seam this
## market is built around — the fee is charged by band, so within a band a better
## fighter is free, and a player who never sees the band name will never notice
## that the 65 and the 61 cost the same six credits.
## IS THE SIM CONFIRM UP. See `_sim_controls()`.
var sim_asking: bool = false
## The confirm's own box. Same width as the shop's, because they are the same
## kind of thing and two modals at two sizes reads as two programs.
const SIM_CARD := Rect2(200.0, 150.0, 560.0, 240.0)

## HOW THE RESERVE COLUMN IS ORDERED. See `_reserve_sorted()`.
var reserve_sort: int = 0

## WHOSE HARNESS IS SELECTED ON THE ARMORER'S TABLE. Named for the screen it
## belongs to rather than the tab it happens to sit on — `market_pick` was the
## old name and the old screen, and a variable that outlives the thing it was
## named after is a comment that lies.
var qm_pick: FighterCard = null


# ------------------------------------------------------------ QUARTERMASTER
## THE ARMORER'S TABLE, and it replaces the free-agent list that used to be on
## this tab.
##
## Pete, 15 Sep 2026: *"Rebuild Market, there's a tab within a tab."* He was
## exactly right — the tab drew a list of free agents and then carried a button
## labelled "Free agents" that opened a second, better screen of the same men.
## Two views of one thing, one of them a worse version of the other, reached by
## a control that says the name of the tab you are already on.
##
## The free agents went to the Squad tab, which is where a player is thinking
## about his squad. This tab is now the one thing the game had a full mechanic
## for and no screen at all: what everybody is wearing, what state it is in, who
## the marshals are about to refuse, and what it costs to put right.
## How many earnings the clubhouse shows. See the note where they are drawn.
const QM_PURSE_LINES: int = 3

const QM_ROW := 30.0
const QM_TOP := 66.0
## EVERY X ON THIS SCREEN IS DERIVED FROM THE CELL, not typed. The first cut had
## four hand-placed columns and a bar width, and on the reserve side they added
## up to more than the half-screen they had — which is the same arithmetic
## mistake as the clubhouse's three tier words, two screens apart on the same
## afternoon.
const QM_GAP := 16.0
const QM_NAME_W := 118.0
const QM_GRADE_W := 92.0
const QM_BAR_W := 86.0
const QM_COST_W := 58.0


func _qm_cell() -> float:
	return (UiKit.span() - QM_GAP) * 0.5


## TWO COLUMNS, THE BUS AND THE CLUBHOUSE — the same split the Squad screen
## uses, and for the same reason.
##
## One column of thirteen at 30 pixels a row needs 390 of the 276 this screen has
## between the header and the action row, so the first cut ran four men off the
## bottom of the frame. Splitting it is not a workaround for that: the eight who
## travel are the men the marshals will actually look at, and the reserve is a
## different question the player asks less often. The layout should say so.
func _qm_rows() -> Array:
	var out: Array = []
	var y := CONTENT_Y + QM_TOP
	for f in season.club.active_eight():
		out.append({"card": f, "y": y, "x": 24.0, "bus": true})
		y += QM_ROW
	y = CONTENT_Y + QM_TOP
	for f in season.club.reserves():
		out.append({"card": f, "y": y, "x": 24.0 + _qm_cell() + QM_GAP, "bus": false})
		y += QM_ROW
	return out


# ------------------------------------------------------------ THE ARMORER
## AND IT REPLACES THE FREE-AGENT LIST THAT USED TO BE ON THIS TAB.
##
## Pete, 15 Sep 2026: *"Rebuild Market, there's a tab within a tab."* He was
## exactly right — the tab drew a list of free agents and then carried a button
## labelled "Free agents" that opened a second, better screen of the same men.
## Two views of one thing, one of them a worse version of the other, reached by a
## control named after the tab you were already standing on.
##
## The free agents moved to the Squad tab, where a player is already thinking
## about his squad. This tab is now the one thing the game had a full mechanic
## for and no screen at all: what everybody is wearing, what state it is in, who
## the marshals are about to refuse, and what it costs to put right. See
## `scripts/league/quartermaster.gd` for what was measured before it was built.
func _draw_market() -> void:
	var o := season.office
	var eight := season.club.active_eight()
	var led := Quartermaster.ledger(eight)

	UiKit.pair(self, font, "THE ARMORER", "%d CC in hand" % o.credits,
		Vector2(24, CONTENT_Y), UiKit.right_edge(), 16, 13, UiKit.YOU, UiKit.DIM)

	## THE HEADLINE IS THE MARSHALS, not the average. A club whose mean harness
	## reads 74% is fine; a club with one man under the line cannot field five,
	## and those two facts do not live in the same number.
	var head := "Every harness on the bus passes inspection."
	var head_col := UiKit.UP
	if int(led["failing"]) > 0:
		head = "%d of the eight will not pass inspection." % led["failing"]
		head_col = UiKit.DOWN
	elif int(led["at_risk"]) > 0:
		head = "%d of the eight are a bad week from failing." % led["at_risk"]
		## YOU, NOT DOWN. A club a bad week from trouble is a warning and a club
		## already in it is a failure; drawing both in the same red loses the only
		## distinction the line exists to make.
		head_col = UiKit.YOU
	UiKit.pair(self, font, head,
		("%d CC to put the eight right" % led["bill"]) if int(led["bill"]) > 0
			else "nothing owing",
		Vector2(24, CONTENT_Y + 26), UiKit.right_edge(), 14, 13, head_col, UiKit.DIM)

	var cell := _qm_cell()
	UiKit.text(self, font, "ON THE BUS", Vector2(24, CONTENT_Y + QM_TOP - 22),
		12, UiKit.EDGE)
	UiKit.text(self, font, "IN THE CLUBHOUSE",
		Vector2(24 + cell + QM_GAP, CONTENT_Y + QM_TOP - 22), 12, UiKit.EDGE)

	for row in _qm_rows():
		var f: FighterCard = row["card"]
		var y: float = row["y"]
		var x: float = row["x"]
		var bus: bool = row["bus"]
		if qm_pick == f:
			draw_rect(Rect2(x - 4.0, y - 20, cell + 8.0, QM_ROW - 4), UiKit.SELECT)

		## A MAN IN THE RESERVE IS DRAWN QUIETER. His kit still wears, but he is
		## not the one the marshals are about to look at.
		UiKit.text(self, font, UiKit.clip_px(font, f.display_name, 14, QM_NAME_W),
			Vector2(x, y), 14, UiKit.INK if bus else UiKit.DIM)
		var gx := x + QM_NAME_W + 6.0
		UiKit.text(self, font, UiKit.clip_px(font, Quartermaster.name_of(f), 12,
			QM_GRADE_W), Vector2(gx, y), 12,
			UiKit.UP if Quartermaster.grade_of(f) >= Quartermaster.Grade.FITTED
			else UiKit.DIM)

		## THE BAR CARRIES TWO LINES THE NUMBER CANNOT.
		##
		## The inspection line, painted where it actually falls, so "how close am
		## I" is a look rather than a subtraction. And the ceiling of his grade,
		## so the gap he can NEVER close is visible — which is the whole sales
		## pitch for the next harness and the one thing a percentage hides.
		var bx := gx + QM_GRADE_W + 6.0
		var r := Rect2(bx, y - 11, QM_BAR_W, 13)
		var col := UiKit.DOWN if not f.passes_inspection() \
			else (UiKit.UP if f.inspection_margin() >= Quartermaster.RISK_MARGIN
				else UiKit.YOU)
		UiKit.bar(self, r, clampf(f.armor, 0.0, 1.0), col)
		draw_rect(Rect2(r.position.x + r.size.x * FighterCard.INSPECTION_MIN,
			r.position.y - 2, 1.0, r.size.y + 4), UiKit.DOWN)
		if Quartermaster.ceiling(f) < 0.999:
			draw_rect(Rect2(r.position.x + r.size.x * Quartermaster.ceiling(f),
				r.position.y - 2, 1.0, r.size.y + 4), UiKit.EDGE)

		## WHAT IT COSTS, on the row, so a player reads the bill down a column
		## instead of tapping thirteen men to find out.
		var word := ""
		var wcol := UiKit.DIM
		if not f.passes_inspection():
			word = "OUT"
			wcol = UiKit.DOWN
		elif not Quartermaster.topped_out(f):
			word = "%d CC" % ClubOffice.kit_cost(f)
		elif Quartermaster.next_grade(f) >= 0:
			word = "%d CC" % Quartermaster.upgrade_cost(f)
			wcol = UiKit.EDGE
		if word != "":
			UiKit.right(self, font, word, Vector2(x + cell, y), 12, wcol, QM_COST_W)


func _market_controls() -> void:
	var o := season.office
	var led := Quartermaster.ledger(season.club.active_eight())
	var cell := _qm_cell()

	for row in _qm_rows():
		var f: FighterCard = row["card"]
		var b := UiKit.button("", Vector2(float(row["x"]) - 4.0, float(row["y"]) - 20),
			Vector2(cell + 8.0, QM_ROW - 4), func():
				qm_pick = f
				flash = ""
				_rebuild())
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		ui.add_child(b)

	## THE BULK ACTION IS THE ONE A PLAYER ACTUALLY WANTS. Thirteen taps to fix
	## thirteen harnesses is not a decision, it is a chore — the decision is "can
	## I afford the bus this week", and that is one button with the answer on it.
	var third := (UiKit.span() - 16.0) / 3.0
	if int(led["bill"]) > 0:
		ui.add_child(UiKit.button("Fix the bus  ·  %d CC" % led["bill"],
			Vector2(24, action_y()), Vector2(third, 46), func():
				var fixed := 0
				var spent := 0
				for f in season.club.active_eight():
					if Quartermaster.topped_out(f):
						continue
					var c := ClubOffice.kit_cost(f)
					if o.repair_kit(f) == "":
						fixed += 1
						spent += c
				flash = ("Nothing the armorer could do this week." if fixed == 0
					else "%d harnesses seen to, %d CC." % [fixed, spent])
				season.sync_power()
				Session.autosave()
				_rebuild(), "armor"))

	if qm_pick != null:
		var nm := UiKit.clip(qm_pick.display_name, 9)
		if not Quartermaster.topped_out(qm_pick):
			ui.add_child(UiKit.button("Repair %s · %d CC" % [nm,
				ClubOffice.kit_cost(qm_pick)],
				Vector2(24 + third + 8.0, action_y()), Vector2(third, 46), func():
					var err := o.repair_kit(qm_pick)
					flash = UiKit.said(err) if err != "" \
						else "%s's harness seen to." % qm_pick.display_name
					season.sync_power()
					Session.autosave()
					_rebuild()))
		var nxt := Quartermaster.next_grade(qm_pick)
		if nxt >= 0:
			ui.add_child(UiKit.button("%s · %d CC" % [
				String(Quartermaster.GRADE_NAME[nxt]),
				Quartermaster.upgrade_cost(qm_pick)],
				Vector2(24 + (third + 8.0) * 2.0, action_y()), Vector2(third, 46), func():
					var err := o.buy_harness(qm_pick)
					flash = UiKit.said(err) if err != "" \
						else "%s is in %s harness." % [qm_pick.display_name,
							Quartermaster.name_of(qm_pick).to_lower()]
					season.sync_power()
					Session.autosave()
					_rebuild(), "coin"))


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
## HOW MANY BUTTONS ARE IN THE NAV LIST, in one place, because three other things
## measure themselves from the bottom of it: the ornament frame around it, the
## purse ledger under it and the coaching line under that. It was five, the
## coaching-credits button moved to the Finances page, and the frame and both
## blocks were each carrying their own hand-written `NAV_ROW * 4.0`.
##
## **A number that has to agree with another number is a number that will stop
## agreeing** — and this one had already stopped twice in an afternoon when the
## list grew.
const NAV_BUTTONS: int = 4
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
	## HONORS tab and then through the captain panel underneath it, which a
	## screenshot shows instantly and reasoning about coordinates never does.
	ui.add_child(UiKit.button("The staff", Vector2(NAV_X + NAV_PAD, CONTENT_Y + 28 + NAV_ROW * 0),
		Vector2(NAV_W - NAV_PAD * 2.0, NAV_BTN_H), func():
			Session.autosave()
			UiKit.go("res://scenes/Staff.tscn"), "helm"))
	ui.add_child(UiKit.button("Records", Vector2(NAV_X + NAV_PAD, CONTENT_Y + 28 + NAV_ROW * 1),
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

	## THE COUNTER MOVED TO FINANCES, and so did the arena button on the action
	## row below. Pete, 15 Sep 2026: *"Clubhouse is too crowded."*
	##
	## He is right and the count says why: this tab carried four progress bars
	## with a price button each, five nav buttons, three action buttons, a purse
	## ledger and a coaching warning — sixteen controls and two readouts on one
	## screen. Both of the ones that left are about MONEY and there is now a page
	## about money; the arena is on it with the numbers that explain it, and the
	## counter belongs next to the balance it adds to rather than next to the
	## buildings.
	##
	## **A hub is defined by what it does not hold.** Everything still here is
	## either a thing this club owns or a room in it.

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
	## "A NIGHT OUT" IS GONE. Pete, 15 Sep 2026: *"A night out is pretty dumb,
	## take that out."*
	##
	## `Season.boost_morale()` and `ClubOffice.can_boost()` are left alone and
	## still tested — morale is real, it is pushed around by results and regimes
	## and cuts, and a club still wants somewhere to spend on it. What was dumb
	## was THIS: a button on the busiest row in the game whose whole offer was
	## "pay four credits, feel slightly better", competing for a thumb with the
	## chalkboard and the arena.
	##
	## The ones that are left are all places you GO. That is a coherent row.
	var third := (UiKit.span() - 16.0) / 3.0
	ui.add_child(UiKit.button("Playbook", Vector2(24, action_y()),
		Vector2(third, 46), func():
			Session.autosave()
			UiKit.go("res://scenes/Chalkboard.tscn"), "board"))
	ui.add_child(UiKit.button("Create", Vector2(24 + third + 8.0, action_y()),
		Vector2(third, 46), func():
			Session.autosave()
			UiKit.go("res://scenes/Create.tscn"), "anvil"))
	## AND THE ARENA IS ON THE FINANCES PAGE NOW — see the note above. Two
	## buttons across the row rather than three, which is `third` being a
	## deliberate width rather than a division: the row keeps its proportions and
	## the space where the arena was is space, which is the point of the exercise.


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
## and the reason is, because **a shop that shows a button it cannot honor is a
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
						## shop that credits on the REQUEST credits a canceled
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
		Rect2(NAV_X, CONTENT_Y, NAV_W, 28 + NAV_ROW * float(NAV_BUTTONS - 1)
			+ NAV_BTN_H + 2.0), UiKit.FRAME, 24.0)

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
	## MEASURED OFF THE NAV LIST rather than written down, so a fifth button moves
	## this with it instead of printing through it.
	##
	## The gap is back to 26 now that the purse ledger has gone to FINANCES: it
	## was cut to 12 because two blocks were fighting for 112 pixels, and with one
	## block left there is room to breathe — which is the whole of Pete's
	## *"Clubhouse is too crowded"* in one number.
	var y := CONTENT_Y + 28.0 + NAV_ROW * float(NAV_BUTTONS - 1) + NAV_BTN_H + 26.0
	## THE PURSE LEDGER WENT TO THE FINANCES PAGE, and it was already broken here.
	##
	## It was three lines of "what came in" under the nav list — Pete's item 25 of
	## the 15 Sep playtest, *"No income weekly ever"* — and it was, in its own
	## comment, *"the cheapest possible answer"*. Two things have changed since.
	##
	## First, there is a real one now. FINANCES shows every heading of income and
	## every heading of spending, this year against last, which is what item 25
	## actually wanted; and **a summary that repeats the screen it points at is two
	## screens disagreeing about which is the authority.**
	##
	## Second, and worse: the screenshot from 16 Sep shows "WHAT CAME IN / Nothing
	## yet. The gate pays after your first event." drawn UNDERNEATH the five nav
	## buttons, in grey, invisible. The nav list is Controls on the UI layer and
	## this block is `_draw()`; the layer always wins. **A scrim cannot cover a
	## Button — and it goes the other way too, and the other way is worse**,
	## because nothing errors and nobody can see what is missing.
	##
	## So the block is gone rather than moved down, and the space it used to take
	## is the answer to *"Clubhouse is too crowded."*

	## ---------------------------------------------------- ON THE LIST
	## ONE LINE, NOT A TABLE OF THREE.
	##
	## This drew Rail / Flanker / Center each with its coaching tier stacked
	## under it, plus two lines of warning — ninety pixels of a column that had a
	## hundred and thirty for two blocks. Adding the purse ledger above it pushed
	## the tiers straight through the action row.
	##
	## The table was never the point. Everything it said ended in *"go to the
	## staff room"*, and the staff room shows the same three roles in more detail
	## on a screen that is one tap away and is not full. **A summary that repeats
	## the screen it points at is two screens disagreeing about which of them is
	## the authority.** So: the headline, and the sentence that says what to do.
	UiKit.text(self, font, "ON THE LIST", Vector2(NAV_X, y), 13, UiKit.DIM)
	var bare := o.untaught()
	if bare.is_empty():
		var best := ""
		for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
			best = String(Tuning.AI_SKILL[o.tier_for(role)]["name"])
			break
		UiKit.pair(self, font, "Every role taught.", "going out %s" % best.to_lower(),
			Vector2(NAV_X, y + 20), UiKit.right_edge(), 13, 13, UiKit.UP, UiKit.DIM)
	else:
		## ONE LINE, and the column is the reason. There are 132 pixels between
		## the foot of the nav list and the action row for two blocks, and a
		## second line of warning put its descenders through the Chalkboard
		## button. The staff room says all of this at length and is one tap away.
		var names := ""
		for r in bare:
			names += ("" if names == "" else " and ") + String(Tuning.ROLE_NAME[r])
		UiKit.text(self, font, UiKit.fit_px(font,
			"%s untaught — see the staff room." % names,
			13, UiKit.right_edge() - NAV_X), Vector2(NAV_X, y + 20), 13, UiKit.DOWN)

## The widest role name at the size the list draws them, so the skill column
## clears all three rather than clearing the first one.
func _role_col_w() -> float:
	var w := 0.0
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		w = maxf(w, font.get_string_size(String(Tuning.ROLE_NAME[role]),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x)
	return w


# ------------------------------------------------------------- FINANCES tab
## WHERE THE MONEY CAME FROM AND WHERE IT WENT.
##
## Pete, 15 Sep 2026: *"Make Honors a finances page to show balance breakdowns
## and you can use that to advertise/buy CC. Might be a place to put the arena."*
##
## ---------------------------------------------------------------------------
## THIS TAB REPLACED THE TROPHY CABINET AND THAT IS THE RIGHT TRADE.
##
## What HONORS drew was two lists — the cups the club has won and the seasons it
## has had — and neither of them is a decision. A player looks at a trophy
## cabinet once a career; he looks at the books every time he is deciding whether
## he can afford something, which on this screen is most weeks. A tab is the most
## expensive piece of real estate the game has and it was spent on a scrapbook.
##
## The cabinet is not gone: both lists moved to a HISTORY page on the Records
## screen, which is where the club's other records already live and which is
## reached from the Squad tab. See `records_scene.gd`.
##
## ---------------------------------------------------------------------------
## AND IT IS HERE BECAUSE OF WHAT `tools/probe_afford.gd` FOUND.
##
## Pete: *"The income is either too low or costs are too high. 84 in one year
## will not maintain enough, you'll decline."* The probes say something more
## specific and much more interesting than "income is low", and a player can only
## act on the specific version:
##
##   A Backyard club's first five seasons take 17.8, 23.4, 23.8, 26.2 and 25.2
##   credits. **Of that, the gate is 1.4 a season and the membership subs are
##   8 to 19.** The money does not come from fighting; it comes from people
##   paying to belong to the club. The whole crowd-and-notoriety apparatus —
##   five screens' worth of bands, meters and turnout percentages — is worth
##   under two credits a year in the division a new player spends his first
##   hours in.
##
## No screen in the game said so, because money left the club in twenty-three
## separate places and nothing added it up. Now it does, and this draws it.
## Whether the shape is RIGHT is Pete's call and a separate commit; this is the
## instrument that makes the call possible.

const FIN_LEFT := 24.0
const FIN_RIGHT := 500.0
const FIN_ROW := 22.0
## The two figure columns, as right edges. This year and last, side by side,
## because a breakdown with nothing to compare it to is a list of numbers.
const FIN_NOW := 372.0
const FIN_WAS := 452.0
## WHERE THE TWO BUTTONS SIT, AND IT IS BELOW THE CROWD BLOCK RATHER THAN IN THE
## MIDDLE OF IT. They were at 300, which is eleven pixels above "A home fight
## pays" — and a Control is a child of the UI layer, so the button drew OVER the
## line and the figure simply was not there. **A scrim cannot cover a Button —
## and it goes the other way too, and the other way is worse**, because a
## missing number looks like a number the game does not have.
const FIN_BUTTONS_Y := 372.0


func _finances_controls() -> void:
	## THE GROUND, from the page that talks about what it earns. Pete asked for
	## the arena to live here and it half does: the numbers are on this screen and
	## the building is one tap away, which is better than a sixth copy of the
	## build button.
	ui.add_child(UiKit.button("The ground", Vector2(FIN_RIGHT, FIN_BUTTONS_Y),
		Vector2(200, 44), func():
			Session.autosave()
			UiKit.go("res://scenes/Arena.tscn"), "gate"))
	## AND THE COUNTER. It was on the Clubhouse, which is Pete's *"Clubhouse is
	## too crowded"* — and it belongs on the page about money rather than the page
	## about buildings.
	ui.add_child(UiKit.button("Buy credits", Vector2(FIN_RIGHT + 216.0, FIN_BUTTONS_Y),
		Vector2(200, 44), func():
			shop_open = true
			_rebuild(), "coin"))


## THE YEAR IN HAND AND THE YEAR BEFORE IT, in two columns.
func _draw_finances() -> void:
	var o := season.office
	var last: Dictionary = o.books_last
	var was_in: Dictionary = last.get("in", {})
	var was_out: Dictionary = last.get("out", {})

	UiKit.text(self, font, "COMING IN", Vector2(FIN_LEFT, CONTENT_Y), 13, UiKit.DIM)
	UiKit.right(self, font, "this year", Vector2(FIN_NOW, CONTENT_Y), 11, UiKit.EDGE.lightened(0.35), 90)
	UiKit.right(self, font, "last", Vector2(FIN_WAS, CONTENT_Y), 11, UiKit.EDGE.lightened(0.35), 90)
	var y := CONTENT_Y + 26.0
	y = _fin_block(o.books_in, was_in, ClubOffice.IN_ORDER, y, UiKit.UP)
	var in_now := ClubOffice.book_total(o.books_in)
	var in_was := ClubOffice.book_total(was_in)
	y = _fin_rule(y)
	_fin_row("Everything in", in_now, in_was, y, UiKit.INK, 15)

	y += 38.0
	UiKit.text(self, font, "GOING OUT", Vector2(FIN_LEFT, y), 13, UiKit.DIM)
	y += 26.0
	y = _fin_block(o.books_out, was_out, ClubOffice.OUT_ORDER, y, UiKit.DOWN)
	var out_now := ClubOffice.book_total(o.books_out)
	var out_was := ClubOffice.book_total(was_out)
	y = _fin_rule(y)
	_fin_row("Everything out", out_now, out_was, y, UiKit.INK, 15)

	## AND THE ONE LINE THE WHOLE PAGE IS FOR. Green or red, at the foot, because
	## "am I making money" is the question and everything above it is the working.
	y += 30.0
	var net := in_now - out_now
	_fin_row("LEFT OVER" if net >= 0 else "SHORT", net, in_was - out_was, y,
		UiKit.UP if net >= 0 else UiKit.DOWN, 17)

	_fin_ground()


## One heading and its figure in both columns.
func _fin_row(label: String, now: int, was: int, y: float, col: Color,
		px: int = 13) -> void:
	UiKit.text(self, font, label, Vector2(FIN_LEFT + 14.0, y), px, col)
	UiKit.right(self, font, "%d" % now, Vector2(FIN_NOW, y), px, col, 90)
	## LAST YEAR IS DIMMED, ALWAYS, whatever this year's line is doing. It is
	## context, not news — coloring it would put two equally loud numbers on one
	## row and the eye would have to work out which one is the present.
	UiKit.right(self, font, "—" if was == 0 else "%d" % was,
		Vector2(FIN_WAS, y), maxi(11, px - 2), UiKit.EDGE.lightened(0.4), 90)


func _fin_rule(y: float) -> float:
	draw_line(Vector2(FIN_LEFT + 14.0, y + 6.0), Vector2(FIN_WAS, y + 6.0),
		UiKit.FRAME, 1.0)
	return y + 24.0


## Every heading with anything on it, in the order the office keeps them.
func _fin_block(now: Dictionary, was: Dictionary, order: Array[String],
		y: float, col: Color) -> float:
	var rows: Array = ClubOffice.book_rows(now, order)
	## A HEADING THAT WAS BUSY LAST YEAR AND IS EMPTY THIS YEAR STILL SHOWS, at
	## nothing, because its absence is the information: a club that spent forty
	## credits on kit last year and nothing this year has either finished the job
	## or stopped doing it, and a row that quietly vanishes says neither.
	var seen := {}
	for r in rows:
		seen[String(r["line"])] = true
	for r in ClubOffice.book_rows(was, order):
		if not seen.has(String(r["line"])):
			rows.append({"line": String(r["line"]), "cc": 0})
	if rows.is_empty():
		UiKit.text(self, font, "Nothing yet.", Vector2(FIN_LEFT + 14.0, y), 13,
			UiKit.EDGE.lightened(0.3))
		return y + FIN_ROW
	for r in rows:
		var line := String(r["line"])
		_fin_row(line, int(r["cc"]), int(was.get(line, 0)), y,
			col if int(r["cc"]) > 0 else UiKit.DIM)
		y += FIN_ROW
	return y


## THE GROUND, ON THE PAGE ABOUT WHAT IT COSTS.
##
## Four lines and no more. The Arena screen is where a ground is looked at; this
## is where it is ACCOUNTED FOR, and the difference is that this side only cares
## about the two numbers that move money — what it pays and what it is costing
## you to let it go. **A summary that repeats the screen it points at is two
## screens disagreeing about which is the authority.**
func _fin_ground() -> void:
	var o := season.office
	var a := o.arena
	UiKit.text(self, font, "THE GROUND", Vector2(FIN_RIGHT, CONTENT_Y), 13, UiKit.DIM)
	var y := CONTENT_Y + 28.0
	UiKit.pair(self, font, a.arena_name(), a.condition_word(),
		Vector2(FIN_RIGHT, y), UiKit.right_edge(), 16, 13, UiKit.INK,
		UiKit.DOWN if a.shabby() else UiKit.DIM)
	y += 26.0

	## WHAT IT PAYS, and what it would pay kept. One line when the ground is
	## spotless, because "11 of 11" is a sum nobody needs to read.
	var pays := a.retainer()
	var full := a.retainer_full()
	if pays >= full:
		UiKit.pair(self, font, "Pays a year", "%d CC" % full,
			Vector2(FIN_RIGHT, y), UiKit.right_edge(), 13, 13, UiKit.DIM, UiKit.DIM)
	else:
		## SHORTER THAN IT WAS. "%d CC — %d lost to the state of it" finished at
		## 958 of a 960 canvas and `UiKit.pair` right-aligns, so on any narrower
		## shape the sentence walked back over its own label.
		UiKit.pair(self, font, "Pays a year",
			"%d CC  ·  %d lost to neglect" % [pays, full - pays],
			Vector2(FIN_RIGHT, y), UiKit.right_edge(), 13, 13, UiKit.DIM, UiKit.DOWN)
	y += 22.0

	UiKit.pair(self, font, "Upkeep each summer", "%d CC" % o.arena_upkeep(),
		Vector2(FIN_RIGHT, y), UiKit.right_edge(), 13, 13, UiKit.DIM, UiKit.DIM)
	y += 22.0
	if a.condition < 0.999 and a.level >= Arena.WEARS_FROM_LEVEL:
		UiKit.pair(self, font, "Putting it right", "%d CC" % a.upkeep_cost(),
			Vector2(FIN_RIGHT, y), UiKit.right_edge(), 13, 13, UiKit.DIM, UiKit.YOU)
	else:
		UiKit.pair(self, font, "Putting it right", "nothing to do",
			Vector2(FIN_RIGHT, y), UiKit.right_edge(), 13, 13, UiKit.DIM,
			UiKit.EDGE.lightened(0.35))

	## AND THE CROWD, because it is the other half of what a ground earns and it
	## is the half the probes found nobody was being told about: at the bottom of
	## the pyramid the gate is worth about a credit and a half a SEASON.
	y += 34.0
	UiKit.text(self, font, "THE CROWD", Vector2(FIN_RIGHT, y), 13, UiKit.DIM)
	y += 26.0
	UiKit.pair(self, font, "They put through the door",
		"%s  ·  %d%% full" % [UiKit.crowd_word(o.attendance()),
			int(round(o.fill() * 100.0))],
		Vector2(FIN_RIGHT, y), UiKit.right_edge(), 13, 13, UiKit.DIM, UiKit.DIM)
	y += 22.0
	UiKit.pair(self, font, "A home fight pays", "%d CC" % o.crowd_pay(),
		Vector2(FIN_RIGHT, y), UiKit.right_edge(), 13, 13, UiKit.DIM, UiKit.DIM)
	y += 22.0
	## AND THE BAR, which is the half that does not swing with the results. It is
	## on this page rather than the arena's because the whole reason it exists is
	## that it is a different KIND of income, and this is the page about that.
	UiKit.pair(self, font, Arena.sells(a.level),
		"%d CC a home meet" % Arena.counter_take(a.level, o.attendance()),
		Vector2(FIN_RIGHT, y), UiKit.right_edge(), 12, 13,
		UiKit.EDGE.lightened(0.35), UiKit.DIM)
