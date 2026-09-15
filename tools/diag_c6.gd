extends SceneTree
## The C-6 landscape: every formation-and-strategy pairing, hands off, as a
## matrix. The suite finds its own hole now (see tests/test_c6.gd) and no longer
## needs a number from here — this is for LOOKING at the board, not for feeding
## the test.
##
## N IS AN ARGUMENT AND IS PRINTED IN THE HEADER, because the last version of
## this tool measured at 14 bouts, handed the suite a pairing it had read at 36%,
## and the suite measured the same pairing at 50%. A tool whose sample size is
## invisible will eventually be quoted as though it were the suite.
##
##   godot --headless --path . --script res://tools/diag_c6.gd -- [bouts]

const TSC := preload("res://tests/test_c6.gd")

var n := 8


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		n = int(args[0])
	var t := TSC.new()
	var setups: Array = []
	for f in Tuning.FORMATIONS.keys():
		for st in Tuning.STRATEGIES.keys():
			setups.append([int(f), int(st)])

	print("\nC-6 LANDSCAPE — player's win rate, hands off, at %d bouts a cell" % n)
	print("(the suite measures at %d; do not quote these two numbers as one)\n" % TSC.N)
	var head := "%-26s" % "us \\ them"
	for them in setups:
		head += "%10s" % _short(them)
	print(head)

	var best := {"rate": -1.0}
	var worst := {"rate": 101.0}
	for us in setups:
		var row := "%-26s" % _name(us)
		for them in setups:
			if us[0] == them[0] and us[1] == them[1]:
				row += "%10s" % "—"
				continue
			var r: float = t._winrate(n, "auto", us[0], us[1], them[0], them[1], 0, TSC.SEED_BASE)
			row += "%9.0f%%" % r
			if r > best["rate"]:
				best = {"rate": r, "us": us, "them": them}
			if r < worst["rate"]:
				worst = {"rate": r, "us": us, "them": them}
		print(row)

	print("\nbest for the player:  %s against %s   %.0f%%" % [
		_name(best["us"]), _name(best["them"]), best["rate"]])
	print("worst for the player: %s against %s   %.0f%%" % [
		_name(worst["us"]), _name(worst["them"]), worst["rate"]])
	print("")
	quit(0)


func _name(s: Array) -> String:
	return "%s / %s" % [Tuning.FORMATIONS[s[0]]["name"], Tuning.STRATEGIES[s[1]]["name"]]


func _short(s: Array) -> String:
	return "%s/%s" % [String(Tuning.FORMATIONS[s[0]]["name"]).substr(0, 4),
		String(Tuning.STRATEGIES[s[1]]["name"]).substr(0, 4)]
