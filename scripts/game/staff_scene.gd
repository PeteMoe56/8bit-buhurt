extends Node2D
## THE STAFF ROOM. Two captains, what each of them teaches, and how hard he
## works the men he teaches.
##
## The regime was three words on the Office tab for days: drawn, never settable,
## read by nothing. It is now the sharpest decision on this screen — see
## `ClubOffice.Regime`, whose numbers are Retro Bowl's own, read out of the
## shipped build rather than invented.

const CARD_W := 200.0
const CARD_H := 150.0
const CUR_Y := 96.0
const OFFER_X := 496.0
const OFFER_W := 200.0
const OFFER_H := 126.0

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


## Who is available — one list, in ClubOffice, read by both screens that sell
## captains.
func _offer(slot: int) -> Dictionary:
	return ClubOffice.offer(season.seed_value, season.world.season, slot,
		season.office.staff_refreshes)


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	if season == null:
		return
	var o := season.office
	for i in ClubOffice.MAX_CAPTAINS:
		var x := 24.0 + float(i) * (CARD_W + 16.0)
		if i < o.captains.size():
			## THE REGIME, AS THREE BUTTONS UNDER THE MAN IT APPLIES TO.
			## Retro Bowl puts them under the coordinator for the same reason:
			## the choice belongs to a person, not to the club.
			## LAID OUT BY WHAT IS IN THEM, not in equal thirds.
			##
			## Three equal thirds of a card is 68 pixels and "Normal" needs 72,
			## and a Button's `size` is a FLOOR — Godot raises it to whatever the
			## contents need rather than clipping — so the middle one grew, ate
			## its own gap and had its last letter drawn over by "Hard". It read
			## as "Norma" and looked like text clipping, which is the one thing
			## it was not.
			##
			## So each takes its natural width and they are packed left to right.
			## The three of them come to 192 in a 204-pixel row, which is why
			## this fits at all — and `test_layout.gd` is what will say so when a
			## fourth regime or a longer word makes it stop fitting.
			var made: Array[Button] = []
			for k in 3:
				var bb := UiKit.button(ClubOffice.REGIME_NAME[k], Vector2.ZERO,
					Vector2(40, 36), _set_regime.bind(i, k))
				made.append(bb)
				ui.add_child(bb)
			var bx := x
			for bb in made:
				bb.position = Vector2(bx, CUR_Y + CARD_H + 8.0)
				bx += bb.size.x + UiKit.DROP_PX + 4.0
			## KEEP HIM, or let the deal run out. Two controls where there was one,
			## because a captain you cannot re-sign is a captain you are only ever
			## losing.
			var half := (CARD_W - 6.0) / 2.0
			ui.add_child(UiKit.button("+1yr · %d" % ClubOffice.CAPTAIN_EXTEND,
				Vector2(x, CUR_Y + CARD_H + 50.0), Vector2(half, 34), _extend.bind(i)))
			ui.add_child(UiKit.button("Release", Vector2(x + half + 6.0, CUR_Y + CARD_H + 50.0),
				Vector2(half, 34), _release.bind(i)))
		else:
			ui.add_child(UiKit.button("Hire  ·  %d CC" % ClubOffice.cost_of(_offer(i)),
				Vector2(x, CUR_Y + CARD_H + 8.0), Vector2(CARD_W, 36), _hire.bind(i)))
			## PUT THE WORD OUT AGAIN. The list is deterministic from the season so
			## it does not reshuffle while you read it — which also means a bad crop
			## is a bad crop for a year unless you pay to turn it over.
			ui.add_child(UiKit.button("New names  ·  %d CC" % ClubOffice.REFRESH_COST,
				Vector2(x, CUR_Y + CARD_H + 50.0), Vector2(CARD_W, 34), _refresh))
	## AN EXTRA SESSION, AND IT BELONGS ON THIS SCREEN AND NOT THE CLUBHOUSE.
	##
	## Pete, 15 Sep 2026: *"we can go with a 'team training' CC sink that may
	## work."* It is a thing the CAPTAINS do — what it buys is a week's work at
	## the grade of whoever teaches each role, so its value is decided entirely by
	## the two cards above it. Put on the Clubhouse action row it would have been
	## a number with no explanation next to it, on the row Pete had already called
	## too crowded; here the price and the men who set its worth are on one
	## screen.
	##
	## It says why it cannot be pressed rather than spending a tap to refuse: a
	## club with no captains buys almost nothing, which is the rule the practice
	## is built on and the one thing this screen should never let a player
	## discover by accident.
	var cost := season.office.session_cost()
	var idle: bool = season.office.captains.is_empty()
	ui.add_child(UiKit.button("Extra session  ·  %d CC" % cost,
		Vector2(UiKit.right_edge(280.0), UiKit.screen().y - 56), Vector2(280, 44),
		func():
			flash = UiKit.said(season.run_session()) if not idle \
				else "Nobody is teaching. A session with no captain is a warm-up."
			if flash == "":
				flash = "A week's work in one afternoon."
			Session.autosave()
			_build()))
	ui.add_child(UiKit.button("Back", Vector2(24, UiKit.screen().y - 56),
		Vector2(150, 44), func():
			UiKit.back("res://scenes/Season.tscn")))
	queue_redraw()


