class_name SeasonCups
extends RefCounted
## Methods of `Season`, moved out of season.gd so that file is not one
## three-thousand-line object. Every function takes the Season as `s`; `Season`
## keeps a one-line wrapper for each, so callers did not change.




# ----------------------------------------------------------------- the bid
## Is the federation waiting on you? Answered before the season starts, the same
## way a cup tie is answered before the next matchday — a decision the game
## stops and asks for is a decision the player notices making.
static func bid_open(s: Season) -> bool:
	return not s.bid_offers.is_empty()




## Put the year's dates on the table. Called at the start of every season,
## including the first, and only when the club has no tournament already running.
static func open_bids(s: Season) -> void:
	if s.booked != null:
		return
	s.bid_offers = ClubEvent.offers(s.world.events_this_season(),
		s.world.player_tier())




## Take a date. The bid and the budget are both spent NOW, a season before the
## show — which is the whole shape of it. What you do to your ground and your
## following between here and there is what decides whether it comes back.
static func take_bid(s: Season, offer_i: int, budget_i: int) -> String:
	if not s.bid_open():
		return UiKit.t("There is nothing on the table.")
	if offer_i < 0 or offer_i >= s.bid_offers.size():
		return UiKit.t("No such date.")
	var offer: Dictionary = s.bid_offers[offer_i]
	var b: Dictionary = ClubEvent.BUDGETS[clampi(budget_i, 0, ClubEvent.BUDGETS.size() - 1)]
	var total := int(offer["bid"]) + int(b["cost"])
	if s.office.credits < total:
		return UiKit.t("The date and the budget come to %d CC and you have %d.") % [
			total, s.office.credits]
	s.office.spend(total, ClubOffice.LINE_CUP)
	s.booked = ClubEvent.tournament(offer, s.office.arena, budget_i)
	## ITS OWN SATURDAY, straight after the league day it was bid for.
	Calendar.insert_own(s.world.calendar, int(offer["event"]), s.world.week)
	s.bid_offers.clear()
	return ""




## Or pass on the year. Free, and it has to be — a club that cannot afford a
## date must still be able to get on with its season.
static func decline_bid(s: Season) -> void:
	s.bid_offers.clear()




static func bid_preview(s: Season, offer_i: int, budget_i: int) -> Dictionary:
	if offer_i < 0 or offer_i >= s.bid_offers.size():
		return {}
	var offer: Dictionary = s.bid_offers[offer_i]
	return ClubEvent.preview(s.office.arena.capacity(), s.office.fans,
		budget_i, int(offer["bid"]), s.world.player_tier())




# --------------------------------------------------------------------- cups
## THE TIE IN FRONT OF YOU, or null. One at a time and in a fixed order — the
## domestic cups before the Worlds — so a player never has two brackets asking
## him for a result and no way to say which is which.
##
## AND ONLY ON ITS OWN SATURDAY (30 Sep 2026). A bracket you are alive in waits
## for its week; until then the week in front of you is whatever the calendar
## says it is.
static func pending_cup(s: Season) -> Cup:
	var w := s.world.this_week()
	var c: Cup = null
	if int(w.get("kind", -1)) == Calendar.Kind.OWN:
		c = s.booked.cup if s.booked != null else null
	else:
		c = s.world.cup_of_week(w)
	if c != null and not c.player_match().is_empty():
		return c
	return null




## ANY CUP WORTH LOOKING AT, whether or not it is waiting on you.
##
## `pending_cup()` only answers while a tie of yours is unplayed, and the draw
## screen was reachable from nowhere else — so the moment you were knocked out,
## the bracket you had just been knocked out of became unviewable, and the
## CHAMPION line on that screen was code no player could reach. A cup is most
## interesting in the ten seconds after you lose.
##
## Prefers one you are still in, then any running cup, then the last one that
## finished this season.
static func viewable_cup(s: Season) -> Cup:
	var mine := s.pending_cup()
	if mine != null:
		return mine
	for c in s.world.open_cups():
		return c
	var best: Cup = null
	for c in s.world.cups:
		if c.entrants.has(s.world.player_club):
			best = c
	if best != null:
		return best
	if s.world.worlds != null and s.world.worlds.entrants.has(s.world.player_club):
		return s.world.worlds
	return null




## Is a bracket waiting on the player? The season cannot roll over while one is,
## and the Club screen shows the tie instead of the league fixture.
static func cup_pending(s: Season) -> bool:
	return s.pending_cup() != null




static func cup_opponent(s: Season) -> int:
	var c := s.pending_cup()
	if c == null:
		return -1
	var m := c.player_match()
	return int(m["b"]) if int(m["a"]) == s.world.player_club else int(m["a"])




