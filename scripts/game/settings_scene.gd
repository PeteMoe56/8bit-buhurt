extends Node2D
class_name SettingsScene
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
## A credit line's room: the panel (COL_W + 6) less its 18 px inset each side.
const CREDIT_W := COL_W + 6.0 - 36.0
const TOP := 96.0
## HOW FAR APART THE THREE VOLUME ROWS SIT. It was 64 and the panel was 262 tall,
## which left the THIS CAREER panel starting at 378 — fine while that panel was a
## two-line signpost and not fine the moment it grew a control, because 378 plus
## a control is 498 and the Back button lives at 470.
##
## Named rather than nudged, and the panel's height is derived from it, so the
## next row added to SOUND cannot silently push the panel under a button again.
const ROW_STEP := 52.0
const SOUND_H := 218.0
## The career panel, and the Back button riding the bottom of whatever shape the
## screen turned out to be rather than a literal 470.
## IN THE RIGHT COLUMN, under About (round 8: the right column was empty and
## the left one pressed Back against the career box).
const CAREER_X := RIGHT_X
const CAREER_Y := TOP + 244.0
const CAREER_H := 150.0
## LANGUAGE, under the credits: one cycling button, like the grade's.
const LANG_Y := TOP
const LANG_H := 80.0
const ABOUT_Y := TOP + 98.0
const ABOUT_H := 128.0
## THE GUIDE, under SOUND, its top in line with THIS CAREER (Pete, 1 Oct 2026:
## "Make a Guide in the Settings/Menu area").
const GUIDE_Y := CAREER_Y
const GUIDE_H := 130.0

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
		var y := TOP + 56.0 + float(i) * ROW_STEP
		ui.add_child(UiKit.button("-", Vector2(LEFT_X + 214, y),
			Vector2(44, 38), _nudge.bind(key, -1)))
		ui.add_child(UiKit.button("+", Vector2(LEFT_X + COL_W - 68, y),
			Vector2(44, 38), _nudge.bind(key, 1)))
	## ------------------------------------------------------------ difficulty
	## Pete, 15 Sep 2026: *"Difficulty should be changeable."*
	##
	## It was set once, on the club-creation screen, and this panel was a SIGNPOST
	## saying so — which was an answer to item 14 of the 15 Sep playtest (*"Can't
	## find difficulty settings"*) that told the player where it wasn't.
	##
	## The old argument was that a grade you can change between fixtures makes the
	## table meaningless. That assumes the player is cheating the table. The actual
	## player is four events into a losing season, has just been told by his own
	## game that the way out is *"bringing the difficulty down"*, and cannot find
	## the control — and **a difficulty setting you can only choose before you know
	## what it means is not a difficulty setting, it is a quiz question.**
	##
	## The record stays honest because `Season.grade_history` writes down every
	## change with the event it happened on, so a promotion won on FRIENDLY says so.
	##
	## ONE CYCLING BUTTON, like the reserve sort. Five grades is too many for a
	## row of buttons in a 430-pixel panel and a dropdown is a control this game
	## does not otherwise have; the button shows what it will change TO, which is
	## the one thing a cycling control has to do to not be a guess.
	## ONE HOME FOR THE DIFFICULTY (blind review, 29 Sep: a cycling button that
	## showed the NEXT grade read as the current one). Settings says which grade
	## is on and sends the player to the grade page, where all six are laid out
	## with what each one does.
	if Session.season != null:
		var half := (COL_W - 36.0 - 8.0) * 0.5
		ui.add_child(UiKit.button(UiKit.t("Difficulty"),
			Vector2(CAREER_X + 18, CAREER_Y + 104.0), Vector2(half, 38), func():
				Session.autosave()
				Session.create_tab = 2
				UiKit.go("res://scenes/Create.tscn"), "ladder"))
		## WHERE A PLAYER LOOKS FOR HIS CLUB'S NAME (playtest 30 Sep #2: "it
		## feels like it should be Settings").
		ui.add_child(UiKit.button(UiKit.t("Name & badge"),
			Vector2(CAREER_X + 18 + half + 8.0, CAREER_Y + 104.0), Vector2(half, 38), func():
				Session.autosave()
				Session.create_tab = 1
				UiKit.go("res://scenes/Create.tscn"), "shield"))

	## THE LANGUAGE BUTTON SHOWS WHAT IT CHANGES TO, like the grade's; the panel
	## says what is in use now. A draft is offered only in a debug build.
	var langs := Settings.offered()
	if langs.size() > 1:
		var li := langs.find(Settings.language)
		## A PICKER: < the one in use >, both ways (blind review round 3: "Switch
		## to English" beside "Automatic · English" contradicted itself).
		var prv: String = langs[(maxi(0, li) - 1 + langs.size()) % langs.size()]
		var nxt: String = langs[(maxi(0, li) + 1) % langs.size()]
		ui.add_child(UiKit.arrow(false, Vector2(RIGHT_X + 18, LANG_Y + 32.0), Vector2(52, 38), func():
			Settings.set_language(prv)
			Audio.play("tap")
			_build()))
		ui.add_child(UiKit.arrow(true, Vector2(RIGHT_X + COL_W - 70.0, LANG_Y + 32.0), Vector2(52, 38), func():
			Settings.set_language(nxt)
			Audio.play("tap")
			_build()))
	ui.add_child(UiKit.button(UiKit.t("Back"), Vector2(LEFT_X, UiKit.bottom(58.0)),
		Vector2(160, 46), _back))
	## THE CREDITS LIVE BEHIND THEIR OWN BUTTON (blind review, 29 Sep: they took
	## half the screen and outranked the settings). Every line is still there, in
	## full, above the licence texts.
	ui.add_child(UiKit.button(UiKit.t("Credits & licenses"), Vector2(RIGHT_X + 18, ABOUT_Y + 80.0),
		Vector2(COL_W - 36.0, 40), _show_licences, "scroll"))
	ui.add_child(UiKit.button(UiKit.t("Open the Guide"), Vector2(LEFT_X + 18, GUIDE_Y + 80.0),
		Vector2(COL_W - 36.0, 40), func(): UiKit.go("res://scenes/Guide.tscn"), "book"))
	queue_redraw()