func _set_regime(i: int, r: int) -> void:
	flash = UiKit.said(season.office.set_regime(i, r))
	Session.autosave()
	_build()


func _hire(slot: int) -> void:
	flash = UiKit.said(season.hire_captain(_offer(slot)))
	Session.autosave()
	_build()


func _extend(i: int) -> void:
	flash = UiKit.said(season.office.extend_captain(i))
	Session.autosave()
	_build()


func _refresh() -> void:
	flash = UiKit.said(season.office.refresh_staff())
	Session.autosave()
	_build()


func _release(i: int) -> void:
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
	UiKit.text(self, font, "THE STAFF", Vector2(24, 46), 26, UiKit.INK)
	UiKit.purse(self, font, o.credits, Vector2(UiKit.screen().x - 24, 46),
		18, UiKit.YOU, 200)
	UiKit.text(self, font, "YOUR CAPTAINS", Vector2(24, 78), 12, UiKit.DIM)

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
				"foot": "%s  ·  %dy" % [ClubOffice.REGIME_NAME[reg],
					int(c.get("years", ClubOffice.CAPTAIN_YEARS))],
				"foot_col": UiKit.DOWN if int(c.get("years", 9)) <= 1 else _regime_color(reg),
			}, true)
			## The mark on the selected regime button, which a Button cannot
			## carry itself without a theme.
			var w := (CARD_W - 8.0) / 3.0
			draw_rect(Rect2(x + float(reg) * (w + 4.0), CUR_Y + CARD_H + 4.0, w, 3.0),
				_regime_color(reg))
		else:
			## AN EMPTY SLOT IS THE STRONGEST THING ON THIS SCREEN. A club with
			## one captain teaches at most two of the three jobs, and the third
			## is a role nobody on your line is being shown how to fight.
			UiKit.panel(self, r)
			UiKit.text(self, font, "NO CAPTAIN", r.position + Vector2(14, 34), 13, UiKit.DOWN)
			var off := _offer(i)
			UiKit.text(self, font, String(off["name"]), r.position + Vector2(14, 66), 17, UiKit.INK)
			UiKit.text(self, font, _roles_of(off), r.position + Vector2(14, 88), 12, UiKit.DIM)
			UiKit.stars(self, r.position + Vector2(14, 98), int(off["grade"]) * 20,
				UiKit.YOU, 11.0, 3.0)

	_what_it_costs()
	_coverage()
	_trait_word()
	if flash != "":
		UiKit.text(self, font, flash, Vector2(24, UiKit.screen().y - 70), 13, UiKit.DOWN)


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
	var y := CUR_Y + CARD_H + 110.0
	UiKit.text(self, font, "WHAT ELSE THEY BRING", Vector2(OFFER_X, y), 12, UiKit.DIM)
	y += 24.0
	var said := 0
	for i in ClubOffice.MAX_CAPTAINS:
		var c: Dictionary = o.captains[i] if i < o.captains.size() else _offer(i)
		var t := ClubOffice.trait_of(c)
		if t == ClubOffice.Trait.NONE:
			continue
		said += 1
		UiKit.text(self, font, "%s  ·  %s" % [String(c.get("name", "?")),
			String(ClubOffice.TRAIT_NAME[t])], Vector2(OFFER_X, y), 13, UiKit.UP)
		UiKit.text(self, font, String(ClubOffice.TRAIT_BLURB[t]),
			Vector2(OFFER_X, y + 16.0), 11, UiKit.EDGE.lightened(0.5))
		y += 40.0
	if said == 0:
		UiKit.text(self, font, "Neither of them brings anything but the coaching.",
			Vector2(OFFER_X, y), 11, UiKit.EDGE.lightened(0.5))


