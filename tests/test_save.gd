extends SceneTree
## Saving, and the one thing a save test has to prove.
##
##   godot --headless --path . --script res://tests/test_save.gd
##
## It is easy to write a save that round-trips the numbers you thought to check
## and still ruins the game. The check that matters is not "the table looks the
## same" — it is that the world CONTINUES the same: play on from a reload and
## every remaining fixture of the season must resolve exactly as it would have.
## That catches the RNG stream, which is the field everyone forgets and the one
## whose absence is invisible until a player reloads and notices the results
## moved under him.

const SLOT := 2

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
	SaveGame.set_namespace("save")
	print("\n=== 8-Bit Buhurt — saving ===\n")
	SaveGame.delete(SLOT)
	_test_round_trip()
	_test_the_world_continues_the_same()
	_test_a_live_cup_survives()
	_test_the_slot_reads_without_loading()
	_test_a_broken_save_is_refused()
	_test_a_deep_career_survives_a_reload()
	_test_an_old_save_is_carried_forward()
	_test_every_golden_file_opens()
	SaveGame.delete(SLOT)

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE SAVE HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


## AN OLD FILE OPENS, AND A FILE TOO OLD DOES NOT.
##
## The version check was strict equality until 15 Sep 2026: a v11 file was
## refused as cleanly as a corrupt one. Correct while the only v11 files in the
## world were on this machine, and unacceptable the moment anybody else has a
## career — every schema change would wipe it, and this project moved the
## version four times in a month.
##
## The check is the shape of the promise rather than the contents of one step:
## a file at the floor opens, a file below it does not, a file from the future
## does not, and today's file is handed through untouched.
func _test_an_old_save_is_carried_forward() -> void:
	var s := _mid_season(11, 2)
	var today := SaveGame.to_dict(s)
	## TODAY'S FILE IS NOT TOUCHED. A migration that rewrites a current save is
	## a migration that can corrupt one.
	var same = SaveGame._migrate(today.duplicate(true))
	_ok(same != null and int(same["version"]) == SaveGame.VERSION
			and not same.has("migrated_from"),
		"a current save passes through the migration untouched",
		"v%d in, v%d out, no migration mark" % [SaveGame.VERSION,
			int(same["version"]) if same != null else -1])

	## A FILE AT THE FLOOR IS CARRIED FORWARD and comes back as a world.
	var old := today.duplicate(true)
	old["version"] = SaveGame.VERSION_MIN
	var lifted = SaveGame._migrate(old)
	var world_back: Season = SaveGame.from_dict(lifted) if lifted != null else null
	_ok(lifted != null and int(lifted["version"]) == SaveGame.VERSION
			and world_back != null and world_back.club.roster.size() == s.club.roster.size(),
		"a save at the oldest supported version is carried forward",
		"v%d -> v%d, %d men back" % [SaveGame.VERSION_MIN, SaveGame.VERSION,
			world_back.club.roster.size() if world_back != null else -1])

	## AND IT IS MARKED, which is what tells the decode side it owes the roster
	## whatever the old build never paid out.
	_ok(lifted != null and int(lifted.get("migrated_from", 99)) == SaveGame.VERSION_MIN,
		"and the file says where it came from",
		"migrated_from = %d" % int(lifted.get("migrated_from", -1)) if lifted != null else "none")

	## TOO OLD IS REFUSED, and so is too new. A save that predates the floor
	## cannot be walked forward by any step this file has, and a save from a
	## later build carries fields this one would silently drop.
	var ancient := today.duplicate(true)
	ancient["version"] = SaveGame.VERSION_MIN - 1
	var future := today.duplicate(true)
	future["version"] = SaveGame.VERSION + 1
	_ok(SaveGame._migrate(ancient) == null and SaveGame._migrate(future) == null,
		"a file older than the floor, or newer than this build, is refused",
		"v%d and v%d both come back null" % [SaveGame.VERSION_MIN - 1, SaveGame.VERSION + 1])

	## THROUGH THE REAL DOOR, not just the helper: an old file written to a slot
	## has to open through `load_slot`, which is the only path the game uses.
	var f := FileAccess.open(SaveGame.path_for(SLOT), FileAccess.WRITE)
	f.store_buffer(SaveGame.MAGIC.to_ascii_buffer())
	f.store_var(old, false)
	f.close()
	var loaded := SaveGame.load_slot(SLOT)
	var peeked := SaveGame.peek(SLOT)
	SaveGame.delete(SLOT)
	_ok(loaded != null and not peeked.is_empty(),
		"and the game's own door opens it",
		"load_slot returned a season and peek read its name: %s"
			% String(peeked.get("club", "—")))
	notes.append("the migration: floor v%d, current v%d, %d step(s) between"
		% [SaveGame.VERSION_MIN, SaveGame.VERSION, SaveGame.VERSION - SaveGame.VERSION_MIN])

