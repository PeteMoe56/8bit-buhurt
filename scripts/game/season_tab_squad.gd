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
	## Just over the action row: under the tallest the three boxes can be (eight
	## travelling, five on the line and three on the bench).
	return SeasonScene.action_y() - 8.0



static func _squad_rows(v: SeasonScene) -> Array:
	var out: Array = []
	## THE FIVE FIRST, IN SLOT ORDER, THEN THE BENCH (playtest 30 Sep #17).
	## The eight used to be drawn in depth-chart order, so the BENCH heading
	## landed after whichever man came first in the chart and four men on the
	## line read as benched — which Pete took for a line with one man on it and
	## no way to fill it. The model was never short; the sheet was lying.
	var five := v.season.club.starting_five()
	var y := SeasonScene.CONTENT_Y + SeasonScene.SQUAD_TOP
	for i in five.size():
		out.append({ "card": five[i], "y": y, "kind": "on the line", "x": 24.0, "slot": i })
		y += SeasonScene.SQUAD_ROW
	var bench_started := false
	for f in v.season.club.active_eight():
		if five.has(f):
			continue
		if not bench_started:
			bench_started = true
			y += BENCH_GAP
		out.append({ "card": f, "y": y, "kind": "bench", "x": 24.0 })
		y += SeasonScene.SQUAD_ROW
	## The reserve stands in its own column rather than below, which is the
	## whole reason a landscape screen is worth having: the eight and the five
	## you might promote are visible at the same time, so the swap is a
	## comparison instead of a memory test.
	var ri := 0
	for f in v._reserve_sorted():
		out.append({ "card": f, "y": _reserve_y(ri), "kind": "reserve", "x": SeasonScene.RESERVE_X })
		ri += 1
	return out


## Where reserve place `i` sits, filled or not.
static func _reserve_y(i: int) -> float:
	return SeasonScene.CONTENT_Y + SeasonScene.SQUAD_TOP + float(i) * SeasonScene.SQUAD_ROW


## THE MAN YOU TAPPED, bottom right (Pete, 1 Oct 2026: "Use the bottom right for
## info panel on whomever you click on"). Under the four reserve places, above
## the key line.
static func info_rect() -> Rect2:
	var top := _reserve_y(MeleeClub.RESERVE_SIZE) - 4.0
	if Session.season != null:
		top = _reserve_y(maxi(MeleeClub.RESERVE_SIZE, Session.season.club.reserves().size())) - 4.0
	return Rect2(SeasonScene.RESERVE_X - 6.0, top, SeasonScene.SQUAD_W + 12.0,
		SeasonScene._squad_key_y() - 22.0 - top)


