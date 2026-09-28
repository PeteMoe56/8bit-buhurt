class_name SeasonWinter
extends RefCounted
## Methods of `Season`, moved out of season.gd so that file is not one
## three-thousand-line object. Every function takes the Season as `s`; `Season`
## keeps a one-line wrapper for each, so callers did not change.




static func roll_over(s: Season) -> void:
	s.results.clear()
	s.last_winter = {"gained": 0, "lost": 0, "retired": [], "prospect": "",
		"walked": [], "signed": []}
	## A NEW SUMMER IS A NEW MARKET. The pool is keyed on the season number, so
	## clearing this is what opens it — and it has to happen before `world.season`
	## advances or the list the player was looking at yesterday stays closed.
	s.market_taken.clear()
	var before := s.world.player_tier()
	var finished := s.position()
	s.world.roll_over()
	## THE ANSWER IS SPENT. Both flags reset here rather than at the start of the
	## next season, because `roll_over()` is the only thing that consumes them and
	## a flag cleared anywhere else is a flag that survives a save and declines a
	## promotion nobody was offered.
	s.world.stay_down = false
	s.promotion_answered = false
	s.sync_power()
	var after := s.world.player_tier()
	## The summer: prize money, the gate from hosting, and the winter's training.
	## THE PURSE IS PAID ON THE DIVISION THE CLUB JUST LEFT, not the one it is
	## about to join. `finished` and `before` were both taken above `world.roll_over()`
	## for exactly this reason: a promoted club that was paid at its NEW tier
	## would take a champion's share of a division it has not played a fight in.
	if finished >= 1:
		s.office.take(Season.purse(finished, League.club_count(before), before),
			"Finished %s" % UiKit.ordinal(finished), "season", ClubOffice.LINE_PRIZE)
	if after > before:
		s.office.take(Season.CREDITS_PROMOTED, "Went up", "season", ClubOffice.LINE_PRIZE)
		s.office.after_move(true)
	elif after < before:
		s.office.after_move(false)
	s.office.take(s.office.gate_income(), "A season of gates", "season",
		ClubOffice.LINE_GROUND)
	## THE DUES. Banked before the bills, because that is what they are for — the
	## members' money is the income that does not move with results, and it is
	## the money the federation's bill is actually competing for.
	## THE FEDERATION'S BILL, AND IT GOES THE OTHER WAY NOW.
	##
	## This line used to READ `office.take(office.dues(), "Members' dues")` and it
	## was the biggest single earner in the game — 24.4 credits a season across a
	## career, 58% of everything the club made, from a standing subscription. Pete,
	## 15 Sep 2026: *"I'm not liking the dues portion, that should more be a league
	## dues at the start of a season, one in which you CAN go negative but it's a
	## good bite."*
	##
	## CHARGED HERE, at the roll-over, rather than at the first fixture — because
	## the roll-over is where the division is decided and the bill is for the
	## division you are about to enter. `office.tier` has already been set by
	## `_apply_regime`'s caller below; this runs after the promotion choice is
	## settled, so a club that stayed down pays the cheaper bill it stayed down for.
	##
	## AND IT IS ALLOWED TO GO NEGATIVE. `spend()` does not check, deliberately —
	## every other caller checks first and this one must not, because a bill you
	## can decline is not a bill. See `ClubOffice.in_the_red()`.
	s.office.spend(League.dues_for(s.office.tier), ClubOffice.LINE_FEDERATION)
	## AND THEN THE BILLS. Deliberately after the retainer and the prize money and
	## deliberately before the training: a club should be paid for the year it had
	## and then asked what it costs to keep what it owns, in that order, because
	## that is the order a player reasons about it in. Anything it cannot cover
	## sheds a level — see ClubOffice.pay_upkeep.
	s.last_upkeep = s.office.pay_upkeep()
	## The summer: people forget, and a following bleeds if it is not fed.
	s.office.winter()
	## THE STAFF ARE ON DEALS TOO, and a captain whose contract ran out has gone
	## before the winter's training rather than after it — the roles he taught are
	## untaught for that winter, which is the cost of having let it lapse.
	s.last_staff_left = s.office.age_captains()
	s._train()
	## AND THE MEN AT THEIR CEILING CASH IN. Retro Bowl's rule — *"maxed players
	## convert further level-ups into credits"* — and the reason to take it is
	## that the alternative is throwing away every point of XP a veteran earns
	## for the rest of his career. See `Career.cash_in`.
	s.last_cashed = 0
	for f in s.club.roster:
		var got := Career.cash_in(f)
		if got > 0:
			s.last_cashed += s.office.take(got, "%s passing it on" % f.display_name,
				"season", ClubOffice.LINE_SQUAD)
	for f in s.club.roster:
		f.injury = 0            ## nobody carries a knock across a winter
	s.sync_power()

	## THE BID IS PART OF THE SUMMER. New division, new calendar, new dates — and
	## a promoted club is offered a longer season with later, dearer slots in it.
	s.open_bids()

	## WHAT THE YEAR DID TO YOUR NAME. After the club's summer, because a
	## reputation is read off where the club finished and the club has to have
	## finished first.
	##
	## `finished` was taken before `world.roll_over()` — the table is rebuilt in
	## there — so it is the position you actually came, not the one you start the
	## new season in. Getting those two the wrong way round would have paid a
	## promoted club for finishing first in a division it had already left.
	s.coach.after_division(finished, before)
	## AND WHAT THE CUPS DID. Every bracket that resolved this year and had you in
	## it pays by how far you went — the size of the round you went out in, which
	## is the key `Coach.REP_BY_CUP_EXIT` is written on.
	##
	## EACH CUP IS COUNTED ONCE, WHENEVER IT ENDED. This used to ask for honours
	## labelled `world.season` — but `world.roll_over()` above has already moved
	## the season on, so no Invitational was ever counted and a Worlds (which
	## ends in the following year) was counted a year late. Now every honour
	## carries a `counted` flag and the summer pays for the ones not yet paid.
	var won_cup := false
	for h in s.honors():
		if bool(h.get("counted", false)):
			continue
		h["counted"] = true
		var exit_size := int(h.get("exit", -1))
		if exit_size > 0:
			s.coach.after_cup(exit_size)
		if int(h.get("champion", -1)) == s.world.player_club:
			won_cup = true
	s.coach.note_season(after > before, after < before, won_cup)

	## AND THEN THE CLUB MAY COME APART. Last, after everything else the summer
	## does, because a squad that is about to lose half its men should still have
	## been paid, trained and aged first — the men who walk take the winter they
	## earned with them, which is what makes the rival dangerous rather than a
	## collection of last year's numbers.
	## WHO STAYED AND WHO WALKED, and it moves the FOLLOWING now rather than a
	## membership roll of its own.
	##
	## `members` is gone — the third of three populations all answering the same
	## question, and the one whose only output was a subscription the club no
	## longer collects. What it reacted to was always right, though: a season in
	## the top half, a room worth being in, a club that can fill its own bus. So
	## those three keep moving people; they move the one population that is left.
	##
	## NOT compliance — see the note at the top of `Federation`. People leaving
	## over paperwork would make both masters want the same thing and collapse the
	## pillar into one slider.
	var bench_full: bool = s.club.active_eight().size() >= s.office.travel_slots
	var was_fans := s.office.fans
	s.office.fans = Federation.following_after(s.office.fans, s.office.fan_cap(),
		finished <= int(League.club_count(before) / 2), s.office.morale, bench_full)
	s.last_members = {"was": was_fans, "now": s.office.fans}

	## THE BREAKAWAYS HAVE A WINTER TOO — before a new one can form, so a club
	## founded this summer starts as the men who walked.
	s._winter_the_splinters()
	s.last_split = s._maybe_split(finished, before, after)

	## AND THE BOOKS CLOSE. LAST, after every summer payment and every summer
	## bill, so `books_last` is a WHOLE year — the gate, the prize money, the
	## retainer, the dues, the upkeep and the paperwork — rather than the twelve
	## matchdays plus whichever half of the summer happened to run first.
	##
	## The finances page reads it against the year in progress, and **a column
	## made of two halves of two different years is the most misleading number a
	## ledger can print.**
	s.office.close_books()

	var h: Dictionary = s.world.history[s.world.history.size() - 1] if not s.world.history.is_empty() else {}
	s.season_finished.emit(int(h.get("position", -1)), after > before, after < before)