func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


func _mid_season(seed_v: int, events: int) -> Season:
	var s := Season.new(MeleeRosters.player_club(), seed_v)
	for i in events:
		if not s.season_complete():
			s.skip_event()
	return s


## The whole world as one string: every division, every row, every rating.
func _fingerprint(s: Season) -> String:
	var out := "s%d e%d t%d " % [s.world.season, s.world.event, s.world.player_tier()]
	for t in League.TIERS.size():
		for row in s.world.table(t):
			out += "%d:%d:%d:%d:%d|" % [t, int(row["club"]), int(row["points"]),
				League.margin_diff(row), League.round_diff(row)]
	for c in s.world.clubs:
		out += "%d=%d," % [int(c["id"]), int(c["power"])]
	out += " club:%d" % s.club.power()
	for f in s.club.roster:
		## MORALE IS IN THE FINGERPRINT, and it had to be added the day morale
		## went per man: it was dropped from the save for an afternoon and every
		## check in this file still passed, because none of them was looking at
		## it. A round-trip check only covers the fields it reads.
		out += "%s/%d/%d/%.2f/%s/%.3f," % [f.display_name, int(f.pos), f.overall(),
			f.armor, "A" if f.active else "R", f.morale]
	## And the staff, for the same reason — a captain's grade decides how many
	## roles he teaches, so a grade lost in the save is a line coached differently.
	for c in s.office.captains:
		out += "%s:%d:%s:%d|" % [String(c["name"]), int(c["grade"]),
			str(ClubOffice.specialties_of(c)), int(c.get("regime", 0))]
	out += _career_print(s)
	return out


## ------------------------------------------------------- what a career accrues
## THE NOTE ABOVE PROVED ITSELF AGAIN: *"a round-trip check only covers the
## fields it reads."*
##
## Everything above is the state a NEW club has — a table, some ratings, a
## roster, a captain. None of it is the state a CAREER has, and a career is what
## a player saves. Five seasons in, a club is carrying bought facilities, an
## arena, extra travel slots, a raised wage cap, federation certificates, a
## market it has already shopped in, men on three-year deals at agreed wages,
## levels and XP part-way to the next one, traits, grudges, a trophy cabinet and
## a record book. Not one of those fields was in the fingerprint, so every check
## in this file would have gone on passing with the whole lot dropped from the
## save.
func _career_print(s: Season) -> String:
	var o := s.office
	var out := " office:%d/%d/%d/%d/%.3f/%.3f/%d/%d" % [o.credits, o.travel_slots,
		o.cap_level, o.arena.level, o.fans, o.morale, o.market_refreshes,
		o.staff_refreshes]
	## The week's limits, the purse log, bought credits and the promotion answer —
	## all four were missing from the save until 27 Sep 2026.
	var wk: Array = o.built_this_week.keys()
	wk.sort()
	out += " week:%s purse:%d bought:%d stay:%s/%s" % [",".join(wk), o.purse_log.size(),
		o.bought, str(s.world.stay_down), str(s.promotion_answered)]
	for f in ClubOffice.Facility.values():
		out += ":f%d=%d" % [int(f), o.level(int(f))]
	for r in Federation.rules():
		out += ":r%d=%d" % [r, o.rule_level(r)]
	## THE DEALS. A man's contract is the thing a manager spends a whole summer
	## on, and `years` and `wage_agreed` are two integers that would have gone
	## missing in complete silence.
	for f in s.club.roster:
		out += "|%s:%d:%d:%d:%d:%d:%d:%d" % [f.display_name, f.years,
			f.wage_agreed, f.level, f.xp, f.potential, int(f.trait_id),
			f.grudge_club]
	## THE MARKET HE HAS ALREADY SHOPPED IN. The pool is regenerated from the
	## seed and never stored, so `market_taken` is the ONLY record that a man was
	## bought — lose it and every signing reappears on the list, at full price,
	## on the next load.
	out += "|taken:" + ",".join(s.market_taken)
	## THE STREAM ITSELF. `_test_the_world_continues_the_same` proves the stream
	## comes back by CONSEQUENCE — play on and see whether the world agrees — but
	## a consequence test tells you that something diverged, not what. The state
	## is two integers; putting them in the print turns "diverged at character
	## 464" into "the stream was at a different position before a bout was
	## fought."
	out += "|rng:%d/%d" % [s.world.rng.seed, s.world.rng.state]
	out += "|cabinet:%d" % s.world.honors.size()
	for h in s.world.honors:
		out += ",%s@%d" % [String(h.get("id", "?")), int(h.get("season", -1))]
	return out


