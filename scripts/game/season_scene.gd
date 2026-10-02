class_name SeasonScene
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
## Drawn with primitives on the same landscape 960x540 design frame as the melee
## (wider on phones — see UiKit.screen), so sprites drop in later without
## touching layout.

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
var flash_px := 15
var flash_room := 0.0
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
const PURSE_W := 170.0
## The Club button's width, and how far the purse and mood moved left for it.
const CLUB_BTN_W := 104.0
const HEADER_SHIFT := CLUB_BTN_W + 8.0
## The Menu button spans what Exit and Club used to: the purse keeps its place.
const MENU_BTN_W := 98.0 + HEADER_SHIFT
const MENU_W := 140.0
const PURSE_H := 38.0
const PURSE_SIZE: int = 18


static func purse_box() -> Rect2:
	return Rect2(UiKit.right_edge(376.0 + HEADER_SHIFT), 12.0, PURSE_W, PURSE_H)


static func purse_at() -> Vector2:
	return Vector2(UiKit.right_edge(358.0 + HEADER_SHIFT), 29.0)


const TABLE_Y := 140.0
## WHERE THE BUTTON ROW SITS — sixty-four pixels off the bottom of whatever
## canvas the game got. On every handset that is 476, the number this was before
## it moved, because a handset never changes the 540. A 4:3 tablet gets 720 of
## height and the row goes to the bottom of it instead of floating two-thirds
## up the screen with a third of a screen of nothing underneath.
## 74, not 64 (playtest 30 Sep: the Sim it / Fight row cut into the ticker).
## A 46-tall button with its 4 px drop now ends 2 px above the 22 px tape.
const ACTION_INSET := 74.0


static func action_y() -> float:
	return UiKit.screen().y - ACTION_INSET

var font: Font
var season: Season
var ui: CanvasLayer
var tab: int = Tab.CLUB
## THE TAB YOU LEFT FROM IS THE TAB YOU COME BACK TO. Open Free agents or the
## cards from Squad, press Back, and you are on Squad again — not the Club tab.
static var last_tab: int = Tab.CLUB
## THE MESSAGE GOES AWAY ON ITS OWN (Pete, 1 Oct: it sat over the Finances
## headings until the next tap). Shown for FLASH_MS, then cleared — a tap on the
## same screen still replaces it at once.
var flash := "":
	set(v):
		flash = v
		_flash_at = Time.get_ticks_msec()
var _flash_at: int = 0
const FLASH_MS: int = 4500
## The counter, open or shut. A modal on this screen for the same reason the
## fighter's meeting card is one: real money deserves a deliberate stop.
var shop_open := false
## THE CLUB MENU (Pete, 29 Sep 2026, round 2): the rooms — staff, records,
## career, federation, playbook, create — left the Clubhouse tab for a list
## behind one header button, so the tab holds only the things you buy.
var club_menu_open := false
## THE TRAINING POPUP (Pete, 1 Oct 2026): each captain's Light / Normal / Hard
## and the paid session, off the Team tab's Training button.
var training_open := false
## WHICH "?" IS OPEN on the Upgrades tab, or "".
var help_key := ""
## THE GROUND PROMPT, mid-season (Pete, 1 Oct 2026). See SeasonDesk.ground_ask.
var ground_open := false
## THE FULL BOOKS are open on the Management tab (its Finances button).
var fin_full := false
## THE ARMORERS FOR HIRE are open on the Maintenance tab.
var armorer_open := false
## The squad screen's whole interaction: pick a man, then pick who he trades
## places with. Two taps, no modal, and the second tap is on a list you are
## already looking at.
var picked: FighterCard = null
## SWAP MODE (playtest 30 Sep #16): the picked man's Swap button arms it, and
## the next man tapped trades places with him. Off, a tap only picks.
var swapping: bool = false


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	if Session.season == null:
		Session.season = Season.new(MeleeRosters.starting_club(), randi())
	season = Session.season
	## A SAVE FROM BEFORE THE COACH asks for him once (Pete, 1 Oct 2026).
	if not season.coach.created:
		UiKit.go.call_deferred("res://scenes/Coach.tscn")
	if Session.open_armorers:
		Session.open_armorers = false
		armorer_open = true
	## Something to answer first (a card, a tie, promotion) opens on the Club tab.
	tab = last_tab if season.blocked_by() == "" else Tab.CLUB
	## A bout walked out of on the last run — said once.
	if season.last_interrupted != "":
		flash = season.last_interrupted
		season.last_interrupted = ""
	## Anything the club had to do to put five men on the list — said once.
	if not season.last_emergency.is_empty():
		flash = UiKit.t("Short of fit men: ") + season.last_emergency[0] + (
			UiKit.t(" and %d more.") % (season.last_emergency.size() - 1)
				if season.last_emergency.size() > 1 else ".")
		season.last_emergency = []
	if not season.ground_ask().is_empty():
		ground_open = true
	if flash == "":
		flash = season.summer_warning()
	if flash == "":
		flash = season.hoard_note()
	## BELOW THE LEAGUE'S INSURANCE, the cups are shut — said where it can be fixed.
	if flash == "" and not season.office.compliant():
		flash = UiKit.t("Insurance is below what your league asks: no cups until it is raised in Upgrades.")
	ui = CanvasLayer.new()
	add_child(ui)
	_rebuild()