static func _maybe_split(s: Season, place: int, tier_before: int, tier_after: int) -> Dictionary:
	var field: int = League.club_count(tier_before)
	if not ClubSplit.fractures(s.office.morale, place, field, tier_after < tier_before,
			s.world.season):
		return {}

	## WHO THEY TAKE. The men who have actually been fighting are the ones with a
	## reason to stay, so the lineup the player has been picking all season is
	## half of the input — see `ClubSplit.who_walks`.
	var picked: Array = s.club.active_eight()
	var leaving: Array = ClubSplit.who_walks(s.club.roster, picked)
	if leaving.is_empty():
		return {}

	## WHERE THEY GO. The pyramid has a fixed number of clubs per division and
	## the fixture list is built off that count, so a breakaway cannot simply be
	## appended — a seventh club in a six-club division breaks every table in the
	## world. They take over the weakest club in your own division instead, which
	## is also what actually happens: a breakaway group does not build a club from
	## nothing, it absorbs one that was already dying.
	##
	## And it has to be YOUR division, because the direction document is specific
	## about the payoff: *"a rival club across town that you now have to fight."*
	var victim := -1
	var worst := 1 << 30
	for cid in s.world.clubs_in(s.world.player_tier()):
		if cid == s.world.player_club:
			continue
		var p := int(s.world.clubs[cid]["power"])
		if p < worst:
			worst = p
			victim = cid
	if victim < 0:
		return {}

	var rng := RandomNumberGenerator.new()
	rng.seed = hash("split:%d:%d" % [s.seed_value, s.world.season])
	var parent := String(s.world.clubs[s.world.player_club]["name"])
	var new_name := ClubSplit.name_for(parent, rng)

	## Move the men. `cut` is not used: they are not being released, they are
	## walking, and the morale consequences of a cut would be nonsense here — the
	## room they would lift is the room that just emptied.
	var took: Array[String] = []
	var carried: Array = []
	for f in leaving:
		s.club.roster.erase(f)
		## THEY ALL TRAVEL NOW. The men who walk are, by construction, the ones who
		## were not being picked — so most of them arrive carrying `active = false`
		## from the squad they just left. Founding the rival without clearing that
		## produced a club whose entire line was WALK-ONS while the five men who
		## actually walked sat in its reserve: a breakaway that fielded strangers,
		## which is the one thing this system exists not to do.
		##
		## It passed every check I had written, because "can the rival field five"
		## was true — it just was not fielding any of them. What caught it was a
		## note printing `active_eight().size()` as 0 next to a sentence saying the
		## club was made of these men.
		f.active = true
		carried.append(f)
		took.append(f.display_name)

	## THE RIVAL IS THOSE MEN. Any slots they cannot fill are walk-ons at the
	## division's floor, so a breakaway of six is a real club and not a forfeit.
	var typed: Array[FighterCard] = []
	for f in carried:
		typed.append(f)
	var rival := MeleeClub.build(new_name, ClubSplit.short_for(new_name),
		Color(0.55, 0.16, 0.16), Color(0.9, 0.85, 0.7), 0, typed)
	rival.travel_cap = MeleeClub.ACTIVE_SIZE
	var guard := 0
	## `starting_five()` does not pad with nulls when it comes up short — it
	## returns a SHORT array and says so by its size. Asking it `.has(null)` is a
	## question it can never answer yes to, so this loop never ran and the
	## breakaway club was whatever the split left it, line or no line.
	while rival.starting_five().size() < MeleeClub.LINE_SIZE and guard < MeleeClub.SQUAD_MAX:
		guard += 1
		var w := ClubFactory.walk_on(rng, s._missing_slot(rival), s.world.player_tier())
		if rival.sign(w) != "":
			break
		w.active = true

	s.world.clubs[victim]["name"] = new_name
	s.world.clubs[victim]["short"] = ClubSplit.short_for(new_name)
	s.world.clubs[victim]["power"] = rival.power()
	s.world.clubs[victim]["splinter"] = true
	s._clubs[victim] = { "club": rival, "power": rival.power() }
	## THE WHOLE CLUB, NOT THE MEN WHO WALKED.
	##
	## `carried` is the breakaway itself — the men who left you — and storing
	## only those was right up until the loop above started running. It fills the
	## line with walk-ons, and those walk-ons are part of the club from that
	## moment on: they are in `rival`, they are in `rival.power()`, and that power
	## is what the whole league table is built on.
	##
	## They were not in the save. So a reloaded career rebuilt the breakaway from
	## the carried men ALONE — and a breakaway of three cannot field five, which
	## made its power zero and handed the player a walkover he had not earned. The
	## bout that decided his season came out 0-2 in a game played straight
	## through and 2-1 in the same game reloaded, and the divergence spread from
	## there through the table, the drift and his own development.
	##
	## What the save has to carry is the CLUB, because the club is what plays.
	var whole: Array[FighterCard] = []
	for f in rival.roster:
		whole.append(f)
	s.splinter_rosters[victim] = whole

	## And the club you have left has to be able to field five. `_fill_squad`
	## already knows how to sign walk-ons at the position that is actually
	## missing, so the recovery goes through the same road as a bad winter.
	var replacements := s._fill_squad()
	s.sync_power()
	s.office.sync_morale(s.club)

	return {
		"club": new_name, "id": victim, "took": took,
		"replacements": replacements, "season": s.world.season,
	}




