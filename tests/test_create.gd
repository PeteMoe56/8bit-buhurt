extends SceneTree
## CREATE-A-PLAYER and CREATE-A-TEAM.
##
##   godot --headless --path . --script res://tests/test_create.gd
##
## This screen is the one that can break the game, and not by accident — by
## working exactly as a player would want it to. The roster is the top rung of
## the ladder (roster > thumb > tactics), so a fighter you write yourself is the
## single most powerful thing in the product. Every check here is on the
## governor rather than on the feature.

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	## Its own corner of user:// — these files run in parallel and there are
	## only three slots between all of them.
	SaveGame.set_namespace("create")
	print("\n=== 8-Bit Buhurt — create ===\n")
	_test_the_division_caps_a_made_man()
	_test_a_lopsided_build_cannot_dodge_the_cap()
	_test_the_ceiling_rises_with_you()
	_test_four_men_and_they_cost()
	_test_a_made_man_joins_the_books_properly()
	_test_the_cap_still_bites()
	_test_the_bank_is_bought_not_given()
	_test_every_mark_reads()
	_test_the_contrast_rule_holds()
	_test_the_workshop_saves()
	await _test_the_dials_are_customs()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("CREATE HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


func _man(s: int, b: int, k: int, g: int, a: int, nm := "Made Man") -> FighterCard:
	var f := Workshop.blank()
	f.display_name = nm
	f.strength = s
	f.base = b
	f.skill = k
	f.gas = g
	f.aggression = a
	return f


func _test_the_division_caps_a_made_man() -> void:
	## The whole point. A Backyard club cannot write a National Division fighter
	## and walk the league with him.
	var lim := Workshop.limits(0)
	var monster := _man(99, 99, 99, 99, 99)
	var fine := _man(40, 42, 40, 40, 38)
	_ok(Workshop.fighter_legal(monster, 0) != "" and Workshop.fighter_legal(fine, 0) == ""
			and int(lim["rating"]) == 52,
		"the division caps a made man",
		"Backyard tops out at %d; a 99 across the board is refused" % int(lim["rating"]))
	_ok(Workshop.fighter_legal(_man(50, 50, 50, 50, 50, ""), 0) != "",
		"a made man needs a name", "an unnamed fighter is refused before anything else")


func _test_a_lopsided_build_cannot_dodge_the_cap() -> void:
	## A RATING CAP ALONE IS NOT A CAP. Rating is a weighted mean, so 99 strength
	## with ones everywhere else rates 24 and sails through — and then bullrushes
	## a division whose best man is 46. That is the hole the per-stat ceiling
	## exists to close, and it is the one somebody would actually find.
	var sneak := _man(99, 1, 1, 1, 1)
	var lim := Workshop.limits(0)
	var under_rating: bool = sneak.rating() <= float(lim["rating"])
	_ok(under_rating and Workshop.fighter_legal(sneak, 0) != "",
		"a lopsided build cannot dodge the cap",
		"99 strength rates %d — inside the rating cap — and is still refused" % sneak.overall())


func _test_the_ceiling_rises_with_you() -> void:
	## It has to move, or the feature dies the moment you get promoted.
	var ceilings: Array = []
	for t in League.TIERS.size():
		ceilings.append(int(Workshop.limits(t)["rating"]))
	var rising := true
	for i in range(1, ceilings.size()):
		if ceilings[i] <= ceilings[i - 1]:
			rising = false
	var top := _man(70, 70, 70, 70, 70)
	_ok(rising and Workshop.fighter_legal(top, 0) != ""
			and Workshop.fighter_legal(top, League.TIERS.size() - 1) == "",
		"the ceiling rises with you",
		"caps by division: %s" % str(ceilings))


func _test_four_men_and_they_cost() -> void:
	var s := _season(80)
	var spent := 0
	var made := 0
	for i in 6:
		var before := s.office.credits
		var err := s.workshop.create(s.office, s.club, _man(40, 40, 40, 40, 40, "Man %d" % i),
			_worst(s.club))
		if err == "":
			made += 1
			spent += before - s.office.credits
	_ok(made == Workshop.MAX_FIGHTERS and spent == 3 + 5 + 7 + 9 and s.workshop.left() == 0
			and s.club.roster.size() == MeleeClub.SQUAD_MAX,
		"four men, and they cost",
		"%d written for %d credits; the fifth is refused, the books stay at %d" % [
			made, spent, s.club.roster.size()])


func _test_a_made_man_joins_the_books_properly() -> void:
	## ON THE RESERVE, not on the line. A made man who walked straight into the
	## five would make the depth chart decorative.
	var s := _season(80)
	var before := s.club.roster.size()
	var gone := _worst(s.club)
	var numbers := {}
	for f in s.club.roster:
		numbers[f.number] = true
	var err := s.workshop.create(s.office, s.club, _man(42, 44, 40, 41, 38, "Hollis Vane"), gone)
	var him: FighterCard = s.club.roster[s.club.roster.size() - 1]
	_ok(err == "" and s.club.roster.size() == before and not him.active
			and s.club.reserves().has(him) and not s.club.roster.has(gone)
			and s.club.line_legal() == "",
		"a made man joins the books properly",
		"%s replaced on the reserve; the club still fields a legal line" % gone.display_name)
	## Nobody on the eight can be written over from here. Losing a starter to a
	## button on a creation screen is not a decision anybody meant to make.
	var starter: FighterCard = s.club.active_eight()[0]
	var refused := s.workshop.create(s.office, s.club, _man(40, 40, 40, 40, 40, "Late"), starter)
	## And a half-applied create is the worst bug this screen could have: the man
	## it refused to replace must still be there.
	_ok(refused != "" and s.club.roster.has(starter),
		"a refused create changes nothing",
		"replacing a man on the eight is refused and he is still on the books")


func _test_the_cap_still_bites() -> void:
	## Creating him and affording him are two decisions. A club already at its
	## cap cannot write its way past it.
	## Swapping a cheap reserve for an expensive made man is exactly how a player
	## would try to buy his way past the cap, so that is the trade under test.
	## THE WAGE CURVE IS EXPONENTIAL, so the cap only bites near the top of a
	## division: the club you start with has room for any legal made man, and a
	## club at the band top still has a little. That is the correct shape — the
	## rating ceiling is what governs an ordinary club and the cap is what
	## governs a good one — but it means this check has to be run against a club
	## that is genuinely tight, or it proves nothing and passes anyway.
	##
	## THE HOLE IS SWEPT AT RUN TIME, not written down. This check used to name a
	## rating — 52 against a club built at 48 — and the contract layer moved the
	## bill under it without touching anything this test was about: some of that
	## club's men are now on rookie deals at 60% of market, so the squad bills
	## less and a 52 fits where he used to breach. That is the sixth hardcoded
	## threshold in this suite to go stale.
	##
	## The first rewrite swept for the wall and found one at 56 — and PASSED FOR
	## THE WRONG REASON, because at 56 the RATING cap fires first: the refusal it
	## read as proof of the wage check was "the Backyard Circuit caps a made man
	## at 52". Two rules guard this button and the sweep had wandered into the
	## other one. A green test proving a rule it is not testing is worse than a
	## red one.
	##
	## So the club is put where the question is real: wages loaded until the bill
	## is just under the cap, and then a man who is comfortably LEGAL on rating is
	## created. The only thing that can refuse him is the wage check, and the
	## refusal has to say so.
	var s := _season(80)
	s.club = ClubFactory.build(901, "Top of the Shop", "TOP", 48)
	var o := s.office
	var cheap := _worst(s.club)

	## A man the rating cap has no opinion about — asked of the same function the
	## button asks, then stepped back until it says yes, so this cannot drift out
	## of step with the limit it is dodging.
	var legal_top := 90
	var dear: FighterCard = null
	while legal_top > 20:
		dear = _man(legal_top, legal_top, legal_top, legal_top, legal_top, "Expensive")
		if s.workshop.fighter_legal(dear, o.tier) == "":
			break
		legal_top -= 1
	var his_wage := Contracts.offer(ClubOffice.wage(dear), dear.age)

	## Load the squad so the swap lands exactly ONE DOLLAR over. Everybody on a
	## dollar and the remainder piled on one man, rather than a per-man share:
	## dividing the room evenly truncates, the bill lands several dollars under
	## where it was aimed, and the check quietly stops testing the boundary it
	## was written for. The first attempt did precisely that and came out at $194
	## of a $200 cap.
	var others: Array = []
	for f in s.club.roster:
		if f != cheap:
			others.append(f)
	for f in others:
		f.wage_agreed = 1
	## bill_after = billed(cheap) + (n-1) + big - billed(cheap) + his_wage
	var big: int = o.cap() + 1 - his_wage - (others.size() - 1)
	others[0].wage_agreed = maxi(1, big)
	var bill := ClubOffice.wage_bill(s.club) - ClubOffice.billed(cheap) + his_wage
	var fits_before: bool = ClubOffice.wage_bill(s.club) <= o.cap()

	var err := s.workshop.create(o, s.club, dear, cheap)
	notes.append("a squad billing %s of a %s cap, and a legal %d who wants %s: \"%s\""
		% [ClubOffice.money(ClubOffice.wage_bill(s.club)), ClubOffice.money(o.cap()),
			legal_top, ClubOffice.money(his_wage), err])
	_ok(fits_before and bill > o.cap() and err != "" and err.contains("cap")
			and s.workshop.fighter_legal(dear, o.tier) == ""
			and s.club.roster.has(cheap) and s.workshop.made == 0,
		"the cap still bites",
		"a man the rating cap allows is still refused on wages, and the refusal names the bill rather than the rating")


func _test_the_bank_is_bought_not_given() -> void:
	## THE MARK IS THE PURCHASE. A club can wear the starter set from the first
	## save and nothing else until it pays, and the check lives on Workshop
	## rather than on the create screen — a rule enforced at one call site is a
	## rule with a hole in it.
	var s := _season(20)
	var starter: Array = IconBank.starter()
	var paid: int = IconBank.in_pack(IconBank.PACK_STEEL)[0]
	var before := s.office.credits
	var wearing_locked := s.workshop.rename(s.club, "Bonk Works", "BNK",
		IconBank.KIT_COLORS[0], IconBank.MARK_COLORS[0], paid)
	var bought := s.workshop.buy_icon(s.office, paid)
	var now_ok := s.workshop.rename(s.club, "Bonk Works", "BNK",
		IconBank.KIT_COLORS[0], IconBank.MARK_COLORS[0], paid)
	var twice := s.workshop.buy_icon(s.office, paid)
	_ok(starter.size() == 4 and s.workshop.owns(starter[0])
			and wearing_locked != "" and bought == "" and now_ok == ""
			and s.club.icon == paid and twice != ""
			and before - s.office.credits == IconBank.cost(paid),
		"the bank is bought, not given",
		"%d free marks; the %s cost %d and cannot be bought twice" % [
			starter.size(), IconBank.icon_name(paid), IconBank.cost(paid)])
	## Broke is a refusal, not a free mark.
	var poor := _season(0)
	var dear: int = IconBank.in_pack(IconBank.PACK_BEASTS)[3]
	_ok(poor.workshop.buy_icon(poor.office, dear) != "" and not poor.workshop.owns(dear),
		"a mark you cannot afford stays locked",
		"no credits, no %s" % IconBank.icon_name(dear))


func _test_every_mark_reads() -> void:
	## Two things a mark has to be, checked here because they are checkable and
	## the third thing — whether it LOOKS like an axe — is not, and is settled by
	## rendering the sheet in tools/shot_icons.gd and looking at it.
	##
	## Ids must be unique and stable: the save stores the id, so a renumbering
	## silently repaints every club that ever bought a mark.
	var seen := {}
	var dupes := 0
	var unnamed := 0
	for e in IconBank.ICONS:
		if seen.has(int(e["id"])):
			dupes += 1
		seen[int(e["id"])] = true
		if String(e["name"]).strip_edges() == "":
			unnamed += 1
	## EVERY KIT HAS MARKS THAT READ ON IT. The mark popup greys the pairs the
	## contrast rule refuses (1 Oct 2026: more colors, some of them bright), so
	## what it must never do is leave a kit with nothing to wear on it.
	var bad := 0
	for kit in IconBank.KIT_COLORS:
		var legal := 0
		for mark in IconBank.MARK_COLORS:
			if IconBank.contrast_ok(kit, mark):
				legal += 1
		if legal < 3:
			bad += 1
	_ok(dupes == 0 and unnamed == 0 and bad == 0 and IconBank.count() >= 20,
		"every mark reads",
		"%d marks, ids unique, and every one of %d kits has at least three marks that read on it (%d short)" % [
			IconBank.count(), IconBank.KIT_COLORS.size(), bad])


func _test_the_contrast_rule_holds() -> void:
	## Create-A-Team's only real rule: the mark has to read on the kit.
	var s := _season(20)
	var light_on_light := s.workshop.rename(s.club, "Bonk Works", "BNK",
		IconBank.MARK_COLORS[0], IconBank.MARK_COLORS[1], 4)
	## A mark from the starter set, because `rename` also checks ownership now
	## and this check is about contrast, not about the bank.
	var good := s.workshop.rename(s.club, "Bonk Works", "bnk",
		IconBank.KIT_COLORS[2], IconBank.MARK_COLORS[0], IconBank.starter()[2])
	var no_name := s.workshop.rename(s.club, "  ", "BNK",
		IconBank.KIT_COLORS[2], IconBank.MARK_COLORS[0], 4)
	var bad_short := s.workshop.rename(s.club, "Bonk Works", "BONKER",
		IconBank.KIT_COLORS[2], IconBank.MARK_COLORS[0], 4)
	_ok(light_on_light != "" and good == "" and no_name != "" and bad_short != ""
			and s.club.short_name == "BNK" and s.club.display_name == "Bonk Works"
			and s.club.line_legal() == "",
		"the contrast rule holds",
		"a light mark on a light kit is refused; a renamed club still passes its own check")


func _test_the_workshop_saves() -> void:
	var s := _season(80)
	s.workshop.create(s.office, s.club, _man(40, 40, 40, 40, 40, "Hollis Vane"), _worst(s.club))
	s.workshop.create(s.office, s.club, _man(41, 40, 40, 40, 40, "Ord Tarrow"), _worst(s.club))
	s.workshop.buy_icon(s.office, 12)
	s.workshop.rename(s.club, "Bonk Works", "BNK",
		IconBank.KIT_COLORS[3], IconBank.MARK_COLORS[1], 12)
	SaveGame.save(s, 2)
	var back := SaveGame.load_slot(2)
	SaveGame.delete(2)
	var names: Array = []
	for f in back.club.roster:
		names.append(f.display_name)
	var owned_back: bool = back.workshop.owns(12) and back.workshop.owns(7) and back.workshop.owned.size() == IconBank.starter().size() + 2
	_ok(owned_back and back != null and back.workshop.made == 2 and back.workshop.cost() == 7
			and names.has("Hollis Vane") and names.has("Ord Tarrow")
			and back.club.display_name == "Bonk Works"
			and back.club.icon == 12,
		"the workshop survives a save",
		"two made men, the ledger at 2 of 4, a bought mark and the new kit all came back")


## The man a club would actually cut: the weakest name in the reserve.
func _worst(club: MeleeClub) -> FighterCard:
	var worst: FighterCard = null
	for f in club.reserves():
		if worst == null or f.rating() < worst.rating():
			worst = f
	return worst


## A CLUB WITH ITS FOUR RESERVES: the starting club is eight men now (1 Oct
## 2026), and these tests are about a made man taking a reserve's place.
func _season(credits: int) -> Season:
	var s := Season.new(MeleeRosters.starting_club_with_reserve(), 91)
	s.office.credits = credits
	s.office.tier = 0
	return s


## THE DIALS ARE CUSTOM'S (1 Oct novice report, Pete approved): every grade but
## Custom is its name and one sentence — no read-out rows, no − and + — and the
## sentence is one sentence and fits its window in every language. Custom keeps
## every row and every dial.
func _test_the_dials_are_customs() -> void:
	var bad: Array[String] = []
	var s := _season(40)
	Session.season = s
	Session.create_tab = 2
	var n: Node = load("res://scenes/Create.tscn").instantiate()
	root.add_child(n)
	await process_frame
	for g in Grade.ORDER:
		s.set_grade(int(g))
		n.call("_rebuild")
		UiKit.ledger_start()
		n.queue_redraw()
		await process_frame
		await process_frame
		var drawn := UiKit.ledger_stop()
		## THE FIGHT'S DIALS stay Custom's; WHAT IT CHANGES (strength, calls,
		## dues...) shows on every grade since the 2 Oct 2026 playtest ("the
		## Right to show the effects").
		var rows := 0
		var effects := 0
		for e in drawn:
			var t := String(e.get("text", ""))
			if t == UiKit.t("Free swing on arrival") or t == UiKit.t("Missed bullrush, he falls") \
					or t == UiKit.t("Grabbed or tripped passing"):
				rows += 1
			if t == UiKit.t("Opposition strength"):
				effects += 1
		var dials := 0
		for c in n.get_children():
			for b in c.get_children():
				if b is Button and ((b as Button).text == "-" or (b as Button).text == "+"):
					dials += 1
		var nm := Grade.name_of(int(g))
		if int(g) == Grade.G.CUSTOM:
			if rows < 3 or effects < 1 or dials < 2 * n.DIAL_ROWS.size():
				bad.append("%s shows %d rows and %d dials" % [nm, rows, dials])
		else:
			if rows > 0 or dials > 0 or effects < 1:
				bad.append("%s shows %d fight rows, %d dials, %d effects" % [nm, rows, dials, effects])
			var en := String(Grade.BLURB[int(g)])
			if en.count(". ") > 0 or not en.ends_with("."):
				bad.append("%s is more than one sentence" % nm)
	n.queue_free()
	await process_frame
	Session.create_tab = -1
	## The sentence fits its window (nine lines at 15 px, the middle column) in every language.
	var was := TranslationServer.get_locale()
	var iw: float = float((load("res://scripts/game/create_scene.gd") as GDScript).get_script_constant_map()["GRADE_MID"].y) - 32.0
	for loc in ["en", "es", "fr", "de", "it", "pt_BR", "pl", "ru", "ja"]:
		TranslationServer.set_locale(loc)
		for g in Grade.ORDER:
			var lines := UiKit.wrap(UiKit.body(), Grade.blurb_of(int(g)), iw, 15)
			if lines.size() > 9:
				bad.append("%s %s runs to %d lines" % [loc, Grade.name_of(int(g)), lines.size()])
	TranslationServer.set_locale(was)
	_ok(bad.is_empty(), "the dials are Custom's: every grade shows what it changes, in one sentence",
		"%d grades read off the screen" % Grade.ORDER.size() if bad.is_empty() else "; ".join(bad))
