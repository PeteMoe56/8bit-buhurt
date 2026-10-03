extends Node2D
## THE STAFF ROOM. Two captains, what each of them teaches, and how hard he
## works the men he teaches.
##
## The regime was three words on the Office tab for days: drawn, never settable,
## read by nothing. It is now the sharpest decision on this screen — see
## `ClubOffice.Regime`, whose numbers are Retro Bowl's own, read out of the
## shipped build rather than invented.

const CARD_W := 218.0
## THE ARMORER'S ROW, between the captains and the coverage line.
const ARM_Y := 284.0
const CARD_H := 124.0
const CUR_Y := 96.0
const OFFER_X := 496.0
const OFFER_W := 200.0
const OFFER_H := 126.0

var font: Font
var ui: CanvasLayer
var season: Season
var flash: String = ""
## WHAT KIND OF LINE IT IS. Everything here was drawn in the refusal color, so
## "A week's work in one afternoon." read as an error. 0 a refusal, 1 good news,
## 2 a question (a two-tap confirm).
var flash_tone: int = 0
## THE CAPTAIN MARKET is open (playtest 30 Sep #13).
var browsing := false
const LIST := Rect2(40.0, 60.0, 880.0, 420.0)
const LIST_ROW := 44.0


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	season = Session.season
	ui = CanvasLayer.new()
	add_child(ui)
	## CENTRED ON A WIDE PHONE (2 Oct 2026 playtest): see `UiKit.frame`.
	UiKit.frame(self, ui)
	if Session.staff_browse:
		Session.staff_browse = false
		browsing = true
	_build()


## Who is available — one list, in ClubOffice, read by both screens that sell
## captains.
func _offer(slot: int) -> Dictionary:
	return season.staff_offer(slot)


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	if season == null:
		return
	## THE LIST OWNS THE SCREEN while it is open (Pete, 1 Oct: the gold "Find a
	## captain" buttons sat on top of it). A scrim cannot cover a Button, so the
	## room's buttons are simply not built.
	if browsing:
		_market_controls()
		queue_redraw()
		return
	var o := season.office
	for i in ClubOffice.MAX_CAPTAINS:
		var x := 24.0 + float(i) * (CARD_W + 16.0)
		if i < o.captains.size():
			## THE REGIME MOVED TO THE TRAINING POPUP (Pete, 1 Oct 2026); the
			## room keeps hiring, keeping and letting go.
			## KEEP HIM, or let the deal run out. Two controls where there was one,
			## because a captain you cannot re-sign is a captain you are only ever
			## losing.
			var half := (CARD_W - 6.0) / 2.0
			## "+1 yr · 3 CC", and Release in the destructive style, two taps
			## (round 4: "· 3" had no unit and Release looked like its neighbour).
			## RELEASE STANDS OFF (round 8: "right next to +1 yr").
			## A VERB ON EACH (round 9: "+1 yr" needed one), Release narrower and
			## apart so both read at the same size.
			## 116 AND 92, 8 apart (round 2, 2 Oct: at 92 the Extend label shrank to a squint).
			var ext := UiKit.button(UiKit.t("Extend · %d CC") % ClubOffice.extend_cost(season.office.captains[i]),
				Vector2(x, CUR_Y + CARD_H + 8.0), Vector2(CARD_W - 100.0, 38), _extend.bind(i))
			ext.disabled = ClubOffice.extend_cost(season.office.captains[i]) > season.office.credits
			ui.add_child(ext)
			ui.add_child(UiKit.danger(UiKit.button(UiKit.t("Release"), Vector2(x + CARD_W - 92.0, CUR_Y + CARD_H + 8.0),
				Vector2(92, 38), _release.bind(i))))
		else:
			## THE MARKET, NOT ONE MAN AND A REROLL.
			ui.add_child(UiKit.primary(UiKit.button(UiKit.t("Find a captain"),
				Vector2(x, CUR_Y + CARD_H + 8.0), Vector2(CARD_W, 42), func():
					browsing = true
					flash = ""
					_build(), "helm")))
	## THE ARMORER IS STAFF TOO: his card, and the door to the list.
	ui.add_child(UiKit.button(UiKit.t("Armorers"), Vector2(24.0 + CARD_W + 16.0, ARM_Y + 14.0), Vector2(CARD_W, 40),
		func():
			Session.open_armorers = true
			SeasonScene.last_tab = SeasonScene.Tab.MARKET
			Session.autosave()
			UiKit.go("res://scenes/Season.tscn"), "anvil"))
	ui.add_child(UiKit.back_button("res://scenes/Season.tscn"))
	queue_redraw()


