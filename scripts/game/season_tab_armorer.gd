class_name SeasonArmorerTab
extends RefCounted
## Methods of `SeasonScene`, moved out of season_scene.gd so that file is not one
## three-thousand-line object. Every function takes the SeasonScene as `v`; `SeasonScene`
## keeps a one-line wrapper for each, so callers did not change.






# ------------------------------------------------------------ THE ARMORER
## AND IT REPLACES THE FREE-AGENT LIST THAT USED TO BE ON THIS TAB.
##
## Pete, 15 Sep 2026: *"Rebuild Market, there's a tab within a tab."* He was
## exactly right — the tab drew a list of free agents and then carried a button
## labelled "Free agents" that opened a second, better screen of the same men.
## Two views of one thing, one of them a worse version of the other, reached by a
## control named after the tab you were already standing on.
##
## The free agents moved to the Squad tab, where a player is already thinking
## about his squad. This tab is now the one thing the game had a full mechanic
## for and no screen at all: what everybody is wearing, what state it is in, who
## the marshals are about to refuse, and what it costs to put right. See
## `scripts/league/quartermaster.gd` for what was measured before it was built.
static func _draw_market(v: SeasonScene) -> void:
	var o := v.season.office
	var eight := v.season.club.active_eight()
	var led := Quartermaster.ledger(eight)

	UiKit.pair(v, v.font, UiKit.t("THE ARMORER"), UiKit.t("%d CC in hand") % o.credits,
		Vector2(24, SeasonScene.CONTENT_Y), UiKit.right_edge(), 16, 13, UiKit.YOU, UiKit.DIM)

	## THE HEADLINE IS THE MARSHALS, not the average. A club whose mean harness
	## reads 74% is fine; a club with one man under the line cannot field five,
	## and those two facts do not live in the same number.
	var head := UiKit.t("Every traveling harness passes inspection.")
	var head_col := UiKit.UP
	if int(led["failing"]) > 0:
		head = "%d of the eight will not pass inspection." % led["failing"]
		head_col = UiKit.DOWN
	elif int(led["at_risk"]) > 0:
		head = "%d of the eight are a bad week from failing." % led["at_risk"]
		## YOU, NOT DOWN. A club a bad week from trouble is a warning and a club
		## already in it is a failure; drawing both in the same red loses the only
		## distinction the line exists to make.
		head_col = UiKit.YOU
	UiKit.pair(v, v.font, head,
		("%d CC to put the eight right" % led["bill"]) if int(led["bill"]) > 0
			else UiKit.t("nothing owing"),
		Vector2(24, SeasonScene.CONTENT_Y + 26), UiKit.right_edge(), 14, 14, head_col, UiKit.DIM)

	var cell := v._qm_cell()
	UiKit.text(v, v.font, UiKit.t("TRAVELING"), Vector2(24, SeasonScene.CONTENT_Y + SeasonScene.QM_TOP - 22),
		12, UiKit.DIM)
	UiKit.text(v, v.font, UiKit.t("AT HOME"),
		Vector2(24 + cell + SeasonScene.QM_GAP, SeasonScene.CONTENT_Y + SeasonScene.QM_TOP - 22), 12, UiKit.DIM)
	## COLUMN HEADINGS (blind review round 3: "Borrowed" x13 and an unlabelled
	## "3 CC" told the player nothing). Over both halves.
	for cx in [24.0, 24.0 + cell + SeasonScene.QM_GAP]:
		var hy := SeasonScene.CONTENT_Y + SeasonScene.QM_TOP - 22
		var gx0: float = cx + SeasonScene.QM_NAME_W + 6.0
		UiKit.text_fit(v, v.font, UiKit.t("HARNESS"), Vector2(gx0, hy), 12, UiKit.DIM, SeasonScene.QM_GRADE_W)
		UiKit.text_fit(v, v.font, UiKit.t("CONDITION"), Vector2(gx0 + SeasonScene.QM_GRADE_W + 6.0, hy), 12,
			UiKit.DIM, SeasonScene.QM_BAR_W)
		UiKit.right(v, v.font, UiKit.t("FIX"), Vector2(cx + cell, hy), 12, UiKit.DIM, SeasonScene.QM_COST_W)

	## WHAT TO DO HERE, said (blind review, 29 Sep: "no visible action"). The
	## rows are the buttons; the line on each bar is the marshals' minimum.
	if v.qm_pick == null:
		UiKit.text(v, v.font, UiKit.t("Tap a fighter to repair or upgrade his harness. The tick is the minimum."),
			Vector2(24, SeasonScene.action_y() - 14.0), 14, UiKit.DIM)
	for row in v._qm_rows():
		var f: FighterCard = row["card"]
		var y: float = row["y"]
		var x: float = row["x"]
		var bus: bool = row["bus"]
		## EVERY ROW IS A BUTTON AND NOW LOOKS LIKE ONE: a plate under it.
		v.draw_rect(Rect2(x - 4.0, y - 20, cell + 8.0, SeasonScene.QM_ROW - 4),
			UiKit.SELECT if v.qm_pick == f else UiKit.PANEL)

		## A MAN IN THE RESERVE IS DRAWN QUIETER. His kit still wears, but he is
		## not the one the marshals are about to look at.
		UiKit.text(v, v.font, UiKit.clip_px(v.font, f.display_name, 14, SeasonScene.QM_NAME_W),
			Vector2(x, y), 14, UiKit.INK if bus else UiKit.DIM)
		var gx := x + SeasonScene.QM_NAME_W + 6.0
		UiKit.text(v, v.font, UiKit.clip_px(v.font, Quartermaster.name_of(f), 12,
			SeasonScene.QM_GRADE_W), Vector2(gx, y), 12,
			UiKit.UP if Quartermaster.grade_of(f) >= Quartermaster.Grade.FITTED
			else UiKit.DIM)

		## THE BAR CARRIES TWO LINES THE NUMBER CANNOT.
		##
		## The inspection line, painted where it actually falls, so "how close am
		## I" is a look rather than a subtraction. And the ceiling of his grade,
		## so the gap he can NEVER close is visible — which is the whole sales
		## pitch for the next harness and the one thing a percentage hides.
		var bx := gx + SeasonScene.QM_GRADE_W + 6.0
		var r := Rect2(bx, y - 11, SeasonScene.QM_BAR_W, 13)
		var col := UiKit.DOWN if not f.passes_inspection() \
			else (UiKit.UP if f.inspection_margin() >= Quartermaster.RISK_MARGIN
				else UiKit.YOU)
		UiKit.bar(v, r, clampf(f.armor, 0.0, 1.0), col)
		v.draw_rect(Rect2(r.position.x + r.size.x * FighterCard.INSPECTION_MIN - 1.0,
			r.position.y - 3, 2.0, r.size.y + 6), UiKit.DOWN)
		if Quartermaster.ceiling(f) < 0.999:
			v.draw_rect(Rect2(r.position.x + r.size.x * Quartermaster.ceiling(f),
				r.position.y - 2, 1.0, r.size.y + 4), UiKit.EDGE)

		## WHAT IT COSTS, on the row, so a player reads the bill down a column
		## instead of tapping thirteen men to find out.
		var word := ""
		var wcol := UiKit.DIM
		if not f.passes_inspection():
			word = UiKit.t("OUT")
			wcol = UiKit.DOWN
		elif not Quartermaster.topped_out(f):
			word = "%d CC" % ClubOffice.kit_cost(f)
		elif Quartermaster.next_grade(f) >= 0:
			word = "%d CC" % Quartermaster.upgrade_cost(f)
			wcol = UiKit.DIM
		if word != "":
			UiKit.right(v, v.font, word, Vector2(x + cell, y), 12, wcol, SeasonScene.QM_COST_W)