## BACK (Android back / Esc), via AppLife. A modal closes first; then back to
## the Club tab; then out to the title, the same as Menu.
func go_back() -> bool:
	if ground_open:
		SeasonClubTab.close_ground(self)
		return true
	if club_menu_open or training_open or help_key != "" or armorer_open:
		club_menu_open = false
		training_open = false
		help_key = ""
		armorer_open = false
		_rebuild()
		return true
	if shop_open:
		shop_open = false
		_rebuild()
		return true
	if sim_asking:
		sim_asking = false
		_rebuild()
		return true
	if fin_full:
		fin_full = false
		_rebuild()
		return true
	if tab != Tab.CLUB:
		tab = Tab.CLUB
		picked = null
		_rebuild()
		return true
	Session.autosave()
	UiKit.trail_reset()
	UiKit.go("res://scenes/Title.tscn")
	return true
## -> SeasonClubTab (season_tab_club.gd)
func _winter_word() -> String:
	return SeasonClubTab._winter_word(self)


## -> SeasonClubTab (season_tab_club.gd)
func _split_word() -> String:
	return SeasonClubTab._split_word(self)


## -> SeasonClubTab (season_tab_club.gd)
func _upkeep_word() -> String:
	return SeasonClubTab._upkeep_word(self)




func _rebuild() -> void:
	_centre_modals()
	if Session.save_failed and not Session.save_warned:
		Session.save_warned = true
		flash = UiKit.t("Could not save — your phone may be out of space. The last save is safe.")
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
	if club_menu_open:
		SeasonClubhouseTab._club_menu_controls(self)
		queue_redraw()
		return
	if training_open:
		SeasonClubhouseTab._training_controls(self)
		queue_redraw()
		return
	if help_key != "":
		SeasonClubhouseTab._help_controls(self)
		queue_redraw()
		return
	if ground_open:
		SeasonClubTab._ground_controls(self)
		queue_redraw()
		return
	if armorer_open:
		SeasonArmorerTab._armorers_controls(self)
		queue_redraw()
		return
	## Five tabs across 960 with the Menu button on the right, so they narrow
	## rather than the row wrapping — a wrapped tab row on a landscape phone
	## screen eats the first line of every page behind it.
	## EACH TAB CARRIES ITS MARK. A row of five words all the same length is
	## parsed; a row of five marks is recognised, which on a phone held in one
	## hand is the whole difference. The names stay — an icon alone is a rebus.
	## "UPGRADES", NOT "CLUBHOUSE" (playtest 30 Sep #17: "No real obvious way to
	## upgrade facilities"). The tab is the club's shop of improvements; its
	## name says so, and it carries the coin.
	## FIGHT, TEAM, MAINTENANCE, UPGRADES, MANAGEMENT (Pete, 1 Oct 2026).
	var names := [UiKit.t("FIGHT"), UiKit.t("TEAM"), UiKit.t("MAINTENANCE"), UiKit.t("UPGRADES"), UiKit.t("MANAGEMENT")]
	var marks := ["sword", "roster", "armor", "coin", "purse"]
	## THE ARMORER OPENS AFTER BOUT ONE (Pete, 29 Sep 2026, #5). The tabs close up
	## rather than leave a hole.
	var shown: Array[int] = []
	for i in names.size():
		if i == Tab.MARKET and not season.first_bout_done():
			continue
		shown.append(i)
	if tab == Tab.MARKET and not shown.has(Tab.MARKET):
		tab = Tab.CLUB
	for slot in shown.size():
		var i: int = shown[slot]
		ui.add_child(UiKit.selected(UiKit.button(names[i], Vector2(24 + float(slot) * (TAB_W + 6.0), TAB_Y),
			Vector2(TAB_W, TAB_H), func():
				tab = i
				picked = null
				fin_full = false
				_rebuild(), marks[i]), i == tab))
	## ONE MENU BUTTON (Pete, 1 Oct 2026: "Menu - Resume, Settings, Save/Load,
	## Quit"). The rooms that used to hang off the header — staff, playbook,
	## records, create — live on the Management tab now.
	ui.add_child(UiKit.button(UiKit.t("Menu"), Vector2(UiKit.right_edge(MENU_W + 20.0), 14),
		Vector2(MENU_W, 36), func():
			club_menu_open = true
			_rebuild(), "cog"))
	## The tape's own control goes with the tab's, so leaving the club tab takes
	## it down and nothing has to remember to.
	_tape_label = null
	_tape_clip = null
	## NOT ON AN OCCASION: the tape sits on the bottom strip, and on a cup or boss
	## night that strip is the ribbon naming the occasion — the tape hid it.
	if tab == Tab.CLUB and season.blocked_by() == "" and season.mood() == UiKit.Mood.NORMAL:
		_tape_build()
	match tab:
		Tab.CLUB: _club_controls()
		Tab.SQUAD: _squad_controls()
		Tab.MARKET: _market_controls()
		Tab.OFFICE: _office_controls()
		Tab.FINANCES: _finances_controls()
	_next_controls()
	last_tab = tab
	queue_redraw()


