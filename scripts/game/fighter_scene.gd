extends Node2D
## ONE FIGHTER, everything the club knows about him, and the two decisions you
## can make about him standing next to it.
##
## Three columns: who he is, what he is made of, and what he has done. The third
## one did not exist until today — the sim has always counted downs caused and
## rounds finished standing, because that is what XP is paid on, and then thrown
## both away. A career mode whose careers leave no trace is not one.

const COL_Y := 92.0
const COL_H := 330.0
const L_X := 24.0
const M_X := 336.0
const R_X := 648.0
const COL_W := 288.0
## The band between the bottom of the panels and the footer row. Empty until the
## level became something the player spends.
const LEVEL_ROW_Y := 430.0
const ROW_H := 40.0
## The footer's ">" — the page count sits between it and "<" at 640.
const PAGE_NEXT_X := 748.0
const GAP := 8.0
## The meeting button is the fixed thing in that band and the +1 buttons divide
## what is left, because the meeting button's label is the one whose width the
## screen does not control — it carries a price.
const MEET_W := 230.0
static func meet_x() -> float:
	return UiKit.right_edge() - MEET_W


## TALL SCREENS GROW THE THREE COLUMNS (3 Oct 2026): taller panels, wider row
## pitch and bigger type on 960x720, and the level row follows the panels down.
## Widths stay at 288, so only what fits there grows. Phones: k = 1.
static func col_h() -> float:
	return UiKit.tk(COL_H)


static func level_row_y() -> float:
	return COL_Y + col_h() + 8.0

## ------------------------------------------------------------ the card
## Layout B off the mockups: four rows in two columns, the price ON the button,
## and the stat each purchase moves drawn underneath it.
##
## THE GEOMETRY IS DERIVED FROM THE PANEL, not written down four times. The first
## pass put the read-out at 60, the button at 210 and the bar at 140 wide under
## a 250-wide button — four numbers that had to agree and did not, so the two
## columns sat 16px from one edge and 36px from the other and each row had a
## different vertical rhythm. Everything below is measured off `CARD` and `COLS`.
## THE CARD FILLS THE CANVAS IT GOT. Was a flat 872 wide — 960 less two 44s —
## which on a handset left the meeting sitting in the left three-quarters of the
## screen with a bare strip beside it. Everything below still derives from it,
## so widening the canvas widens the columns and nothing else had to change.
static func card() -> Rect2:
	return Rect2(44.0, 68.0, UiKit.span(44.0), 372.0)


static func cell_w() -> float:
	return (card().size.x - PAD * 2.0 - GUT) / float(COLS)


static func btn_w() -> float:
	return cell_w() - READ_W - 12.0


static func card_close_y() -> float:
	return card().position.y + card().size.y - 56.0
const COLS: int = 2
const PAD := 20.0
const GUT := 24.0
## One column's usable width, and the parts inside it.
const READ_W := 140.0
const ROW_TOP := 34.0
const HEAD_H := 44.0
const CELL_H := 128.0
## Two label/value lines under every row, on the same baselines in all four, so
## the card reads as one shape rather than as four arrangements.
const LINE_1 := 82.0
const LINE_2 := 104.0
const BAR_Y := 54.0
const BAR_H := 12.0

var font: Font
var ui: CanvasLayer
var season: Season
var man: FighterCard
var flash: String = ""
## Why the bus button is dead, when it is. Set in `_build`, drawn in `_draw`.
var bus_note: String = ""
## Why the deal button is off, for the same line (3 Oct 2026).
var deal_note: String = ""

## --------------------------------------------------------------- the meeting
## PETE, 14 Sep 2026: *"Let's go with B and add the affected stats underneath.
## Then when you hit the buttons, you can actually see the effect."*
##
## Layout B off `tools/mock_meeting.gd` — four rows in two columns with the price
## ON the button rather than beside it, which is one control instead of two and
## is what every other button in this game already is. It opens over the fighter
## page rather than being a screen of its own: the three panels underneath are
## what you read, and this is where you spend.
var meeting_open: bool = false

## WHAT A PURCHASE DID, SHOWN ROLLING RATHER THAN SNAPPED.
##
## Each entry remembers only where a number CAME FROM. The destination is read
## live off the card at draw time, so a roll can never finish showing a value the
## man does not have — which is the failure mode of caching both ends and the
## reason this stores one.
##
## The progress goes through `Juice.ladder` like everything else that moves in
## this game: six steps, so a number COUNTS up in whole jumps instead of sliding.
## A smooth tween on a pixel screen is the one thing the juice rules exist to
## prevent, and a counter is exactly where it would creep in.
var rolls: Dictionary = {}
const ROLL_S: float = 0.55
const ROLL_STEPS: int = 6


func _roll(key: String, now: float) -> float:
	if not rolls.has(key):
		return now
	var r: Dictionary = rolls[key]
	var t: float = Juice.ladder(clampf(float(r["t"]) / ROLL_S, 0.0, 1.0), ROLL_STEPS)
	return lerpf(float(r["from"]), now, t)


## Remember where a number was, just before the purchase moves it.
func _start_roll(key: String, from: float) -> void:
	rolls[key] = {"from": from, "t": 0.0}


func _process(delta: float) -> void:
	if rolls.is_empty():
		return
	var live := false
	for k in rolls:
		var r: Dictionary = rolls[k]
		if float(r["t"]) < ROLL_S:
			r["t"] = float(r["t"]) + delta
			live = true
	if live:
		queue_redraw()
	else:
		rolls.clear()
		queue_redraw()


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	season = Session.season
	man = Session.viewing_fighter
	if man == null and season != null and not season.club.roster.is_empty():
		man = season.club.roster[0]
	ui = CanvasLayer.new()
	add_child(ui)
	## CENTRED ON A WIDE PHONE (2 Oct 2026 playtest): see `UiKit.frame`.
	UiKit.frame(self, ui)
	_build()


## Everybody, in the order the roster shows them, so the arrows walk the screen
## the player just came from rather than the raw roster array.
func _order() -> Array:
	var out: Array = []
	if season == null:
		return out
	## ONLY THE MEN WITH A POINT, while a levelling run is on.
	if Session.level_run:
		for f in _all_order():
			if Career.can_place(f):
				out.append(f)
		if not out.is_empty():
			if not out.has(man) and man != null:
				out.push_front(man)
			return out
		Session.level_run = false
	return _all_order()


func _all_order() -> Array:
	var out: Array = []
	var line := season.club.starting_five()
	for f in line:
		out.append(f)
	for f in season.club.active_eight():
		if not line.has(f):
			out.append(f)
	for f in season.club.reserves():
		out.append(f)
	## THE HURT ARE STILL HIS MEN (3 Oct 2026): off the bus, not off the books.
	for f in season.club.injured():
		if not out.has(f):
			out.append(f)
	return out


