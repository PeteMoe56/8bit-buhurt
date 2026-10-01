class_name SeasonFinancesTab
extends RefCounted
## Methods of `SeasonScene`, moved out of season_scene.gd so that file is not one
## three-thousand-line object. Every function takes the SeasonScene as `v`; `SeasonScene`
## keeps a one-line wrapper for each, so callers did not change.




## The foot of the books, either way; `_fin_row` translates it.
const NET_WORD := ["AHEAD SO FAR", "SHORT SO FAR"]


static func _finances_controls(v: SeasonScene) -> void:
	if v.fin_full:
		v.ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(24, SeasonScene.action_y()),
			Vector2(200, 44), func():
				v.fin_full = false
				v._rebuild()))
		v.ui.add_child(UiKit.button(UiKit.t("Buy credits"), Vector2(240, SeasonScene.action_y()),
			Vector2(200, 44), func():
				v.shop_open = true
				v._rebuild(), "coin"))
		return
	## MANAGEMENT (Pete, 1 Oct 2026): Finances, Staff, You — each a summary and
	## the button that opens all of it.
	var pw := panel_w()
	var by := panel_bottom() - 54.0
	v.ui.add_child(UiKit.button(UiKit.t("Finances"), Vector2(panel_x(0) + 14.0, by), Vector2(pw - 28.0, 40),
		func():
			v.fin_full = true
			v._rebuild(), "purse"))
	v.ui.add_child(UiKit.button(UiKit.t("Staff"), Vector2(panel_x(1) + 14.0, by), Vector2(pw - 28.0, 40),
		func():
			Session.autosave()
			UiKit.go("res://scenes/Staff.tscn"), "helm"))
	var half := (pw - 36.0) * 0.5
	v.ui.add_child(UiKit.button(UiKit.t("Playbook"), Vector2(panel_x(2) + 14.0, by), Vector2(half, 40),
		func():
			Session.autosave()
			UiKit.go("res://scenes/Chalkboard.tscn"), "board"))
	v.ui.add_child(UiKit.button(UiKit.t("Team edit"), Vector2(panel_x(2) + 22.0 + half, by), Vector2(half, 40),
		func():
			Session.autosave()
			Session.create_tab = 1
			UiKit.go("res://scenes/Create.tscn"), "anvil"))
	## A RED WARNING CARRIES ITS FIX (review, 1 Oct 2026).
	var o := v.season.office
	if not o.untaught().is_empty():
		var names := ""
		for r in o.untaught():
			names += ("" if names == "" else UiKit.t(" and ")) + UiKit.t(String(Tuning.ROLE_NAME[r]))
		var yy := panel_top() + 74.0 + float(o.captains.size()) * 42.0 + (22.0 if o.captains.is_empty() else 0.0)
		v.ui.add_child(UiKit.danger(UiKit.button(UiKit.t("Hire for %s") % names, Vector2(panel_x(1) + 14.0, yy - 4.0),
			Vector2(pw - 28.0, 32), func():
				Session.staff_browse = true
				Session.autosave()
				UiKit.go("res://scenes/Staff.tscn"), "helm")))
	## A POINT TO SPEND opens the coach's page, where the + buttons are.
	var c := v.season.coach
	if c.points > 0:
		var ry := panel_top() + 56.0 + YOU_SKILL_Y + 5.0 * YOU_ROW - 14.0
		## NOT GOLD: the hub has one gold button and it is the way forward (C3).
		v.ui.add_child(UiKit.button(UiKit.tn("Spend %d point", "Spend %d points", c.points) % c.points,
			Vector2(panel_x(2) + 14.0, ry), Vector2(pw - 28.0, 34), func():
				Session.autosave()
				UiKit.go("res://scenes/Coach.tscn"), "ladder"))


const PANEL_GAP := 12.0


static func panel_w() -> float:
	return (UiKit.span() - PANEL_GAP * 2.0) / 3.0


static func panel_x(i: int) -> float:
	return 24.0 + float(i) * (panel_w() + PANEL_GAP)


static func panel_top() -> float:
	return SeasonScene.CONTENT_Y - 6.0


static func panel_bottom() -> float:
	return SeasonScene.action_y() - 12.0


