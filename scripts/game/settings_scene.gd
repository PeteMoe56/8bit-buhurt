extends Node2D
## Settings and credits, and the credits half is not optional.
##
## `menu.ogg` is licensed rather than ours, and that licence makes attribution a
## CONDITION: failure to attribute is "a material breach". So the credits are
## generated from `Audio.LICENSED` — the same dictionary the fallback chain
## walks — rather than typed out here where they could quietly go stale.

const PAD := 24.0
const COL_W := 430.0
const LEFT_X := 24.0
const RIGHT_X := 500.0
const TOP := 96.0

var font: Font
var ui: CanvasLayer

const ROWS := [
	{"key": "music", "label": "Music"},
	{"key": "sfx", "label": "Effects"},
	{"key": "ui", "label": "Interface"},
]


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	ui = CanvasLayer.new()
	add_child(ui)
	_build()


func _build() -> void:
	for c in ui.get_children():
		c.queue_free()
	for i in ROWS.size():
		var key := String(ROWS[i]["key"])
		var y := TOP + 64.0 + float(i) * 64.0
		ui.add_child(UiKit.button("-", Vector2(LEFT_X + 214, y),
			Vector2(44, 38), _nudge.bind(key, -1)))
		ui.add_child(UiKit.button("+", Vector2(LEFT_X + COL_W - 68, y),
			Vector2(44, 38), _nudge.bind(key, 1)))
	ui.add_child(UiKit.button("Back", Vector2(LEFT_X, 470), Vector2(160, 46), _back))
	queue_redraw()


func _nudge(key: String, dir: int) -> void:
	Settings.nudge(key, dir)
	## The tick you just heard is the volume you just set, which is the only
	## honest way to audition a UI slider.
	Audio.play("tap")
	queue_redraw()


func _back() -> void:
	UiKit.back("res://scenes/Title.tscn")


func _draw() -> void:
	UiKit.set_mood(UiKit.Mood.NORMAL)
	Audio.music("menu")
	UiKit.ground(self)
	UiKit.text(self, font, "SETTINGS", Vector2(LEFT_X, 54), 30, UiKit.INK)

	# ---------------------------------------------------------------- volume
	UiKit.panel(self, Rect2(LEFT_X, TOP, COL_W, 262))
	UiKit.text(self, font, "SOUND", Vector2(LEFT_X + 18, TOP + 30), 15, UiKit.DIM)
	for i in ROWS.size():
		var key := String(ROWS[i]["key"])
		var y := TOP + 64.0 + float(i) * 64.0
		UiKit.text(self, font, String(ROWS[i]["label"]),
			Vector2(LEFT_X + 18, y + 26), 17, UiKit.INK)
		var lvl := Settings.get_level(key)
		## Eight notches, because eight is countable at a glance and a continuous
		## bar is not — you can see what you set, not just that you set it.
		UiKit.meter(self, Rect2(LEFT_X + 266, y + 10, 90, 18),
			int(round(lvl / Settings.STEP)), 8,
			UiKit.YOU if lvl > 0.0 else UiKit.EDGE)

	UiKit.text(self, font, "Saved as you set them.",
		Vector2(LEFT_X + 2, TOP + 288), 13, UiKit.EDGE.lightened(0.5))

	# --------------------------------------------------------------- credits
	UiKit.panel(self, Rect2(RIGHT_X, TOP, COL_W + 6, 344))
	UiKit.text(self, font, "CREDITS", Vector2(RIGHT_X + 18, TOP + 30), 15, UiKit.DIM)
	var y := TOP + 62.0
	UiKit.text(self, font, "MUSIC", Vector2(RIGHT_X + 18, y), 13, UiKit.YOU)
	y += 26.0
	for c in Settings.credit_lines():
		UiKit.text(self, font, UiKit.clip(String(c["line"]), 42),
			Vector2(RIGHT_X + 18, y), 16, UiKit.INK)
		y += 21.0
		UiKit.text(self, font, "from %s  ·  %s" % [String(c["from"]), String(c["url"])],
			Vector2(RIGHT_X + 18, y), 13, UiKit.DIM)
		y += 19.0
		UiKit.text(self, font, "Used under the %s" % String(c["licence"]),
			Vector2(RIGHT_X + 18, y), 12, UiKit.EDGE.lightened(0.5))
		y += 24.0
	## SHORTER, BECAUSE IT DID NOT FIT. Seventeen pixels over the panel's right
	## edge — invisible to every check until `test_ink.gd` learned to pair a
	## string with the box it was drawn on, and invisible by eye because the
	## overhang is one short word on a dim line. Wrapping it was the first fix
	## and it was worse: the second line pushed everything below it 18 pixels
	## down and ran "Built by BonkWorks." out of the bottom of the same panel,
	## which the same check then caught. One line, made to fit.
	UiKit.text(self, font, "All other audio written for this game.",
		Vector2(RIGHT_X + 18, y), 14, UiKit.DIM)
	y += 28.0
	UiKit.text(self, font, "TYPE", Vector2(RIGHT_X + 18, y), 13, UiKit.YOU)
	y += 24.0
	var fc := Settings.face_credit()
	## TWO LINES, because the credit is generated and its length is not ours to
	## choose: the face's name and the face it is after are both somebody else's
	## words. On one line at 13px in the real face it ran to x 973 of a 960 frame.
	## A credit that is cut off is a licence condition that is not met.
	UiKit.text(self, font, String(fc["name"]), Vector2(RIGHT_X + 18, y), 13, UiKit.INK)
	y += 17.0
	UiKit.text(self, font, "after %s" % String(fc["from"]),
		Vector2(RIGHT_X + 18, y), 12, UiKit.INK)
	y += 19.0
	UiKit.text(self, font, "%s  ·  %s" % [String(fc["licence"]), String(fc["url"])],
		Vector2(RIGHT_X + 18, y), 12, UiKit.EDGE.lightened(0.5))
	y += 19.0
	UiKit.text(self, font, String(fc["ours"]),
		Vector2(RIGHT_X + 18, y), 12, UiKit.EDGE.lightened(0.5))
	y += 28.0
	UiKit.text(self, font, "GAME", Vector2(RIGHT_X + 18, y), 13, UiKit.YOU)
	y += 26.0
	UiKit.text(self, font, Brand.short_name(), Vector2(RIGHT_X + 18, y), 16, UiKit.INK)
	y += 21.0
	UiKit.text(self, font, "Built by BonkWorks.", Vector2(RIGHT_X + 18, y), 13, UiKit.DIM)
