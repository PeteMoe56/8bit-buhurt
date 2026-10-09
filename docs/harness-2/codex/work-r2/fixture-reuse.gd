extends SceneTree
var failures: Array[String] = []
var checks := 0
func ok(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)
	print("CHECK ", label, " ", value)
func _initialize() -> void:
	var f := FighterCard.new()
	f.base = 50
	f.gas = 50
	f.strength = 50
	f.skill = 50
	f.aggression = 50
	f.potential = 70
	var raw := f.ability()
	var room := f.headroom()
	var s := Season.new(MeleeRosters.starting_club(),9001)
	s.club = MeleeClub.new()
	s.club.roster.append(f)
	s.office = ClubOffice.new()
	var wear: Array[float] = []
	for grade in 5:
		f.harness = grade
		f.armor = 1.0
		wear.append(Quartermaster.wear_scale(f))
		SeasonBouts.bout_wear(s)
		ok(is_equal_approx(f.armor, minf(Quartermaster.ceiling(f), 1.0 - .06*Quartermaster.wear_scale(f))), "wear dose grade %d" % grade)
		ok(f.ability() == raw and f.headroom() == room, "raw growth invariant grade %d" % grade)
	for i in 4: ok(wear[i] > wear[i+1], "durability order %d" % i)
	ok(not is_equal_approx(wear[0]-wear[1],wear[1]-wear[2]) and not is_equal_approx(wear[1]-wear[2],wear[2]-wear[3]) and not is_equal_approx(wear[2]-wear[3],wear[3]-wear[4]), "uneven steps include Titanium")
	f.harness = 4
	f.armor = .73
	f.age = 40
	var recipient := FighterCard.new()
	recipient.harness = 1
	recipient.armor = .82
	recipient.age = 25
	s.club.roster.append(recipient)
	Quartermaster.hand_down(f,s.club)
	ok(f.harness == 1 and recipient.harness == 4, "grade stock conserved in swap")
	ok(is_equal_approx(f.armor,.82) and is_equal_approx(recipient.armor,.73), "neither condition is refilled")
	ok(recipient.age == 25 and f.age == 40, "no stats or ages moved")
	f.harness = 4
	f.armor = .39
	recipient.harness = 0
	Quartermaster.hand_down(f,s.club)
	ok(recipient.harness == 0 and f.harness == 4, "worn departure not forced onto recipient")
	print("FIXTURE checks=",checks," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
