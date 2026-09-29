class_name Cup
extends RefCounted
## Knockouts: the Invitationals and Worlds.
##
## Taken from ACRTW at Pete's instruction (10 Sep 2026) — it already had both,
## and it had them in the right shape: two named side-tournaments during the
## season that you are only INVITED to if you are near the top of your division,
## and a Worlds at the end that is pools first and a bracket after.
##
## Two things are deliberately changed on the way across.
##
## 1. ACRTW invites on National top-3. This game starts you in the Backyard
##    Circuit, so the same rule would mean you never see an Invitational for
##    seven seasons. Here it is the top three of YOUR OWN division, which makes
##    a cup run something a bad club in a bad league can still have.
##
## 2. ACRTW's Worlds pool points are "men left standing in rounds won" — a 5-1
##    scores 5. Pete's are the differential: a 5-1 is 4 and a 1-0 is 1. His is
##    the better number, because ACRTW's cannot tell a 5-1 from a 5-4, and the
##    whole point of the tiebreak is to know how convincingly you won. The same
##    margin is the league's tiebreak, so one measure runs the entire game.
##
## Deterministic from a seed, no node dependencies, resolved through a Callable
## so the player's own bout can be the real melee and the other seven are
## numbers by Sunday night — exactly as in the league.

signal round_opened(round_name: String)
signal cup_finished(champion: int)

enum Stage { POOLS, KNOCKOUT, DONE }

const POOL_SIZE: int = 4
const POOLS_ADVANCE: int = 2

## The bracket names, by how many clubs are left going into the round.
const ROUND_NAMES := {
	16: "Round of 16",
	8: "Quarter-finals",
	4: "Semi-finals",
	2: "Final",
}

var cup_name: String = "Invitational"
var entrants: Array = []                ## club ids, seeded best first
var player_club: int = -1
var has_pools: bool = false

var stage: int = Stage.KNOCKOUT
var pools: Array = []                   ## Array[Array[club id]]
var pool_tables: Array = []             ## Array[{club id: row}]
var pool_matches: Array = []            ## flat list of match dicts
var rounds: Array = []                  ## Array[Array[match dict]] — the bracket
var third_place: Dictionary = {}
var champion: int = -1
var runner_up: int = -1
var third: int = -1
## HOW THE PLAYER'S RUN ENDED, in words, and it is SET now — it was declared the
## day the cups were written and never assigned once, so every screen that
## reported a cup run printed an empty string. Same family of bug as
## `player_match()` sitting with no caller: a field nobody could see was wrong
## because nobody could see it.
var player_finish: String = ""

var rng := RandomNumberGenerator.new()


## `seeded` must already be in merit order — the caller knows what the seeding
## means, this does not.
func _init(name_: String, seeded: Array, seed_value: int, player: int = -1,
		pools_first: bool = false) -> void:
	cup_name = name_
	entrants = seeded.duplicate()
	player_club = player
	has_pools = pools_first
	rng.seed = seed_value
	if has_pools:
		stage = Stage.POOLS
		_draw_pools()
	else:
		_open_round(entrants)


# ------------------------------------------------------------------- the draw
## Snake the seeds across the pools, so the four best cannot land together and
## the fourth pool is not made entirely of the clubs nobody rates. Standard, and
## it is what stops a group of death being a coin flip in the draw.
func _draw_pools() -> void:
	var n_pools := int(ceil(float(entrants.size()) / float(POOL_SIZE)))
	pools.clear()
	pool_tables.clear()
	for _i in n_pools:
		pools.append([])
		pool_tables.append({})
	var forward := true
	var i := 0
	for cid in entrants:
		pools[i].append(cid)
		pool_tables[i][cid] = League.new_row(cid, rng.randi_range(0, 1_000_000))
		if forward:
			i += 1
			if i >= n_pools:
				i = n_pools - 1
				forward = false
		else:
			i -= 1
			if i < 0:
				i = 0
				forward = true

	pool_matches.clear()
	for pi in pools.size():
		for day in League.fixtures(pools[pi]):
			for pair in day:
				pool_matches.append(_match(int(pair[0]), int(pair[1]), "Pool %s" % char(65 + pi), pi))
	round_opened.emit("Pools")


func _match(a: int, b: int, round_name: String, pool_index: int = -1) -> Dictionary:
	return {
		"a": a, "b": b, "round": round_name, "pool": pool_index,
		"played": false, "ra": 0, "rb": 0, "ma": 0, "mb": 0, "winner": -1,
	}


