extends Node2D
## THE ROSTER, and it is laid out like the sport rather than like a list.
##
## Retro Bowl puts ten cards in a flat 2x5 grid and lets a position badge carry
## the meaning, because in football the five men on a line are not standing in a
## meaningful left-to-right order. **In buhurt they are.** Rail, Flanker, Center,
## Flanker, Rail is a real arrangement on a real line, and a roster screen that
## scrambles it throws away the one piece of information the player is about to
## make a decision with.
##
## So: the five on the line across the top, in the order they stand. Then the
## three on the bench and the five in reserve underneath, smaller, because that
## is exactly how much they matter today.

const CARD_W := 176.0
const CARD_H := 168.0
const CARD_GAP := 10.0
const LINE_Y := 92.0
const SMALL_W := 108.0
const SMALL_H := 104.0
const SMALL_GAP := 8.0
const SMALL_Y := 288.0

var font: Font
var ui: CanvasLayer
var season: Season
var flash: String = ""


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	season = Session.season
	ui = CanvasLayer.new()
	add_child(ui)
	_build()


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	if season == null:
		return
	for slot in _slots():
		var f: FighterCard = slot["card"]
		var r: Rect2 = slot["rect"]
		var b := UiKit.button("", r.position, r.size, _open.bind(f))
		## The card is drawn; the button is the hit box over it. Two things in
		## one place, and the alternative is hit boxes computed by a second
		## function that drifts from the first — which this project has already
		## paid for once, 22 pixels apart.
		b.flat = true
		b.modulate = Color(1, 1, 1, 0)
		ui.add_child(b)
	ui.add_child(UiKit.back_button("res://scenes/Season.tscn"))
	## TABLE | CARDS (Pete, 29 Sep 2026: Squad and Roster are one screen). This is
	## the Cards view; Table is the Squad tab.
	ui.add_child(UiKit.button(UiKit.t("Table"), Vector2(UiKit.screen().x - 24.0 - 150.0 - 256.0, 14.0),
		Vector2(120, 44), func():
			SeasonScene.last_tab = SeasonScene.Tab.SQUAD
			UiKit.go("res://scenes/Season.tscn"), "roster"))
	ui.add_child(UiKit.selected(UiKit.button(UiKit.t("Cards"), Vector2(UiKit.screen().x - 24.0 - 150.0 - 128.0, 14.0),
		Vector2(120, 44), func(): pass, "roster")))
	queue_redraw()


## Every card on the screen and where it goes. One list, so the drawing and the
## hit boxes cannot disagree about where a man is.
func _slots() -> Array:
	var out: Array = []
	if season == null:
		return out
	var line := season.club.starting_five()
	var total_w := 5.0 * CARD_W + 4.0 * CARD_GAP
	var x0 := (UiKit.screen().x - total_w) * 0.5
	for i in line.size():
		out.append({"card": line[i], "kind": "line",
			"rect": Rect2(x0 + float(i) * (CARD_W + CARD_GAP), LINE_Y, CARD_W, CARD_H)})
	var rest: Array = []
	for f in season.club.active_eight():
		if not line.has(f):
			rest.append({"card": f, "kind": "bench"})
	for f in season.club.reserves():
		rest.append({"card": f, "kind": "reserve"})
	var sw := float(rest.size()) * SMALL_W + float(maxi(0, rest.size() - 1)) * SMALL_GAP
	var sx := (UiKit.screen().x - sw) * 0.5
	for i in rest.size():
		var e: Dictionary = rest[i]
		e["rect"] = Rect2(sx + float(i) * (SMALL_W + SMALL_GAP), SMALL_Y, SMALL_W, SMALL_H)
		out.append(e)
	return out


func _open(f: FighterCard) -> void:
	Session.viewing_fighter = f
	UiKit.go("res://scenes/Fighter.tscn")


func _draw() -> void:
	if season == null:
		return
	UiKit.set_mood(season.mood())
	Audio.for_mood(UiKit.mood, false)
	UiKit.ground(self)

	UiKit.text(self, font, UiKit.t("SQUAD"), Vector2(24, 46), 26, UiKit.INK)
	UiKit.purse(self, font, season.office.credits,
		Vector2(UiKit.screen().x - 24, 46), 18, UiKit.YOU, 200)
	UiKit.text(self, font, UiKit.t("THE LINE"), Vector2(24, 78), 12, UiKit.DIM)

	for slot in _slots():
		var f: FighterCard = slot["card"]
		var r: Rect2 = slot["rect"]
		if String(slot["kind"]) == "line":
			_card(f, r, true)
		else:
			_card(f, r, false)

	## The label for the second row goes between the rows rather than above the
	## first of them, because a header that sits over the first card reads as
	## that card's title.
	UiKit.text(self, font, UiKit.t("THE BENCH AND THE RESERVE"),
		Vector2(24, SMALL_Y - 12), 12, UiKit.DIM)
	_footer()


