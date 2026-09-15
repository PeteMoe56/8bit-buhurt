class_name Audio
extends RefCounted
## MUSIC AND SOUND — ported from ACRTW's AudioDirector (Pete, 10 Sep 2026:
## *"Check ACRTW, we built an awesome audio engine in it. We can translate that
## here"*), and it was worth porting rather than rewriting.
##
## WHAT CAME ACROSS, and why each piece is here rather than reinvented:
##
##   * **The buses are created at RUN TIME**, not stored in a
##     `default_bus_layout.tres`. A bus layout is a binary resource that has to
##     be edited in the editor and kept in step with the code that names the
##     buses, and when the two drift the sound silently lands on Master. Naming
##     them in one const and building them on first use means there is one
##     source of truth and no resource to lose.
##   * **A catalog rather than paths at the call site.** Every track carries its
##     own volume, loop flag and fade times, so balancing the mix is a diff of
##     one dictionary instead of a hunt through the scenes.
##   * **A pool of SFX players.** Twelve, round-robin. Allocating a player per
##     sound is how a UI click stutters on a phone.
##   * **`play_music_or_stop`** — a track that is not there is not an error. This
##     is the piece that matters most today, because there is not a single audio
##     file in this project yet and the whole system has to be silent and
##     harmless until there is.
##   * **The WAV-versus-Ogg loop gotcha**, comment and all. It is hard-won and
##     it would have been re-learned the expensive way.
##
## WHAT HAD TO CHANGE: ACRTW's director is an **autoload Node**. Constraint 06.5
## rules autoloads out of this project, and everything else here is a `class_name`
## holder with static vars — `Session`, `Tuning`, `UiKit`. But audio genuinely
## needs to be in the tree: `AudioStreamPlayer` has to be a child of something
## and `create_tween` is a Node method.
##
## So this is a static holder that **owns one node and builds it lazily**, on the
## first call that needs it, parented to the WINDOW rather than to the current
## scene — so the music does not stop when the player walks from the clubhouse
## into a fight. Same lifetime an autoload would have had, without being one.
##
## AND IT IS SILENT HEADLESS. The suite runs a hundred and twenty-two checks
## through `--script` with no audio device and no main loop; every entry point
## here returns early rather than warning, or the test output would be buried in
## push_warnings about files nobody has recorded yet.

const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_UI := "UI"

const FADE_IN := 0.75
const FADE_OUT := 0.75
const POOL := 12


# ------------------------------------------------------------------ the music
## ONE TRACK PER MOOD, and that is the whole point of doing this now rather than
## later. `UiKit.Mood` already decides what the shell looks like; the same value
## decides what it sounds like, so a cup night is a different colour AND a
## different arrangement without a second piece of state to keep in step.
##
## Pete's plan, and it is the right one: **the same melody, differently
## arranged.** One tune for the club, a heavier treatment of it for a cup, and
## the heaviest for the final. That is how the 8-bit boss idea actually works —
## you recognise the tune and the room has changed around it.
const MUSIC := {
	## LICENSED, NOT OURS. This slot holds HeatleyBros' "Game On" (HeatleyBros IV,
	## track 19) under their Attribution License — which is **revocable**: "The
	## Owner may terminate this License at any time, with or without cause," and
	## nothing in it protects a game already shipped.
	##
	## So the fallback chain below runs `menu -> menu_own -> club`. Delete
	## `menu.ogg` and the synthesised menu takes over on the next launch, with no
	## code change and no other file touched. That is the whole mitigation, and it
	## is why `menu_own` exists as a slot nothing ever asks for by name.
	##
	## ATTRIBUTION IS A CONDITION OF THE LICENCE, not a courtesy: failure to
	## attribute is "a material breach". The game needs a credits screen before it
	## ships with this file in it.
	"menu": {
		"path": "res://audio/music/menu.ogg",
		"about": "Title screen. HeatleyBros — Game On (licensed, see menu_own).",
		"db": -8.0, "loop": true, "in": 1.2, "out": 0.8,
	},
	## Ours, and the insurance policy. Never requested directly — it is reached
	## only when `menu.ogg` is absent.
	"menu_own": {
		"path": "res://audio/music/menu_own.ogg",
		"about": "Title screen, ours. The tune stated plainly, call and response.",
		"db": -8.0, "loop": true, "in": 1.2, "out": 0.8,
	},
	"club": {
		"path": "res://audio/music/club.ogg",
		"about": "The clubhouse on an ordinary week. The base melody, acoustic.",
		"db": -10.0, "loop": true, "in": 1.0, "out": 0.8,
	},
	"cup": {
		"path": "res://audio/music/cup.ogg",
		"about": "Cup night. Same melody, half-time, heavier.",
		"db": -8.0, "loop": true, "in": 0.6, "out": 0.5,
	},
	"hosted": {
		"path": "res://audio/music/hosted.ogg",
		"about": "Your own tournament. The melody, but celebratory.",
		"db": -8.0, "loop": true, "in": 0.8, "out": 0.6,
	},
	"worlds": {
		"path": "res://audio/music/worlds.ogg",
		"about": "Worlds. Bigger, stranger, further from home.",
		"db": -7.0, "loop": true, "in": 0.6, "out": 0.5,
	},
	"final": {
		"path": "res://audio/music/final.ogg",
		"about": "The final. Full metal treatment of the melody.",
		"db": -6.0, "loop": true, "in": 0.3, "out": 0.4,
	},
	## THE CHAMPION CUE IS A ONE-SHOT — `loop` false — and it is the only track
	## in the set that is. It lands on a held major chord and stops; looping it
	## would turn a victory into a waiting room.
	"champion": {
		"path": "res://audio/music/champion.ogg",
		"about": "You won it. The melody lifted out of Dorian into major.",
		"db": -6.0, "loop": false, "in": 0.05, "out": 0.3,
	},
	"fight": {
		"path": "res://audio/music/fight.ogg",
		"about": "A league bout. Driving, and it has to survive three rounds.",
		"db": -11.0, "loop": true, "in": 0.4, "out": 0.4,
	},
}

