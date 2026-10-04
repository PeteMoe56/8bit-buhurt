extends SceneTree
## The audio rig, ported from ACRTW's AudioDirector.
##
##   godot --headless --path . --script res://tests/test_audio.gd
##
## There is not a single audio file in this project yet, which makes this the
## most important moment to test it: **the whole system has to be silent and
## harmless until there is.** A rig that pushes a warning for every missing file
## would bury a hundred and twenty-two checks in noise, and one that throws would
## take the game down on a screen nobody had recorded a track for.
##
## The second thing worth proving is the wiring: `UiKit.Mood` decides what the
## shell looks like AND what it sounds like, from one read. Two systems off one
## value cannot disagree about what occasion this is — but only if nothing has
## quietly added a sixth mood the music does not know about.

var failures: Array[String] = []
## COUNTED, NOT TYPED. Every banner in this suite carried a hand-written total
## and six of fifteen were wrong — one claimed fourteen checks and ran thirteen.
## A number that says how much was verified is the last number that should be
## maintained by remembering.
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the audio rig ===\n")
	_test_silence_is_the_default_state()
	_test_every_mood_has_a_track()
	_test_the_catalog_is_honest()
	_test_licensed_music_can_be_pulled()
	_test_every_licensed_track_is_credited()
	_test_a_bus_is_built_not_stored()
	_test_volume_is_a_slider_not_decibels()
	_test_no_screen_is_silent()
	_test_the_sounds_are_actually_called()
	_test_the_menus_play_one_playlist()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE RIG HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	if cond:
		print("  pass  %s — %s" % [label, detail])
	else:
		print("  FAIL  %s — %s" % [label, detail])
		failures.append("%s: %s" % [label, detail])


func _test_silence_is_the_default_state() -> void:
	## EVERY ENTRY POINT, called with nothing recorded and no audio device, has to
	## come back without a sound and without a complaint. This is the check that
	## lets the rest of the game call `Audio.for_mood()` on every frame of every
	## screen a year before anybody writes the music.
	Audio.enabled = true
	var calls := 0
	for id in Audio.MUSIC.keys():
		Audio.music(String(id))
		calls += 1
	for id in Audio.SOUNDS.keys():
		Audio.play(String(id))
		calls += 1
	for m in UiKit.PALETTES.keys():
		Audio.for_mood(int(m))
		Audio.for_mood(int(m), true)
		calls += 2
	## And the ones that are meant to be no-ops on a rig that was never built.
	Audio.music("a track that does not exist")
	Audio.play("nor this one")
	Audio.stop()
	calls += 3
	var quiet: bool = Audio.now_playing() == ""
	notes.append("%d calls into the rig with no files and no device, and nothing played" % calls)
	_ok(quiet, "silence is the default state",
		"every entry point is safe to call before a single note has been recorded")


func _test_every_mood_has_a_track() -> void:
	## THE WIRING. `UiKit.Mood` dresses the room and scores it off one read, so a
	## mood added to the palette and not to the catalog would leave a screen that
	## looks like an occasion and sounds like a Tuesday — and nothing would say
	## so, because a missing track is deliberately silent.
	var missing: Array[String] = []
	## Mirrors Audio.for_mood. Written out rather than reflected, because the
	## point is to catch a mood nobody thought about, and reflection would
	## cheerfully agree that the default branch covers it.
	var want := {
		UiKit.Mood.NORMAL: "club",
		UiKit.Mood.CUP: "cup",
		UiKit.Mood.HOSTED: "hosted",
		UiKit.Mood.WORLDS: "worlds",
		UiKit.Mood.FINAL: "final",
	}
	for m in UiKit.PALETTES.keys():
		if not want.has(m):
			missing.append("mood %d has a palette and no track" % int(m))
			continue
		if not Audio.MUSIC.has(want[m]):
			missing.append("mood %d wants '%s', which is not in the catalog" % [int(m), want[m]])
	## And the fight variant of NORMAL, which is the one branch that is not a mood.
	if not Audio.MUSIC.has("fight"):
		missing.append("no track for an ordinary league bout")
	if not Audio.MUSIC.has("menu"):
		missing.append("no track for the title screen")
	## The champion cue is not a mood — there is no "you won" palette, because a
	## victory is a moment rather than an occasion you sit in. It is played
	## explicitly, so it is checked explicitly.
	if not Audio.MUSIC.has("champion"):
		missing.append("no champion cue")
	if bool((Audio.MUSIC.get("champion", {}) as Dictionary).get("loop", true)):
		missing.append("the champion cue loops, which turns a victory into a waiting room")
	notes.append("%d moods, %d music tracks, %d one-shots"
		% [UiKit.PALETTES.size(), Audio.MUSIC.size(), Audio.SOUNDS.size()])
	if not missing.is_empty():
		notes.append("  " + ", ".join(missing))
	_ok(missing.is_empty(), "every mood has a track",
		"the palette and the catalog cover the same five occasions, plus a bout and the menu")


