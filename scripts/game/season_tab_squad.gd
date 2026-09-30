class_name SeasonSquadTab
extends RefCounted
## Methods of `SeasonScene`, moved out of season_scene.gd so that file is not one
## three-thousand-line object. Every function takes the SeasonScene as `v`; `SeasonScene`
## keeps a one-line wrapper for each, so callers did not change.




## WHERE THE KEY SITS: under the last man and clear of the action row, measured
## rather than written down. The eight are five on the line, a 28-pixel bench
## header and three on the bench; on a taller canvas the action row moves and a
## key at a fixed 452 would have been left stranded in the middle of the screen.
static func _squad_key_y() -> float:
	var last := SeasonScene.CONTENT_Y + SeasonScene.SQUAD_TOP + SeasonScene.SQUAD_ROW * 8.0 + 28.0
	return minf(last + 16.0, SeasonScene.action_y() - 22.0)



static func _squad_rows(v: SeasonScene) -> Array:
	var out: Array = []
	var five := v.season.club.starting_five()
	## CONTENT_Y + 40 AND NOT + 26, because the column heading now sits between
	## the section title and the first man. Both columns move together and both
	## read the same constant, so the reserve cannot end up fourteen pixels out
	## of step with the eight.
	var y := SeasonScene.CONTENT_Y + SeasonScene.SQUAD_TOP
	var bench_started := false
	for f in v.season.club.active_eight():
		var kind := "on the line" if five.has(f) else "bench"
		## Every group needs the gap its own header is written into. The bench had
		## none, so its label was drawn 26 pixels up into the last man on the line.
		if kind == "bench" and not bench_started:
			bench_started = true
			y += 28.0
		out.append({ "card": f, "y": y, "kind": kind, "x": 24.0 })
		y += SeasonScene.SQUAD_ROW
	## The reserve stands in its own column rather than below, which is the
	## whole reason a landscape screen is worth having: the eight and the five
	## you might promote are visible at the same time, so the swap is a
	## comparison instead of a memory test.
	var ry := SeasonScene.CONTENT_Y + SeasonScene.SQUAD_TOP
	for f in v._reserve_sorted():
		out.append({ "card": f, "y": ry, "kind": "reserve", "x": SeasonScene.RESERVE_X })
		ry += SeasonScene.SQUAD_ROW
	return out




static func _reserve_sorted(v: SeasonScene) -> Array:
	var out: Array = v.season.club.reserves().duplicate()
	match String(SeasonScene.RESERVE_SORTS[v.reserve_sort % SeasonScene.RESERVE_SORTS.size()]["key"]):
		"age":
			## YOUNGEST FIRST, because the reason to sort a reserve by age is to
			## find the man worth waiting for, not the one about to retire.
			out.sort_custom(func(a, b): return a.age < b.age)
		"wage":
			out.sort_custom(func(a, b):
				return ClubOffice.billed(a) > ClubOffice.billed(b))
		"ceiling":
			out.sort_custom(func(a, b): return a.potential > b.potential)
		_:
			out.sort_custom(func(a, b): return a.overall() > b.overall())
	return out




## THE SPREAD OF THE WHOLE BOOK, which is the "min/max" half of item 21.
##
## Not a filter. Thirteen men is a list you read, not a set you query — a filter
## on a squad this size hides men to save scrolling that is not happening. What a
## player actually wants from "min/max" is the SHAPE: how old is this club, how
## far apart are the best and worst, what does the top earner cost. Three pairs
## on one line answer that, and they answer it about every man on the books
## rather than about whichever column is on screen.
static func _squad_spread(v: SeasonScene) -> String:
	var r: Array = v.season.club.roster
	if r.is_empty():
		return ""
	var lo_age := 99
	var hi_age := 0
	var lo_rat := 99
	var hi_rat := 0
	for f in r:
		lo_age = mini(lo_age, f.age)
		hi_age = maxi(hi_age, f.age)
		lo_rat = mini(lo_rat, f.overall())
		hi_rat = maxi(hi_rat, f.overall())
	## TWO PAIRS, NOT THREE. The third was the top wage and it did not fit: the
	## heading leaves 259 pixels and the three-pair line wanted 280, so `fit_px`
	## cut it to "top ." — which `test_ink.gd` would have failed on its next run,
	## because copy the game wrote itself is not allowed to lose its tail.
	##
	## The wage is the least of the three anyway. Total wages against the cap are
	## already on the right of this same line, which is the number that decides
	## anything; what one man costs is on his own row.
	return UiKit.t("age %d-%d  ·  rated %d-%d") % [lo_age, hi_age, lo_rat, hi_rat]