## The gap the BENCH box's title is written into.
const BENCH_GAP := 30.0
## Where on the line each of the five stands, said the way the sport says it.
const SLOT_WORD := ["L rail", "L flank", "Center", "R flank", "R rail"]
## For the string table, which reads literals inside t().
static func _slot_keys() -> Array:
	return [UiKit.t("L rail"), UiKit.t("L flank"), UiKit.t("R flank"), UiKit.t("R rail")]




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
	## TEAM'S ROW (Pete, 1 Oct 2026): Club record, Free agents, Training. Card
	## view and the reserve sort went; the man you tap shows bottom right.
	if v.picked == null:
		var ay0 := SeasonScene.action_y()
		v.ui.add_child(UiKit.button(UiKit.t("Club record"), Vector2(24, ay0), Vector2(180, 46), func():
			Session.autosave()
			Session.records_page = Records.Page.HISTORY
			UiKit.go("res://scenes/Records.tscn"), "trophy"))
		v.ui.add_child(UiKit.button(UiKit.t("Free agents"), Vector2(212, ay0), Vector2(180, 46), func():
			Session.autosave()
			UiKit.go("res://scenes/Market.tscn"), "coin"))
		v.ui.add_child(UiKit.button(UiKit.t("Training"), Vector2(400, ay0), Vector2(180, 46), func():
			v.training_open = true
			v._rebuild(), "helm"))
	## AN EMPTY RESERVE PLACE IS A DOOR TO THE FREE AGENTS (Pete, 1 Oct 2026).
	var n_res: int = v.season.club.reserves().size()
	for i in range(n_res, MeleeClub.RESERVE_SIZE):
		var hb := UiKit.button(UiKit.t("+  Hire free agent"),
			Vector2(SeasonScene.RESERVE_X, _reserve_y(i) - 21.0), Vector2(SeasonScene.SQUAD_W, SeasonScene.SQUAD_ROW - 4.0),
			func():
				Session.autosave()
				UiKit.go("res://scenes/Market.tscn"))
		v.ui.add_child(hb)
	for row in v._squad_rows():
		v.ui.add_child(v._man_button(row["card"], float(row["y"]), float(row["x"])))
	if v.picked != null:
		## THE PICKED MAN'S ROW: Swap, his page, Prospect, the deal, Trade.
		## Five buttons across the 912 the row has (playtest 30 Sep #5 #6 #16).
		var p := v.picked
		var ay := SeasonScene.action_y()
		var swap_b := UiKit.button(UiKit.t("Cancel swap") if v.swapping else UiKit.t("Swap"),
			Vector2(24, ay), Vector2(130, 46), func():
				v.swapping = not v.swapping
				v.flash = (UiKit.t("Tap the man %s trades places with.") % p.display_name) if v.swapping else ""
				v._rebuild(), "roster")
		v.ui.add_child(UiKit.primary(swap_b) if v.swapping else swap_b)
		v.ui.add_child(UiKit.button(UiKit.t("His page"), Vector2(162, ay), Vector2(130, 46), func():
			Session.viewing_fighter = p
			Session.autosave()
			UiKit.go("res://scenes/Fighter.tscn"), "helm"))
		## THE PROSPECT, SAID AS WHAT IT DOES (playtest 30 Sep #6).
		var ground := v.season.office.level(ClubOffice.Facility.TRAINING)
		v.ui.add_child(UiKit.button(
			UiKit.t("Not prospect") if v.season.prospect == p else UiKit.t("Prospect: +%d POT") % Career.PROSPECT_GAIN,
			Vector2(300, ay), Vector2(170, 46), func():
				if v.season.prospect == p:
					v.season.prospect = null
					v.flash = UiKit.t("%s is no longer your prospect.") % p.display_name
				elif ground < Career.PROSPECT_GROUND:
					v.flash = UiKit.t("One man a year can be your prospect: +%d to his max at the winter. Needs a Training ground at %d.") % [
						Career.PROSPECT_GAIN, Career.PROSPECT_GROUND]
				else:
					v.season.prospect = p
					v.flash = UiKit.t("%s is your prospect — +%d to his max at the winter.") % [
						p.display_name, Career.PROSPECT_GAIN]
					Session.autosave()
				v._rebuild()))
		var out_of_deal: bool = p.years <= 0
		var deal_cost: int = v.season.resign_cost(p) if out_of_deal else v.season.extend_cost(p)
		v.ui.add_child(UiKit.button(
			"%s  ·  %s/yr" % [UiKit.t("Re-sign") if out_of_deal else UiKit.t("Extend"),
				ClubOffice.money(deal_cost)],
			Vector2(478, ay), Vector2(196, 46), func():
				var err := v.season.resign(p) if out_of_deal else v.season.extend(p)
				if err == "":
					v.flash = UiKit.t("%s: %s a year for %d years.") % [p.display_name,
						ClubOffice.money(ClubOffice.billed(p)), p.years]
					Session.autosave()
				else:
					v.flash = err
				v._rebuild()))
		var worth := v.season.trade_value(p)
		var who := UiKit.clip(p.display_name, 8)
		v.ui.add_child(UiKit.danger(UiKit.button((UiKit.t("Trade %s  ·  +%d CC") % [who, worth])
				if worth > 0 else (UiKit.t("Cut %s") % who),
			Vector2(706, ay), Vector2(UiKit.right_edge() - 706.0, 46), func():
				if not UiKit.confirm("release:" + p.display_name):
					v.flash = (UiKit.t("Tap again to trade %s. He does not come back.") if worth > 0
						else UiKit.t("Tap again to cut %s. He does not come back.")) % p.display_name
					v._rebuild()
					return
				var gone := p.display_name
				var err := v.season.release(p)
				v.flash = UiKit.said(err) if err != "" else (
					UiKit.t("%s traded for %d CC.") % [gone, worth] if worth > 0
					else UiKit.t("%s released.") % gone)
				if err == "":
					v.picked = null
					v.season.sync_power()
					Session.autosave()
				v._rebuild())))




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
	## A TAP PICKS; SWAP IS A BUTTON (playtest 30 Sep #16). The second tap used
	## to swap whoever it landed on, which is how a mis-tap moved a man.
	if v.picked == null or (not v.swapping and v.picked != f):
		v.picked = f
		v.swapping = false
		v.flash = ""
		v._rebuild()
		return
	if v.picked == f:
		v.picked = null
		v.swapping = false
		v.flash = ""
		v._rebuild()
		return
	v.swapping = false
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
	UiKit.text(v, v.font, UiKit.t("STARTERS"), Vector2(24, SeasonScene.CONTENT_Y), 14, UiKit.DIM)
	UiKit.text(v, v.font, UiKit.t("RESERVE"), Vector2(SeasonScene.RESERVE_X, SeasonScene.CONTENT_Y), 14, UiKit.DIM)
	## The cap, where the decision is: every man on this screen costs against it.
	var bill := ClubOffice.wage_bill(v.season.club)
	var cap := v.season.office.cap()
	UiKit.right(v, v.font, UiKit.t("%s of %s") % [ClubOffice.money(bill), ClubOffice.money(cap)],
		Vector2(UiKit.right_edge(), SeasonScene.CONTENT_Y), 14, UiKit.DOWN if bill > cap else UiKit.DIM, 300)
	## THE HEADINGS, over both columns, before any man is drawn.
	v._squad_head(24.0, SeasonScene.CONTENT_Y + SeasonScene.SQUAD_HEAD_Y)
	v._squad_head(SeasonScene.RESERVE_X, SeasonScene.CONTENT_Y + SeasonScene.SQUAD_HEAD_Y)

	var rows := v._squad_rows()
	## THREE BOXES, ONE PER GROUP (playtest 30 Sep #4: "maybe some box
	## separations"). The line, the bench and the reserve each sit in a framed
	## panel, so which group a man is in is a shape, not a shade.
	var groups := {}
	for row in rows:
		var k := String(row["kind"])
		var y := float(row["y"])
		if not groups.has(k):
			groups[k] = Vector2(y, y)
		groups[k] = Vector2(minf(groups[k].x, y), maxf(groups[k].y, y))
	## THE RESERVE'S BOX HOLDS ALL FOUR PLACES, filled or not.
	groups["reserve"] = Vector2(_reserve_y(0), _reserve_y(maxi(MeleeClub.RESERVE_SIZE,
		v.season.club.reserves().size()) - 1))
	for k in groups:
		var span: Vector2 = groups[k]
		var gx: float = SeasonScene.RESERVE_X if k == "reserve" else 24.0
		v.draw_rect(Rect2(gx - 6.0, span.x - 24.0, SeasonScene.SQUAD_W + 12.0,
			span.y - span.x + SeasonScene.SQUAD_ROW + 8.0), UiKit.FRAME, false, 1.0)
	for row in rows:
		var kind := String(row["kind"])
		var y := float(row["y"])
		var x := float(row["x"])
		if kind == "bench" and y == float(groups["bench"].x):
			UiKit.text(v, v.font, UiKit.t("BENCH"), Vector2(24, y - 28), 14, UiKit.DIM)
		v._man_row(row["card"], y, kind, x)
		## WHERE HE STANDS ON THE LINE, in place of his listed role.
		if row.has("slot"):
			UiKit.text(v, v.font, UiKit.t(String(SLOT_WORD[int(row["slot"])])),
				Vector2(x + SeasonScene.COL_POS, y), 14,
				UiKit.YOU if Tuning.covers(int(row["card"].pos), int(row["slot"])) == false else UiKit.DIM)
	_draw_info(v)

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
	## SAYS WHAT A TAP DOES NOW: it picks him; his buttons do the rest.
	var key := (UiKit.t("green = good  ·  gold = final year  ·  Hurt · 2 = out 2 events") if any_red
		else UiKit.t("green = good  ·  gold = final year"))
	var any_level := false
	for f in v.season.club.roster:
		if Career.levels_banked(f) > 0:
			any_level = true
	if any_level:
		key = UiKit.t("+2 = levels to spend on his page") + UiKit.t("  ·  ") + key
	UiKit.text_fit(v, v.font, key, Vector2(24, SeasonScene._squad_key_y()), 14, UiKit.DIM, UiKit.span())


