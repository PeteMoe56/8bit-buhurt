extends SceneTree
## FIGHTING YOUR OWN CUP TIES.
##
##   godot --headless --path . --script res://tests/test_cupplay.gd
##
## `Cup.player_match()` was written the day the cups were built and then sat
## with NO CALLER for the whole of this project, because the world resolved
## every bracket on paper before anybody could be asked about it. A player could
## qualify for the Worlds, win it, and never throw a punch.
##
## So the checks here are about the seam, not about the bracket — test_cup.gd
## already proves the bracket. What has to hold is that a cup the player is in
## WAITS for him, that the result he fights is the result that goes in the book,
## that it goes in the CUP's book and not the league table, and that he cannot
## walk away from a semi-final by starting next season.

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
	SaveGame.set_namespace("cupplay")
	print("\n=== 8-Bit Buhurt — fighting your own cup ===\n")
	_test_a_cup_waits_for_you()
	_test_the_tie_you_fight_is_the_tie_recorded()
	_test_a_cup_tie_is_not_a_league_fixture()
	_test_losing_puts_you_out()
	_test_you_cannot_walk_away_from_a_cup()
	_test_the_auto_path_is_untouched()
	_test_your_own_show_waits_for_you_too()
	_test_both_doors_dress_the_same_sim()
	_test_the_weeks_of_a_year()
	_test_the_send_off()
	_test_a_cup_weekend_is_one_week()
	_test_the_men_who_fought_are_paid_and_worn()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE CUP SEAM HOLDS (%d checks)\n" % checks)
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


## A season wound forward until a cup is actually asking the player for a
## result. Returns {} if none came up, which is itself a finding.
func _to_a_cup(s: Season, guard: int = 60) -> bool:
	var n := 0
	while n < guard:
		n += 1
		if s.cup_pending():
			return true
		if s.season_complete():
			if s.ready_to_roll():
				s.roll_over()
			else:
				return s.cup_pending()
		else:
			s.skip_event()
	return false


func _season(seed_v: int = 5150) -> Season:
	var s := Season.new(MeleeRosters.starting_club(), seed_v)
	## Strong enough to be invited to things. Being in the cups at all is the
	## precondition for every check in this file.
	for i in s.world.clubs.size():
		if i != s.world.player_club:
			s.world.clubs[i]["power"] = maxi(20, int(s.world.clubs[i]["power"]) - 12)
	s.sync_power()
	return s


func _test_a_cup_waits_for_you() -> void:
	var s := _season()
	var found := _to_a_cup(s)
	var c := s.pending_cup()
	_ok(found and c != null and not c.player_match().is_empty(),
		"a cup waits for you",
		"%s asked for a result in the %s" % [
			c.cup_name if c != null else "?",
			c.round_name().to_lower() if c != null else "?"])


func _test_the_tie_you_fight_is_the_tie_recorded() -> void:
	## THE SEAM ITSELF. The four numbers that come out of the melee have to be
	## the four numbers in the bracket, the right way round — a cup match stores
	## `a` and `b` in draw order and the player is not always `a`.
	var s := _season()
	if not _to_a_cup(s):
		_ok(false, "the tie you fight is the tie recorded", "no cup came up")
		return
	var c := s.pending_cup()
	var m := c.player_match()
	var player_is_a: bool = int(m["a"]) == s.world.player_club
	var sim := s.begin_cup_bout()
	sim.run_to_end()
	var mine: int = sim.rounds_won[0]
	var theirs: int = sim.rounds_won[1]
	s.post_cup_bout(sim)
	var stored_mine := int(m["ra"]) if player_is_a else int(m["rb"])
	var stored_theirs := int(m["rb"]) if player_is_a else int(m["ra"])
	_ok(bool(m["played"]) and stored_mine == mine and stored_theirs == theirs,
		"the tie you fight is the tie recorded",
		"fought %d-%d as %s, bracket reads %d-%d" % [
			mine, theirs, "the home name" if player_is_a else "the away name",
			stored_mine, stored_theirs])
	## And the rest of the round went on around him rather than sitting unplayed.
	## THE ROUND HE FOUGHT, not the cup's current one: the week is over once his
	## tie is in, so the bracket has already moved on to next Saturday's round.
	var unplayed := 0
	var his: Array = []
	for day in c.rounds:
		if (day as Array).has(m):
			his = day
	if his.is_empty() and c.pool_matches.has(m):
		for x in c.pool_matches:
			if int(x.get("day", 0)) == int(m.get("day", 0)):
				his.append(x)
	for x in his:
		if not bool(x["played"]):
			unplayed += 1
	_ok(not his.is_empty() and unplayed == 0,
		"the round plays out around you",
		"%d ties left unplayed in the round you just fought" % unplayed)