## Fight your own cup tie. The same MeleeSim a league fixture builds, with the
## same captains and the same drawn plan — a cup match is a bout, not a special
## case, and the moment it stops being one the two paths start to drift.
static func begin_cup_bout(s_: Season) -> MeleeSim:
	s_.ensure_a_line()
	var c := s_.pending_cup()
	if c == null:
		return null
	s_.opponent = s_.club_for(s_.cup_opponent())
	var s := hash("cup:%d:%d:%d:%d" % [s_.seed_value, s_.world.season, s_.world.event, s_.cup_opponent()])
	var sim := MeleeSim.new(s_.club, s_.opponent, s, s_.opposition_scale(s_.cup_opponent()))
	## NEUTRAL GROUND AND A REAL TRIP. `venue_kind()` already answers NEUTRAL
	## while a tie is pending, so it is asked rather than re-decided here; the
	## distance is to the club you are actually fighting, which on a cup night is
	## not the one the league has you down for.
	s_._dress_sim(sim, s_.cup_opponent(), s_.venue_kind(),
		s_.world.miles_between(s_.world.player_club, s_.cup_opponent()))
	return sim




## Post a fought cup tie, then play the rest of the round out around it.
static func post_cup_bout(s: Season, sim: MeleeSim) -> void:
	var c := s.pending_cup()
	if c == null:
		return
	var m := c.player_match()
	var mine: bool = int(m["a"]) == s.world.player_club
	s.last_result = [sim.rounds_won[0], sim.rounds_won[1], sim.margin[0], sim.margin[1]]
	## A CUP TIE IS A FIGHT. It moves MATCHED exactly as a league fixture does —
	## the grade describes how hard the country is fighting you, and the country
	## does not stop on a Tuesday night.
	s._grade_bout(int(s.last_result[0]), int(s.last_result[1]))
	s._award_xp(sim)
	if mine:
		c.record(m, sim.rounds_won[0], sim.rounds_won[1], sim.margin[0], sim.margin[1])
	else:
		c.record(m, sim.rounds_won[1], sim.rounds_won[0], sim.margin[1], sim.margin[0])
	s._finish_cup_round(c, int(m.get("winner", -1)) == s.world.player_club)
	## THE KNOCK LANDS AFTER THE WEEK TICKS, as it does in the league — see
	## `post_bout`. Before, a cup tie never ticked the week at all.
	s._apply_injuries(sim)
	## AND THE KIT TAKES THE TIE, as a league bout does (Pete, 1 Oct 2026:
	## "fights should wear them").
	SeasonBouts.bout_wear(s)
	s.sync_power()




## Or hand it to the AI. Same road afterwards.
## A FORFEITED TIE: recorded 0-2 against the player, and the round plays on.
static func forfeit_cup_tie(s: Season) -> void:
	var c := s.pending_cup()
	if c == null:
		return
	var m := c.player_match()
	var mine: bool = int(m["a"]) == s.world.player_club
	if mine:
		c.record(m, 0, Tuning.BOUT_WINS, 0, MeleeClub.LINE_SIZE)
	else:
		c.record(m, Tuning.BOUT_WINS, 0, MeleeClub.LINE_SIZE, 0)
	s._finish_cup_round(c, false)


static func sim_cup_tie(s: Season) -> void:
	s.ensure_a_line()
	var c := s.pending_cup()
	if c == null:
		return
	var m := c.player_match()
	var res: Array = s.world.quick_bout(int(s.world.clubs[int(m["a"])]["power"]),
		int(s.world.clubs[int(m["b"])]["power"]))
	c.record(m, int(res[0]), int(res[1]), int(res[2]), int(res[3]))
	s._finish_cup_round(c, int(m.get("winner", -1)) == s.world.player_club)




## Everything that happens once the player's tie is in the book: the rest of the
## round is played around him, the bracket moves on, and a finished cup is
## retired — with the gate settled if it was his own show.
static func _finish_cup_round(s: Season, c: Cup, won: bool) -> void:
	s.office.morale_after(won, false)
	s.office.after_event(won, false)
	if Calendar.is_tournament(s.world.week_kind()):
		## A TOURNAMENT IS ONE WEEK — a cup or your show a weekend, the Worlds a
		## whole week (Pete, 30 Sep). Every round is fought inside it, several
		## bouts a day, so the bracket plays on around you until you are out or
		## it is won.
		var r := s.world.cup_resolver()
		c.sim_others(r)
		## NOT PAST THE PLAYER'S BRONZE. If he lost a semi he is owed the
		## third-place match, and finishing the cup around him would sim it.
		while c.round_complete() and not c.is_over() and not c.player_in_third():
			if not c.advance():
				break
			c.sim_others(r)
		c.settle_third(r, true)
		if not c.player_match().is_empty():
			s.sync_power()
			return
		## Out, or champion: the rest of the day on paper, then the money.
		c.run_all(r)
		_crown(s, c)
		if s.booked != null and s.booked.cup == c:
			s._settle_gate(s.booked, c)
		else:
			s.world.retire_cup(c)
		end_week(s)
		return
	## A PLAYOFF ROUND IS A WEEK. The rest of the round is played around you, the
	## bracket moves on a round, and the week is over.
	end_week(s)
	_crown(s, c)
	s.sync_power()


