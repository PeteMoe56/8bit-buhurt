from pathlib import Path
import shutil
ROOT=Path('C:/Users/PeterM/Documents/Codex/work/harness-2-r2')
MAIN=Path('C:/Dev/RetroBuhurt/docs/harness-2/codex')
common='''extends SceneTree
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
'''
blocks={
'sponsor':'''\tf.harness = 1
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
''',
'turnout':'''\tf.harness = 0
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
''',
'gas':'''\tf.harness = 4
	f.armor = 1.0
	ok(is_equal_approx(f.effective_gas(),53.5) and f.fighting_gas() == 54, "mild gas reaches real melee tank")
	var rating := f.rating()
	f.armor = 0.0
	ok(is_equal_approx(f.effective_gas(),50.0) and f.rating() < rating, "only bonus fades to raw gas")
	f.gas = 99
	f.armor = 1.0
	ok(is_equal_approx(f.effective_gas(),99), "gas ceiling 99")
''',
'reuse':'''\tf.harness = 4
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
''',
'resale':'''\tf.harness = 4
	f.armor = 1.0
	s.office.credits = 0
	ok(Quartermaster.salvage_value(f) == 7, "half cumulative rung cost, not repeat purchase refund")
	Quartermaster.dispose_harness(s.office,f)
	ok(s.office.credits == 7 and f.harness == 0, "resale consumes physical kit")
	Quartermaster.dispose_harness(s.office,f)
	ok(s.office.credits == 7, "idempotent disposal cannot pay twice")
	f.harness = 4
	f.armor = .5
	ok(Quartermaster.salvage_value(f) == 3, "wear reduces resale and rounding goes down")
''',
'control':''}
for name,extra in blocks.items():
    code=common+extra+'\tprint("FIXTURE checks=",checks," failures=",JSON.stringify(failures))\n\tquit(0 if failures.is_empty() else 1)\n'
    (MAIN/f'work-r2/fixture-{name}.gd').write_text(code,encoding='utf-8',newline='\n')
    (ROOT/name/'tools/probe_harness_r2_fixture.gd').write_text(code,encoding='utf-8',newline='\n')
shutil.copyfile(MAIN/'probe_harness_quality_check.gd',ROOT/'gas/tools/probe_harness_quality_check.gd')
