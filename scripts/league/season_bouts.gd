class_name SeasonBouts
extends RefCounted
## Methods of `Season`, moved out of season.gd so that file is not one
## three-thousand-line object. Every function takes the Season as `s`; `Season`
## keeps a one-line wrapper for each, so callers did not change.




## EVERYTHING YOUR CAPTAINS PUT ON THE LINE, in one place.
##
## This was two copies of the same four lines — one in `begin_bout`, one in
## `begin_cup_bout` — and the day the Physio trait needed a second injection
## beside the tiers, only one of them would have got it. That is the fifth time
## this document has recorded the same shape: a rule applied at two call sites is
## a rule with a hole in it. There is now one caller-facing verb, and a cup tie
## and a league fixture are dressed identically by construction rather than by
## somebody remembering.
## EVERYTHING A SIM NEEDS TO KNOW ABOUT THE FIXTURE IT IS ABOUT TO BE, in one
## place, because the two bout paths have now disagreed about the fixture THREE
## TIMES: the injury tick, the grade, and this.
##
## `begin_cup_bout` was a copy of `begin_bout` with the roles block factored out,
## and a copy drifts. It set the corner clock, the occasion and the skills by
## hand and never set `opponent_club_id`, `venue` or `miles` at all — so on a cup
## night GRUDGE could not fire against the club the man was actually fighting,
## HOMESICK could not fire on a trip nobody was at home for, and the splash
## before the charge drew the HOME arena for a tie on neutral ground. Three
## traits and a screen, silently off, on the biggest fixtures in the game.
##
## The roles block is not the shared part. THE FIXTURE is the shared part.
static func _dress_sim(s: Season, sim: MeleeSim, opp_id: int, kind: int, dist: float) -> void:
	## WHO, WHERE, HOW FAR. Handed over rather than looked up, for the same
	## reason `big_occasion` is: the fixture knows, the sim should not have to ask.
	sim.opponent_club_id = opp_id
	sim.venue = kind
	sim.miles = dist
	sim.corner_time = Grade.corner_time(s.grade, s.custom_grade)
	sim.set_wheel(Grade.wheel_for(s.grade, s.matched_step, s.custom_grade))
	## ASKED OF THE SEASON, not read off `Session.bout_mood` (29 Sep 2026). The
	## screen sets that static AFTER `begin_cup_bout` returns, so every fought
	## cup tie ran with the previous bout's mood (never a big occasion) and the
	## next league bout inherited the cup's — and a reload reset it, so a bout
	## replayed from a save came out differently. `mood()` is only ever not
	## NORMAL while a tie is pending, and a pending tie blocks league bouts.
	sim.big_occasion = s.mood() != UiKit.Mood.NORMAL
	## And now that the sim knows the fixture, let the fixture reach the men.
	sim.dress()
	## The opposition is coached to its division, on the six-rung ladder Pete
	## named on 10 Sep 2026. A Backyard club is nobody's idea of well drilled;
	## the National Division is, and Worlds guests are better than that.
	var ot := -1
	if opp_id >= 0 and opp_id < s.world.clubs.size():
		ot = int(s.world.clubs[opp_id]["tier"])
	sim.skills[1] = Season.GUEST_TIER if ot < 0 else Season.CPU_TIER[clampi(ot, 0, Season.CPU_TIER.size() - 1)]
	## YOUR CHALKBOARD GOES OUT WITH THEM TOO. The shape is always resolved
	## through the board, so a built-in and a drawn formation reach the list by
	## the same road; the play only goes on if it is still legal for the shape
	## you actually picked, which is what Pete's formation-dependent check mark
	## means at the point it matters.
	sim.set_plan(0, s.board.spots_for(s.formation_id).duplicate(), s.called_play())

	var roles := [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]
	var tiers := {}
	var corner := {}
	for role in roles:
		tiers[role] = s.office.tier_for(role)
		## PHYSIO. His men come out of the corner with more left in them, which is
		## a trait you feel in the fifth round of a bout you are losing.
		if s.office.trait_covers(ClubOffice.Trait.PHYSIO, role):
			corner[role] = ClubOffice.TRAIT_PHYSIO
	sim.set_role_skills(0, tiers)
	sim.set_corner_bonus(0, corner)




## ----------------------------------------------------------- whose ground
## THE GROUND A GIVEN CLUB PLAYS ON, and the player's own is the exception.
##
## `LeagueWorld.ground_of()` derives a level and a condition for any club from
## its id, its tier and the season — which is right for the other fifteen clubs
## in the division and WRONG for the player, whose ground is a thing he bought,
## keeps and lets go. Asking the world about your own club would tell you a hash
## about an arena you are looking at on another screen.
##
## **A derived answer that overrides a real one is a screen lying about something
## the player can see.** So one door, and it knows which is which.
static func ground_of(s: Season, id: int) -> Dictionary:
	if id == s.world.player_club:
		return {"level": s.office.arena.level, "condition": s.office.arena.condition}
	return s.world.ground_of(id)




## THE FEDERATION'S GROUND, for a cup tie on neutral turf.
##
## It scales with the division the tie is being fought in rather than being one
## fixed room, because a Backyard invitational and the Worlds final are not the
## same afternoon — and it is always immaculate, because the federation is the
## one body in this game with a groundsman.
static func neutral_ground(s: Season) -> Dictionary:
	return {"level": clampi(s.world.player_tier() + 2, 0, Arena.MAX_LEVEL),
		"condition": 1.0}




## THE GROUND THIS WEEK'S FIGHT IS IN, whoever owns it.
static func fight_ground(s: Season) -> Dictionary:
	match s.venue_kind():
		Venue.Kind.NEUTRAL: return s.neutral_ground()
		Venue.Kind.HOME: return s.ground_of(s.world.player_club)
		_:
			var opp := s.opponent_id()
			return s.ground_of(opp) if opp >= 0 else s.neutral_ground()