## THE WAY FORWARD, on every tab (29 Sep 2026, blind review #1: "the core loop
## has no obvious path forward"). Bottom right, gold, the one primary button on
## the hub. It fights the next event, or names what has to be answered first and
## goes there. On the Club tab a blocker's own buttons are the way forward, so it
## steps aside for them.
const NEXT_W := 220.0


func _next_controls() -> void:
	var block := season.blocked_by()
	if tab == Tab.CLUB and (block != "" or season.season_complete() or team_card >= 0):
		return
	## A picked man owns the Squad tab's row (Trade, Prospect, Extend).
	if tab == Tab.SQUAD and picked != null:
		return
	## And a picked man owns the Armorer's (Repair, Upgrade).
	if tab == Tab.MARKET and qm_pick != null:
		return
	## SAYS WHAT IS NEXT (blind review round 2: "Next event" with crossed swords
	## read as close). "vs ATL" for a fight, "Bye" when there is nobody.
	var opp := season.opponent_id()
	var label := (UiKit.t("Fight: vs %s") % String(season.world.clubs[opp].get("short", "?"))) if opp >= 0 \
		else (UiKit.t("Next event") if season.world.week_kind() == Calendar.Kind.LEAGUE
			else UiKit.t("Train this week"))
	var go := _fight
	if season.season_complete():
		label = UiKit.t("End the season")
		go = func(): tab = Tab.CLUB; _rebuild()
	elif block != "":
		match block:
			"bid": label = UiKit.t("Tournament bid")
			"cup": label = UiKit.t("Fight the cup bout")
			"dilemma": label = UiKit.t("A decision")
			"sendoff": label = UiKit.t("The send-off")
			"promotion": label = UiKit.t("Promotion")
		go = func():
			if block == "bid":
				Session.autosave()
				UiKit.go("res://scenes/Arena.tscn")
				return
			tab = Tab.CLUB
			_rebuild()
	## THE MARK IS THE CROSSED SWORDS, not a ▶: the pixel fonts have no arrow.
	var fight := UiKit.button(label, Vector2(UiKit.right_edge(NEXT_W + 24.0) - step_shift(), action_y()),
		Vector2(NEXT_W, 46), go, "sword")
	ui.add_child(fight if step_shift() > 0.0 else UiKit.primary(fight))
	_step_control()


