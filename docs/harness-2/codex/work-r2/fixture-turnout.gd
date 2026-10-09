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
	f.harness = 0
	f.armor = 1.0
	s.office.set_draws([f])
	var rust := s.office.draw_scale()
	f.harness = 4
	s.office.set_draws([f])
	ok(is_equal_approx(s.office.draw_scale()-rust,.06), "quality draw reaches attendance multiplier")
	s.office.set_draws([f])
	ok(is_equal_approx(s.office.draw_scale()-rust,.06), "refresh is idempotent")
	f.armor = 0.0
	s.office.set_draws([f])
	ok(is_equal_approx(s.office.draw_scale(),rust), "worn kit loses draw bonus")
	print("FIXTURE checks=",checks," failures=",JSON.stringify(failures))
	quit(0 if failures.is_empty() else 1)
