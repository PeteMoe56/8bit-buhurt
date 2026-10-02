class_name SeasonClubhouseTab
extends RefCounted
## Methods of `SeasonScene`, moved out of season_scene.gd so that file is not one
## three-thousand-line object. Every function takes the SeasonScene as `v`; `SeasonScene`
## keeps a one-line wrapper for each, so callers did not change.




static func _office_row_y(v: SeasonScene, i: int) -> float:
	return SeasonScene.CONTENT_Y + 34.0 + float(i) * ROW_STEP


const ROW_STEP := 64.0
## The bar leaves room for its "?" (Pete, 1 Oct 2026: a "?" on each, the
## descriptions off the page).
const BAR_W := SeasonScene.BAR_W - 42.0
const HELP_X := SeasonScene.BAR_X + BAR_W + 8.0


## WHAT ROW `i` COSTS TO KEEP, a year.
static func row_upkeep(v: SeasonScene, kind) -> int:
	var o := v.season.office
	if kind is String:
		if kind == "insurance":
			return o.federation_upkeep()
		return 0
	return o.facility_upkeep(int(kind))


## WHAT ROW `i` WILL COST TO KEEP, a year, after one more step (on its button).
static func row_upkeep_next(v: SeasonScene, kind) -> int:
	var o := v.season.office
	if kind is String:
		return o.rule_upkeep_next(Federation.Rule.INSURANCE) if kind == "insurance" else 0
	return o.facility_upkeep_next(int(kind))


static func row_cost(v: SeasonScene, kind) -> int:
	var o := v.season.office
	if kind is String:
		if kind == "cap":
			return o.cap_cost()
		if kind == "insurance":
			return o.rule_cost(Federation.Rule.INSURANCE) \
				if o.rule_level(Federation.Rule.INSURANCE) < Federation.MAX_LEVEL else 0
		return 0
	return o.facility_cost(int(kind))


## The whole year's keep: every row, and the arena.
static func upkeep_total(v: SeasonScene) -> int:
	var t := v.season.office.arena_upkeep()
	for row in SeasonScene.OFFICE_ROWS:
		t += row_upkeep(v, row["kind"])
	return t


static func _office_controls(v: SeasonScene) -> void:
	var o := v.season.office
	for i in SeasonScene.OFFICE_ROWS.size():
		var row: Dictionary = SeasonScene.OFFICE_ROWS[i]
		var kind = row["kind"]
		var y := v._office_row_y(i)
		var hb := UiKit.button("?", Vector2(HELP_X, y + 4.0), Vector2(34, 34), func(k = str(kind)):
			v.help_key = k
			v._rebuild())
		hb.tooltip_text = UiKit.t(String(row["label"]))
		v.ui.add_child(hb)
		var cost := row_cost(v, kind)
		if cost <= 0:
			continue
		var b := UiKit.button(UiKit.with_upkeep(upgrade_word(v, kind) + UiKit.t(" · %d CC") % cost,
				row_upkeep_next(v, kind)),
			Vector2(UPGRADE_X, y + 4.0), Vector2(UPGRADE_W, 34), func():
				var err: String
				if kind is String and kind == "cap":
					err = o.raise_cap()
				elif kind is String and kind == "insurance":
					err = o.raise_rule(Federation.Rule.INSURANCE)
				else:
					err = o.upgrade(int(kind))
				v.flash = UiKit.said(err) if err != "" else UiKit.t("Improved.")
				Session.autosave()
				v._rebuild(), "coin")
		b.disabled = cost > o.credits
		v.ui.add_child(b)
	## THE ARENA, on the right: the old "The ground" screen behind one button.
	v.ui.add_child(UiKit.button(UiKit.t("Arena"), Vector2(SIDE_X + 16.0, SIDE_Y + side_h() - 56.0),
		Vector2(side_w() - 32.0, 40), func():
			Session.autosave()
			UiKit.go("res://scenes/Arena.tscn"), "gate"))


## Where the upgrade buttons sit and how wide.
const UPGRADE_X := SeasonScene.BAR_X + SeasonScene.BAR_W + 14.0
const UPGRADE_W := 250.0
const SIDE_X := UPGRADE_X + UPGRADE_W + 18.0
const SIDE_Y := SeasonScene.CONTENT_Y + 4.0


