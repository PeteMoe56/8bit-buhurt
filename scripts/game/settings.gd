class_name Settings
## Volume, and the only state in the game that is not part of a save slot.
##
## No autoload (06.5), so this is a static holder over a ConfigFile. It is read
## once at launch and written whenever something changes — a volume that resets
## every time the game opens is not a setting, it is a tease.

const PATH := "user://settings.cfg"

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
	if cfg.load(PATH) == OK:
		music = clampf(float(cfg.get_value("audio", "music", music)), 0.0, 1.0)
		sfx = clampf(float(cfg.get_value("audio", "sfx", sfx)), 0.0, 1.0)
		interface = clampf(float(cfg.get_value("audio", "ui", interface)), 0.0, 1.0)
	apply()


static func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music)
	cfg.set_value("audio", "sfx", sfx)
	cfg.set_value("audio", "ui", interface)
	cfg.save(PATH)


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