static func _draw_management(v: SeasonScene) -> void:
	var o := v.season.office
	var pw := panel_w()
	for i in 3:
		UiKit.panel(v, Rect2(panel_x(i), panel_top(), pw, panel_bottom() - panel_top()))
	var heads := [UiKit.t("FINANCES  ·  THIS YEAR"), UiKit.t("STAFF"), UiKit.t("YOU")]
	for i in 3:
		UiKit.text_fit(v, v.font, heads[i], Vector2(panel_x(i) + 14.0, panel_top() + 24.0), 13, UiKit.DIM, pw - 28.0)
	# ---- finances
	var x := panel_x(0) + 14.0
	var w := pw - 28.0
	var y := panel_top() + 60.0
	var i_n := ClubOffice.book_total(o.books_in)
	var o_n := ClubOffice.book_total(o.books_out)
	UiKit.pair(v, v.font, UiKit.t("In"), UiKit.t("%d CC") % i_n, Vector2(x, y), x + w, 20, 20, UiKit.INK, UiKit.UP)
	y += 32.0
	UiKit.pair(v, v.font, UiKit.t("Out"), UiKit.t("%d CC") % o_n, Vector2(x, y), x + w, 20, 20, UiKit.INK, UiKit.DOWN)
	y += 14.0
	v.draw_line(Vector2(x, y), Vector2(x + w, y), UiKit.FRAME, 1.0)
	y += 28.0
	var net := i_n - o_n
	UiKit.pair(v, v.font, UiKit.t("Total"), UiKit.t("%+d CC") % net, Vector2(x, y), x + w, 22, 22, UiKit.INK,
		UiKit.UP if net >= 0 else UiKit.DOWN)
	y += 34.0
	UiKit.para(v, v.font, UiKit.t("%d CC in hand. Gates and prizes land as events are fought.") % o.credits,
		Vector2(x, y), 13, UiKit.DIM, w, 17.0, 3)
	# ---- staff
	x = panel_x(1) + 14.0
	y = panel_top() + 52.0
	UiKit.text(v, v.font, UiKit.t("CAPTAINS"), Vector2(x, y), 12, UiKit.DIM)
	y += 22.0
	if o.captains.is_empty():
		UiKit.text_fit(v, v.font, UiKit.t("Nobody teaching."), Vector2(x, y), 14, UiKit.DOWN, w)
		y += 22.0
	for c in o.captains:
		UiKit.text_fit(v, v.font, String(c.get("name", "?")), Vector2(x, y), 15, UiKit.INK, w - 70.0)
		UiKit.stars(v, Vector2(x + w - 64.0, y - 11.0), int(c.get("grade", 1)) * 20, UiKit.YOU, 11.0, 2.0)
		y += 18.0
		var t := ClubOffice.trait_of(c)
		var line := ClubOffice.teaches_line(c)
		if t != ClubOffice.Trait.NONE:
			line = UiKit.t("%s  ·  %s") % [UiKit.t(String(ClubOffice.TRAIT_NAME[t])), line]
		UiKit.text_fit(v, v.font, line, Vector2(x, y), 12, UiKit.DIM, w)
		y += 24.0
	if not o.untaught().is_empty():
		## THE WARNING IS A BUTTON (built in the controls): it opens the captain list.
		y += 34.0
	SeasonFinancesTab._draw_armorer_line(v, x, y + 6.0, w)
	# ---- you
	x = panel_x(2) + 14.0
	y = panel_top() + 56.0
	SeasonFinancesTab._draw_you(v, x, y, w)


## THE ARMORER, under the captains. Filled in by the armorer's own patch.
static func _draw_armorer_line(v: SeasonScene, x: float, y: float, w: float) -> void:
	var a: Dictionary = v.season.office.armorer
	UiKit.text(v, v.font, UiKit.t("ARMORER"), Vector2(x, y), 12, UiKit.DIM)
	y += 22.0
	UiKit.text_fit(v, v.font, String(a.get("name", "")), Vector2(x, y), 15, UiKit.INK, w - 70.0)
	UiKit.stars(v, Vector2(x + w - 64.0, y - 11.0), int(a.get("stars", 1)) * 20, UiKit.YOU, 11.0, 2.0)
	UiKit.text_fit(v, v.font, UiKit.t("Makes up to %s") % Armorer.metal_name(Armorer.cap_of(a)),
		Vector2(x, y + 18.0), 12, UiKit.DIM, w)


const YOU_SKILL_Y := 64.0
const YOU_ROW := 24.0


