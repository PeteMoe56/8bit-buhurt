extends SceneTree
var failures: Array[String] = []
func ok(value: bool, label: String) -> void:
	print("CHECK ",label," ",value)
	if not value: failures.append(label)
func drain(s: Season) -> void:
	var guard := 0
	while s.blocked_by() != "" and guard < 40:
		guard += 1
		match s.blocked_by():
			"bid": s.decline_bid()
			"sendoff": s.answer_send_off()
			"dilemma": s.answer_dilemma(0)
			"cup": s.sim_cup_tie()
			"promotion": s.answer_promotion(false)
			_: break
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(),9001)
	Session.season = s
	var m := ProbeManager.new()
	m.buys_harness = true
	m.lv_report = true
	m.lv_policy = ProbeManager.Lv.LOW
	for y in 8:
		m.winter(s)
		m.season(s)
		s.roll_over()
	m.winter(s)
	drain(s)
	var owned := 0
	for f in s.club.starting_five(): owned += int(f.harness > 0)
	ok(m.harness_cc > 0 and owned > 0,"fixture really bought and fields paid kit")
	print("PURCHASE_GUARD cc_spent=",m.harness_cc," paid_line=",owned)
	var played := 0
	var earned := 0
	for i in 3:
		drain(s)
		s.ensure_a_line()
		var before := int(s.office.books_in.get("Harness sponsorship",0))
		var sim := s.begin_bout()
		if sim == null: break
		sim.run_to_end()
		s.post_bout(sim)
		Session.clear_bout()
		played += 1
		earned += int(s.office.books_in.get("Harness sponsorship",0))-before
	ok(played == 3 and earned > 0,"fought bouts actually book positive sponsorship")
	var back := SaveGame.from_dict(SaveGame.to_dict(s))
	ok(back != null and is_equal_approx(back.office.harness_receipts,s.office.harness_receipts),"whole career save retains earned fraction")
	ok(back != null and back.office.credits == s.office.credits and back.office.books_in == s.office.books_in,"whole career save retains cash and income categories")
	var before_receipts := s.office.harness_receipts
	var before_book := int(s.office.books_in.get("Harness sponsorship",0))
	SeasonBouts._apply_regime(s,false,false)
	ok(is_equal_approx(s.office.harness_receipts,before_receipts) and int(s.office.books_in.get("Harness sponsorship",0)) == before_book,"nonfight regime processing pays no sponsorship")
	print("FOUGHT_SPONSORSHIP bouts=",played," booked_cc=",earned," failures=",JSON.stringify(failures))
	m._s = null
	Session.season = null
	quit(0 if failures.is_empty() else 1)