# ---------------------------------------------------------------- the bracket
func _open_round(club_ids: Array) -> void:
	if club_ids.size() <= 1:
		champion = int(club_ids[0]) if club_ids.size() == 1 else -1
		stage = Stage.DONE
		cup_finished.emit(champion)
		return
	## AN ODD FIELD WOULD LOSE ITS MIDDLE CLUB — `size() / 2` pairs, and the one
	## left over was dropped without a word. Every field is 8, 16 or built from
	## pools today, so it cannot happen; if a change ever makes it happen, it is
	## an engine ERROR (which fails the test gate) rather than a silent vanishing.
	if club_ids.size() % 2 == 1:
		push_error("Cup %s: odd field of %d, club %d would get no match"
			% [cup_name, club_ids.size(), int(club_ids[club_ids.size() / 2])])
	var nm: String = String(ROUND_NAMES.get(club_ids.size(), "Round of %d" % club_ids.size()))
	var day: Array = []
	## Top seed meets bottom seed. A bracket that pairs 1v2 in the first round is
	## not a bracket, it is a raffle with extra steps.
	for i in club_ids.size() / 2:
		day.append(_match(int(club_ids[i]), int(club_ids[club_ids.size() - 1 - i]), nm))
	rounds.append(day)
	round_opened.emit(nm)


func current_round() -> Array:
	if stage == Stage.POOLS:
		return pool_matches
	if rounds.is_empty():
		return []
	return rounds[rounds.size() - 1]


func round_name() -> String:
	if stage == Stage.POOLS:
		return "Pools"
	if stage == Stage.DONE:
		return "Complete"
	var day := current_round()
	return String(day[0]["round"]) if not day.is_empty() else ""


## The player's next unplayed fixture in this cup, or {} if he has none — he is
## out, he was never in, or the cup is over.
func player_match() -> Dictionary:
	if player_club == -1:
		return {}
	for m in current_round():
		if not bool(m["played"]) and (int(m["a"]) == player_club or int(m["b"]) == player_club):
			return m
	## THE BRONZE IS HIS TO FIGHT TOO. It lives outside `current_round()`, so the
	## player's third-place match was never offered — always auto-simmed.
	if player_in_third():
		return third_place
	return {}


## Is the player owed an unplayed third-place match?
func player_in_third() -> bool:
	return player_club != -1 and not third_place.is_empty() \
		and not bool(third_place.get("played", false)) \
		and (int(third_place["a"]) == player_club or int(third_place["b"]) == player_club)


## IS THE PLAYER STILL IN IT? Asked by everything that decides whether a cup
## can be resolved on paper or has to wait for him to turn up and fight.
##
## Derived from the bracket rather than stored as a flag, because a flag would
## be a second source of truth for something the rounds already know — and the
## rounds are what `record` writes. Pools are different: nobody is out of a pool
## until the pool is over, so being an entrant is enough while the pools run.
func player_alive() -> bool:
	if player_in_third():
		return true
	if player_club == -1 or stage == Stage.DONE:
		return false
	if not entrants.has(player_club):
		return false
	if stage == Stage.POOLS:
		return true
	## OUT OF THE POOLS IS OUT. Once the stage moves to KNOCKOUT the loop below
	## only reads `rounds`, and a club that failed to qualify has no match in
	## there at all — so it read as still alive, forever. `auto_resolve_cups`
	## then refused to resolve the Worlds every summer: it never finished, never
	## entered the honors, and `roll_over` replaced it with a fresh one while
	## the old guests stayed on the books. Fourteen clubs a season, accumulating.
	##
	## The bracket's entrants are the qualifiers, so after the pools the question
	## "am I in this" is answered by whether the first round contains me.
	if has_pools and not rounds.is_empty():
		var in_bracket := false
		for m in rounds[0]:
			if int(m["a"]) == player_club or int(m["b"]) == player_club:
				in_bracket = true
				break
		if not in_bracket:
			return false
	for round_ in rounds:
		for m in round_:
			if not bool(m["played"]):
				continue
			if int(m["a"]) != player_club and int(m["b"]) != player_club:
				continue
			if int(m.get("winner", -1)) != player_club:
				return false
	return true