## WHAT THIS WEEK'S GATE IS WORTH, and where it is. One function, because the
## pre-fight panel, the report and the payment itself all want it and three
## copies of this arithmetic is three answers to one question — which is the
## failure mode that put a second league table on the ticker.
##
## Returns `{cc, where, level, condition, kind}`.
static func gate_now(s: Season) -> Dictionary:
	var kind := s.venue_kind()
	var g := s.fight_ground()
	return {
		"cc": s.office.gate_for(kind, int(g["level"]), float(g["condition"])),
		"where": String(Venue.NAME[kind]),
		"level": int(g["level"]),
		"condition": float(g["condition"]),
		"kind": kind,
	}




## AND WHAT A NAMED FIXTURE WOULD BE WORTH, for the schedule. Same arithmetic,
## a stated opponent and a stated venue rather than this week's.
static func gate_for_fixture(s: Season, opp: int, home: bool) -> int:
	var kind: int = Venue.Kind.HOME if home else Venue.Kind.AWAY
	var g: Dictionary = s.ground_of(s.world.player_club) if home else (
		s.ground_of(opp) if opp >= 0 else s.neutral_ground())
	return s.office.gate_for(kind, int(g["level"]), float(g["condition"]))




## WHERE THE NEXT BOUT IS. A cup tie is neutral ground whoever is in it; a league
## fixture is home or away as the schedule says.
static func venue_kind(s: Season) -> int:
	## A CUP TIE IS NEUTRAL GROUND, whoever is in it, and `pending_cup` is how the
	## rest of the season already asks that question — a second way of asking it
	## here would be a second answer waiting to disagree.
	if s.pending_cup() != null:
		return Venue.Kind.NEUTRAL
	return Venue.Kind.HOME if s.world.player_hosts() else Venue.Kind.AWAY




## Who is hosting, as a club id — the player, or the other lot, or -1 on neutral
## ground where nobody is.
static func host_id(s: Season) -> int:
	match s.venue_kind():
		Venue.Kind.HOME: return s.world.player_club
		Venue.Kind.AWAY: return s.opponent_id()
		_: return -1




## Start the next fixture. Returns a MeleeSim ready to tick, or null on a bye or
## at the end of a season.
static func begin_bout(s_: Season) -> MeleeSim:
	var opp := s_.opponent_id()
	if opp == -1:
		return null
	s_.ensure_a_line()
	s_.opponent = s_.club_for(opp)
	## Seeded off the season and matchday, so replaying a save replays the bout.
	var s := hash("bout:%d:%d:%d" % [s_.seed_value, s_.world.season, s_.world.event])
	var sim := MeleeSim.new(s_.club, s_.opponent, s, s_.opposition_scale(opp))
	## YOUR CAPTAINS AND THE FIXTURE GO OUT WITH THEM. One door, shared with the
	## cup, so the two paths cannot know different things about the same night.
	s_._dress_sim(sim, opp, s_.venue_kind(), s_.miles_travelled())
	return sim




## The routes the line will open with, or null. A play tied to a formation you
## are not in is not an error and not a warning — it simply is not called.
static func called_play(s: Season):
	if s.play_index < 0 or s.play_index >= s.board.plays.size():
		return null
	var p: Dictionary = s.board.plays[s.play_index]
	var f := int(p["formation"])
	if f != Chalkboard.UNIVERSAL and f != s.formation_id:
		return null
	return p["routes"]




## Post a finished bout to the table and move the matchday on. The four numbers
## are the sim's own — rounds won and the standing differential Pete asked for —
## so a fought fixture and a simulated one reach the table through one shape.
static func post_bout(s: Season, sim: MeleeSim) -> void:
	s.last_result = [sim.rounds_won[0], sim.rounds_won[1], sim.margin[0], sim.margin[1]]
	var opp := s.opponent_id()
	## AND WHERE IT WAS PLAYED, captured here with the opponent and for the same
	## reason: everything below this line happens after the week has ticked.
	var was_home: bool = s.venue_kind() == Venue.Kind.HOME
	## AND WHAT THE GATE WAS WORTH, for the same reason. `_after_event` used to
	## ask `gate_now()` after the week had ticked, which described the NEXT
	## fixture — the last matchday of a season always paid as away with no counter.
	var gate := s.gate_now()
	var before := s._my_row()
	s._award_xp(sim)
	Achievements.after_bout(sim)
	s.world.play_week(s.last_result)
	s._after_event(int(s.last_result[0]), int(s.last_result[1]), gate)
	## INJURIES LAND AFTER THE WEEK TICKS, and the order is the whole fix.
	##
	## They used to be applied first, and `_after_event` then decremented every
	## injury on the roster — including the one just written. `INJURY_LENGTH` is
	## [1,1,1,1,2,2,3], so FOUR OF SEVEN KNOCKS COST NOTHING at any Infirmary
	## level, and at `injury_relief() == 2` the floor of 1 was decremented to 0
	## as well: no knock ever kept anybody out, while the Clubhouse went on
	## advertising "-2 events off a knock". The post-bout report said a man was
	## hurt and the squad screen showed him fit.
	##
	## A cup tie took the same knock and cost a week, because `post_cup_bout`
	## does not tick the week — so the identical injury was free in the league
	## and expensive in a cup. Applying after the tick makes both paths agree.
	s._apply_bout_injuries(sim)
	rest_the_injured(s)
	s._apply_regime(was_home)
	s._log(opp, before, true, was_home)
	s._grade_bout(int(s.last_result[0]), int(s.last_result[1]))
	s.event_played.emit(opp, s.last_result)




