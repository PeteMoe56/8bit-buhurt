extends SceneTree
## THE FIRST-TIME SPLASH over the season screen (11 Oct 2026): the send-off one.
##   RB_TIPS=1 bash tools/bb.sh shot splash   -> shots/splash_sendoff.png
var n := 0


func _initialize() -> void:
	Settings.tips_enabled = true
	Settings.tips_seen.clear()
	var s := Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.decline_bid()
	var me := s.world.player_club
	s.world.clubs[me]["tier"] = League.Tier.NATIONAL
	s.office.tier = League.Tier.NATIONAL
	s.world.finalists[League.Tier.NATIONAL] = [me, 1]
	s.world.calendar = [Calendar.week(Calendar.Kind.BYE, {"before": "worlds"}), Calendar.week(Calendar.Kind.WORLDS)]
	s.world.week = 0
	root.add_child(load("res://scenes/Season.tscn").instantiate())


func _process(_d: float) -> bool:
	n += 1
	if n < 12:
		return false
	root.get_texture().get_image().save_png("res://shots/splash_sendoff.png")
	print("wrote splash_sendoff")
	Settings.tips_seen.clear()
	return true
