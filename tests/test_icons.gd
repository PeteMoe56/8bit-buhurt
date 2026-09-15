extends SceneTree
## The icon bank, the stars, and the ornaments.
##
##   godot --headless --path . --script res://tests/test_icons.gd
##
## THE CHECK THAT MATTERS IS THE THIRD ONE. `UiIcons.draw()` with a name that
## does not exist draws **nothing** — no error, no pink square, no log line. A
## typo in a button's mark is a button that silently loses its icon, and the
## person who notices is a player six months later. So this walks the actual
## source and asserts every name any screen asks for is a name the bank has.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the icon bank ===\n")
	_test_every_mark_is_on_the_grid()
	_test_the_small_pair()
	_test_every_name_a_screen_asks_for_exists()
	_test_the_merge_is_lossless()
	_test_the_merge_was_worth_doing()
	_test_textures_are_cached()
	_test_stars_are_monotonic()
	_test_the_ornaments_and_their_licence()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE BANK HOLDS (%d checks)\n" % checks)
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


## SIXTEEN BY SIXTEEN, EVERY ONE. A grid one row short draws a mark a pixel
## narrow, which is invisible alone and obvious the moment it sits beside
## another one.
func _test_every_mark_is_on_the_grid() -> void:
	var bad: Array[String] = []
	for name in UiIcons.MARKS:
		var rows: Array = UiIcons.MARKS[name]
		if rows.size() != UiIcons.GRID:
			bad.append("%s has %d rows" % [name, rows.size()])
			continue
		for i in rows.size():
			var r := String(rows[i])
			if r.length() != UiIcons.GRID:
				bad.append("%s row %d is %d wide" % [name, i, r.length()])
			for c in r:
				if c != "#" and c != ".":
					bad.append("%s row %d has '%s'" % [name, i, c])
					break
	_ok(bad.is_empty(), "every mark is %dx%d" % [UiIcons.GRID, UiIcons.GRID],
		"%d marks" % UiIcons.MARKS.size() if bad.is_empty() else ", ".join(bad.slice(0, 4)))
	_ok(UiIcons.MARKS.size() >= 30, "and there are enough of them",
		"%d in the bank" % UiIcons.MARKS.size())


## The small cut is a second SIZE, not an exception, so it gets the same check.
func _test_the_small_pair() -> void:
	var bad: Array[String] = []
	for name in UiIcons.SMALL:
		var rows: Array = UiIcons.SMALL[name]
		if rows.size() != UiIcons.SMALL_GRID:
			bad.append("%s has %d rows" % [name, rows.size()])
			continue
		for i in rows.size():
			if String(rows[i]).length() != UiIcons.SMALL_GRID:
				bad.append("%s row %d" % [name, i])
	_ok(bad.is_empty(), "the small pair is %dx%d" % [UiIcons.SMALL_GRID, UiIcons.SMALL_GRID],
		"%d small marks" % UiIcons.SMALL.size() if bad.is_empty() else ", ".join(bad))
	## Both sizes must offer the same two star cuts, or `stars()` falls through
	## to nothing at one of them.
	_ok(UiIcons.SMALL.has("star") and UiIcons.SMALL.has("star_half")
		and UiIcons.MARKS.has("star") and UiIcons.MARKS.has("star_half"),
		"and both sizes have a full and a half star",
		"UiKit.stars() picks by size and must find one either way")


## THE ONE THAT EARNS ITS KEEP.
func _test_every_name_a_screen_asks_for_exists() -> void:
	var asked := {}
	## THREE SHAPES, because there are three ways a name reaches the bank and a
	## scan that knows two of them is a scan that passes while the third is
	## broken. This found its own gap on the first run: it caught the direct
	## draws and missed every button mark, which is where most of them are.
	var pats := [
		## a direct draw:  UiIcons.draw(self, "roster", ...)
		'(?:UiIcons\\.draw|UiKit\\.icon)\\s*\\(\\s*[A-Za-z_.()]+\\s*,\\s*"([a-z_0-9]+)"',
		## a button's trailing mark, which always closes the statement:
		##   ..., "helm"))   or   ..., marks[i]))
		',\\s*"([a-z_0-9]+)"\\)\\)',
		## a hint-bar pair, or any [name, label] table:  ["cursor", "OPEN"]
		'\\[\\s*"([a-z_0-9]+)"\\s*,\\s*"[A-Z ]+"\\s*\\]',
		## the tab row's parallel array:  var marks := ["shield", "roster", ...]
		'marks\\s*:=\\s*\\[([^\\]]*)\\]',
	]
	var files := _gd_files("res://scripts")
	for f in files:
		var txt := _read(f)
		if txt == "":
			continue
		for i in pats.size():
			var re := RegEx.new()
			re.compile(String(pats[i]))
			for m in re.search_all(txt):
				var got := m.get_string(1)
				if i == 3:
					## the array body — pull each quoted name out of it
					var inner := RegEx.new()
					inner.compile('"([a-z_0-9]+)"')
					for q in inner.search_all(got):
						asked[q.get_string(1)] = f
				elif got != "":
					asked[got] = f
	var missing: Array[String] = []
	for name in asked:
		if not UiIcons.has(String(name)):
			missing.append("%s (%s)" % [name, String(asked[name]).get_file()])
	_ok(missing.is_empty(), "every mark a screen asks for exists",
		"%d distinct names across %d files" % [asked.size(), files.size()]
			if missing.is_empty() else "MISSING: " + ", ".join(missing))
	## THE SCAN HAS TO BE FINDING THINGS. A regex that quietly stops matching
	## turns the check above into a check that nothing is wrong with nothing,
	## which is the most comfortable kind of green there is.
	_ok(asked.size() >= 12, "and the scan is actually finding them",
		"%d names in use" % asked.size())
	notes.append("marks in use: " + ", ".join(asked.keys()))


