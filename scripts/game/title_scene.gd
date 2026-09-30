extends Node2D
## The front door: three clubs, and which one you are running today.
##
## Retro Bowl's shell is one save and a straight PLAY. Three slots instead,
## because this game's whole arc is a club climbing a pyramid over many seasons
## and people run more than one — and because a slot list is where the save
## system becomes visible enough to be trusted.
##
## Every slot is read with SaveGame.peek(), which pulls a handful of denormalised
## fields off the front of the file. Rebuilding three worlds to draw three lines
## of text is exactly the kind of thing nobody notices until the phone takes a
## second to open the game.

## Landscape: the three slots stand side by side instead of stacked, which is
## what the shape of the screen wants and also what makes them read as a choice
## between clubs rather than as a list.
const SLOT_X := 24.0
## 124 (was 176): Back and Settings moved from the row above the slots to the
## bottom of the screen (Pete, 29 Sep 2026, #14 — Back bottom-left everywhere),
## so the slots take the row they left.
const SLOT_Y := 124.0
const SLOT_W := 300.0
## The Back / Settings row, between the tagline and the slots.
const HEADER_BTN_Y := 124.0
## 324 so the Delete row (SLOT_Y+276, 40 tall) sits inside the card with 8 to
## spare; at 300 it hung 16 pixels off the bottom (29 Sep 2026).
const SLOT_H := 324.0
const SLOT_GAP := 12.0

var font: Font
var ui: CanvasLayer
var slots: Array = []
var confirm_delete := -1
## One line under the slots — what happened to a save that would not open.
var notice: String = ""


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	## Coming back from a season means that season is over for now; the title
	## screen must not keep a stale world alive behind it.
	Session.season = null
	Session.clear_bout()
	ui = CanvasLayer.new()
	add_child(ui)
	_build()


# ---------------------------------------------------------------- the town
## PICK A TOWN BEFORE YOU PICK ANYTHING ELSE — Pete, 14 Sep 2026: *"we need to
## add the 'City' selectable for your team."*
##
## It goes here rather than on the Club tab because it is an identity decision
## and this is the one screen where a club does not exist yet. A relocation later
## is a different feature with a different price on it.
##
## TWELVE AT A TIME OUT OF FORTY-SIX, with a reroll, because a wall of
## forty-six towns is a list nobody reads and a decision nobody enjoys making.
## Every one of them is takeable: `take_city_for_player` trades, so whoever holds
## the town you want moves into the one you were going to have.
const CITY_COLS := 4
const CITY_ROWS := 3
const CITY_CARD := Vector2(204.0, 48.0)
## THE VERTICAL GAP CARRIES THE AREA LINE. At 12 there was nowhere to put it —
## drawn inside the card it is under a Button on a CanvasLayer and invisible, and
## drawn below it at 12 it touches the next row. The row pitch is what gives way.
const CITY_GAP := Vector2(12.0, 24.0)
const CITY_AREA_DROP := 15.0
const CITY_AT := Vector2(48.0, 214.0)

var picking: int = -1                  ## which save slot is being started, or -1
var offered: Array[String] = []
## WHICH MAP. Pete, 14 Sep 2026: *"have a little button for Europe with European
## cities for our international fans over there."* It is a property of the world,
## not of the club — see `Cities` — so it is chosen here, before anything exists.
var region: int = Cities.Region.US


func _offer_cities() -> void:
	var pool := Cities.names(region)
	pool.shuffle()
	offered.clear()
	for i in mini(CITY_COLS * CITY_ROWS, pool.size()):
		offered.append(String(pool[i]))