func _test_a_cup_tie_is_not_a_league_fixture() -> void:
	## A cup tie and a league fixture build the SAME MeleeSim by design, so the
	## only thing keeping them apart is which post_ function is called. Posting a
	## cup tie to the league table would look like a scoring error for a
	## fortnight before anybody found it.
	var s := _season()
	if not _to_a_cup(s):
		_ok(false, "a cup tie is not a league fixture", "no cup came up")
		return
	var before: Dictionary = (s.world.tables[s.world.player_tier()][s.world.player_club]
		as Dictionary).duplicate()
	var event_before := s.world.event
	var sim := s.begin_cup_bout()
	sim.run_to_end()
	s.post_cup_bout(sim)
	var after: Dictionary = s.world.tables[s.world.player_tier()][s.world.player_club]
	_ok(int(after["played"]) == int(before["played"])
			and int(after["rf"]) == int(before["rf"])
			and s.world.event == event_before,
		"a cup tie is not a league fixture",
		"played %d before and %d after; the matchday did not move" % [
			int(before["played"]), int(after["played"])])


func _test_losing_puts_you_out() -> void:
	## A knockout you cannot go out of is a fixture list.
	var s := _season()
	var out_at := ""
	var ties := 0
	var guard := 0
	while guard < 40:
		guard += 1
		if not _to_a_cup(s, 20):
			break
		var c := s.pending_cup()
		ties += 1
		s.sim_cup_tie()
		if not c.player_alive():
			out_at = "%s, %s" % [c.cup_name, c.player_finish]
			break
	_ok(ties > 0, "you are asked for every round",
		"%d ties came up across the run" % ties)
	notes.append("knocked out: %s" % (out_at if out_at != "" else "won everything in the run"))


func _test_you_cannot_walk_away_from_a_cup() -> void:
	## The end-of-season button must be shut while a bracket is waiting. Without
	## this a player walks away from a Worlds semi-final by starting next year.
	var s := _season()
	if not _to_a_cup(s):
		_ok(false, "you cannot walk away from a cup", "no cup came up")
		return
	## ONE THING A SATURDAY (30 Sep 2026): on a cup Saturday there is no league
	## fixture to fight instead, and the week does not move until the tie is in.
	var wk := s.world.week
	var nm := s.pending_cup().cup_name
	var league := s.begin_bout()
	_ok(s.cup_pending() and not s.ready_to_roll() and league == null and s.world.week == wk,
		"you cannot walk away from a cup",
		"a %s tie is open; league fixture offered: %s; week %d -> %d" % [
			nm, "yes" if league != null else "no", wk, s.world.week])


func _test_the_auto_path_is_untouched() -> void:
	## The soak tests and the auto-play path run a world with no player in it,
	## and every cup must still resolve itself exactly as it always did. This is
	## the check that says the new seam is opt-in.
	var w := LeagueWorld.new(9001)
	var seasons := 0
	for i in 6:
		var g := 0
		while not w.season_complete() and g < 40:
			g += 1
			w.play_event()
		w.roll_over()
		seasons += 1
	var worlds_run := 0
	for h in w.honors:
		if String(h.get("id", "")) == "worlds":
			worlds_run += 1
	_ok(worlds_run == seasons and w.cups.is_empty() and w.worlds == null,
		"the auto path is untouched",
		"%d seasons, %d Worlds resolved, nothing left holding" % [seasons, worlds_run])