## THE GOLD BUTTON IS THE NEXT REAL STEP (1 Oct novice report, Pete approved).
## On the hub, a starter who fails inspection or a ground the division above
## would refuse, and can be built this week, takes the gold slot; the fight
## steps left beside it, plain. `Season.gold_step()` decides.
func _step_control() -> void:
	if step_shift() <= 0.0:
		return
	var o := season.office
	var b: Button
	if season.gold_step() == "kit":
		b = UiKit.button(UiKit.t("Fix kit"), Vector2(UiKit.right_edge(NEXT_W + 24.0), action_y()),
			Vector2(NEXT_W, 46), func():
				tab = Tab.MARKET
				_rebuild(), "anvil")
	else:
		var gap: Dictionary = season.ground_gap()
		b = UiKit.button(UiKit.t("Build %s · %d CC") % [UiKit.t(String(gap["next"])), int(gap["next_cost"])],
			Vector2(UiKit.right_edge(NEXT_W + 24.0), action_y()), Vector2(NEXT_W, 46), func():
				var err := o.build_arena()
				flash = UiKit.said(err) if err != "" else UiKit.t("Built. %s.") % o.arena.arena_name()
				Session.autosave()
				_rebuild(), "hall")
	ui.add_child(UiKit.primary(b))


## How far the fight (and Sim it) step left for the gold step. 0 when there is none.
func step_shift() -> float:
	if tab != Tab.CLUB or team_card >= 0 or season.gold_step() == "":
		return 0.0
	return NEXT_W + 12.0
## -> SeasonClubTab (season_tab_club.gd)
func _club_controls() -> void:
	SeasonClubTab._club_controls(self)




## THE SIM CONFIRM, AS A MODAL RATHER THAN A TAP.
##
## Same shape as the shop: it REPLACES this screen's controls rather than sitting
## over them, because a scrim cannot cover a Button and this project has paid for
## that five times.
func _sim_controls() -> void:
	ui.add_child(UiKit.button(UiKit.t("Sim it"), Vector2(SIM_CARD.position.x + 28.0,
		SIM_CARD.position.y + SIM_CARD.size.y - 62.0), Vector2(220, 46), func():
			sim_asking = false
			season.skip_event()
			Session.autosave()
			flash = UiKit.t("Event simulated.") if season.last_emergency.is_empty() \
				else "Event simulated. " + season.last_emergency[0] + "."
			var warn := season.summer_warning()
			if not season.ground_ask().is_empty():
				ground_open = true
			if warn != "":
				flash = warn
			elif _levels_note() != "":
				flash = _levels_note()
			_rebuild(), "clock"))
	ui.add_child(UiKit.button(UiKit.t("Go back"), Vector2(SIM_CARD.position.x
		+ SIM_CARD.size.x - 248.0, SIM_CARD.position.y + SIM_CARD.size.y - 62.0),
		Vector2(220, 46), func():
			sim_asking = false
			_rebuild()))


