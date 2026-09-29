extends SceneTree
## THE EDGES THE FRESH-EYES AUDIT FOUND (28 Sep 2026), each held here.
##
##   godot --headless --path . --script res://tests/test_edges.gd
##
##   cup nights are big occasions — asked of the season, not of a stale static
##   a full book with nobody fit still puts five out, and says who went
##   the club you leave keeps the men you built, across a reload
##   a save that will not decode is broken (and opens from .bak), not half-built
##   the decoder's required fields and its source agree
##   a wallet killed between its two renames is not lost

var failures: Array[String] = []
var checks: int = 0


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the edges ===\n")
	SaveGame.set_namespace("edges_test")
	_test_cup_nights_are_big()
	_test_full_book_still_fields_five()
	_test_left_club_keeps_its_men()
	_test_undecodable_save_is_broken()
	_test_required_fields_match_the_decoder()
	_test_wallet_survives_the_rename_window()
	_test_save_keeps_everything()
	await _test_market_shows_over_cap()
	await _test_a_failed_save_is_said()
	_test_cup_finish_is_data()
	_test_dilemma_follows_its_man()
	_test_broken_cup_is_refused()
	_test_ticker_speaks_the_language()
	for slot in 3:
		SaveGame.delete(slot)
	print("")
	if failures.is_empty():
		print("THE EDGES HOLD (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


## The static the screen sets is deliberately left WRONG both ways round, which
## is what it was in play: NORMAL for the cup tie, a cup mood for the league bout.
func _test_cup_nights_are_big() -> void:
	var cup_ok := -1
	var league_ok := -1
	for b in [4242, 777, 9001]:
		var s := Season.new(MeleeRosters.starting_club(), int(b))
		Session.season = s
		for y in 3:
			var guard := 0
			while not s.season_complete() and guard < 60:
				guard += 1
				match s.blocked_by():
					"bid": s.decline_bid(); continue
					"dilemma": s.answer_dilemma(0); continue
					"promotion": s.answer_promotion(true); continue
					"cup":
						if cup_ok == -1:
							Session.bout_mood = UiKit.Mood.NORMAL
							var sim := s.begin_cup_bout()
							cup_ok = 1 if sim != null and sim.big_occasion else 0
						s.sim_cup_tie()
						continue
				if league_ok == -1 and cup_ok != -1:
					Session.bout_mood = UiKit.Mood.FINAL
					var lsim := s.begin_bout()
					if lsim != null:
						league_ok = 0 if lsim.big_occasion else 1
				s.skip_event()
			if cup_ok != -1 and league_ok != -1:
				break
			s.roll_over()
		if cup_ok != -1 and league_ok != -1:
			break
	Session.bout_mood = UiKit.Mood.NORMAL
	_ok(cup_ok == 1 and league_ok == 1,
		"a cup tie is a big occasion and the league bout after it is not",
		"cup tie big: %s, next league bout plain: %s (the screen's static left stale both times)"
			% [cup_ok == 1, league_ok == 1])


## Thirteen on the books, every one of them hurt: the old code could not sign
## past thirteen and forfeited, 0-2, every week.
func _test_full_book_still_fields_five() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 5150)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var g := 0
	while s.club.roster.size() < MeleeClub.SQUAD_MAX and g < 40:
		g += 1
		s.club.sign(ClubFactory.walk_on(rng, 0, 0))
	for f in s.club.roster:
		f.injury = 3
	var full := s.club.roster.size()
	var notes := s.ensure_a_line()
	var five := s.club.starting_five().size()
	var told := false
	for n in notes:
		if String(n).contains("let go"):
			told = true
	_ok(full == MeleeClub.SQUAD_MAX and five >= MeleeClub.LINE_SIZE and told
			and s.club.roster.size() <= MeleeClub.SQUAD_MAX,
		"a full book with nobody fit still puts five out, and says who was let go",
		"%d on the books, all hurt → %d fit in the line, %d on the books after; notes: %s"
			% [full, five, s.club.roster.size(), str(notes)])


func _test_left_club_keeps_its_men() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 777)
	s.world.season = 8
	s.coach.reputation = Coach.REP_MAX
	var old_id := s.world.player_club
	## Make the men recognisably ours: every one of them a point better.
	for f in s.club.roster:
		f.strength = mini(99, f.strength + 7)
	var before: Array[String] = []
	for f in s.club.roster:
		before.append("%s:%d" % [f.display_name, f.overall()])
	var targets := Jobs.offers(s.coach, s.world)
	if targets.is_empty():
		_ok(false, "the club you leave keeps the men you built, across a reload", "no offers to take")
		return
	var err := s.take_job(int(targets[0]))
	SaveGame.save(s, 1)
	var back := SaveGame.load_slot(1)
	var after: Array[String] = []
	if back != null:
		for f in back.club_for(old_id).roster:
			after.append("%s:%d" % [f.display_name, f.overall()])
	_ok(err == "" and back != null and after == before,
		"the club you leave keeps the men you built, across a reload",
		"left club's roster after save and load %s the one you built (%d men)"
			% ["matches" if after == before else "DIFFERS from", before.size()])


