extends SceneTree
## The real bracket screen, in the three states that matter: a cup part-way
## through with the player still in it, a cup that is over, and a Worlds group
## stage. Rendered rather than reasoned about — the fifth time on this project.
var n := 0
var at := 0
var shots := ["bracket_live", "bracket_done", "bracket_pools"]
var node: Node = null
var season: Season

func _initialize() -> void:
	season = Season.new(MeleeRosters.starting_club(), 20260911)
	Session.season = season
	_make(at)
	_mount()

func _ids(k: int) -> Array:
	var me := int(season.world.player_club)
	var out: Array = [me]
	for c in season.world.clubs:
		var i := int(c["id"])
		if i != me and out.size() < k:
			out.append(i)
	return out

func _make(which: int) -> void:
	var me := int(season.world.player_club)
	if which == 0:
		var cup := Cup.new("Kings Cup", _ids(8), 7, me)
		cup.sim_others(func(_a, _b): return [3, 1, 4, 2])
		Session.viewing_cup = cup
	elif which == 1:
		var cup := Cup.new("Path of Honor", _ids(8), 11, me)
		cup.run_all(func(a, b): 
			var pa := int(season.world.club(a).get("power", 50))
			var pb := int(season.world.club(b).get("power", 50))
			return [3 if pa >= pb else 1, 1 if pa >= pb else 3, 4, 2])
		Session.viewing_cup = cup
	else:
		var cup := Cup.new("Worlds", _ids(16), 3, me, true)
		cup.sim_others(func(_a, _b): return [3, 1, 4, 2])
		Session.viewing_cup = cup

func _mount() -> void:
	var packed: PackedScene = load("res://scenes/Bracket.tscn")
	node = packed.instantiate()
	root.add_child(node)

func _process(_d: float) -> bool:
	n += 1
	if n < 6:
		return false
	root.get_texture().get_image().save_png("res://shots/%s.png" % shots[at])
	print("wrote ", shots[at])
	at += 1
	if at >= shots.size():
		return true
	node.queue_free()
	n = 0
	_make(at)
	_mount()
	return false