func _draw_sim_ask() -> void:
	UiKit.panel(self, SIM_CARD)
	var o := String(season.world.clubs[season.opponent_id()]["name"]) \
		if season.opponent_id() >= 0 else UiKit.t("nobody yet")
	UiKit.text(self, font, UiKit.t("SIM THIS ONE?"), Vector2(SIM_CARD.position.x + 28.0,
		SIM_CARD.position.y + 46.0), 20, UiKit.YOU)
	UiKit.text(self, font, UiKit.t("The marshals run it without you. The result stands."),
		Vector2(SIM_CARD.position.x + 28.0, SIM_CARD.position.y + 76.0), 14, UiKit.INK)
	UiKit.text(self, font, UiKit.t("Your men still take the week: kit wears, the room moves."),
		Vector2(SIM_CARD.position.x + 28.0, SIM_CARD.position.y + 98.0), 14, UiKit.DIM)
	UiKit.text(self, font, UiKit.t("Against %s.") % o,
		Vector2(SIM_CARD.position.x + 28.0, SIM_CARD.position.y + 124.0), 14, UiKit.DIM)


## WHO HAS A LEVEL TO SPEND, for the message after a simmed week. "" if nobody.
func _levels_note() -> String:
	var who: Array[String] = []
	for f in season.club.roster:
		var n := Career.levels_banked(f)
		if n > 0:
			who.append(UiKit.t("%s +%d") % [f.display_name, n])
	if who.is_empty():
		return ""
	return UiKit.t("Levels to spend: %s. Tap a man, then His page.") % UiKit.t(", ").join(who.slice(0, 4))


func _fight_cup() -> void:
	var sim := season.begin_cup_bout()
	if sim == null:
		flash = UiKit.t("Nothing to fight.")
		_rebuild()
		return
	season.mark_bout_live(true)
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
		var league_week: bool = season.world.week_kind() == Calendar.Kind.LEAGUE
		season.skip_event()
		Session.autosave()
		flash = UiKit.t("Bye this event.") if league_week \
			else UiKit.t("A week of training. The squad is a little better for it.")
		if _levels_note() != "":
			flash = _levels_note()
		_rebuild()
		return
	## Save BEFORE handing over. The bout is a scene change and a few minutes of
	## play; a save taken only on the way back would lose the whole event if the
	## app went away mid-fight.
	season.mark_bout_live(false)
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
## -> SeasonSquadTab (season_tab_squad.gd)
static func _squad_key_y() -> float:
	return SeasonSquadTab._squad_key_y()


## -> SeasonSquadTab (season_tab_squad.gd)
func _squad_rows() -> Array:
	return SeasonSquadTab._squad_rows(self)




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
## -> SeasonSquadTab (season_tab_squad.gd)
func _reserve_sorted() -> Array:
	return SeasonSquadTab._reserve_sorted(self)


## -> SeasonSquadTab (season_tab_squad.gd)
func _squad_spread() -> String:
	return SeasonSquadTab._squad_spread(self)


## -> SeasonSquadTab (season_tab_squad.gd)
func _squad_controls() -> void:
	SeasonSquadTab._squad_controls(self)


## -> SeasonSquadTab (season_tab_squad.gd)
func _man_button(f: FighterCard, y: float, x: float) -> Button:
	return SeasonSquadTab._man_button(self, f, y, x)