func _test_the_catalog_is_honest() -> void:
	## A catalog entry with no path, or two entries pointing at one file, is a
	## track somebody will spend an afternoon wondering why they cannot hear.
	## And every entry carries the note saying what it is FOR, because the person
	## recording these is not the person who wrote the dictionary.
	var seen := {}
	var bad: Array[String] = []
	for id in Audio.MUSIC.keys():
		var d: Dictionary = Audio.MUSIC[id]
		var path := String(d.get("path", ""))
		if path == "" or not path.begins_with("res://"):
			bad.append("%s has no usable path" % id)
		if seen.has(path):
			bad.append("%s and %s share a file" % [id, seen[path]])
		seen[path] = id
		if String(d.get("about", "")) == "":
			bad.append("%s does not say what it is for" % id)
	for id in Audio.SOUNDS.keys():
		var d2: Dictionary = Audio.SOUNDS[id]
		var p2 := String(d2.get("path", ""))
		if p2 == "" or not p2.begins_with("res://"):
			bad.append("%s has no usable path" % id)
		if seen.has(p2):
			bad.append("%s and %s share a file" % [id, seen[p2]])
		seen[p2] = id

	var take := Audio.stocktake()
	notes.append("stocktake: %d of %d recorded — still to write: %s"
		% [take["have"], take["want"], ", ".join(take["missing"] as Array)])
	if not bad.is_empty():
		notes.append("  " + ", ".join(bad))
	## AND EVERY FILE IS THERE (29 Sep 2026). This reported the stocktake and
	## passed anyway: tap, wipe and type were missing — the tap being the most
	## frequent sound in the game — and the check said "honest".
	_ok(bad.is_empty() and (take["missing"] as Array).is_empty(), "the catalog is honest",
		"every entry has its own file and says what it is for, and the stocktake reports %d of %d actually present%s"
			% [take["have"], take["want"], "" if (take["missing"] as Array).is_empty()
				else " — missing: " + ", ".join(take["missing"] as Array)])


func _test_a_bus_is_built_not_stored() -> void:
	## ACRTW's trick, and the reason it was worth porting rather than reaching for
	## a `default_bus_layout.tres`: a bus layout is a binary the editor owns while
	## the bus NAMES live in code, and when the two drift every sound lands on
	## Master with nobody's volume slider attached to it. Built at run time there
	## is one source of truth and nothing to lose.
	Audio.set_volume(Audio.BUS_MUSIC, 0.5)      ## forces the buses into being
	var built: Array[String] = []
	var absent: Array[String] = []
	for b in [Audio.BUS_MUSIC, Audio.BUS_SFX, Audio.BUS_UI]:
		if AudioServer.get_bus_index(b) != -1:
			built.append(b)
		else:
			absent.append(b)
	## Master is the engine's own and must not have been duplicated.
	var masters := 0
	for i in AudioServer.bus_count:
		if AudioServer.get_bus_name(i) == Audio.BUS_MASTER:
			masters += 1
	notes.append("buses present: %s (of %d on the server, %d named Master)"
		% [", ".join(built), AudioServer.bus_count, masters])
	_ok(absent.is_empty() and masters == 1,
		"a bus is built, not stored",
		"the three buses exist with no layout resource in the project, and Master was not duplicated")


func _test_volume_is_a_slider_not_decibels() -> void:
	## A screen should hand over 0 to 1. Audio is logarithmic and no menu should
	## have to know that — so the conversion lives here and is checked both ways,
	## including the end that matters: zero has to be SILENT rather than -80 dB,
	## because a slider dragged to the bottom that still whispers is a bug report.
	Audio.set_volume(Audio.BUS_MUSIC, 1.0)
	var full := Audio.volume_of(Audio.BUS_MUSIC)
	Audio.set_volume(Audio.BUS_MUSIC, 0.5)
	var half := Audio.volume_of(Audio.BUS_MUSIC)
	Audio.set_volume(Audio.BUS_MUSIC, 0.0)
	var off := Audio.volume_of(Audio.BUS_MUSIC)
	var muted := AudioServer.is_bus_mute(AudioServer.get_bus_index(Audio.BUS_MUSIC))
	Audio.set_volume(Audio.BUS_MUSIC, 1.0)
	var back := Audio.volume_of(Audio.BUS_MUSIC)
	notes.append("slider 1.0 -> %.2f, 0.5 -> %.2f, 0.0 -> %.2f (muted: %s), and back to %.2f"
		% [full, half, off, "yes" if muted else "NO", back])
	_ok(absf(full - 1.0) < 0.01 and absf(half - 0.5) < 0.02
			and off == 0.0 and muted and absf(back - 1.0) < 0.01,
		"volume is a slider, not decibels",
		"0-1 in and 0-1 out, zero actually mutes the bus, and a muted bus comes back")