## THE CAPTAIN MARKET: a modal list over the staff room, one Hire per man.
func _market_controls() -> void:
	## A full-screen catch so the room under the list cannot be tapped.
	var catch_ := Button.new()
	catch_.flat = true
	catch_.position = Vector2.ZERO
	catch_.position = UiKit.full_rect().position
	catch_.size = UiKit.full_rect().size
	catch_.focus_mode = Control.FOCUS_NONE
	ui.add_child(catch_)
	var pool := season.staff_pool()
	for i in pool.size():
		var c: Dictionary = pool[i]
		var price := ClubOffice.cost_of(c)
		var b := UiKit.button(UiKit.t("Hire · %d CC") % price,
			Vector2(LIST.end.x - 150.0, LIST.position.y + 56.0 + float(i) * LIST_ROW - 4.0),
			Vector2(136, 38), func(cap = c):
				flash_tone = 0
				flash = UiKit.said(season.hire_captain(cap))
				if flash == "":
					flash = UiKit.t("%s joins the staff.") % String(cap.get("name", ""))
					flash_tone = 1
					browsing = false
				Session.autosave()
				_build())
		b.disabled = price > season.office.credits or season.office.captains.size() >= ClubOffice.MAX_CAPTAINS
		ui.add_child(b)
	var close_b := UiKit.button("", Vector2(LIST.end.x - 52.0, LIST.position.y + 8.0), Vector2(44, 40), func():
		browsing = false
		_build(), "close")
	close_b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ui.add_child(close_b)


func _draw_market() -> void:
	draw_rect(UiKit.full_rect(), Color(0, 0, 0, 0.74))
	UiKit.ledger_cover()
	UiKit.panel(self, LIST)
	UiKit.text(self, font, UiKit.t("CAPTAINS FOR HIRE"), LIST.position + Vector2(20, 32), 18, UiKit.YOU)
	UiKit.text(self, font, UiKit.t("This season's list. More stars teach more roles, better."),
		LIST.position + Vector2(260, 32), 13, UiKit.DIM)
	var pool := season.staff_pool()
	for i in pool.size():
		var c: Dictionary = pool[i]
		var y := LIST.position.y + 80.0 + float(i) * LIST_ROW
		if i % 2 == 0:
			draw_rect(Rect2(LIST.position.x + 8.0, y - 26.0, LIST.size.x - 16.0, LIST_ROW - 2.0), UiKit.BG)
		UiKit.text_fit(self, font, String(c.get("name", "?")), Vector2(LIST.position.x + 20, y), 15, UiKit.INK, 130.0)
		UiKit.stars(self, Vector2(LIST.position.x + 160, y - 12.0), int(c.get("grade", 1)) * 20, UiKit.YOU, 11.0, 3.0)
		UiKit.text_fit(self, font, _roles_of(c), Vector2(LIST.position.x + 240, y), 14, UiKit.DIM, 200.0)
		var t := ClubOffice.trait_of(c)
		UiKit.text_fit(self, font, UiKit.t(String(ClubOffice.TRAIT_NAME[t])) if t != ClubOffice.Trait.NONE else "—",
			Vector2(LIST.position.x + 460, y), 14, UiKit.UP if t != ClubOffice.Trait.NONE else UiKit.DIM, 240.0)


func _hire(slot: int) -> void:
	flash_tone = 0
	flash = UiKit.said(season.hire_captain(_offer(slot)))
	Session.autosave()
	_build()


func _extend(i: int) -> void:
	flash_tone = 0
	flash = UiKit.said(season.office.extend_captain(i))
	Session.autosave()
	_build()


func _refresh() -> void:
	flash_tone = 0
	flash = UiKit.said(season.office.refresh_staff())
	Session.autosave()
	_build()