## -> SeasonSquadTab (season_tab_squad.gd)
func _tap(f: FighterCard) -> void:
	SeasonSquadTab._tap(self, f)




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
	if club_menu_open:
		SeasonClubhouseTab._draw_club_menu(self)
		return
	if training_open:
		SeasonClubhouseTab._draw_training(self)
		return
	if help_key != "":
		SeasonClubhouseTab._draw_help(self)
		return
	if ground_open:
		SeasonClubTab._draw_ground(self)
		return
	if armorer_open:
		SeasonArmorerTab._draw_armorers(self)
		return
	if shop_open:
		## AND NOT THE TAB'S UNDERLINE EITHER. `_rebuild` stopped building the tab
		## buttons under the modal; this used to draw the gold bar that marks
		## which one is current, which left a three-pixel underline floating over
		## an empty row — a mark pointing at a control that is not there.
		_draw_shop()
		return
	## Button's own styling is the one thing here that is not mine to draw.
	## The slot, not the index: before bout one the Armorer's tab is not there.
	var slot := tab
	if not season.first_bout_done() and tab > Tab.MARKET:
		slot -= 1
	draw_rect(Rect2(24 + float(slot) * (TAB_W + 6.0), TAB_Y + TAB_H, TAB_W, 3), UiKit.YOU)
	if flash != "":
		## BY PIXELS, ACROSS THE WHOLE WIDTH, and smaller when it is long. It was
		## cut at 58 characters, which dropped the winter report off the end of
		## the season message and "who are in your division" off the split
		## warning — the two messages that most need reading.
		var room := UiKit.span()
		var px := 15 if font.get_string_size(flash, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15).x <= room else 12
		flash_px = px
		flash_room = room
	match tab:
		Tab.CLUB: _draw_club()
		Tab.SQUAD: _draw_squad()
		Tab.MARKET: _draw_market()
		Tab.OFFICE: _draw_office()
		Tab.FINANCES: _draw_finances()
	## THE MESSAGE IS A BAR OVER THE TAB, drawn last on its own ground (playtest
	## 30 Sep: it printed through "THE ARMORER" underneath it).
	if flash != "":
		var bar := Rect2(16, FLASH_Y - 17.0, UiKit.span() + 16.0, 24.0)
		draw_rect(bar, UiKit.PANEL)
		draw_rect(Rect2(bar.position, Vector2(3, bar.size.y)), UiKit.YOU)
		draw_rect(bar, UiKit.FRAME, false, 1.0)
		UiKit.text(self, font, UiKit.clip_px(font, flash, flash_px, flash_room - 8.0),
			Vector2(28, FLASH_Y), flash_px, UiKit.YOU)