static func _draw_you(v: SeasonScene, x: float, y: float, w: float) -> void:
	var c := v.season.coach
	UiKit.text_fit(v, v.font, c.display_name, Vector2(x, y), 19, UiKit.YOU, w)
	UiKit.text_fit(v, v.font, UiKit.t("%s  ·  level %d") % [Coach.background_name(c.background), c.level],
		Vector2(x, y + 20.0), 13, UiKit.DIM, w)
	UiKit.bar(v, Rect2(x, y + 30.0, w, 9), float(c.xp) / float(Coach.need(c.level)), UiKit.YOU)
	for i in 5:
		var sy := y + YOU_SKILL_Y + float(i) * YOU_ROW
		UiKit.text_fit(v, v.font, Coach.skill_name(i), Vector2(x, sy), 14, UiKit.INK, w - 110.0)
		UiKit.stars(v, Vector2(x + w - 104.0, sy - 11.0), c.skill(i) * 20, UiKit.YOU, 11.0, 2.0)
	var ry := y + YOU_SKILL_Y + 5.0 * YOU_ROW + 4.0
	if c.points <= 0:
		UiKit.text_fit(v, v.font, UiKit.t("Record %s") % c.record_line(), Vector2(x, ry), 13, UiKit.DIM, w)




static var _has_last := true


## THE YEAR IN HAND AND THE YEAR BEFORE IT, in two columns — behind the
## Management tab's Finances button.
static func _draw_finances(v: SeasonScene) -> void:
	if not v.fin_full:
		_draw_management(v)
		return
	var o := v.season.office
	var last: Dictionary = o.books_last
	var was_in: Dictionary = last.get("in", {})
	var was_out: Dictionary = last.get("out", {})

	UiKit.text(v, v.font, UiKit.t("COMING IN, CC"), Vector2(SeasonScene.FIN_LEFT, SeasonScene.CONTENT_Y), 14, UiKit.DIM)
	## LAST YEAR ONLY WHEN THERE WAS ONE (round 4: a column of dashes).
	_has_last = not last.is_empty() and (ClubOffice.book_total(was_in) != 0 or ClubOffice.book_total(was_out) != 0)
	UiKit.right(v, v.font, UiKit.t("this year"), Vector2(SeasonScene.FIN_NOW, SeasonScene.CONTENT_Y), 12, UiKit.DIM, 110)
	if _has_last:
		UiKit.right(v, v.font, UiKit.t("last"), Vector2(SeasonScene.FIN_WAS, SeasonScene.CONTENT_Y), 12, UiKit.DIM, 90)
	## THE ROWS SHARE THE ROOM THERE IS (Pete, 1 Oct: the foot of the page ran off
	## the bottom). Ten headings in a season with everything going on would push
	## the one line that matters off the screen at 22 a row.
	var n_rows := _rows_of(o.books_in, was_in, ClubOffice.IN_ORDER) + _rows_of(o.books_out, was_out, ClubOffice.OUT_ORDER)
	_row_h = clampf((SeasonScene.action_y() - 12.0 - SeasonScene.CONTENT_Y - 166.0) / float(maxi(1, n_rows)),
		15.0, SeasonScene.FIN_ROW)
	var y := SeasonScene.CONTENT_Y + 26.0
	y = v._fin_block(o.books_in, was_in, ClubOffice.IN_ORDER, y, UiKit.UP)
	var in_now := ClubOffice.book_total(o.books_in)
	var in_was := ClubOffice.book_total(was_in)
	y = v._fin_rule(y)
	v._fin_row("Everything in", in_now, in_was, y, UiKit.INK, 15)

	y += 32.0
	UiKit.text(v, v.font, UiKit.t("GOING OUT, CC"), Vector2(SeasonScene.FIN_LEFT, y), 14, UiKit.DIM)
	y += 24.0
	y = v._fin_block(o.books_out, was_out, ClubOffice.OUT_ORDER, y, UiKit.DOWN)
	var out_now := ClubOffice.book_total(o.books_out)
	var out_was := ClubOffice.book_total(was_out)
	y = v._fin_rule(y)
	v._fin_row("Everything out", out_now, out_was, y, UiKit.INK, 15)

	## AND THE ONE LINE THE WHOLE PAGE IS FOR. Green or red, at the foot, because
	## "am I making money" is the question and everything above it is the working.
	y += 30.0
	var net := in_now - out_now
	v._fin_row(NET_WORD[0] if net >= 0 else NET_WORD[1], net, in_was - out_was, y,
		UiKit.UP if net >= 0 else UiKit.DOWN, 17)
	## WHAT THE NUMBER IS AND WHAT TO DO ABOUT IT (blind review, 29 Sep: "SHORT
	## -31" alarmed with no guidance). It is this year so far, not a forecast.
	## AND WHAT IS IN HAND, beside it (round 9: "SHORT -23" next to a 37 CC
	## purse read as a contradiction).
	## IN THE RIGHT COLUMN, under the ground, where there is room for it.
	var words := UiKit.t("This year so far. %d CC in hand now; gates and prizes arrive as events are fought.") % v.season.office.credits \
		if net < 0 else UiKit.t("This year so far. %d CC in hand now.") % v.season.office.credits
	var wy := SeasonScene.FIN_BUTTONS_Y + 6.0
	UiKit.para(v, v.font, words, Vector2(SeasonScene.FIN_RIGHT, wy), 14, UiKit.DIM,
		UiKit.right_edge() - SeasonScene.FIN_RIGHT, 18.0, 2)
	## AND THE LEVERS, by name (blind review round 3: "no path to fix it").
	if net < 0:
		UiKit.text_fit(v, v.font, UiKit.t("To close it: win, fill the ground, trim wages."),
			Vector2(SeasonScene.FIN_RIGHT, wy + 42.0), 14, UiKit.YOU,
			UiKit.right_edge() - SeasonScene.FIN_RIGHT)

	v._fin_ground()




