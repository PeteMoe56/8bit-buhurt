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
	f.harness = 1
	f.armor = 1.0
	s.office.credits = 0
	for i in 12: Quartermaster.appearance(s.office, [f])
	ok(s.office.credits == 0 and is_equal_approx(s.office.harness_receipts,.96), "fraction retained without rounding gift")
	var restored := ClubOffice.from_dict(s.office.to_dict())
	Quartermaster.appearance(restored,[f])
	ok(restored.credits == 1 and is_equal_approx(restored.harness_receipts,.04), "save reload carries fraction into booked CC")
	f.harness = 0
	Quartermaster.appearance(restored,[f])
	ok(restored.credits == 1 and is_equal_approx(restored.harness_receipts,.04), "Rust generates no sponsorship")
	f.harness = 4
	f.armor = 0.0
	Quartermaster.appearance(restored,[f])
	ok(restored.credits == 1 and is_equal_approx(restored.harness_receipts,.04), "fully worn kit earns zero")
	f.harness = 4
	f.armor = 1.0
	ok(is_equal_approx(f.effective_gas(),53.5) and f.fighting_gas() == 54, "mild gas reaches real melee tank")
	var rating := f.rating()
	f.armor = 0.0
	ok(is_equal_approx(f.effective_gas(),50.0) and f.rating() < rating, "only bonus fades to raw gas")
	f.gas = 99
	f.armor = 1.0
	ok(is_equal_approx(f.effective_gas(),99), "gas ceiling 99")
	print("FIXTURE checks=",checks," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