## Which line slot a club is thinnest at. Used when a breakaway is short.
##
## It used to look for a null in `starting_five()` — which never holds one (it
## returns a SHORT array instead) — so every walk-on it asked for was a Center.
static func _missing_slot(s: Season, c: MeleeClub) -> int:
	return s._thinnest_slot(c)




static func _thinnest_slot(s: Season, c: MeleeClub) -> int:
	var eight := c.active_eight()
	var worst := int(Tuning.Pos.CENTER)
	var fewest := 99
	for slot in 5:
		var n := 0
		for f in eight:
			if f.fit() and Tuning.covers(int(f.pos), slot):
				n += 1
		if n < fewest:
			fewest = n
			worst = slot
	return worst




## A BREAKAWAY IS MADE OF MEN, AND MEN AGE. Every other CPU club is a rating that
## drifts; a splinter is a stored roster, and it sat frozen — nobody aged,
## trained or retired, while `_drift_ratings` moved the number the table sims
## used. Its table results and its bouts against you slowly stopped describing
## the same club. Now it has the same winter as yours (coached, no ground), loses
## its retirees, tops its line up with walk-ons at its own division's level, and
## its power is read back off the men.
static func _winter_the_splinters(s: Season) -> void:
	for key in s.splinter_rosters.keys():
		var id := int(key)
		if id < 0 or id >= s.world.clubs.size() or id == s.world.player_club:
			continue
		var rival := s.club_for(id)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash("splinter-winter:%d:%d:%d" % [s.seed_value, s.world.season, id])
		for f in rival.roster.duplicate():
			Career.winter(f, true, 0)
			if rng.randf() < Career.retire_chance(f, 0.7):
				rival.roster.erase(f)
		var guard := 0
		while rival.starting_five().size() < MeleeClub.LINE_SIZE and guard < MeleeClub.SQUAD_MAX:
			guard += 1
			var w := ClubFactory.walk_on(rng, s._thinnest_slot(rival),
				maxi(0, int(s.world.clubs[id]["tier"])))
			if rival.sign(w) != "":
				break
			w.active = true
		var whole: Array[FighterCard] = []
		for f in rival.roster:
			whole.append(f)
		s.splinter_rosters[id] = whole
		s.world.clubs[id]["power"] = rival.power()
		s._clubs[id] = {"club": rival, "power": rival.power()}