func _test_round_trip() -> void:
	## Sign a man and wreck some armor first, so the save is carrying a roster that
	## no generator would reproduce — otherwise this passes on a club the code
	## could have rebuilt from nothing.
	var s := _mid_season(1234, 2)
	s.club.roster[0].armor = 0.41
	## State a fresh club never has, so the round trip has to carry it.
	s.office.mark_this_week(ClubOffice.SLOT_BOOST)
	s.office.bought = 20
	s.office.take(3, "Test money", "test")
	s.world.stay_down = true
	s.promotion_answered = true
	var extra := FighterCard.new()
	extra.display_name = "Testman"
	extra.pos = Tuning.Pos.CENTER
	extra.active = false
	s.club.sign(extra)
	s.sync_power()

	var before := _fingerprint(s)
	var wrote := SaveGame.save(s, SLOT)
	var back := SaveGame.load_slot(SLOT)
	var after := _fingerprint(back) if back != null else "<null>"
	_ok(wrote and back != null and before == after, "a save round-trips",
		"world, table, ratings and a hand-edited roster of %d all come back identical"
			% s.club.roster.size())


func _test_the_world_continues_the_same() -> void:
	## THE CHECK THAT MATTERS. Save mid-season, play the rest twice — once from
	## the original and once from the reload — and the two must end the season
	## in exactly the same place. Without the RNG stream in the save this fails,
	## and nothing else in this file would have noticed.
	var s := _mid_season(777, 2)
	SaveGame.save(s, SLOT)
	var back := SaveGame.load_slot(SLOT)

	while not s.season_complete():
		s.skip_event()
	s.roll_over()
	while not back.season_complete():
		back.skip_event()
	back.roll_over()

	var a := _fingerprint(s)
	var b := _fingerprint(back)
	## And prove the check has teeth: a world reloaded WITHOUT the stream must
	## diverge, or this test would pass on a save that dropped it.
	var naive := SaveGame.load_slot(SLOT)
	naive.world.rng.seed = naive.world.rng.seed      ## resets state to 0
	while not naive.season_complete():
		naive.skip_event()
	naive.roll_over()
	var c := _fingerprint(naive)

	notes.append("continued from a reload: %s" % ("identical" if a == b else "DIVERGED"))
	notes.append("continued with the RNG stream dropped: %s"
		% ("diverged, as it must" if c != a else "IDENTICAL — the test has no teeth"))
	_ok(a == b and c != a, "the world continues the same",
		"playing on from a reload ends the season in the same place; dropping the RNG stream does not")