static func side_w() -> float:
	return UiKit.right_edge() - SIDE_X


static func side_h() -> float:
	return SeasonScene.action_y() - 16.0 - SIDE_Y


## BEFORE → AFTER, for the button. What one more step of this buys, measured by
## taking the step on a copy of the number rather than written out a second time.
static func upgrade_word(v: SeasonScene, kind) -> String:
	var o := v.season.office
	if kind is String and kind == "cap":
		var now := o.cap()
		o.cap_level += 1
		var then := o.cap()
		o.cap_level -= 1
		return UiKit.t("Cap %s → %s") % [ClubOffice.money(now), ClubOffice.money(then)]
	if kind is String and kind == "insurance":
		var il := o.rule_level(Federation.Rule.INSURANCE)
		return UiKit.t("Level %d → %d") % [il, il + 1]
	var f := int(kind)
	var l := o.level(f)
	if f == ClubOffice.Facility.TRAINING:
		return UiKit.t("Camp +%d → +%d") % [l * 3, (l + 1) * 3]
	if f == ClubOffice.Facility.INFIRMARY and floori((l + 1) / 2.0) > floori(l / 2.0):
		return UiKit.t("Knocks -%d → -%d") % [floori(l / 2.0), floori((l + 1) / 2.0)]
	return UiKit.t("Level %d → %d") % [l, l + 1]


## ---------------------------------------------------------------- the menu
## RESUME, SETTINGS, SAVE / LOAD, QUIT (Pete, 1 Oct 2026). Four buttons down the
## middle of the card; Resume is the gold one because it is the one you came for.
static func _club_menu_controls(v: SeasonScene) -> void:
	var card := v.CLUB_CARD
	var bw := card.size.x - 96.0
	var x := card.position.x + 48.0
	var y := card.position.y + 70.0
	var items := [
		[UiKit.t("Resume"), "", "sword"],
		## THE GUIDE (Pete, 1 Oct 2026): what everything means, in one place.
		[UiKit.t("Guide"), "res://scenes/Guide.tscn", "book"],
		[UiKit.t("Settings"), "res://scenes/Settings.tscn", "cog"],
		[UiKit.t("Save / Load"), "res://scenes/Title.tscn", "book"],
		[UiKit.t("Save & quit"), "res://scenes/Start.tscn", "close"],
	]
	for i in items.size():
		var it: Array = items[i]
		var b := UiKit.button(String(it[0]), Vector2(x, y + float(i) * 56.0), Vector2(bw, 46),
			func(path = String(it[1])):
				v.club_menu_open = false
				if path == "":
					v._rebuild()
					return
				Session.autosave()
				if path != "res://scenes/Settings.tscn" and path != "res://scenes/Guide.tscn":
					UiKit.trail_reset()
				UiKit.go(path), String(it[2]))
		## SAVE & QUIT IS NOT RED: nothing is lost by it.
		v.ui.add_child(UiKit.primary(b) if i == 0 else b)


static func _draw_club_menu(v: SeasonScene) -> void:
	v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(v, v.CLUB_CARD)
	UiKit.mid(v, v.font, UiKit.t("MENU"),
		Vector2(v.CLUB_CARD.position.x, v.CLUB_CARD.position.y + 42.0), 19, UiKit.INK,
		v.CLUB_CARD.size.x)




## ---------------------------------------------------------------- training
## TRAINING (Pete, 1 Oct 2026: "Make it a pop up with Light/Normal/Hard
## options"). One row per captain — the regime belongs to the man who runs it —
## and the paid session under them. Hiring and releasing stay in the staff room.
const TRAIN_ROW := 64.0


