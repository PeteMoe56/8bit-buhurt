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

## THE MIDDLE OF THE CANVAS, NOT THE MIDDLE OF 960.
##
## This was a literal 480 and every element on the front door hung off it, so on
## a 1170-wide handset the whole screen — logo, tagline, all three buttons — sat
## 105 pixels left of center with a bare strip down the right. The season screens
## were re-anchored in the mobile pass and this one was missed, because nothing
## that renders a title screen has ever had an opinion about its width.
static func center() -> float:
	return UiKit.screen().x * 0.5

var font: Font
var ui: CanvasLayer
var t: float = 0.0


func _ready() -> void:
	Juice.arm()
	font = UiKit.body()
	Settings.load_once()
	## THE STORE CONNECTS AT THE FRONT DOOR — this is `run/main_scene` — and not
	## when somebody opens the shop. Play re-delivers purchases it never got an
	## acknowledgement for, the charge that landed while the phone was in a
	## tunnel, and it delivers them on connect. A store that only connects when
	## somebody browses is a store that loses those until somebody browses.
	Store.connect_backend()
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
	ui.add_child(UiKit.button(UiKit.t("Play"), Vector2(center() - 130, y),
		Vector2(260, 54), _play))
	ui.add_child(UiKit.button(UiKit.t("Settings"), Vector2(center() - 130, y + 66),
		Vector2(260, 46), _settings))
	## QUIT IS NOT OFFERED ON A PHONE. Mobile platforms have their own way out
	## and a Quit button in a mobile game reads as a bug; on desktop its absence
	## reads as one.
	if not OS.has_feature("mobile"):
		ui.add_child(UiKit.button(UiKit.t("Quit"), Vector2(center() - 130, y + 124),
			Vector2(260, 40), func(): get_tree().quit()))
	queue_redraw()


func _play() -> void:
	## FORWARD, and the trail starts here. This used `UiKit.back()` — for the
	## sound, which is the only thing that used to differ between the two doors.
	## Now that Back follows a trail, calling it to go FORWARD means the slot
	## screen's own Back pops whatever was underneath instead of returning here.
	UiKit.trail_reset()
	UiKit.go("res://scenes/Title.tscn")


func _settings() -> void:
	UiKit.go("res://scenes/Settings.tscn")


## BACK AT THE FRONT DOOR ASKS BEFORE IT QUITS. Android's back gesture closed
## the app from anywhere; here, at the root, it is allowed to — on the second
## press within three seconds, with a line saying so after the first.
var quit_armed_until: float = -1.0


func go_back() -> bool:
	if t < quit_armed_until:
		get_tree().quit()
		return true
	quit_armed_until = t + 3.0
	queue_redraw()
	return true


## NOTHING HERE MOVES, so nothing is redrawn 60 times a second — except while
## the "press back again" line is up, which has to disappear on time.
func _process(delta: float) -> void:
	t += delta
	if quit_armed_until > 0.0 and t > quit_armed_until:
		quit_armed_until = -1.0
		queue_redraw()


func _draw() -> void:
	UiKit.ground(self, false)

	## THE MARK IS THE SCREEN NOW, and the plate it used to sit on is gone.
	##
	## There was a 150-pixel band of PANEL behind the wordmark, put there because
	## a front door with nothing but type on it looks unfinished and the arena art
	## that would have filled it does not exist. The logo IS that picture. Drawing
	## it on a plate would be framing a framed thing — the lockup carries its own
	## gold border and its own dark ground.
	##
	## Top-anchored at 20 and 216 tall, so it ends at 236; Play starts at 300 and
	## the tagline has the gap between them to itself.
	## THE TAGLINE SITS UNDER THE ART, MEASURED, not at a y somebody typed. The
	## first cut put it at 262 against a logo believed to be 216 tall, and the
	## engine was still serving a 300-tall import — so the sentence printed
	## straight through "BUHURT". A number that has to agree with the height of a
	## file is a number that should be read off the file.
	var logo := Brand.tex(Brand.LOGO)
	var tag_y := 262.0
	if logo != null:
		draw_texture(logo, Vector2(center() - logo.get_width() * 0.5, 16.0).floor())
		tag_y = 16.0 + float(logo.get_height()) + 26.0
	else:
		## No art, no invented layout: the wordmark it always drew.
		UiKit.text(self, font, UiKit.t("8-BIT"), Vector2(center() - 236, 176), 62, UiKit.INK)
		UiKit.text(self, font, UiKit.t("BUHURT"), Vector2(center() - 8, 176), 62, UiKit.YOU)
	UiKit.text(self, font, UiKit.t("Run a club.  Take the list.  Climb."),
		Vector2(center() - 134, tag_y), 16, UiKit.DIM)

	## THE TWO DRIFTING BADGES ARE GONE. They were the game's heraldry on a screen
	## that had no logo, which is exactly what they were for; beside a
	## helmet-and-shield lockup they are two more shields competing with it. The
	## idle motion they carried lives on the slot screen now, where a player
	## actually sits still and looks at something.

	if t < quit_armed_until:
		UiKit.mid(self, font, UiKit.t("Press back again to quit"),
			Vector2(0.0, UiKit.screen().y - 60), 14, UiKit.YOU, UiKit.screen().x)
	UiKit.text(self, font, UiKit.t("BonkWorks"), Vector2(24, UiKit.screen().y - 24), 13,
		UiKit.EDGE.lightened(0.4))
	## The credit the licence asks for, on the screen the music is playing on.
	## The full list is in Settings; this is the one that is a condition.
	UiKit.right(self, font, UiKit.t("Music: HeatleyBros — heatleybros.com"),
		Vector2(UiKit.screen().x - 24, UiKit.screen().y - 24), 13,
		UiKit.EDGE.lightened(0.4), 420)