## Record a result. `rounds_a`/`rounds_b` are rounds won, `margin_a`/`margin_b`
## the standing differential — the same four numbers the league takes, so the
## real melee feeds a cup match and a league fixture through one shape.
func record(m: Dictionary, ra: int, rb: int, ma: int, mb: int) -> void:
	m["played"] = true
	m["ra"] = ra
	m["rb"] = rb
	m["ma"] = ma
	m["mb"] = mb
	## A knockout cannot be drawn. If the rounds are level the margin settles it,
	## and if that is level too the higher seed goes through, which is what the
	## seeding was FOR.
	if ra != rb:
		m["winner"] = int(m["a"]) if ra > rb else int(m["b"])
	elif stage == Stage.KNOCKOUT:
		if ma != mb:
			m["winner"] = int(m["a"]) if ma > mb else int(m["b"])
		else:
			m["winner"] = int(m["a"]) if entrants.find(int(m["a"])) \
				< entrants.find(int(m["b"])) else int(m["b"])
	if int(m["pool"]) >= 0:
		var pi := int(m["pool"])
		League.apply_result(pool_tables[pi][int(m["a"])], ra, rb, ma, mb)
		League.apply_result(pool_tables[pi][int(m["b"])], rb, ra, mb, ma)
	## The moment the player goes out, in the round he went out in. Written here
	## rather than at the end of the cup because by then the bracket no longer
	## remembers how far he got.
	if m == third_place:
		third = int(m.get("winner", -1))
		if player_club != -1 and (int(m["a"]) == player_club or int(m["b"]) == player_club):
			player_finish = "third" if third == player_club else "fourth"
		return
	if player_club != -1 and stage == Stage.KNOCKOUT \
			and (int(m["a"]) == player_club or int(m["b"]) == player_club) \
			and int(m.get("winner", -1)) != player_club:
		player_finish = UiKit.t("out in the %s") % String(m["round"]).to_lower()


## Play out everything the player is not in. `resolver` takes two club ids and
## returns [ra, rb, ma, mb].
func sim_others(resolver: Callable) -> void:
	for m in current_round():
		if bool(m["played"]):
			continue
		if int(m["a"]) == player_club or int(m["b"]) == player_club:
			continue
		var res: Array = resolver.call(int(m["a"]), int(m["b"]))
		record(m, int(res[0]), int(res[1]), int(res[2]), int(res[3]))


func round_complete() -> bool:
	for m in current_round():
		if not bool(m["played"]):
			return false
	return true


## Move the cup on. Returns false if the current round is not finished.
func advance() -> bool:
	if stage == Stage.DONE or not round_complete():
		return false
	if stage == Stage.POOLS:
		stage = Stage.KNOCKOUT
		_open_round(_pool_qualifiers())
		return true

	var day := current_round()
	var winners: Array = []
	var losers: Array = []
	for m in day:
		winners.append(int(m["winner"]))
		losers.append(int(m["a"]) if int(m["winner"]) == int(m["b"]) else int(m["b"]))

	if day.size() == 1:
		champion = int(day[0]["winner"])
		runner_up = int(losers[0])
		stage = Stage.DONE
		if player_club != -1:
			if champion == player_club:
				player_finish = "champions"
			elif runner_up == player_club:
				player_finish = "runners-up"
			elif third == player_club:
				player_finish = "third"
		cup_finished.emit(champion)
		return true

	## Semi-final losers fight for third, which ACRTW does and which matters here
	## because a Worlds bronze is a real result to bring home.
	if day.size() == 2 and third_place.is_empty():
		third_place = _match(int(losers[0]), int(losers[1]), "Third-place match")
	_open_round(winners)
	return true


## THE THIRD-PLACE MATCH, PLAYED. It was created by `advance()` and only ever
## resolved by `run_all()` — so on the path the player actually walks, where the
## season calls `sim_others` and `advance` by hand, `third` stayed −1: the 1 CC
## bronze in `ClubEvent.PODIUM[2]` was unreachable, `finish_label()` could never
## say "third", and every interactively played bracket finished with an unplayed
## match sitting in it.
##
## `hold_player`: leave the player's own bronze match for him to fight (the season
## path). `run_all` — a forfeit at the roll-over — plays it on paper.
func settle_third(resolver: Callable, hold_player: bool = false) -> void:
	if third_place.is_empty() or bool(third_place.get("played", false)):
		return
	if hold_player and player_in_third():
		return
	var res: Array = resolver.call(int(third_place["a"]), int(third_place["b"]))
	## `record` reads the stage when it decides what it is recording, and a
	## third-place match is a knockout match whatever the cup is doing around it.
	var keep := stage
	stage = Stage.KNOCKOUT
	record(third_place, int(res[0]), int(res[1]), int(res[2]), int(res[3]))
	stage = keep
	third = int(third_place.get("winner", -1))
	if third == player_club:
		player_finish = "third"


func _pool_qualifiers() -> Array:
	var out: Array = []
	## Winners first, then runners-up, so the seeding for the bracket puts the
	## best pool performances on opposite sides of it.
	for place in POOLS_ADVANCE:
		for pi in pools.size():
			var rows: Array = []
			for cid in pool_tables[pi]:
				rows.append(pool_tables[pi][cid])
			rows = League.sort_table(rows)
			if place < rows.size():
				out.append(int(rows[place]["club"]))
	return out