func _header() -> void:
	var w: Dictionary = season.world.clubs[season.world.player_club]
	draw_rect(Rect2(0, 0, UiKit.screen().x, 62), UiKit.PANEL)
	UiKit.badge(self, Vector2(38, 31), 20, season.club.kit,
		season.club.icon_color, int(season.club.icon))
	## MEASURED AGAINST THE PURSE, which moved left for the Club button.
	var room := purse_box().position.x - 68.0 - 12.0
	UiKit.text(self, font, UiKit.clip_px(font, String(w["name"]), 20, room), Vector2(68, 28), 20, UiKit.INK)
	var sub := UiKit.t("%s  ·  Season %d  ·  rating %d") % [
		season.tier_name(), season.world.season, int(w["power"])]
	UiKit.text(self, font, UiKit.clip_px(font, sub, 14, room), Vector2(68, 50), 14, UiKit.DIM)
	## WHO RUNS IT (Pete, 1 Oct 2026: "You're not named").
	var sw := font.get_string_size(sub + "  ·  ", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x
	var who := UiKit.t("%s, level %d") % [season.coach.display_name, season.coach.level]
	if sw + 60.0 < room:
		UiKit.text(self, font, "  ·  ", Vector2(68 + font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14).x, 50), 14, UiKit.DIM)
		UiKit.text(self, font, UiKit.clip_px(font, who, 14, room - sw), Vector2(68 + sw, 50), 14, UiKit.YOU)
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
	## AND THE WAGES UNDER IT, the other currency, always in sight (review, 1 Oct
	## 2026: "$174 of $250" beside "37 CC" with nothing to say which is which).
	var bill := ClubOffice.wage_bill(season.club)
	var cap := season.office.cap()
	UiKit.text_fit(self, font, UiKit.t("%s/%s wages") % [ClubOffice.money(bill), ClubOffice.money(cap)],
		Vector2(purse_box().position.x + 18.0, 44.0), 12, UiKit.DOWN if bill > cap else UiKit.DIM,
		PURSE_W - 22.0)
	## LABELED (blind review, 29 Sep: "Good what?"). The squad's mood.
	UiKit.text(self, font, UiKit.t("SQUAD MOOD"), Vector2(UiKit.right_edge(194.0 + HEADER_SHIFT), 20), 12, UiKit.DIM)
	UiKit.text(self, font, season.office.morale_word(), Vector2(UiKit.right_edge(194.0 + HEADER_SHIFT), 40), 16,
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
	UiKit.text(self, font, line, Vector2((UiKit.screen().x - w) * 0.5, UiKit.screen().y - 3.0), 14, UiKit.BG)
## -> SeasonClubTab (season_tab_club.gd)
func _draw_club() -> void:
	SeasonClubTab._draw_club(self)


## -> SeasonClubTab (season_tab_club.gd)
func _schedule() -> void:
	SeasonClubTab._schedule(self)




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
	if _tape == "" or _tape_label == null:
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
	if flash != "" and Time.get_ticks_msec() - _flash_at > FLASH_MS:
		flash = ""
		queue_redraw()
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
## -> SeasonClubTab (season_tab_club.gd)
func _draw_dilemma() -> void:
	SeasonClubTab._draw_dilemma(self)




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
## -> SeasonClubTab (season_tab_club.gd)
func _fixture_title() -> String:
	return SeasonClubTab._fixture_title(self)


## -> SeasonClubTab (season_tab_club.gd)
func _fixture() -> void:
	SeasonClubTab._fixture(self)


## -> SeasonClubTab (season_tab_club.gd)
func _last_event() -> void:
	SeasonClubTab._last_event(self)


## -> SeasonClubTab (season_tab_club.gd)
func _table() -> void:
	SeasonClubTab._table(self)
## -> SeasonSquadTab (season_tab_squad.gd)
func _draw_squad() -> void:
	SeasonSquadTab._draw_squad(self)




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
## SIX FIELDS, NOT NINE (Pete, playtest 30 Sep #4: "too packed … everything
## kind of blends together"). The shirt number, age and weekly pay moved to the
## man's own page; the sheet keeps what a manager scans for: who, where, is
## his kit sound, how long is his deal, what is he and what could he be.
const SQUAD_W := 446.0
const COL_NAME := 10.0
## The budget, not a character count. `COL_POS` minus a gap.
const COL_NAME_W := 150.0
const COL_POS := 172.0
const COL_ARMOR := 262.0
const COL_YEARS := 322.0
const COL_RATING_TO := 404.0
const COL_RATING_BOX := 40.0
const COL_POT_TO := 438.0
const COL_POT_BOX := 24.0
## -> SeasonSquadTab (season_tab_squad.gd)
func _man_row(f: FighterCard, y: float, role: String, x: float) -> void:
	SeasonSquadTab._man_row(self, f, y, role, x)


## -> SeasonSquadTab (season_tab_squad.gd)
func squad_columns(f: Font, size_hint: int = 0) -> Array:
	return SeasonSquadTab.squad_columns(self, f, size_hint)




## HOW BIG THE HEADING TYPE IS. Small, and smaller than anything in the row it
## labels, because a heading that competes with its own data is a heading that
## makes the table harder to read rather than easier.
const SQUAD_HEAD_PX: int = 11
## -> SeasonSquadTab (season_tab_squad.gd)
func _squad_head(x: float, y: float) -> void:
	SeasonSquadTab._squad_head(self, x, y)




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
## THE CLUB WHOSE CARD IS OPEN on the Club tab (tap a row of the table), or -1.
var team_card: int = -1
## The confirm's own box. Same width as the shop's, because they are the same
## kind of thing and two modals at two sizes reads as two programs.
## Centred on the live canvas by `_centre_modals()` — fixed at x=200 they sat
## about 100 px left of centre on a 19.5:9 phone.
var SIM_CARD := Rect2(200.0, 150.0, 560.0, 240.0)

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

const QM_ROW := 29.0
const QM_TOP := 92.0
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
## -> SeasonSquadTab (season_tab_squad.gd)
func _qm_cell() -> float:
	return SeasonSquadTab._qm_cell(self)


## -> SeasonSquadTab (season_tab_squad.gd)
func _qm_rows() -> Array:
	return SeasonSquadTab._qm_rows(self)
## -> SeasonArmorerTab (season_tab_armorer.gd)
func _draw_market() -> void:
	SeasonArmorerTab._draw_market(self)


## -> SeasonArmorerTab (season_tab_armorer.gd)
func _market_controls() -> void:
	SeasonArmorerTab._market_controls(self)




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
	## PLACES ON THE BUS ARE GONE (Pete, 1 Oct 2026: "It should always be up to 8
	## fighters anyway"). INSURANCE is the federation now, all of it.
	{ "label": "TRAINING GROUND", "kind": ClubOffice.Facility.TRAINING },
	{ "label": "INFIRMARY", "kind": ClubOffice.Facility.INFIRMARY },
	{ "label": "INSURANCE", "kind": "insurance" },
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
var SHOP_CARD := Rect2(200.0, 120.0, 560.0, 300.0)
var CLUB_CARD := Rect2(200.0, 80.0, 560.0, 374.0)
var TRAIN_CARD := Rect2(150.0, 76.0, 660.0, 380.0)


func _centre_modals() -> void:
	var w := UiKit.screen().x
	SIM_CARD.position.x = floorf((w - SIM_CARD.size.x) * 0.5)
	SHOP_CARD.position.x = floorf((w - SHOP_CARD.size.x) * 0.5)
	CLUB_CARD.position.x = floorf((w - CLUB_CARD.size.x) * 0.5)
	TRAIN_CARD.position.x = floorf((w - TRAIN_CARD.size.x) * 0.5)
## -> SeasonClubhouseTab (season_tab_clubhouse.gd)
func _office_row_y(i: int) -> float:
	return SeasonClubhouseTab._office_row_y(self, i)


## -> SeasonClubhouseTab (season_tab_clubhouse.gd)
func _office_controls() -> void:
	SeasonClubhouseTab._office_controls(self)


## -> SeasonClubhouseTab (season_tab_clubhouse.gd)
func _offer(slot: int) -> Dictionary:
	return SeasonClubhouseTab._offer(self, slot)


## -> SeasonClubhouseTab (season_tab_clubhouse.gd)
func _shop_controls() -> void:
	SeasonClubhouseTab._shop_controls(self)


## -> SeasonClubhouseTab (season_tab_clubhouse.gd)
func _draw_shop() -> void:
	SeasonClubhouseTab._draw_shop(self)


## -> SeasonClubhouseTab (season_tab_clubhouse.gd)
func _draw_office() -> void:
	SeasonClubhouseTab._draw_office(self)



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
## -> SeasonFinancesTab (season_tab_finances.gd)
func _finances_controls() -> void:
	SeasonFinancesTab._finances_controls(self)


## -> SeasonFinancesTab (season_tab_finances.gd)
func _draw_finances() -> void:
	SeasonFinancesTab._draw_finances(self)


## -> SeasonFinancesTab (season_tab_finances.gd)
func _fin_row(label: String, now: int, was: int, y: float, col: Color, px: int = 13) -> void:
	SeasonFinancesTab._fin_row(self, label, now, was, y, col, px)


## -> SeasonFinancesTab (season_tab_finances.gd)
func _fin_rule(y: float) -> float:
	return SeasonFinancesTab._fin_rule(self, y)


## -> SeasonFinancesTab (season_tab_finances.gd)
func _fin_block(now: Dictionary, was: Dictionary, order: Array[String], y: float, col: Color) -> float:
	return SeasonFinancesTab._fin_block(self, now, was, order, y, col)


## -> SeasonFinancesTab (season_tab_finances.gd)
func _fin_ground() -> void:
	SeasonFinancesTab._fin_ground(self)


