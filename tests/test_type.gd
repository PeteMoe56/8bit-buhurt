extends SceneTree
## The face — that it loaded, that it is proportional, that digits are not.
##
##   godot --headless --path . --script res://tests/test_type.gd
##
## THIS FILE EXISTS BECAUSE THE FALLBACK IS SILENT. `UiKit._face()` hands back
## `ThemeDB.fallback_font` when the load fails, which is the right behaviour for
## a running game and the worst possible behaviour for a check: rename the file,
## break the import, ship the wrong folder, and every screen still draws — in
## the engine's default sans, which is not a pixel face and is not 8-bit
## anything. Nobody notices in a headless log. So the first check below is that
## the thing we got back is NOT the fallback.
##
## The rest of it is Pete's complaint, turned into arithmetic. 12 Sep 2026:
## *"Merrick looks like Merri-ck, Ulme looks like Ul-me, Coyle looks like
## Coyl-e."* The cause was a monospaced face — an `i` advancing a whole 8px cell
## leaves 2px of nothing beside it, and 2px of nothing between two letters is
## what a space looks like. A proportional face cannot have that fault, and the
## way to assert "proportional" without writing down a number that goes stale is
## to measure a narrow word against a wide one of the same length.

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== Retro Buhurt — the type ===\n")
	_test_the_face_is_the_face()
	_test_narrow_letters_take_less_room()
	_test_the_names_that_broke_it()
	_test_digits_stay_in_their_columns()
	_test_sizes_land_on_the_grid()
	_test_the_faces_share_a_ladder()
	_test_the_licence_travels()
	_test_the_credit_is_generated_not_typed()

	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE TYPE HOLDS (%d checks)\n" % checks)
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


func _w(f: Font, s: String, px: int) -> float:
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1.0, px).x


## THE FACE LOADED, and is not the engine's sans wearing its name.
func _test_the_face_is_the_face() -> void:
	var f := UiKit.body()
	_ok(f != null, "a face came back", "UiKit.body() is not null")
	_ok(f != ThemeDB.fallback_font, "and it is not the fallback",
		"a silent fallback would draw every screen in the engine's sans")
	_ok(UiKit.title() != null and UiKit.title() != ThemeDB.fallback_font,
		"and so did the display face", "UiKit.title() is a real face")
	_ok(UiKit.number() == UiKit.title(),
		"numbers are set in the display face", "its digits are the tabular ones")
	## TWO FACES, ON PURPOSE, and the check is that they are actually two. A
	## paste error that points both roles at one file would leave the UI looking
	## fine-ish and quietly throw away the hierarchy the split exists for.
	_ok(UiKit.body() != UiKit.title(), "body and display are different faces",
		"%s vs %s" % [UiKit.FACE_BODY, UiKit.FACE_TITLE])
	for file in [UiKit.FACE_BODY, UiKit.FACE_TITLE, UiKit.FACE_NUMBER]:
		_ok(ResourceLoader.exists(UiKit.FACE_DIR + file),
			"the file is where UiKit says", UiKit.FACE_DIR + file)


## PROPORTIONAL, PROVED BY COMPARISON and not by a written-down width. Six
## narrow letters must come out narrower than six wide ones; on a monospaced
## face they are identical to the pixel, which is exactly the failure.
func _test_narrow_letters_take_less_room() -> void:
	var px := UiKit.GRID * 2
	for pair in [["body", UiKit.body()], ["display", UiKit.title()]]:
		var role: String = pair[0]
		var f: Font = pair[1]
		var thin := _w(f, "iiiiii", px)
		var fat := _w(f, "MMMMMM", px)
		_ok(thin < fat, "%s: narrow letters take less room" % role,
			"iiiiii is %.0fpx, MMMMMM is %.0fpx at %dpx" % [thin, fat, px])
		## A monospaced face fails the line above by being EQUAL, so the gap has
		## to be worth having — one pixel of difference would pass and still tear.
		_ok(fat - thin >= float(px) / UiKit.GRID * 5.0,
			"%s: and the gap is worth having" % role,
			"%.0fpx apart over six letters" % (fat - thin))


## PETE'S THREE NAMES. Each one has a narrow letter in the middle, which is
## where the tear appeared. What we can assert without a stale number is that
## the narrow letter costs less than the widest letter in the same word — if it
## ever stops being true the face has gone monospaced again.
func _test_the_names_that_broke_it() -> void:
	var f := UiKit.title()
	var px := UiKit.GRID * 2
	for pair in [["Merrick", "r"], ["Ulme", "l"], ["Coyle", "l"]]:
		var name_s: String = pair[0]
		var thin_ch: String = pair[1]
		var whole := _w(f, name_s, px)
		var without := _w(f, name_s.replace(thin_ch, ""), px)
		var each := (whole - without) / float(name_s.count(thin_ch))
		var wide := _w(f, "M", px)
		_ok(each < wide, "%s does not tear" % name_s,
			"'%s' costs %.0fpx where M costs %.0fpx" % [thin_ch, each, wide])


