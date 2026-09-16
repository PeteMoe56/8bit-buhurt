class_name SaveGame
extends RefCounted
## Saving, and the reason it is written by hand.
##
## Everything in this game is deterministic from seeds and ids, so a save is a
## small dictionary rather than a snapshot of the world. `ResourceSaver` on the
## fighter cards would have been fewer lines and would have welded the save
## format to Godot's Resource serialisation, which changes between versions and
## is unreadable when a player's save breaks. This writes what it means.
##
## **The RNG STREAM is saved, not just the seed.** A world reloaded with a fresh
## RandomNumberGenerator resolves the rest of its season differently from the run
## that saved it — the fixtures you have not played yet quietly change. That is
## the same class of bug as a table that re-sorts on reload, and it is invisible
## until somebody reloads and notices the results moved.
##
## Only the PLAYER'S club is stored. Every other club in the country is rebuilt
## by ClubFactory from its id and its current rating, which is exactly what
## happens during play, so a save cannot disagree with a fresh session about who
## is on Iron Crown's line.

## Bumped to 2 on 10 Sep 2026 when the heraldry vocabulary was retired: a club's
## kit and mark are stored under new keys and the mark is an IconBank id rather
## than a Charge enum. A version 1 file would decode into a club with no colors
## at all, so it is refused cleanly instead — the whole reason the version is in
## the file.
## 3 on 10 Sep 2026: the Home ground facility became the Arena, so an office
## carries a ground level and a reputation, and a season carries a booked event.
## 4 on 10 Sep 2026: reputation became notoriety and fans, and the arena
## capacities moved, so an old office would load with a following it cannot have.
## 5 on 10 Sep 2026: the career layer. Every fighter carries an age, a potential
## and banked XP, and a version 4 file has none of them — it would load a squad
## of 26-year-olds with ceilings equal to their current rating, which is a club
## that can never improve and never retires anybody. Refused cleanly instead.
## 6 on 10 Sep 2026: contracts and the market. A fighter carries the deal he is
## on — a wage and the summers left on it — and a version 5 file has neither, so
## it would load a squad on no contract at all: everybody out of contract, the
## whole club walking at the first roll-over.
## 7 on 10 Sep 2026: the dilemma deck. A season carries the card on the table and
## the last few dealt; a version 6 file has neither, so it would load mid-season
## with a dilemma the player had already answered still blocking his next fight.
## 12 on 12 Sep 2026: the federation and the members. A version 11 file has
## neither, and both default into a lie rather than a gap: a club with no
## certificates is BARRED FROM EVERY CUP the moment it loads, and a club with no
## members banks no dues and cannot pay the federation it has just been told it
## owes. Refused instead.
##
## THE NUMBER DID NOT MOVE WHEN TRIALS AND GOODWILL CAME OUT, and that is worth
## saying out loud rather than leaving as an omission. Every save this build
## writes is still a version 12, and every version 12 written by the build that
## had them still loads — the removed keys are simply not read, and nothing that
## IS read decodes into anything different. A version bump exists to refuse a
## file that would come back wrong; a file that comes back right does not need
## one, and bumping anyway would have thrown away Pete's saves for nothing.
## 11 on 12 Sep 2026: the coach. A file from before him has no reputation, no
## lifetime record and no posts, so it would load a twenty-season career as a
## man who has never taken a job — and the job-offer list, which is read off the
## reputation, would come back empty for a coach who had earned the country.
## 10 on 11 Sep 2026: morale went per man, and the captains' specialties started
## scaling with their stars. Both make a version 9 file a lie rather than a gap.
## Every fighter in one would come back at a flat 0.70 — a save-and-reload would
## CURE the toxic man the player has been managing round all season, and with him
## the +6 strength he was fighting at — and every captain in one carries two
## specialties whatever his grade, so a one-star hired under the old rules would
## reload still teaching two jobs he is not good enough to teach.
const VERSION := 12

## THE OLDEST FILE THIS BUILD WILL STILL OPEN.
##
## Strict equality was right while nobody had a career in a slot: a v11 file was
## refused as cleanly as a corrupt one, which is honest and costs nothing when
## the only v11 files in the world are on this machine. It stops being right the
## moment somebody else has one, because then every schema change wipes every
## player's club — and this project has moved the version four times in a month.
##
## So: a floor, and a migration between it and today. Below the floor a file is
## still refused, because a save old enough to predict nothing useful is worse
## than no save; at or above it, `_migrate()` walks it forward one version at a
## time and hands `from_dict` a dictionary shaped like today's.
##
## 11 rather than 1 is deliberate. Versions 1–10 were built before the game had
## a career worth keeping and no file of them exists outside this repo's tests;
## claiming to migrate them would be claiming to have checked something nobody
## can check. **A migration nobody can test is a promise, not a path.**
const VERSION_MIN := 11
const PATH := "user://retrobuhurt_save_%s%d.dat"