## One heading and its figure in both columns.
static func _fin_row(v: SeasonScene, label: String, now: int, was: int, y: float, col: Color, px: int = 13) -> void:
	## "The squad" is signings, sessions and captains, all in CC — the wages
	## are $ and are not on this page (round 6: read as wages in CC).
	var shown := UiKit.t("Signings & training") if label == ClubOffice.LINE_SQUAD else UiKit.t(label)
	UiKit.text(v, v.font, shown, Vector2(SeasonScene.FIN_LEFT + 14.0, y), px, col)
	UiKit.right(v, v.font, "%d" % now, Vector2(SeasonScene.FIN_NOW, y), px, col, 90)
	## LAST YEAR IS DIMMED, ALWAYS, whatever this year's line is doing. It is
	## context, not news — coloring it would put two equally loud numbers on one
	## row and the eye would have to work out which one is the present.
	if _has_last:
		UiKit.right(v, v.font, "—" if was == 0 else "%d" % was,
			Vector2(SeasonScene.FIN_WAS, y), maxi(12, px - 2), UiKit.DIM, 90)




static func _fin_rule(v: SeasonScene, y: float) -> float:
	v.draw_line(Vector2(SeasonScene.FIN_LEFT + 14.0, y + 6.0), Vector2(SeasonScene.FIN_WAS, y + 6.0),
		UiKit.FRAME, 1.0)
	return y + 24.0




## Every heading with anything on it, in the order the office keeps them.
static func _fin_block(v: SeasonScene, now: Dictionary, was: Dictionary, order: Array[String], y: float, col: Color) -> float:
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
		UiKit.text(v, v.font, UiKit.t("Nothing yet."), Vector2(SeasonScene.FIN_LEFT + 14.0, y), 13,
			UiKit.DIM)
		return y + _row_h
	for r in rows:
		var line := String(r["line"])
		v._fin_row(line, int(r["cc"]), int(was.get(line, 0)), y,
			col if int(r["cc"]) > 0 else UiKit.DIM)
		y += _row_h
	return y


static var _row_h := 22.0


## How many rows a block will draw, before it draws them.
static func _rows_of(now: Dictionary, was: Dictionary, order: Array[String]) -> int:
	var seen := {}
	for r in ClubOffice.book_rows(now, order):
		seen[String(r["line"])] = true
	for r in ClubOffice.book_rows(was, order):
		seen[String(r["line"])] = true
	return maxi(1, seen.size())