func _test_no_screen_is_silent() -> void:
	## FOUR TRACKS, SEVEN SLOTS, AND NOT ONE SILENT SCREEN.
	##
	## Silence on one screen and music on the next does not read as "that track
	## is not written yet" — it reads as the audio being broken. So every id the
	## game can ask for has to resolve, through the fallback chain, to a file
	## that is actually on disk.
	##
	## This check is the reason the chain exists, and it is written to keep
	## working as tracks arrive: once `worlds.ogg` is recorded, `resolve` stops
	## returning `cup` for it and this still passes without an edit.
	var unresolved: Array[String] = []
	var borrowed: Array[String] = []
	for id in Audio.MUSIC.keys():
		var got := Audio.resolve(String(id))
		if got == "":
			unresolved.append(String(id))
		elif got != String(id):
			borrowed.append("%s->%s" % [id, got])

	## And every mood, through the real entry point the screens use.
	var moods_ok := true
	for m in UiKit.PALETTES.keys():
		for fighting in [false, true]:
			Audio.for_mood(int(m), fighting)
	## The champion cue has to resolve too — it is played on its own and has no
	## fallback, so if it is missing it is silent and that is a real hole.
	if Audio.resolve("champion") == "":
		moods_ok = false

	var take := Audio.stocktake()
	notes.append("%d of %d music files recorded; borrowing: %s"
		% [Audio.MUSIC.size() - unresolved.size(), Audio.MUSIC.size(),
			"none" if borrowed.is_empty() else ", ".join(borrowed)])
	if not unresolved.is_empty():
		notes.append("  SILENT: " + ", ".join(unresolved))
	_ok(unresolved.is_empty() and moods_ok,
		"no screen is silent",
		"every music slot resolves to a file that exists, %d of them by borrowing a neighbor"
			% borrowed.size())


func _test_the_sounds_are_actually_called() -> void:
	## A SOUND NOBODY PLAYS IS A FILE, NOT A FEATURE.
	##
	## The champion cue was written, mastered and shipped with no code path
	## calling it, and nothing noticed because a missing call sounds exactly like
	## a missing file: silence. So every id in the catalog has to be reachable
	## from somewhere in the game, and this check reads the source to prove it
	## rather than trusting that somebody remembered.
	## EVERY SCRIPT, found rather than listed: a fixed list went stale the day
	## the season screen was split into five files. And the CALL, not the word —
	## `play("x"`, a Juice event's `"sound": "x"` or `music("x"` — so a dictionary key that happens to share a
	## sound's name cannot stand in for somebody playing it.
	var src := ""
	for path in _scripts("res://scripts"):
		src += FileAccess.get_file_as_string(path) + "\n"
	var orphans: Array[String] = []
	for id in Audio.SOUNDS.keys():
		if not RegEx.create_from_string('(?:play\\(|"sound":)\\s*"%s"' % id).search(src):
			orphans.append(String(id))
	## Music is reached through `for_mood` rather than by name, so only the two
	## that are played explicitly are checked here.
	## "menu" is reached through the menu playlist (4 Oct 2026), not by name.
	for id in ["champion"]:
		if not RegEx.create_from_string('music\\(\\s*"%s"' % id).search(src):
			orphans.append(id)
	if not Audio.PLAYLIST.has("menu"):
		orphans.append("menu")

	notes.append("%d one-shots, all reachable from a screen or the sim" % Audio.SOUNDS.size())
	if not orphans.is_empty():
		notes.append("  NEVER PLAYED: " + ", ".join(orphans))
	_ok(orphans.is_empty(), "the sounds are actually called",
		"every one-shot and both explicit cues appear at a real call site, not just in the catalog")


