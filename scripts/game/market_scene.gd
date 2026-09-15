extends Node2D
## FREE AGENTS, as cards.
##
## The market was a row list — legible, and it made every man look like every
## other man. A signing is a comparison, and a comparison is what a card grid is
## for. The card is `UiKit.card`, the same one the roster and the staff room
## draw, so a fighter cannot look like one thing on the market and another the
## week after you sign him.
##
## Two prices on every card, because both have to clear: the FEE in credits to
## take him on, and the WAGE that then sits under your cap for as long as he
## does. A market that shows one of them is a market that lies about half its
## refusals.

const CARD_W := 172.0
const CARD_H := 158.0
const GAP := 12.0
const TOP := 96.0
const PER_ROW := 5

var font: Font
var ui: CanvasLayer
var season: Season
var flash: String = ""
var picked: FighterCard = null


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	season = Session.season
	ui = CanvasLayer.new()
	add_child(ui)
	_build()


func _slots() -> Array:
	var out: Array = []
	if season == null:
		return out
	var men := season.market()
	for i in men.size():
		if i >= PER_ROW * 2:
			break
		var col := i % PER_ROW
		var row := int(i / PER_ROW)
		var total_w := float(PER_ROW) * CARD_W + float(PER_ROW - 1) * GAP
		var x0 := (UiKit.screen().x - total_w) * 0.5
		out.append({
			"card": men[i],
			"rect": Rect2(x0 + float(col) * (CARD_W + GAP),
				TOP + float(row) * (CARD_H + 12.0), CARD_W, CARD_H),
		})
	return out


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	if season == null:
		return
	for slot in _slots():
		var f: FighterCard = slot["card"]
		var r: Rect2 = slot["rect"]
		var b := UiKit.button("", r.position, r.size, func(m = f): picked = m; _build())
		b.flat = true
		b.modulate = Color(1, 1, 1, 0)
		ui.add_child(b)
	ui.add_child(UiKit.button("Back", Vector2(24, UiKit.screen().y - 56),
		Vector2(150, 44), func():
			UiKit.back("res://scenes/Season.tscn")))
	## PUT THE WORD OUT. The pool is fixed for the summer, deliberately, so that
	## it does not reshuffle under the player while he compares two men — which
	## also means a summer with nothing in it stays that way unless he pays.
	ui.add_child(UiKit.button("New names  ·  %d CC" % ClubOffice.REFRESH_COST,
		Vector2(190, UiKit.screen().y - 56), Vector2(220, 44), func():
			flash = UiKit.said(season.office.refresh_market())
			picked = null
			Session.autosave()
			_build()))
	if picked != null:
		ui.add_child(UiKit.button("Sign %s  ·  %d CC"
			% [UiKit.clip(picked.display_name, 12), season.market_fee(picked)],
			Vector2(560, UiKit.screen().y - 56), Vector2(376, 44), func():
				flash = UiKit.said(season.sign_from_market(picked))
				if flash == "":
					picked = null
				Session.autosave()
				_build()))
	queue_redraw()


func _draw() -> void:
	if season == null:
		return
	UiKit.set_mood(season.mood())
	draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), UiKit.BG)
	UiKit.text(self, font, "FREE AGENTS", Vector2(24, 46), 26, UiKit.INK)
	UiKit.purse(self, font, season.office.credits,
		Vector2(UiKit.screen().x - 24, 46), 18, UiKit.YOU, 200)
	UiKit.text(self, font, "Season %d  ·  %s" % [season.world.season, season.tier_name()],
		Vector2(24, 78), 12, UiKit.DIM)

	var slots := _slots()
	if slots.is_empty():
		UiKit.text(self, font, "Nobody is looking for a club this season.",
			Vector2(24, 140), 16, UiKit.DIM)
	for slot in slots:
		var f: FighterCard = slot["card"]
		var r: Rect2 = slot["rect"]
		if f == picked:
			draw_rect(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), UiKit.SELECT)
		## BOTH PRICES ON THE CARD. The fee is what you spend now and the wage
		## is what you carry, and a market that shows one of them lies about half
		## its refusals. The fee goes in the foot, in credits, coloured by
		## whether you can actually pay it — a price you cannot meet should look
		## different from one you can.
		var fee := season.market_fee(f)
		var afford: bool = season.office.credits >= fee
		## AND WHETHER THE CLUB CAN CARRY HIM. `can_afford_wage` answers the
		## other half of the refusal the comment above is about — it existed with
		## no caller for months while this screen drew the wage in flat grey and
		## let the player find out at the tap.
		var room: bool = season.office.can_afford_wage(season.club, f)
		UiKit.card(self, font, r, {
			"tag": f.pos_name(), "name": f.display_name, "rating": f.overall(),
			"band": _pos_colour(f),
			"note": "age %d  ·  %s/wk%s" % [f.age,
				ClubOffice.money(season.market_wage(f)), "" if room else "  over cap"],
			"note_col": UiKit.DIM if room else UiKit.DOWN,
			"right_note": "to %d" % f.potential,
			"right_col": UiKit.UP,
			"foot": "%d CC" % fee,
			"foot_col": UiKit.YOU if afford else UiKit.DOWN,
		}, true)

	_footer()
	if flash != "":
		UiKit.text(self, font, flash, Vector2(200, UiKit.screen().y - 30), 13, UiKit.DOWN)


func _pos_colour(f: FighterCard) -> Color:
	match int(f.pos):
		Tuning.Pos.CENTER: return UiKit.DOWN
		Tuning.Pos.FLANK_L, Tuning.Pos.FLANK_R: return UiKit.SELECT
		_: return UiKit.UP


func _footer() -> void:
	var bill := ClubOffice.wage_bill(season.club)
	var cap := season.office.cap()
	## THE BOTTOM ROW, IN FULL: Back at 24, New names at 190-410, the sign button
	## at 560-936. This panel was at **190 and 350 wide** — the same rectangle as
	## the New names button, drawn underneath it, with the bill and its bar
	## hidden behind a control for the whole life of the screen.
	##
	## Nothing could see it. `test_layout.gd` measures controls against controls
	## and a panel is not a control; nothing measured drawn text at all until
	## `test_ink.gd`, which named it on its first run. It goes in the gap that is
	## actually free.
	var y := UiKit.screen().y - 56.0
	UiKit.panel(self, Rect2(424, y, 124, 44))
	UiKit.text(self, font, "WAGE BILL", Vector2(434, y + 18), 11, UiKit.DIM)
	UiKit.bar(self, Rect2(434, y + 24, 104, 12), float(bill) / float(maxi(1, cap)),
		UiKit.DOWN if bill > cap else UiKit.YOU)
	UiKit.right(self, font, _bill_word(bill, cap),
		Vector2(UiKit.right_edge(422.0), y + 18), 11, UiKit.INK if bill <= cap else UiKit.DOWN, 100)


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
	return "%s / %s  ·  over by %s" % [ClubOffice.money(bill),
		ClubOffice.money(cap), ClubOffice.money(over)]
