extends SceneTree
## THE SEND-OFF WEEK, all five days (11 Oct 2026).
##
##   bash tools/bb.sh shot sendoff [WxH]     -> shots/sendoff_<n>.png
##
## A National champion in the bye before the Worlds, walked through Monday to
## Friday by the real answer path, a shot of each day before it is answered.
var n := 0
var day := 0
var s: Season
var scene: Node = null


func _initialize() -> void:
	Settings.tips_enabled = false
	if OS.get_environment("RB_LOCALE") != "":
		Settings.load_once()
		TranslationServer.set_locale(OS.get_environment("RB_LOCALE"))
	s = Season.new(MeleeRosters.starting_club(), 4242)
	Session.season = s
	s.decline_bid()
	var me := s.world.player_club
	s.world.clubs[me]["tier"] = League.Tier.NATIONAL
	s.office.tier = League.Tier.NATIONAL
	s.world.finalists[League.Tier.NATIONAL] = [me, 1]
	s.world.calendar = [Calendar.week(Calendar.Kind.BYE, {"before": "worlds"}), Calendar.week(Calendar.Kind.WORLDS)]
	s.world.week = 0
	s.world.honors.append({"id": "playoff:%d" % League.Tier.NATIONAL, "name": "National Playoff",
		"season": s.world.season, "champion": me, "runner_up": 1, "player": "Champions", "exit": 0, "score": "2-1"})
	s.world._ensure_rivals()
	s.world.rivals[2]["met"] = 2
	s.world.rivals[2]["beat_you"] = 1
	s.world.rivals[2]["lost_to_you"] = 1
	_mount()


func _mount() -> void:
	if scene != null:
		scene.queue_free()
	scene = load("res://scenes/Season.tscn").instantiate()
	root.add_child(scene)
	n = 0


func _process(_d: float) -> bool:
	n += 1
	if n < 12:
		return false
	root.get_texture().get_image().save_png("res://shots/sendoff_%s%d.png" % [OS.get_environment("RB_LOCALE"), day + 1])
	print("wrote sendoff_%d  due=%s" % [day + 1, SendOff.due(s)])
	if day < SendOff.STEPS:
		s.answer_send_off(0)
	day += 1
	if day == SendOff.STEPS:
		## AFTER THE TABARD: the header wears the flag and the name.
		_mount()
		return false
	if day > SendOff.STEPS:
		print("team=%s  grudge=%d  picks=%s" % [s.world.team_title, s.world.grudge_rival, str(s.send_off_picks)])
		return true
	_mount()
	return false
