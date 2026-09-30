extends Node2D
## THE FEDERATION AND THE MEMBERS, on one screen because they are one decision.
##
## Two panels, and the reason they sit side by side is the whole pillar: the left
## one is a bill that buys nothing on the field and without which you are not
## entered for the cups; the right one is the income that pays it and the people
## who leave when paying it has made the club not worth belonging to.

const L_X := 24.0
const R_X := 500.0
const COL_W := 436.0
const COL_Y := 92.0
const COL_H := 330.0
const ROW_H := 78.0

var font: Font
var ui: CanvasLayer
var season: Season
var flash: String = ""
## WHAT KIND OF LINE IT IS. Everything here was drawn in the refusal color, so
## "A week's work in one afternoon." read as an error. 0 a refusal, 1 good news,
## 2 a question (a two-tap confirm).
var flash_tone: int = 0


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	season = Session.season
	ui = CanvasLayer.new()
	add_child(ui)
	_build()


func _row_y(i: int) -> float:
	return COL_Y + 62.0 + float(i) * ROW_H


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	if season == null:
		return
	var o := season.office
	var rules := Federation.rules()
	for i in rules.size():
		var r: int = rules[i]
		var cost := o.rule_cost(r)
		if cost <= 0:
			continue
		## A VERB (blind review, 29 Sep: "3 CC" beside "0 of 0 needed"). Short
		## of the rule: bring it up, and it is the button that matters. Already
		## there: raising it is getting ahead of the division above.
		var short: bool = o.rule_level(r) < Federation.required(o.tier, r)
		var btn := UiKit.button((UiKit.t("Meet it · %d CC") if short else UiKit.t("Get ahead · %d CC")) % cost,
			Vector2(L_X + COL_W - 184.0, _row_y(i) + 8.0), Vector2(172, 36), func(rule = r):
				flash_tone = 0
				flash = UiKit.said(o.raise_rule(rule))
				season.sync_power()
				Session.autosave()
				_build())
		ui.add_child(UiKit.primary(btn) if short else btn)
	ui.add_child(UiKit.back_button("res://scenes/Season.tscn"))
	queue_redraw()


func _draw() -> void:
	if season == null:
		return
	UiKit.set_mood(season.mood())
	UiKit.ground(self)
	var o := season.office
	## LITERAL TITLE, THE VOICE UNDER IT (Pete, 29 Sep 2026).
	UiKit.text(self, font, UiKit.t("FEDERATION"), Vector2(24, 40), 26, UiKit.INK)
	UiKit.text(self, font, UiKit.t("Two masters: the federation's rules and your members."),
		Vector2(24, 62), 14, UiKit.DIM)
	UiKit.purse(self, font, o.credits, Vector2(UiKit.screen().x - 24, 46),
		18, UiKit.YOU, 200)
	_federation(o)
	_members(o)
	if flash != "":
		UiKit.text(self, font, flash, Vector2(24, UiKit.screen().y - 70), 13,
			[UiKit.DOWN, UiKit.UP, UiKit.YOU][flash_tone])


func _federation(o: ClubOffice) -> void:
	UiKit.panel(self, Rect2(L_X, COL_Y, COL_W, COL_H))
	UiKit.text(self, font, UiKit.t("THE FEDERATION"), Vector2(L_X + 16, COL_Y + 26), 12, UiKit.DIM)
	## NAMED OFF `o.tier`, which is the number `Federation.required()` is keyed
	## on — not off `season.tier_name()`, which reads the world. The two are kept
	## equal by `sync_power()` and a screen that reads the other one is a screen
	## that will one day print "Backyard Circuit rules" over a Regional
	## requirement and be believed.
	UiKit.right(self, font, UiKit.t("%s rules") % League.tier_name(o.tier),
		Vector2(L_X + COL_W - 16, COL_Y + 26), 11, UiKit.EDGE.lightened(0.5), 240)

	var rules := Federation.rules()
	for i in rules.size():
		var r: int = rules[i]
		var y := _row_y(i)
		var have := o.rule_level(r)
		var want := Federation.required(o.tier, r)
		var short: bool = have < want
		UiKit.text(self, font, UiKit.t(String(Federation.RULE_NAME[r])), Vector2(L_X + 16, y),
			14, UiKit.DOWN if short else UiKit.INK)
		UiKit.meter(self, Rect2(L_X + 16, y + 18, COL_W - 216.0, 14),
			have, Federation.MAX_LEVEL, UiKit.DOWN if short else UiKit.UP)
		## THE LINE YOU HAVE TO REACH, drawn ON the meter. A requirement the
		## player has to work out by being refused is a requirement he meets once,
		## by accident, after it has already cost him a cup.
		if want > 0:
			var w := COL_W - 216.0
			var tick := L_X + 16.0 + w * (float(want) / float(Federation.MAX_LEVEL))
			draw_rect(Rect2(tick - 1.0, y + 15.0, 2.0, 20.0), UiKit.INK)
		## BESIDE THE BAR'S END, never under the button (round 4: they overlapped).
		UiKit.text_fit(self, font, (UiKit.t("%d of %d needed") % [have, want]) if want > 0
			else (UiKit.t("Level %d · not needed here") % have), Vector2(L_X + 16, y + 50),
			13, UiKit.DOWN if short else UiKit.EDGE.lightened(0.5), COL_W - 216.0)

	var y2 := COL_Y + COL_H - 46.0
	var shorts := o.shortfalls()
	if shorts.is_empty():
		UiKit.text_fit(self, font, UiKit.t("In good standing. You may be entered for the cups."),
			Vector2(L_X + 16, y2), 14, UiKit.UP, COL_W - 32.0)
	else:
		UiKit.text(self, font, UiKit.t("NOT ENTERED FOR THE CUPS"), Vector2(L_X + 16, y2), 14, UiKit.DOWN)
		UiKit.text_fit(self, font, UiKit.t("Short on: ") + UiKit.t(", ").join(shorts),
			Vector2(L_X + 16, y2 + 18.0), 14, UiKit.DOWN, COL_W - 32.0)
	## ITS OWN LINE (29 Sep 2026). It sat on the same baseline as "In good
	## standing…" and the two printed through each other, in English and worse
	## in German. Under the standing line when that is one line, and under the
	## shortfall list when there is one.
	if o.federation_upkeep() > 0:
		UiKit.right(self, font, UiKit.t("%d CC a year to hold") % o.federation_upkeep(),
			Vector2(L_X + COL_W - 16, y2 + (18.0 if shorts.is_empty() else 36.0)), 14, UiKit.DIM, 220)