## ----------------------------------------------------------------- the grade
## WHAT THE GRADE IS WORTH AGAINST THIS PARTICULAR CLUB.
##
## One function, called by both bout paths, so a cup tie and a league fixture
## cannot end up on different difficulties — which is the same class of bug as
## `post_cup_bout` not ticking the week, and that one hid for a fortnight.
static func opposition_scale(s: Season, opp_id: int) -> float:
	## `clubs` is an ARRAY indexed by club id, not a dictionary keyed by one.
	## It was guarded with `.has(opp_id)` for a fortnight, which on a typed array
	## is a type error that returns false — so every bout in the game, against
	## every club, was graded against the same invented power-50 tier-0 nobody.
	## A guard that can only fail is no more a guard than one that cannot.
	if opp_id < 0 or opp_id >= s.world.clubs.size():
		return Grade.scale_for(s.grade, s.matched_step, 50, 0, s.custom_grade)
	var c: Dictionary = s.world.clubs[opp_id]
	return Grade.scale_for(s.grade, s.matched_step, int(c["power"]), int(c["tier"]), s.custom_grade)




## MATCHED MOVES, and only MATCHED. Read off rounds rather than the result alone,
## because a 2-0 and a 2-1 are not the same afternoon — Retro Bowl reads margin
## the same way, taking a second step off the scale for a win by more than
## fourteen. The trophy gate is theirs too: the top of the ladder stays shut
## until the cabinet has something in it.
static func _grade_bout(s: Season, rounds_for: int, rounds_against: int) -> void:
	if s.grade != Grade.G.MATCHED:
		return
	s.matched_step = Grade.matched_next(s.matched_step, rounds_for, rounds_against,
		not s.world.honors.is_empty())





## Knocks land here rather than inside the sim: the fight records who went down
## badly, the season decides whose books it lands on. Only your own men carry
## injuries — the other fourteen fixtures are numbers on a page.
## THE REGIME'S OTHER THREE, once a week: what it costs in morale, in armor,
## and in men.
##
## Morale and wear are club-wide sums of per-man effects, because a club running
## two captains on two different regimes is running two different weeks at once
## and the average is the honest answer.
## `hosted` IS PASSED IN, NOT READ HERE, and that is not fussiness. Both callers
## run `world.play_event()` before this — so by the time this function is on the
## stack, `venue_kind()` is answering about NEXT week's fixture. A function that
## asks the world what happened after the world has moved on is a function that
## is reliably one week wrong, which is exactly the class of bug `post_cup_bout`
## not ticking the week already cost this project a fortnight of.
static func _apply_regime(s: Season, hosted: bool, fought := true) -> void:
	## WHO TRAVELLED, for the gate. A DRAW only pulls people in on a day he is
	## actually there — read off the eight rather than the squad, because a man in
	## the reserves sells nobody a ticket.
	s.office.set_draws(s.club.active_eight())
	for f in s.club.active_eight():
		var role := Tuning.role_of(int(f.pos))
		## EVERY MAN FEELS HIS OWN WEEK. The regime belongs to the captain who
		## teaches his role, so two men on the same eight under two captains on
		## two different regimes have two different weeks — which is the whole
		## reason the regime is set per captain rather than per club.
		f.morale_shift(s.office.regime_morale(role))
		## A captain who teaches nothing still lifts the room.
		f.morale_shift(s.office.presence())
	s.office.sync_morale(s.club)
	## KIT WEARS IN FIGHTS, NOT IN TRAINING (Pete, 1 Oct 2026: "fights should
	## wear them, but not training"). The regime used to carry the wear — Hard
	## took a tenth a week, Light mended a tenth — and a bout took nothing.
	if fought:
		Quartermaster.pay_sponsors(s.office, s.club.starting_five())
		bout_wear(s)

	## AND THE GROUND HAS THE SAME WEEK THE MEN DID.
	##
	## Here rather than in `_after_event`, because this is the ONE place the fought
	## path and the simmed path already converge — and the kit wear sitting two
	## lines above it is the proof that this is where a per-week cost belongs. A
	## ground that only wore out when you pressed FIGHT would be the harness bug
	## again in a second costume: skipping the week would keep your arena clean.
	s.office.arena.take_a_week(hosted, s.world.events_this_season())
	## AND THE RATING THE TABLE READS, AFTER ALL OF IT. The week's kit wear and
	## morale move the club's power, and `_after_event` synced it before they ran —
	## so every matchday left the next fixture played at last week's rating, up to
	## a point off, and a reload (which re-syncs) changed the result. Found by
	## tests/test_invariants.gd, 27 Sep 2026.
	s.sync_power()


## THE BOUT'S WEAR ON THE LINE: every man who stood in it loses BOUT_WEAR of
## his harness, scaled by his trait (KIT MINDER, ROUGH ON KIT) and by the
## grade he is wearing — better metal takes less, which is what an armorer and
## a Titanium harness are for. Fought, simmed or cup: the same five, the same
## wear. A forfeit fought nobody and wears nothing.
const BOUT_WEAR: float = 0.06


static func bout_wear(s: Season) -> void:
	for f in s.club.starting_five():
		f.armor = clampf(f.armor - BOUT_WEAR
			* FighterTrait.mod(f.trait_id, "wear", 1.0)
			* Quartermaster.wear_scale(f), 0.0, Quartermaster.ceiling(f))