## YOU WON SOMETHING. The fanfare is played here rather than left to the mood
## system, because a mood is a state you are in and this is a moment that has
## just passed. Everybody who travelled gets the honor, not only the five on the
## line for the final — a cup is won by an eight.
static func _crown(s: Season, c: Cup) -> void:
	if c.is_over() and c.champion == s.world.player_club and not c.has_meta("crowned"):
		c.set_meta("crowned", true)
		Audio.champion()
		for f in s.club.active_eight():
			f.honors += 1


## THE WEEK ENDS. The world plays its Saturday (everyone else's fixtures, the
## rest of a cup round), then the club's week happens whether or not it fought:
## the squad trains, knocks heal a week, the one-job-a-week throttles reset.
## Called by every week that is not a league matchday — the league's own path
## does the same in `_after_event`.
static func end_week(s: Season) -> void:
	if s.practiced_week != s.world.week:
		s._practice()
	s.world.play_week()
	quiet_week(s)
	enter_week(s)
	s.sync_week()


static func quiet_week(s: Season) -> void:
	for f in s.club.roster:
		if f.injury > 0:
			f.injury -= 1
	s.office.new_week()
	s._roll_availability()
	s.sync_power()


## A SATURDAY OF YOUR OWN. The show's bracket is drawn the morning it starts, so
## it is drawn against the club you are on the day rather than on the day you
## bid.
static func enter_week(s: Season) -> void:
	if s.world.week_kind() == Calendar.Kind.OWN and s.booked != null \
			and not s.booked.settled and s.booked.cup == null:
		s._settle_event()


## The cup path uses the same rule as the league path, because it was two copies
## of one rule and that is how the two ended up disagreeing about what an injury
## costs.
static func _apply_injuries(s: Season, sim: MeleeSim) -> void:
	s._apply_bout_injuries(sim)




# ------------------------------------------------------------------- events
## Book a demo. Instant, unplayed, small and it cannot lose — this is what a
## club with no following and an empty week does.
static func run_demo(s: Season) -> String:
	if s.booked != null:
		return UiKit.t("You already have %s in the diary.") % s.booked.kind_name().to_lower()
	## ONCE A WEEK, and without this the game has no economy.
	##
	## `run_demo` never set `booked`, and the button's only guard was
	## `booked == null`, so it came back on every rebuild of the screen. Forty
	## taps on a Backyard club is forty credits — both facilities, two captains,
	## the arena and four cap raises, in one sitting, from a button meant to pay
	## one credit for an empty week. Every price in the game was a suggestion.
	##
	## It goes through the same per-week throttle as an upgrade rather than
	## getting its own flag, because a second throttle is a second thing to
	## forget to reset.
	if s.office.done_this_week("demo"):
		return UiKit.t("You have already put a demo on this week.")
	var pay: int = ClubEvent.DEMO_PAY[clampi(s.office.arena.level, 0, ClubEvent.DEMO_PAY.size() - 1)]
	s.office.take(pay, UiKit.t("A demo at the ground"), "event", ClubOffice.LINE_GROUND)
	## A demo keeps you on the calendar. Barely — a quarter of the turnout a real
	## event would pull, and no promotion behind it.
	var heads := int(float(ClubEvent.attendance(s.office.arena.capacity(),
		s.office.fans)) * 0.25)
	s.office.crowd_came(heads)
	s.office.mark_this_week("demo")
	s.last_show = {
		"kind": "Demo", "heads": heads,
		"gate": pay, "cost": 0, "net": pay, "finish": "", "podium": 0,
	}
	return ""




## Does the booked event land on this matchday? Called as the event advances.
static func _event_due(s: Season) -> bool:
	return s.world.week_kind() == Calendar.Kind.OWN and s.booked != null \
		and not s.booked.settled and s.booked.cup == null