## THE LICENCES, IN FULL, WHERE A PLAYER CAN READ THEM (29 Sep 2026). Godot's
## MIT licence and the fonts' SIL OFL both require their text to travel with the
## game, and on a phone a file inside the pack is not somewhere a player can
## look. Godot's own text comes from the engine (so it is always the version
## that is running); the rest is read from the files the export ships
## (`include_filter` in export_presets.cfg).
const LICENCE_FILES := [
	["Buhurt Plate (from Press Start 2P) — SIL Open Font License 1.1", "res://fonts/OFL.txt"],
	["LanaPixel by eishiya — SIL Open Font License 1.1", "res://fonts/fallback/LanaPixel-OFL.txt"],
	["Fantasy UI Borders by Kenney — CC0", "res://art/ui/KENNEY-LICENSE.txt"],
]

var _licences: Control = null


static func credits_text() -> String:
	var out: Array[String] = ["CREDITS", "", "MUSIC"]
	for c in Settings.credit_lines():
		out.append(String(c["line"]))
		out.append(UiKit.t("from %s  ·  %s") % [String(c["from"]), String(c["url"])])
		out.append(UiKit.t("Used under the %s") % String(c["licence"]))
		out.append("")
	out.append(UiKit.t("All other audio written for this game."))
	out.append("")
	out.append("TYPE")
	var fc := Settings.face_credit()
	out.append(String(fc["name"]))
	out.append(UiKit.t("after %s") % String(fc["from"]))
	out.append(UiKit.t("%s  ·  %s") % [String(fc["licence"]), String(fc["url"])])
	out.append(UiKit.t("Buhurt Rail, Gorget and Maul drawn for this game."))
	out.append(UiKit.t("Other alphabets: LanaPixel by eishiya, SIL OFL 1.1"))
	out.append("")
	out.append("GAME")
	out.append(Brand.short_name())
	out.append(UiKit.t("Built by BonkWorks."))
	return "\n".join(out)