## THE MERGE IS AN OPTIMISATION AND OPTIMISATIONS LIE. Every pixel the grid says
## is ink must be covered by exactly one run, and no run may cover a pixel the
## grid says is empty.
func _test_the_merge_is_lossless() -> void:
	var bad: Array[String] = []
	for name in UiIcons.MARKS:
		var rows: Array = UiIcons.MARKS[name]
		var seen := []
		for y in UiIcons.GRID:
			seen.append([])
			for x in UiIcons.GRID:
				seen[y].append(0)
		for r in UiIcons.runs(String(name)):
			var rr: Rect2 = r
			for y in range(int(rr.position.y), int(rr.position.y + rr.size.y)):
				for x in range(int(rr.position.x), int(rr.position.x + rr.size.x)):
					seen[y][x] += 1
		for y in UiIcons.GRID:
			var row := String(rows[y])
			for x in UiIcons.GRID:
				var want := 1 if row[x] == "#" else 0
				if seen[y][x] != want:
					bad.append("%s at %d,%d covered %d times, wanted %d"
						% [name, x, y, seen[y][x], want])
					break
			if not bad.is_empty():
				break
		if not bad.is_empty():
			break
	_ok(bad.is_empty(), "the run merge covers exactly the ink",
		"every pixel of every mark, once" if bad.is_empty() else bad[0])


## AND IT HAS TO HAVE BEEN WORTH DOING. A screen with twenty marks on it is
## twenty times whatever this number is, every frame, on a phone.
func _test_the_merge_was_worth_doing() -> void:
	var total_runs := 0
	var total_ink := 0
	var worst := 0
	for name in UiIcons.MARKS:
		var n: int = UiIcons.runs(String(name)).size()
		total_runs += n
		worst = maxi(worst, n)
		for row in UiIcons.MARKS[name]:
			total_ink += String(row).count("#")
	var avg := float(total_runs) / float(UiIcons.MARKS.size())
	_ok(total_runs < total_ink / 3, "and it is worth doing",
		"%d rects for %d ink pixels — %.0f rects a mark, worst %d"
			% [total_runs, total_ink, avg, worst])


func _test_textures_are_cached() -> void:
	var a := UiIcons.texture("star", Color.WHITE, 1)
	var b := UiIcons.texture("star", Color.WHITE, 1)
	_ok(a != null and a == b, "a texture is built once and kept",
		"a button that rebuilt its icon every frame would be free on a desktop")
	var c := UiIcons.texture("star", Color.RED, 1)
	_ok(c != a, "and color is part of the key",
		"or every button in the game would wear the first color anybody asked for")


## A BETTER RATING CAN NEVER DRAW FEWER STARS. The same rule the roster already
## asserts about its own star column, applied to the thing that draws it.
func _test_stars_are_monotonic() -> void:
	var last := -1
	var drops: Array[String] = []
	for rating in range(0, 100):
		var halves := clampi(int(round(float(rating) / 10.0)), 0, 10)
		if halves < last:
			drops.append("%d -> %d" % [rating, halves])
		last = halves
	_ok(drops.is_empty(), "stars never go backwards",
		"0..99 climbs 0 to 10 halves" if drops.is_empty() else ", ".join(drops))


## THE ORNAMENTS ARE CC0 AND THAT IS THE REASON THE LICENCE HAS TO SHIP. CC0
## requires no attribution, so the file that proves we owe nobody anything is
## the only evidence there is.
func _test_the_ornaments_and_their_licence() -> void:
	var files := [UiKit.ORN_CREST, UiKit.ORN_PANEL, UiKit.ORN_TROPHY,
		UiKit.ORN_BANNER, UiKit.RULE_GEM, UiKit.RULE_BRACKET]
	var missing: Array[String] = []
	for f in files:
		if not ResourceLoader.exists(UiKit.ORNAMENT_DIR + String(f)):
			missing.append(String(f))
	_ok(missing.is_empty(), "every ornament UiKit names is on disk",
		"%d files" % files.size() if missing.is_empty() else ", ".join(missing))
	var lic := UiKit.ORNAMENT_DIR + "KENNEY-LICENSE.txt"
	_ok(FileAccess.file_exists(lic), "and the licence ships with them", lic)
	var txt := _read(lic)
	_ok(txt.to_lower().contains("creative commons zero") or txt.contains("CC0"),
		"and it is CC0", "%d bytes" % txt.length())


# ------------------------------------------------------------------ plumbing
func _read(path: String) -> String:
	var f := FileAccess.open(path, FileAccess.READ)
	return "" if f == null else f.get_as_text()


func _gd_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	d.list_dir_begin()
	var n := d.get_next()
	while n != "":
		if d.current_is_dir() and not n.begins_with("."):
			out.append_array(_gd_files(dir + "/" + n))
		elif n.ends_with(".gd"):
			out.append(dir + "/" + n)
		n = d.get_next()
	d.list_dir_end()
	return out
