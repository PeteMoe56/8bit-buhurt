class_name JuiceArt
extends Node2D
## THE ONE NODE THE FEEL LAYER NEEDS — it ticks the clock and draws the two
## things that must sit over everything: the palette flash and the wipe.
##
## It lives inside a `CanvasLayer` parented to the window (see `Juice.arm()`),
## which has two consequences that are both wanted:
##
##   * it survives a scene change, so a wipe can cover one, and
##   * it is NOT moved by the viewport's canvas transform, so the world can
##     shake underneath it while the cover stays exactly where it was put. A
##     full-screen flash that shakes is a full-screen flash with a gap down one
##     side.
##
## THE SHAKE IS APPLIED HERE, to the viewport, rather than by each screen. A
## screen that had to remember to offset itself is a screen that will forget,
## and the one that forgets is the one that looks broken. The scene's own
## `CanvasLayer` of buttons does not move with it — which is right: in a melee
## the arena shakes and the HUD stays nailed down, the way it does in every
## fighting game that has ever done this well.

var _shaking := false


func _ready() -> void:
	## Above its siblings inside the layer, and drawn every frame — there is
	## always something moving, even if it is only the idle counter.
	z_index = 100
	set_process(true)


func _process(delta: float) -> void:
	Juice.tick(delta)

	var vp := get_viewport()
	if vp != null:
		var off := Juice.shake_offset()
		if off != Vector2.ZERO:
			vp.canvas_transform = Transform2D(0.0, off)
			_shaking = true
		elif _shaking:
			## RESTORE EXACTLY ONCE. Writing identity every frame would fight
			## anything else that ever wants the canvas transform, and this
			## codebase has learned twice what it costs when two things own one
			## value.
			vp.canvas_transform = Transform2D.IDENTITY
			_shaking = false

	var path := Juice.take_pending_scene()
	if path != "" and get_tree() != null:
		get_tree().change_scene_to_file(path)

	queue_redraw()


func _draw() -> void:
	var screen := UiKit.screen()

	## THE NUMBERS THAT LAND. Drawn here rather than by each screen for the
	## reason everything else in this file is here: a screen that had to
	## remember to draw them is a screen that will forget, and the popup that
	## does not appear is indistinguishable from the event that did not happen.
	##
	## They sit UNDER the wipe and under the flash. A number still rising while
	## the screen is being covered has been overtaken by events.
	var pops := Juice.popups()
	if not pops.is_empty():
		var f := UiKit.number()
		var px := UiKit.snap(16)
		for pp in pops:
			var at: Vector2 = pp["at"]
			var txt := String(pp["text"])
			## A one-pixel black drop, so a number reads over the surface art as
			## well as it reads over a panel. Cheaper than an outline and it is
			## what an 8-bit machine would have done.
			draw_string(f, at + Vector2(1, 1), txt,
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, px, UiKit.TRACK)
			draw_string(f, at, txt, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px, pp["col"])

	## THE WIPE. Eight columns of blocks on the 8px grid, arriving as whole
	## columns. Not a sliding edge — a sliding edge is a fade lying down.
	var cover := Juice.wipe_cover()
	if cover > 0.0:
		var cols := int(ceil(screen.x / Juice.WIPE_BLOCK))
		var lit := int(round(cover * float(cols)))
		var from_right := Juice.wipe_from_right()
		for c in lit:
			var i := (cols - 1 - c) if from_right else c
			var x := float(i) * Juice.WIPE_BLOCK
			draw_rect(Rect2(Vector2(x, 0.0), Vector2(Juice.WIPE_BLOCK, screen.y)),
				UiKit.TRACK)

	## THE PALETTE FLASH. Two frames, over the top of everything including the
	## wipe, because the events that earn a flash outrank a screen change.
	if Juice.flashing():
		draw_rect(Rect2(Vector2.ZERO, screen), Juice._flash_col)
