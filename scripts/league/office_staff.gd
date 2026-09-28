class_name OfficeStaff
extends RefCounted
## Methods of `ClubOffice`, moved out of club_office.gd so that file is not one
## three-thousand-line object. Every function takes the ClubOffice as `o`; `ClubOffice`
## keeps a one-line wrapper for each, so callers did not change.




## WHICH REGIME APPLIES TO A ROLE. A role a captain teaches is trained his way;
## a role NOBODY teaches is trained nobody's way, which is Normal — the man is
## turning up and doing what he has always done.
static func regime_for(o: ClubOffice, role: int) -> int:
	for c in o.captains:
		if ClubOffice.specialties_of(c).has(role):
			return int(c.get("regime", ClubOffice.Regime.NORMAL))
	return ClubOffice.Regime.NORMAL




static func set_regime(o: ClubOffice, index: int, regime: int) -> String:
	if index < 0 or index >= o.captains.size():
		return UiKit.t("There is no captain in that job.")
	if regime < ClubOffice.Regime.LIGHT or regime > ClubOffice.Regime.HARD:
		return UiKit.t("That is not a regime.")
	o.captains[index]["regime"] = regime
	return ""




## The four multipliers, by the role a man stands in.
static func regime_xp(o: ClubOffice, role: int) -> float:
	return float(ClubOffice.REGIME_XP[o.regime_for(role)])




static func regime_morale(o: ClubOffice, role: int) -> float:
	return float(ClubOffice.REGIME_MORALE[o.regime_for(role)])




static func regime_wear(o: ClubOffice, role: int) -> float:
	return float(ClubOffice.REGIME_WEAR[o.regime_for(role)])




static func regime_injury(o: ClubOffice, role: int) -> float:
	return float(ClubOffice.REGIME_INJURY[o.regime_for(role)])




static func captain(nm: String, a: int, b: int, grade: int = 2, trait_: int = ClubOffice.Trait.NONE) -> Dictionary:
	## HIS GRADE SAYS HOW MANY HE TEACHES. Two different roles at the top, one in
	## the middle, none at the bottom — and a captain who lists the same job
	## twice knows one job, which is the half-coverage the whole model exists to
	## refuse.
	var second: int = b if b != a else (a + 1) % 3
	var spec: Array = [a, second]
	spec.resize(ClubOffice.specialty_count(grade))
	return {
		"name": nm, "specialties": spec, "grade": grade,
		"regime": ClubOffice.Regime.NORMAL, "trait": trait_,
		## A CAPTAIN IS ON A DEAL, like everybody else at the club.
		## `msg_StaffExpiring`: *"Your $position's contract expires at the end of
		## this season."* Without it a five-star hired in season two is yours for
		## twenty years for five credits, and the staff room — the screen with the
		## sharpest decision in the game on it — is visited once and never again.
		"years": ClubOffice.CAPTAIN_YEARS,
	}




static func trait_of(c: Dictionary) -> int:
	return int(c.get("trait", ClubOffice.Trait.NONE))




## DOES ANY CAPTAIN BRING THIS TRAIT TO THIS ROLE? One question, one place. Every
## trait below is read through here, so a trait can never apply to a role its
## man does not cover — which is the rule that makes the one-star honest.
static func trait_covers(o: ClubOffice, t: int, role: int) -> bool:
	for c in o.captains:
		if ClubOffice.trait_of(c) == t and ClubOffice.specialties_of(c).has(role):
			return true
	return false




## And the same question with no role in mind, for the traits that are about the
## club rather than about a man — the following, the size of the market.
## HOW MANY EXTRA CALLS THE STAFF IS WORTH. Zero or one today; a sum rather than
## a bool so a second source of calls — if one is ever added — does not have to
## re-decide what "has a Tactician" means.
static func extra_calls(o: ClubOffice) -> int:
	return ClubOffice.TRAIT_TACTICIAN_CALLS if o.has_trait(ClubOffice.Trait.TACTICIAN) else 0




static func has_trait(o: ClubOffice, t: int) -> bool:
	for c in o.captains:
		if ClubOffice.trait_of(c) == t and not ClubOffice.specialties_of(c).is_empty():
			return true
	return false