func _page(step: int) -> void:
	var order := _order()
	var i := order.find(man)
	if i == -1 or order.is_empty():
		return
	man = order[(i + step + order.size()) % order.size()]
	Session.viewing_fighter = man
	flash = ""
	_build()


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	if man == null:
		return
	var y := UiKit.screen().y - 56.0
	## A SCRIM CANNOT COVER A BUTTON, and this project has now paid for that twice
	## — FIGHT was pressable through the corner's sub popup, and the report drew
	## over a still-live splash button. A Control is a node, not paint: dimming
	## the pixels behind a modal leaves every hit target underneath it armed.
	##
	## So the card does not draw OVER this screen's controls, it REPLACES them.
	## Nothing below is built while it is open.
	if meeting_open:
		_meeting_controls()
		queue_redraw()
		return
	ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(24, y), Vector2(130, 44), func():
		Session.viewing_fighter = null
		UiKit.back("res://scenes/Roster.tscn")))

	## WHERE HE STANDS. One button with the move that actually applies: a man on
	## the eight can be stood down, a reserve can be brought up. Two buttons with
	## one of them always refusing is a screen that argues with you.
	## AND IT SAYS WHAT IT DOES, IN THE GAME'S OWN WORDS.
	##
	## Pete, 15 Sep 2026: *"No idea what 'Stand down' is or does. When pressed,
	## it's hidden."* Both halves are fair. The label was military and the game is
	## not — every other screen calls this the BUS ("PLACES ON THE BUS", "6 of 8",
	## "ON THE BUS") and this one screen called it standing down. The vocabulary
	## rule this project already applies to formations applies to verbs.
	##
	## And the hiding: pressing it on a full eight is REFUSED, with a sentence
	## that then printed ten pixels above a row of buttons. The refusal is
	## foreseeable — `set_active` will not let the eight be seven — so the button
	## says so on its face instead, the way the night-out button learned to. A
	## control that can tell you no before you spend the tap should.
	var on_eight: bool = man.active
	var bus_label := UiKit.t("Leave at home") if on_eight else UiKit.t("Take to events")
	var bus_why := season.club.set_active_would(man, not on_eight) \
		if season.club.has_method("set_active_would") else ""
	## THE REASON GOES ON THE LINE ABOVE, NOT ON THE FACE. "Off the bus · need
	## eight" is 210 pixels of label in a 190-pixel button and came out as "Off
	## the bus · need e" — a refusal clipped mid-word, which is worse than no
	## refusal because it reads as damage. The button says what it does and goes
	## dead; the sentence says why, where there is room for a sentence.
	var bus_b := UiKit.button(bus_label, Vector2(170, y), Vector2(190, 44), func():
		flash = UiKit.said(season.club.set_active(man, not on_eight))
		season.sync_power()
		Session.autosave()
		_build())
	bus_b.disabled = bus_why != ""
	## Kept for `_draw`, which is a different function and runs on a different
	## frame — a screen that recomputed the reason to print it would be two
	## answers to one question.
	bus_note = ("" if bus_why == "" else (UiKit.t("%s cannot be left at home: %s.") if on_eight
		else UiKit.t("%s cannot travel: %s.")) % [man.display_name, bus_why])
	## "need eight" said as a rule (round 8: "cryptic").
	if on_eight and bus_why == UiKit.t("need eight"):
		bus_note = UiKit.t("Every seat on the bus must be filled, so %s travels.") % man.display_name
	## AN INJURED MAN NEVER TRAVELS (3 Oct 2026): he is off the bus entirely, so
	## "every seat must be filled, so he travels" would be a lie about him.
	if man.injury > 0:
		bus_note = UiKit.tn("Injured — out %d event. He stays home.",
			"Injured — out %d events. He stays home.", man.injury) % man.injury
	ui.add_child(bus_b)

	## THE CONTRACT, as one control with the price on it — the same fork the
	## squad tab uses, so the two screens cannot quote different numbers.
	var out_of_deal: bool = man.years <= 0
	## Both prices come off the season now. They used to be one call to the season
	## and one hand-rolled `Contracts.offer` right here, which agreed until a
	## captain's Negotiator trait started discounting one of them — and then the
	## button would have quoted a price the club did not charge.
	var cost: int = season.resign_cost(man) if out_of_deal else season.extend_cost(man)
	## THE HALL OF FAME TAG, on his own page, exactly where Retro Bowl puts it:
	## *"you need to tag them in the top-left corner of their profile page."* It is
	## a decision you make about a man while he is still playing, which is what
	## separates it from a leaderboard the game fills in for you.
	var tagged: bool = season.world.in_hall(man.display_name)
	## THE STAR IS AN ICON, not a character: no face this game ships draws ★.
	## INVEST, BESIDE IT (Pete, 2 Oct 2026: the old "Prospect" read like scouting
	## a free agent, and lived on the team sheet). One man a year: +3 to his max
	## at the winter, with a Training ground at 3. Tap again to take it back.
	var invested: bool = season.prospect == man
	var half := (COL_W - 32.0 - 8.0) * 0.5
	var inv := UiKit.button(UiKit.t("Invested") if invested else UiKit.t("Invest +%d") % Career.PROSPECT_GAIN,
		Vector2(R_X + 16, COL_Y + col_h() - 48), Vector2(half, 38), func():
			var ground := season.office.level(ClubOffice.Facility.TRAINING)
			if season.prospect == man:
				season.prospect = null
				flash = UiKit.t("%s is no longer your investment.") % man.display_name
			elif ground < Career.PROSPECT_GROUND:
				flash = UiKit.t("Invest in one man a year: +%d to his max at the winter. Needs a Training ground at %d.") % [
					Career.PROSPECT_GAIN, Career.PROSPECT_GROUND]
			else:
				season.prospect = man
				flash = UiKit.t("%s is your investment: +%d to his max at the winter.") % [
					man.display_name, Career.PROSPECT_GAIN]
			Session.autosave()
			_build(), "up")
	## SAYS WHAT IT DOES BEFORE THE TAP, on a PC hover (the tap's answer is the
	## gold line under his name).
	inv.tooltip_text = UiKit.t("Invest in one man a year: +%d to his max at the winter. Needs a Training ground at %d.") % [
		Career.PROSPECT_GAIN, Career.PROSPECT_GROUND]
	ui.add_child(UiKit.selected(inv, invested))
	## "To the Hall": "Tag for the Hall" shrank to a squint at half the panel.
	ui.add_child(UiKit.button(UiKit.t("In the Hall") if tagged else UiKit.t("To the Hall"),
		## IN HIS RECORD'S PANEL, under the honors it is about (blind review
		## round 3: it sat cramped in the page header).
		Vector2(R_X + 16 + half + 8.0, COL_Y + col_h() - 48), Vector2(half, 38), func():
			if tagged:
				season.world.untag_from_hall(man.display_name)
				flash = UiKit.t("%s taken out of the Hall.") % man.display_name
			else:
				var err := season.world.tag_for_hall(man, season.world.season)
				flash = UiKit.said(err) if err != "" else UiKit.t("%s tagged for the Hall.") % man.display_name
			Session.autosave()
			_build(), "star" if tagged else "hall"))
	var deal_b := UiKit.button(UiKit.t("%s · %s/yr") % [UiKit.t("Re-sign") if out_of_deal else UiKit.t("Extend early"),
		ClubOffice.money(cost)], Vector2(376, y), Vector2(250, 44), func():
			flash = UiKit.said(season.resign(man) if out_of_deal else season.extend(man))
			Session.autosave()
			_build())
	## OFF WHEN HE WILL NOT SIGN (3 Oct 2026), and the line under the title says
	## why: a lit button beside "He will not sign again." could only answer no.
	var refuses := bool(Contracts.demand(man)["refuses"])
	deal_b.disabled = refuses or (not out_of_deal and not Contracts.can_extend(man))
	deal_note = UiKit.t("He will not sign while his morale is this low. A talk can lift it.") \
		if refuses else ""
	ui.add_child(deal_b)

	## THE ARROWS AROUND THE COUNT THEY MOVE (round 8: "group the arrows with
	## the counter"). "3 of 13" is drawn between them in `_draw`.
	ui.add_child(UiKit.arrow(false, Vector2(640, y), Vector2(44, 44), _page.bind(-1)))
	ui.add_child(UiKit.arrow(true, Vector2(PAGE_NEXT_X, y), Vector2(44, 44), _page.bind(1)))
	## HIS WEAPON, and a tap changes it. Sword-and-shield or polearm — a line-up
	## decision, so it costs nothing and can be changed between any two events.
	## SAYS WHAT IT IS (3 Oct 2026): the sword mark beside "Sword" read as a tick,
	## "✓ Sword", and said nothing about a weapon or a tap. The words alone now,
	## so "Weapon: Sword" has the whole face (round 10 had it squeezed by the mark).
	ui.add_child(UiKit.button(UiKit.t("Weapon: %s") % (UiKit.t("Sword")
		if man.weapon == Tuning.Weapon.SWORD_SHIELD else UiKit.t("Pole")),
		Vector2(PAGE_NEXT_X + 52.0, y), Vector2(UiKit.right_edge() - PAGE_NEXT_X - 52.0, 44), func():
			man.weapon = Tuning.Weapon.POLEARM if man.weapon == Tuning.Weapon.SWORD_SHIELD \
				else Tuning.Weapon.SWORD_SHIELD
			flash = UiKit.t("%s will carry a %s.") % [man.display_name,
				Tuning.weapon_name(man.weapon).to_lower()]
			Session.autosave()
			_build()))

	## ------------------------------------------------------------ the level
	## WHERE THE POINT GOES, and it is a row of real buttons rather than a
	## confirm-then-choose, because the choice IS the decision — Pete, 13 Sep
	## 2026: *"Players should be able to upgrade fighters stats anytime the +1
	## level/level up is available."*
	##
	## The band between the panels (422) and the footer row (484) was empty and
	## is exactly the right size for one row of controls.
	if Career.can_place(man):
		var can := Career.raisable(man)
		## WIDTH IS DERIVED, NOT DECLARED. The first version wrote `168` and four
		## of those ran 164px into the meeting button beside them — which the
		## screenshot could not show, because the man in the shot was at his
		## ceiling and the row never drew. A number that has to agree with
		## another number is a number that will stop agreeing, so this one is
		## measured from the gap the meeting button leaves.
		var bw := (meet_x() - GAP - L_X - float(Career.STATS.size() - 1) * GAP) \
			/ float(Career.STATS.size())
		for i in Career.STATS.size():
			var stat: int = Career.STATS[i]
			var ok: bool = can.has(stat)
			var b := UiKit.button(UiKit.t("+%d %s") % [Career.POINTS_PER_LEVEL, Career.stat_name(stat)],
				Vector2(L_X + float(i) * (bw + GAP), level_row_y()),
				Vector2(bw, ROW_H), func():
					## It can still refuse — a stat at 99, or a level he has not
					## finished earning — and it says which, because a button that
					## goes gray without a reason is one the player argues with.
					var r := Career.level_into(man, stat)
					if bool(r.get("levelled", false)):
						flash = UiKit.t("%s put a level into %s.") % [man.display_name,
							Career.stat_name(stat).to_lower()]
						season.sync_power()
						## ON TO THE NEXT MAN WAITING, in a levelling run.
						if Session.level_run and not Career.can_place(man):
							var left := _all_order().filter(func(x): return x != man and Career.can_place(x))
							if left.is_empty():
								Session.level_run = false
								flash += "  " + UiKit.t("Every level is spent.")
							else:
								man = left[0]
								Session.viewing_fighter = man
					elif r.get("reason", "") == "not earned":
						flash = UiKit.said(UiKit.t("%d more xp before he levels.") %
							int(r.get("short", 0)))
					else:
						flash = UiKit.said(UiKit.t("Nothing left in his %s.") %
							Career.stat_name(stat).to_lower())
					Session.autosave()
					_build())
			b.disabled = not ok
			## GOLD AS ONE CHOICE (before/after review: green on slate lost the
			## call to action). The four +1s are one decision, so they are one
			## gold group — checklist C3 counts a group once.
			if ok:
				UiKit.primary(b)
				b.set_meta("primary_group", "level")
			ui.add_child(b)
	elif not meeting_open:
		## --------------------------------------------------- the meeting door
		## ONE BUTTON INSTEAD OF THREE. The purchases moved into a card of their
		## own (layout B, `tools/mock_meeting.gd`) so each one can show the stat
		## it MOVES underneath it — which is the thing three buttons in a strip
		## could never do, because there was nowhere to put the answer.
		var open_b := UiKit.button(UiKit.t("Meeting · %s") % man.display_name,
			Vector2(L_X, level_row_y()), Vector2(meet_x() - GAP - L_X, ROW_H), func():
				meeting_open = true
				rolls.clear()
				_build())
		ui.add_child(open_b)
	queue_redraw()