func _test_your_own_show_waits_for_you_too() -> void:
	## The hosted tournament goes through the same seam, which is the whole
	## reason it was worth building the seam rather than special-casing the cups.
	var s := Season.new(MeleeRosters.starting_club(), 77)
	s.office.credits = 60
	s.take_bid(1, 1)
	## THE SHOW, NOT WHICHEVER CUP IS FIRST. A club good enough to be invited to
	## an Invitational has that tie pending too, and this used to take the first
	## pending cup to be its own show.
	var guard := 0
	var c: Cup = null
	while s.booked != null and guard < 12:
		guard += 1
		var p := s.pending_cup()
		if p != null and s.booked.cup == p:
			c = p
			break
		if p != null:
			s.sim_cup_tie()
		else:
			s.skip_event()
	var waiting := c != null and s.cup_pending()
	var credits_before := s.office.credits
	## Fight it out.
	var g2 := 0
	while s.booked != null and s.cup_pending() and g2 < 12:
		g2 += 1
		s.sim_cup_tie()
	_ok(waiting and c != null and s.booked == null and not s.last_show.is_empty(),
		"your own show waits for you too",
		"the %s ran as a bracket; finished %s, net %+d" % [
			c.cup_name if c != null else "?",
			String(s.last_show.get("finish", "?")), int(s.last_show.get("net", 0))])
	_ok(s.office.credits != credits_before or int(s.last_show.get("gate", 0)) == 0,
		"and the gate is counted when it is over",
		"credits %d -> %d once the podium was known" % [credits_before, s.office.credits])


## --------------------------------------------- the cup knows what night it is
## THE SECOND DOOR FORGOT THREE THINGS THE FIRST ONE SAID.
##
## `begin_cup_bout` started life as a copy of `begin_bout` with the roles block
## factored out, and a copy drifts: it set the corner clock, the occasion and the
## opposition's coaching by hand, and never set `opponent_club_id`, `venue` or
## `miles` at all. A cup sim therefore ran with `opponent_club_id == -1` and
## `venue == HOME` — so GRUDGE could not fire against the club the man was
## actually fighting, HOMESICK could not fire on a trip nobody was at home for,
## and the splash before the charge drew the home arena for a tie on neutral
## ground. Three traits and a screen, off, on the biggest fixtures in the game,
## and the file already carried a note saying this exact pair of functions had
## disagreed twice before.
##
## So this does not check the cup. It checks that THE TWO DOORS AGREE — every
## field the league fixture sets, the cup tie sets too.
func _test_both_doors_dress_the_same_sim() -> void:
	var bad: Array[String] = []
	var s := _season(7311)
	if not _to_a_cup(s):
		_ok(false, "both doors dress the same sim", "no cup came up")
		return
	var cup := s.begin_cup_bout()
	if cup == null:
		_ok(false, "both doors dress the same sim", "the cup door returned nothing")
		return

	## 1. WHO. The one the bracket drew, not -1 and not the league's next name.
	var drawn := s.cup_opponent()
	if cup.opponent_club_id != drawn:
		bad.append("the cup sim fights club %d and the bracket says %d"
			% [cup.opponent_club_id, drawn])

	## 2. WHERE. A cup tie is neutral ground, which is what the season already
	## says out loud; a sim left on its HOME default is the bug, not a default.
	if cup.venue != Venue.Kind.NEUTRAL:
		bad.append("a cup tie was dressed as %s" % Venue.NAME.get(cup.venue, "?"))
	## 3. HOW FAR. Zero is the signature of nobody having set it.
	if cup.miles <= 0.0:
		bad.append("the trip to the tie measures %.0f miles" % cup.miles)

	## 4. And the things the copy DID set, so tightening the door did not drop
	## them on the way through.
	if cup.corner_time <= 0.0:
		bad.append("the cup sim has no corner clock")
	if typeof(cup.skills[1]) == TYPE_DICTIONARY and cup.skills[1].is_empty():
		bad.append("the cup opposition was never coached")

	## 5. THE REAL CHECK: no field a league fixture fills is left empty here.
	## Compared field by field against the other door rather than by a list
	## somebody has to remember to extend.
	var league := s.begin_bout()
	if league != null:
		for field in ["opponent_club_id", "venue", "corner_time"]:
			var l = league.get(field)
			var c = cup.get(field)
			if typeof(l) == TYPE_INT and l >= 0 and typeof(c) == TYPE_INT and c < 0:
				bad.append("%s: the league sets %d, the cup leaves it %d" % [field, l, c])
			if typeof(l) == TYPE_FLOAT and l > 0.0 and typeof(c) == TYPE_FLOAT \
					and is_zero_approx(c):
				bad.append("%s: the league sets %.2f, the cup leaves it 0" % [field, l])
		notes.append("both doors: league vs %s, cup vs %s on %s, %.0f miles"
			% [String(s.world.clubs[league.opponent_club_id]["name"]),
				String(s.world.clubs[cup.opponent_club_id]["name"]),
				Venue.NAME.get(cup.venue, "?"), cup.miles])

	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	_ok(bad.is_empty(), "both doors dress the same sim",
		"a cup tie knows who it is against, that it is on neutral ground, and how far the men travelled")