## ACRTW keeps seven catalogs — music, ambience, UI, combat, stone, stingers, VO
## — each with its own near-identical play function. That is the right shape for
## a game with a stone intro and voice acting in it, and premature for one with
## no audio files at all. One catalog with a BUS on each entry does the same job
## in a fifth of the lines, and splitting it later is a rename.
const SOUNDS := {
	"tap": {"path": "res://audio/ui/tap.ogg", "bus": BUS_UI, "db": -12.0},
	"confirm": {"path": "res://audio/ui/confirm.ogg", "bus": BUS_UI, "db": -10.0},
	"refuse": {"path": "res://audio/ui/refuse.ogg", "bus": BUS_UI, "db": -10.0},
	"coin": {"path": "res://audio/ui/coin.ogg", "bus": BUS_UI, "db": -9.0},
	"down": {"path": "res://audio/fight/down.ogg", "bus": BUS_SFX, "db": -6.0},
	"clash": {"path": "res://audio/fight/clash.ogg", "bus": BUS_SFX, "db": -9.0},
	"whistle": {"path": "res://audio/fight/whistle.ogg", "bus": BUS_SFX, "db": -7.0},
	"crowd": {"path": "res://audio/fight/crowd.ogg", "bus": BUS_SFX, "db": -12.0},
	## THE JUICE LAYER'S OWN FOUR. `back` is `tap` a fifth down, `fanfare` is the
	## only UI sound allowed to be long, `wipe` is air rather than a note, and
	## `type` is deliberately almost inaudible — it fires every second frame for
	## the length of a paragraph and anything with a shape to it becomes a
	## machine gun by the third word.
	"back": {"path": "res://audio/ui/back.ogg", "bus": BUS_UI, "db": -13.0},
	"fanfare": {"path": "res://audio/ui/fanfare.ogg", "bus": BUS_UI, "db": -8.0},
	"wipe": {"path": "res://audio/ui/wipe.ogg", "bus": BUS_UI, "db": -16.0},
	"type": {"path": "res://audio/ui/type.ogg", "bus": BUS_UI, "db": -22.0},
}


## WHAT PLAYS WHEN A TRACK IS NOT WRITTEN YET.
##
## Four of the seven exist. Without this map the other three moods and the
## ordinary league bout would be **silent**, and silence on one screen and music
## on the next reads as the audio being broken rather than as the audio being
## unfinished. A fallback is not a placeholder — it is a reasonable answer that
## happens to be reused.
##
## Each choice, and why it is the nearest honest fit:
##
##   menu   -> club    the club's own theme is the right thing to open on
##   fight  -> cup     a league bout wants drive, and the clubhouse loop has
##                     none; cup night is the closest thing written
##   hosted -> cup     your own tournament IS cup energy, just warmer
##   worlds -> cup     the weakest of the four, and deliberately NOT `final` —
##                     the Phrygian theme is the boss, and if Worlds borrows it
##                     then the actual final has nothing left to escalate to
##
## Worlds is therefore the next track anybody should write. It is the one place
## in the game where the fallback is audibly a compromise.
## SLOTS HOLDING SOMEBODY ELSE'S MUSIC, and the owned slot each one falls back
## to. Every entry here is a licence that can end — HeatleyBros' terms are
## explicitly revocable "at any time, with or without cause" — so every entry
## here must have somewhere to fall. `test_audio.gd` asserts it.
const LICENSED := {
	"menu": {
		"fallback": "menu_own",
		"artist": "HeatleyBros",
		"title": "Game On",
		"album": "HeatleyBros IV",
		"url": "heatleybros.com",
		"licence": "HeatleyBros Attribution License",
	},
}