func _build_city_picker() -> void:
	for i in offered.size():
		var city := offered[i]
		var at := CITY_AT + Vector2(
			float(i % CITY_COLS) * (CITY_CARD.x + CITY_GAP.x),
			float(i / CITY_COLS) * (CITY_CARD.y + CITY_GAP.y))
		## THE STATE OR THE COUNTRY UNDER THE NAME, because "Portland" is two
		## cities and "Valencia" is a place in three countries. The line that
		## makes a city mean somewhere is the second one.
		var b := UiKit.button(city, at, CITY_CARD, func(c = city): _take_city(c))
		b.tooltip_text = Cities.full_name(city)
		ui.add_child(b)
	## THE MAP SWITCH, at the top where it changes what is under it. One button
	## that names the map you are NOT on, because a toggle labelled with the state
	## it is already in is the oldest bad button in software.
	var other: int = Cities.Region.EU if region == Cities.Region.US \
		else Cities.Region.US
	ui.add_child(UiKit.button(String(Cities.REGION_NAME[other]),
		Vector2(UiKit.screen().x - 48.0 - 240.0, CITY_AT.y - 54.0),
		Vector2(240, 40), func():
			region = other
			_offer_cities()
			_build()))
	var y := CITY_AT.y + float(CITY_ROWS) * (CITY_CARD.y + CITY_GAP.y) + 16.0
	ui.add_child(UiKit.button(UiKit.t("Show me others"), Vector2(CITY_AT.x, y),
		Vector2(280, 46), func():
			_offer_cities()
			_build()))
	ui.add_child(UiKit.button(UiKit.t("Anywhere will do"), Vector2(CITY_AT.x + 296, y),
		Vector2(280, 46), func():
			_take_city(offered[randi() % offered.size()])))
	## NOT AT (24, 96). That is the back button's home on every other screen and
	## on this one the title block is already there — it drew straight through
	## "Run a club. Take the list. Climb." A shared position is only shared where
	## the thing behind it is.
	ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(CITY_AT.x + 592.0, y),
		Vector2(200, 46), func():
			picking = -1
			_build()))


## THE SEASON IS BUILT FIRST AND THE TOWN APPLIED TO IT, rather than the town
## being handed to the constructor. `LeagueWorld` names forty-six clubs out of
## the same list, so a town cannot be reserved before the map exists — and after
## it exists the swap is one call.
func _take_city(city: String) -> void:
	var slot := picking
	picking = -1
	var s := Season.new(MeleeRosters.starting_club(), randi(), region)
	var err := s.set_city(city)
	if err != "":
		_build()
		return
	SaveGame.save(s, slot)
	_enter(s, slot)


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	if picking >= 0:
		_build_city_picker()
		queue_redraw()
		return
	slots.clear()
	var goes := {}
	for i in SaveGame.SLOTS:
		var info := SaveGame.peek(i)
		slots.append(info)
		var x := SLOT_X + float(i) * (SLOT_W + SLOT_GAP)
		if info.is_empty():
			ui.add_child(UiKit.button(UiKit.t("Start a club"), Vector2(x + 20, SLOT_Y + 216),
				Vector2(SLOT_W - 40, 52), _new_club.bind(i)))
		elif info.get("broken", false):
			ui.add_child(UiKit.button(UiKit.t("Set it aside"), Vector2(x + 20, SLOT_Y + 216),
				Vector2(SLOT_W - 40, 52), _set_aside.bind(i)))
		else:
			var go := UiKit.button(UiKit.t("Continue"), Vector2(x + 20, SLOT_Y + 216),
				Vector2(SLOT_W - 40, 52), _continue.bind(i))
			ui.add_child(go)
			goes[i] = go
			## The destructive half moves UP when armed, so the finger that
			## tapped Delete is not resting on the button that confirms it.
			if confirm_delete == i:
				ui.add_child(UiKit.danger(UiKit.button(UiKit.t("Delete it for good"),
					Vector2(x + 20, SLOT_Y + 216), Vector2(SLOT_W - 40, 46), _delete.bind(i))))
			else:
				ui.add_child(UiKit.danger(UiKit.button(UiKit.t("Delete"), Vector2(x + 20, SLOT_Y + 276),
					Vector2(SLOT_W - 40, 40), _delete.bind(i))))
	## THE CAREER YOU WERE PLAYING IS THE PRIMARY ACTION on this screen.
	if goes.has(_latest()):
		UiKit.primary(goes[_latest()])
	## Settings lives on the title screen rather than inside a season, because
	## the credits are in there and the licence for the menu music wants them
	## reachable without starting a club.
	## A ROW OF THEIR OWN (29 Sep 2026), under the tagline instead of beside it:
	## at y 96 Back sat level with the tagline, eighteen pixels from its first
	## letter. HEADER_BTN_Y still clears the slot panels at SLOT_Y.
	ui.add_child(UiKit.button(UiKit.t("Settings"), Vector2(UiKit.screen().x - 180, UiKit.screen().y - 56),
		Vector2(156, 44), _settings))
	ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(24, UiKit.screen().y - 56), Vector2(150, 44), func():
		UiKit.go("res://scenes/Start.tscn")))
	## A CANCEL, NOT A SECOND TAP ON THE SAME PIXEL. "Delete" became "Sure?" in
	## place, same rect, no way out — so a double-tap destroyed a career, which
	## is the exact failure the two-step was added to prevent. The confirm moves
	## and brings a Keep it with it.
	if confirm_delete != -1:
		var cx := SLOT_X + float(confirm_delete) * (SLOT_W + SLOT_GAP)
		ui.add_child(UiKit.button(UiKit.t("Keep it"), Vector2(cx + 20, SLOT_Y + 276),
			Vector2(SLOT_W - 40, 40), func():
				confirm_delete = -1
				_build()))
	queue_redraw()