func _test_a_live_cup_survives() -> void:
	## An Invitational opens on matchday 2 and is not resolved until the summer,
	## so a save taken during a season is very often carrying a live bracket.
	var s := _mid_season(5150, 3)
	var live := s.world.cups.size()
	SaveGame.save(s, SLOT)
	var back := SaveGame.load_slot(SLOT)
	var same := back != null and back.world.cups.size() == live
	if same and live > 0:
		var x: Cup = s.world.cups[0]
		var y: Cup = back.world.cups[0]
		same = x.cup_name == y.cup_name and x.entrants == y.entrants \
			and x.rounds.size() == y.rounds.size() and x.rng.state == y.rng.state
	s.roll_over()
	back.roll_over()
	_ok(same and s.honors().size() == back.honors().size()
			and _fingerprint(s) == _fingerprint(back),
		"a live cup survives a save",
		"%d bracket(s) open at the save point, and both worlds award the same trophies" % live)


func _test_the_slot_reads_without_loading() -> void:
	## The title screen lists three slots. Rebuilding three worlds to draw three
	## lines of text would be the kind of thing nobody notices until the phone
	## takes a second to open the game.
	var s := _mid_season(31337, 3)
	SaveGame.save(s, SLOT)
	var p := SaveGame.peek(SLOT)
	_ok(not p.is_empty() and String(p["club"]) == s.club.display_name
			and int(p["season"]) == s.world.season and int(p["event"]) == s.world.event
			and String(p["saved"]) != "",
		"a slot reads without loading",
		"'%s · %s · season %d, event %d of %d'" % [p["club"], p["tier"],
			p["season"], p["event"], p["events"]])


func _test_a_broken_save_is_refused() -> void:
	## A truncated or foreign file must come back null, not half a world. A save
	## system that loads garbage is worse than one that loses the game, because
	## the player carries on playing something corrupt.
	## A clean slot first: an earlier check's good file would otherwise be sitting
	## in `.bak`, and the junk below would (correctly) open from it.
	SaveGame.delete(SLOT)
	var f := FileAccess.open(SaveGame.path_for(SLOT), FileAccess.WRITE)
	f.store_string("this is not a save")
	f.close()
	var junk := SaveGame.load_slot(SLOT)
	var junk_peek := SaveGame.peek(SLOT)
	## And a file that IS ours but is cut in half, which is what an app killed
	## mid-write actually leaves behind.
	var good := _mid_season(4, 1)
	SaveGame.save(good, SLOT)
	var whole := FileAccess.get_file_as_bytes(SaveGame.path_for(SLOT))
	var g := FileAccess.open(SaveGame.path_for(SLOT), FileAccess.WRITE)
	g.store_buffer(whole.slice(0, whole.size() / 2))
	g.close()
	var truncated := SaveGame.load_slot(SLOT)
	SaveGame.delete(SLOT)
	var gone := not SaveGame.has_save(SLOT) and SaveGame.load_slot(SLOT) == null
	## A broken slot says so — "broken", not empty — so the title screen offers to
	## set it aside instead of offering to write a new club over it.
	_ok(junk == null and bool(junk_peek.get("broken", false)) and truncated == null and gone,
		"a broken save is refused",
		"garbage and a half-written file both load as null rather than as half a world, the slot reads as broken rather than empty, and a deleted slot is gone")

	## THE BACKUP IS THE SECOND DOOR. Two good saves, then the newest torn in
	## half: the slot opens from the one before, one event behind.
	var a := _mid_season(4, 1)
	SaveGame.save(a, SLOT)
	a.skip_event()
	SaveGame.save(a, SLOT)
	var newest := FileAccess.get_file_as_bytes(SaveGame.path_for(SLOT))
	var h := FileAccess.open(SaveGame.path_for(SLOT), FileAccess.WRITE)
	h.store_buffer(newest.slice(0, newest.size() - 100))
	h.close()
	var back := SaveGame.load_slot(SLOT)
	_ok(back != null and back.world.event == a.world.event - 1,
		"a torn save opens from its backup",
		"newest torn; came back at event %d (the save before it)"
			% (back.world.event if back != null else -1))

	## SET ASIDE, NOT DELETED. Quarantine frees the slot and keeps the bytes.
	var moved := SaveGame.quarantine(SLOT)
	_ok(moved != "" and FileAccess.file_exists(moved) and not SaveGame.has_save(SLOT),
		"a slot that will not open is set aside, not deleted",
		"moved to %s" % moved.get_file())
	if moved != "":
		DirAccess.remove_absolute(moved)
		if FileAccess.file_exists(moved.replace(".dat.bad", ".dat.bak.bad")):
			DirAccess.remove_absolute(moved.replace(".dat.bad", ".dat.bak.bad"))


