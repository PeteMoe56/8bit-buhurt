extends SceneTree
## EVERY SCRIPT PARSES — in one engine (29 Sep 2026).
##
##   godot --headless --path . --script res://tools/parse_all.gd
##
## The gate used to start the engine once per file with `--check-only`: 235
## launches, about twelve of the suite's fifteen minutes on a two-core box. One
## engine that loads every script finds the same errors — the engine prints
## `Parse Error` / `Compile Error` with the file for each, and `run_tests.sh`
## fails on any — because a script loaded inside the project resolves every
## `class_name` the way the game does. Prints "PARSED <n>" last, so a run that
## died part-way is not mistaken for a clean one.

func _initialize() -> void:
	var files: Array[String] = []
	for dir in ["res://scripts", "res://tools", "res://tests"]:
		_collect(dir, files)
	files.sort()
	var bad := 0
	for f in files:
		var s = ResourceLoader.load(f, "", ResourceLoader.CACHE_MODE_REUSE)
		if s == null or not (s is GDScript) or not (s as GDScript).can_instantiate():
			print("DOES NOT PARSE: ", f)
			bad += 1
	print("PARSED %d scripts, %d bad" % [files.size(), bad])
	quit(1 if bad > 0 else 0)


func _collect(dir: String, out: Array[String]) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(d), out)