const FALLBACK := {
	"menu": "menu_own",
	"menu_own": "club",
	"fight": "cup",
	"hosted": "cup",
	"worlds": "cup",
}


## Follow the fallback chain until something is actually on disk. Returns "" when
## nothing in the chain exists, which is the signal to go quiet.
static func resolve(id: String) -> String:
	var seen: Array[String] = []
	var at := id
	while at != "" and not seen.has(at):
		seen.append(at)
		var d: Dictionary = MUSIC.get(at, {})
		var path := String(d.get("path", ""))
		if path != "" and ResourceLoader.exists(path):
			return at
		at = String(FALLBACK.get(at, ""))
	return ""


# ------------------------------------------------------------------- the rig
static var _rig: Node = null
static var _music: AudioStreamPlayer = null
static var _pool: Array[AudioStreamPlayer] = []
static var _next: int = 0
static var _tween: Tween = null
static var _playing: String = ""
## Set false by anything that wants silence — the settings screen, and the
## suite. Kept as a var rather than read from a setting so a test can turn it
## off without a save file.
static var enabled: bool = true


## Everything public goes through here first, so there is exactly one place that
## knows how to fail quietly.
static func _ready_rig() -> bool:
	if not enabled:
		return false
	if _rig != null and is_instance_valid(_rig):
		return true
	var loop := Engine.get_main_loop()
	if loop == null or not (loop is SceneTree):
		return false
	var tree := loop as SceneTree
	if tree.root == null:
		return false

	_buses()
	_rig = Node.new()
	_rig.name = "AudioRig"
	## Parented to the WINDOW, not the current scene. A player under the scene is
	## freed on every scene change, which would cut the music every time somebody
	## opened the Chalkboard.
	tree.root.add_child(_rig)
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.bus = BUS_MUSIC
	_rig.add_child(_music)
	_pool.clear()
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.name = "Sfx%d" % i
		p.bus = BUS_SFX
		_rig.add_child(p)
		_pool.append(p)
	return true


## Built here rather than stored in a `default_bus_layout.tres`, which is
## ACRTW's trick and a good one: a bus layout is a binary the editor owns, the
## names live in code, and when the two drift every sound quietly lands on
## Master with nobody's volume slider attached to it.
static func _buses() -> void:
	for b in [BUS_MUSIC, BUS_SFX, BUS_UI]:
		if AudioServer.get_bus_index(b) != -1:
			continue
		AudioServer.add_bus(AudioServer.bus_count)
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, b)
		AudioServer.set_bus_send(i, BUS_MASTER)


# ------------------------------------------------------------------ playing
## THE CHAMPION CUE, and it needed its own entry point.
##
## `for_mood` cannot play it: winning is not an occasion you sit in, it is a
## moment, and by the time the result is posted the mood has already gone back
## to normal. It was written, mastered and shipped with **nothing in the game
## calling it** — a cue nobody can hear is a file, not a feature.
static func champion() -> void:
	music("champion")


## WHAT THE OCCASION SOUNDS LIKE. The one call the rest of the game makes.
static func for_mood(mood: int, fighting: bool = false) -> void:
	match mood:
		UiKit.Mood.CUP: music("cup")
		UiKit.Mood.HOSTED: music("hosted")
		UiKit.Mood.WORLDS: music("worlds")
		UiKit.Mood.FINAL: music("final")
		_: music("fight" if fighting else "club")