func _meeting_controls() -> void:
	## Layout B, and the four rows are the four things a credit can buy about one
	## man: his mood, his harness, his next level and his deal. Under each one,
	## THE STAT IT MOVES — because a purchase whose effect you cannot see is a
	## purchase you take on trust, and that is the difference between a shop and
	## a decision.
	for i in 4:
		var c: Dictionary = _meeting_row(i)
		var at := _cell_at(i)
		var price: String = (UiKit.t("%s/yr") % ClubOffice.money(int(c["wage"]))) if c.has("wage") \
			else (UiKit.t("%d CC") % int(c["cc"]))
		var b := UiKit.button("%s · %s" % [String(c["verb"]), price],
			at + Vector2(READ_W + 12.0, 0.0), Vector2(btn_w(), HEAD_H),
			_buy.bind(String(c["key"])))
		b.disabled = bool(c["off"])
		ui.add_child(b)
	var fy := card_close_y()
	ui.add_child(UiKit.arrow(false, Vector2(card().position.x + PAD, fy),
		Vector2(52, 40), _page.bind(-1)))
	ui.add_child(UiKit.arrow(true, Vector2(card().position.x + PAD + 58.0, fy),
		Vector2(52, 40), _page.bind(1)))
	ui.add_child(UiKit.button(UiKit.t("Done"),
		Vector2(card().position.x + card().size.x - PAD - 130.0, fy),
		Vector2(130, 40), func():
			meeting_open = false
			rolls.clear()
			_build()))


## Where a cell's top-left corner is. Two columns, two rows, off the panel.
func _cell_at(i: int) -> Vector2:
	return Vector2(
		card().position.x + PAD + float(i % COLS) * (cell_w() + GUT),
		card().position.y + ROW_TOP + float(i / COLS) * CELL_H)


