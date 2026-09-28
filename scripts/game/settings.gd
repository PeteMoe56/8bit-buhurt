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


static func load_once() -> void:
	if _loaded:
		return
	_loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(path) == OK:
		music = clampf(float(cfg.get_value("audio", "music", music)), 0.0, 1.0)
		sfx = clampf(float(cfg.get_value("audio", "sfx", sfx)), 0.0, 1.0)
		interface = clampf(float(cfg.get_value("audio", "ui", interface)), 0.0, 1.0)
		language = String(cfg.get_value("general", "language", ""))
	apply()
	apply_language()


static func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "ui", interface)
	cfg.set_value("general", "language", language)
	cfg.save(path)


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
const DRAFTS: Array[String] = ["es", "fr", "de", "it", "pt_BR", "pl", "ru", "ja"]
const LANG_NAME := {
	"": "Automatic", "en": "English", "es": "Español", "fr": "Français",
	"de": "Deutsch", "it": "Italiano", "pt_BR": "Português (BR)", "pl": "Polski",
	"ru": "Русский", "ja": "日本語",
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