## "just now", "20 minutes ago", "yesterday", "3 days ago". Both ends are read as
## the same local wall clock the save wrote, so the difference is true.
static func _ago(saved: String) -> String:
	if saved == "":
		return UiKit.t("some time ago")
	var then := Time.get_unix_time_from_datetime_string(saved)
	var now := Time.get_unix_time_from_datetime_string(Time.get_datetime_string_from_system(false))
	var mins := int(maxf(0.0, float(now - then)) / 60.0)
	if mins < 2:
		return UiKit.t("just now")
	if mins < 60:
		return UiKit.t("%d minutes ago") % mins
	var hours := mins / 60
	if hours < 24:
		return UiKit.t("1 hour ago") if hours == 1 else UiKit.t("%d hours ago") % hours
	var days := hours / 24
	return UiKit.t("yesterday") if days == 1 else UiKit.t("%d days ago") % days


## The slot saved most recently, or -1.
func _latest() -> int:
	var best := -1
	var best_t := ""
	for i in slots.size():
		var info: Dictionary = slots[i]
		if info.is_empty() or info.get("broken", false):
			continue
		var t := String(info.get("saved", ""))
		if best == -1 or t > best_t:
			best = i
			best_t = t
	return best


## BACK: out of the town picker, out of a delete confirm, else to the front door.
func go_back() -> bool:
	if picking >= 0:
		picking = -1
		_build()
		return true
	if confirm_delete != -1:
		confirm_delete = -1
		_build()
		return true
	UiKit.go("res://scenes/Start.tscn")
	return true


func _settings() -> void:
	UiKit.go("res://scenes/Settings.tscn")


func _new_club(slot: int) -> void:
	picking = slot
	_offer_cities()
	_build()


func _continue(slot: int) -> void:
	var s := SaveGame.load_slot(slot)
	if s == null:
		## SET ASIDE, NEVER DELETED. This used to delete the file — so a save from
		## a newer build, a torn write or a decoder bug erased a career on one
		## tap. The file is moved to `.bad-<time>`, the slot is freed, and the
		## player is told.
		_set_aside(slot)
		return
	_enter(s, slot)


func _set_aside(slot: int) -> void:
	SaveGame.quarantine(slot)
	notice = UiKit.t("Slot %d could not be opened. The file was kept aside, not deleted.") % (slot + 1)
	_build()


func _delete(slot: int) -> void:
	## Two taps, and the second one is on a button that has changed its own
	## label. A single-tap delete on a screen full of buttons will eventually eat
	## somebody's tenth season.
	if confirm_delete != slot:
		confirm_delete = slot
		_build()
		return
	SaveGame.delete(slot)
	confirm_delete = -1
	_build()


## THE ONE DOOR INTO A CAREER — new or continued, both come through here.
##
## Which makes it the only place a bought credit can be handed over. `Store`
## keeps money in a wallet outside every save, because a purchase is not
## attached to a save slot: a player can buy with nothing loaded, or buy while
## slot 1 is open and then play slot 2. It is claimed here, once, into whichever
## club he actually opens, and written to that slot immediately — a credit that
## is in the office and not in the file is a credit the next crash eats.
func _enter(s: Season, slot: int) -> void:
	Session.season = s
	## A career opens on its Club tab.
	SeasonScene.last_tab = SeasonScene.Tab.CLUB
	Session.slot = slot
	if slot >= 0:
		Store.claim(s.office, func() -> bool: return SaveGame.save(s, slot))
	## A CAREER OPENING CUTS THE TRAIL. Everything before this belongs to the
	## menus, and Back inside a club must never walk out of it into a slot list.
	UiKit.trail_reset()
	UiKit.go("res://scenes/Season.tscn")