## THE FOUR ROWS, IN ONE PLACE. The controls need the verb and the price and the
## drawing needs the read-out and the two lines under it, and a card where those
## two lists are written separately is a card whose button and whose answer can
## come to disagree.
func _meeting_row(i: int) -> Dictionary:
	match i:
		0:
			return {"key": "morale", "label": UiKit.t("MORALE"), "verb": UiKit.t("Talk to him"),
				"cc": ClubOffice.negotiate_cost(man), "off": false,
				"value": man.morale_word(), "col": man.morale_color(),
				"bar": _roll("morale", man.morale), "bar_col": man.morale_color()}
		1:
			## THE ARMORER'S PRICE AND THE ARMORER'S ANSWER (3 Oct 2026): this quoted
			## titanium-cap money the Maintenance tab did not, and stayed lit at a
			## harness's ceiling, in a training week and after this week's repair.
			var cap := season.office.armorer_cap()
			return {"key": "kit", "label": UiKit.t("CONDITION"), "verb": UiKit.t("Fix kit"),
				"cc": ClubOffice.kit_cost(man, cap),
				"off": Quartermaster.topped_out(man, cap) or SeasonArmorerTab.repair_block(season, man) != "",
				"value": "%d%%" % int(round(_roll("kit", man.armor) * 100.0)),
				"col": UiKit.INK,
				"bar": _roll("kit", man.armor), "bar_col": UiKit.YOU}
		2:
			var bar := 0.0
			if not Career.at_ceiling(man):
				bar = clampf(_roll("xp", float(man.xp))
					/ maxf(1.0, float(Career.next_level_at(man))), 0.0, 1.0)
			return {"key": "level", "label": UiKit.t("XP LEVEL"), "verb": UiKit.t("Extra training"),
				"cc": Career.level_cost(man), "off": Career.at_ceiling(man),
				"value": str(int(round(_roll("level", float(man.level))))),
				"col": UiKit.INK, "bar": bar,
				"bar_col": UiKit.UP if Career.can_level(man) else UiKit.YOU}
		_:
			var bill := ClubOffice.wage_bill(season.club)
			var cap := maxi(1, season.office.cap())
			## A WAGE, NOT A PRICE IN CC (playtest 30 Sep: "Extend · 34 CC" was
			## his $34 a week printed as credits). The deal costs nothing today;
			## the button says what it will pay him.
			return {"key": "deal", "label": UiKit.t("CONTRACT"),
				"verb": UiKit.t("Re-sign") if man.years <= 0 else UiKit.t("Extend"),
				"wage": season.resign_cost(man) if man.years <= 0 \
					else season.extend_cost(man), "cc": 0,
				"off": Contracts.refuses(man) or (man.years > 0 and not Contracts.can_extend(man)),
				"value": ClubOffice.money(int(round(_roll("wage",
					float(man.wage_agreed))))),
				"col": UiKit.INK,
				"bar": clampf(float(bill) / float(cap), 0.0, 1.0),
				"bar_col": UiKit.DOWN if bill > cap else UiKit.YOU}


## And the two lines under each row — label on the left, value on the right, the
## same two baselines in all four cells.
func _meeting_under(i: int) -> Array:
	match i:
		0:
			return [[UiKit.t("Strength"), "%d → %d" % [man.strength,
					int(round(_roll("str", float(man.fighting_strength()))))],
					## Red only when he fights BELOW his number — a boost is not a
					## warning (29 Sep 2026: "50 → 56" was drawn in the alarm colour).
					man.fighting_strength() < man.strength],
				[UiKit.t("Gas"), "%d → %d" % [man.gas,
					int(round(_roll("gas", float(man.fighting_gas()))))],
					man.fighting_gas() < man.gas]]
		1:
			return [[UiKit.t("Base"), "%d → %d" % [man.base,
					int(round(_roll("base", float(man.effective_base()))))],
					man.armor < 1.0],
				[UiKit.t("Inspection"), UiKit.t("passes") if man.passes_inspection() else UiKit.t("FAILS"),
					not man.passes_inspection()]]
		2:
			return [[UiKit.t("To the next"), UiKit.t("at his ceiling") if Career.at_ceiling(man)
					else (UiKit.t("ready") if Career.can_level(man)
						else UiKit.t("%d xp") % maxi(0, Career.next_level_at(man) - man.xp)),
					Career.can_level(man)],
				[UiKit.t("Ceiling"), str(man.potential), false]]
		_:
			var bill := ClubOffice.wage_bill(season.club)
			return [[UiKit.t("Wage bill"), UiKit.t("%s of %s") % [ClubOffice.money(bill),
					ClubOffice.money(season.office.cap())],
					bill > season.office.cap()],
				[UiKit.t("Years left"), str(int(round(_roll("years", float(man.years))))),
					man.years <= 0]]


## ONE DOOR FOR ALL FOUR PURCHASES, so the before-values are remembered in one
## place. Every number the card can move is snapshotted here rather than in four
## separate handlers — a roll that somebody forgets to start is a number that
## snaps while the three beside it count, and that reads as a bug in the ones
## that worked.
func _buy(which: String) -> void:
	var was := {
		"morale": man.morale, "kit": man.armor, "level": float(man.level),
		"xp": float(man.xp), "wage": float(man.wage_agreed),
		"years": float(man.years), "str": float(man.fighting_strength()),
		"gas": float(man.fighting_gas()), "base": float(man.effective_base()),
		"cc": float(season.office.credits), "power": float(season.club.power()),
	}
	var err := ""
	match which:
		"morale":
			err = season.office.negotiate(man)
			if err == "":
				flash = UiKit.t("%s is %s after a word.") % [man.display_name,
					man.morale_word().to_lower()]
		"kit":
			err = season.office.repair_kit(man)
			if err == "":
				flash = UiKit.t("The armorer went over %s's harness.") % man.display_name
		"level":
			err = season.office.buy_level(man)
			if err == "":
				flash = UiKit.t("%s has a level waiting after a week of extra reps.") \
					% man.display_name
		"deal":
			var out: bool = man.years <= 0
			err = season.resign(man) if out else season.extend(man)
			if err == "":
				flash = UiKit.tn("%s signed for %d year.", "%s signed for %d years.", man.years) \
					% [man.display_name, man.years]
	if err != "":
		## `said` already shakes once (3 Oct 2026); a second call shook twice.
		flash = UiKit.said(err)
		_build()
		return
	season.sync_power()
	for k in was:
		_start_roll(k, float(was[k]))
	Audio.play("coin")
	Session.autosave()
	_build()