## A file with a good hash and a missing field: the old loader built a world
## with a null in the roster and the title screen called the slot healthy.
func _test_undecodable_save_is_broken() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	SaveGame.save(s, 2)
	s.skip_event()
	SaveGame.save(s, 2)            ## now there is a .bak one event behind
	var d := SaveGame.to_dict(s)
	(d["club"]["roster"][0] as Dictionary).erase("morale")
	## Write the damaged dictionary as the slot through the real writer's format,
	## by saving a season and swapping the body — simplest honest way is to use
	## the decoder check directly on the dictionary and the loader on the file.
	var dec_ok := SaveGame.decodable(SaveGame.to_dict(s))
	var dec_bad := SaveGame.decodable(d)
	## A damaged main file with a good backup opens from the backup.
	var p := SaveGame.path_for(2)
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_var(d, false)            ## no header: unreadable as a slot file
	f.close()
	var back := SaveGame.load_slot(2)
	var from_bak := back != null and back.world.event == 0
	_ok(dec_ok and not dec_bad and from_bak,
		"a save that will not decode is refused, and the slot opens from its backup",
		"whole save decodable: %s; missing a fighter's morale: %s; damaged slot opened from .bak: %s"
			% [dec_ok, dec_bad, from_bak])


## The lists in SaveGame are hand-kept; the decoders are the truth. Read the
## decoders and require every `d["x"]` they index to be listed.
func _test_required_fields_match_the_decoder() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/game/save_game.gd")
	var bad: Array[String] = []
	## The cup's decoder lives in cup.gd and keeps its own list.
	var csrc := FileAccess.get_file_as_string("res://scripts/league/cup.gd")
	var ci := csrc.find("static func from_dict(")
	var cj := csrc.find("\nstatic func ", ci + 10)
	if cj < 0:
		cj = csrc.find("\nfunc ", ci + 10)
	var cbody := csrc.substr(ci, (cj - ci) if cj > 0 else -1)
	for m in RegEx.create_from_string('\\bd\\["(\\w+)"\\]').search_all(cbody):
		var k := m.get_string(1)
		## `season` is read only after a `.get` says it is there.
		if not Cup.NEED.has(k) and k != "season" and k != "rng_state":
			bad.append("Cup.from_dict indexes d[\"%s\"] without it being required" % k)
	var pairs := [["from_dict", SaveGame.NEED_SEASON, ["splinters"]],
		["club_from_dict", SaveGame.NEED_CLUB, []],
		["fighter_from_dict", SaveGame.NEED_FIGHTER, []]]
	var rx := RegEx.create_from_string('\\bd\\["(\\w+)"\\]')
	for pr in pairs:
		var i := src.find("static func %s(" % pr[0])
		var j := src.find("\nstatic func ", i + 10)
		var body := src.substr(i, j - i)
		for m in rx.search_all(body):
			var k := m.get_string(1)
			if not (pr[1] as Array).has(k) and not (pr[2] as Array).has(k):
				bad.append("%s indexes d[\"%s\"] without it being required" % [pr[0], k])
	_ok(bad.is_empty(), "the save's required fields are exactly what its decoders index",
		"4 decoders read" if bad.is_empty() else "; ".join(bad))


## Kill the app after the old wallet has stepped aside and before the new one
## is renamed in: the old code had deleted the old one, so nothing was left.
func _test_wallet_survives_the_rename_window() -> void:
	var path := Store.wallet_path()
	for x in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(x):
			DirAccess.remove_absolute(x)
	Store.owed = 7
	Store.save_wallet()
	Store.owed = 12
	Store.save_wallet()                       ## live 12, .bak 7
	## The window: live moved to .bak, .tmp written, rename never happened.
	DirAccess.rename_absolute(path, path + ".tmp")
	Store.load_wallet()
	var from_tmp := Store.owed
	DirAccess.remove_absolute(path + ".tmp")
	Store.load_wallet()
	var from_bak := Store.owed
	for x in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(x):
			DirAccess.remove_absolute(x)
	Store.owed = 0
	_ok(from_tmp == 12 and from_bak == 7,
		"a wallet killed between its two renames is not lost",
		"unrenamed .tmp read back %d (want 12); with only the backup left, %d (want 7)"
			% [from_tmp, from_bak])