## Start a track, crossfading out whatever is on. A track that is not in the
## catalog, or whose file is not there, **stops the music and says nothing** —
## which is what lets this whole system ship before a single note is recorded.
static func music(id: String) -> void:
	if not _ready_rig():
		return
	## Ask for what the screen wants; play the nearest thing that exists.
	id = resolve(id)
	if id == "":
		stop()
		return
	var d: Dictionary = MUSIC.get(id, {})
	var path := String(d.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		stop()
		return
	if _playing == id and _music.playing:
		return
	var stream: AudioStream = load(path)
	if stream == null:
		stop()
		return
	_loop(stream, bool(d.get("loop", true)))
	var db := float(d.get("db", -8.0))
	var fin := float(d.get("in", FADE_IN))
	var fout := float(d.get("out", FADE_OUT))
	if _tween != null:
		_tween.kill()
		_tween = null
	if _music.playing and fout > 0.0:
		_tween = _rig.create_tween()
		_tween.tween_property(_music, "volume_db", -80.0, fout)
		_tween.tween_callback(func() -> void: _begin(id, stream, db, fin))
	else:
		_begin(id, stream, db, fin)


static func _begin(id: String, stream: AudioStream, db: float, fin: float) -> void:
	## SAME GUARD AS `play()`, and for the same reason. Under `--script` the rig
	## is built against a SceneTree whose root is not yet taking children, so
	## this printed `Playback can only happen when a node is inside the scene
	## tree` on every headless call — and the suite runner had grown a line to
	## filter that error away, which would have swept the next real one up with
	## it. The track is still recorded as playing: the rig's state is what the
	## rest of the game reads, and it is not wrong just because there is no
	## device to hear it on.
	if not _music.is_inside_tree():
		_playing = id
		return
	_music.stop()
	_music.stream = stream
	_music.volume_db = -80.0
	_music.play()
	_playing = id
	if fin > 0.0:
		_tween = _rig.create_tween()
		_tween.tween_property(_music, "volume_db", db, fin)
	else:
		_music.volume_db = db


static func stop(fade: float = FADE_OUT) -> void:
	if _music == null or not is_instance_valid(_music):
		return
	if _tween != null:
		_tween.kill()
		_tween = null
	_playing = ""
	if not _music.playing:
		return
	if fade > 0.0:
		_tween = _rig.create_tween()
		_tween.tween_property(_music, "volume_db", -80.0, fade)
		_tween.tween_callback(func() -> void:
			_music.stop()
			_music.stream = null)
	else:
		_music.stop()
		_music.stream = null


static func now_playing() -> String:
	return _playing


## A one-shot, off the pool. Round-robin rather than "find a free one", which is
## ACRTW's choice and the right one: finding a free player means walking twelve
## nodes on every UI tap, and stealing the oldest is inaudible.
static func play(id: String) -> void:
	if not _ready_rig():
		return
	var d: Dictionary = SOUNDS.get(id, {})
	var path := String(d.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	var stream: AudioStream = load(path)
	if stream == null:
		return
	_loop(stream, false)
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.bus = String(d.get("bus", BUS_SFX))
	p.stream = stream
	p.volume_db = float(d.get("db", -10.0))
	## NOT UNTIL IT IS ACTUALLY IN THE TREE. Under `--script` the rig is built
	## against a SceneTree whose root is not yet accepting children, so `play()`
	## printed `Playback can only happen when a node is inside the scene tree`
	## on every call — and `run_tests.sh` had grown a line to filter that error
	## out of the suite's output, which is sweeping dirt under a rug: the next
	## real playback error would have been swept with it. One guard, and the
	## filter can go.
	if not p.is_inside_tree():
		return
	p.play()


## LOOPING IS NOT ONE FLAG. Straight from ACRTW, comment and all, because it is
## the kind of thing that costs an afternoon twice:
##
## `AudioStreamWAV` loops via the `loop_mode` ENUM (0 disabled, 1 forward), NOT
## the `loop` bool that Ogg and MP3 use. Setting `loop` on a WAV does nothing and
## reports nothing, so a track that was supposed to loop just stops, once, in the
## middle of a fight.
static func _loop(stream: AudioStream, should: bool) -> void:
	if stream == null:
		return
	if stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if should else AudioStreamWAV.LOOP_DISABLED
		return
	for prop in stream.get_property_list():
		var n := String(prop.get("name", ""))
		if n == "loop":
			stream.set("loop", should)
			return
		if n == "loop_mode":
			stream.set("loop_mode", 1 if should else 0)
			return


# ------------------------------------------------------------------ settings
## Volume as 0-1 per bus, which is what a slider gives you. Converted to dB here
## so no screen has to know that audio is logarithmic.
static func set_volume(bus: String, amount: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		_buses()
		i = AudioServer.get_bus_index(bus)
	if i == -1:
		return
	var a := clampf(amount, 0.0, 1.0)
	AudioServer.set_bus_mute(i, a <= 0.001)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(a, 0.0001)))


static func volume_of(bus: String) -> float:
	var i := AudioServer.get_bus_index(bus)
	if i == -1:
		return 1.0
	return 0.0 if AudioServer.is_bus_mute(i) else db_to_linear(AudioServer.get_bus_volume_db(i))


## WHAT IS ACTUALLY RECORDED, for a dev screen and for the register. A catalog
## that lists forty tracks and has two files is a catalog that lies.
static func stocktake() -> Dictionary:
	var have := 0
	var want := 0
	var missing: Array[String] = []
	for cat in [MUSIC, SOUNDS]:
		for id in cat.keys():
			want += 1
			if ResourceLoader.exists(String((cat[id] as Dictionary)["path"])):
				have += 1
			else:
				missing.append(String(id))
	return {"have": have, "want": want, "missing": missing}