static func _train(s: Season) -> void:
	s._ground_used = 0
	var points := s.office.training_points()
	var pool: Array = s.club.roster.duplicate()
	pool.sort_custom(func(a, b): return a.overall() < b.overall())

	## THE PROSPECT, banked during the season and cashed here. One man, once a
	## year, and only with a Training ground built up to take it — the one scarce
	## way a ceiling moves.
	if s.prospect != null and s.club.roster.has(s.prospect) \
			and s.office.level(ClubOffice.Facility.TRAINING) >= Career.PROSPECT_GROUND:
		s.prospect.potential = mini(Career.POTENTIAL_CEILING,
			s.prospect.potential + Career.PROSPECT_GAIN)
		s.last_winter["prospect"] = s.prospect.display_name
	s.prospect = null

	## The ground's points are handed out round-robin from the bottom, and this
	## is the share each man may take out of the pool. Working out the share
	## first rather than looping a shared counter keeps `Career.winter` a pure
	## function of one fighter — it was a shared counter, and a lambda capturing
	## it by value was exactly the kind of bug this codebase has already paid
	## for twice.
	## CAPPED BY HEADROOM, AND THE REMAINDER COMES BACK.
	##
	## This used to hand points round-robin with no regard for how much room a
	## man had left, so a Training ground advertising "15 points a winter" with
	## three eligible men each one point under potential allotted five each,
	## spent three, and SILENTLY BURNED TWELVE — while the winter report said
	## "gained 3" and the Clubhouse went on promising fifteen.
	##
	## A man already at his ceiling is also included now if age is about to take
	## something off him: the decline happens inside `Career.winter`, after this
	## share is worked out, and it opens room that the old filter had already
	## refused him.
	var budget := points
	var eligible: Array = []
	for f in pool:
		if not s.office.taught(Tuning.role_of(int(f.pos))):
			continue
		if f.overall() < f.potential or Career.will_decline(f):
			eligible.append(f)
	var share := {}
	var i := 0
	var guard := 0
	while points > 0 and not eligible.is_empty() and guard < 4096:
		guard += 1
		var f: FighterCard = eligible[i % eligible.size()]
		i += 1
		var room: int = maxi(0, f.potential - f.overall())
		if Career.will_decline(f):
			room += 1
		if int(share.get(f, 0)) >= room:
			## Everyone full? Stop rather than spin.
			var any := false
			for g in eligible:
				var r2: int = maxi(0, g.potential - g.overall())
				if Career.will_decline(g):
					r2 += 1
				if int(share.get(g, 0)) < r2:
					any = true
					break
			if not any:
				break
			continue
		share[f] = int(share.get(f, 0)) + 1
		points -= 1

	var retired: Array[String] = []
	var gained := 0
	var lost := 0
	for f in s.club.roster.duplicate():
		var coached := s.office.taught(Tuning.role_of(int(f.pos)))
		var r := Career.winter(f, coached, int(share.get(f, 0)))
		gained += int(r["gained"])
		lost += int(r["lost"])
		s._ground_used += int(r["ground"])
		## RETIREMENT IS ROLLED AFTER THE WINTER, on the man he has become. A
		## fighter who just lost three points to age is likelier to go than the
		## one he was in October, which is the order it happens in real life and
		## the only order in which `retire_chance` can read a current card.
		if s._roster_rng().randf() < Career.retire_chance(f, s.office.morale):
			retired.append("%s (%d)" % [f.display_name, f.age])
			s.club.roster.erase(f)
	## WHAT THE GROUND DID NOT MANAGE TO SPEND goes round again, among the men
	## still on the books after the retirements — post-decline, so the room the
	## winter just opened is usable.
	var spare := budget - s._ground_used
	var pass_guard := 0
	while spare > 0 and pass_guard < 64:
		pass_guard += 1
		var spent_this_pass := 0
		for f in s.club.roster:
			if spare <= 0:
				break
			if not s.office.taught(Tuning.role_of(int(f.pos))):
				continue
			var used := Career.train_only(f, 1)
			spare -= used
			spent_this_pass += used
			gained += used
		if spent_this_pass == 0:
			break
	s.last_winter["points"] = budget
	s.last_winter["unspent"] = maxi(0, spare)
	s.last_winter["gained"] = gained
	s.last_winter["lost"] = lost
	s.last_winter["retired"] = retired
	s.last_winter["walked"] = s._settle_contracts()
	s.last_winter["signed"] = s._fill_squad()
	s.sync_power()