static func _market_controls(v: SeasonScene) -> void:
	var o := v.season.office
	var led := Quartermaster.ledger(v.season.club.active_eight())
	var cell := v._qm_cell()

	for row in v._qm_rows():
		var f: FighterCard = row["card"]
		var b := UiKit.button("", Vector2(float(row["x"]) - 4.0, float(row["y"]) - 20),
			Vector2(cell + 8.0, SeasonScene.QM_ROW - 4), func():
				v.qm_pick = f
				v.flash = ""
				v._rebuild())
		b.flat = true
		b.focus_mode = Control.FOCUS_NONE
		v.ui.add_child(b)

	## THE BULK ACTION IS THE ONE A PLAYER ACTUALLY WANTS. Thirteen taps to fix
	## thirteen harnesses is not a decision, it is a chore — the decision is "can
	## I afford the bus this week", and that is one button with the answer on it.
	var third := (UiKit.span() - 16.0) / 3.0
	if int(led["bill"]) > 0:
		v.ui.add_child(UiKit.button(UiKit.t("Repair the traveling kit  ·  %d CC") % led["bill"],
			Vector2(24, SeasonScene.action_y()), Vector2(third, 46), func():
				var fixed := 0
				var spent := 0
				for f in v.season.club.active_eight():
					if Quartermaster.topped_out(f):
						continue
					var c := ClubOffice.kit_cost(f)
					if o.repair_kit(f) == "":
						fixed += 1
						spent += c
				v.flash = (UiKit.t("Nothing the armorer could do this week.") if fixed == 0
					else UiKit.t("%d harnesses seen to, %d CC.") % [fixed, spent])
				v.season.sync_power()
				Session.autosave()
				v._rebuild(), "armor"))

	if v.qm_pick != null:
		var nm := UiKit.clip(v.qm_pick.display_name, 9)
		if not Quartermaster.topped_out(v.qm_pick):
			v.ui.add_child(UiKit.button(UiKit.t("Repair %s · %d CC") % [nm,
				ClubOffice.kit_cost(v.qm_pick)],
				Vector2(24 + third + 8.0, SeasonScene.action_y()), Vector2(third, 46), func():
					var err := o.repair_kit(v.qm_pick)
					v.flash = UiKit.said(err) if err != "" \
						else "%s's harness seen to." % v.qm_pick.display_name
					v.season.sync_power()
					Session.autosave()
					v._rebuild()))
		var nxt := Quartermaster.next_grade(v.qm_pick)
		if nxt >= 0:
			v.ui.add_child(UiKit.button(UiKit.t("Upgrade to %s · %d CC") % [
				UiKit.t(String(Quartermaster.GRADE_NAME[nxt])),
				Quartermaster.upgrade_cost(v.qm_pick)],
				Vector2(24 + (third + 8.0) * 2.0, SeasonScene.action_y()), Vector2(third, 46), func():
					var err := o.buy_harness(v.qm_pick)
					v.flash = UiKit.said(err) if err != "" \
						else "%s is in %s harness." % [v.qm_pick.display_name,
							Quartermaster.name_of(v.qm_pick).to_lower()]
					v.season.sync_power()
					Session.autosave()
					v._rebuild(), "coin"))