static func offer(seed_value: int, season_no: int, slot: int, refreshes: int = 0) -> Dictionary:
	var h := absi(hash("cap:%d:%d:%d:%d" % [seed_value, season_no, slot, refreshes]))
	var roles := [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]
	var a: int = roles[h % 3]
	var b: int = roles[(a + 1 + int(h / 3) % 2) % 3]
	## THE FULL FIVE STARS ARE ON THE MARKET, not three of them. The grade used to
	## top out at 3, which — once the grade decided how many roles a man teaches
	## — made a two-specialty captain a thing the code could build and the game
	## could never sell.
	var grade := 1 + int(h / 11) % 5
	## AND A TRAIT, on roughly half of them. Not all, because a man with no trait
	## has to be a real thing on the list or the trait is not a reason to pick
	## anybody — it is just a line every card happens to carry.
	var t: int = ClubOffice.Trait.NONE
	if int(h / 7) % 2 == 0:
		t = 1 + int(h / 13) % (ClubOffice.Trait.SCOUT)
	## AND THE RARE ONE, rolled separately rather than added to the common pool.
	## Dropping TACTICIAN into `% Trait.SCOUT` would have made it as common as
	## Physio, and "rare" was the word in the brief.
	if grade >= ClubOffice.TACTICIAN_GRADE and int(h / 17) % ClubOffice.TACTICIAN_ODDS == 0:
		t = ClubOffice.Trait.TACTICIAN
	return ClubOffice.captain(ClubOffice.OFFER_NAMES[h % ClubOffice.OFFER_NAMES.size()], a, b, grade, t)




static func specialties_of(c: Dictionary) -> Array:
	return c.get("specialties", [])