func _draw() -> void:
	if man == null or season == null:
		return
	UiKit.set_mood(season.mood())
	UiKit.ground(self)

	## HIS PORTRAIT, IN THE HEADER, and NOT inside the left panel where it went
	## first — that panel's values are right-aligned into exactly the corner the
	## portrait wanted, so it would have printed straight through his age, weight
	## and contract. Invisible until the art existed, which is why placeholders
	## were generated to check it rather than reasoned about.
	##
	## 64px drawn at 64px, between the Hall button and the squad counter.
	ArtBank.portrait(self, Rect2(580, 8, 64, 64), man.overall(), man.display_name,
		man.number)
	UiKit.text(self, font, UiKit.t("%s  —  %s") % [man.pos_name().to_upper(),
		man.display_name.to_upper()], Vector2(24, 46), 24, UiKit.INK)
	var order := _order()
	UiKit.right(self, font, "#%d" % man.number,
		Vector2(UiKit.screen().x - 24, 46), 18, UiKit.DIM, 80)
	if not meeting_open:
		UiKit.mid(self, font, UiKit.t("%d of %d") % [order.find(man) + 1, order.size()],
			Vector2(684, UiKit.screen().y - 28.0), 13, UiKit.INK, PAGE_NEXT_X - 684.0)

	_the_man()
	_attributes()
	_the_book()

	## THE CARD GOES LAST AND OVER A SCRIM, because it is a modal and the three
	## panels under it are what it is a decision ABOUT — dimmed rather than
	## hidden, so the numbers it moves are still visible behind it.
	if meeting_open:
		_draw_meeting()

	if flash != "":
		## CLEAR OF THE BUTTON ROW. The row starts at `screen().y - 56`; at -66 a
		## 13px line's descenders were inside the buttons' own drop shadow, which
		## is what "when pressed, it's hidden" was describing.
		##
		## AND OVER THE TITLE WHILE THE LEVEL ROW IS UP (novice report 2: "Calder
		## put a level into strength" and "N more xp before he levels" were drawn
		## under the +3 buttons, so a spent point and a refusal both looked like
		## nothing). The band under the name is the one bus_note uses; the two
		## never show at once.
		## IN GOLD, NOT RED (3 Oct 2026): most of what lands here is good news —
		## a level spent, a man tagged for the Hall — and red is for danger. Fitted
		## at the size it is drawn, or a line could run 8% past its room.
		UiKit.text(self, font, UiKit.fit_px(font, flash, 14, UiKit.span()),
			Vector2(24, flash_y()), 14, UiKit.YOU)
	elif bus_note != "":
		## UNDER THE TITLE, NOT ABOVE THE BUTTONS. The first cut put it on the
		## same line the flash uses — and the ink sweep failed it at all four
		## canvas shapes with `'Calder cannot come off the bus: need eight.'
		## under '+1 Strength'`, because a man with a level to spend grows a row
		## of three buttons across exactly that y.
		##
		## The flash can live there: it appears after a tap, when the player is
		## looking at the button he tapped. This is standing state, drawn every
		## frame, so it needs somewhere that is free every frame — and the strip
		## under the fighter's name is the only band on this screen that is.
		UiKit.text(self, font, UiKit.fit_px(font, bus_note, 14, UiKit.span()),
			Vector2(24, 74), 14, UiKit.DIM)
	elif deal_note != "" and not meeting_open:
		UiKit.text(self, font, UiKit.fit_px(font, deal_note, 14, UiKit.span()),
			Vector2(24, 74), 14, UiKit.DIM)


## Where the flash line sits: above the button row, or under the title when the
## level row is up and would cover it.
##
## UNDER THE TITLE, ALWAYS (Pete, 4 Oct 2026: "Invest +3 ... whatever clicking it
## did hides behind 'Meeting · Ellis'"). The low line was clear of the footer
## row but not of the Meeting door, which sits on the same band — so every
## answer to a tap on this page that was not a level drew under a button.
func flash_y() -> float:
	return 74.0