## ------------------------------------------------- five seasons, then a reload
## THE STATE A PLAYER ACTUALLY SAVES IN.
##
## `_test_the_world_continues_the_same` above saves two events into season one
## and continues with `skip_event()` — the AI path, where nobody throws a punch.
## That is the right check for the schedule and the RNG stream, and it is not
## the state anybody's save file is in. A real save is five seasons deep: bought
## facilities, an arena, extra travel slots, men on deals at agreed wages, levels
## part-way to the next one, traits earned in fights, a trophy or two, and a
## market that has already been shopped in.
##
## And every bout in it was FOUGHT. A fought bout runs the melee's own stream,
## writes XP, morale, knocks, traits and grudges back through `post_bout`, and
## draws from `_roster_rng()` on the way — four streams that all have to come
## back at the same position, not one.
##
## So: play five seasons for real, save, then play three more twice — once from
## the original and once from the reload — and require the two to end in exactly
## the same place, down to every field `_career_print` reads.
const DEEP_SEASONS := 5
const AFTER_SEASONS := 3


## One season, fought rather than skipped, with the ordinary manager moves a
## player makes without thinking. Deliberately the same shape as `tools/soak.gd`
## so the two walks exercise one road.
func _play_a_season(s: Season) -> void:
	## A STIPEND, because this is a SAVE test and not a balance one. A club left
	## on its own income finishes every season on two or three credits and
	## `sign_from_market` refuses every offer it is shown — so the market, the
	## fee, `market_taken` and the cut-to-make-room road all stay out of the save
	## and the check quietly covers less than it claims. The soak is where the
	## real economy gets walked; here the money is a fixture, not a finding.
	s.office.credits += 30
	s.office.new_week()
	if s.office.travel_slots < ClubOffice.TRAVEL_MAX:
		s.office.buy_travel_slot()
	s.office.new_week()
	s.office.upgrade(ClubOffice.Facility.TRAINING)
	## THE BOOKS ARE FULL AT THIRTEEN and a starting club arrives with thirteen,
	## so a policy that only signs never signs — which is how the first run of
	## this check reported "0 bought" with sixty credits in the bank. Cut the
	## worst man in the reserve first, which is what the refusal tells you to do.
	for f in s.market():
		if s.sign_from_market(f) == "":
			break
		var worst: FighterCard = null
		for r in s.club.reserves():
			if worst == null or r.overall() < worst.overall():
				worst = r
		if worst != null and s.release(worst) == "" and s.sign_from_market(f) == "":
			break
	s.sync_power()
	var guard := 0
	while not s.season_complete() and guard < 40:
		guard += 1
		var sim := s.begin_bout()
		if sim == null:
			s.skip_event()
			continue
		Session.season = s
		Session.bout = sim
		sim.run_to_end()
		s.post_bout(sim)
		Session.clear_bout()
		var ties := 0
		while s.pending_cup() != null and ties < 8:
			ties += 1
			s.sim_cup_tie()
	s.roll_over()