func _release(i: int) -> void:
	if not UiKit.confirm("captain:%d" % i):
		flash = UiKit.t("Tap Release again to let him go.")
		flash_tone = 2
		_build()
		return
	season.office.release(i)
	Audio.play("confirm")
	Session.autosave()
	_build()


func _draw() -> void:
	if season == null:
		return
	UiKit.set_mood(season.mood())
	UiKit.ground(self)
	var o := season.office
	UiKit.text(self, font, UiKit.t("THE STAFF"), Vector2(24, 46), 26, UiKit.INK)
	UiKit.purse(self, font, o.credits, Vector2(UiKit.screen().x - 24, 46),
		18, UiKit.YOU, 200)
	UiKit.text(self, font, UiKit.t("YOUR CAPTAINS"), Vector2(24, 78), 12, UiKit.DIM)

	for i in ClubOffice.MAX_CAPTAINS:
		var x := 24.0 + float(i) * (CARD_W + 16.0)
		var r := Rect2(x, CUR_Y, CARD_W, CARD_H)
		if i < o.captains.size():
			var c: Dictionary = o.captains[i]
			var reg := int(c.get("regime", ClubOffice.Regime.NORMAL))
			UiKit.card(self, font, r, {
				"tag": _roles_of(c), "name": String(c["name"]),
				"rating": int(c["grade"]) * 20,
				"band": UiKit.SELECT,
				## THE REGIME AND THE YEARS LEFT ON HIS DEAL, together, because they
				## are the two things about a hired captain that change.
				"foot": UiKit.t("%s  ·  %dy") % [UiKit.t(String(ClubOffice.REGIME_NAME[reg])),
					int(c.get("years", ClubOffice.CAPTAIN_YEARS))],
				"foot_col": UiKit.DOWN if int(c.get("years", 9)) <= 1 else _regime_color(reg),
				"head_frac": 0.2,
			}, true)
		else:
			## AN EMPTY SLOT IS THE STRONGEST THING ON THIS SCREEN. A club with
			## one captain teaches at most two of the three jobs, and the third
			## is a role nobody on your line is being shown how to fight.
			UiKit.panel(self, r)
			UiKit.text(self, font, UiKit.t("NO CAPTAIN"), r.position + Vector2(14, 34), 14, UiKit.DOWN)
			UiKit.para(self, font, UiKit.t("An empty chair. Nobody teaches the roles he would cover."),
				r.position + Vector2(14, 62), 13, UiKit.DIM, r.size.x - 28.0, 17.0, 3)

	_coverage()
	_trait_word()
	_armorer_card()
	if flash != "":
		UiKit.text(self, font, flash, Vector2(24, UiKit.screen().y - 70), 13,
			[UiKit.DOWN, UiKit.UP, UiKit.YOU][flash_tone])
	if browsing:
		_draw_market()


func _roles_of(c: Dictionary) -> String:
	return ClubOffice.teaches_line(c)


## WHAT ELSE EACH MAN BRINGS. A trait drawn as a name is a word on a card; the
## blurb is the reason to prefer a three-star Physio to a four-star who teaches
## the same two jobs, and that comparison is the whole point of the screen.
## DRAWN UNDER THE REGIME PANEL, ON THE RIGHT, and not under the captain cards.
##
## The first version put each man's trait under his own card at `SCREEN.y - 96`,
## which is a clean idea and put it straight through `_coverage()` — "Physio"
## printed on top of "Rail / Hard" and "Motivator" through "nobody teaches it".
## Two functions placing text at absolute positions on the same screen is exactly
## the collision this project already keeps a check for on the roster cards, and
## the left column below 390 already belonged to the coverage row.
##
## The right column under the regime panel is empty and 440px wide, which is also
## room for the whole sentence rather than thirty characters of it.
func _trait_word() -> void:
	var o := season.office
	var y := CUR_Y + 20.0
	UiKit.text(self, font, UiKit.t("WHAT ELSE THEY BRING"), Vector2(OFFER_X, y), 12, UiKit.DIM)
	y += 24.0
	var said := 0
	for i in ClubOffice.MAX_CAPTAINS:
		if i >= o.captains.size():
			continue
		var c: Dictionary = o.captains[i]
		var t := ClubOffice.trait_of(c)
		if t == ClubOffice.Trait.NONE:
			continue
		said += 1
		UiKit.text(self, font, UiKit.t("%s  ·  %s") % [String(c.get("name", "?")),
			UiKit.t(String(ClubOffice.TRAIT_NAME[t]))], Vector2(OFFER_X, y), 14, UiKit.UP)
		UiKit.text(self, font, UiKit.t(String(ClubOffice.TRAIT_BLURB[t])),
			Vector2(OFFER_X, y + 16.0), 11, UiKit.EDGE.lightened(0.5))
		y += 40.0
	if said == 0:
		UiKit.text(self, font, UiKit.t("Neither of them brings anything but the coaching."),
			Vector2(OFFER_X, y), 14, UiKit.EDGE.lightened(0.5))