static func _apply_bout_injuries(s: Season, sim: MeleeSim) -> void:
	var line := sim.lineup(0)
	for k in sim.injuries:
		var i := int(k["idx"])
		## The card that was hurt, recorded at the moment it happened — the slot
		## may hold a different man by the end of the bout.
		var hurt = k.get("card", null)
		if hurt is FighterCard and not s.club.roster.has(hurt):
			continue
		if hurt is FighterCard or (i < 5 and i < line.size()):
			var card: FighterCard = hurt if hurt is FighterCard else line[i]
			## THE REGIME'S SHARPEST EDGE. Retro Bowl lets a knock through 10% of
			## the time on Light, 20% on Normal and ALWAYS on Hard — so Hard is
			## not a bit riskier than Normal, it is five times riskier. That
			## asymmetry is what stops Hard being a free 1.5x on development.
			##
			## The roll is its own stream: an injury that consumed the world's
			## RNG would make a squad decision reshuffle the country, which is a
			## bug this project has already fixed twice.
			var roll := RandomNumberGenerator.new()
			## THE WEEK AND THE BOUT ARE IN THE SEED (3 Oct 2026). Keyed on the
			## league day alone, every tie of a cup weekend rolled the same number
			## for a man as the league bout before it: hurt in all, or in none.
			roll.seed = hash("knock:%d:%d:%d:%d:%d:%s" % [s.world.rng.seed, s.world.season,
				s.world.event, s.world.week, sim.rng.seed, card.display_name])
			## AND THE GRADE'S SHARE of it (playtest 30 Sep: too many knocks).
			if roll.randf() > s.office.regime_injury(Tuning.role_of(int(card.pos))) * s.office.knocks_scale \
					* s.office.knock_guard():
				continue
			var was := card.injury
			card.injury = maxi(card.injury,
				maxi(1, int(k["events"]) - s.office.injury_relief()
					+ int(FighterTrait.mod(card.trait_id, "injury_events", 0.0))))
			if card.injury > was:
				card.injury_kind = FighterCard.injury_for(card.injury, roll.randi())
				card.knocks += 1
				## Recorded here rather than counted off the roster afterwards:
				## `_apply_bout_injuries` is the only place that knows this knock
				## is new, and a later pass over the squad cannot tell a man hurt
				## today from a man hurt last week.
				s._note_change("knock", card.display_name,
					UiKit.tn("carried off — %s, out for %d event", "carried off — %s, out for %d events",
						card.injury) % [card.injury_word(), card.injury], -1)




static func _note_change(s: Season, kind: String, who: String, text_: String, good: int = 0) -> void:
	s.last_changes.append({"kind": kind, "who": who, "text": text_, "good": good})




static func _award_xp(s: Season, sim: MeleeSim) -> void:
	s.last_levels.clear()
	s.last_changes.clear()
	s.last_xp.clear()
	## `fought()`, not `men`: a man subbed off at the corner earned his own
	## afternoon and keeps it; the man who replaced him starts from nothing.
	for m in sim.fought():
		if m.team != 0 or m.card == null:
			continue
		if not s.club.roster.has(m.card):
			continue
		## THE REGIME'S FIRST EFFECT. Hard develops a man half again as fast and
		## Light at three fifths — Retro Bowl's own 1.5 and 0.6, applied to the
		## role he stands in because our captains cover roles.
		var role := Tuning.role_of(int(m.card.pos))
		## SPONGE and PLATEAUED ride on the same multiplier the regime and the
		## captain already use, which is the point of them being multipliers: one
		## man who learns faster is the same shape as a hard winter, at the man.
		var earned := int(round(float(Career.xp_for(m.downs_caused, m.rounds_standing, m.card.overall()))
			* s.office.regime_xp(role) * s.office.specialty_xp(role)
			* FighterTrait.mod(m.card.trait_id, "xp", 1.0) * s.coach.training_mult()))
		m.card.xp += earned
		s.last_xp[m.card] = earned
		## CEILING RAISER. A three-down afternoon is the best thing a man does all
		## season; on him it moves what he could become, not just what he is.
		if m.downs_caused >= 3 and FighterTrait.flag(m.card.trait_id, "ceiling_on_big"):
			m.card.potential = mini(99, m.card.potential + 1)
			s._note_change("trait", m.card.display_name,
				UiKit.t("Ceiling Raiser — a three-down event moved what he could become"), 1)
		## AND IF HE HAS EARNED A LEVEL, IT WAITS FOR YOU. It used to be taken here
		## automatically, into whatever stat he was worst at — which quietly made
		## it impossible to build a specialist, because every point a man earned
		## went into his weakness. The report names him; the spending is a
		## decision, and it can be made any time after.
		if Career.levels_waiting(m.card) > 0:
			s.last_levels.append({"name": m.card.display_name, "waiting": true,
				"level": m.card.level, "overall": m.card.overall()})
			s._note_change("level", m.card.display_name,
				UiKit.t("has a level waiting — spend it on his card"), 1)
		if int(m.assists) > 0:
			s._note_change("work", m.card.display_name,
				UiKit.tn("%d assist — second man on somebody else's takedown",
					"%d assists — second man on somebody else's takedown",
					int(m.assists)) % int(m.assists), 1)
		## THE BOOK, kept from the same two numbers the XP is paid on. They were
		## already being counted and already being discarded; writing them down
		## costs nothing and is the difference between a level and a career.
		m.card.bouts += 1
		m.card.downs += int(m.downs_caused)
		m.card.rounds_standing += int(m.rounds_standing)
		m.card.best_downs = maxi(m.card.best_downs, int(m.downs_caused))
		m.card.assists += int(m.assists)
		## AND THE CLUB'S BOOK, written at the moment it happens. A record
		## computed by scanning the roster would lose everything a retired man
		## ever did, which is most of the history of any club worth having one.
		s.world.note_record("downs_event", int(m.downs_caused),
			m.card.display_name, s.world.season)
		s.world.note_record("downs_career", m.card.downs, m.card.display_name, s.world.season)
		s.world.note_record("events", m.card.bouts, m.card.display_name, s.world.season)
		s.world.note_record("standing", m.card.rounds_standing,
			m.card.display_name, s.world.season)
		s.world.note_record("rating", m.card.overall(), m.card.display_name, s.world.season)

	## AND THE WEEK THAT LED UP TO IT. Every man on the books, starters included
	## — they get a quarter of a practice on top of what the afternoon paid them.
	## See `_practice`.
	## ONCE A WEEK, NOT ONCE A TIE (3 Oct 2026): a fought cup weekend of three
	## ties practised the whole roster three times; simmed, once.
	if s.practiced_week != s.world.week:
		s._practice()

	## ------------------------------------------------------- who sat, and who
	## PRIMA DONNA — *"Sours every event he does not start."*
	##
	## Everybody on the eight who was not one of the five. It runs over the club's
	## own roster and not over `sim.men`, because the men who did not play are
	## exactly the ones `sim.men` has never heard of — a loop over who fought can
	## never find who did not, which is the shape of the bug this trait would
	## otherwise have had.
	var played := {}
	for m in sim.fought():
		if m.team == 0 and m.card != null:
			played[m.card] = true
	for f in s.club.active_eight():
		if played.has(f):
			continue
		var sour := FighterTrait.mod(f.trait_id, "benched_morale", 0.0)
		if sour != 0.0:
			f.morale_shift(sour)
			s._note_change("trait", f.display_name,
				UiKit.t("Prima Donna — sat out and did not take it well"), -1)

	## TALISMAN — *"Lifts the room while he is here. Guts it when he goes."*
	##
	## The dressing room and not the field. Every in-fight version of this was
	## measured and every one was either enormous or nothing — the figures are in
	## the note on `MeleeSim._rally`. Morale is where a room trait belongs anyway:
	## it is bounded by construction, it already has measured effects all through
	## the club layer, and "lifts the room" is a sentence about a squad rather
	## than about a clinch.
	##
	## AND THE SECOND HALF IS THE POINT OF IT. While he is fit and on the eight,
	## everybody else lifts. While he is on the books and cannot go out, the same
	## men drop by half as much — that is what *guts it when he goes* means on a
	## week a club can actually see.
	for t in s.club.active_eight():
		var lift := FighterTrait.mod(t.trait_id, "room_morale", 0.0)
		if lift == 0.0:
			continue
		var here: bool = t.fit()
		for f in s.club.active_eight():
			if f == t:
				continue
			f.morale_shift(lift if here else -lift * 0.5)
		s._note_change("trait", t.display_name,
			UiKit.t("Talisman — the room is better for him being out there") if here
			else UiKit.t("Talisman — the room felt him missing"), 1 if here else -1)

	## GRUDGE — *"Fights above himself against one named club, forever."*
	##
	## Named by the first club that beats him while he is on your eight, which is
	## a thing that actually happens to people and needs no new screen. Set once
	## and never cleared: a grudge that expires is a preference.
	## WHO HE IS ANGRY AT IS WHO HE JUST FOUGHT, and that is a fact about the
	## BOUT, so the bout is what is asked. It used to ask `opponent_id()`, the
	## next name on the LEAGUE fixture list — correct on a Saturday and wrong on
	## a cup night, when `post_cup_bout` calls this same function: lose a tie to
	## Bristol and your man swore lifelong revenge on whoever you happened to
	## play next, by name, on the report.
	var beat_us := sim.opponent_club_id
	if sim.bout_winner() == 1 and beat_us >= 0 and beat_us < s.world.clubs.size():
		for m in sim.men:
			if m.team != 0 or m.card == null or m.card.grudge_club >= 0:
				continue
			if FighterTrait.mod(m.card.trait_id, "grudge", 1.0) == 1.0:
				continue
			m.card.grudge_club = beat_us
			s._note_change("trait", m.card.display_name,
				UiKit.t("Grudge — he will not forget %s") % String(
					s.world.clubs[beat_us]["name"]), -1)




