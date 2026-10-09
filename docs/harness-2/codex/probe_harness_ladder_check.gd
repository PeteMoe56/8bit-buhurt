extends SceneTree
## Explicitly includes Titanium, absent from the legacy ladder loop.
func _initialize() -> void:
	var prior_wear := 100.0
	var prior_base := 0.0
	var steps: Array[float] = []
	for g in 5:
		var s := Season.new(MeleeRosters.starting_club(), 9001)
		for man in s.club.roster:
			man.harness = g
			man.armor = Quartermaster.ceiling(man)
		var f: FighterCard = s.club.starting_five()[0]
		var before := f.armor
		var ability := f.ability()
		var headroom := f.headroom()
		var eb := f.effective_base()
		var wear := Quartermaster.wear_scale(f)
		assert(wear < prior_wear)
		assert(eb >= prior_base)
		if g > 0:
			steps.append(prior_wear-wear)
		SeasonBouts.bout_wear(s)
		var expected := SeasonBouts.BOUT_WEAR * FighterTrait.mod(f.trait_id, "wear", 1.0) * wear
		assert(absf((before-f.armor)-expected) < 0.000001)
		assert(f.ability() == ability and f.headroom() == headroom)
		print("GRADE_FIXTURE ", JSON.stringify({"grade": g, "wear": wear, "actual_loss": before-f.armor, "expected_loss": expected, "effective_base_at_top": eb, "ability": ability, "headroom": headroom}))
		prior_wear = wear
		prior_base = eb
	assert(absf(steps[0]-steps[1]) > 0.000001 or absf(steps[1]-steps[2]) > 0.000001 or absf(steps[2]-steps[3]) > 0.000001)
	print("ALL_FIVE_GRADE_FIXTURE=PASS")
	quit(0)