func _test_a_deep_career_survives_a_reload() -> void:
	var bad: Array[String] = []
	var s := Season.new(MeleeRosters.starting_club(), 99177)
	## THE GUARDS BELOW ARE THE POINT. The first run of this check reported
	## "0 bought" and passed anyway, because the guard was an `or` across three
	## conditions and two of them held. `market_taken` went into the save empty,
	## so the one thing only it can prove — that a man you paid for does not
	## reappear on the list at full price after a load — was never exercised.
	## *A screenshot of the empty case is the mistake this project has now made
	## twice*, and a fingerprint of the empty case is the same mistake.
	for i in DEEP_SEASONS - 1:
		_play_a_season(s)

	## AND A BREAKAWAY, BUILT ON PURPOSE.
	##
	## A splinter is the ONE CPU roster the save stores — every other club is
	## rebuilt from its id and its power and needs no storage, so the breakaway is
	## the only place a saved roster can be wrong. It is also the thing that was
	## wrong: `splinter_rosters` held only the men who WALKED and not the walk-ons
	## signed to fill the line behind them, so a reloaded career rebuilt a club of
	## three that could not field five, and the bout against it came out 0-2 in a
	## game played straight through and 2-1 in the same game reloaded.
	##
	## The first version of this check found that by luck — the career it happened
	## to walk happened to fracture. Reintroducing the bug afterwards did NOT make
	## it fail, because a slightly different career did not. *A check that passes
	## because of what the world happened to do is a check waiting for the world
	## to do something else*, and that goes for the failing direction too.
	##
	## So the room is put on the floor before the last summer. `fractures()` wants
	## morale under the fuse and a finish in the bottom half; the fuse is the half
	## this test can set, and the bottom half a club this size arrives at on its
	## own.
	for f in s.club.roster:
		f.morale = 0.02
	s.office.sync_morale(s.club)
	_play_a_season(s)
	## AND IF THE CLUB DID TOO WELL TO FRACTURE, THE SPLIT IS CALLED DIRECTLY with
	## a bottom finish. `fractures()` also wants the bottom half, which a stronger
	## starting club (27 Sep pacing package) no longer arrives at on its own —
	## the world stopped doing the thing this check was relying on it to do.
	if s.splinter_rosters.is_empty():
		var t := s.world.player_tier()
		for f in s.club.roster:
			f.morale = 0.02
		s.office.sync_morale(s.club)
		s.last_split = s._maybe_split(League.club_count(t), t, t)
	if s.splinter_rosters.is_empty():
		bad.append("no club broke away, so the one saved CPU roster is not in this save")
	else:
		var sp: int = int(s.splinter_rosters.keys()[0])
		notes.append("a breakaway: %s, %d men on its books, rated %d"
			% [String(s.world.clubs[sp]["name"]), s.splinter_rosters[sp].size(),
				int(s.world.clubs[sp]["power"])])
		## AND IT HAS TO BE A CLUB. A breakaway that cannot field five is the bug
		## itself wearing a different face — and before the line-numbering fix
		## earlier today it was a crash rather than a walkover.
		if s.club_for(sp).starting_five().size() < MeleeClub.LINE_SIZE:
			bad.append("the breakaway cannot field five before the save was even taken")

	## ONE MORE SUMMER'S SHOPPING, AFTER THE LAST ROLL-OVER AND BEFORE THE SAVE.
	##
	## `market_taken` is CLEARED at the top of `roll_over()` — that clearing is
	## what opens a new summer's list — so a career saved at a season boundary has
	## an empty one BY DESIGN. The first run of this check read that as "0 bought"
	## and went looking for a bug in the save. The field is only ever non-empty
	## between a signing and the next summer, so that is where the save has to be
	## taken if it is going to carry it.
	s.office.credits += 30
	## THE BOOKS ARE FULL AT THIRTEEN and a career club is usually at thirteen, so
	## a policy that only signs never signs. Cut the worst man in the reserve
	## first, which is exactly what the refusal tells you to do — and which is
	## also the only road in this file to `Season.release()`.
	for f in s.market():
		if s.sign_from_market(f) == "":
			break
		var spare: FighterCard = null
		for r in s.club.reserves():
			if spare == null or r.overall() < spare.overall():
				spare = r
		if spare != null and s.release(spare) == "" and s.sign_from_market(f) == "":
			break
	s.sync_power()

	## THE SAVE HAS TO BE CARRYING SOMETHING. A career that bought nothing and
	## signed nobody would round-trip trivially and prove nothing — the same
	## mistake as photographing the empty case.
	## EVERY CONDITION, NOT ANY OF THEM. An `or` here is a guard that passes on
	## two thirds of an empty career, which is exactly what it did.
	if s.office.travel_slots <= ClubOffice.TRAVEL_START:
		bad.append("five seasons and the club never bought a travel slot")
	if s.office.level(ClubOffice.Facility.TRAINING) <= 0:
		bad.append("five seasons and the club never built a training ground")
	if s.market_taken.is_empty():
		bad.append("five seasons and the club never signed anybody — the market is not in the save")
	notes.append("five fought seasons: %d travel slots, training %d, %d bought, %d in the cabinet, %d CC"
		% [s.office.travel_slots, s.office.level(ClubOffice.Facility.TRAINING),
			s.market_taken.size(), s.world.honors.size(), s.office.credits])

	if not SaveGame.save(s, SLOT):
		_ok(false, "a deep career survives a reload", "the save would not write")
		return
	var back := SaveGame.load_slot(SLOT)
	if back == null:
		_ok(false, "a deep career survives a reload", "five seasons in, the save loaded as null")
		return
	## First, at the save point itself — so a divergence below is known to have
	## happened in the PLAY and not in the write.
	if _fingerprint(s) != _fingerprint(back):
		bad.append("the reload differed from the save before a single bout was fought")

	for i in AFTER_SEASONS:
		_play_a_season(s)
	for i in AFTER_SEASONS:
		_play_a_season(back)

	var a := _fingerprint(s)
	var b := _fingerprint(back)
	if a != b:
		## SAY WHERE. A fingerprint mismatch with no location is a failing test
		## nobody can act on, and this string is thousands of characters long.
		var at := 0
		while at < a.length() and at < b.length() and a[at] == b[at]:
			at += 1
		bad.append("diverged at character %d: '%s' vs '%s'" % [at,
			a.substr(maxi(0, at - 30), 60), b.substr(maxi(0, at - 30), 60)])

	notes.append("and three more fought seasons on each side: %s"
		% ("identical" if a == b else "DIVERGED"))
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "a deep career survives a reload",
		"%d seasons fought, saved, and %d more played out the same on both sides"
			% [DEEP_SEASONS, AFTER_SEASONS])