static func _training_controls(v: SeasonScene) -> void:
	var card := v.TRAIN_CARD
	var o := v.season.office
	var bx0 := card.position.x + 300.0
	for i in o.captains.size():
		var y := card.position.y + 70.0 + float(i) * TRAIN_ROW
		var bw := (card.end.x - 24.0 - bx0 - 8.0) / 3.0
		for k in 3:
			v.ui.add_child(UiKit.selected(UiKit.button(UiKit.t(String(ClubOffice.REGIME_NAME[k])),
				Vector2(bx0 + float(k) * (bw + 4.0), y), Vector2(bw, 42),
				func(ci = i, rk = k):
					v.flash = UiKit.said(o.set_regime(ci, rk))
					Session.autosave()
					v._rebuild()),
				k == int(o.captains[i].get("regime", ClubOffice.Regime.NORMAL))))
	var cost := o.session_cost()
	var idle: bool = o.captains.is_empty()
	var sb := UiKit.button(UiKit.t("Session  ·  +%d XP each fighter  ·  %d CC") % [SeasonBouts.session_xp(v.season), cost],
		Vector2(card.position.x + 24.0, card.end.y - 66.0), Vector2(card.size.x - 48.0, 46), func():
			var err := v.season.run_session() if not idle else \
				UiKit.t("Nobody is teaching. A session with no captain is a warm-up.")
			v.flash = UiKit.said(err) if err != "" else UiKit.t("A week's work in one afternoon.")
			Session.autosave()
			v._rebuild())
	sb.disabled = cost > o.credits
	v.ui.add_child(sb if idle or sb.disabled else UiKit.primary(sb))
	var close_b := UiKit.button("", Vector2(card.end.x - 56.0, card.position.y + 12.0), Vector2(44, 44), func():
		v.training_open = false
		v._rebuild(), "close")
	close_b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.ui.add_child(close_b)


static func _draw_training(v: SeasonScene) -> void:
	var card := v.TRAIN_CARD
	var o := v.season.office
	v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(v, card)
	UiKit.text(v, v.font, UiKit.t("TRAINING"), card.position + Vector2(24, 40), 19, UiKit.INK)
	if o.captains.is_empty():
		UiKit.para(v, v.font, UiKit.t("Nobody is teaching. Hire a captain from Management, Staff."),
			card.position + Vector2(24, 96), 15, UiKit.DIM, card.size.x - 48.0, 20.0, 2)
	for i in o.captains.size():
		var c: Dictionary = o.captains[i]
		var y := card.position.y + 70.0 + float(i) * TRAIN_ROW
		UiKit.text_fit(v, v.font, String(c.get("name", "?")), Vector2(card.position.x + 24.0, y + 18.0), 17,
			UiKit.INK, 260.0)
		UiKit.text_fit(v, v.font, UiKit.t("CAPTAIN  ·  %s") % ClubOffice.teaches_line(c),
			Vector2(card.position.x + 24.0, y + 38.0), 13, UiKit.DIM, 260.0)
	## WHAT THE THREE TRADE, in one line each.
	var ly := card.position.y + 70.0 + float(maxi(1, o.captains.size())) * TRAIN_ROW + 18.0
	for k in 3:
		UiKit.text_fit(v, v.font, _regime_line(k), Vector2(card.position.x + 24.0, ly + float(k) * 20.0), 14,
			[UiKit.UP, UiKit.YOU, UiKit.DOWN][k], card.size.x - 48.0)


static func _regime_line(k: int) -> String:
	match k:
		ClubOffice.Regime.LIGHT:
			return UiKit.t("Light: XP ×0.6, morale up, knocks rare")
		ClubOffice.Regime.HARD:
			return UiKit.t("Hard: XP ×1.5, morale down, knocks ×5")
	return UiKit.t("Normal: XP ×1.0")




## Who is available — one list, in ClubOffice, read by both screens that sell
## captains. It used to be a second copy of the same hash here.
static func _offer(v: SeasonScene, slot: int) -> Dictionary:
	return v.season.staff_offer(slot)