func _regime_color(r: int) -> Color:
	match r:
		ClubOffice.Regime.LIGHT: return UiKit.UP
		ClubOffice.Regime.HARD: return UiKit.DOWN
		_: return UiKit.YOU


## WHICH OF THE THREE JOBS NOBODY IS TEACHING, and which one the club is known
## for. Two five-star captains give four slots over three roles, so a top staff
## always overlaps — and that overlap is the SPECIALTY, the job this place turns
## men out in faster than anybody. The screen called it waste for a week.
func _coverage() -> void:
	var o := season.office
	## ON ITS OWN LINE, IN THE LEFT COLUMN.
	##
	## The club specialty was drawn at x=300 beside the heading, which is fine
	## until the right column has anything in it below the regime panel — and then
	## "trains ×1.25" prints through "His men come out of the corner with more
	## left." That is the third absolute-position collision on this one screen, so
	## the rule it now follows is simple enough to keep: **the left column ends at
	## 480 and the right begins at 496**, and nothing reaches across.
	var y := 378.0
	UiKit.text(self, font, UiKit.t("WHAT IS BEING TAUGHT"), Vector2(24, y), 12, UiKit.DIM)
	y += 20.0
	var spec := o.club_specialty()
	if spec >= 0:
		UiKit.text(self, font, UiKit.t("Club specialty: %s, training ×%.2f")
			% [UiKit.t(String(Tuning.ROLE_NAME[spec])), ClubOffice.SPECIALTY_XP],
			Vector2(24, y), 14, UiKit.UP)
	elif o.presence() > 0.0:
		UiKit.text(self, font, UiKit.t("No specialty — but the room is a happier one."),
			Vector2(24, y), 14, UiKit.YOU)
	y += 24.0
	var roles := [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]
	for i in roles.size():
		var role: int = roles[i]
		var taught: bool = o.taught(role)
		var is_spec: bool = role == spec
		var x := 24.0 + float(i) * 150.0
		UiKit.text(self, font, UiKit.t(String(Tuning.ROLE_NAME[role])), Vector2(x, y), 15,
			(UiKit.UP if is_spec else UiKit.INK) if taught else UiKit.DOWN)
		var line := UiKit.t("nobody teaches it")
		if taught:
			line = UiKit.t(String(ClubOffice.REGIME_NAME[o.regime_for(role)]))
			if is_spec:
				line += UiKit.t("  ·  specialty")
		UiKit.text(self, font, line, Vector2(x, y + 20), 12,
			(UiKit.UP if is_spec else _regime_color(o.regime_for(role))) if taught else UiKit.DOWN)



func _armorer_card() -> void:
	var a: Dictionary = season.office.armorer
	## 74 TALL (review, 2 Oct: "Makes up to Rust" sat on the bottom edge at 68).
	var r := Rect2(24, ARM_Y, CARD_W, 74)
	UiKit.panel(self, r)
	UiKit.text(self, font, UiKit.t("ARMORER"), r.position + Vector2(12, 18), 11, UiKit.DIM)
	UiKit.text_fit(self, font, String(a.get("name", "")), r.position + Vector2(12, 41), 16, UiKit.INK, 130.0)
	UiKit.stars(self, r.position + Vector2(150, 30), int(a.get("stars", 1)) * 20, UiKit.YOU, 10.0, 2.0)
	UiKit.text_fit(self, font, UiKit.t("Makes up to %s") % Armorer.metal_name(Armorer.cap_of(a)),
		r.position + Vector2(12, 61), 12, UiKit.DIM, CARD_W - 24.0)