static func _squad_controls(v: SeasonScene) -> void:
	## THE ROSTER, which is the same men laid out like the sport rather than
	## like a list — and the only place a fighter's own record can be read.
	## IT WAS SITTING ON THE HONORS TAB. At y=70 with the tab strip at 72 this
	## button covered the right 112 pixels of the fifth tab, so on this tab the
	## label read "HONORS" and the tap opened the roster. Shipped, invisible,
	## and found by `test_layout.gd` the first time it drove every tab instead of
	## only the default one.
	## THE SAME MEN AS CARDS (Pete, 29 Sep 2026: Squad and Roster are one screen
	## with a Table | Cards switch). The row makes room for the hub's Next event.
	if v.picked == null:
		## TABLE | CARDS: this is Table; Cards opens the card view of the same men.
		v.ui.add_child(UiKit.button(UiKit.t("Card view"), Vector2(588, SeasonScene.action_y()),
		Vector2(116, 46), func():
			Session.autosave()
			UiKit.go("res://scenes/Roster.tscn"), "roster"))
	## ONE BUTTON THAT CYCLES, not four that are three-quarters wrong at any
	## moment. The action row has three places on it and the sort is the least of
	## them; a segmented control would cost the width of the roster button to say
	## something the heading already says.
	## THE ROW BELONGS TO THE PICKED MAN WHEN THERE IS ONE.
	##
	## `Reserve by` sits at x=24 and `Free agents` at x=544, and both were added
	## UNCONDITIONALLY — while picking a fighter adds Trade at x=24 and the
	## contract fork at x=464. Two overlaps, and both were invisible for the life
	## of the screen: Trade is added later so it wins the tap and draws on top, and
	## the only symptom was that **the reserve could not be re-sorted while a man
	## was selected** and the right-hand button showed a bare "s" sticking out
	## from under Extend.
	##
	## `shots/trade.png` is the first thing that ever rendered this tab with a
	## fighter picked. `test_layout.gd` measures controls against controls and
	## would have caught it on sight — it drives every tab and never drove this
	## STATE, which is the gap it has now closed.
	##
	## Both come back the instant he is deselected. Sorting the reserve and going
	## to the shelf are things you do when you are not in the middle of a decision
	## about one man, which is why hiding them costs nothing.
	var sw := UiKit.t(String(SeasonScene.RESERVE_SORTS[(v.reserve_sort + 1) % SeasonScene.RESERVE_SORTS.size()]["word"]))
	if v.picked == null:
		v.ui.add_child(UiKit.button(UiKit.t("Reserve by %s") % sw,
			Vector2(24, SeasonScene.action_y()), Vector2(180, 46), func():
				v.reserve_sort = (v.reserve_sort + 1) % SeasonScene.RESERVE_SORTS.size()
				v._rebuild(), "roster"))

	## THE FREE AGENTS LIVE HERE NOW.
	##
	## They used to be the MARKET tab, which also carried a button labelled "Free
	## agents" that opened a second and better screen of the same men — Pete's
	## *"there's a tab within a tab"*, item 5 of the 15 Sep playtest. Two views of
	## one thing, one of them a worse version of the other, reached by a control
	## named after the tab you were already standing on.
	##
	## Signing a man is a SQUAD decision, so it is reached from the squad, and the
	## tab it vacated became the armorer's — the one mechanic in this game that
	## Direction calls the cap and that had no screen at all.
	if v.picked == null:
		v.ui.add_child(UiKit.button(UiKit.t("Free agents"),
			Vector2(400, SeasonScene.action_y()), Vector2(180, 46), func():
				Session.autosave()
				UiKit.go("res://scenes/Market.tscn"), "coin"))

	## THE CLUB'S RECORD, which is where the HONORS tab went.
	##
	## Pete, 15 Sep 2026: *"Throw Honors into Squad and a team history page."*
	## The trophies and the season-by-season are now a page on the Records screen
	## — the club's other records already live there — and this is the door to it
	## from the squad, which is the screen a player is on when he wonders what
	## this lot have actually done.
	##
	## ONLY WHEN NOBODY IS PICKED. The action row has three places and the picked
	## state already wants all three for Cut, Prospect and Extend; a fourth button
	## underneath one of those is a button that works until it does not.
	if v.picked == null:
		v.ui.add_child(UiKit.button(UiKit.t("Club record"), Vector2(212, SeasonScene.action_y()),
			Vector2(180, 46), func():
				Session.autosave()
				Session.records_page = Records.Page.HISTORY
				UiKit.go("res://scenes/Records.tscn"), "trophy"))
	for row in v._squad_rows():
		v.ui.add_child(v._man_button(row["card"], float(row["y"]), float(row["x"])))
	if v.picked != null:
		## THE FORK, AS ONE BUTTON. Extend while the deal runs, re-sign once it has
		## not — and it is deliberately one control rather than two, because two
		## buttons with two prices means the player picks the cheaper one and
		## there is no decision left in it. The button shows the price it is
		## actually charging, and which of the two it is.
		var out_of_deal: bool = v.picked.years <= 0
		var deal_cost: int = v.season.resign_cost(v.picked) if out_of_deal \
			else v.season.extend_cost(v.picked)
		v.ui.add_child(UiKit.button(
			"%s  ·  %s/wk" % ["Re-sign" if out_of_deal else "Extend",
				ClubOffice.money(deal_cost)],
			Vector2(468, SeasonScene.action_y()), Vector2(256, 46), func():
				var err := v.season.resign(v.picked) if out_of_deal else v.season.extend(v.picked)
				if err == "":
					v.flash = UiKit.t("%s: %s a week for %d years.") % [v.picked.display_name,
						ClubOffice.money(ClubOffice.billed(v.picked)), v.picked.years]
					Session.autosave()
				else:
					v.flash = err
				v._rebuild()))
		## AND THE BUTTON SAYS WHAT HE FETCHES, because letting a man go is a
		## PRICE now and not just a decision — see `Market.trade_value`. The three
		## buckets are coarse on purpose and a player can only read the edges if
		## the number is in front of him at the moment he is deciding; a sale
		## whose value he discovers in the ledger afterwards is a mechanic he
		## never games.
		##
		## Nothing for a man out of contract, and the label says "Cut" then rather
		## than naming a price of zero — the distinction is real (his deal has run
		## out and nobody is paying you for a man who can walk in the summer) and
		## "Trade · 0 CC" reads as a bug.
		var worth := v.season.trade_value(v.picked)
		## WIDER THAN THE ROW'S OTHER BUTTONS, and deliberately.
		##
		## "Trade Calder · 3 CC" is about 195 pixels of text and the row's standard
		## button is 204, so it filled its own edges — and a National Marquee man
		## with a long name and a 33-credit price would have run straight past
		## them. `Prospect` and `Extend` do not name the man and do not need to;
		## this one does, because it is the only control on the screen that both
		## costs a fighter and pays money, and "which man" is the thing a player
		## checks before pressing it. The 56 pixels of dead space between Extend
		## and Roster paid for it.
		var who := UiKit.clip(v.picked.display_name, 10 if worth > 0 else 14)
		v.ui.add_child(UiKit.button((UiKit.t("Trade %s  ·  %d CC") % [who, worth])
				if worth > 0 else (UiKit.t("Cut %s") % who),
			Vector2(24, SeasonScene.action_y()), Vector2(232, 46), func():
				if not UiKit.confirm("release:" + v.picked.display_name):
					v.flash = (UiKit.t("Tap again to trade %s. He does not come back.") if worth > 0
						else UiKit.t("Tap again to cut %s. He does not come back.")) % v.picked.display_name
					v._rebuild()
					return
				var gone := v.picked.display_name
				var err := v.season.release(v.picked)
				v.flash = UiKit.said(err) if err != "" else (
					UiKit.t("%s traded for %d CC.") % [gone, worth] if worth > 0
					else UiKit.t("%s released.") % gone)
				if err == "":
					v.picked = null
					v.season.sync_power()
					Session.autosave()
				v._rebuild()))
		## THE PROSPECT. One man a year, cashed at the winter, and the button
		## refuses rather than going quiet when the ground is not built for it —
		## a control that does nothing and says nothing is how a player concludes
		## the feature is broken.
		var ground := v.season.office.level(ClubOffice.Facility.TRAINING)
		v.ui.add_child(UiKit.button(
			"Clear" if v.season.prospect == v.picked else "Prospect",
			Vector2(272, SeasonScene.action_y()), Vector2(180, 46), func():
				if v.season.prospect == v.picked:
					v.season.prospect = null
					v.flash = UiKit.t("%s is no longer your prospect.") % v.picked.display_name
				elif ground < Career.PROSPECT_GROUND:
					v.flash = UiKit.t("A prospect needs a Training ground at %d. Yours is %d.") % [
						Career.PROSPECT_GROUND, ground]
				else:
					v.season.prospect = v.picked
					v.flash = UiKit.t("%s is your prospect — +%d ceiling at the winter.") % [
						v.picked.display_name, Career.PROSPECT_GAIN]
					Session.autosave()
				v._rebuild()))