## THE INFO PANEL: who he is, what he is wearing, his deal, his four and the pair.
static func _draw_info(v: SeasonScene) -> void:
	var r := info_rect()
	UiKit.panel(v, r)
	var f: FighterCard = v.picked
	var x := r.position.x + 14.0
	var y := r.position.y + 26.0
	if f == null:
		## NOBODY PICKED: THE TEAM ITSELF (review, 1 Oct 2026: an empty box was a
		## third of the screen). The five's four ratings, the line's average, and
		## what tapping does.
		UiKit.text(v, v.font, UiKit.t("YOUR FIVE"), Vector2(x, y), 13, UiKit.DIM)
		var five: Array = v.season.club.starting_five()
		var sum := 0
		for m in five:
			sum += m.overall()
		UiKit.right(v, v.font, UiKit.t("OVR %d") % int(round(float(sum) / float(maxi(1, five.size())))),
			Vector2(r.end.x - 14.0, y), 16, UiKit.INK, 120)
		TeamCard.draw_stars(v, v.font, Vector2(x, y + 28.0), v.season.club, 2, (r.size.x - 28.0) * 0.5, 13)
		UiKit.text(v, v.font, UiKit.t("Tap a fighter to see him here."), Vector2(x, r.end.y - 12.0), 13, UiKit.DIM)
		return
	var right_w := 150.0
	UiKit.text_fit(v, v.font, f.display_name, Vector2(x, y), 18, UiKit.INK, r.size.x - right_w - 40.0)
	var sub := UiKit.t("%s  ·  age %d  ·  %s kit %d%%") % [Tuning.pos_name(int(f.pos)), f.age,
		Quartermaster.name_of(f), int(round(f.armor * 100.0))]
	UiKit.text_fit(v, v.font, sub, Vector2(x, y + 20.0), 13, UiKit.DIM, r.size.x - right_w - 40.0)
	var deal := UiKit.t("%dy left  ·  %s a year") % [maxi(0, f.years), ClubOffice.money(ClubOffice.billed(f))]
	UiKit.text_fit(v, v.font, deal, Vector2(x, y + 38.0), 13,
		UiKit.DOWN if f.years <= 0 else (UiKit.YOU if f.years == 1 else UiKit.DIM), r.size.x - right_w - 40.0)
	var stats := [f.strength, f.base, f.skill, f.gas]
	var sw := (r.size.x - right_w - 40.0) * 0.5
	for i in 4:
		var sx := x + float(i % 2) * (sw + 12.0)
		var sy := y + 60.0 + float(i / 2) * 20.0
		UiKit.text(v, v.font, TeamCard.cat_name(i), Vector2(sx, sy), 12, UiKit.DIM)
		UiKit.right(v, v.font, "%d" % int(stats[i]), Vector2(sx + sw, sy), 13, UiKit.INK, 30)
	var px := r.end.x - right_w
	UiKit.mid(v, v.font, UiKit.t("OVR"), Vector2(px, y + 4.0), 12, UiKit.DIM, 70)
	UiKit.mid(v, v.font, "%d" % f.overall(), Vector2(px, y + 40.0), 30, UiKit.DOWN if f.fading() else UiKit.INK, 70)
	UiKit.mid(v, v.font, UiKit.t("POT"), Vector2(px + 72.0, y + 4.0), 12, UiKit.DIM, 70)
	UiKit.mid(v, v.font, "%d" % f.potential, Vector2(px + 72.0, y + 40.0), 30,
		UiKit.UP if f.headroom() >= 6 else UiKit.DIM, 70)
	var banked := Career.levels_banked(f)
	if banked > 0:
		UiKit.mid(v, v.font, UiKit.tn("%d level to spend", "%d levels to spend", banked) % banked, Vector2(px, y + 66.0), 13, UiKit.YOU, 142)




