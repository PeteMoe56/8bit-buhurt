extends SceneTree
## THE CORNER AFTER A ROUND, which is the case the screen exists for.
##
##   xvfb-run -a godot --path . --script res://tools/shot_corner.gd
##
## `shot_melee_panels.gd` opens the corner before the charge, where there is no
## score, no takedowns, no assists, nobody downed and nothing to recover — so it
## photographs five of the seven things on the row as blank. A screenshot of the
## empty case is the mistake this project has now made twice.
var n := 0
var stage := 0
var s: Node


func _initialize() -> void:
	Settings.tips_enabled = false
	## A FIXED GLOBAL SEED, FIRST. `melee_scene._ready()` opens a standalone
	## exhibition with `_new_bout(randi())`, and Godot seeds the global stream
	## randomly at startup — so this tool drew a different bout, a different
	## opposing formation and a different set of men EVERY RUN. Three of its four
	## pictures changed between two runs with no code touched at all.
	##
	## That is not a cosmetic problem. It means the tool cannot answer the only
	## question a shot tool is for — "did my change alter this screen?" — because
	## the answer was always yes. *A check that passes because of what the world
	## happened to do is a check waiting for the world to do something else*, and
	## a picture that changes on its own is the same fault in the other direction.
	seed(20260914)
	## A SEASON, because the book reads its shapes and its favorites off
	## `Session.season.board` and falls back to the built-in formations without
	## one. The first version of this tool had none, so the star mode
	## photographed "0 of 4" on a board that did not exist.
	Session.season = Season.new(MeleeRosters.starting_club(), 20260914)
	s = load("res://scenes/Melee.tscn").instantiate()
	root.add_child(s)


func _process(_d: float) -> bool:
	n += 1
	if n < 4:
		return false
	match stage:
		0:
			## ONE ROUND, STOPPING AT THE CORNER. `run_to_end` leaves the sim in
			## OVER, and `_process` flips the screen away from a corner the sim is
			## no longer in — so the first version of this tool photographed the
			## corner's controls floating over a live fight with no panel behind
			## them. `skip_round` is the round the marshal would have run.
			var sim = s.get("sim")
			sim.skip_round()
			s.set("screen", 2)                      ## Screen.CORNER
			s.set("corner_done_for_round", -1)
			s.call("_show_strategy_panel")
		1:
			root.get_texture().get_image().save_png("res://shots/corner_round.png")
			## AND THE SUB POPUP, which is the other half of the screen and is the
			## only part of it a player cannot see without tapping.
			s.set("sub_open", 1)
			s.call("_build_corner")
		2:
			root.get_texture().get_image().save_png("res://shots/corner_sub.png")
			## AND THE BOOK IN STAR MODE, with two already starred — the empty
			## case would photograph a feature that has never been used.
			s.set("sub_open", -1)
			var board = Session.season.board if Session.season != null else null
			if board != null:
				var sim = s.get("sim")
				board.toggle_favorite(int(sim.formations[0]), "push", "0")
				board.toggle_favorite(int(sim.formations[0]), "push", "2")
			s.set("starring", true)
			s.call("_show_playbook")
		3:
			root.get_texture().get_image().save_png("res://shots/book_stars.png")
			## AND BACK TO THE CORNER, to prove the stars reach it. Two starred
			## out of four means the right-hand column shows two — the fallback
			## is all-or-nothing, so a half-full column is the only picture that
			## can only have come from real favorites.
			s.set("starring", false)
			s.call("_clear_panel")
			s.call("_build_corner")
		4:
			root.get_texture().get_image().save_png("res://shots/corner_faves.png")
			print("done")
			quit(0)
			return true
	stage += 1
	n = 0
	return false
