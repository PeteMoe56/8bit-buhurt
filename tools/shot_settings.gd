extends SceneTree
## THE SETTINGS SCREEN, WITH A CAREER LOADED.
##
##   xvfb-run -a godot --path . --script res://tools/shot_settings.gd
##
## THE CAREER IS THE POINT NOW. The THIS CAREER panel holds the difficulty
## control (Pete, 16 Sep: *"Difficulty should be changeable"*) and with
## `Session.season` null it draws the other branch — so the old version of this
## tool photographed the one state where the new control does not exist, and
## would have reported the screen as fine forever. **A fixture that cannot reach
## the thing under test is a fixture that always passes.**
func _initialize() -> void:
	Session.season = Season.new(MeleeRosters.starting_club(), 4242)
	var packed: PackedScene = load("res://scenes/Settings.tscn")
	var s: Node = packed.instantiate()
	root.add_child(s)
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png("res://shots/settings.png")
	print("shot written")
	quit(0)