## THE TITLE SCREEN ASKS FOR ITS OWN FRAMES, which nothing on it did before.
## `Juice` ticks whether or not anybody is watching, but a CanvasItem only
## redraws when something asks — the same fault the dilemma card's typewriter
## sat under for months. One screen, one line, and only while it is on top.
## Only when the breathing pixel actually moves (twice a second), not every
## frame — a still menu redrawing at the display's refresh rate costs battery.
var _last_lift: float = -999.0


func _process(_delta: float) -> void:
	if picking < 0:
		var lift := Juice.breathe(30)
		if lift != _last_lift:
			_last_lift = lift
			queue_redraw()


func _draw() -> void:
	## THE MENU IS ALWAYS THE MENU. The mood is static state on UiKit, so a player
	## who quits out of a Worlds final and lands back here would otherwise find
	## the title screen still wearing the boss palette — which reads as the game
	## having broken rather than as a theme.
	UiKit.set_mood(UiKit.Mood.NORMAL)
	UiKit.ground(self, false)
	## ONE PIXEL, EVERY HALF SECOND, ON THE CREST AND THE SECOND WORD.
	##
	## `Juice.breathe()` is the whole of the idle-motion rule — *nothing in a
	## retro game is ever completely still, and two pixels is a wobble and a
	## wobble is a bug* — and it had no caller anywhere. The title screen is the
	## one screen a player looks at without doing anything, so a title screen
	## that is perfectly still is the one place the game can look crashed.
	##
	## The crest and BUHURT move together and RETRO does not, so the two words
	## breathe against each other rather than the whole block sliding, which is
	## the difference between a logo with life in it and a logo that is loose.
	var lift := Juice.breathe(30)
	## THE CREST, NOT THE WHOLE LOCKUP. This is a header, not a splash.
	##
	## The full mark went here first, at 132 tall from y=18 — and ran straight
	## through the Back button, which has sat at (24, 96) since the day it was
	## added. The front door is where the lockup belongs and it has it; a screen
	## with a list of save slots on it wants the mark at the size of a heading.
	##
	## So the shape of the old header is kept exactly — mark, then two words, at
	## the same three x positions — and only the primitive badge is replaced by
	## the real crest. The breathe still lifts the mark and the second word
	## against a still first word, which is what made the pair read as alive.
	if not Brand.draw_logo(self, Brand.CREST_SMALL, Vector2(26, 26 - lift)):
		UiKit.badge(self, Vector2(60, 78 - lift), 38,
			IconBank.KIT_COLORS[0], IconBank.MARK_COLORS[0], 5)
	## THE SECOND WORD IS PLACED OFF THE FIRST, MEASURED.
	##
	## "RETRO" and "BUHURT" were at 118 and 268 — two literals that added up to a
	## word gap only because somebody had looked at them. "8-BIT" is four glyphs
	## and a hyphen where "RETRO" was five letters, so the day the name changed
	## the pair printed as `8-BITBUHURT`. The font knows how wide the first word
	## is; asking it is one call and it cannot go stale.
	var one := "8-BIT"
	UiKit.text(self, font, one, Vector2(118, 72), 42, UiKit.INK)
	var two_x := 118.0 + font.get_string_size(one, HORIZONTAL_ALIGNMENT_LEFT,
		-1.0, 42).x + 18.0
	UiKit.text(self, font, UiKit.t("BUHURT"), Vector2(two_x, 72 - lift), 42, UiKit.YOU)
	## UNDER THE WORDMARK. It once started at 120, underneath the Back button
	## (then at 24, 96), and was moved to 180 — still level with the button and
	## eighteen pixels off it. The buttons have their own row now (HEADER_BTN_Y),
	## so the line sits where the eye expects it, under "8-BIT".
	UiKit.text_fit(self, font, UiKit.t("Run a club. Take the list. Climb."),
		Vector2(118, 102), 16, UiKit.DIM, UiKit.screen().x - 118.0 - 24.0)

	if picking >= 0:
		## THE PANEL IS DERIVED FROM THE GRID IT HOLDS, not written down — the
		## first figure was 284 and the bottom edge ran through the middle of the
		## two buttons under the towns.
		var rows := float(CITY_ROWS) * (CITY_CARD.y + CITY_GAP.y)
		UiKit.panel(self, Rect2(CITY_AT - Vector2(24, 64),
			Vector2(UiKit.screen().x - (CITY_AT.x - 24) * 2.0, 64 + rows + 82)))
		UiKit.text(self, font, UiKit.t("WHERE ARE YOU FROM?"),
			Vector2(CITY_AT.x, CITY_AT.y - 34), 20, UiKit.YOU)
		UiKit.text(self, font,
			"Your town names the club, and it is where you play at home.",
			Vector2(CITY_AT.x, CITY_AT.y - 12), 13, UiKit.DIM)
		## THE AREA UNDER EACH NAME. Drawn rather than put in the button, because
		## a two-line button either clips the second line or shrinks the first,
		## and the first is the one being chosen.
		for i in offered.size():
			var at := CITY_AT + Vector2(
				float(i % CITY_COLS) * (CITY_CARD.x + CITY_GAP.x),
				float(i / CITY_COLS) * (CITY_CARD.y + CITY_GAP.y))
			UiKit.right(self, font, Cities.area_of(offered[i]),
				at + Vector2(CITY_CARD.x - 6.0, CITY_CARD.y + CITY_AREA_DROP),
				11, UiKit.DIM, CITY_CARD.x - 12.0)
		return

	for i in slots.size():
		var x := SLOT_X + float(i) * (SLOT_W + SLOT_GAP)
		UiKit.panel(self, Rect2(x, SLOT_Y, SLOT_W, SLOT_H))
		var info: Dictionary = slots[i]
		if info.get("broken", false):
			UiKit.text(self, font, UiKit.t("SLOT %d") % (i + 1), Vector2(x + 20, SLOT_Y + 34), 15, UiKit.DIM)
			UiKit.text(self, font, UiKit.t("Can't open"), Vector2(x + 20, SLOT_Y + 70), 24, UiKit.DOWN)
			UiKit.text(self, font, UiKit.t("This file is damaged or from"), Vector2(x + 20, SLOT_Y + 106), 14, UiKit.DIM)
			UiKit.text(self, font, UiKit.t("a newer version of the game."), Vector2(x + 20, SLOT_Y + 126), 14, UiKit.DIM)
			continue
		if info.is_empty():
			UiKit.text(self, font, UiKit.t("SLOT %d") % (i + 1), Vector2(x + 20, SLOT_Y + 34), 15, UiKit.DIM)
			UiKit.text(self, font, UiKit.t("Empty"), Vector2(x + 20, SLOT_Y + 70), 24, UiKit.DIM)
			UiKit.para(self, font, UiKit.t("A new club starts in the Backyard Circuit."),
				Vector2(x + 20, SLOT_Y + 106), 14, UiKit.DIM, SLOT_W - 40.0, 20.0)
			continue
		UiKit.text(self, font, UiKit.t("SLOT %d") % (i + 1), Vector2(x + 20, SLOT_Y + 34), 15, UiKit.DIM)
		## CLIPPED BY PIXELS, into a box that is measured in pixels. It was
		## twenty characters, and "Detroit Free Company" is exactly twenty — 291
		## of them at this size, into a card that has 280.
		UiKit.text(self, font,
			UiKit.clip_px(font, String(info["club"]), 21, SLOT_W - 40.0),
			Vector2(x + 20, SLOT_Y + 72), 21, UiKit.INK)
		UiKit.text(self, font, UiKit.t(String(info["tier"])), Vector2(x + 20, SLOT_Y + 102), 15, UiKit.YOU)
		UiKit.text(self, font, UiKit.t("Season %d") % int(info["season"]),
			Vector2(x + 20, SLOT_Y + 130), 15, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("Event %d of %d") % [int(info["event"]), int(info["events"])],
			Vector2(x + 20, SLOT_Y + 152), 15, UiKit.DIM)
		## HOW LONG AGO, NOT A TIMESTAMP (blind review, 29 Sep), and which slot
		## was played last.
		UiKit.text(self, font, UiKit.t("Played %s") % _ago(String(info["saved"])),
			Vector2(x + 20, SLOT_Y + 186), 13, UiKit.DIM)
		if i == _latest():
			UiKit.right(self, font, UiKit.t("LAST PLAYED"), Vector2(x + SLOT_W - 20, SLOT_Y + 34), 12, UiKit.YOU, 160)
	if notice != "":
		UiKit.text(self, font, notice, Vector2(SLOT_X, SLOT_Y + SLOT_H + 28), 14, UiKit.DOWN)
