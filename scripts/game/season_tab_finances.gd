class_name SeasonFinancesTab
extends RefCounted
## Methods of `SeasonScene`, moved out of season_scene.gd so that file is not one
## three-thousand-line object. Every function takes the SeasonScene as `v`; `SeasonScene`
## keeps a one-line wrapper for each, so callers did not change.




## The foot of the books, either way; `_fin_row` translates it.
const NET_WORD := ["AHEAD SO FAR", "SHORT SO FAR"]


static func _finances_controls(v: SeasonScene) -> void:
	## THE GROUND, from the page that talks about what it earns. Pete asked for
	## the arena to live here and it half does: the numbers are on this screen and
	## the building is one tap away, which is better than a sixth copy of the
	## build button.
	v.ui.add_child(UiKit.button(UiKit.t("The ground"), Vector2(SeasonScene.FIN_RIGHT, SeasonScene.FIN_BUTTONS_Y),
		Vector2(200, 44), func():
			Session.autosave()
			UiKit.go("res://scenes/Arena.tscn"), "gate"))
	## AND THE COUNTER. It was on the Clubhouse, which is Pete's *"Clubhouse is
	## too crowded"* — and it belongs on the page about money rather than the page
	## about buildings.
	v.ui.add_child(UiKit.button(UiKit.t("Buy credits"), Vector2(SeasonScene.FIN_RIGHT + 216.0, SeasonScene.FIN_BUTTONS_Y),
		Vector2(200, 44), func():
			v.shop_open = true
			v._rebuild(), "coin"))




static var _has_last := true


## THE YEAR IN HAND AND THE YEAR BEFORE IT, in two columns.
static func _draw_finances(v: SeasonScene) -> void:
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
	var y := SeasonScene.CONTENT_Y + 26.0
	y = v._fin_block(o.books_in, was_in, ClubOffice.IN_ORDER, y, UiKit.UP)
	var in_now := ClubOffice.book_total(o.books_in)
	var in_was := ClubOffice.book_total(was_in)
	y = v._fin_rule(y)
	v._fin_row("Everything in", in_now, in_was, y, UiKit.INK, 15)

	y += 38.0
	UiKit.text(v, v.font, UiKit.t("GOING OUT, CC"), Vector2(SeasonScene.FIN_LEFT, y), 14, UiKit.DIM)
	y += 26.0
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
	var words := UiKit.t("So far this year. Gates and prize money arrive as the events are fought.") \
		if net < 0 else UiKit.t("So far this year.")
	UiKit.para(v, v.font, words, Vector2(SeasonScene.FIN_LEFT + 14.0, y + 22.0), 14, UiKit.DIM,
		SeasonScene.FIN_WAS - SeasonScene.FIN_LEFT - 14.0, 18.0, 2)
	## AND THE LEVERS, by name (blind review round 3: "no path to fix it").
	if net < 0:
		UiKit.text_fit(v, v.font, UiKit.t("To close it: win, fill the ground, trim wages."),
			Vector2(SeasonScene.FIN_LEFT + 14.0, y + 62.0), 14, UiKit.YOU,
			SeasonScene.FIN_WAS - SeasonScene.FIN_LEFT - 14.0)

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
		return y + SeasonScene.FIN_ROW
	for r in rows:
		var line := String(r["line"])
		v._fin_row(line, int(r["cc"]), int(was.get(line, 0)), y,
			col if int(r["cc"]) > 0 else UiKit.DIM)
		y += SeasonScene.FIN_ROW
	return y




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
	UiKit.text(v, v.font, UiKit.t("THE GROUND"), Vector2(SeasonScene.FIN_RIGHT, SeasonScene.CONTENT_Y), 14, UiKit.DIM)
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
			Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM, UiKit.DIM)
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
		UiKit.DIM if short <= 0 else UiKit.DOWN)
	y += 22.0
	if a.condition < 0.999 and a.level >= Arena.WEARS_FROM_LEVEL:
		UiKit.pair(v, v.font, UiKit.t("Putting it right"), UiKit.t("%d CC") % a.upkeep_cost(),
			Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM, UiKit.YOU)
	else:
		UiKit.pair(v, v.font, UiKit.t("Putting it right"), UiKit.t("nothing to do"),
			Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM,
			UiKit.DIM)

	## AND THE CROWD, because it is the other half of what a ground earns and it
	## is the half the probes found nobody was being told about: at the bottom of
	## the pyramid the gate is worth about a credit and a half a SEASON.
	y += 34.0
	UiKit.text(v, v.font, UiKit.t("THE CROWD"), Vector2(SeasonScene.FIN_RIGHT, y), 14, UiKit.DIM)
	y += 26.0
	UiKit.pair(v, v.font, UiKit.t("They put through the door"),
		UiKit.t("%s  ·  %d%% full") % [UiKit.crowd_word(o.attendance()),
			int(round(o.fill() * 100.0))],
		Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM, UiKit.DIM)
	y += 22.0
	UiKit.pair(v, v.font, UiKit.t("A home fight pays"), UiKit.t("%d CC") % o.crowd_pay(),
		Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 14, UiKit.DIM, UiKit.DIM)
	y += 22.0
	## AND THE BAR, which is the half that does not swing with the results. It is
	## on this page rather than the arena's because the whole reason it exists is
	## that it is a different KIND of income, and this is the page about that.
	UiKit.pair(v, v.font, Arena.sells(a.level),
		UiKit.t("%d CC") % Arena.counter_take(a.level, o.attendance()),
		Vector2(SeasonScene.FIN_RIGHT, y), UiKit.right_edge(), 14, 13,
		UiKit.DIM, UiKit.DIM)
	## TWO CURRENCIES, SAID ONCE (Pete, 29 Sep 2026, #7): CC is the club's money
	## and $ is the men's pay. Both appear across the game; this is the page
	## about money, so this is where the difference is written down.
	UiKit.text_fit(v, v.font, UiKit.t("CC is club money. $ is weekly pay."),
		Vector2(SeasonScene.FIN_RIGHT, y + 26.0), 14, UiKit.DIM, UiKit.right_edge() - SeasonScene.FIN_RIGHT)