## ---------------------------------------------------------------- the shop
## COACHING CREDITS, BOUGHT WITH MONEY. The only thing this game sells.
##
## Direction §8, superseded by Pete on 12 Sep 2026: premium at $4.99 with IAP
## for credits. There is no unlock product — nothing is locked, because the
## price of entry already happened.
##
## `Store` decides whether there is a counter at all; this only draws it. On
## desktop and on any build without the billing plugin the packs are not drawn
## and the reason is, because **a shop that shows a button it cannot honor is a
## shop that takes a tap and does nothing.**
static func _shop_controls(v: SeasonScene) -> void:
	var y := v.SHOP_CARD.position.y + v.SHOP_CARD.size.y - 62.0
	if Store.available():
		var packs := Store.PRODUCTS
		var pad := 24.0
		var pw: float = (v.SHOP_CARD.size.x - pad * 2.0 - 16.0) / float(maxi(1, packs.size()))
		for i in packs.size():
			var pk: Dictionary = packs[i]
			## THE STORE'S OWN PRICE, localized, once Play has answered.
			v.ui.add_child(UiKit.button(UiKit.t("%d  ·  %s") % [int(pk["credits"]), Store.price_word(String(pk["id"]))],
				Vector2(v.SHOP_CARD.position.x + pad + float(i) * (pw + 8.0),
					v.SHOP_CARD.position.y + 150.0), Vector2(pw, 46),
				func(id = String(pk["id"])):
					var err := Store.buy(id)
					if err != "":
						v.flash = UiKit.said(err)
					else:
						## The grant is the store's callback, not this tap — a
						## shop that credits on the REQUEST credits a canceled
						## purchase. What lands now is whatever is already owed.
						var got := Store.claim(v.season.office, Session.autosave)
						v.flash = (UiKit.t("%d credits.") % got) if got > 0 \
							else UiKit.t("Asked the store. Credits land when it answers.")
					v._rebuild()))
		## THE BUTTON A PLAYER WHOSE MONEY WENT MISSING WILL LOOK FOR. For a
		## consumable there is nothing to re-own — the credits were spent — so
		## this asks the store for anything it charged for and never delivered.
		v.ui.add_child(UiKit.button(UiKit.t("Restore a purchase"),
			Vector2(v.SHOP_CARD.position.x + 24.0, y), Vector2(240, 44), func():
				Store.resolve_pending()
				var got := Store.claim(v.season.office, Session.autosave)
				v.flash = (UiKit.t("%d credits.") % got) if got > 0 \
					else UiKit.t("Asked the store for anything outstanding.")
				v._rebuild()))
	v.ui.add_child(UiKit.button(UiKit.t("Back"),
		Vector2(v.SHOP_CARD.end.x - 184.0, y), Vector2(160, 44), func():
			v.shop_open = false
			v._rebuild()))




static func _draw_shop(v: SeasonScene) -> void:
	v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(v, v.SHOP_CARD)
	UiKit.mid(v, v.font, UiKit.t("COACHING CREDITS"),
		Vector2(v.SHOP_CARD.position.x, v.SHOP_CARD.position.y + 34.0), 19, UiKit.INK,
		v.SHOP_CARD.size.x)
	UiKit.mid(v, v.font, UiKit.t("Spent on levels, kit, the cap and the bus."),
		Vector2(v.SHOP_CARD.position.x, v.SHOP_CARD.position.y + 60.0), 14, UiKit.DIM,
		v.SHOP_CARD.size.x)
	UiKit.text(v, v.font, UiKit.t("In hand"), Vector2(v.SHOP_CARD.position.x + 24.0,
		v.SHOP_CARD.position.y + 104.0), 14, UiKit.DIM)
	UiKit.right(v, v.font, UiKit.t("%d CC") % v.season.office.credits,
		Vector2(v.SHOP_CARD.end.x - 24.0, v.SHOP_CARD.position.y + 104.0), 15, UiKit.YOU, 200)
	if not Store.available():
		## The reason, in the middle, where the packs would have been.
		UiKit.mid(v, v.font, Store.closed_word(),
			Vector2(v.SHOP_CARD.position.x, v.SHOP_CARD.position.y + 170.0), 14,
			UiKit.EDGE.lightened(0.5), v.SHOP_CARD.size.x)
	elif Store.owed > 0:
		UiKit.right(v, v.font, UiKit.t("%d waiting") % Store.owed,
			Vector2(v.SHOP_CARD.end.x - 24.0, v.SHOP_CARD.position.y + 128.0), 12,
			UiKit.YOU, 200)
	## A PENDING PAYMENT (cash at a shop, a slow bank) is not lost and not
	## credited — say so, or the player buys the pack twice.
	if Store.available() and Store.pending > 0:
		UiKit.text(v, v.font, UiKit.t("A payment is pending. Credits land when it clears."),
			Vector2(v.SHOP_CARD.position.x + 24.0, v.SHOP_CARD.position.y + 128.0), 14, UiKit.DIM)