## EVERY DEAL LOSES A YEAR, AND THE MEN WHO RAN OUT LAST SUMMER WALK.
##
## The two-stage shape is the whole feature. A deal reaching zero does not remove
## anybody — it puts him OUT OF CONTRACT, which is a state the player can see on
## the team sheet and do something about for a whole season. Only a man who was
## already out of contract, and whom nobody re-signed, actually leaves.
##
## Without that stage the player loses fighters to a number he was never shown
## changing, which is the same class of failure as a squad that quietly shrinks
## over a summer. With it, losing somebody is a decision he made by not making
## one — which is a fair thing for a game to do to you.
##
## WHETHER HE WAITS is rolled rather than certain, and rolled against the club's
## NOTORIETY: a fighter will hang on for a club people have heard of, and a good
## fighter at a club nobody has heard of will not. That is the arena system
## reaching a roster decision, which is the kind of connection that makes two
## features into one game.
static func _settle_contracts(s: Season) -> Array[String]:
	var walked: Array[String] = []
	var band: Array = League.TIERS[s.world.player_tier()]["power"]
	## Anyone who spent the whole of last season out of contract is decided
	## first, on the deal he had BEFORE this summer's tick — otherwise a man
	## signed in year one would be given a year of grace he never earned.
	for f in s.club.roster.duplicate():
		if f.years > 0:
			continue
		var wait := Contracts.will_wait(f, s.office.pull(), int(band[1]), s.office.morale)
		if s._roster_rng().randf() > wait:
			walked.append("%s (%d)" % [f.display_name, f.overall()])
			s.club.roster.erase(f)
	Contracts.age_deals(s.club.roster)
	return walked