## A PREFIX FOR TEST ISOLATION, empty in the game.
##
## There are three save slots and there are five test files that write to them.
## Run one at a time that is fine; run them in parallel — which is the only way
## the melee suite finishes this decade — and they share `user://`, so one file's
## save lands in another file's slot. `test_save` failed on a round trip whose
## numbers were perfect, because by the time it read slot 2 back, `test_arena`
## had written its own season over it.
##
## It had been like that for a while and passed anyway, which is the worrying
## part: the tests were green by luck and got less lucky as more of them started
## saving. A test that shares mutable global state with another test is not
## isolated, and parallelism is what tells you.
## `namespace` is a reserved word in GDScript and the parse error it gives is
## "Expected variable name after var", which names neither the word nor the
## reason. Noted so nobody spends ten minutes on it twice.
static var slot_prefix: String = ""


static func set_namespace(n: String) -> void:
	slot_prefix = n if n == "" else n + "_"
const SLOTS := 3
## Four bytes at the front, checked before anything is decoded. Without it a
## foreign or truncated file reaches `get_var`, which returns null but prints an
## engine error on the way — so a player with one corrupt slot gets a log full of
## internal errors that look like the game is broken rather than like one bad
## file. Cheap to write, and it turns "refuse it" into a clean refusal.
const MAGIC := "RBHT"


static func path_for(slot: int) -> String:
	return PATH % [slot_prefix, slot]


static func has_save(slot: int) -> bool:
	return FileAccess.file_exists(path_for(slot))


static func delete(slot: int) -> void:
	if has_save(slot):
		DirAccess.remove_absolute(path_for(slot))