static func licence_text() -> String:
	var parts: Array[String] = [credits_text()]
	parts.append("Godot Engine — MIT License\n\n" + Engine.get_license_text())
	for pair in LICENCE_FILES:
		var body := FileAccess.get_file_as_string(String(pair[1]))
		parts.append("%s\n\n%s" % [String(pair[0]), body.strip_edges()])
	## AND WHAT GODOT ITSELF IS BUILT FROM (FreeType, and the rest), as the
	## engine reports it — Godot's own "complying with licenses" guidance asks
	## for these alongside its MIT text.
	var third: Array[String] = []
	for comp in Engine.get_copyright_info():
		for part in comp.get("parts", []):
			var holders := ", ".join(part.get("copyright", []))
			third.append("%s — %s — %s" % [String(comp.get("name", "")), holders, String(part.get("license", ""))])
	parts.append("Third-party components of Godot Engine\n\n" + "\n".join(third))
	var info: Dictionary = Engine.get_license_info()
	for name in info.keys():
		parts.append("%s\n\n%s" % [String(name), String(info[name]).strip_edges()])
	return "\n\n————————\n\n".join(parts)


func _show_licences() -> void:
	if _licences != null:
		return
	var screen := UiKit.screen()
	var box := Panel.new()
	box.position = Vector2(24, 24)
	box.size = screen - Vector2(48, 48)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiKit.PANEL
	sb.border_color = UiKit.EDGE
	sb.set_border_width_all(3)
	box.add_theme_stylebox_override("panel", sb)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(16, 16)
	scroll.size = box.size - Vector2(32, 88)
	var label := Label.new()
	label.text = licence_text()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(scroll.size.x - 16.0, 0)
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", UiKit.INK)
	scroll.add_child(label)
	box.add_child(scroll)
	box.add_child(UiKit.button(UiKit.t("Close"), Vector2(16, box.size.y - 62.0),
		Vector2(160, 46), func():
			_licences.queue_free()
			_licences = null))
	_licences = box
	ui.add_child(box)


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
	UiKit.ground(self)
	UiKit.text(self, font, UiKit.t("SETTINGS"), Vector2(LEFT_X, 54), 30, UiKit.INK)

	# ---------------------------------------------------------------- volume
	UiKit.panel(self, Rect2(LEFT_X, TOP, COL_W, SOUND_H))
	UiKit.text(self, font, UiKit.t("SOUND"), Vector2(LEFT_X + 18, TOP + 30), 15, UiKit.DIM)
	for i in ROWS.size():
		var key := String(ROWS[i]["key"])
		var y := TOP + 56.0 + float(i) * ROW_STEP
		UiKit.text(self, font, UiKit.t(String(ROWS[i]["label"])),
			Vector2(LEFT_X + 18, y + 26), 17, UiKit.INK)
		var lvl := Settings.get_level(key)
		## Eight notches, because eight is countable at a glance and a continuous
		## bar is not — you can see what you set, not just that you set it.
		UiKit.meter(self, Rect2(LEFT_X + 266, y + 10, 90, 18),
			int(round(lvl / Settings.STEP)), 8,
			UiKit.YOU if lvl > 0.0 else UiKit.EDGE)

	## ------------------------------------------------------ where difficulty is
	## Pete, item 14 of the 15 Sep playtest: *"Can't find difficulty settings."*
	##
	## He could not because they are not here, and that is deliberate — the note
	## on `Season.grade` says it plainly: *"volume is a property of the room you
	## are sitting in, and difficulty is a property of the run."* A grade you
	## could change at the title screen between fixtures would make the table
	## meaningless.
	##
	## So this is not a move, it is a signpost, and the grade is the one thing on
	## this screen the player cannot change here. **A setting that is deliberately
	## somewhere else still has to be findable from where people look for it** —
	## an absence with no explanation is indistinguishable from an omission, and
	## that is exactly what it was mistaken for.
	## IN ITS PANEL'S HEADER, not floating between panels (round 4).
	UiKit.right(self, font, UiKit.t("Saved as you set them."),
		Vector2(LEFT_X + COL_W - 18.0, TOP + 30), 12, UiKit.EDGE.lightened(0.5), COL_W - 120.0)

	## ITS OWN PANEL, because it is its own kind of thing. The first cut put it
	## inside the SOUND box's last six pixels and it landed on "Saved as you set
	## them" — which is what a row added to a panel sized for the rows it already
	## had always does.
	## TALLER, because it holds a control now rather than a sentence explaining
	## that the control is elsewhere. 82 was the height of the signpost.
	var gy := CAREER_Y
	UiKit.panel(self, Rect2(CAREER_X, gy, COL_W, CAREER_H))
	UiKit.text(self, font, UiKit.t("THIS CAREER"), Vector2(CAREER_X + 18, gy + 24), 15, UiKit.DIM)
	if Session.season != null:
		UiKit.pair(self, font, UiKit.t("Difficulty"), Grade.name_of(Session.season.grade),
			Vector2(CAREER_X + 18, gy + 48.0), CAREER_X + COL_W - 18.0, 17, 15,
			UiKit.INK, UiKit.YOU)
		## WHAT THE ONE HE IS ON ACTUALLY DOES, not what the next one does. The
		## button below says where a tap goes; this line says where he is, and a
		## panel where both the label and the blurb describe somewhere else is a
		## panel that reads as already changed.
		## WRAPPED, NOT CUT. `fit_px` records every cut it makes and `test_ink.gd`
		## fails the suite on any of them, for the good reason that a clipped
		## sentence the game wrote itself reads to a player as a broken game — and
		## these blurbs were written for the club-creation screen's wider box, so
		## the first draw here lost four words off "A properly sanctioned fight.
		## Their numbers me." Two lines at 12px is the box being honest about how
		## much room it has.
		UiKit.para(self, font, Grade.blurb_of(Session.season.grade),
			Vector2(CAREER_X + 18, gy + 70.0), 14, UiKit.DIM, COL_W - 36.0, 18.0)
	else:
		UiKit.text(self, font, UiKit.t("Difficulty"), Vector2(CAREER_X + 18, gy + 48.0),
			17, UiKit.DIM)
		UiKit.text(self, font, UiKit.t("Open it from the Club menu."),
			Vector2(CAREER_X + 18, gy + 68.0), 14, UiKit.DIM)

	# -------------------------------------------------------------- language
	UiKit.panel(self, Rect2(RIGHT_X, LANG_Y, COL_W, LANG_H))
	UiKit.text(self, font, UiKit.t("LANGUAGE"), Vector2(RIGHT_X + 18, LANG_Y + 22.0), 15, UiKit.DIM)
	var shown := Settings.language_name(Settings.language) if Settings.language != "" \
		else UiKit.t("Automatic (%s)") % Settings.language_name(Settings.resolved())
	UiKit.mid(self, font, shown, Vector2(RIGHT_X + 76.0, LANG_Y + 57.0), 16, UiKit.INK, COL_W - 152.0)

	# ----------------------------------------------------------------- about
	UiKit.panel(self, Rect2(RIGHT_X, ABOUT_Y, COL_W, ABOUT_H))
	UiKit.text(self, font, UiKit.t("ABOUT"), Vector2(RIGHT_X + 18, ABOUT_Y + 26), 15, UiKit.DIM)
	UiKit.text(self, font, Brand.short_name(), Vector2(RIGHT_X + 18, ABOUT_Y + 50), 16, UiKit.INK)
	UiKit.text_fit(self, font, UiKit.t("Built by BonkWorks."),
		Vector2(RIGHT_X + 18, ABOUT_Y + 70), 14, UiKit.DIM, COL_W - 36.0)

	# ----------------------------------------------------------------- guide
	UiKit.panel(self, Rect2(LEFT_X, GUIDE_Y, COL_W, GUIDE_H))
	UiKit.text(self, font, UiKit.t("GUIDE"), Vector2(LEFT_X + 18, GUIDE_Y + 24), 15, UiKit.DIM)
	UiKit.para(self, font, UiKit.t("What every number and word means."),
		Vector2(LEFT_X + 18, GUIDE_Y + 50), 14, UiKit.INK, COL_W - 36.0, 18.0)