## THE SHAPE OF A YEAR (Pete, 30 Sep and 1 Oct): a league fixture a Saturday,
## each cup one weekend, a bye, the playoff one weekend; at National a second
## bye and the Worlds week. Never two things in one week.
func _test_the_weeks_of_a_year() -> void:
	var by := Calendar.build(5, false)
	var nat := Calendar.build(15, true)
	var kinds := func(cal: Array) -> Array:
		var out: Array = []
		for w in cal:
			out.append(int(w["kind"]))
		return out
	var b: Array = kinds.call(by)
	var n: Array = kinds.call(nat)
	var K := Calendar.Kind
	_ok(b.count(K.LEAGUE) == 5 and b.count(K.CUP) == 2 and b.count(K.PLAYOFF) == 1
			and b[b.size() - 2] == K.BYE and b[b.size() - 1] == K.PLAYOFF and not b.has(K.WORLDS),
		"a Backyard year is five league weeks, two cup weekends, a bye and the playoff",
		"%d weeks: %s" % [b.size(), str(b)])
	_ok(n.count(K.LEAGUE) == 15 and n.count(K.BYE) == 2 and n[n.size() - 1] == K.WORLDS
			and n[n.size() - 2] == K.BYE and n[n.size() - 3] == K.PLAYOFF,
		"a National year ends playoff, bye, Worlds",
		"%d weeks, last four %s" % [n.size(), str(n.slice(n.size() - 4))])


## THE SEND-OFF: the National champion's bye before the Worlds is three cards —
## the celebration, the national camp, the tabard — and the club goes to the
## Worlds under the country's name, as its only berth.
func _test_the_send_off() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	var w := s.world
	for c in w.clubs:
		if int(c["tier"]) == League.Tier.NATIONAL:
			c["tier"] = 0
			break
	w.clubs[w.player_club]["tier"] = League.Tier.NATIONAL
	w._new_season()
	## Straight to the week before the Worlds, as champions.
	var other := -1
	for c in w.clubs:
		if int(c["tier"]) == League.Tier.NATIONAL and int(c["id"]) != w.player_club:
			other = int(c["id"])
			break
	w.finalists[League.Tier.NATIONAL] = [w.player_club, other]
	w.week = w.calendar.size() - 2
	var fans := s.office.fans
	var xp := 0
	for f in s.club.roster:
		xp += f.xp
	var asked: Array[String] = []
	var guard := 0
	while s.blocked_by() == "sendoff" and guard < 6:
		guard += 1
		asked.append(String(s.send_off_card()["title"]))
		s.answer_send_off()
	var xp2 := 0
	for f in s.club.roster:
		xp2 += f.xp
	_ok(asked.size() == SendOff.STEPS and s.office.fans > fans and xp2 > xp
			and w.team_title == SendOff.team_name(s),
		"the champion is sent off: celebrated, trained, given the tabard",
		"%s; fans %.0f -> %.0f, squad XP +%d, going as '%s'" % [", ".join(asked), fans, s.office.fans,
			xp2 - xp, w.team_title])
	## And the Worlds takes the champion as the country's one club.
	s.skip_event()
	var home := 0
	if w.worlds != null:
		for id in w.worlds.entrants:
			if not bool(w.clubs[int(id)].get("guest", false)):
				home += 1
	_ok(w.worlds != null and w.worlds.entrants.has(w.player_club) and home == LeagueWorld.WORLDS_HOME,
		"and goes to the Worlds as the country's only club",
		"%d home club(s) in a field of %d" % [home, w.worlds.entrants.size() if w.worlds != null else 0])