static func _draw_office(v: SeasonScene) -> void:
	var o := v.season.office
	UiKit.text(v, v.font, UiKit.t("UPGRADES"), Vector2(SeasonScene.BAR_X, SeasonScene.CONTENT_Y + 6.0), 20, UiKit.INK)
	for i in SeasonScene.OFFICE_ROWS.size():
		var row: Dictionary = SeasonScene.OFFICE_ROWS[i]
		var kind = row["kind"]
		var y := v._office_row_y(i)
		var label := UiKit.t(String(row["label"]))
		var bar := Rect2(SeasonScene.BAR_X, y + 8.0, BAR_W, SeasonScene.BAR_H)
		var right := ""
		if kind is String and kind == "cap":
			## A GAUGE, THE BILL WRITTEN IN THE FILL (Pete, 1 Oct 2026).
			var bill := ClubOffice.wage_bill(v.season.club)
			var cap := o.cap()
			var frac := clampf(float(bill) / float(maxi(1, cap)), 0.0, 1.0)
			v.draw_rect(bar, UiKit.TRACK)
			v.draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)),
				UiKit.DOWN if bill > cap else UiKit.YOU)
			v.draw_rect(bar, UiKit.FRAME, false, 1.0)
			UiKit.text(v, v.font, ClubOffice.money(bill), bar.position + Vector2(6, 19), 14, UiKit.BG)
			UiKit.right(v, v.font, ClubOffice.money(cap), Vector2(bar.end.x - 6.0, bar.position.y + 19.0), 14,
				UiKit.DIM, 80)
		elif kind is String and kind == "insurance":
			var il := o.rule_level(Federation.Rule.INSURANCE)
			var need := Federation.required(o.tier, Federation.Rule.INSURANCE)
			right = UiKit.t("league needs %d") % need
			UiKit.meter(v, bar, il, Federation.MAX_LEVEL, UiKit.UP if il >= need else UiKit.DOWN)
		else:
			var f := int(kind)
			right = UiKit.t("not built")
			match f:
				ClubOffice.Facility.TRAINING:
					## THE GROUND'S OWN SHARE, the number its button moves (review, 1 Oct).
					right = UiKit.t("+%d winter camp") % (o.level(f) * 3)
				ClubOffice.Facility.INFIRMARY:
					if o.injury_relief() > 0:
						right = UiKit.tn("-%d event off a knock", "-%d events off a knock",
							o.injury_relief()) % o.injury_relief()
			UiKit.meter(v, bar, o.level(f), ClubOffice.FACILITY_MAX, UiKit.UP if o.level(f) > 0 else UiKit.EDGE)
		UiKit.pair(v, v.font, label, right, Vector2(SeasonScene.BAR_X, y), HELP_X + 34.0, 13, 12, UiKit.DIM, UiKit.INK)
		var keep := row_upkeep(v, kind)
		UiKit.right(v, v.font, UiKit.t("%d CC/Year") % keep, Vector2(UPGRADE_X + UPGRADE_W, y + 52.0), 13,
			UiKit.DOWN if keep > 0 else UiKit.DIM, UPGRADE_W - 60.0)
	var ty := v._office_row_y(SeasonScene.OFFICE_ROWS.size()) + 16.0
	v.draw_line(Vector2(SeasonScene.BAR_X, ty - 18.0), Vector2(UPGRADE_X + UPGRADE_W, ty - 18.0), UiKit.FRAME, 1.0)
	UiKit.pair(v, v.font, UiKit.t("Maintenance total, arena included"), UiKit.t("%d CC/Year") % upkeep_total(v),
		Vector2(SeasonScene.BAR_X, ty), UPGRADE_X + UPGRADE_W, 15, 15, UiKit.INK, UiKit.DOWN)
	_draw_arena_panel(v)