## THE WHOLE SAVE, NOT A FINGERPRINT OF IT (29 Sep 2026). test_save compares a
## hand-picked set of fields, and a mutation that dropped the league records on
## load sailed through it. This writes a lived-in season — fought bouts, so the
## records and the book have something in them — and asks that everything the
## writer writes comes back, bar the timestamp.
func _test_save_keeps_everything() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	var fought := 0
	var guard := 0
	while fought < 6 and guard < 60:
		guard += 1
		match s.blocked_by():
			"bid": s.decline_bid(); continue
			"dilemma": s.answer_dilemma(0); continue
			"cup": s.sim_cup_tie(); continue
			"promotion": s.answer_promotion(false); continue
		if s.season_complete():
			s.roll_over()
			continue
		var sim := s.begin_bout()
		if sim == null:
			s.skip_event()
			continue
		sim.run_to_end()
		s.post_bout(sim)
		fought += 1
	var before := SaveGame.to_dict(s)
	SaveGame.save(s, 0)
	var back := SaveGame.load_slot(0)
	var after := SaveGame.to_dict(back) if back != null else {}
	before.erase("saved")
	after.erase("saved")
	var differ: Array[String] = []
	for k in before:
		if not after.has(k) or str(before[k]) != str(after[k]):
			differ.append(String(k))
	_ok(back != null and differ.is_empty(),
		"everything a save writes comes back, not only the fields a test picked",
		"%d fields compared after %d fought bouts%s" % [before.size(), fought,
			"" if differ.is_empty() else "; differ: " + ", ".join(differ)])