func _members(o: ClubOffice) -> void:
	UiKit.panel(self, Rect2(R_X, COL_Y, COL_W, COL_H))
	UiKit.text(self, font, UiKit.t("THE MEMBERS"), Vector2(R_X + 16, COL_Y + 26), 12, UiKit.DIM)
	UiKit.text(self, font, Federation.following_word(o.fans, o.fan_cap()),
		Vector2(R_X + 16, COL_Y + 64), 22, UiKit.YOU)
	UiKit.meter(self, Rect2(R_X + 16, COL_Y + 78, COL_W - 32, 16),
		int(round(o.fans)), int(round(o.fan_cap())), UiKit.YOU)
	UiKit.right(self, font, UiKit.t("%d following") % int(round(o.fans)),
		Vector2(R_X + COL_W - 16, COL_Y + 114), 12, UiKit.DIM, 160)

	var y := COL_Y + 148.0
	## DUES ARE A BILL, not income. They are charged at the roll-over for the
	## division the club is about to enter; this screen still printed them as
	## "Dues a year" coming in and "Left over" as dues minus upkeep.
	_line("League dues a year", ("-%d CC" if o.dues() > 0 else "%d CC") % o.dues(), y); y += 26.0
	_line("Paperwork upkeep", ("-%d CC" if o.federation_upkeep() > 0 else "%d CC") % o.federation_upkeep(), y); y += 26.0
	var net := -(o.dues() + o.federation_upkeep())
	UiKit.text(self, font, UiKit.t("The federation costs"), Vector2(R_X + 16, y), 14, UiKit.DIM)
	UiKit.right(self, font, UiKit.t("%s%d CC") % ["+" if net >= 0 else "", net],
		Vector2(R_X + COL_W - 16, y), 14, UiKit.UP if net >= 0 else UiKit.DOWN, 180)
	y += 40.0

	## WHAT THEY ARE ACTUALLY WATCHING, said out loud. Members leaving for reasons
	## the player cannot see is a number that reads as random.
	## Two pixels over the panel's right edge at the old three-pixel slop, so it
	## passed; at one pixel it does not, and two pixels of a dim line hanging off
	## a frame is still a line hanging off a frame.
	UiKit.text_fit(self, font, UiKit.t("They stay for a good room, a full bus, a good year."),
		Vector2(R_X + 16, y), 14, UiKit.EDGE.lightened(0.5), COL_W - 32.0)
	UiKit.text_fit(self, font, UiKit.t("They do not care about your paperwork."),
		Vector2(R_X + 16, y + 18.0), 14, UiKit.EDGE.lightened(0.5), COL_W - 32.0)

	var bench_full: bool = season.club.active_eight().size() >= o.travel_slots
	## THE TWO THE CLUB CAN SEE RIGHT NOW. The third thing members watch — how the
	## year went — is settled in the summer and is not a state this screen can read
	## mid-season without pretending to, so it is said in the line above and not
	## dressed up as a live reading here.
	var bits: Array[String] = []
	bits.append(UiKit.t("room %s") % o.morale_word().to_lower())
	bits.append(UiKit.t("bus full") if bench_full else UiKit.t("bus short"))
	UiKit.text_fit(self, font, UiKit.t("Right now: %s") % "  ·  ".join(bits), Vector2(R_X + 16, y + 44.0), 14,
		UiKit.DOWN if not bench_full or o.morale < 0.38 else UiKit.INK, COL_W - 32.0)


func _line(label: String, value: String, y: float) -> void:
	UiKit.text(self, font, UiKit.t(label), Vector2(R_X + 16, y), 14, UiKit.DIM)
	UiKit.right(self, font, value, Vector2(R_X + COL_W - 16, y), 14, UiKit.INK, 180)