## An invisible hit box over each drawn row. Drawing the row myself and putting a
## flat button on top of it keeps the list looking like a list — a screen of
## themed Buttons reads as a form, and this is a team sheet.
static func _man_button(v: SeasonScene, f: FighterCard, y: float, x: float) -> Button:
	var b := UiKit.button("", Vector2(x, y - 20), Vector2(446, SeasonScene.SQUAD_ROW - 2),
		v._tap.bind(f))
	b.flat = true
	b.focus_mode = Control.FOCUS_NONE
	return b




static func _tap(v: SeasonScene, f: FighterCard) -> void:
	if v.picked == null:
		v.picked = f
		v.flash = UiKit.t("Pick who %s trades places with.") % f.display_name
		v._rebuild()
		return
	if v.picked == f:
		v.picked = null
		v.flash = ""
		v._rebuild()
		return
	## TWO KINDS OF SWAP, AND THE SCREEN NO LONGER REFUSES THE SECOND ONE.
	##
	## One on the bus and one in the clubhouse is a squad change: `swap_squad`.
	## TWO ON THE BUS is a depth-chart change — which men start and which sit on
	## the bench — and this used to answer it with *"Pick one from the eight and
	## one from the reserve"*, i.e. the screen told the player that the thing he
	## was trying to do was a mistake. It was not. It was the one thing the game
	## could not do at all: `starting_five()` reads roster order and nothing
	## could reorder the roster, so a man who ended up on the bench stayed there
	## whatever the player thought of him.
	##
	## Two in the RESERVE is still a no-op rather than a refusal — the reserve
	## has no order that means anything, so there is nothing to say and nothing
	## to do.
	## WHO WAS ON THE LINE BEFORE, so the message can say what actually changed.
	var five_before: Array = v.season.club.starting_five()
	var err := ""
	if v.picked.active and not f.active:
		err = v.season.club.swap_squad(v.picked, f)
	elif f.active and not v.picked.active:
		err = v.season.club.swap_squad(f, v.picked)
	elif v.picked.active and f.active:
		err = v.season.club.swap_order(v.picked, f)
	else:
		err = "Two in the reserve: bring one up to the eight first."
	if err == "":
		## REPORT WHAT CHANGED, NOT WHAT WAS TAPPED.
		##
		## The five is not a list the player edits — it is CHOSEN, by walking the
		## depth chart and taking the first fit man who covers each slot. So
		## swapping two entries can move somebody the player never touched: a
		## probe on the starting club swapped Calder for Quillan and promoted
		## Egan as well, because a Center arriving at the top of the chart
		## displaces the man who was covering that slot out of position.
		##
		## That is the model working, and a message saying "Calder and Quillan
		## swapped" while three names moved is the screen lying about it. So the
		## line is compared before and after and the message names the men who
		## actually came on and came off.
		var five_after: Array = v.season.club.starting_five()
		var came_on: Array[String] = []
		var came_off: Array[String] = []
		for m in five_after:
			if not five_before.has(m):
				came_on.append(String(m.display_name))
		for m in five_before:
			if not five_after.has(m):
				came_off.append(String(m.display_name))
		if came_on.is_empty():
			v.flash = UiKit.t("%s and %s swapped. The five is unchanged.") % [
				v.picked.display_name, f.display_name]
		else:
			v.flash = UiKit.t("On: %s.  Off: %s.") % [", ".join(came_on), ", ".join(came_off)]
		v.season.sync_power()
		Session.autosave()
	else:
		v.flash = err
	v.picked = null
	v._rebuild()