static func _man_row(v: SeasonScene, f: FighterCard, y: float, role: String, x: float) -> void:
	var w := SeasonScene.SQUAD_W
	if v.picked == f:
		v.draw_rect(Rect2(x, y - 20, w, SeasonScene.SQUAD_ROW - 2), UiKit.SELECT)
	elif role == "on the line":
		v.draw_rect(Rect2(x, y - 20, w, SeasonScene.SQUAD_ROW - 2), UiKit.PANEL)
	var col := UiKit.INK if role != "reserve" else UiKit.DIM
	## FITTED, NOT CLIPPED. The column is a pixel budget and the name is cut to
	## it — a thirteen-character count let a wide name run into the position.
	## LEVELS WAITING, IN GOLD BESIDE HIS NAME (Pete, 1 Oct: "Simmed multiple
	## weeks, no one leveled up, should show on squad page"). They had levelled —
	## a level is the player's to place, on the man's page — and nothing on this
	## sheet said a single one was waiting.
	var banked := Career.levels_banked(f)
	var badge := UiKit.t("+%d") % banked if banked > 0 else ""
	var bw := v.font.get_string_size(badge, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x + 6.0 if badge != "" else 0.0
	var nm := UiKit.fit(v.font, f.display_name, 16, SeasonScene.COL_NAME_W - bw)
	UiKit.text(v, v.font, nm, Vector2(x + SeasonScene.COL_NAME, y), 16, col)
	if badge != "":
		var nw := v.font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16).x
		UiKit.text(v, v.font, badge, Vector2(x + SeasonScene.COL_NAME + nw + 6.0, y), 13, UiKit.YOU)
	## An injury is the most important thing on a team sheet, so it goes where a
	## position would and takes the color that means "deal with this".
	## "HURT · 1", NOT "OUT 1" (playtest 30 Sep #9: "No idea why Norrey is
	## out"): the word says why, the number is the events he will miss.
	if f.injury > 0:
		UiKit.text(v, v.font, UiKit.t("Hurt · %d") % f.injury, Vector2(x + SeasonScene.COL_POS, y), 14, UiKit.DOWN)
	elif role != "on the line":
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
	## (Age moved to his page with the shirt number and the pay — see the
	## column table. A fading man still shows: his NOW goes red below.)
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
	## "0y", NOT "OUT": the third thing on this sheet that said "out" (#9, 30 Sep).
	UiKit.text(v, v.font, UiKit.t("%dy") % maxi(0, f.years),
		Vector2(x + SeasonScene.COL_YEARS, y), 14, deal_col)
	## THE TWO NUMBERS, together. Retro Bowl's roster screen is read almost
	## entirely off rating-and-potential, and the pairing is why: neither one
	## answers "should I keep him" on its own. The ceiling is dimmed so the
	## rating still reads first at a glance.
	UiKit.right(v, v.font, "%d" % f.overall(), Vector2(x + SeasonScene.COL_RATING_TO, y), 16,
		UiKit.DOWN if f.fading() else col, SeasonScene.COL_RATING_BOX)
	UiKit.right(v, v.font, "%d" % f.potential, Vector2(x + SeasonScene.COL_POT_TO, y), 14,
		UiKit.UP if f.headroom() >= 6 else UiKit.DIM, SeasonScene.COL_POT_BOX)
	## The prospect wears a mark rather than a word — one man a year, and the
	## screen has no room for a sentence about him.
	if v.season.prospect == f:
		UiKit.text(v, v.font, "*", Vector2(x + SeasonScene.COL_POS - 16.0, y), 16, UiKit.UP)




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

	## The name can never exceed its budget, because `UiKit.fit` measures it.
	out.append({"name": "name", "head": UiKit.t("FIGHTER"), "align": "left",
		"rect": Rect2(SeasonScene.COL_NAME, 0.0, SeasonScene.COL_NAME_W, 18.0),
		"head_rect": lhead.call(UiKit.t("FIGHTER"), SeasonScene.COL_NAME)})
	out.append({"name": "position", "head": "", "align": "left",
		"rect": Rect2(SeasonScene.COL_POS, 0.0, float(w.call("FLANKER", 13)), 18.0),
		"head_rect": Rect2(SeasonScene.COL_POS, 0.0, 0.0, 14.0)})
	out.append({"name": "armor", "head": UiKit.t("KIT"), "align": "left",
		"rect": Rect2(SeasonScene.COL_ARMOR, 0.0, float(w.call("100%", 13)), 18.0),
		"head_rect": lhead.call(UiKit.t("KIT"), SeasonScene.COL_ARMOR)})
	## `YR` AND NOT `DEAL`. Six pixels separate the wage's stop from the years'
	## and no four-letter word survives that; the field says `3y` and `OUT`, so
	## the two letters are the whole of the information anyway.
	out.append({"name": "years", "head": UiKit.t("DEAL"), "align": "left",
		"rect": Rect2(SeasonScene.COL_YEARS, 0.0, float(w.call("OUT", 14)), 18.0),
		"head_rect": lhead.call(UiKit.t("DEAL"), SeasonScene.COL_YEARS)})
	var rating: float = w.call("99", 16)
	out.append({"name": "rating", "head": UiKit.t("OVR"), "align": "right",
		"rect": Rect2(SeasonScene.COL_RATING_TO - rating, 0.0, rating, 18.0),
		"head_rect": rhead.call(UiKit.t("OVR"), SeasonScene.COL_RATING_TO)})
	var pot: float = w.call("99", 14)
	## MAX RIDES THE END OF THE ROW rather than the ceiling's own stop. There are
	## eight spare pixels at 446 and this label needs six of them to clear `NOW`;
	## the alternative was a third abbreviation nobody would read.
	out.append({"name": "ceiling", "head": UiKit.t("POT"), "align": "right",
		"rect": Rect2(SeasonScene.COL_POT_TO - pot, 0.0, pot, 18.0),
		"head_rect": rhead.call(UiKit.t("POT"), SeasonScene.SQUAD_W)})
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
	## EVERYBODY, ACROSS BOTH COLUMNS (review, 1 Oct 2026: a club with nobody at
	## home left the right half reading "Nobody at home."). The eight first, the
	## men at home after them, drawn quieter.
	var out: Array = []
	var men: Array = v.season.club.active_eight().duplicate()
	var home: Array = v.season.club.reserves()
	men.append_array(home)
	var per := maxi(6, int(ceil(float(men.size()) / 2.0)))
	for i in men.size():
		var col := i / per
		out.append({"card": men[i], "y": SeasonScene.CONTENT_Y + SeasonScene.QM_TOP + float(i % per) * SeasonScene.QM_ROW,
			"x": 24.0 + float(col) * (v._qm_cell() + SeasonScene.QM_GAP), "bus": not home.has(men[i])})
	return out


## THE KIT'S COLOUR ON THE TEAM SHEET: green when it is good, red when it is
## worn. A function of its own (29 Sep 2026) so test_loop can pin it — the
## fresh audit reversed it and nothing noticed.
static func armor_col(a: float) -> Color:
	return UiKit.UP if a > 0.85 else (UiKit.DOWN if a < 0.6 else UiKit.DIM)