## ONE CARD. `big` is the line; the rest are the same card with the detail that
## does not survive the size taken out — the portrait block and the stars go,
## the position, the name, the rating and the condition stay, because those four
## are what the player is scanning for.
## The roster's card is `UiKit.card` with the roster's facts in it. It was this
## screen's own function until the market and the staff room needed the same
## card; one copy, three callers.
func _card(f: FighterCard, r: Rect2, big: bool) -> void:
	var out: bool = not f.fit()
	var d := {
		"tag": f.pos_name(), "number": f.number, "name": f.display_name,
		"rating": f.overall(), "dim": out,
		"band": UiKit.pos_color(f),
		"face": {"rating": f.overall(), "name": f.display_name, "number": f.number},
		## THE ARMOR BAR IS NOW A PASS/FAIL, not a mood ring. It used to redden
		## below 0.4, which was a number picked to look about right; it reddens at
		## the inspection line now, because that is where the harness stops being
		## worn and starts being a reason he cannot fight.
		"bar": f.armor,
		"bar_col": UiKit.DOWN if not f.passes_inspection() else UiKit.UP,
	}
	if big:
		var flag := f.morale_flag()
		d["rating_word"] = true
		d["note"] = (UiKit.t("age %d  ·  %s") % [f.age, flag]) if flag != "" \
			else (UiKit.t("age %d") % f.age)
		## A man at his ceiling has nowhere to go, and that is worth seeing on
		## the card rather than two taps away — it is the whole reason to prefer
		## a 39 who can reach 60 over a 45 who cannot.
		d["right_note"] = UiKit.t("capped") if f.headroom() <= 0 else UiKit.t("to %d") % f.potential
		d["right_col"] = UiKit.EDGE.lightened(0.5) if f.headroom() <= 0 else UiKit.UP
		## On the star row, as the market does, so the note line keeps its whole
		## width at the 11-pixel floor (#15) — sharing it left "51 · age ." cut.
		d["right_note_up"] = true
	UiKit.card(self, font, r, d, big)
	## THE INSPECTION LINE, drawn ON the armor bar. A threshold you cannot see is
	## a threshold the player discovers by being refused, and this one decides
	## whether he has five men.
	var bar := Rect2(r.position.x + 6, r.end.y - 18, r.size.x - 12, 12)
	var tick := bar.position.x + bar.size.x * FighterCard.INSPECTION_MIN
	draw_rect(Rect2(tick, bar.position.y - 2.0, 1.0, bar.size.y + 4.0),
		UiKit.EDGE.lightened(0.8))
	## THE BAR SAYS WHAT IT IS (item 2: "the bar on each card has no label").
	UiKit.right(self, font, UiKit.t("kit %d%%") % int(round(f.armor * 100.0)),
		Vector2(bar.end.x, bar.position.y - 4.0), 12,
		UiKit.DOWN if not f.passes_inspection() else UiKit.DIM, bar.size.x)
	## A MOOD YOU CAN SEE WHILE SCANNING. The word only fits on the big card, and
	## a toxic man you find by tapping into him is a man you find after he has
	## already cost you the weekend — so the stripe is on every size. It runs down
	## the left edge, which is the one part of this card nothing else uses.
	if f.angry():
		draw_rect(Rect2(r.position.x, r.position.y, 4.0, r.size.y), f.morale_color())
	## WHY HE IS NOT PLAYING, in his own words, rather than "OUT 2" for every
	## reason there is. Three different problems with three different answers: a
	## knock waits, a harness is a trip to the workshop, and a man who cannot get
	## the weekend off is why you bought a bench.
	if out:
		UiKit.right(self, font, f.unfit_reason().to_upper(),
			Vector2(r.end.x - 8, r.end.y - 24), 11, UiKit.DOWN, 96)


func _footer() -> void:
	var y := UiKit.screen().y - 60.0
	var bill := ClubOffice.wage_bill(season.club)
	var cap := season.office.cap()
	UiKit.panel(self, Rect2(200, y, 380, 44))
	UiKit.text(self, font, UiKit.t("WAGE BILL"), Vector2(212, y + 18), 11, UiKit.DIM)
	UiKit.bar(self, Rect2(212, y + 24, 356, 12), float(bill) / float(maxi(1, cap)),
		UiKit.DOWN if bill > cap else UiKit.YOU)
	UiKit.right(self, font, _bill_word(bill, cap),
		Vector2(568, y + 18), 11, UiKit.INK if bill <= cap else UiKit.DOWN, 220)

	UiKit.panel(self, Rect2(596, y, 150, 44))
	## ONE WORD FOR ONE THING: the hub says "SQUAD MOOD: Flying" (round 7).
	UiKit.text(self, font, UiKit.t("SQUAD MOOD"), Vector2(608, y + 18), 12, UiKit.DIM)
	UiKit.text_fit(self, font, season.office.morale_word(),
		Vector2(608, y + 36), 15, UiKit.UP if season.office.morale >= 0.6 else UiKit.INK, 130.0)

	UiKit.panel(self, Rect2(760, y, 176, 44))
	UiKit.text(self, font, UiKit.t("CLUB RATING"), Vector2(772, y + 18), 12, UiKit.DIM)
	UiKit.text(self, font, "%d" % season.club.power(), Vector2(772, y + 38), 16, UiKit.YOU)


## THE WAGE BILL, AND BY HOW MUCH IT IS OVER.
##
## Both screens drew "$41 / $200" and turned it red past the cap, which says
## THAT you are over and never BY WHAT. `ClubOffice.over_cap()` has returned
## exactly that number since the day it was written and had no caller until
## 15 Sep 2026 — the screens were re-deriving half of it inline and throwing the
## useful half away.
func _bill_word(bill: int, cap: int) -> String:
	var over := season.office.over_cap(season.club)
	if over <= 0:
		return "%s / %s" % [ClubOffice.money(bill), ClubOffice.money(cap)]
	return UiKit.t("%s / %s  ·  over by %s") % [ClubOffice.money(bill),
		ClubOffice.money(cap), ClubOffice.money(over)]
