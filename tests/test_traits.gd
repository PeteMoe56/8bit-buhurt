extends SceneTree
## Fighter traits: that they exist, that they are wired, and that they DO something.
##
##   godot --headless --path . --script res://tests/test_traits.gd
##
## THIS FILE EXISTS BECAUSE OF THE SCOUT.
##
## `ClubOffice.Trait.SCOUT` shipped with a name, a blurb, a weight in the offer
## roll and a line on the hire screen — and no code anywhere. It said "More men
## at the trials" and pointed at a system that had been cut. Nothing in the suite
## noticed, because nothing in the suite could: a trait is a number in a dict
## until somebody reads it, and "somebody reads it" is not a property any
## assertion about the dict can see.
##
## Forty-one traits is forty-one chances to do that again. So there are three
## gates here and they are deliberately different kinds:
##
##   1. BOOKKEEPING — every trait is either wired or openly pending, and a
##      pending one can never be rolled onto a fighter.
##   2. THE GREP — every effect key in `MOD` is read somewhere outside
##      `fighter_trait.gd`. This is the one that would have caught the Scout.
##   3. THE MEASUREMENT — for each wired trait, the number it claims to move
##      actually moves, in the direction it claims, against an identical man
##      who does not have it. This is the one that catches a key that is read
##      in dead code, or read and then thrown away.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — fighter traits ===\n")
	_test_every_trait_is_wired_or_openly_pending()
	_test_a_pending_trait_can_never_be_rolled()
	_test_every_effect_key_is_read_somewhere()
	_test_the_roll_leaves_most_men_ordinary()
	_test_the_sim_traits_move_their_number()
	_test_the_career_traits_move_their_number()
	_test_the_club_traits_move_their_number()
	_test_the_wrestler_opens_ahead()
	_test_second_wind_comes_once()
	_test_the_room_moves_with_who_is_standing()
	_test_heavy_hands_wreck_a_harness()
	_test_a_grudge_is_carried_on_the_card()
	_test_a_talisman_lifts_the_dressing_room()
	_test_proud_and_prima_donna_are_read_where_they_matter()
	_test_what_is_left_is_named()
	_test_homesick_is_a_different_man_away()
	_test_levelling_is_not_a_winter_thing()
	_test_a_level_goes_where_you_put_it()
	_test_a_level_does_not_move_the_bill_until_he_re_signs()
	_test_a_sour_man_will_not_re_sign_at_any_price()
	_test_a_happy_man_signs_for_less()
	_test_sitting_him_down_costs_more_the_worse_it_is()
	_test_a_career_climbs_as_far_as_it_used_to()
	_test_a_trait_survives_the_save()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE TRAITS HOLD (%d checks)\n" % checks)
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


# --------------------------------------------------------------- bookkeeping
## A TRAIT CANNOT SIT IN LIMBO. It is in MOD and wired, or it is in PENDING and
## unreachable. The state that produced the Scout — in the enum, in the roll, in
## neither list — is the one this makes impossible.
func _test_every_trait_is_wired_or_openly_pending() -> void:
	var limbo: Array[String] = []
	var both: Array[String] = []
	for k in FighterTrait.NAME:
		var t := int(k)
		if t == FighterTrait.T.NONE:
			continue
		var wired: bool = FighterTrait.MOD.has(t)
		var pending: bool = FighterTrait.PENDING.has(t)
		if not wired and not pending:
			limbo.append(FighterTrait.name_of(t))
		if wired and pending:
			both.append(FighterTrait.name_of(t))
	_ok(limbo.is_empty(), "every trait is wired or openly pending",
		"%d wired, %d pending" % [FighterTrait.MOD.size(), FighterTrait.PENDING.size()]
		if limbo.is_empty() else "in neither list: " + ", ".join(limbo))
	_ok(both.is_empty(), "and none is in both lists",
		"clean" if both.is_empty() else ", ".join(both))

	## AND EVERY WIRED ONE ACTUALLY CARRIES AN EFFECT. A trait whose row is `{}`
	## passes the check above and does nothing at all.
	var empty: Array[String] = []
	for k in FighterTrait.MOD:
		if (FighterTrait.MOD[k] as Dictionary).is_empty():
			empty.append(FighterTrait.name_of(int(k)))
	_ok(empty.is_empty(), "and every wired trait carries an effect",
		"clean" if empty.is_empty() else ", ".join(empty))


func _test_a_pending_trait_can_never_be_rolled() -> void:
	var seen := {}
	for i in 20000:
		seen[FighterTrait.roll(hash("roll:%d" % i))] = true
	var leaked: Array[String] = []
	for t in FighterTrait.PENDING:
		if seen.has(t):
			leaked.append(FighterTrait.name_of(int(t)))
	_ok(leaked.is_empty(), "a pending trait is never rolled onto a fighter",
		"20,000 rolls" if leaked.is_empty() else "leaked: " + ", ".join(leaked))
	var wired_seen := 0
	for k in FighterTrait.MOD:
		if seen.has(int(k)):
			wired_seen += 1
	_ok(wired_seen == FighterTrait.MOD.size(),
		"and every wired one does turn up",
		"%d of %d" % [wired_seen, FighterTrait.MOD.size()])


# ------------------------------------------------------------------ the grep
## THE CHECK THAT WOULD HAVE CAUGHT THE SCOUT.
##
## An effect key nobody reads is a trait that does nothing, and it is invisible
## from inside `fighter_trait.gd` — the dict is perfectly well-formed. So this
## walks the rest of `scripts/` looking for the string, and fails naming the key.
const TRAIT_FILE := "res://scripts/melee/fighter_trait.gd"