## THE ARENA, IN BRIEF (Pete, 1 Oct 2026: "Put the Arena in there on the right,
## brief info and Arena button").
static func _draw_arena_panel(v: SeasonScene) -> void:
	var o := v.season.office
	var a := o.arena
	var r := Rect2(SIDE_X, SIDE_Y, side_w(), side_h())
	UiKit.panel(v, r)
	var x := r.position.x + 16.0
	var w := r.size.x - 32.0
	var y := r.position.y + 26.0
	UiKit.text(v, v.font, UiKit.t("ARENA"), Vector2(x, y), 13, UiKit.DIM)
	y += 26.0
	UiKit.text_fit(v, v.font, a.arena_name(), Vector2(x, y), 19, UiKit.INK, w)
	y += 22.0
	UiKit.text_fit(v, v.font, UiKit.t("Level %d of %d  ·  holds %d") % [a.level, Arena.LEVELS.size() - 1, a.capacity()],
		Vector2(x, y), 13, UiKit.DIM, w)
	y += 30.0
	UiKit.pair(v, v.font, UiKit.t("Crowd"), UiKit.t("%d%% full") % int(round(o.fill() * 100.0)),
		Vector2(x, y), x + w, 14, 14, UiKit.DIM, UiKit.INK)
	y += 8.0
	UiKit.bar(v, Rect2(x, y, w, 8), o.fill(), UiKit.YOU)
	y += 30.0
	UiKit.pair(v, v.font, UiKit.t("A home fight pays"), UiKit.t("%d CC") % o.crowd_pay(),
		Vector2(x, y), x + w, 14, 14, UiKit.DIM, UiKit.UP)
	y += 24.0
	UiKit.pair(v, v.font, UiKit.t("Maintenance"), UiKit.t("%d CC/Year") % o.arena_upkeep(),
		Vector2(x, y), x + w, 14, 14, UiKit.DIM, UiKit.DOWN)
	y += 24.0
	if not a.at_top():
		UiKit.pair(v, v.font, UiKit.t("Next"), String(UiKit.t(String(a.next()["name"]))),
			Vector2(x, y), x + w, 14, 14, UiKit.DIM, UiKit.INK)


## ------------------------------------------------------------------ the "?"
static func help_text(key: String) -> Array:
	if key == "kit":
		return [UiKit.t("KIT"), UiKit.t("Your armorer's stars are the best metal he can make and keep.")]
	if key == "cap":
		return [UiKit.t("SALARY CAP"), UiKit.t("$ is yearly wages. Your whole team's wages may not add up to more than the cap. Raise it to carry better men.")]
	if key == "insurance":
		return [UiKit.t("INSURANCE"), UiKit.t("Cover for the men, the ground and the people watching. Each league asks for a level. Below it, you are not entered for the cups.")]
	if key == str(ClubOffice.Facility.TRAINING):
		return [UiKit.t("TRAINING GROUND"), UiKit.t("More weekly practice, and a bigger winter camp.")]
	if key == str(ClubOffice.Facility.INFIRMARY):
		return [UiKit.t("INFIRMARY"), UiKit.t("Each level: a knock keeps a man out one event less, and one knock in ten never lands.")]
	return ["", ""]


static func _help_card() -> Rect2:
	var sz := Vector2(520.0, 290.0)
	return Rect2(Vector2(floorf((UiKit.screen().x - sz.x) * 0.5), 130.0), sz)


static func _help_controls(v: SeasonScene) -> void:
	var card := _help_card()
	v.ui.add_child(UiKit.button(UiKit.t("Got it"), Vector2(card.end.x - 184.0, card.end.y - 62.0), Vector2(160, 44),
		func():
			v.help_key = ""
			v._rebuild()))


static func _draw_help(v: SeasonScene) -> void:
	var card := _help_card()
	var h := help_text(v.help_key)
	v.draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), Color(0, 0, 0, 0.74))
	UiKit.panel(v, card)
	UiKit.text(v, v.font, String(h[0]), card.position + Vector2(24, 40), 19, UiKit.INK)
	if v.help_key == "kit":
		## THE FIVE METALS, BY STAR, and nothing else (Pete, 1 Oct 2026).
		for i in Armorer.MAX_STARS:
			var y := card.position.y + 76.0 + float(i) * 24.0
			UiKit.stars(v, Vector2(card.position.x + 24.0, y - 12.0), (i + 1) * 20, UiKit.YOU, 12.0, 2.0)
			UiKit.text(v, v.font, Armorer.metal_name(i), Vector2(card.position.x + 120.0, y), 16, UiKit.INK)
		UiKit.para(v, v.font, String(h[1]), Vector2(card.position.x + 24.0, card.position.y + 200.0), 13,
			UiKit.DIM, card.size.x - 48.0, 17.0, 2)
		return
	UiKit.para(v, v.font, String(h[1]), card.position + Vector2(24, 78), 15, UiKit.DIM,
		card.size.x - 48.0, 21.0, 4)