## A WEEK'S PRACTICE, FOR EVERY MAN ON THE BOOKS.
##
## Until 15 Sep 2026 only `starting_five()` earned anything. Eight men travel and
## five fight: the other three and the five in reserve improved by exactly zero
## for their whole careers, so the only way to bring a twenty-year-old on was to
## start him instead of a better man and lose the season for it. There was no
## such thing as a pipeline.
##
## The first patch paid the bench a SHARE OF THE STARTERS' fight XP. That fixed
## the arithmetic and said something untrue — that a man who did not play is paid
## a fraction of an afternoon he did not have — and it left the number the club
## actually controls, the captain's stars, reaching nothing. Pete's reading is
## the right one: **the coaches hold practices.** See `Career.practice_xp`.
##
## Everything a club can do about development multiplies here and nowhere else:
## the captain's grade for the role the man stands in, the training ground, the
## regime, and the traits that touch XP. A club with two five-star captains, a
## built ground and a Hard regime develops men several times faster than a club
## with none of it — which is what a staff is FOR, and what the grade on a hire
## card has never until now been worth.
static func _practice(s: Season, paid: bool = false) -> void:
	var five := s.club.starting_five()
	## Morning decision #11's option, off unless a probe sets it.
	var full := paid and Tuning.session_full_week
	## A SEASON'S PRACTICE IS THE SAME SIZE IT WAS (30 Sep 2026). The year grew
	## from league days to Saturdays — cup rounds and the playoff are weeks now,
	## and the squad trains through every one — so a week's practice is the
	## league's share of it. Without this the calendar alone would have been a
	## 2.5x training buff that nobody chose. A paid session is not scaled: it is
	## one bought week, priced as one.
	var share := 1.0 if paid else s.practice_share()
	if not paid:
		s.practiced_week = s.world.week
	for f in s.club.roster:
		var role := Tuning.role_of(int(f.pos))
		var got := Career.practice_xp(s.office.coaching(role), five.has(f) and not full) \
			* s.office.practice_ground() * s.office.regime_xp(role) \
			* s.office.specialty_xp(role) * FighterTrait.mod(f.trait_id, "xp", 1.0) \
			* s.coach.training_mult()
		var week_xp := maxi(1, int(round(got)))
		if share >= 1.0:
			f.xp += week_xp
			continue
		## THE SHARE, ROUNDED BY A DIE THAT IS THE SAME EVERY TIME: a whole
		## number of points a week with the right average, so a bench man on
		## 0.8 of a point a week still gets his season's worth. Seeded on the
		## week and the man, not drawn from a stream, so a reload rolls the same.
		var want := float(week_xp) * share
		var whole := int(floor(want))
		var h := absi(hash("practice:%d:%d:%d:%s" % [s.seed_value, s.world.season,
			s.world.week, f.display_name]))
		f.xp += whole + (1 if float(h % 10000) / 10000.0 < want - float(whole) else 0)