# ----------------------------------------------------------------- SQUAD tab
static func _draw_squad(v: SeasonScene) -> void:
	## THE HEADING CARRIES THE SPREAD, because there is nowhere else for it.
	##
	## It went on its own line at `CONTENT_Y + 18` first, which is eight pixels
	## above the first man's baseline — so it printed under "#1 Calder" and was
	## invisible. The heading line has three hundred spare pixels between the end
	## of the words and the reserve column, and a summary belongs beside the thing
	## it summarises anyway.
	## THE COUNT IS THE CLUB'S (blind review, 29 Sep: "eight" over six men).
	UiKit.pair(v, v.font, UiKit.t("THE %d WHO TRAVEL") % v.season.office.travel_slots, v._squad_spread(),
		Vector2(24, SeasonScene.CONTENT_Y), SeasonScene.RESERVE_X - 16.0, 13, 12, UiKit.DIM, UiKit.DIM)
	## THE RESERVE SAYS HOW IT IS ORDERED, because it is the only list on this
	## screen whose order is a choice rather than a fact.
	UiKit.text(v, v.font, UiKit.t("RESERVE — by %s") % UiKit.t(String(
		SeasonScene.RESERVE_SORTS[v.reserve_sort % SeasonScene.RESERVE_SORTS.size()]["word"])),
		Vector2(SeasonScene.RESERVE_X, SeasonScene.CONTENT_Y), 14, UiKit.DIM)
	## The cap, where the decision is: every man on this screen costs against it.
	var bill := ClubOffice.wage_bill(v.season.club)
	var cap := v.season.office.cap()
	UiKit.right(v, v.font, UiKit.t("%s of %s") % [ClubOffice.money(bill), ClubOffice.money(cap)],
		Vector2(UiKit.right_edge(), SeasonScene.CONTENT_Y), 14, UiKit.DOWN if bill > cap else UiKit.DIM, 300)
	## THE HEADINGS, over both columns, before any man is drawn.
	v._squad_head(24.0, SeasonScene.CONTENT_Y + SeasonScene.SQUAD_HEAD_Y)
	if not v.season.club.reserves().is_empty():
		v._squad_head(SeasonScene.RESERVE_X, SeasonScene.CONTENT_Y + SeasonScene.SQUAD_HEAD_Y)

	var rows := v._squad_rows()
	var last_kind := "on the line"
	for row in rows:
		var kind := String(row["kind"])
		var y := float(row["y"])
		var x := float(row["x"])
		## The line/bench split is otherwise carried only by a background shade,
		## which is not a label. Five men fight and three wait, and the screen
		## should say which is which.
		if kind == "bench" and last_kind == "on the line":
			UiKit.text(v, v.font, UiKit.t("BENCH — two may come on each corner"),
				Vector2(24, y - 24), 14, UiKit.DIM)
		v._man_row(row["card"], y, kind, x)
		last_kind = kind
	if v.season.club.reserves().is_empty():
		UiKit.text(v, v.font, UiKit.t("Nobody."),
			Vector2(SeasonScene.RESERVE_X + 16, SeasonScene.CONTENT_Y + SeasonScene.SQUAD_TOP), 15, UiKit.DIM)

	## AND THE KEY, for the three things a column heading cannot say.
	##
	## Headings name the fields; they do not explain the COLORS, and this screen
	## colors five of them. A player who sees one man's age in red and another's
	## in grey has been told something and has no way to find out what — which is
	## the same complaint as the unlabelled numbers, one layer down.
	##
	## One line, and only the three that carry a decision. The fourth and fifth
	## (a green kit percentage, a dimmed reserve name) mean "this is fine" and
	## "this man is not in the eight", and a key that explains the absence of a
	## problem is a key nobody finishes reading.
	## THE RED PART ONLY WHEN SOMETHING IS RED (round 4: the key promised red
	## and the sheet had none).
	var any_red: bool = ClubOffice.wage_bill(v.season.club) > v.season.office.cap()
	for f in v.season.club.roster:
		if f.injury > 0 or f.fading() or f.years <= 0 or f.armor < 0.6:
			any_red = true
	## ONE LINE (round 8: "cut the two-line legend"). The verb in ink, the key
	## in dim after it.
	var tap := UiKit.t("Tap a man for his page")
	var key := (UiKit.t("green = good  ·  gold years = final year  ·  red = deal with it") if any_red
		else UiKit.t("green = good  ·  gold years = final year"))
	var ky: float = SeasonScene._squad_key_y()
	UiKit.text(v, v.font, tap, Vector2(24, ky), 14, UiKit.INK)
	var tw: float = v.font.get_string_size(tap, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 18.0
	UiKit.text_fit(v, v.font, key, Vector2(24 + tw, ky), 14, UiKit.DIM, UiKit.span() - tw)




static func _man_row(v: SeasonScene, f: FighterCard, y: float, role: String, x: float) -> void:
	var w := SeasonScene.SQUAD_W
	if v.picked == f:
		v.draw_rect(Rect2(x, y - 20, w, SeasonScene.SQUAD_ROW - 2), UiKit.SELECT)
	elif role == "on the line":
		v.draw_rect(Rect2(x, y - 20, w, SeasonScene.SQUAD_ROW - 2), UiKit.PANEL)
	var col := UiKit.INK if role != "reserve" else UiKit.DIM
	UiKit.text(v, v.font, "#%d" % f.number, Vector2(x + SeasonScene.COL_NUM, y), 14, UiKit.DIM)
	## FITTED, NOT CLIPPED. The column is a pixel budget and the name is cut to
	## it — a thirteen-character count let a wide name run into the position.
	UiKit.text(v, v.font, UiKit.fit(v.font, f.display_name, 16, SeasonScene.COL_NAME_W),
		Vector2(x + SeasonScene.COL_NAME, y), 16, col)
	## An injury is the most important thing on a team sheet, so it goes where a
	## position would and takes the color that means "deal with this".
	if f.injury > 0:
		UiKit.text(v, v.font, UiKit.t("OUT %d") % f.injury, Vector2(x + SeasonScene.COL_POS, y), 14, UiKit.DOWN)
	else:
		UiKit.text(v, v.font, Tuning.pos_name(int(f.pos)), Vector2(x + SeasonScene.COL_POS, y), 14, UiKit.DIM)
	## Kit is this game's salary cap and already costs him base, so it belongs on
	## the team sheet next to the rating it is quietly subtracting from.
	var armor_col := armor_col(f.armor)
	UiKit.text(v, v.font, "%3d%%" % int(round(f.armor * 100.0)),
		Vector2(x + SeasonScene.COL_ARMOR, y), 14, armor_col)
	## AGE, and it is not decoration — see scripts/game/career.gd. Marked when he
	## is past the age at which not-being-put-down peaks and has fallen a way from
	## his own ceiling, because "he is 37 and eight off what he could have been"
	## is the entire argument for replacing him and the player should not have to
	## do that subtraction in his head.
	UiKit.text(v, v.font, "%d" % f.age, Vector2(x + SeasonScene.COL_AGE, y), 13,
		UiKit.DOWN if f.fading() else UiKit.DIM)
	## WHAT HE IS ON, and how many summers it has left. The wage is the DEAL, not
	## the market rate — showing the market rate here is what the cap used to bill
	## and it is the thing the contract layer exists to separate. It turns red the
	## year the deal runs out, because that is the one piece of roster news that
	## cannot wait until the player happens to look.
	var deal_col := UiKit.DIM
	if f.years <= 0:
		deal_col = UiKit.DOWN
	elif f.years == 1:
		## GOLD, a warning: green on this sheet means room to grow (round 4).
		deal_col = UiKit.YOU
	UiKit.right(v, v.font, ClubOffice.money(ClubOffice.billed(f)),
		Vector2(x + SeasonScene.COL_WAGE_TO, y), 14, UiKit.DIM, SeasonScene.COL_WAGE_BOX)
	UiKit.text(v, v.font, (UiKit.t("OUT") if f.years <= 0 else UiKit.t("%dy") % f.years),
		Vector2(x + SeasonScene.COL_YEARS, y), 12, deal_col)
	## THE TWO NUMBERS, together. Retro Bowl's roster screen is read almost
	## entirely off rating-and-potential, and the pairing is why: neither one
	## answers "should I keep him" on its own. The ceiling is dimmed so the
	## rating still reads first at a glance.
	UiKit.right(v, v.font, "%d" % f.overall(), Vector2(x + SeasonScene.COL_RATING_TO, y), 16, col,
		SeasonScene.COL_RATING_BOX)
	UiKit.right(v, v.font, "%d" % f.potential, Vector2(x + SeasonScene.COL_POT_TO, y), 12,
		UiKit.UP if f.headroom() >= 6 else UiKit.DIM, SeasonScene.COL_POT_BOX)
	## The prospect wears a mark rather than a word — one man a year, and the
	## screen has no room for a sentence about him.
	if v.season.prospect == f:
		UiKit.text(v, v.font, "*", Vector2(x + 28, y), 16, UiKit.UP)




## THE SAME STOPS, AS RECTANGLES, FOR THE CHECK. A column table that only the
## drawing code knows about is a column table nothing can test, so this hands
## back what each field will actually occupy given the widest string it can
## produce and the font the screen is really using.
## EACH COLUMN NOW CARRIES ITS OWN HEADING AND ITS OWN ALIGNMENT, and that is
## the fix for Pete's *"Player has no idea what the numbers mean of the
## fighters."*
##
## Nine unlabelled fields is not a dense table, it is a cipher: a row reads
## `#4 Calder FLANKER 92% 27 $4.1k 3y 61 68` and there is nothing anywhere on
## the screen that says which of those two trailing numbers is what he is and
## which is what he could be. Every one of them was explained in a comment in
## `_man_row`, which is the one place the player cannot see.
##
## THE HEADING LIVES IN THE SAME TABLE AS THE STOP, so a column cannot be moved
## without its label coming with it and a label cannot claim a field the row does
## not draw. `test_layout.gd` already walks these rects for collisions; putting
## the heading here means the heading is walked too.
static func squad_columns(v: SeasonScene, f: Font, size_hint: int = 0) -> Array:
	var _unused := size_hint
	var out: Array = []
	var w := func(s: String, px: int) -> float:
		return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x
	## THE HEADING GETS ITS OWN MEASURED RECT, and that turned out to matter on
	## the first screenshot: the four fields on the right hold tiny values —
	## `$3`, `3y`, `40`, `44` — so their rects are sized to the widest value they
	## could ever hold, which is narrower than the WORD that names them. Drawn at
	## the data's own stops the row read `WAGEDEALNOWMAX`.
	##
	## So the heading has its own stop per column, its width is measured from the
	## label at the size it is actually drawn, and `test_layout.gd` walks these
	## for collisions exactly as it walks the data rects. **A label that does not
	## fit where its column does is a column with no label.**
	var hw := func(s: String) -> float:
		return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0,
			SeasonScene.SQUAD_HEAD_PX).x
	var lhead := func(label: String, at: float) -> Rect2:
		return Rect2(at, 0.0, float(hw.call(label)), 14.0)
	var rhead := func(label: String, to: float) -> Rect2:
		var wd: float = float(hw.call(label))
		return Rect2(to - wd, 0.0, wd, 14.0)

	out.append({"name": "number", "head": "#", "align": "left",
		"rect": Rect2(SeasonScene.COL_NUM, 0.0, float(w.call("#13", 13)), 18.0),
		"head_rect": lhead.call("#", SeasonScene.COL_NUM)})
	## The name can never exceed its budget, because `UiKit.fit` measures it.
	out.append({"name": "name", "head": UiKit.t("FIGHTER"), "align": "left",
		"rect": Rect2(SeasonScene.COL_NAME, 0.0, SeasonScene.COL_NAME_W, 18.0),
		"head_rect": lhead.call(UiKit.t("FIGHTER"), SeasonScene.COL_NAME)})
	out.append({"name": "position", "head": UiKit.t("ROLE"), "align": "left",
		"rect": Rect2(SeasonScene.COL_POS, 0.0, float(w.call("FLANKER", 13)), 18.0),
		"head_rect": lhead.call(UiKit.t("ROLE"), SeasonScene.COL_POS)})
	out.append({"name": "armor", "head": UiKit.t("KIT"), "align": "left",
		"rect": Rect2(SeasonScene.COL_ARMOR, 0.0, float(w.call("100%", 13)), 18.0),
		"head_rect": lhead.call(UiKit.t("KIT"), SeasonScene.COL_ARMOR)})
	out.append({"name": "age", "head": UiKit.t("AGE"), "align": "left",
		"rect": Rect2(SeasonScene.COL_AGE, 0.0, float(w.call("39", 13)), 18.0),
		"head_rect": lhead.call(UiKit.t("AGE"), SeasonScene.COL_AGE)})
	## Right-aligned: the widest string this field can produce, ending at its stop.
	var wage: float = w.call("$99.9k", 13)
	out.append({"name": "wage", "head": UiKit.t("PAY"), "align": "right",
		"rect": Rect2(SeasonScene.COL_WAGE_TO - wage, 0.0, wage, 18.0),
		"head_rect": rhead.call(UiKit.t("PAY"), SeasonScene.COL_WAGE_TO)})
	## `YR` AND NOT `DEAL`. Six pixels separate the wage's stop from the years'
	## and no four-letter word survives that; the field says `3y` and `OUT`, so
	## the two letters are the whole of the information anyway.
	out.append({"name": "years", "head": UiKit.t("YR"), "align": "left",
		"rect": Rect2(SeasonScene.COL_YEARS, 0.0, float(w.call("OUT", 12)), 18.0),
		"head_rect": lhead.call(UiKit.t("YR"), SeasonScene.COL_YEARS)})
	var rating: float = w.call("99", 16)
	out.append({"name": "rating", "head": UiKit.t("NOW"), "align": "right",
		"rect": Rect2(SeasonScene.COL_RATING_TO - rating, 0.0, rating, 18.0),
		"head_rect": rhead.call(UiKit.t("NOW"), SeasonScene.COL_RATING_TO)})
	var pot: float = w.call("99", 12)
	## MAX RIDES THE END OF THE ROW rather than the ceiling's own stop. There are
	## eight spare pixels at 446 and this label needs six of them to clear `NOW`;
	## the alternative was a third abbreviation nobody would read.
	out.append({"name": "ceiling", "head": UiKit.t("MAX"), "align": "right",
		"rect": Rect2(SeasonScene.COL_POT_TO - pot, 0.0, pot, 18.0),
		"head_rect": rhead.call(UiKit.t("MAX"), SeasonScene.SQUAD_W)})
	return out




