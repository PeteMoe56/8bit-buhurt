extends SceneTree
## THE FOUR FAVORITES, IN THE ORDER THE CORNER WILL READ THEM.
##
##   xvfb-run -a godot --path . --script res://tools/shot_favs.gd
##
## Two frames of one control, which is the only honest way to photograph a
## reorder: the strip before a tap and the strip after it. A single frame of a
## list proves the list drew and nothing about whether it moves.
##
## It also walks the corner afterwards, because the strip's whole claim is that
## it changes where a card sits on THAT screen — a shot of the strip alone would
## be a shot of the control agreeing with itself.
var n := 0
var stage := 0
var scene: Node = null

func _initialize() -> void:
	Session.season = Season.new(MeleeRosters.starting_club(), 909)
	scene = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(scene)


## STARRED THROUGH THE SCENE'S OWN BOOK, not by pushing dictionaries into
## `favorites`. The book is what turns a shape into a list of calls, and a
## fixture built from anything else is a fixture that can disagree with the
## screen it is photographing about what a favorite even is.
func _star_four() -> void:
	var board: Chalkboard = Session.season.board
	var put := 0
	for sh in scene.call("_book_shapes"):
		for c in scene.call("_book_calls", int(sh["id"])):
			if put >= Chalkboard.MAX_FAVORITES:
				return
			board.toggle_favorite(int(sh["id"]), String(c["kind"]),
				Chalkboard.fav_key(String(c["kind"]), int(c["id"]),
					String(c["name"])))
			put += 1


func _process(_d: float) -> bool:
	n += 1
	if n < 12:
		return false
	n = 0
	match stage:
		0:
			_star_four()
			print("starred %d" % Session.season.board.live_favorites().size())
			scene.set("starring", true)
			## THROUGH THE WALK-OUT, as a player gets here (Screen Score #1, S38:
			## this tool opened the book over the splash, which no player can do).
			scene.call("_show_strategy_panel")
			scene.call("_show_playbook")
		1:
			root.get_texture().get_image().save_png("res://shots/favs_before.png")
			print("wrote favs_before  order=%s" % str(_order()))
			## SLOT 3 TO SLOT 2 — a move in the middle of the list, not at an
			## end, because the ends are the cases the verb refuses and a shot
			## of a refusal is a shot of nothing happening.
			Session.season.board.promote_favorite(2)
			scene.call("_show_playbook")
		2:
			root.get_texture().get_image().save_png("res://shots/favs_after.png")
			print("wrote favs_after   order=%s" % str(_order()))
			scene.set("starring", false)
			scene.call("_clear_panel")
			scene.call("_build_corner")
		3:
			root.get_texture().get_image().save_png("res://shots/favs_corner.png")
			print("wrote favs_corner")
			return true
	stage += 1
	return false

func _order() -> Array:
	var out: Array = []
	for f in Session.season.board.live_favorites():
		out.append(scene.call("_fav_name", f))
	return out