## AN EXTRA SESSION, PAID FOR. See `ClubOffice.charge_session` for the price and
## the throttle; this is the work. One more week's practice for everybody, right
## now, on the same function the matchday runs — so a bought session and a free
## one cannot ever be worth different amounts, and every multiplier the club has
## applies to both.
## WHAT A PAID SESSION IS WORTH TO THE FIVE, per man, on the same sum
## `_practice` runs — shown on the button so the price has a number beside it
## (Pete, 29 Sep 2026, decision #11).
static func session_xp(s: Season) -> int:
	var five := s.club.starting_five()
	if five.is_empty():
		return 0
	var total := 0
	for f in five:
		var role := Tuning.role_of(int(f.pos))
		## THE COACH TOO (3 Oct 2026): `_practice` multiplies by him, so the
		## button quoted less than the session paid.
		var got := Career.practice_xp(s.office.coaching(role), not Tuning.session_full_week) \
			* s.office.practice_ground() * s.office.regime_xp(role) \
			* s.office.specialty_xp(role) * FighterTrait.mod(f.trait_id, "xp", 1.0) \
			* s.coach.training_mult()
		total += maxi(1, int(round(got)))
	return int(round(float(total) / float(five.size())))


static func run_session(s: Season) -> String:
	var err := s.office.charge_session()
	if err != "":
		return err
	_practice(s, true)
	return ""




static func _award_sim_xp(s: Season) -> void:
	for f in s.club.starting_five():
		f.xp += Season.XP_SIMMED
		## A simmed event is still an event he turned up to. It pays no downs,
		## because nobody watched him cause any.
		f.bouts += 1
	s._practice()




## Play the matchday without fighting it — a bye, or the player choosing to sim.
static func skip_event(s: Season) -> void:
	## NOT A LEAGUE SATURDAY: a cup round of yours is handed to the AI, and a week
	## with nothing on is a week of training.
	## A tournament week is skipped whole: every tie of yours handed over until
	## you are out or it is won and the week ends.
	if s.world.week_kind() != Calendar.Kind.LEAGUE:
		var wk := s.world.week
		var guard := 0
		while s.cup_pending() and s.world.week == wk and guard < 16:
			guard += 1
			s.sim_cup_tie()
		if s.world.week == wk and not s.world.season_complete():
			SeasonCups.end_week(s)
		return
	s.ensure_a_line()
	s._award_sim_xp()
	var opp := s.opponent_id()
	var was_home: bool = s.venue_kind() == Venue.Kind.HOME
	var gate := s.gate_now()
	var before := s._my_row()
	var was := s._my_row()
	## THE GRADE APPLIES TO A SIMMED FIXTURE TOO. See the note in
	## `LeagueWorld.play_event` — until 15 Sep 2026 the difficulty setting was
	## read only by `MeleeSim`, so pressing SIM IT fought the season at no
	## difficulty at all and five twenty-season careers at five different grades
	## came back identical.
	s.world.player_scale = s.opposition_scale(opp)
	s.world.play_week()
	s.world.player_scale = 1.0
	var now := s._my_row()
	s._after_event(int(now["rf"]) - int(was["rf"]), int(now["ra"]) - int(was["ra"]), gate)
	## AND THE WEEK STILL HAPPENED.
	##
	## `_apply_regime()` ran from `post_bout` and not from here, so a SIMMED event
	## cost no morale drift and no kit wear at all: `tools/probe_kit.gd` walked
	## twenty-four simmed events and the squad finished on exactly the harness it
	## started with. Fighting your bouts wore your armor out and skipping them
	## did not, which is a discount for not playing the game — and it is the kind
	## of asymmetry a player finds by accident and then never fights again.
	s._apply_regime(was_home)
	s._log(opp, before, false, was_home)
	s.event_played.emit(opp, [])




## A FORFEIT: the fixture is lost 0-2 with nobody standing, and the week still
## happens (the crowd came, the regime ran). No XP — nobody fought.
static func forfeit_bout(s: Season) -> void:
	var opp := s.opponent_id()
	var was_home: bool = s.venue_kind() == Venue.Kind.HOME
	var gate := s.gate_now()
	var before := s._my_row()
	s.last_result = [0, Tuning.BOUT_WINS, 0, MeleeClub.LINE_SIZE]
	s.world.play_week(s.last_result)
	s._after_event(0, Tuning.BOUT_WINS, gate)
	s._apply_regime(was_home, false)
	s._log(opp, before, false, was_home)
	s.event_played.emit(opp, [])