## THE HEADING ROW, drawn from the column table so it cannot drift from it.
##
## `NOW` AND `MAX` RATHER THAN `RTG` AND `POT`. The pair is the whole reason the
## roster screen works — neither number answers "should I keep him" on its own —
## and two abbreviations a player has to learn do not deliver that; two words he
## already knows do. Same reason `KIT` is not `ARM`: this game has a harness and
## an armorer, and the word on the team sheet should be the word on the shop.
static func _squad_head(v: SeasonScene, x: float, y: float) -> void:
	var cols: Array = v.squad_columns(v.font, SeasonScene.SQUAD_HEAD_PX)
	for c in cols:
		var label := String(c.get("head", ""))
		if label == "":
			continue
		## DRAWN AT ITS OWN RECT'S LEFT EDGE, left-aligned, whatever the column's
		## alignment is. The rect was already solved for — a right-aligned draw
		## here would solve for it a second time and the two would disagree the
		## day somebody changed the size.
		var hr: Rect2 = c["head_rect"]
		UiKit.text(v, v.font, label, Vector2(x + hr.position.x, y),
			SeasonScene.SQUAD_HEAD_PX, UiKit.DIM)
	## AND THE HAIRLINE UNDER IT, which is what turns nine words into a table
	## header rather than a tenth row of small text.
	v.draw_line(Vector2(x, y + 6.0), Vector2(x + SeasonScene.SQUAD_W, y + 6.0),
		UiKit.FRAME, 1.0)