## PUT THE SHOW ON. The field is drawn from clubs near your own strength, the
## Cup machinery runs it exactly as it runs an Invitational, and the gate is
## settled against the following you had on the day rather than the one you had
## when you booked it.
## PUT THE SHOW ON. The field is drawn from clubs near your own strength and the
## Cup machinery runs it exactly as it runs an Invitational — and YOU ARE IN IT,
## so the bracket waits for you the same way a King's Cup does. The gate is not
## counted until the cup is finished, because the podium is part of the payout
## and there is no podium until somebody has won it.
static func _settle_event(s: Season) -> void:
	var e := s.booked
	var field := s._invite_field(e)
	e.cup = Cup.new("%s Invitational" % s.club.short_name, field,
		hash("show:%d:%d" % [s.seed_value, e.due]), s.world.player_club, false)
	## AN ID, so a save can find its way back to this cup. Every other cup in
	## the world gets one from `league_world.gd`; the one the player pays for
	## was the only one without, which is why a reload orphaned it.
	e.cup.set_meta("id", "show:%d" % e.due)
	s.world.cups.append(e.cup)
	## Everything that is not yours in the opening round, so the bracket is
	## ready to ask you for a result the moment the screen opens.
	e.cup.sim_others(s.world.cup_resolver())




## The money, once the bracket is done. Attendance is read against the
## following you have ON THE DAY rather than the one you had when you booked —
## two matchdays is long enough for that to have moved, and the gamble is the
## whole point of the feature.
static func _settle_gate(s: Season, e: ClubEvent, c: Cup) -> void:
	var heads := ClubEvent.attendance(s.office.arena.capacity(), s.office.fans,
		float(ClubEvent.BUDGETS[e.budget]["draw"]))
	var g := ClubEvent.show_gate(heads, float(ClubEvent.BUDGETS[e.budget]["take"])) \
		+ ClubEvent.entry_fees(s.world.player_tier())
	var podium := 0
	if c.champion == s.world.player_club:
		podium = ClubEvent.PODIUM[0]
	elif c.runner_up == s.world.player_club:
		podium = ClubEvent.PODIUM[1]
	elif c.third == s.world.player_club:
		podium = ClubEvent.PODIUM[2]
	s.office.take(g + podium, UiKit.t("The cup"), "event", ClubOffice.LINE_CUP)
	## A crowd is the loudest thing that can happen to a club, and everyone who
	## came is half a fan afterwards. An empty house is not punished twice — the
	## lost credits are punishment enough — so this only ever adds.
	s.office.crowd_came(heads)
	## A PODIUM AT YOUR OWN SHOW IS WORTH A CROWD. It used to be `note_shift(2.0)`
	## on a fame scale that no longer exists; a fifteenth of the room left is the
	## same size of nudge against the one number that is.
	if podium > 0:
		s.office.fans += (s.office.fan_cap() - s.office.fans) * 0.067
		s.office.crowd_came(0)
	e.settled = true
	s.last_show = {
		"kind": e.kind_name(), "heads": heads, "gate": g, "cost": e.cost(),
		"net": g + podium - e.cost(), "finish": c.player_finish, "podium": podium,
	}
	e.report = s.last_show.duplicate()
	s.world.retire_cup(c)
	s.booked = null




## Worlds guests are deleted when their Worlds ends; a show that invited one
## would hold an id that stops existing mid-bracket.
static func _is_guest(s: Season, id: int) -> bool:
	return bool(s.world.clubs[id].get("guest", false)) or int(s.world.clubs[id].get("tier", 0)) < 0




## Who turns up. Eight clubs of roughly your own standard, because a tournament
## you cannot place in is not a tournament you would put money into — and a
## bigger budget reaches further up the list for names.
static func _invite_field(s: Season, e: ClubEvent) -> Array:
	var mine: int = int(s.world.clubs[s.world.player_club]["power"])
	var reach: int = 4 + e.budget * 7
	var pool: Array = []
	for id in s.world.clubs.size():
		if id == s.world.player_club or s._is_guest(id):
			continue
		if absi(int(s.world.clubs[id]["power"]) - mine) <= reach:
			pool.append(id)
	pool.sort_custom(func(a, b): return int(s.world.clubs[a]["power"]) > int(s.world.clubs[b]["power"]))
	var field: Array = [s.world.player_club]
	for id in pool:
		if field.size() >= ClubEvent.FIELD:
			break
		field.append(id)
	## A thin country still gets a full draw; the weakest clubs make up the
	## numbers rather than the bracket being short.
	var i := 0
	while field.size() < ClubEvent.FIELD and i < s.world.clubs.size():
		if i != s.world.player_club and not field.has(i) and not s._is_guest(i):
			field.append(i)
		i += 1
	field.sort_custom(func(a, b): return int(s.world.clubs[a]["power"]) > int(s.world.clubs[b]["power"]))
	return field




## The last event, or {} at the start of a season.
static func last_event(s: Season) -> Dictionary:
	return s.results[s.results.size() - 1] if not s.results.is_empty() else {}