func _regime_color(r: int) -> Color:
	match r:
		ClubOffice.Regime.LIGHT: return UiKit.UP
		ClubOffice.Regime.HARD: return UiKit.DOWN
		_: return UiKit.YOU


## WHAT THE THREE REGIMES ACTUALLY TRADE, on the screen where you pick one.
## A decision whose consequences are in a wiki is not a decision.
func _what_it_costs() -> void:
	UiKit.panel(self, Rect2(OFFER_X, CUR_Y, 440, CARD_H + 86.0))
	UiKit.text(self, font, "WHAT A REGIME COSTS", Vector2(OFFER_X + 16, CUR_Y + 26),
		12, UiKit.DIM)
	var cols := ["", "TRAINING", "MORALE", "ARMOR", "KNOCKS"]
	var xs := [16.0, 140.0, 226.0, 306.0, 386.0]
	for i in cols.size():
		UiKit.text(self, font, cols[i], Vector2(OFFER_X + xs[i], CUR_Y + 54), 10, UiKit.EDGE.lightened(0.5))
	var rows := [
		{"r": ClubOffice.Regime.LIGHT, "t": "×0.6", "m": "+", "a": "+", "k": "rare"},
		{"r": ClubOffice.Regime.NORMAL, "t": "×1.0", "m": "—", "a": "—", "k": "some"},
		{"r": ClubOffice.Regime.HARD, "t": "×1.5", "m": "−", "a": "−", "k": "\u00d75"},
	]
	var y := CUR_Y + 84.0
	for row in rows:
		var col := _regime_color(int(row["r"]))
		UiKit.text(self, font, ClubOffice.REGIME_NAME[int(row["r"])],
			Vector2(OFFER_X + xs[0], y), 14, col)
		UiKit.text(self, font, String(row["t"]), Vector2(OFFER_X + xs[1], y), 13, UiKit.INK)
		UiKit.text(self, font, String(row["m"]), Vector2(OFFER_X + xs[2], y), 13, UiKit.INK)
		UiKit.text(self, font, String(row["a"]), Vector2(OFFER_X + xs[3], y), 13, UiKit.INK)
		UiKit.text(self, font, String(row["k"]), Vector2(OFFER_X + xs[4], y), 13,
			UiKit.DOWN if int(row["r"]) == ClubOffice.Regime.HARD else UiKit.DIM)
		y += 30.0
	## THE SHOUT MOVED INTO THE SENTENCE. The cell said "FIVE TIMES" and in the
	## real face that column ran to x 971 of a 960 frame — and it was the only
	## cell in the table not written as a multiplier anyway. The row reads ×5 like
	## every other figure on it; the line under it is where the shouting belongs.
	UiKit.text(self, font, "Hard is not a bit riskier than Normal. It is FIVE TIMES.",
		Vector2(OFFER_X + 16, y + 8), 11, UiKit.EDGE.lightened(0.5))


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
	UiKit.text(self, font, "WHAT IS BEING TAUGHT", Vector2(24, y), 12, UiKit.DIM)
	y += 20.0
	var spec := o.club_specialty()
	if spec >= 0:
		UiKit.text(self, font, "Club specialty: %s, training ×%.2f"
			% [Tuning.ROLE_NAME[spec], ClubOffice.SPECIALTY_XP],
			Vector2(24, y), 12, UiKit.UP)
	elif o.presence() > 0.0:
		UiKit.text(self, font, "No specialty — but the room is a happier one.",
			Vector2(24, y), 12, UiKit.YOU)
	y += 24.0
	var roles := [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]
	for i in roles.size():
		var role: int = roles[i]
		var taught: bool = o.taught(role)
		var is_spec: bool = role == spec
		var x := 24.0 + float(i) * 150.0
		UiKit.text(self, font, String(Tuning.ROLE_NAME[role]), Vector2(x, y), 15,
			(UiKit.UP if is_spec else UiKit.INK) if taught else UiKit.DOWN)
		var line := "nobody teaches it"
		if taught:
			line = ClubOffice.REGIME_NAME[o.regime_for(role)]
			if is_spec:
				line += "  ·  specialty"
		UiKit.text(self, font, line, Vector2(x, y + 20), 12,
			(UiKit.UP if is_spec else _regime_color(o.regime_for(role))) if taught else UiKit.DOWN)