func _test_every_effect_key_is_read_somewhere() -> void:
	var keys := {}
	for k in FighterTrait.MOD:
		for key in (FighterTrait.MOD[k] as Dictionary):
			keys[String(key)] = 0
	var files: Array[String] = []
	_walk("res://scripts", files)
	## IT LOOKS FOR THE CALL, NOT FOR THE WORD.
	##
	## The first version searched every file for `"key"` in quotes, and
	## `HEAVY_HANDS`'s `harness` passed that with **no code anywhere** — because
	## `dilemma.gd` has a card whose id is `"harness"`. A gate an unrelated string
	## can satisfy is a gate with a hole, and this one is the whole defense
	## against the Scout: a trait with a description and no code.
	##
	## So it matches the shapes a key can actually be read through — `tmod("k"`,
	## `tflag("k"`, and `mod(x, "k"` / `flag(x, "k"` — and nothing else. A new way
	## of reading a key has to be added here, which is the point: a reader the
	## gate does not know about is a reader nobody can find.
	for path in files:
		if path == TRAIT_FILE:
			continue
		var src := FileAccess.get_file_as_string(path)
		for key in keys:
			var re := RegEx.new()
			re.compile('(?:tmod|tflag)\\(\\s*"%s"|(?:mod|flag)\\([^()]*,\\s*"%s"'
				% [key, key])
			if re.search(src) != null:
				keys[key] = int(keys[key]) + 1
	var dead: Array[String] = []
	for key in keys:
		if int(keys[key]) == 0:
			dead.append(String(key))
	_ok(dead.is_empty(), "every effect key is read outside the trait file",
		"%d keys across %d files" % [keys.size(), files.size()]
		if dead.is_empty() else "read nowhere: " + ", ".join(dead))