## THE MARKET SAYS WHEN THE CLUB CANNOT CARRY A MAN, in red, on his card. A
## mutation that treated every wage as affordable got through the suite.
func _test_market_shows_over_cap() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	for f in s.club.roster:
		f.wage_agreed = 400
	Session.season = s
	var n: Node = (load("res://scenes/Market.tscn") as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	UiKit.ledger_start()
	(n as CanvasItem).queue_redraw()
	await process_frame
	await process_frame
	var ink := UiKit.ledger_stop()
	var red := 0
	var cards := 0
	var needle := UiKit.t("age %d · over cap").split("%d")[1]
	for row in ink:
		if String(row["text"]).ends_with(needle):
			cards += 1
			if Color(row.get("col", Color.WHITE)).is_equal_approx(UiKit.DOWN):
				red += 1
	n.queue_free()
	await process_frame
	_ok(cards > 0 and red == cards,
		"a man the club cannot carry says so on his market card, in red",
		"%d cards over the cap, %d of them in red" % [cards, red])



## A SAVE THAT FAILS IS SAID, ONCE. Saving into a folder that does not exist
## fails the way a full phone does; the season screen has to say so, and not
## again on the next rebuild while nothing has changed.
func _test_a_failed_save_is_said() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	Session.slot = 0
	SaveGame.set_namespace("no_such_dir/edges")
	var ok := Session.autosave()
	var n: Node = (load("res://scenes/Season.tscn") as PackedScene).instantiate()
	root.add_child(n)
	await process_frame
	n.call("_rebuild")
	var first := String(n.get("flash"))
	n.set("flash", "")
	n.call("_rebuild")
	var second := String(n.get("flash"))
	n.queue_free()
	await process_frame
	SaveGame.set_namespace("edges_test")
	var healed := Session.autosave()
	Session.slot = -1
	var msg := UiKit.t("Could not save — your phone may be out of space. The last save is safe.")
	_ok(not ok and first == msg and second == "" and healed and not Session.save_failed,
		"a save that fails is said on the season screen, once",
		"save failed: %s; said: %s; said again: %s; a good save clears it: %s"
			% [not ok, first == msg, second != "", healed and not Session.save_failed])


## A CUP FINISH IS STORED ENGLISH AND DRAWN IN THE PLAYER'S LANGUAGE (29 Sep
## 2026). It used to be translated on the night and saved, with the English
## round name glued in — so a Spanish save read "fuera en la quarter-finals"
## forever, and switching language never fixed it.
func _test_cup_finish_is_data() -> void:
	var cup := Cup.new("Test", [10, 11, 12, 13, 14, 15, 16, 17], 7, 10)
	var day := cup.current_round()
	for m in day:
		var p := int(m["a"]) == 10 or int(m["b"]) == 10
		## The player loses his quarter-final; everybody else, side a wins.
		if p:
			var him_a := int(m["a"]) == 10
			cup.record(m, 0 if him_a else 2, 2 if him_a else 0, 0, 3)
		else:
			cup.record(m, 2, 0, 3, 0)
	var stored := cup.player_finish
	var cabinet := cup.finish_label()
	TranslationServer.set_locale("es")
	var es_low := Cup.finish_words(stored)
	var es_cap := Cup.finish_words(cabinet)
	var old := Cup.finish_words("fuera en la quarter-finals")
	TranslationServer.set_locale("en")
	var en_low := Cup.finish_words(stored)
	_ok(stored == "out in the quarter-finals" and cabinet == "Out in the quarter-finals"
			and en_low == stored and es_low != stored and es_cap.substr(0, 1) == es_low.substr(0, 1).to_upper()
			and old == "fuera en la quarter-finals",
		"a cup finish is saved in English and drawn in the language on screen",
		"stored '%s', cabinet '%s' → es '%s' / '%s'; an old translated save passes through as '%s'"
			% [stored, cabinet, es_low, es_cap, old])


## A DILEMMA IS ABOUT A MAN, NOT A ROSTER SLOT (29 Sep 2026). The card kept an
## index; releasing anybody listed before him slid the next man into it, and the
## answer landed on him. Letting the man himself go leaves the card about nobody.
func _test_dilemma_follows_its_man() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var r: Array = s.club.roster
	var early: FighterCard = r[1]
	var him: FighterCard = r[r.size() - 1]
	early.active = false
	him.active = false
	s.prospect = early
	s.dilemma = {"id": String(Dilemma.CARDS[0]["id"]), "man": r.find(him),
		"name": him.display_name, "rival": "them"}
	var err := s.release(early)
	var still := s.dilemma_man()
	var prospect_gone := s.prospect == null
	var err2 := s.release(him)
	var gone := s.dilemma_man()
	## A card saved before the name was kept still trusts its index.
	s.dilemma = {"id": String(Dilemma.CARDS[0]["id"]), "man": 0, "rival": "them"}
	var legacy := s.dilemma_man()
	_ok(err == "" and err2 == "" and still == him and gone == null and legacy == s.club.roster[0]
			and prospect_gone,
		"a dilemma stays with its man when the roster moves, and a released prospect is dropped",
		"after releasing a man above him the card names %s (want %s); after releasing him: %s; old card by index: %s; prospect cleared: %s"
			% [still.display_name if still != null else "nobody", him.display_name,
				"nobody" if gone == null else gone.display_name, legacy != null, prospect_gone])


## A cup missing a field the decoder needs makes the save undecodable, instead
## of loading a null into the world's cup list. A cup missing only a field that
## came later (third_place) still opens.
func _test_broken_cup_is_refused() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var guard := 0
	while s.world.cups.is_empty() and guard < 40:
		guard += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"dilemma": s.answer_dilemma(0)
			"cup": s.sim_cup_tie()
			"promotion": s.answer_promotion(false)
			_: s.skip_event()
	var d := SaveGame.to_dict(s)
	var has_cup := not (d["cups"] as Array).is_empty()
	var old := d.duplicate(true)
	if has_cup:
		(old["cups"][0] as Dictionary).erase("third_place")
		(old["cups"][0] as Dictionary).erase("rng_state")
	var bad := d.duplicate(true)
	if has_cup:
		(bad["cups"][0] as Dictionary).erase("rounds")
	var old_cup: Cup = Cup.from_dict(old["cups"][0]) if has_cup else null
	_ok(has_cup and SaveGame.decodable(d) and SaveGame.decodable(old) and not SaveGame.decodable(bad)
			and old_cup != null,
		"a save whose cup lacks a needed field is refused; one lacking a later field still opens",
		"cup in the save: %s; whole: %s; without third_place/rng_state: %s; without rounds: %s"
			% [has_cup, SaveGame.decodable(d), SaveGame.decodable(old), SaveGame.decodable(bad)])


## THE TICKER HAD NO TRANSLATION AT ALL (29 Sep 2026): standings, results and
## every remark were English in every language. In Spanish, none of its English
## sentence frames may survive, and every remark must come from the table.
func _test_ticker_speaks_the_language() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	for i in 3:
		s.skip_event()
	TranslationServer.set_locale("es")
	var line := Ticker.line_for(s)
	var quips_es: Array[String] = []
	for q in Ticker.QUIPS:
		quips_es.append(UiKit.t(q))
	TranslationServer.set_locale("en")
	var english := []
	for frame in [" lead the ", " are level at the top", " prop up the table", " beat ", " drew with ", " lost to ", " point"]:
		if line.contains(frame):
			english.append(frame.strip_edges())
	var untranslated := 0
	for i in Ticker.QUIPS.size():
		if quips_es[i] == Ticker.QUIPS[i]:
			untranslated += 1
	_ok(english.is_empty() and untranslated == 0 and line != "",
		"the ticker speaks the language on screen",
		"es line %d chars; English frames found: %s; remarks left in English: %d of %d"
			% [line.length(), str(english), untranslated, Ticker.QUIPS.size()])