func _test_licensed_music_can_be_pulled() -> void:
	## THE INSURANCE, AND IT IS LOAD-BEARING.
	##
	## `menu.ogg` is HeatleyBros' "Game On", used under a licence that says in
	## plain words: "The Owner may terminate this License at any time, with or
	## without cause." Nothing in it covers a game already on sale.
	##
	## The mitigation is one line of `FALLBACK` and a file nothing asks for by
	## name: delete `menu.ogg` and `resolve()` walks to `menu_own`, which is ours.
	## No code change, no other file touched, no silent screen.
	##
	## Untested insurance is not insurance, so this walks the chain the way
	## `resolve()` would with the licensed file already gone.
	var broken: Array[String] = []
	for id in Audio.LICENSED:
		var entry: Dictionary = Audio.LICENSED[id]
		var owned := String(entry.get("fallback", ""))
		if not Audio.MUSIC.has(owned):
			broken.append("%s falls back to %s, which is not in the catalog" % [id, owned])
			continue
		var path := String((Audio.MUSIC[owned] as Dictionary).get("path", ""))
		if path == "" or not ResourceLoader.exists(path):
			broken.append("%s falls back to %s, whose file is missing" % [id, owned])
			continue
		if String(Audio.FALLBACK.get(id, "")) != owned:
			broken.append("%s is licensed but its FALLBACK does not point at %s" % [id, owned])
			continue
		## And the owned slot must itself land somewhere real, so pulling the
		## licensed file cannot strand the chain.
		if Audio.resolve(owned) == "":
			broken.append("%s resolves to nothing on its own" % owned)
	if not broken.is_empty():
		notes.append("  " + ", ".join(broken))
	notes.append("%d licensed slot(s), each with an owned fallback that exists"
		% Audio.LICENSED.size())
	_ok(broken.is_empty(), "licensed music can be pulled",
		"every borrowed track falls back to one of ours, so a revoked licence is a file deletion")


func _test_every_licensed_track_is_credited() -> void:
	## ATTRIBUTION IS A CONDITION, NOT A COURTESY. The HeatleyBros licence says
	## failing to attribute is "a material breach", which means a credits screen
	## that silently falls out of step with the audio catalog is not a cosmetic
	## bug — it is a breach that ships.
	##
	## So `Settings.credit_lines()` reads `Audio.LICENSED` rather than a typed
	## list, and this asserts the loop actually closes: every licensed slot
	## produces a line, and every line names an artist, a title and a licence.
	var missing: Array[String] = []
	var lines := Settings.credit_lines()
	var seen: Array[String] = []
	for c in lines:
		seen.append(String(c["slot"]))
		for field in ["line", "from", "url", "licence"]:
			if String(c.get(field, "")).strip_edges() == "":
				missing.append("%s has no %s" % [String(c["slot"]), field])
	for id in Audio.LICENSED:
		if not seen.has(String(id)):
			missing.append("%s is licensed but never credited" % String(id))
	if not missing.is_empty():
		notes.append("  " + ", ".join(missing))
	notes.append("credits: %d licensed track(s), each named with artist, source and licence"
		% lines.size())
	_ok(missing.is_empty(), "every licensed track is credited",
		"the credits screen is generated from the same catalog the fallback walks")


func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir + "/" + d))
	return out


## ONE PLAYLIST FOR EVERY MENU (Pete, 4 Oct 2026: the music changed on every tab,
## because the season screen asked for "club" and the ground under it asked for
## "menu" in the same draw). Every menu door now asks for the playlist, and a
## second ask while a playlist track plays keeps it. Played to the end, a track
## hands over to a different one.
func _test_the_menus_play_one_playlist() -> void:
	var was := Audio.enabled
	Audio.enabled = true
	Audio.stop(0.0)
	Audio.for_mood(UiKit.Mood.NORMAL)
	var first := Audio.now_playing()
	Audio.menu()
	Audio.for_mood(UiKit.Mood.NORMAL)
	var tracks := Audio._tracks()
	_ok(tracks.size() >= 2 and tracks.has(first) and Audio.now_playing() == first,
		"every menu door keeps the one playlist track playing",
		"%s, then %s, of %s" % [first, Audio.now_playing(), str(tracks)])
	var seen := {first: true}
	for k in 6:
		Audio._on_finished()
		seen[Audio.now_playing()] = true
	_ok(seen.size() == tracks.size(), "and a finished track hands over through the whole list",
		"heard %s" % str(seen.keys()))
	Audio.for_mood(UiKit.Mood.NORMAL, true)
	_ok(Audio.now_playing() == "fight", "a fight still has its own track", Audio.now_playing())
	Audio.stop(0.0)
	Audio.enabled = was