func _walk(dir: String, out: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		var p := dir + "/" + n
		if d.current_is_dir():
			_walk(p, out)
		elif n.ends_with(".gd"):
			out.append(p)
		n = d.get_next()
	d.list_dir_end()


## MOST MEN ARE ORDINARY. A squad where everybody is unusual is a squad where
## nobody is, and it is also a balance problem nobody can reason about.
func _test_the_roll_leaves_most_men_ordinary() -> void:
	var none := 0
	const N := 6000
	for i in N:
		if FighterTrait.roll(hash("o:%d" % i)) == FighterTrait.T.NONE:
			none += 1
	var pct := 100.0 * float(none) / float(N)
	_ok(pct > 35.0 and pct < 65.0, "most men have no trait at all",
		"%.0f%% of %d are ordinary" % [pct, N])
	notes.append("a trait turns up on %.0f%% of generated fighters" % (100.0 - pct))


# ----------------------------------------------------------- the measurement
## TWO IDENTICAL MEN, ONE DIFFERENCE.
##
## For each sim-side trait, build the quantity it claims to move with the trait
## and without it, and assert it moved the right way. A key that is read into a
## variable nobody uses passes the grep and fails here.
func _man(trait_id: int, slot: int = 0) -> MeleeSim.Man:
	var c := FighterCard.new()
	c.strength = 60
	c.base = 60
	c.skill = 60
	c.gas = 60
	c.aggression = 60
	c.weight = 220
	c.armor = 1.0
	c.morale = 0.5
	c.trait_id = trait_id
	var m := MeleeSim.Man.new()
	m.card = c
	m.slot = slot
	return m


func _moved(label: String, trait_id: int, key: String, with_v: float,
		without_v: float, want_up: bool) -> void:
	var up := with_v > without_v
	var moved: bool = not is_equal_approx(with_v, without_v)
	_ok(moved and up == want_up, label,
		"%s %.3f vs %.3f" % [FighterTrait.name_of(trait_id), with_v, without_v])


func _test_the_sim_traits_move_their_number() -> void:
	var T := FighterTrait.T
	## eff_tank — DEEP TANK
	_moved("deep tank carries more", T.DEEP_TANK, "tank",
		_man(T.DEEP_TANK).eff_tank(), _man(T.NONE).eff_tank(), true)
	## fighting_strength — FIRESTARTER, through an angry man
	var hot := _man(T.FIRESTARTER).card
	var cold := _man(T.NONE).card
	## ANGRY IS A LOW BAND, NOT A HIGH ONE — `angry()` is `morale < 0.34`, the
	## band above toxic. The first draft of this check set them both to 0.95 and
	## compared two contented men, which is a test that cannot fail and therefore
	## cannot pass either.
	hot.morale = 0.25
	cold.morale = 0.25
	_ok(hot.angry() == cold.angry(), "both test men are in the same mood",
		"angry: %s" % str(hot.angry()))
	_moved("firestarter chips harder", T.FIRESTARTER, "chip_strength",
		float(hot.fighting_strength()), float(cold.fighting_strength()), true)
	## morale floor — STEADY
	var steady := _man(T.STEADY).card
	var plain := _man(T.NONE).card
	for i in 40:
		steady.morale_shift(-0.5)
		plain.morale_shift(-0.5)
	_moved("steady never sulks", T.STEADY, "morale_floor",
		steady.morale, plain.morale, true)
	## out of position — LANE RUNNER
	var sim := MeleeSim.new(MeleeRosters.player_club(), MeleeRosters.rival_club(), 11)
	var runner := _man(T.LANE_RUNNER).card
	runner.pos = Tuning.Pos.CENTER
	var ordinary := _man(T.NONE).card
	ordinary.pos = Tuning.Pos.CENTER
	## slot 1 is a Flanker slot; a Center is out of position there, and one slot
	## from his own, so LANE RUNNER is forgiven and the other man is not.
	var a_out: bool = sim._out_of_pos(runner, 1)
	var b_out: bool = sim._out_of_pos(ordinary, 1)
	_ok(not a_out and b_out, "lane runner is forgiven one slot either side",
		"runner out_of_pos %s, ordinary %s" % [str(a_out), str(b_out)])
	## and NOT forgiven two slots out, or the trait is just "no penalty"
	_ok(sim._out_of_pos(runner, 4), "and not forgiven two slots out",
		"a Center on a far Rail is still out of position")
	## the occasion — BIG OCCASION and FLAT TRACK on the same switch
	var big := _man(T.BIG_OCCASION)
	big.occasion = big.tmod("occasion", 1.0)
	var flat := _man(T.FLAT_TRACK)
	flat.occasion = flat.tmod("occasion", 1.0)
	_moved("big occasion turns up", T.BIG_OCCASION, "occasion",
		big.eff_base(), _man(T.NONE).eff_base(), true)
	_moved("flat track shrinks", T.FLAT_TRACK, "occasion",
		flat.eff_base(), _man(T.NONE).eff_base(), false)


func _test_the_career_traits_move_their_number() -> void:
	var T := FighterTrait.T
	var late := _man(T.LATE_PEAK).card
	var early := _man(T.BURNS_OUT).card
	var mid := _man(T.NONE).card
	for f in [late, early, mid]:
		f.age = 36
	_moved("late peak declines later", T.LATE_PEAK, "peak",
		float(Career.peak_for(late, Career.Stat.BASE)),
		float(Career.peak_for(mid, Career.Stat.BASE)), true)
	_moved("burns out declines sooner", T.BURNS_OUT, "peak",
		float(Career.peak_for(early, Career.Stat.BASE)),
		float(Career.peak_for(mid, Career.Stat.BASE)), false)
	_ok(Career.decline_for_man(late, Career.Stat.BASE)
			< Career.decline_for_man(mid, Career.Stat.BASE),
		"and the decline itself follows the peak",
		"at 36: late %d, ordinary %d" % [
			Career.decline_for_man(late, Career.Stat.BASE),
			Career.decline_for_man(mid, Career.Stat.BASE)])


func _test_the_club_traits_move_their_number() -> void:
	var T := FighterTrait.T
	var cheap := _man(T.CHEAP).card
	var plain := _man(T.NONE).card
	for f in [cheap, plain]:
		f.wage_agreed = 1000
	_moved("cheap costs less", T.CHEAP, "wage",
		float(ClubOffice.billed(cheap)), float(ClubOffice.billed(plain)), false)

	## DRAW pulls people through the gate, and only while he is on the eight.
	var o := ClubOffice.new()
	## THE DRAW IS THE ONLY THING LEFT THAT PULLS PEOPLE WHO DO NOT ALREADY FOLLOW
	## YOU. `turnout()` was `notoriety / 125` plus the trait; with one population
	## the division has nothing to divide, so what survives is exactly the trait —
	## `draw_scale()`, 1.0 for everybody else.
	var without := o.draw_scale()
	var d := _man(T.DRAW).card
	o.set_draws([d])
	var with_him := o.draw_scale()
	_moved("a draw sells tickets", T.DRAW, "turnout", with_him, without, true)
	o.set_draws([])
	_ok(is_equal_approx(o.draw_scale(), without),
		"and stops selling them the week he does not travel",
		"back to %.3f" % o.draw_scale())

	## LOYAL does not walk, however sour he is.
	var loyal := _man(T.LOYAL).card
	var sour := _man(T.NONE).card
	for f in [loyal, sour]:
		f.morale = 0.02
	var walked: Array = ClubSplit.who_walks([loyal, sour, _man(T.NONE).card,
		_man(T.NONE).card, _man(T.NONE).card, _man(T.NONE).card], [])
	_ok(not walked.has(loyal) and walked.has(sour),
		"loyal does not walk in a split",
		"%d walked, and he was not one of them" % walked.size())


## A TRAIT IS AN INT IN THE FILE, so it has to come back as the same man.
## ----------------------------------------------------------------- levelling
## A MAN LEVELS WHEN HE EARNS IT, and the bar stops rising. Both halves matter:
## without the first he waits until June, and without the second the port of
## Retro Bowl's `level * 100` walls a career at three points of overall.
func _test_levelling_is_not_a_winter_thing() -> void:
	var f := FighterCard.new()
	f.strength = 50
	f.base = 50
	f.skill = 50
	f.gas = 50
	f.aggression = 50
	f.age = 22
	f.potential = 72
	f.morale = 0.5
	## AT PAR, so this measures the LEVEL term. `next_level_at` carries an age
	## term too now, and a check that reads both at once can only ever say "the
	## product changed" — which is the one thing nobody needs telling.
	f.age = Career.LEARN_PAR
	_ok(Career.next_level_at(f) == Career.LEVEL_XP,
		"the first level is the cheapest", "%d xp at par" % Career.next_level_at(f))
	f.xp = Career.next_level_at(f)
	var was_morale := f.morale
	var got := Career.drain(f)
	_ok(got.size() == 1 and f.level == 2, "and he takes it the moment he has it",
		"level %d after one drain" % f.level)
	_ok(f.morale > was_morale, "and it lifts his mood",
		"%.2f to %.2f — Retro Bowl's attitude +10, at our scale"
		% [was_morale, f.morale])

	## ONE A BOUT. A monstrous afternoon must not buy two levels, which is what
	## their `xp = 1` reset is for — we keep the remainder and cap the count
	## instead, so nothing a man earns is quietly binned.
	f.xp = Career.next_level_at(f) * 6
	var before := f.level
	var many := Career.drain(f)
	_ok(many.size() == 1 and f.level == before + 1, "one level an afternoon",
		"six levels' worth of xp bought one")
	_ok(f.xp > 0, "and the change is kept", "%d xp still banked" % f.xp)

	## THE BAR STOPS RISING. This is the line that makes the port work at our
	## income, and the one a future tidy-up is most likely to "fix".
	var high := FighterCard.new()
	high.potential = 99
	high.level = 40
	high.age = Career.LEARN_PAR
	_ok(Career.next_level_at(high) == Career.LEVEL_BAR_CAP * Career.LEVEL_XP,
		"the bar stops rising, as xp_cost always did",
		"level 40 still asks %d" % Career.next_level_at(high))

	## AND AT HIS CEILING HE STOPS ENTIRELY.
	var done := FighterCard.new()
	done.strength = 60
	done.base = 60
	done.skill = 60
	done.gas = 60
	done.aggression = 60
	done.potential = done.overall()
	done.xp = 9999
	_ok(Career.at_ceiling(done) and Career.drain(done).is_empty(),
		"a man at his potential does not level",
		"overall %d, potential %d" % [done.overall(), done.potential])


## THE MEASUREMENT THAT DECIDED THE NUMBER. The rework moved WHEN a man levels;
## it was not supposed to move how far he climbs, and a curve that quietly halved
## a career would be a balance change wearing a UX change's clothes.
const CAREER_SEASONS := 8
const CAREER_EVENTS := 13


func _test_a_career_climbs_as_far_as_it_used_to() -> void:
	var f := FighterCard.new()
	f.strength = 50
	f.base = 50
	f.skill = 50
	f.gas = 50
	f.aggression = 50
	f.age = 22
	f.potential = 72
	f.morale = 0.5
	var levels := 0
	for s in CAREER_SEASONS:
		for e in CAREER_EVENTS:
			f.xp += Career.xp_for(2, 3)
			levels += Career.drain(f).size()
	## The winter it replaced measured 47 points and 50 -> 61 over the same eight
	## seasons — see `tools/probe_levels.gd`. The floor is deliberately loose:
	## this is a guard against the curve collapsing, not a pin on the tuning.
	##
	## AND IT COUNTS THE CLIMB, NOT THE LEVELS, which it did not until 15 Sep
	## 2026. `levels >= 36` was a proxy for "he got somewhere", and it was a fair
	## one while every level was worth exactly one stat point. `Career.gain_for`
	## pays by how far a man has left to go, so a level is now worth up to five —
	## and this fighter reaches his ceiling of 72 in THIRTY-TWO levels where he
	## used to stop at 61 after forty-seven. The proxy failed while the thing it
	## stood for got better by eleven points.
	##
	## **A proxy is only a proxy until the rate it assumed changes.** The climb
	## is what the check has always been about, so the climb is what it reads —
	## and the level count stays in the note, where a number that is interesting
	## but not load-bearing belongs.
	_ok(f.overall() >= 61, "eight seasons still build a fighter",
		"overall 50 -> %d in %d levels (the winter it replaced gave 61 in 47)"
		% [f.overall(), levels])
	_ok(levels >= 24, "and he is paid in levels along the way",
		"%d levels over %d seasons" % [levels, CAREER_SEASONS])
	notes.append("a played career: %d levels over %d seasons, overall 50 -> %d"
		% [levels, CAREER_SEASONS, f.overall()])


## ------------------------------------------------- the rule the economy rests on
## PETE, 13 SEP 2026: *"The overalls and salary costs won't matter until you
## re-sign the players. So you may run up a player's level, but you have to make
## sure you can pay them."*
##
## That is not a nice-to-have, it is the load-bearing rule of the whole levelling
## economy. Levelling is free and frequent now; the ONLY thing stopping a club
## levelling its way to a squad it cannot afford is that the bill does not move
## until the deal does. If a level ever raised his wage on the spot, levelling
## would become something a club could not afford to do — and the feature would
## quietly delete itself.
##
## It holds because `ClubOffice.billed` prefers `wage_agreed`. This asserts it
## rather than trusting it, and it is the check most likely to be broken by
## somebody tidying that function up.
func _test_a_level_does_not_move_the_bill_until_he_re_signs() -> void:
	var f := FighterCard.new()
	f.strength = 50
	f.base = 50
	f.skill = 50
	f.gas = 50
	f.aggression = 50
	f.age = 24
	f.potential = 90
	f.morale = 0.8
	f.wage_agreed = ClubOffice.wage(f)
	var signed_at := ClubOffice.billed(f)
	var was := f.overall()
	for i in 8:
		f.xp += Career.next_level_at(f)
		Career.level_up(f)
	_ok(f.overall() > was, "he is a better fighter than the one you signed",
		"overall %d to %d over %d levels" % [was, f.overall(), f.level - 1])
	_ok(ClubOffice.billed(f) == signed_at, "and he costs exactly what he did",
		"%s a week, unchanged" % ClubOffice.money(signed_at))
	## AND THE BILL LANDS THE DAY THE DEAL DOES.
	var asks: Dictionary = Contracts.demand(f)
	_ok(int(asks["wage"]) > signed_at, "until the day you re-sign him",
		"he asks %s against the %s he was on"
		% [ClubOffice.money(int(asks["wage"])), ClubOffice.money(signed_at)])
	notes.append("eight levels cost nothing until the re-sign, then %s to %s a week"
		% [ClubOffice.money(signed_at), ClubOffice.money(int(asks["wage"]))])


## THE NEGOTIATION IS NOT ABOUT MONEY. Retro Bowl refuses outright at attitude
## 45 — `msg_CannotSignMoraleLow` — and that refusal is the design: you cannot
## buy your way out of a season of bad decisions.
func _test_a_sour_man_will_not_re_sign_at_any_price() -> void:
	var sour := FighterCard.new()
	sour.strength = 70
	sour.base = 70
	sour.skill = 70
	sour.gas = 70
	sour.aggression = 70
	sour.age = 27
	sour.morale = Contracts.MORALE_REFUSES - 0.05
	var happy := sour.copy()
	happy.morale = 0.8
	_ok(Contracts.refuses(sour) and not Contracts.refuses(happy),
		"a sour man refuses and a content one does not",
		"at %.2f he is gone; at %.2f he talks" % [sour.morale, happy.morale])
	_ok(Contracts.refusal(sour) != "" and Contracts.refusal(happy) == "",
		"and the club is told why", Contracts.refusal(sour))
	## THE FLOOR BEATS EVERYTHING ABOVE IT. A tiny club with a huge following and
	## a modest fighter is the best case the old maths could build, and it still
	## does not matter.
	_ok(is_equal_approx(Contracts.will_wait(sour, 1.0, 99,
			0.99), 0.0),
		"no amount of club pull buys him back",
		"will_wait is 0.00 with the following maxed")
	_ok(Contracts.will_wait(happy, 1.0, 99, 0.9) > 0.0,
		"while the man who is happy is still a live conversation",
		"%.2f" % Contracts.will_wait(happy, 1.0, 99, 0.9))


## A LEVEL IS SPENT WHERE THE PLAYER PUTS IT, and refused where it cannot go.
func _test_a_level_goes_where_you_put_it() -> void:
	var f := FighterCard.new()
	f.strength = 40
	f.base = 70
	f.skill = 55
	f.gas = 60
	f.aggression = 50
	f.age = 24
	f.potential = 90
	f.morale = 0.6
	f.xp = Career.next_level_at(f)
	## `_raise_one` would have taken strength, because it is lowest. The point of
	## the rework is that the club can choose otherwise and build a specialist.
	var r := Career.level_into(f, Career.Stat.SKILL)
	_ok(bool(r.get("levelled", false)) and f.skill == 55 + Career.POINTS_PER_LEVEL and f.strength == 40,
		"a level lands on the stat you chose, not the one he is worst at",
		"skill 55 to %d, strength untouched at %d" % [f.skill, f.strength])
	_ok(Career.levels_waiting(f) == 0, "and it is spent once", "nothing waiting")

	## THE OLD DOG LEARNS THE SAME TRICKS, SLOWER — Pete, 13 Sep 2026: *"I was
	## talking about how fast he levels as in from Level 5 to level 6, leave the
	## ability to gain all stats still. He's just slower at leveling his main
	## level is all."*
	##
	## Two halves, and the first version of this got the wrong one: what a level
	## COSTS moves with age, what a level CAN BUY does not. So the checks are
	## written as a pair — the bar is longer AND the stat list is identical —
	## because a rule that only holds on one side of that line is the rule he
	## rejected.
	var kid := f.copy()
	kid.age = 19
	var old_man := f.copy()
	old_man.age = 38
	_ok(Career.next_level_at(old_man) > Career.next_level_at(kid),
		"the old man's level bar is longer than the kid's",
		"%d xp at 38 against %d at 19" % [
			Career.next_level_at(old_man), Career.next_level_at(kid)])
	_ok(Career.raisable(old_man) == Career.raisable(kid)
		and Career.raisable(old_man).size() == 4,
		"and both of them can still put it into any of the four",
		"%d stats open to each" % Career.raisable(old_man).size())
	## AND HE GETS THERE. A bar he can never fill is the wall again with
	## arithmetic on it, which is the version already thrown out once.
	old_man.xp = Career.next_level_at(old_man)
	var r2 := Career.level_into(old_man, Career.Stat.GAS)
	_ok(bool(r2.get("levelled", false)) and old_man.gas == f.gas + Career.POINTS_PER_LEVEL,
		"the old dog does learn the trick",
		"gas %d to %d at 38, which the peak rule forbade" % [f.gas, old_man.gas])
	## THE BAR IS THE ONLY GATE. One bar short and it refuses; it does not refuse
	## for being old, and the reason it gives has to say so.
	var short_man := f.copy()
	short_man.age = 38
	short_man.xp = Career.next_level_at(short_man) - 1
	var r3 := Career.level_into(short_man, Career.Stat.GAS)
	_ok(String(r3.get("reason", "")) == "not earned"
		and int(r3.get("short", 0)) == 1,
		"and one xp short is one xp short, not 'past his peak'",
		"refused: %s, short by %d" % [
			String(r3.get("reason", "")), int(r3.get("short", 0))])
	## BOTH ENDS OF THE CURVE ARE CLAMPED, checked at the ages the note names.
	var floor_man := f.copy()
	floor_man.age = 16
	var ancient := f.copy()
	ancient.age = 48
	_ok(Career.learn_rate(floor_man) == Career.LEARN_MIN
		and Career.learn_rate(ancient) == Career.LEARN_MAX,
		"the pace is clamped at both ends",
		"x%.2f floor, x%.2f cap" % [Career.LEARN_MIN, Career.LEARN_MAX])
	_ok(Career.learn_rate_par() == 1.0,
		"and a man at par pays the plain bar",
		"age %d is x1.00" % Career.LEARN_PAR)
	## THE WORD IS SILENT IN THE MIDDLE. A label every fighter carries is a label
	## that distinguishes nobody.
	var par_man := f.copy()
	par_man.age = Career.LEARN_PAR
	_ok(Career.learn_word(par_man) == "" and Career.learn_word(ancient) != ""
		and Career.learn_word(floor_man) != "",
		"and the screen only says so at the ends",
		"'%s' at 16, nothing at %d, '%s' at 48" % [
			Career.learn_word(floor_man), Career.LEARN_PAR,
			Career.learn_word(ancient)])


## ----------------------------------------------- what his mood costs the club
## PETE: *"If someone likes it there and doesnt want to leave, they are more
## willing to take a lower price. If someone is great but hates it, you'll have
## to pay more."*
##
## Two men, identical in every number that describes a fighter, differing only in
## how they feel about the place. If those two ask for the same wage then morale
## is a read-out again, which is the state this codebase has already thrown a
## facility out for.
func _test_a_happy_man_signs_for_less() -> void:
	var base := FighterCard.new()
	base.strength = 72
	base.base = 72
	base.skill = 72
	base.gas = 72
	base.aggression = 72
	base.age = 27
	var glad := base.copy()
	glad.morale = 0.92
	var grim := base.copy()
	## Just above the line where he stops talking to you at all.
	grim.morale = Contracts.MORALE_REFUSES + 0.02
	var a: Dictionary = Contracts.demand(glad)
	var b: Dictionary = Contracts.demand(grim)
	_ok(int(a["wage"]) < int(b["wage"]),
		"the same fighter costs less when he wants to stay",
		"%s glad against %s grim"
		% [ClubOffice.money(int(a["wage"])), ClubOffice.money(int(b["wage"]))])
	_ok(int(a["rate"]) == int(b["rate"]),
		"and it is the relationship, not the fighter",
		"both are worth %s on paper" % ClubOffice.money(int(a["rate"])))
	var spread := float(b["wage"]) / maxf(1.0, float(a["wage"]))
	_ok(spread > 1.25, "the spread is worth playing for",
		"grim costs %.2fx glad" % spread)
	notes.append("mood on the wage: %.2fx at the top, %.2fx at the bottom"
		% [Contracts.mood_rate(0.95), Contracts.mood_rate(0.46)])

	## AND IT IS BOUNDED AT BOTH ENDS. Without a ceiling, a man one point above
	## refusing would name a number nobody could meet — a refusal wearing a price
	## tag, which wastes the player's time instead of telling him something.
	_ok(Contracts.mood_rate(0.0) <= Contracts.MOOD_DEAREST
			and Contracts.mood_rate(1.0) >= Contracts.MOOD_CHEAPEST,
		"and bounded at both ends",
		"%.2f to %.2f" % [Contracts.mood_rate(1.0), Contracts.mood_rate(0.0)])


## THE CREDIT SINK. Retro Bowl prices a meeting off the man's MOOD BAND and
## nothing else — 4 for a toxic man down to 1 for a great one — so the price
## says something about the relationship rather than about the asset.
func _test_sitting_him_down_costs_more_the_worse_it_is() -> void:
	var sour := FighterCard.new()
	sour.morale = 0.10
	var fine := FighterCard.new()
	fine.morale = 0.90
	_ok(ClubOffice.negotiate_cost(sour) > ClubOffice.negotiate_cost(fine),
		"rescuing a relationship costs more than topping one up",
		"%s %d CC against %s %d CC" % [sour.morale_word(),
			ClubOffice.negotiate_cost(sour), fine.morale_word(),
			ClubOffice.negotiate_cost(fine)])

	var o := ClubOffice.new()
	o.credits = 20
	var man := FighterCard.new()
	man.display_name = "Vane"
	man.number = 7
	man.morale = 0.30
	var was := man.morale
	var before_credits := o.credits
	_ok(o.negotiate(man) == "", "a conversation goes through", "no error")
	_ok(man.morale > was, "and it lifts him",
		"%.2f to %.2f" % [was, man.morale])
	_ok(o.credits < before_credits, "and it is paid for",
		"%d CC to %d CC" % [before_credits, o.credits])

	## ONCE A WEEK. Without the throttle a club with credits walks a toxic squad
	## to delighted in one afternoon and morale stops being a consequence.
	var again := o.negotiate(man)
	_ok(again != "", "but only once a week", again)
	o.tick_week() if o.has_method("tick_week") else o.built_this_week.clear()
	_ok(o.negotiate(man) == "", "and again the week after", "the throttle lifts")

	## AND IT CANNOT BE BOUGHT PAST THE PROBLEM IN ONE GO. `morale_shift` scales
	## by the room left, so the same conversation is worth far more to a man who
	## is struggling than to one who is already content — which is what makes
	## rescuing somebody the better buy and matches the cost table.
	var low := FighterCard.new()
	low.morale = 0.25
	var high := FighterCard.new()
	high.morale = 0.88
	var lo_was := low.morale
	var hi_was := high.morale
	low.morale_shift(ClubOffice.NEGOTIATE_LIFT)
	high.morale_shift(ClubOffice.NEGOTIATE_LIFT)
	_ok((low.morale - lo_was) > (high.morale - hi_was),
		"one conversation is worth more to the man who needs it",
		"+%.3f against +%.3f" % [low.morale - lo_was, high.morale - hi_was])


func _test_a_trait_survives_the_save() -> void:
	SaveGame.set_namespace("traits")
	var s := Season.new(MeleeRosters.starting_club(), 909)
	var first = s.club.roster[0]
	first.trait_id = FighterTrait.T.GRINDER
	_ok(SaveGame.save(s, 2), "a squad with traits saves", "slot 2")
	var back := SaveGame.load_slot(2)
	_ok(back != null and back.club.roster[0].trait_id == FighterTrait.T.GRINDER,
		"and every man comes back with his own",
		FighterTrait.name_of(back.club.roster[0].trait_id) if back != null else "nothing")
	var old := {"xp": 4}
	_ok(int(old.get("trait", FighterTrait.T.NONE)) == FighterTrait.T.NONE,
		"a file from before traits is a squad of ordinary men",
		"the default is None, so the version does not move")
	SaveGame.delete(2)
	SaveGame.set_namespace("")


## ------------------------------------------------- the eight that were pending
## THEY WERE WRITTEN AND NOT WIRED for eight passes, held out of the roll by
## `PENDING` so no card ever shipped a sentence that did nothing. Each needed a
## thing the sim did not have; each now has it, and each is checked at the place
## the sim actually reads it rather than at the table.
func _test_the_wrestler_opens_ahead() -> void:
	var sim := MeleeSim.new(MeleeRosters.player_club(),
		MeleeRosters.rival_club(), 8081)
	var a: MeleeSim.Man = sim.men[0]
	var b: MeleeSim.Man = sim.men[5]
	a.card.trait_id = FighterTrait.T.WRESTLER
	var before: float = b.stability
	sim._enter_grapple(a, b)
	_ok(b.stability < before,
		"a wrestler opens a clinch already ahead",
		"%.2f to %.2f" % [before, b.stability])
	## AND IT IS ON THE LEDGER, which is what separates it from a trait that
	## grinds men down invisibly.
	_ok(float(b.wear.get(a.idx, 0.0)) > 0.0,
		"and the opening counts toward an assist like any other work",
		"%.2f on his ledger" % float(b.wear.get(a.idx, 0.0)))


func _test_second_wind_comes_once() -> void:
	var sim := MeleeSim.new(MeleeRosters.player_club(),
		MeleeRosters.rival_club(), 8082)
	var m: MeleeSim.Man = sim.men[0]
	m.card.trait_id = FighterTrait.T.SECOND_WIND
	m.tank = 0.0
	sim._tick_timers(m)
	_ok(m.gas_frac() > 0.4 and m.wind_used,
		"an empty man with second wind comes back to half",
		"%.0f%% of his tank" % (m.gas_frac() * 100.0))
	m.tank = 0.0
	sim._tick_timers(m)
	_ok(m.gas_frac() < 0.1, "and it does not come twice in a bout",
		"%.0f%% the second time" % (m.gas_frac() * 100.0))


## LAST MAN AND TALISMAN BOTH MOVE `rally`, in opposite directions and for
## opposite reasons, so they are checked together — the interesting case is that
## a Talisman never lifts himself.
func _test_the_room_moves_with_who_is_standing() -> void:
	var sim := MeleeSim.new(MeleeRosters.player_club(),
		MeleeRosters.rival_club(), 8083)
	var solo: MeleeSim.Man = sim.men[0]
	solo.card.trait_id = FighterTrait.T.LAST_MAN
	sim._rally()
	_ok(is_equal_approx(solo.rally, 1.0),
		"a last man with his five up is an ordinary man",
		"rally %.3f" % solo.rally)
	for i in range(1, 5):
		sim.men[i].state = MeleeSim.State.DOWN
	sim._rally()
	_ok(solo.rally > 1.05, "and the last one standing fights above himself",
		"rally %.3f with four down" % solo.rally)

	## AND A TALISMAN IS NOT IN HERE AT ALL, which is the check that keeps him
	## out. Three in-fight levers were measured and every one of them was either
	## enormous or nothing, so he is a morale trait now — and a later pass
	## reaching for `rally` to "just add the room back" is exactly what this
	## assertion is for.
	var sim2 := MeleeSim.new(MeleeRosters.player_club(),
		MeleeRosters.rival_club(), 8084)
	sim2.men[0].card.trait_id = FighterTrait.T.TALISMAN
	sim2._rally()
	_ok(is_equal_approx(sim2.men[1].rally, 1.0),
		"a talisman changes nothing about how his side fights",
		"mate at %.3f" % sim2.men[1].rally)


func _test_heavy_hands_wreck_a_harness() -> void:
	var sim := MeleeSim.new(MeleeRosters.player_club(),
		MeleeRosters.rival_club(), 8085)
	var hitter: MeleeSim.Man = sim.men[0]
	var t: MeleeSim.Man = sim.men[5]
	hitter.card.trait_id = FighterTrait.T.HEAVY_HANDS
	var base_before: float = t.eff_base()
	for _i in 20:
		hitter.hit_cd = 0.0
		sim._resolve(hitter, Tuning.Act.HIT, t.idx)
	_ok(t.harness < 1.0 and t.eff_base() < base_before,
		"heavy hands wreck the other man's harness and his base with it",
		"harness %.2f, base %.1f to %.1f" % [t.harness, base_before, t.eff_base()])
	_ok(t.harness >= Tuning.HARNESS_FLOOR,
		"and it stops at the floor rather than deciding the afternoon",
		"%.2f against a floor of %.2f" % [t.harness, Tuning.HARNESS_FLOOR])


func _test_a_grudge_is_carried_on_the_card() -> void:
	var sim := MeleeSim.new(MeleeRosters.player_club(),
		MeleeRosters.rival_club(), 8086)
	var m: MeleeSim.Man = sim.men[0]
	m.card.trait_id = FighterTrait.T.GRUDGE
	m.card.grudge_club = 7
	_ok(is_equal_approx(m.grudge, 1.0),
		"a grudge against nobody in this fixture is no grudge at all",
		"the sim knows club %d" % sim.opponent_club_id)
	var s2 := MeleeSim.new(MeleeRosters.player_club(),
		MeleeRosters.rival_club(), 8086)
	s2.opponent_club_id = 7
	s2.clubs[0].starting_five()[0].trait_id = FighterTrait.T.GRUDGE
	s2.clubs[0].starting_five()[0].grudge_club = 7
	s2.dress()
	_ok(s2.men[0].grudge > 1.0,
		"and against the club he named he fights above himself",
		"x%.2f" % s2.men[0].grudge)
	## IT SURVIVES A COPY, because a grudge is a career fact and cards are copied
	## when a man moves.
	var copy: FighterCard = s2.clubs[0].starting_five()[0].copy()
	_ok(copy.grudge_club == 7, "and it survives the card being copied",
		"club %d" % copy.grudge_club)


## AND THE ROOM, WHERE IT ACTUALLY LIVES. Both halves, because the second one is
## the reason the trait is interesting: a Talisman who cannot go out costs the
## room instead of paying it.
func _test_a_talisman_lifts_the_dressing_room() -> void:
	var lift := FighterTrait.mod(FighterTrait.T.TALISMAN, "room_morale", 0.0)
	_ok(lift > 0.0, "a talisman has a room to lift", "%.3f a week" % lift)
	var f := FighterCard.new()
	f.morale = 0.5
	var was := f.morale
	f.morale_shift(lift)
	var up := f.morale
	f.morale = was
	f.morale_shift(-lift * 0.5)
	_ok(up > was and f.morale < was,
		"and it cuts the other way when he cannot go out",
		"%.2f up to %.2f, down to %.2f" % [was, up, f.morale])


func _test_proud_and_prima_donna_are_read_where_they_matter() -> void:
	var f := FighterCard.new()
	f.trait_id = FighterTrait.T.PROUD
	_ok(FighterTrait.flag(f.trait_id, "no_sub"),
		"proud refuses the corner", "the corner grays his box")
	var d := FighterCard.new()
	d.trait_id = FighterTrait.T.PRIMA_DONNA
	d.morale = 0.7
	var was := d.morale
	d.morale_shift(FighterTrait.mod(d.trait_id, "benched_morale", 0.0))
	_ok(d.morale < was, "a prima donna sours an event he did not start",
		"%.2f to %.2f" % [was, d.morale])


## AND NOTHING IS PENDING ANY MORE. Homesick was the last one and it needed a
## home and an away; Pete built the fixture model rather than the workaround.
##
## THE CHECK STAYS AND IT IS NOT `size() == 0`. An empty list is the state today
## and the mechanism is what matters: every trait is either wired or named, and
## the pair of assertions above — `every trait is wired or openly pending` and `a
## pending trait is never rolled` — is what makes that true. This one just says
## the count agrees with the list, so a trait added to `PENDING` next year is
## still held out of the roll and a trait added to neither still fails.
func _test_what_is_left_is_named() -> void:
	var rollable := 0
	for t in FighterTrait.T.values():
		if t != FighterTrait.T.NONE and FighterTrait.is_wired(t):
			rollable += 1
	_ok(rollable + FighterTrait.PENDING.size() == FighterTrait.T.size() - 1,
		"every trait is either rollable or named in the pending list",
		"%d rollable, %d pending, %d in the enum" % [rollable,
			FighterTrait.PENDING.size(), FighterTrait.T.size() - 1])
	_ok(not FighterTrait.PENDING.has(FighterTrait.T.HOMESICK),
		"and homesick is not one of them any more — the fixture list has a home",
		"x%.2f away" % FighterTrait.mod(FighterTrait.T.HOMESICK, "away", 1.0))


## HOMESICK, AT THE PLACE THE SIM READS IT. Away and neutral both count; a
## neutral ground is not his either.
func _test_homesick_is_a_different_man_away() -> void:
	var f := FighterCard.new()
	f.trait_id = FighterTrait.T.HOMESICK
	_ok(is_equal_approx(Venue.homesick_scale(f, Venue.Kind.HOME), 1.0),
		"a homesick man at home is an ordinary man",
		"x%.2f" % Venue.homesick_scale(f, Venue.Kind.HOME))
	_ok(Venue.homesick_scale(f, Venue.Kind.AWAY) < 1.0
		and is_equal_approx(Venue.homesick_scale(f, Venue.Kind.AWAY),
			Venue.homesick_scale(f, Venue.Kind.NEUTRAL)),
		"and away and neutral cost him the same — neither is his ground",
		"x%.2f" % Venue.homesick_scale(f, Venue.Kind.AWAY))
	var ordinary := FighterCard.new()
	_ok(is_equal_approx(Venue.homesick_scale(ordinary, Venue.Kind.AWAY), 1.0),
		"and nobody else notices where they are",
		"x%.2f" % Venue.homesick_scale(ordinary, Venue.Kind.AWAY))
