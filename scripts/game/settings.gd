class_name Settings
## Volume, and the only state in the game that is not part of a save slot.
##
## No autoload (06.5), so this is a static holder over a ConfigFile. It is read
## once at launch and written whenever something changes — a volume that resets
## every time the game opens is not a setting, it is a tease.

const PATH := "user://settings.cfg"
## Tools that press every button (the monkey) point this elsewhere, so a night of
## random taps does not leave the developer's own volume at zero.
static var path: String = PATH

## Defaults chosen so the first launch is pleasant rather than loud: music sits
## under the effects, and the UI ticks sit under both.
static var music: float = 0.80
static var sfx: float = 0.90
static var interface: float = 0.65
static var _loaded := false
## FIGHT CONTROLS (Pete, 2 Oct 2026: "start with E for both ... a gameplay
## setting with left/right handed as well"). Where every choice in a fight is
## made: "corner", a quarter-wheel under the thumb, or "classic", the guard
## triangle on the man and the three boxes over him. `fight_hand` puts the
## corner under the right thumb or the left.
const CONTROLS := ["corner", "classic"]
const HANDS := ["right", "left"]
static var fight_controls: String = "corner"
static var fight_hand: String = "right"
## DESKTOP ONLY (Steam, 3 Oct 2026): start fullscreen; Alt+Enter / F11 and the
## Settings button flip it. Ignored on phones and tablets.
static var fullscreen: bool = true


static func load_once() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	## THREE DOORS, as the wallet has (3 Oct 2026, audit): the live file, a
	## finished `.tmp` that never got renamed, then the one before it.
	var opened := false
	for p in [path, path + ".tmp", path + ".bak"]:
		if FileAccess.file_exists(p) and cfg.load(p) == OK:
			opened = true
			break
	if opened:
		music = clampf(float(cfg.get_value("audio", "music", music)), 0.0, 1.0)
		sfx = clampf(float(cfg.get_value("audio", "sfx", sfx)), 0.0, 1.0)
		interface = clampf(float(cfg.get_value("audio", "ui", interface)), 0.0, 1.0)
		language = String(cfg.get_value("general", "language", ""))
		var fc := String(cfg.get_value("controls", "fight", fight_controls))
		fight_controls = fc if CONTROLS.has(fc) else "corner"
		var fh := String(cfg.get_value("controls", "hand", fight_hand))
		fight_hand = fh if HANDS.has(fh) else "right"
		var seen = cfg.get_value("general", "tips_seen", [])
		tips_seen.clear()
		if seen is Array:
			for k in seen:
				tips_seen.append(String(k))
		fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	apply()
	## STEAM, on a Steam build, as early as the game has a first screen: started
	## once, and anything earned offline re-sent. Nothing anywhere else.
	Achievements.boot()
	apply_display()
	apply_language()


static func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "ui", interface)
	cfg.set_value("general", "language", language)
	cfg.set_value("general", "tips_seen", tips_seen)
	cfg.set_value("controls", "fight", fight_controls)
	cfg.set_value("controls", "hand", fight_hand)
	cfg.set_value("display", "fullscreen", fullscreen)
	## WRITTEN ASIDE AND MOVED IN (3 Oct 2026, audit). Straight over the file, a
	## kill mid-write tore it and every setting came back at its default.
	var tmp := path + ".tmp"
	if cfg.save(tmp) != OK:
		return
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	DirAccess.rename_absolute(tmp, path)


## A desktop window: fullscreen (borderless, the desktop's own resolution) or a
## window. Phones, tablets and headless runs are left alone.
## NOT FROM THE EDITOR BINARY: the suite and the shot tools run under xvfb with
## it, and a fullscreen window there would change the screen every test measures.
static func is_desktop() -> bool:
	return OS.has_feature("pc") and not OS.has_feature("editor") and DisplayServer.get_name() != "headless"


static func apply_display() -> void:
	if not is_desktop():
		return
	var want := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != want:
		DisplayServer.window_set_mode(want)
		if not fullscreen:
			## A window big enough to read: two thirds of the screen at 16:9.
			var scr := DisplayServer.screen_get_size()
			var w := int(scr.x * 0.66)
			DisplayServer.window_set_size(Vector2i(w, int(w * 9.0 / 16.0)))
			DisplayServer.window_set_position((scr - DisplayServer.window_get_size()) / 2)


static func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	apply_display()
	save_to_disk()


static func set_fight_controls(which: String) -> void:
	if CONTROLS.has(which):
		fight_controls = which
		save_to_disk()


static func set_fight_hand(which: String) -> void:
	if HANDS.has(which):
		fight_hand = which
		save_to_disk()