## THE GROUND, ON THE PAGE ABOUT WHAT IT COSTS.
##
## Four lines and no more. The Arena screen is where a ground is looked at; this
## is where it is ACCOUNTED FOR, and the difference is that this side only cares
## about the two numbers that move money — what it pays and what it is costing
## you to let it go. **A summary that repeats the screen it points at is two
## screens disagreeing about which is the authority.**
static func _fin_ground(v: SeasonScene) -> void:
	var o := v.season.office
	var a := o.arena
	UiKit.text(v, v.font, UiKit.t("VENUE"), Vector2(SeasonScene.FIN_RIGHT, SeasonScene.CONTENT_Y), 14, UiKit.DIM)
	var y := SeasonScene.CONTENT_Y + 28.0
	UiKit.pair(v, v.font, a.arena_name(), a.condition_word(),
		Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 16, 13, UiKit.INK,
		UiKit.DOWN if a.shabby() else UiKit.DIM)
	y += 26.0

	## WHAT IT PAYS, and what it would pay kept. One line when the ground is
	## spotless, because "11 of 11" is a sum nobody needs to read.
	var pays := a.retainer()
	var full := a.retainer_full()
	if pays >= full:
		UiKit.pair(v, v.font, UiKit.t("Pays a year"), UiKit.t("%d CC") % full,
			Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM, UiKit.INK)
	else:
		## SHORTER THAN IT WAS. "%d CC — %d lost to the state of it" finished at
		## 958 of a 960 canvas and `UiKit.pair` right-aligns, so on any narrower
		## shape the sentence walked back over its own label.
		UiKit.pair(v, v.font, UiKit.t("Pays a year"),
			"%d CC  ·  %d lost to neglect" % [pays, full - pays],
			Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM, UiKit.DOWN)
	y += 22.0

	## THE WHOLE SUMMER, not just the ground's share of it: dues, every building
	## and every certificate. Red with the shortfall when the purse will not
	## cover it, because whatever goes unpaid falls a level.
	var bill := o.summer_bill()
	var short := bill - o.credits
	UiKit.pair(v, v.font, UiKit.t("The summer bill"),
		(UiKit.t("%d CC") % bill) if short <= 0 else (UiKit.t("%d CC  ·  %d short") % [bill, short]),
		Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM,
		UiKit.INK if short <= 0 else UiKit.DOWN)
	y += 22.0
	if a.condition < 0.999 and a.level >= Arena.WEARS_FROM_LEVEL:
		UiKit.pair(v, v.font, UiKit.t("Putting it right"), UiKit.t("%d CC") % a.upkeep_cost(),
			Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM, UiKit.YOU)
	else:
		UiKit.pair(v, v.font, UiKit.t("Putting it right"), UiKit.t("nothing to do"),
			Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM,
			UiKit.INK)

	## AND THE CROWD, because it is the other half of what a ground earns and it
	## is the half the probes found nobody was being told about: at the bottom of
	## the pyramid the gate is worth about a credit and a half a SEASON.
	y += 34.0
	UiKit.text(v, v.font, UiKit.t("THE CROWD"), Vector2(SeasonScene.FIN_RIGHT, y), 14, UiKit.DIM)
	y += 26.0
	UiKit.pair(v, v.font, UiKit.t("They put through the door"),
		UiKit.t("%s  ·  %d%% full") % [UiKit.crowd_word(o.attendance()),
			int(round(o.fill() * 100.0))],
		Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM, UiKit.INK)
	y += 22.0
	UiKit.pair(v, v.font, UiKit.t("A home fight pays"), UiKit.t("%d CC") % o.crowd_pay(),
		Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM, UiKit.INK)
	y += 22.0
	## AND THE BAR, which is the half that does not swing with the results. It is
	## on this page rather than the arena's because the whole reason it exists is
	## that it is a different KIND of income, and this is the page about that.
	UiKit.pair(v, v.font, Arena.sells(a.level),
		UiKit.t("%d CC") % Arena.counter_take(a.level, o.attendance()),
		Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 13,
		UiKit.DIM, UiKit.INK)
	## TWO CURRENCIES, SAID ONCE (Pete, 29 Sep 2026, #7): CC is the club's money
	## and $ is the men's pay. Both appear across the game; this is the page
	## about money, so this is where the difference is written down.
	UiKit.text_fit(v, v.font, UiKit.t("CC is club money. $ is weekly pay."),
		Vector2(SeasonScene.FIN_RIGHT, y + 26.0), 14, UiKit.DIM, UiKit.right_edge() - SeasonScene.FIN_RIGHT)
