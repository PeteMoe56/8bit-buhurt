extends SceneTree
var n := 0
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 20260912)
	s.world.season = 6
	s.office.credits = 31
	s.office.members = 24.0
	## Two rules met and one short, so the screen shows both states and the
	## refusal rather than a club that happens to be fine.
	s.office.compliance[Federation.Rule.KIT] = 2
	s.office.compliance[Federation.Rule.MARSHALS] = 2
	s.office.compliance[Federation.Rule.INSURANCE] = 0
	s.office.tier = League.Tier.REGIONAL
	for f in s.club.roster: f.morale = 0.64
	s.office.sync_morale(s.club)
	Session.season = s
	root.add_child((load("res://scenes/Federation.tscn") as PackedScene).instantiate())
func _process(_d: float) -> bool:
	n += 1
	if n < 8: return false
	root.get_texture().get_image().save_png("res://shots/federation.png")
	print("wrote federation")
	return true