## Everything that happens to the club because an event happened: credits for
## the result, morale, and a week off the treatment table.
static func _after_event(s: Season, rf: int, ra: int, gate: Dictionary = {}) -> void:
	## THE CROWD IS PAID FIRST, and it is paid whatever the result. A fight in
	## front of a house that knows who you are is worth money because it was
	## watched, not because it was won — that is the whole point of banding it.
	## The result then pays on top, so a win in a big year is worth a great deal
	## more than the same win was worth in a small one.
	##
	## Note the ORDER: the pay is read BEFORE `after_event` moves the following, so
	## the fight pays the band the club had when it walked out. Paying after
	## would let a single win push a club over a gate and then pay the new band
	## for the fight that crossed it, which is a half-band of free money on every
	## crossing and reads as a bug the first time a player notices it.
	## AND THE GATE IS ONLY YOURS AT HOME — Pete, 14 Sep 2026. A club that took
	## its gate on the road is a club with no reason to build an arena, which is
	## the whole of the Arena screen. `Venue.pays_the_gate` is the one place that
	## rule lives, so a second earner added next year cannot quietly disagree
	## with it.
	## THE GATE IS PAID WHEREVER THE FIGHT WAS, at a share set by the venue and
	## multiplied by the ground it was fought in. It used to be home-only, which
	## made two thirds of a season's fixtures worth nothing at all — see the long
	## note over `Venue.gate_share`.
	var g := gate if not gate.is_empty() else s.gate_now()
	s.office.take(int(g["cc"]), UiKit.t("The gate  ·  %s") % UiKit.t(String(g["where"])), "event",
		ClubOffice.LINE_GATE)
	## AND THE COUNTER, AT HOME ONLY. It is your bar or it is not.
	##
	## Pete, 15 Sep 2026: *"Stadium damper could be food sales. Lemonade, bakery,
	## brownies for back yard, progressing to real NFL beer sales and stuff at
	## higher tiers."*
	##
	## THIS IS THE DAMPER AND THE DAMPING IS THE POINT. The gate reads the band and
	## swings with form; the counter reads the turnstile and does not. A club that
	## loses in front of a full house still sold them all a pint, so a bad season
	## at a well-attended ground is a bad season rather than a crisis — which is
	## exactly what Retro Bowl's stadium does for them, in a shape that belongs to
	## this sport instead of theirs.
	if int(g["kind"]) == Venue.Kind.HOME:
		var heads := s.office.attendance()
		s.office.take(Arena.counter_take(s.office.arena.level, heads),
			UiKit.t("The counter  ·  %s") % Arena.sells(s.office.arena.level), "event",
			ClubOffice.LINE_COUNTER)
	if rf > ra:
		Achievements.unlock("FIRST_WIN")
		s.office.take(Season.CREDITS_WIN, UiKit.t("Won the event"), "event", ClubOffice.LINE_PRIZE)
		s.office.morale_after(true, false)
	elif rf == ra:
		s.office.take(Season.CREDITS_DRAW, UiKit.t("Drew the event"), "event", ClubOffice.LINE_PRIZE)
		s.office.morale_after(false, true)
	else:
		s.office.morale_after(false, false)
	## THE RESULT LANDS ON EVERY MAN, and then the difficult ones land on
	## everybody else.
	##
	## Retro Bowl's own tip: *"Toxic players bring down the attitudes of team
	## mates after a loss."* That is what makes a toxic man a decision rather
	## than a bad stat — he is fine while you are winning.
	var won: bool = rf > ra
	var drew: bool = rf == ra
	var swing := ClubOffice.MORALE_WIN if won else (0.0 if drew else ClubOffice.MORALE_LOSS)
	swing += s.office.ground_morale()
	## THE COACH'S MOTIVATION takes the edge off a loss, 10% a star.
	if swing < 0.0:
		swing *= s.coach.morale_loss_mult()
	## THE MOOD, BEFORE AND AFTER, PER MAN. The swing is the same for everybody
	## and the WORD is not — `morale_shift` is a logistic, so the same nudge moves
	## a contented man a little and a struggling one a lot, and the report is
	## about the men who crossed a band rather than about the number.
	var before := {}
	for f in s.club.active_eight():
		before[f] = f.morale_word()
	for f in s.club.active_eight():
		f.morale_shift(swing)
	for f in s.club.active_eight():
		if f.morale_word() != String(before[f]):
			s._note_change("mood", f.display_name,
				"%s to %s" % [String(before[f]).to_lower(),
					f.morale_word().to_lower()],
				1 if f.morale > 0.5 else -1)
	if not won and not drew:
		## LIKEABLE. *"Toxic players ($pos) have no negative impact on teammates."*
		## A captain who is good to be around does not fix the difficult man — he
		## still fights angry, he still costs you nothing on a win — he just stops
		## him taking the room down with him. So the trait is read PER TOXIC MAN,
		## against the role that man stands in, rather than as a club-wide switch:
		## your Rail captain cannot cover for a poisonous Center.
		## POISON counts double and THICK SKIN does not count at all — one on each
		## side of the same sum, which is the same shape as Bear against Anchor and
		## for the same reason: a club can field both and have them cancel.
		var poison := 0.0
		for f in s.club.active_eight():
			if f.toxic() and not s.office.trait_covers(
					ClubOffice.Trait.LIKEABLE, Tuning.role_of(int(f.pos))):
				poison += FighterTrait.mod(f.trait_id, "toxic_weight", 1.0)
		if poison > 0.0:
			for f in s.club.active_eight():
				if f.toxic() or FighterTrait.flag(f.trait_id, "immune_toxic"):
					continue
				f.morale_shift(Season.TOXIC_DRAG * poison)
	s.office.sync_morale(s.club)
	for f in s.club.roster:
		if f.injury > 0:
			f.injury -= 1
	## The following moves with the result, and then the show goes on if it is
	## due. In that order, because a tournament is drawn against the standing you
	## have on the day of it.
	s.office.after_event(rf > ra, rf == ra)
	## AND IT GOES IN YOUR BOOK TOO. The club's record is the club's; this one
	## follows you out of the door when you take another job, which is the only
	## reason to keep a second copy of the same three numbers.
	s.coach.note_result(rf > ra, rf == ra)
	if s._event_due():
		s._settle_event()
	s._draw_dilemma()
	## A NEW WEEK. The throttle that lets a club work on each building once per
	## matchday is cleared here, so "a week" means the same thing to the Clubhouse
	## as it does to the fixture list — see ClubOffice.new_week.
	s.office.new_week()
	s._roll_availability()
	s.sync_power()
	s.sync_week()