## EVERY GOLDEN FILE OPENS. `tests/fixtures/save_vN.dat` are real files written by
## real builds (tools/make_save_fixture.gd, run just before each VERSION bump).
## Each is copied into a slot and opened through the game's own door, then played
## on — so a migration is proven on a file an old build wrote, not on today's
## dictionary with its version number edited.
func _test_every_golden_file_opens() -> void:
	var dir := DirAccess.open("res://tests/fixtures")
	var found := 0
	if dir == null:
		_ok(false, "golden saves", "tests/fixtures is missing")
		return
	for fname in dir.get_files():
		if not fname.begins_with("save_v") or not fname.ends_with(".dat"):
			continue
		found += 1
		var bytes := FileAccess.get_file_as_bytes("res://tests/fixtures/" + fname)
		var f := FileAccess.open(SaveGame.path_for(SLOT), FileAccess.WRITE)
		f.store_buffer(bytes)
		f.close()
		var want := FileAccess.get_file_as_string(
			"res://tests/fixtures/" + fname.replace(".dat", ".txt")).strip_edges().split("|")
		var s := SaveGame.load_slot(SLOT)
		if s == null:
			_ok(false, "golden save opens", fname + " came back null")
			continue
		var same: bool = s.club.display_name == want[0] \
			and ("s%d" % s.world.season) == want[1] and ("e%d" % s.world.event) == want[2] \
			and ("%d men" % s.club.roster.size()) == want[4]
		var played := 0
		for i in 3:
			if s.season_complete():
				break
			s.skip_event()
			played += 1
		_ok(same and played > 0, "golden save opens and plays on",
			"%s -> %s, season %d event %d, %d men, %d events played after the load"
				% [fname, s.club.display_name, s.world.season, s.world.event,
					s.club.roster.size(), played])
	_ok(found > 0, "there is at least one golden save", "%d in tests/fixtures" % found)