## NOBODY TURNS UP TO AN EVENT WITH SEVEN MEN. Retirements land at the winter and
## they can leave the traveling eight short, or — after a bad run of them — leave
## the club unable to cover all five positions at all. That failure would not
## surface until the player was standing at the next event wondering why the
## Fight button was refusing him.
##
## Reserves come up first, because a club promotes from within before it phones
## round. Only when the books themselves are short does a walk-on get signed, and
## he is signed at the position that is actually missing rather than at whatever
## the generator felt like — see ClubFactory.walk_on.
##
## Returns the names taken on, so the summer can say so out loud.
static func _fill_squad(s: Season) -> Array[String]:
	var took: Array[String] = []
	while s.club.active_eight().size() < s.club.party_size():
		var up: FighterCard = null
		for f in s.club.reserves():
			up = f
			break
		if up == null:
			break
		up.active = true

	## THE PARTY GOES BACK TO FULL, not just to a line. The first pass signed
	## walk-ons only while the club could not fill a line, so a squad that
	## retired down to six men kept traveling with six: legal on the day, and a
	## club whose bench was one knock from being unable to fight. A 25-season
	## probe run found it as a roster of FIVE, which is the state that rule
	## allows and nobody would ever choose.
	var guard := 0
	while s.club.active_eight().size() < s.club.party_size() and guard < MeleeClub.SQUAD_MAX:
		guard += 1
		var w := ClubFactory.walk_on(s._roster_rng(), s._uncovered_slot(), s.world.player_tier())
		if s.club.sign(w) != "":
			break
		w.active = true
		took.append("%s (%s, %d)" % [w.display_name, w.pos_name(), w.overall()])
	return took




static func ensure_a_line(s: Season) -> Array[String]:
	s.last_emergency = []
	## The travel cap first: the party is the first N active men in roster
	## order, and N is the office's, not whatever the club was last built with.
	s.sync_power()
	if s.club.starting_five().size() >= MeleeClub.LINE_SIZE:
		return s.last_emergency
	for f in s.club.reserves():
		if s.club.starting_five().size() >= MeleeClub.LINE_SIZE:
			break
		if not f.fit():
			continue
		var out_man: FighterCard = null
		for a in s.club.active_eight():
			if not a.fit():
				out_man = a
				break
		if out_man != null:
			out_man.active = false
		f.active = true
		s.last_emergency.append("%s travels in place of the injured" % f.display_name)
	## Its own stream, keyed on the matchday: the roster stream is not saved, and
	## a mid-season draw from it would come out differently after a reload.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("emergency:%d:%d:%d" % [s.seed_value, s.world.season, s.world.event])
	var guard := 0
	while s.club.starting_five().size() < MeleeClub.LINE_SIZE and guard < MeleeClub.LINE_SIZE:
		guard += 1
		var w := ClubFactory.walk_on(rng, s._uncovered_slot(), s.world.player_tier())
		if s.club.sign(w) != "":
			break
		## If the party is full of injured men, one of them stays home for him.
		if s.club.active_eight().size() >= s.club.party_size():
			for a in s.club.active_eight():
				if not a.fit():
					a.active = false
					break
		w.active = true
		s.last_emergency.append("%s signed as an emergency walk-on" % w.display_name)
	if not s.last_emergency.is_empty():
		s.sync_power()
	return s.last_emergency




## Which place on the line the eight cannot fill. Counted by who COVERS the slot
## rather than who is listed for it, so a club short of a Center is not handed a
## second Rail on the grounds that the Rail slot has one man in it.
static func _uncovered_slot(s: Season) -> int:
	return s._thinnest_slot(s.club)