## DIGITS DO NOT MOVE. Every screen that shows a record, a purse or a rating
## shows it in a column, and a column of proportional figures is a ragged
## column. All ten must measure the same, and a three-digit number must be
## exactly three of them.
func _test_digits_stay_in_their_columns() -> void:
	var f := UiKit.number()
	var px := UiKit.GRID * 2
	var one := _w(f, "0", px)
	var ragged := ""
	for d in "0123456789":
		if absf(_w(f, d, px) - one) > 0.01:
			ragged += d
	_ok(ragged == "", "all ten digits are one width",
		"ragged: '%s'" % ragged if ragged != "" else "each is %.0fpx at %dpx" % [one, px])
	_ok(absf(_w(f, "109", px) - one * 3.0) < 0.01, "and they add up",
		"109 is %.0fpx, three digits is %.0fpx" % [_w(f, "109", px), one * 3.0])
	## THE POINT OF IT: two numbers of the same length line up. This is the
	## check that would catch somebody "fixing" the digits into the
	## proportional pass.
	_ok(absf(_w(f, "111", px) - _w(f, "408", px)) < 0.01, "and two of them line up",
		"111 and 408 both measure %.0fpx" % _w(f, "111", px))


## THE LADDER. A pixel face is crisp at whole multiples of its grid and smeared
## everywhere else, so `snap()` has to round down and must never return zero.
func _test_sizes_land_on_the_grid() -> void:
	var g := UiKit.GRID
	for px in [1, 7, 8, 11, 13, 15, 16, 23, 24, 31, 32, 40]:
		var s := UiKit.snap(px)
		_ok(s % g == 0 and s >= g and s <= maxi(px, g),
			"snap(%d) lands on the grid" % px, "-> %d" % s)


## ONE LADDER, ASSERTED. The whole reason Rail was rebuilt on an 8px em is that
## two faces on two ems have two ladders, and a screen cannot then ask both of
## them for "the same size". The way to check it without writing a number down
## is to ask each face how tall a line it wants at a legal size and require the
## answer to be a whole number of pixels — a face off the grid gives a fraction.
func _test_the_faces_share_a_ladder() -> void:
	for pair in [["body", UiKit.body()], ["display", UiKit.title()]]:
		var role: String = pair[0]
		var f: Font = pair[1]
		for px in [UiKit.GRID, UiKit.GRID * 2, UiKit.GRID * 3]:
			var h := f.get_height(px)
			_ok(absf(h - roundf(h)) < 0.001,
				"%s at %d sits on whole pixels" % [role, px],
				"line height %.3f" % h)


## THE LICENCE TRAVELS. OFL §2 says the copyright notice and licence must ship
## with the font, and the face is a renamed derivative of Press Start 2P because
## §5 forbids a modified version from keeping a Reserved Font Name. A missing
## OFL.txt is a licence breach, not a tidy-up.
func _test_the_licence_travels() -> void:
	_ok(FileAccess.file_exists(UiKit.FACE_DIR + "OFL.txt"),
		"the licence ships beside the font", UiKit.FACE_DIR + "OFL.txt")
	var txt := ""
	var fh := FileAccess.open(UiKit.FACE_DIR + "OFL.txt", FileAccess.READ)
	if fh != null:
		txt = fh.get_as_text()
	_ok(txt.contains("SIL OPEN FONT LICENSE"), "and it is the OFL",
		"%d bytes" % txt.length())
	_ok(not UiKit.FACE_TITLE.to_lower().contains("press"),
		"and the derivative does not carry the reserved name",
		UiKit.FACE_TITLE)
	notes.append("credits screen credits Press Start 2P — Cody Boisclair, SIL OFL 1.1")


## THE CREDIT IS GENERATED, not typed into the screen. Same reasoning as the
## music credits, and the same failure it prevents: a face swapped in `UiKit`
## while the settings screen goes on thanking the old one, which under the OFL
## is not a cosmetic error.
func _test_the_credit_is_generated_not_typed() -> void:
	var c := Settings.face_credit()
	_ok(c == UiKit.FACE_CREDIT, "the screen reads the declaration",
		"Settings.face_credit() is UiKit.FACE_CREDIT")
	for key in ["name", "from", "url", "licence"]:
		_ok(String(c.get(key, "")) != "", "the credit has a %s" % key,
			String(c.get(key, "(missing)")))
	_ok(String(c["from"]).contains("Press Start 2P"),
		"and it names the face it came from", String(c["from"]))
	_ok(String(c["licence"]).contains("Open Font License"),
		"and the licence it came under", String(c["licence"]))