static func _qm_cell(v: SeasonScene) -> float:
	return (UiKit.span() - SeasonScene.QM_GAP) * 0.5




## TWO COLUMNS, THE BUS AND THE CLUBHOUSE — the same split the Squad screen
## uses, and for the same reason.
##
## One column of thirteen at 30 pixels a row needs 390 of the 276 this screen has
## between the header and the action row, so the first cut ran four men off the
## bottom of the frame. Splitting it is not a workaround for that: the eight who
## travel are the men the marshals will actually look at, and the reserve is a
## different question the player asks less often. The layout should say so.
static func _qm_rows(v: SeasonScene) -> Array:
	var out: Array = []
	var y := SeasonScene.CONTENT_Y + SeasonScene.QM_TOP
	for f in v.season.club.active_eight():
		out.append({"card": f, "y": y, "x": 24.0, "bus": true})
		y += SeasonScene.QM_ROW
	y = SeasonScene.CONTENT_Y + SeasonScene.QM_TOP
	for f in v.season.club.reserves():
		out.append({"card": f, "y": y, "x": 24.0 + v._qm_cell() + SeasonScene.QM_GAP, "bus": false})
		y += SeasonScene.QM_ROW
	return out


## THE KIT'S COLOUR ON THE TEAM SHEET: green when it is good, red when it is
## worn. A function of its own (29 Sep 2026) so test_loop can pin it — the
## fresh audit reversed it and nothing noticed.
static func armor_col(a: float) -> Color:
	return UiKit.UP if a > 0.85 else (UiKit.DOWN if a < 0.6 else UiKit.DIM)