# ------------------------------------------------------------------- column 1
func _the_man() -> void:
	UiKit.panel(self, Rect2(L_X, COL_Y, COL_W, col_h()))
	## HIS NAME, NOT "THE MAN" (playtest 30 Sep #12).
	UiKit.text_fit(self, font, man.display_name, Vector2(L_X + 16, COL_Y + UiKit.tk(26)), UiKit.tz(14), UiKit.INK, COL_W - 32.0)
	## THE LIST PAYS FOR THE TRAIT OUT OF ITS OWN RHYTHM, 22 instead of 24.
	##
	## The first cut grew `COL_H` by 14 instead, and the panel's new bottom ran
	## under the +1 button row — which the ink sweep did not catch, because the
	## text was inside the panel and the panel was the thing in the wrong place.
	## Six rows at two pixels tighter is invisible; a panel under a button is not.
	var ROW := UiKit.tk(22.0)
	var y := COL_Y + UiKit.tk(54.0)
	_line("Age", "%d" % man.age, y); y += ROW
	_line("Weight", UiKit.t("%d lb in harness") % man.weight, y); y += ROW
	## THREE WAGES, EACH NAMED (review, 1 Oct 2026): what he is on now, what he
	## asks at renewal, and what extending early costs.
	_line("Contract", UiKit.t("%s/yr  ·  %dy left") % [ClubOffice.money(ClubOffice.billed(man)),
		man.years] if man.years > 0 else UiKit.t("OUT OF CONTRACT"), y)
	y += ROW
	## AN INJURED MAN IS "OUT N EVENTS" WHERE HE WOULD BE (3 Oct 2026): the count
	## and the injury's name did not fit one 256px line, so the count moved here.
	_line("Where", (UiKit.tn("out %d event", "out %d events", man.injury) % man.injury) if man.injury > 0
		else (UiKit.t("the line") if season.club.starting_five().has(man)
		else (UiKit.t("the bench") if man.active else UiKit.t("reserve"))), y)
	y += ROW
	## HURT: what it is, and for how long, on the one line (Pete, 3 Oct 2026).
	if man.injury > 0:
		## "Hurt · 3" is the team sheet's own word for it: 3 = events he misses.
		## WITH ITS UNIT (3 Oct 2026): "Hurt · 3" left the 3 to be guessed. As a
		## pair, so the count and the injury's name cannot run into each other.
		UiKit.pair(self, font, UiKit.t("Hurt"), man.injury_word(), Vector2(L_X + 16, y),
			L_X + COL_W - 16, 14, 14, UiKit.DOWN, UiKit.DOWN)
	else:
		_line("Fit", UiKit.t("ready") if man.fit() else man.unfit_reason(), y)
	y += ROW
	## HIS MOOD, and it belongs on this list rather than in a panel of its own:
	## it is a fact about the man in the same way his weight is, and it is the one
	## on the list that you can do something about this week.
	UiKit.text(self, font, UiKit.t("Morale"), Vector2(L_X + 16, y), 14, UiKit.DIM)
	UiKit.right(self, font, man.morale_word(), Vector2(L_X + COL_W - 16, y), 13,
		man.morale_color(), 210)
	y += ROW

	## WHAT HE IS LIKE, AND THE GAME HAD NEVER SAID.
	##
	## Nine trait hooks are wired into the sim and tested — Wrestler, Second
	## Wind, Last Man, Proud, Talisman, Prima Donna, Homesick, Grudge, Heavy
	## Hands — and on 15 Sep 2026 `FighterTrait.name_of()` and `blurb_of()` had
	## no caller anywhere in `scripts/game/`. Every one of them was moving
	## numbers the player could feel and could not name.
	##
	## `is_flaw()` colors it, which is the whole reason that function exists:
	## a pool with no downside is a stat wearing a nicer hat, and a screen that
	## printed Prima Donna in the same color as Talisman would be hiding the
	## half that costs you something.
	if man.trait_id != FighterTrait.T.NONE:
		var flaw := FighterTrait.is_flaw(man.trait_id)
		UiKit.text(self, font, UiKit.t("Known for"), Vector2(L_X + 16, y), UiKit.tz(14), UiKit.DIM)
		UiKit.right(self, font, FighterTrait.name_of(man.trait_id),
			Vector2(L_X + COL_W - 16, y), UiKit.tz(14), UiKit.DOWN if flaw else UiKit.UP, 210)
		y += UiKit.tk(17.0)
		for line in UiKit.wrap(font, FighterTrait.blurb_of(man.trait_id),
				COL_W - 32.0, UiKit.tz(11)):
			UiKit.text(self, font, String(line), Vector2(L_X + 16, y), UiKit.tz(11),
				UiKit.EDGE.lightened(0.5))
			y += UiKit.tk(13.0)
		y += UiKit.tk(4.0)
	else:
		y += UiKit.tk(8.0)

	UiKit.text(self, font, UiKit.t("RATING"), Vector2(L_X + 16, y), UiKit.tz(11), UiKit.DIM)
	UiKit.stars(self, Vector2(L_X + 16, y + 8), man.overall(), UiKit.YOU, 13.0, 4.0)
	UiKit.text(self, font, "%d" % man.overall(), Vector2(L_X + 116, y + 20), 15, UiKit.INK)

	UiKit.text(self, font, UiKit.t("CEILING"), Vector2(L_X + 156, y), UiKit.tz(11), UiKit.DIM)
	UiKit.stars(self, Vector2(L_X + 156, y + 8), man.potential, UiKit.UP, 13.0, 4.0)
	UiKit.text(self, font, "%d" % man.potential, Vector2(L_X + 256, y + 20), 15,
		UiKit.UP if man.headroom() > 0 else UiKit.DIM)
	y += UiKit.tk(44.0)

	## HIS LEVEL, AND WHAT IS WAITING TO BE SPENT.
	##
	## This panel described the old model for a while after the model changed:
	## it walked the `xp_cost` ladder — 8, 12, 18, 26, 40 — and reported "3 points
	## ready", which was true of a winter that no longer happens. Levelling is
	## `next_level_at` now, it lands the moment it is earned, and the point is
	## the player's to place. A screen that explains a system the game has
	## replaced is worse than a screen that explains nothing.
	## `next_level_at` carries the age term now, so this one number is both the
	## price of his next level and the statement that he is slow.
	var bar := Career.next_level_at(man)
	var capped: bool = Career.at_ceiling(man)
	var waiting: bool = Career.can_place(man)
	UiKit.text(self, font, UiKit.t("LEVEL"), Vector2(L_X + 16, y), 11, UiKit.DIM)
	UiKit.text(self, font, "%d" % man.level, Vector2(L_X + 70, y + 2), 15, UiKit.INK)
	## TWO STATES. "A level waiting with nowhere to put it" was a third message
	## written for a case a peak-as-a-wall rule created, and that rule lasted one
	## pass. Only 99 in all four gets a man there now, and a screen that keeps
	## explaining a rule the game no longer has is the `xp_cost` ladder again.
	## THE SAME COUNT AS THE TEAM SHEET'S "+3" (review, 1 Oct 2026).
	var banked := maxi(1, Career.levels_banked(man))
	## LEVELS, NOT POINTS (round 2, 2 Oct: "3 POINTS TO SPEND" over buttons that
	## each give +3 read as nine points). The count is levels; the line under says
	## what one buys.
	var word := (UiKit.tn("%d LEVEL TO SPEND", "%d LEVELS TO SPEND", banked) % banked) if waiting \
		else UiKit.t("%d / %d xp") % [man.xp, bar]
	var tint := UiKit.YOU if waiting else UiKit.DIM
	if capped:
		word = UiKit.t("at his ceiling")
		tint = UiKit.EDGE.lightened(0.5)
	## MEASURED AGAINST "LEVEL 1" (round 7: the two printed through each other).
	UiKit.right_fit(self, font, word, Vector2(L_X + COL_W - 16, y), UiKit.tz(14), tint, COL_W - 32.0 - 76.0)
	UiKit.bar(self, Rect2(L_X + 16, y + UiKit.tk(12), COL_W - 32, UiKit.tk(14)),
		1.0 if waiting else clampf(float(man.xp) / float(maxi(1, bar)), 0.0, 1.0),
		UiKit.DIM if capped
			else (UiKit.YOU if waiting else UiKit.SELECT))
	## A FULL BAR SAYS WHY IT IS FULL (item 2): the level is earned and waiting.
	if waiting and not capped:
		## NO NUMBER IN IT (review, 2 Oct: "+1s" under buttons that read "+3", and
		## cut at the panel's edge). The buttons say what a point buys.
		UiKit.text_fit(self, font, UiKit.t("Each level: +%d to one stat below.") % Career.POINTS_PER_LEVEL,
			Vector2(L_X + 16, y + UiKit.tk(40.0)), UiKit.tz(12), UiKit.YOU, COL_W - 32.0)
	else:
		_pace(y + UiKit.tk(38.0))
	## WHAT HE WILL ASK FOR WHEN THE DEAL ENDS, which is the whole reason a level
	## is free today. `Contracts.demand` splits the fighter's price from the
	## relationship's, so both halves are on the screen rather than one number the
	## player has to take on trust.
	var asks: Dictionary = Contracts.demand(man)
	## ONLY WHEN IT SAYS SOMETHING THE EXTEND BUTTON DOES NOT (round 8: the panel
	## was too full). Same price, same years: the button below already says it.
	var same: bool = man.years > 0 and not bool(asks["refuses"]) \
		and season.resign_cost(man) == season.extend_cost(man)
	if same:
		return
	## ONLY WHERE THERE IS ROOM IN THE PANEL (playtest 30 Sep #10: a two-line
	## trait pushed this line through the panel's bottom edge).
	var ay := y + UiKit.tk(56.0)
	if ay > COL_Y + col_h() - 8.0:
		return
	if bool(asks["refuses"]):
		UiKit.text(self, font, UiKit.t("He will not sign again."),
			Vector2(L_X + 16, ay), UiKit.tz(14), UiKit.DOWN)
	else:
		## TWO PRICES, NAMED APART (blind review, 29 Sep: "$23 disagrees with $24").
		## Extending now and re-signing when the deal runs out are different deals.
		## PHONE SIZES ON A TABLET (3 Oct 2026): label and price share 256px that does
		## not widen, and scaled up they ran into each other.
		UiKit.text(self, font, UiKit.t("Asks at renewal"), Vector2(L_X + 16, ay), 14, UiKit.DIM)
		## The price the club would actually pay (a Negotiator captain included),
		## from the same function `Season.resign` charges.
		var wage_asked: int = season.resign_cost(man) if season != null else int(asks["wage"])
		UiKit.right(self, font, UiKit.t("%s/yr · %dy") % [
			ClubOffice.money(wage_asked), int(asks["years"])],
			Vector2(L_X + COL_W - 16, ay), 12,
			## A DEARER ASK IS A PRICE, NOT A DANGER (3 Oct 2026): gold, not red.
			UiKit.YOU if float(asks["mood"]) > 1.02 else (
				UiKit.UP if float(asks["mood"]) < 0.98 else UiKit.INK), 200)