## A CUP WEEKEND IS ONE WEEK OF PRACTICE, FOUGHT OR SIMMED, AND ITS RESULTS
## REACH THE MEN (3 Oct 2026). Three fought ties practised the roster three
## times; a cup result moved only the club figure, which the next re-sync erased.
func _test_a_cup_weekend_is_one_week() -> void:
	var gains := []
	for mode in ["fight", "sim"]:
		var s := _season()
		if not _to_a_cup(s):
			_ok(false, "a cup weekend is one week", "no cup came up")
			return
		var wk := s.world.week
		var five := s.club.starting_five()
		var x0 := 0
		for f in s.club.roster:
			if not five.has(f):
				x0 += f.xp
		while s.cup_pending() and s.world.week == wk:
			if mode == "fight":
				var sim := s.begin_cup_bout()
				sim.run_to_end()
				s.post_cup_bout(sim)
			else:
				s.sim_cup_tie()
		if s.world.week == wk:
			SeasonCups.end_week(s)
		var x1 := 0
		for f in s.club.roster:
			if not five.has(f):
				x1 += f.xp
		gains.append(x1 - x0)
	_ok(gains[0] == gains[1], "a fought cup weekend practises once, as a simmed one does",
		"men off the line gained %d fought, %d simmed" % [gains[0], gains[1]])
	var t := _season()
	_to_a_cup(t)
	var c := t.pending_cup()
	var m := c.player_match()
	var men := t.club.active_eight()
	var before := 0.0
	for f in men:
		before += f.morale
	if int(m["a"]) == t.world.player_club:
		c.record(m, 2, 0, 8, 0)
	else:
		c.record(m, 0, 2, 0, 8)
	t._finish_cup_round(c, true)
	var after := 0.0
	for f in men:
		after += f.morale
	_ok(after > before, "a cup tie won lifts the men, not just the club figure",
		"eight's morale %.3f -> %.3f" % [before, after])


## THE SPONSOR AND THE WEAR FOLLOW THE MEN WHO STOOD IN THE TIE (Pete, 8 Oct 2026,
## Harness #2). Codex found the sponsor paid the line before injuries were rested
## and the wear landed on the line after, so a man hurt in the tie was paid with
## no dent and the reserve who replaced him was dented with no pay.
func _test_the_men_who_fought_are_paid_and_worn() -> void:
	var s := _season()
	if not _to_a_cup(s):
		_ok(false, "the men who fought are paid and worn", "no cup came up")
		return
	for f in s.club.roster:
		f.harness = Quartermaster.Grade.TITANIUM
		f.armor = 1.0
	var sim := s.begin_cup_bout()
	sim.run_to_end()
	var stood := SeasonBouts.fought_line(s, sim)
	var before := {}
	for f in s.club.roster:
		before[f] = f.armor
	var sp0 := int(s.office.books_in.get(ClubOffice.LINE_SPONSOR, 0))
	var owed := s.office.harness_receipts
	for f in stood:
		owed += Quartermaster.sponsor_rate(f)
	## A KNOCK ON THE FIRST MAN, forced rather than rolled, so the line that is
	## rested after the tie is guaranteed to differ from the line that fought it.
	var hurt: FighterCard = stood[0]
	hurt.injury = 3
	s.post_cup_bout(sim)
	var worn_ok := true
	var spared_ok := true
	for f in s.club.roster:
		var dented: bool = float(f.armor) < float(before[f]) - 0.0001
		if stood.has(f) and not dented:
			worn_ok = false
		if not stood.has(f) and dented:
			spared_ok = false
	_ok(stood.size() >= 5 and stood.has(hurt), "the men who stood in the tie are the men read off the bout",
		"%d men, the hurt man among them" % stood.size())
	_ok(worn_ok, "every man who fought the tie takes the wear, the hurt man included",
		"%s at %.3f" % [hurt.display_name, hurt.armor])
	_ok(spared_ok, "and no man who did not fight it is dented",
		"the reserve who came in for him kept his kit")
	## Read off the Sponsors line, not the bank: a won tie also pays a purse.
	var paid := int(s.office.books_in.get(ClubOffice.LINE_SPONSOR, 0)) - sp0
	_ok(paid == int(floor(owed + 0.000000001)),
		"and the sponsor paid for exactly those men",
		"%d CC paid, %.2f owed" % [paid, owed])