func pool_table(pool_index: int) -> Array:
	var rows: Array = []
	for cid in pool_tables[pool_index]:
		rows.append(pool_tables[pool_index][cid])
	return League.sort_table(rows)


func is_over() -> bool:
	return stage == Stage.DONE


## Run the whole thing with nobody watching — every match on rating, including
## the player's. Used for a cup the player was not invited to, and by the tests.
func run_all(resolver: Callable, guard: int = 40) -> void:
	while not is_over() and guard > 0:
		guard -= 1
		for m in current_round():
			if bool(m["played"]):
				continue
			var res: Array = resolver.call(int(m["a"]), int(m["b"]))
			record(m, int(res[0]), int(res[1]), int(res[2]), int(res[3]))
		settle_third(resolver)
		advance()


## Where the player got to, as a label. "" if he was not in it.
func finish_label() -> String:
	if player_club == -1 or not entrants.has(player_club):
		return ""
	if champion == player_club:
		return "Champions"
	if runner_up == player_club:
		return "Runners-up"
	if third == player_club:
		return "Third"
	for day in rounds:
		for m in day:
			if int(m["winner"]) != -1 and int(m["winner"]) != player_club \
					and (int(m["a"]) == player_club or int(m["b"]) == player_club):
				return UiKit.t("Out in the %s") % String(m["round"]).to_lower()
	if has_pools:
		return UiKit.t("Out in the pools")
	return UiKit.t("In progress")


## HOW FAR THE PLAYER GOT, AS A NUMBER: the size of the round he went out in.
## 1 if he won the thing, 2 if he lost the final, 4 the semis, and so on; -1 if
## he never entered or the cup is still being fought.
##
## It is the same walk `finish_label()` does, and it has to be — the label on the
## screen and the reputation the run is worth must never be able to disagree
## about where a club went out. `ROUND_NAMES` is keyed on exactly this number,
## which is why it is the number and not a rank.
func player_exit_size() -> int:
	if player_club == -1 or not entrants.has(player_club):
		return -1
	if champion == player_club:
		return 1
	if runner_up == player_club:
		return 2
	for day in rounds:
		for m in day:
			if int(m["winner"]) != -1 and int(m["winner"]) != player_club \
					and (int(m["a"]) == player_club or int(m["b"]) == player_club):
				return day.size() * 2
	return -1


# ------------------------------------------------------------------- saving
## Plain data in, plain data out. A cup can be live when the player saves — an
## Invitational opens on matchday 2 and is not resolved until the summer — so it
## has to survive a reload with the bracket exactly as it stood.
func to_dict() -> Dictionary:
	return {
		"name": cup_name, "entrants": entrants.duplicate(), "player": player_club,
		"pools_first": has_pools, "stage": stage,
		"pools": pools.duplicate(true), "pool_tables": pool_tables.duplicate(true),
		"pool_matches": pool_matches.duplicate(true), "rounds": rounds.duplicate(true),
		"third_place": third_place.duplicate(true),
		"champion": champion, "runner_up": runner_up, "third": third,
		"id": String(get_meta("id", "")),
		"season": int(get_meta("season", -1)),
		## The stream, not just the seed. A cup reloaded with a fresh RNG would
		## resolve its remaining rounds differently from the run that saved it,
		## which is the same class of bug as a table that re-sorts on reload.
		"rng_seed": rng.seed, "rng_state": rng.state,
	}


static func from_dict(d: Dictionary) -> Cup:
	var c := Cup.new(String(d["name"]), [], 0, int(d["player"]), false)
	c.entrants = (d["entrants"] as Array).duplicate()
	c.has_pools = bool(d["pools_first"])
	c.stage = int(d["stage"])
	c.pools = (d["pools"] as Array).duplicate(true)
	c.pool_tables = (d["pool_tables"] as Array).duplicate(true)
	c.pool_matches = (d["pool_matches"] as Array).duplicate(true)
	c.rounds = (d["rounds"] as Array).duplicate(true)
	c.third_place = (d["third_place"] as Dictionary).duplicate(true)
	c.champion = int(d["champion"])
	c.runner_up = int(d["runner_up"])
	c.third = int(d["third"])
	c.set_meta("id", String(d["id"]))
	if int(d.get("season", -1)) >= 0:
		c.set_meta("season", int(d["season"]))
	c.rng.seed = int(d["rng_seed"])
	c.rng.state = int(d["rng_state"])
	return c
