extends Node2D
## THE FRONT DOOR, and the game did not have one.
##
## It booted straight into three save slots, which is a file picker — the first
## thing anybody saw was an administrative question. Retro Bowl opens on its
## name and its music and asks nothing, and there is a reason beyond taste: the
## title screen is where the menu track gets to play, and the menu track is now
## the one thing in this game somebody else is owed a credit for.
##
## PLAY goes to the slots. Everything else is one tap away and out of the road.

const CENTRE := 480.0

var font: Font
var ui: CanvasLayer
var t: float = 0.0


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	## Coming back here means no season is live. A stale world behind the front
	## door is how a title screen ends up wearing a boss palette.
	Session.season = null
	Session.clear_bout()
	Session.viewing_cup = null
	UiKit.set_mood(UiKit.Mood.NORMAL)
	ui = CanvasLayer.new()
	add_child(ui)
	_build()
	set_process(true)


func _build() -> void:
	var has_any := false
	for i in SaveGame.SLOTS:
		if SaveGame.has_save(i):
			has_any = true
	var y := 300.0
	ui.add_child(UiKit.button("Play" if not has_any else "Play", Vector2(CENTRE - 130, y),
		Vector2(260, 54), _play))
	ui.add_child(UiKit.button("Settings", Vector2(CENTRE - 130, y + 66),
		Vector2(260, 46), _settings))
	## QUIT IS NOT OFFERED ON A PHONE. Mobile platforms have their own way out
	## and a Quit button in a mobile game reads as a bug; on desktop its absence
	## reads as one.
	if not OS.has_feature("mobile"):
		ui.add_child(UiKit.button("Quit", Vector2(CENTRE - 130, y + 124),
			Vector2(260, 40), func(): get_tree().quit()))
	queue_redraw()


func _play() -> void:
	UiKit.back("res://scenes/Title.tscn")


func _settings() -> void:
	UiKit.go("res://scenes/Settings.tscn")


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	Audio.music("menu")
	draw_rect(Rect2(Vector2.ZERO, UiKit.screen()), UiKit.BG)

	## A BAND OF GROUND behind the wordmark, so the name sits on something. The
	## arena art, if it ever arrives, would go here — but this reads as a
	## deliberate plate rather than as an empty slot, because the front door is
	## the one screen that must never look unfinished.
	draw_rect(Rect2(0, 96, UiKit.screen().x, 150), UiKit.PANEL)
	draw_line(Vector2(0, 96), Vector2(UiKit.screen().x, 96), UiKit.FRAME, 2.0)
	draw_line(Vector2(0, 246), Vector2(UiKit.screen().x, 246), UiKit.FRAME, 2.0)

	UiKit.text(self, font, "RETRO", Vector2(CENTRE - 236, 176), 62, UiKit.INK)
	UiKit.text(self, font, "BUHURT", Vector2(CENTRE - 8, 176), 62, UiKit.YOU)
	UiKit.text(self, font, "Run a club.  Take the list.  Climb.",
		Vector2(CENTRE - 134, 218), 16, UiKit.DIM)

	## Two badges either side of the name, drifting. The only motion on the
	## screen, and it is the game's own heraldry rather than a decoration —
	## the mark is what this game looks like.
	var sway := sin(t * 0.7) * 6.0
	UiKit.badge(self, Vector2(150, 171 + sway), 52,
		IconBank.KIT_COLOURS[0], IconBank.MARK_COLOURS[0], 5, 1.0)
	UiKit.badge(self, Vector2(UiKit.right_edge(150.0), 171 - sway), 52,
		IconBank.KIT_COLOURS[3], IconBank.MARK_COLOURS[2], 11, 1.0)

	UiKit.text(self, font, "BonkWorks", Vector2(24, UiKit.screen().y - 24), 13,
		UiKit.EDGE.lightened(0.4))
	## The credit the licence asks for, on the screen the music is playing on.
	## The full list is in Settings; this is the one that is a condition.
	UiKit.right(self, font, "Music: HeatleyBros — heatleybros.com",
		Vector2(UiKit.screen().x - 24, UiKit.screen().y - 24), 13,
		UiKit.EDGE.lightened(0.4), 420)