# ---------------------------------------------------------------------- tips
## THE ONE-TIME COACH MARKS (Pete, 29 Sep 2026, #5: "Draw a route" and "The
## corner"). Kept with the device, not the save: a player who starts a second
## club has already been shown how to draw a route.
static var tips_seen: Array[String] = []
## The test runner exports RB_NO_TIPS=1: a sweep that walks every screen must see
## the screens, not a coach mark over them. `test_audit_ui` turns it back on to
## hold the tips themselves.
static var tips_enabled: bool = OS.get_environment("RB_NO_TIPS") == ""


static func tip_due(key: String) -> bool:
	load_once()
	return tips_enabled and not tips_seen.has(key)


static func tip_done(key: String) -> void:
	if not tips_seen.has(key):
		tips_seen.append(key)
		save_to_disk()


# ------------------------------------------------------------------ language
## THE LANGUAGE (28 Sep 2026). "" is Automatic: the phone's own language if it is
## one this build SHIPS, else English.
##
## SHIPPING is the list Pete has approved after a native read. The eight drafts
## are registered in project.godot, so without this gate a Spanish phone would
## open a release build in an unreviewed draft — `apply_language` is what stops
## it. In a DEBUG build the drafts are offered too, marked, so they can be looked
## at on a real screen before anybody signs them off.
const SHIPPING: Array[String] = ["en"]
const DRAFTS: Array[String] = ["es", "fr", "de", "it", "pt_BR", "pl", "uk", "ja"]
const LANG_NAME := {
	"": "Automatic", "en": "English", "es": "Español", "fr": "Français",
	"de": "Deutsch", "it": "Italiano", "pt_BR": "Português (BR)", "pl": "Polski",
	"uk": "Українська", "ja": "日本語",
}
static var language: String = ""
## Tests set this to see what a release build would offer.
static var release_rules: bool = false


## What the picker offers, Automatic first.
static func offered() -> Array[String]:
	var out: Array[String] = [""]
	out.append_array(SHIPPING)
	if OS.is_debug_build() and not release_rules:
		out.append_array(DRAFTS)
	return out


static func is_draft(code: String) -> bool:
	return DRAFTS.has(code) and not SHIPPING.has(code)


## The locale actually used: the chosen one if it is still offered, else the
## phone's if it ships, else English. A phone never lands in a draft by itself.
static func resolved() -> String:
	if language != "" and offered().has(language):
		return language
	var os_full := OS.get_locale()
	var os_lang := OS.get_locale_language()
	for code in SHIPPING:
		if code == os_full or code == os_lang:
			return code
	return "en"


static func apply_language() -> void:
	TranslationServer.set_locale(resolved())


static func set_language(code: String) -> void:
	language = code if offered().has(code) else ""
	apply_language()
	save_to_disk()


static func language_name(code: String) -> String:
	var nm := UiKit.t("Automatic") if code == "" else String(LANG_NAME.get(code, code))
	return nm + (UiKit.t("  (draft)") if is_draft(code) else "")


static func apply() -> void:
	Audio.set_volume(Audio.BUS_MUSIC, music)
	Audio.set_volume(Audio.BUS_SFX, sfx)
	Audio.set_volume(Audio.BUS_UI, interface)


## One step is an eighth, which gives eight visible notches — enough to be worth
## adjusting and few enough to hit with a thumb.
const STEP := 0.125


static func nudge(which: String, dir: int) -> void:
	var v := clampf(get_level(which) + float(dir) * STEP, 0.0, 1.0)
	match which:
		"music": music = v
		"sfx": sfx = v
		_: interface = v
	apply()
	save_to_disk()


static func get_level(which: String) -> float:
	match which:
		"music": return music
		"sfx": return sfx
		_: return interface


## THE CREDITS ARE GENERATED, NOT TYPED.
##
## Attribution is a condition of the HeatleyBros licence — failing to attribute
## is "a material breach" — so the one thing that must never happen is the
## credits screen and the audio catalog drifting apart. This reads `LICENSED`,
## which is the same dictionary `resolve()` falls back through, so a track
## cannot be in the game without being on this list. `test_audio.gd` asserts it.
## THE TYPEFACE, credited from where it is declared. Press Start 2P is SIL OFL,
## which makes the copyright notice a condition of redistribution — the same
## shape of obligation as the music, so it is met the same way.
static func face_credit() -> Dictionary:
	return UiKit.FACE_CREDIT


static func credit_lines() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in Audio.LICENSED:
		var e: Dictionary = Audio.LICENSED[id]
		out.append({
			"slot": String(id),
			"line": "%s — \"%s\"" % [String(e.get("artist", "")), String(e.get("title", ""))],
			"from": String(e.get("album", "")),
			"url": String(e.get("url", "")),
			"licence": String(e.get("licence", "")),
		})
	return out