## HOW FAST HE LEARNS, IN A WORD, under the xp bar.
##
## The bar already carries the fact — a thirty-eight-year-old's next level reads
## `12 / 48 xp` where a kid's reads `12 / 17 xp` — but only to a player holding
## both numbers at once, which is a player reading two fighters side by side and
## nobody else. The word says it on one screen.
##
## Nothing at all between x0.85 and x1.30, because a label on every fighter in
## the game is a label that says nothing about any of them.
func _pace(y: float) -> void:
	var word := Career.learn_word(man)
	if word == "" or Career.at_ceiling(man):
		return
	UiKit.text(self, font, word, Vector2(L_X + 16, y), UiKit.tz(10),
		UiKit.UP if Career.learn_rate(man) < 1.0 else UiKit.DIM)


## ==================================================== drawing the meeting
## FOUR CELLS ON ONE RHYTHM, and under each one the stat it moves.
##
## Pete, 14 Sep 2026: *"when you hit the buttons, you can actually see the effect
## — bars filling, Toxic rising to the next level, condition counting up in both
## areas, and contract/salary counting up to new numbers."* And then, on the
## first build: *"it definitely needs better formatting."*
##
## He was right. The first pass drew morale with two text lines and no bar,
## condition with a bar at one baseline, and the level and the deal with a bar at
## a different one — four arrangements rather than one shape, because each row
## was laid out where it happened to fit. Every cell now runs the same way down:
## a read-out and its button on one baseline, a full-width bar under them, and
## exactly two label/value lines on the same two baselines in all four.
##
## Every value goes through `_roll()`, which remembers where a number came from
## and walks it to wherever the card says it is NOW. Nothing caches a
## destination: the card always draws the man, and the roll only decides how far
## along the way it has got.
func _draw_meeting() -> void:
	draw_rect(UiKit.full_rect(), Color(0, 0, 0, 0.74))
	UiKit.panel(self, card())
	UiKit.mid(self, font, UiKit.t("MEETING: %s") % man.display_name.to_upper(),
		Vector2(card().position.x, card().position.y + 22.0), 19, UiKit.INK,
		card().size.x)
	## THE PURSE, ROLLING TOO. Spending is the other half of every row on this
	## card, and a balance that snaps while the effect counts is the card telling
	## you the price was free.
	UiKit.right(self, font, UiKit.t("%d CC") % int(round(_roll("cc",
		float(season.office.credits)))),
		Vector2(card().position.x + card().size.x - PAD, card().position.y + 22.0),
		17, UiKit.YOU, 200.0)

	for i in 4:
		_draw_cell(i)

	## A RULE, AND THE CLUB'S OWN NUMBER UNDER IT. Every one of the four rows can
	## move the club's rating and none of them shows it, so it goes at the foot
	## where a total belongs — on its own line rather than across the baseline of
	## the paging arrows, which is where the first pass put it.
	## Clear of the footer row, not across its baseline — which is where the
	## first pass put it, so the total and the paging arrows shared a line.
	var ry := card_close_y() - 32.0
	draw_rect(Rect2(card().position.x + PAD, ry, card().size.x - PAD * 2.0, 1.0),
		UiKit.FRAME)
	UiKit.mid(self, font, UiKit.t("club rating %d")
		% int(round(_roll("power", float(season.club.power())))),
		Vector2(card().position.x, ry + 20.0), 14, UiKit.DIM, card().size.x)


func _draw_cell(i: int) -> void:
	var c: Dictionary = _meeting_row(i)
	var at := _cell_at(i)
	var off: bool = bool(c["off"])

	## The read-out, in its own box, exactly as their screen has it.
	var box := Rect2(at.x, at.y, READ_W, HEAD_H)
	draw_rect(box, UiKit.TRACK)
	draw_rect(box, UiKit.FRAME, false, 1.0)
	UiKit.mid(self, font, String(c["label"]), at + Vector2(0, 16.0), 11,
		UiKit.DIM, READ_W)
	UiKit.mid(self, font, String(c["value"]), at + Vector2(0, 35.0), 15,
		UiKit.DIM if off else Color(c["col"]), READ_W)

	## THE BAR RUNS THE WHOLE CELL, not just the width of the read-out above it.
	## It is the answer to the button beside it as much as to the box, and a bar
	## that stops short of the control it belongs to reads as belonging to
	## neither.
	UiKit.bar(self, Rect2(at.x, at.y + BAR_Y, cell_w(), BAR_H),
		clampf(float(c["bar"]), 0.0, 1.0),
		UiKit.EDGE if off else Color(c["bar_col"]))

	## And the two lines, on the same baselines in every cell.
	var lines: Array = _meeting_under(i)
	for k in mini(2, lines.size()):
		var row: Array = lines[k]
		var y := at.y + (LINE_1 if k == 0 else LINE_2)
		UiKit.text(self, font, String(row[0]), Vector2(at.x, y), 12, UiKit.DIM)
		UiKit.right(self, font, String(row[1]), Vector2(at.x + cell_w(), y), 13,
			man.morale_color() if bool(row[2]) else UiKit.INK, 170.0)


func _line(label: String, value: String, y: float) -> void:
	## 14 ON EVERY SCREEN: "Contract  $20/yr · 2y left" fills 256 already (3 Oct 2026).
	UiKit.text(self, font, UiKit.t(label), Vector2(L_X + 16, y), 14, UiKit.DIM)
	UiKit.right(self, font, value, Vector2(L_X + COL_W - 16, y), 14, UiKit.INK, 210)