## A one-line description for the title screen, without loading the whole world.
static func peek(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var d = _migrate(_read(slot))
	if d == null:
		return {}
	return {
		"club": String(d.get("club_name", "?")),
		"season": int(d.get("season", 1)),
		"tier": String(d.get("tier_name", "")),
		"event": int(d.get("event", 0)),
		"events": int(d.get("events", 0)),
		"saved": String(d.get("saved", "")),
	}


static func save(season: Season, slot: int) -> bool:
	var f := FileAccess.open(path_for(slot), FileAccess.WRITE)
	if f == null:
		return false
	f.store_buffer(MAGIC.to_ascii_buffer())
	f.store_var(to_dict(season), false)
	f.close()
	return true


static func load_slot(slot: int) -> Season:
	var d = _migrate(_read(slot))
	if d == null:
		return null
	var s := from_dict(d)
	if s != null:
		_settle(s, int(d.get("migrated_from", VERSION)))
	return s


## WHAT A MIGRATED FILE OWES ITS FIGHTERS, paid after the decode rather than
## during it. `_migrate` works on a raw dictionary and levels live on decoded
## `FighterCard`s, so this is the only place the two exist at once.
##
## A fighter from a build with no levels can be carrying more XP than one level
## costs — several, on a veteran — and the ordinary door takes one at a time
## because a monstrous afternoon must not buy two. A migration is not an
## afternoon: he is owed all of them, at once, and `Career.drain_all()` was
## written for this exact case and then sat with no caller for want of a
## migration to call it from.
static func _settle(s: Season, from: int) -> void:
	if from >= VERSION or s == null:
		return
	for f in s.club.roster:
		Career.drain_all(f)
	s.sync_power()


## WALK AN OLD FILE FORWARD, OR REFUSE IT. Returns a dictionary shaped like
## today's, or null — and null is the only way a caller learns it failed, which
## is the same contract `_read` already had.
##
## One step per version, in order, so a v11 file passes through every step a
## v12 file skipped. Steps are written as "what changed between n and n+1" and
## never as "what the file needs today": the second kind has to be rewritten
## every time the schema moves and the first kind never does.
static func _migrate(d):
	if not (d is Dictionary):
		return null
	var v := int(d.get("version", 0))
	if v == VERSION:
		return d
	if v < VERSION_MIN or v > VERSION:
		## Newer than this build is refused too. A file from a later version can
		## carry fields this build would silently drop, and a save that loses a
		## season because the player opened an older build is worse than one that
		## says it cannot be opened.
		return null
	var out: Dictionary = d.duplicate(true)
	while int(out.get("version", 0)) < VERSION:
		var from := int(out.get("version", 0))
		match from:
			11:
				_v11_to_v12(out)
			_:
				## No step for this version means the table above is missing one,
				## which is a bug in this file rather than in the player's save.
				## Refusing is the honest answer; pretending is the other one.
				return null
		if int(out.get("version", 0)) != from + 1:
			return null
	return out


## 11 -> 12: the version moved for the after-action book and for morale being
## stored rather than defaulted (see the note above `VERSION`). A v11 file has
## neither, and the decoder already fills a missing book with an empty one — so
## the only thing this step owes it is the flag that says the file has been
## brought forward, plus the levels a v11 fighter may be owed.
##
## `Career.drain_all()` is what pays those out. It was written for exactly this
## — "for a save loaded from a build that had no levels, where a man may be
## owed several" — and then had no caller for months, because there was no
## migration to call it from.
static func _v11_to_v12(d: Dictionary) -> void:
	d["version"] = 12
	d["migrated_from"] = mini(11, int(d.get("migrated_from", 11)))


## Everything that opens a save file goes through here, so the magic check and
## the version check cannot be applied in one path and forgotten in the other.
static func _read(slot: int):
	if not has_save(slot):
		return null
	var f := FileAccess.open(path_for(slot), FileAccess.READ)
	if f == null:
		return null
	if f.get_length() < MAGIC.length() + 4:
		f.close()
		return null
	if f.get_buffer(MAGIC.length()).get_string_from_ascii() != MAGIC:
		f.close()
		return null
	var d = f.get_var()
	f.close()
	return d


# ------------------------------------------------------------------ the world
static func to_dict(season: Season) -> Dictionary:
	var w := season.world
	var cups: Array = []
	for c in w.cups:
		cups.append(c.to_dict())
	return {
		"version": VERSION,
		"saved": Time.get_datetime_string_from_system(true),
		## Denormalised for the title screen, so listing three slots does not
		## mean rebuilding three worlds.
		"club_name": season.club.display_name,
		"season": w.season,
		"event": w.event,
		"events": League.events_in_season(w.player_tier()),
		"tier_name": season.tier_name(),

		"seed": season.seed_value,
		"rng_seed": w.rng.seed,
		"rng_state": w.rng.state,
		"clubs": w.clubs.duplicate(true),
		"player_club": w.player_club,
		"schedule": w.schedule.duplicate(true),
		"tables": w.tables.duplicate(true),
		"history": w.history.duplicate(true),
		"honors": w.honors.duplicate(true),
		"records": w.records.duplicate(true),
		"hall": w.hall.duplicate(true),
		"cups": cups,
		"worlds": w.worlds.to_dict() if w.worlds != null else {},
		"results": season.results.duplicate(true),
		"club": club_to_dict(season.club),
		"office": season.office.to_dict(),
		"coach": season.coach.to_dict(),
		## THE BREAKAWAY CLUBS, by id. The only CPU rosters in the game that are
		## stored rather than generated — see `Season.club_for` for why.
		"splinters": _splinters_to_dict(season),
		"board": season.board.to_dict(),
		"formation_id": season.formation_id,
		"grade": season.grade,
		## EVERY GRADE THIS CAREER HAS BEEN FOUGHT ON. New on 16 Sep, when the
		## grade became changeable mid-career: a title won on FRIENDLY has to be
		## able to say so, and a record that only keeps the CURRENT grade cannot.
		"grade_history": season.grade_history,
		"matched_step": season.matched_step,
		"play_index": season.play_index,
		"workshop": season.workshop.to_dict(),
		"booked": _event_to_dict(season.booked),
		"last_show": season.last_show.duplicate(),
		## The three dates are derived from the division's season length, so the
		## save carries WHETHER they are on the table rather than what they are.
		## Storing them would be a second copy of something already deterministic.
		"bid_open": season.bid_open(),
		## THE PROSPECT IS STORED BY ROSTER INDEX, not by the card. A save that
		## wrote the whole card would come back holding a COPY — the winter would
		## then raise a ceiling on a fighter nobody is fielding, and the one on
		## the roster would be untouched. The index is the only reference that
		## survives the round trip, because the roster is rebuilt in order.
		"prospect": season.club.roster.find(season.prospect) if season.prospect != null else -1,
		## WHO IS GONE FROM THIS SUMMER'S MARKET, not who was in it. The pool is
		## regenerated from the world seed and the season number, so storing the
		## list would be a second copy of something already deterministic — and a
		## second copy is a second thing that can disagree with the first.
		"market_taken": season.market_taken.duplicate(),
		## The card on the table, and the last few dealt. Both have to survive a
		## reload or a player answers a different dilemma from the one he was
		## reading — and the deck would happily deal him the same card twice in a
		## row across a save, which is the one thing the memory exists to stop.
		"dilemma": season.dilemma.duplicate(),
		"dilemma_recent": season.dilemma_recent.duplicate(),
	}


static func from_dict(d: Dictionary) -> Season:
	## THE PURSE WATCHER HAS TO FORGET. It pops the difference between two
	## sightings of the balance, and loading a save is not earning — the number
	## jumps because a different career is on screen, and announcing that as a
	## gain of four hundred credits would be a lie told with a sound effect.
	Juice.forget_purse()
	var club := club_from_dict(d["club"] as Dictionary)
	## Season's constructor builds a whole fresh world from the seed; everything
	## below overwrites it. Cheaper in code than a second constructor, and it
	## guarantees any field added to LeagueWorld later still gets a sane default
	## rather than staying null in an old save.
	var s := Season.new(club, int(d["seed"]))
	var w := s.world
	w.rng.seed = int(d["rng_seed"])
	w.rng.state = int(d["rng_state"])
	w.clubs.clear()
	for c in d["clubs"]:
		w.clubs.append((c as Dictionary).duplicate(true))
	w.player_club = int(d["player_club"])
	w.season = int(d["season"])
	w.event = int(d["event"])
	w.schedule = (d["schedule"] as Dictionary).duplicate(true)
	w.tables = (d["tables"] as Dictionary).duplicate(true)
	w.history = _dicts(d["history"])
	w.honors = _dicts(d["honors"])
	w.records = (d.get("records", {}) as Dictionary).duplicate(true)
	w.hall.clear()
	for h in d.get("hall", []):
		w.hall.append((h as Dictionary).duplicate(true))
	w.cups.clear()
	for c in d["cups"]:
		w.cups.append(Cup.from_dict(c as Dictionary))
	var worlds: Dictionary = d.get("worlds", {})
	w.worlds = Cup.from_dict(worlds) if not worlds.is_empty() else null
	s.results = _dicts(d.get("results", []))
	s.office = ClubOffice.from_dict(d.get("office", {}))
	## YOU. Refused rather than defaulted, like the career layer and morale before
	## it: a file without a coach decodes into a brand-new one — reputation 1, no
	## record, no posts — which reads as a career that never happened rather than
	## as a field that has not been written yet.
	s.coach = Coach.from_dict(d["coach"])
	s.splinter_rosters.clear()
	for key in d.get("splinters", {}):
		var men: Array[FighterCard] = []
		for m in d["splinters"][key]:
			men.append(fighter_from_dict(m as Dictionary))
		s.splinter_rosters[int(key)] = men
	s.board = Chalkboard.from_dict(d.get("board", {}))
	s.formation_id = int(d.get("formation_id", Tuning.Formation.TWO_ONE_TWO))
	## THE VERSION DID NOT MOVE FOR THE GRADE, and that is a decision rather than
	## an oversight. A version bump exists to refuse a file that would come back
	## WRONG; a version 12 career is by construction a career fought at
	## SANCTIONED, because that is the only difficulty the build that wrote it
	## had. It decodes into exactly what it was. Bumping would have thrown away
	## Pete's saves to record a fact the default already states — the same
	## argument as the trials and goodwill removal above.
	s.grade = int(d.get("grade", Grade.DEFAULT))
	## DEFAULTED, NOT REQUIRED — a save written before the grade could move was a
	## save fought on one grade, and an empty history says exactly that.
	s.grade_history = d.get("grade_history", [])
	## CLAMPED ON THE WAY IN. The step's range narrowed once the win rates were
	## measured, and a file written before that carries a number outside it —
	## harmless today because `matched_scale` clamps too, and a lie on the grade
	## screen, which reads the raw step.
	s.matched_step = clampi(int(d.get("matched_step", Grade.STEP_START)),
		Grade.STEP_MIN, Grade.STEP_MAX)
	s.play_index = int(d.get("play_index", -1))
	s.workshop = Workshop.from_dict(d.get("workshop", {}))
	s.booked = _event_from_dict(d.get("booked", {}))
	_relink_event(s)
	s.last_show = (d.get("last_show", {}) as Dictionary).duplicate()
	s.dilemma = (d.get("dilemma", {}) as Dictionary).duplicate()
	s.dilemma_recent.clear()
	for k in d.get("dilemma_recent", []):
		s.dilemma_recent.append(String(k))
	s.market_taken.clear()
	for k in d.get("market_taken", []):
		s.market_taken.append(String(k))
	var pi: int = int(d.get("prospect", -1))
	s.prospect = s.club.roster[pi] if pi >= 0 and pi < s.club.roster.size() else null
	if bool(d.get("bid_open", false)):
		s.open_bids()
	else:
		s.bid_offers.clear()
	## AND THE CAP BACK ONTO THE CLUB.
	##
	## `ClubOffice.travel_slots` is saved; `MeleeClub.travel_cap` is not, because
	## it is a copy of that number pushed onto the club by `sync_power()`. Nothing
	## pushed it here, so a reloaded club took the DEFAULT eight while its office
	## said six — and `active_eight()` handed back eight men where the live season
	## handed back six. The save round-trip caught it as a roster that came back
	## different; without that check it would have surfaced as a club that quietly
	## got two men better every time the player reloaded.
	s.sync_power()
	return s


## A booked event is a handful of numbers and a DRAW.
##
## THE CUP IS NOT COPIED IN HERE — it is already saved once, in `world.cups`,
## and a second copy is a second source of truth. What IS saved is the LINK:
## the cup's id, so the event can be tied back to the cup it owns.
##
## Without that link a hosted tournament was permanently broken by any reload.
## `_finish_cup_round` asks `booked.cup == c` to decide whether a finished
## bracket is your show or somebody else's; after a load `booked.cup` was null,
## so the answer was no, the gate was never paid and `settled` stayed false.
## `_event_due()` was then true on every subsequent matchday, so the same
## Invitational was drawn again, and again, for the rest of the save — you
## fought your own tournament every week, were never paid for it, and never got
## another bid because `open_bids()` returns early while one is booked.
static func _event_to_dict(e: ClubEvent) -> Dictionary:
	if e == null:
		return {}
	return {"kind": e.kind, "budget": e.budget, "due": e.due,
		"arena_level": e.arena_level, "settled": e.settled,
		"slot": e.slot, "bid": e.bid,
		"cup_id": "" if e.cup == null else String(e.cup.get_meta("id", ""))}


static func _event_from_dict(d: Dictionary) -> ClubEvent:
	if d.is_empty():
		return null
	var e := ClubEvent.new()
	e.kind = int(d.get("kind", ClubEvent.Kind.DEMO))
	e.budget = int(d.get("budget", 0))
	e.due = int(d.get("due", -1))
	e.arena_level = int(d.get("arena_level", 0))
	e.settled = bool(d.get("settled", false))
	e.slot = int(d.get("slot", -1))
	e.bid = int(d.get("bid", 0))
	## The cup itself is hung back on in `_relink_event`, once the world that
	## owns it has been restored.
	e.set_meta("cup_id", String(d.get("cup_id", "")))
	return e


## Hang the booked event back on its cup. Both were saved; only the pointer
## between them was not, and a pointer nobody restores is the same as a pointer
## nobody set.
static func _relink_event(s: Season) -> void:
	if s.booked == null or s.world == null:
		return
	var want := String(s.booked.get_meta("cup_id", ""))
	if want == "":
		return
	for c in s.world.cups:
		if String(c.get_meta("id", "")) == want:
			s.booked.cup = c
			return


static func _dicts(a) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for x in a:
		out.append((x as Dictionary).duplicate(true))
	return out


# ------------------------------------------------------------------- the club
static func club_to_dict(c: MeleeClub) -> Dictionary:
	var men: Array = []
	for f in c.roster:
		men.append(fighter_to_dict(f))
	return {
		"name": c.display_name, "short": c.short_name,
		"kit": c.kit.to_html(), "icon_color": c.icon_color.to_html(),
		"icon": int(c.icon), "roster": men,
	}


static func club_from_dict(d: Dictionary) -> MeleeClub:
	var cards: Array[FighterCard] = []
	for m in d["roster"]:
		cards.append(fighter_from_dict(m as Dictionary))
	return MeleeClub.build(String(d["name"]), String(d["short"]),
		Color(String(d["kit"])), Color(String(d["icon_color"])),
		int(d["icon"]), cards)


static func _splinters_to_dict(season: Season) -> Dictionary:
	var out := {}
	for id in season.splinter_rosters:
		var men: Array = []
		for f in season.splinter_rosters[id]:
			men.append(fighter_to_dict(f))
		out[id] = men
	return out


static func fighter_to_dict(f: FighterCard) -> Dictionary:
	return {
		"name": f.display_name, "no": f.number, "pos": int(f.pos),
		"str": f.strength, "base": f.base, "tec": f.skill,
		"gas": f.gas, "agg": f.aggression, "kg": f.weight,
		"armor": f.armor, "harness": f.harness,
		"active": f.active, "available": f.available,
		"injury": f.injury,
		## THE CAREER LAYER. A file without these decodes into a squad of
		## 26-year-olds whose ceilings equal their current rating — a club that
		## can never improve and never retires anybody — which is why VERSION
		## moved rather than these being defaulted in quietly.
		"age": f.age, "potential": f.potential, "xp": f.xp, "trait": f.trait_id, "level": f.level,
		## HIS OWN AGEING CURVE. Defaulted to 0 on read rather than refused, and
		## that is the same distinction the two blocks around it draw: a fighter
		## from a file written before peaks varied really does have the sport's
		## average schedule, so 0 decodes into something TRUE. See
		## `FighterCard.peak_seed`.
		"peaks": f.peak_seed,
		"deal": f.wage_agreed, "years": f.years,
		## THE BOOK. Defaulted to zero on read rather than refused, because a
		## version 8 squad with no record is a squad that simply has not had one
		## kept yet — unlike the career fields above, a missing book decodes into
		## something true.
		"bouts": f.bouts, "downs": f.downs, "standing": f.rounds_standing,
		"best": f.best_downs, "knocks": f.knocks, "honors": f.honors,
		## HIS MOOD. Refused rather than defaulted, and the distinction is the
		## whole reason VERSION moved: a missing book decodes into something true
		## (no record kept yet), a missing morale decodes into 0.70 for every man
		## on the roster — which would quietly CURE the toxic fighter you have
		## been managing round him all season, the moment the player reloaded.
		"morale": f.morale,
	}


static func fighter_from_dict(d: Dictionary) -> FighterCard:
	var f := FighterCard.new()
	f.display_name = String(d["name"])
	f.number = int(d["no"])
	f.pos = int(d["pos"])
	f.strength = int(d["str"])
	f.base = int(d["base"])
	f.skill = int(d["tec"])
	f.gas = int(d["gas"])
	f.aggression = int(d["agg"])
	f.weight = int(d["kg"])
	f.armor = float(d["armor"])
	## DEFAULTED, NOT REQUIRED. Every save written before the quartermaster
	## existed has no `harness` key, and Borrowed is exactly what those men were
	## wearing — so the absence reads correctly rather than needing a migration
	## step of its own.
	f.harness = int(d.get("harness", Quartermaster.Grade.BORROWED))
	f.active = bool(d["active"])
	f.available = bool(d["available"])
	f.injury = int(d.get("injury", 0))
	f.age = int(d.get("age", 26))
	f.potential = int(d.get("potential", f.overall()))
	f.xp = int(d.get("xp", 0))
	## A FILE FROM BEFORE TRAITS IS A SQUAD OF ORDINARY MEN, which is exactly
	## what it was — the default is NONE and nothing decodes wrong, so the
	## version does not move. Same argument as the grade.
	f.trait_id = int(d.get("trait", FighterTrait.T.NONE))
	## A FILE FROM BEFORE LEVELS HAS MEN AT LEVEL ONE, which is what they were —
	## and their banked XP comes back with them, so the first time anybody opens
	## the squad they level up for the seasons they already earned.
	f.level = maxi(1, int(d.get("level", 1)))
	f.peak_seed = int(d.get("peaks", 0))
	f.wage_agreed = int(d.get("deal", 0))
	f.years = int(d.get("years", Contracts.YEARS_NEW))
	f.bouts = int(d.get("bouts", 0))
	f.downs = int(d.get("downs", 0))
	f.rounds_standing = int(d.get("standing", 0))
	f.best_downs = int(d.get("best", 0))
	f.knocks = int(d.get("knocks", 0))
	f.honors = int(d.get("honors", 0))
	f.morale = float(d["morale"])
	return f