## WHAT A CAPTAIN TEACHES, IN WORDS, for every screen that prints it. A one-star
## teaches nothing, and the three screens drawing his card each printed the
## heading "Teaches" over an empty space — which reads as a bug rather than as
## the man's actual job. He has one: he is good in a changing room.
static func teaches_list(c: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for r in ClubOffice.specialties_of(c):
		out.append(UiKit.t(String(Tuning.ROLE_NAME[int(r)])))
	if out.is_empty():
		out.append(UiKit.t("Nothing · lifts the room"))
	return out




static func teaches_line(c: Dictionary) -> String:
	return " + ".join(ClubOffice.teaches_list(c))




static func hire(o: ClubOffice, c: Dictionary) -> String:
	if o.captains.size() >= ClubOffice.MAX_CAPTAINS:
		return UiKit.t("You already have two captains. Release one first.")
	var price := ClubOffice.cost_of(c)
	if o.credits < price:
		return UiKit.t("%s costs %d CC and you have %d.") % [String(c.get("name", UiKit.t("A captain"))), price, o.credits]
	o.spend(price, ClubOffice.LINE_SQUAD)
	o.captains.append(c)
	return ""




## WHAT HE DOES ON THE DAY HE WALKS IN. Three of the nine fire once, at the
## hiring, and they are the reason a hire is felt immediately rather than in
## March. Separated from `hire()` because `hire` knows about money and this knows
## about the squad — and because the office does not hold the roster, the season
## does. See `Season.hire_captain`, which is the only caller of both.
static func arrival_effect(o: ClubOffice, c: Dictionary, club) -> Dictionary:
	var t := ClubOffice.trait_of(c)
	var touched: Array[String] = []
	if not ClubOffice.ARRIVAL_TRAITS.has(t) or ClubOffice.specialties_of(c).is_empty():
		return {"trait": t, "men": touched}
	for f in club.roster:
		if not ClubOffice.specialties_of(c).has(Tuning.role_of(int(f.pos))):
			continue
		match t:
			ClubOffice.Trait.EXPERIENCE:
				f.xp += ClubOffice.TRAIT_XP_BANKED
			ClubOffice.Trait.TALENT_SPOTTER:
				f.potential = clampi(f.potential + ClubOffice.TRAIT_CEILING, 1, 99)
			ClubOffice.Trait.MOTIVATOR:
				f.morale_shift(ClubOffice.TRAIT_MORALE)
		touched.append(f.display_name)
	return {"trait": t, "men": touched}




## THE SUMMER, FOR THE STAFF. Everybody loses a year; anybody on zero has gone.
## Returns the names that left, so the summer can say so — a captain who
## disappears silently is a line that starts fighting Green in March for reasons
## the player never sees.
static func age_captains(o: ClubOffice) -> Array[String]:
	var gone: Array[String] = []
	var keep: Array[Dictionary] = []
	for c in o.captains:
		var years := int(c.get("years", ClubOffice.CAPTAIN_YEARS)) - 1
		c["years"] = years
		if years <= 0:
			gone.append(String(c.get("name", UiKit.t("A captain"))))
		else:
			keep.append(c)
	o.captains.clear()
	for c in keep:
		o.captains.append(c)
	return gone




## ANOTHER YEAR COSTS WHAT HE IS WORTH. It was a flat 2 CC for anybody, so a
## five-star hired for 20 was kept forever for 2 a year. Now a fifth of his
## hiring price a year, never less than CAPTAIN_EXTEND — a one-star costs what
## he always did.
static func extend_cost(c: Dictionary) -> int:
	return maxi(ClubOffice.CAPTAIN_EXTEND, int(round(float(ClubOffice.cost_of(c)) * 0.2)))




static func extend_captain(o: ClubOffice, i: int) -> String:
	if i < 0 or i >= o.captains.size():
		return UiKit.t("There is no captain in that job.")
	var price := ClubOffice.extend_cost(o.captains[i])
	if o.credits < price:
		return UiKit.t("Another year costs %d CC and you have %d.") % [price, o.credits]
	o.spend(price, ClubOffice.LINE_SQUAD)
	o.captains[i]["years"] = int(o.captains[i].get("years", 0)) + 1
	return ""




static func release(o: ClubOffice, i: int) -> void:
	if i < 0 or i >= o.captains.size():
		return
	## The crowd's man walks and takes a fifth of the following with him. This is
	## the half of Fan Favorite that makes him a decision rather than a bonus:
	## hiring him is cheap and sacking him is not.
	if ClubOffice.trait_of(o.captains[i]) == ClubOffice.Trait.FAN_FAVORITE and not ClubOffice.specialties_of(o.captains[i]).is_empty():
		o.fans = maxf(0.0, o.fans * ClubOffice.FANS_LOST_FAVORITE)
		o._clamp_fans()
	o.captains.remove_at(i)




## HOW GOOD THE MAN TEACHING THIS ROLE IS — 0 if nobody does, otherwise his
## stars. Pete, 15 Sep 2026: *"The Coaches hold practices, the better the
## coaches, the more you get out of practice."*
##
## `taught()` below has answered this question as a BOOL since the day captains
## were written, and every caller inherited that: a one-star and a five-star
## taught a role identically, and the grade a player paid for reached nothing at
## all except how many roles the man covered. Retro Bowl's Training Facility is
## *"players gain XP faster"* — a multiplier, not a switch — and the grade is
## ours. The best of them wins rather than the sum: two captains on one role is
## already worth something (see `club_specialty`), and adding their stars would
## make doubling up the dominant move on every hire screen.
static func coaching(o: ClubOffice, role: int) -> int:
	var best := 0
	for c in o.captains:
		if ClubOffice.specialties_of(c).has(role):
			best = maxi(best, int(c.get("grade", 1)))
	return best




## Is anybody teaching this role? That is the only question there is.
static func taught(o: ClubOffice, role: int) -> bool:
	for c in o.captains:
		if ClubOffice.specialties_of(c).has(role):
			return true
	return false




## How many captains specialize in it. Only ever used to point out that two of
## them are teaching the same job while another goes without.
static func doubled(o: ClubOffice, role: int) -> bool:
	var n := 0
	for c in o.captains:
		if ClubOffice.specialties_of(c).has(role):
			n += 1
	return n > 1




## THE THING THE CAPTAINS DO. A man's AI tier is set by whether his role is
## taught — not by a difficulty setting, not by his own stats.
##
## Two rungs of the six, because a role is taught or it is not. An untaught role
## goes out **Rust** — it does the opening plan and then stands on its zone,
## which is exactly what Pete described — and a taught one goes out **Hardened**.
## The four rungs above are the league's, not the player's: they describe how
## good a CPU club is, and you climb to meet them rather than buying them.
static func tier_for(o: ClubOffice, role: int) -> int:
	return Tuning.AiSkill.HARDENED if o.taught(role) else Tuning.AiSkill.RUST




## The roles going out untaught — the warning, and the only thing on the staff
## screen the player has to act on.
static func untaught(o: ClubOffice) -> Array:
	var out: Array = []
	for role in [Tuning.Role.RAIL, Tuning.Role.FLANK, Tuning.Role.CENTER]:
		if not o.taught(role):
			out.append(role)
	return out