## THE RESULT, ON THE MEN (3 Oct 2026). The club figure is an average of the
## eight and `sync_morale` rebuilds it from them, so a swing given only to
## `office.morale` was gone by the next event. Cup results and dilemma cards
## come through here; the league result has its own fuller version above.
static func room_shift(s: Season, swing: float, soften: bool = true) -> void:
	if swing < 0.0 and soften:
		swing *= s.coach.morale_loss_mult()
	for f in s.club.active_eight():
		f.morale_shift(swing)
	s.office.sync_morale(s.club)


static func result_swing(s: Season, won: bool, drew: bool) -> float:
	return (ClubOffice.MORALE_WIN if won else (0.0 if drew else ClubOffice.MORALE_LOSS)) \
		+ s.office.ground_morale()


## A HURT MAN DOES NOT HOLD A SEAT (3 Oct 2026). He cannot fight, so he comes
## off the bus altogether — even with no reserve to replace him (Pete: "take him
## off and create an 'Injured' section"). A reserve takes his seat, fit first;
## `ensure_a_line` signs walk-ons only when that still leaves no five.
static func rest_the_injured(s: Season) -> Array[String]:
	var out: Array[String] = []
	for f in s.club.rest_injured(true):
		out.append(UiKit.t("%s travels in place of the injured") % f.display_name)
	s.sync_power()
	return out


static func _roll_availability(s: Season) -> void:
	## A FRESH STREAM PER WEEK, seeded on the week, rather than a draw from the
	## season-long roster stream.
	##
	## It used `_roster_rng()` at first, which is a stateful stream whose POSITION
	## is not saved — it is rebuilt from the world seed and the season number on
	## demand. The winter drew from it once a year and nothing noticed. Drawing
	## from it every week meant a reloaded save restarted the stream from the
	## beginning, rolled different men unavailable, and the two worlds came apart:
	## `the world continues the same` went red, which is exactly the check that
	## exists to catch a save carrying less state than the game is using.
	##
	## Seeding on (season, event) removes the state instead of saving it. Same
	## answer every time, no position to keep.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("avail:%d:%d:%d" % [s.world.rng.seed, s.world.season, s.world.week])
	var gone := 0
	for f in s.club.roster:
		## LAST WEEK'S EXCUSE IS OVER. Cleared for everybody first, including the
		## men who were out, so this is a state of one weekend and not a flag that
		## accumulates until the squad is all crosses.
		f.available = true
	for f in s.club.active_eight():
		if gone >= Season.AVAILABILITY_MAX:
			break
		## A man already out with a knock does not also need the weekend off. The
		## two would read as one problem on the screen and cost twice.
		if f.injury > 0:
			continue
		if rng.randf() < Season.AVAILABILITY_CHANCE:
			f.available = false
			gone += 1




## THE YEAR ADDED UP — every week fought, not the handful a screen has room for.
##
## It lives here rather than in the review page because a total computed inside a
## `_draw()` is a total nothing can check, and because the page shows the last
## nine rows: *a total of what happens to be on screen is not a total.* The
## screen slices; the season counts.
static func year_summary(s: Season) -> Dictionary:
	var fought := 0
	var simmed := 0
	var rf := 0
	var ra := 0
	var diff := 0
	var byes := 0
	for r in s.results:
		if bool(r.get("bye", false)):
			byes += 1
			continue
		if bool(r.get("fought", true)):
			fought += 1
		else:
			simmed += 1
		rf += int(r.get("rf", 0))
		ra += int(r.get("ra", 0))
		diff += int(r.get("margin", 0))
	return {
		"events": fought + simmed, "fought": fought, "simmed": simmed,
		"byes": byes, "rf": rf, "ra": ra, "diff": diff,
	}




static func _my_row(s: Season) -> Dictionary:
	return (s.world.tables[s.world.player_tier()][s.world.player_club] as Dictionary).duplicate()




## `at_home` IS PASSED IN, NOT ASKED FOR, and that is not fussiness.
##
## Both callers run this AFTER `world.play_event()` has ticked the week, so
## `venue_kind()` in here would answer about the NEXT fixture — the club would
## log every away day as a home one whenever the following week happened to be
## at home. It is the identical mistake `post_bout` already carries a note about
## for `opponent_id()`, three lines further up the same function, and it would
## have been invisible until somebody read a season review and wondered why the
## club never travelled.
static func _log(s: Season, opp: int, before: Dictionary, fought: bool, at_home: bool) -> void:
	if opp == -1:
		s.results.append({ "opponent": -1, "bye": true, "fought": false })
		return
	var now := s._my_row()
	s.results.append({
		"opponent": opp, "bye": false, "fought": fought,
		"rf": int(now["rf"]) - int(before["rf"]),
		"ra": int(now["ra"]) - int(before["ra"]),
		"margin": League.margin_diff(now) - League.margin_diff(before),
		## HOW IT WAS FOUGHT, not just that it was.
		##
		## Pete, 14 Sep 2026, on a losing career: *"which can be turned around by
		## spending CC currency, bringing the difficulty down, or just fighting
		## better/smarter."* He is right, and dropping the grade when a season
		## goes bad is a real lever that should stay — Retro Bowl's own season
		## review carries a `Diff` column on every week for exactly that reason.
		##
		## So the record remembers. A row that says the club won its division
		## while fighting FRIENDLY is a different row from one that says it won
		## the same division on THE HARD LIST, and a cabinet that cannot tell
		## them apart is a cabinet that is not really keeping score.
		##
		## MATCHED carries its step too, because MATCHED is not one difficulty —
		## it is a dial the season moves under the player, and "Matched 7" and
		## "Matched 2" are further apart than two of the fixed grades.
		"grade": s.grade,
		"step": s.matched_step,
		"home": at_home,
	})