# ------------------------------------------------------------------- column 2
## THE FOUR THAT TRAIN, and the ceiling drawn on the same track as the value.
##
## A bar that shows only what a man has tells you nothing about whether to spend
## a winter on him. The faint segment past the fill is the room he has left,
## which is the number the decision actually turns on.
func _attributes() -> void:
	UiKit.panel(self, Rect2(M_X, COL_Y, COL_W, col_h()))
	## STATISTICS, OUT OF 100, WITH WHERE HE CAN GROW (Pete, playtest 30 Sep
	## #11: "make the yellow bar go to their current stats, but an outlined red
	## box up to their potential and mark it").
	UiKit.text(self, font, UiKit.t("STATISTICS"), Vector2(M_X + 16, COL_Y + UiKit.tk(26)), UiKit.tz(12), UiKit.DIM)
	UiKit.right(self, font, UiKit.t("out of 100"), Vector2(M_X + COL_W - 16, COL_Y + UiKit.tk(26)), UiKit.tz(12), UiKit.DIM, 120)
	## THE VALUE AND WHAT HE ACTUALLY FIGHTS AT. An angry man hits harder and a
	## toxic one lasts longer — the melee reads `fighting_strength()` and
	## `fighting_gas()`, so this panel reads them too rather than drawing the
	## stored number and letting the fight disagree with the card.
	var rows := [
		{"n": UiKit.t("Strength"), "v": man.strength, "f": man.fighting_strength(), "w": UiKit.t("puts men down")},
		{"n": UiKit.t("Base"), "v": man.base, "f": man.base, "w": UiKit.t("stays on his feet")},
		{"n": UiKit.t("Skill"), "v": man.skill, "f": man.skill, "w": UiKit.t("takedowns and escapes")},
		{"n": UiKit.t("Gas"), "v": man.gas, "f": man.fighting_gas(), "w": UiKit.t("how long he lasts")},
	]
	var y := COL_Y + UiKit.tk(54.0)
	for row in rows:
		var base: int = int(row["v"])
		var fights_at: int = int(row["f"])
		var chipped: bool = fights_at != base
		## THE NAME AND "50 → 56  max 100" SHARE 256 PX: 14 on every screen.
		UiKit.text(self, font, String(row["n"]), Vector2(M_X + 16, y), 14, UiKit.INK)
		## WHERE THIS STAT CAN GO: his headroom spread evenly over the four, the
		## way the winter and the levels spend it. A man at his ceiling has no
		## box at all.
		var grow: int = mini(100, base + int(ceil(float(man.headroom()) / 0.92)))
		UiKit.right(self, font,
			("%d → %d" % [base, fights_at]) if chipped else ("%d" % base),
			Vector2(M_X + COL_W - 16 - (66.0 if grow > base else 0.0), y), 14,
			_chip_col(fights_at, base) if chipped else UiKit.INK, 110)
		## THE HEADROOM IS GOOD NEWS (3 Oct 2026): in the gain color, not red.
		if grow > base:
			UiKit.right(self, font, UiKit.t("max %d") % grow, Vector2(M_X + COL_W - 16, y), 12, UiKit.DIM, 62)
		var track := Rect2(M_X + 16, y + UiKit.tk(8), COL_W - 32, UiKit.tk(13))
		UiKit.bar(self, track, float(base) / 100.0, UiKit.YOU)
		if grow > base:
			var gx0 := track.position.x + track.size.x * (float(base) / 100.0)
			var gx1 := track.position.x + track.size.x * (float(grow) / 100.0)
			draw_rect(Rect2(gx0, track.position.y - 1.0, gx1 - gx0, track.size.y + 2.0), UiKit.UP, false, 2.0)
		## The chip drawn past the fill, so you can see what the mood is buying.
		if chipped:
			var x0 := track.position.x + track.size.x * (float(base) / 100.0)
			var x1 := track.position.x + track.size.x * (float(fights_at) / 100.0)
			draw_rect(Rect2(x0, track.position.y, maxf(2.0, x1 - x0), track.size.y),
				_chip_col(fights_at, base))
		## NO CEILING TICK ON THESE BARS. The first version drew one at
		## `potential` on every stat, which says a man has a ceiling per stat.
		## He does not — `potential` is a ceiling on his OVERALL, and the winter
		## spends points wherever they will do the most good. Four identical
		## ticks claiming four separate limits is a picture of a rule the game
		## does not have.
		UiKit.text_fit(self, font, String(row["w"]), Vector2(M_X + 16, y + UiKit.tk(37)), UiKit.tz(13),
			UiKit.DIM, COL_W - 32.0)
		y += UiKit.tk(66.0)
	## ONE SHORT LINE ON THE SAME BASELINE EITHER WAY.
	##
	## Two mistakes in a row here. First a 64-character sentence along the bottom
	## of a 280-pixel panel: it clipped mid-word and the tail crossed into the
	## third column — the panel's width IS the sentence's length, and nothing here
	## wraps. Then two short lines instead, which fit and then sat four pixels
	## under the last stat's caption. There is exactly one line of room at the
	## bottom of this panel, so it is one line, on the baseline the contented
	## version already proved clear.
	UiKit.text_fit(self, font,
		(UiKit.t("%s: a boost, for now.") % man.morale_word()) if man.angry()
			else UiKit.t("Green box: his room to grow, shared by all four."),
		## PHONE SIZE ON A TABLET TOO (3 Oct 2026): the column does not widen, and
		## at 16px the legend was cut to "how far he can gr.".
		Vector2(M_X + 16, COL_Y + col_h() - 14), 13,
		UiKit.YOU if man.angry() else UiKit.DIM, COL_W - 32.0)


## A STAT HIS MOOD LIFTS IS A GAIN (3 Oct 2026): a Toxic man's "50 → 56" was
## drawn in the mood's red, which read the buff as damage. The line under the
## panel keeps the warning, in gold — a boost, for now; a mood that drags a stat
## down keeps the mood's own color.
func _chip_col(fights_at: int, base: int) -> Color:
	return UiKit.UP if fights_at > base else man.morale_color()


# ------------------------------------------------------------------- column 3
func _the_book() -> void:
	UiKit.panel(self, Rect2(R_X, COL_Y, COL_W, col_h()))
	UiKit.text(self, font, UiKit.t("HIS RECORD"), Vector2(R_X + 16, COL_Y + UiKit.tk(26)), UiKit.tz(12), UiKit.DIM)
	if man.bouts <= 0:
		UiKit.text_fit(self, font, UiKit.t("No events for you yet."),
			Vector2(R_X + 16, COL_Y + UiKit.tk(64)), UiKit.tz(14), UiKit.DIM, COL_W - 32.0)
		UiKit.para(self, font, UiKit.t("His record starts at his first event."),
			Vector2(R_X + 16, COL_Y + UiKit.tk(92)), UiKit.tz(14), UiKit.EDGE.lightened(0.5), COL_W - 32.0, UiKit.tk(18.0))
		return
	var y := COL_Y + UiKit.tk(56.0)
	var rp := UiKit.tk(26.0)
	_book("Events", "%d" % man.bouts, y); y += rp
	_book("Downs caused", "%d" % man.downs, y); y += rp
	_book("Assists", "%d" % man.assists, y); y += rp
	_book("Per event", "%.2f" % man.downs_per_bout(), y); y += rp
	_book("Best event", "%d" % man.best_downs, y); y += rp
	_book("Rounds standing", "%d" % man.rounds_standing, y); y += rp
	_book("Carried off", "%d" % man.knocks, y); y += UiKit.tk(34.0)
	UiKit.text(self, font, UiKit.t("HONORS"), Vector2(R_X + 16, y), UiKit.tz(11), UiKit.DIM)
	if man.honors <= 0:
		UiKit.text(self, font, UiKit.t("Nothing yet."), Vector2(R_X + 16, y + UiKit.tk(22)), UiKit.tz(14), UiKit.DIM)
	else:
		UiKit.text(self, font, (UiKit.t("%d cup") if man.honors == 1 else UiKit.t("%d cups")) % man.honors,
			Vector2(R_X + 16, y + UiKit.tk(22)), UiKit.tz(16), UiKit.YOU)


func _book(label: String, value: String, y: float) -> void:
	UiKit.text(self, font, UiKit.t(label), Vector2(R_X + 16, y), UiKit.tz(14), UiKit.DIM)
	UiKit.right(self, font, value, Vector2(R_X + COL_W - 16, y), UiKit.tz(14), UiKit.INK, 120)


## A levelling run ends when the page is left.
func _exit_tree() -> void:
	Session.level_run = false
