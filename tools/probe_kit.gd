extends SceneTree
## THE ONE CLUB IN THE COUNTRY WHOSE KIT WEARS OUT.
##
##   godot --headless --path . --script res://tools/probe_kit.gd
##
## `armor` multiplies a man's base between 0.78 and 1.0 and gates inspection at
## 0.35, and it decays every event off the captain's regime. The question nothing
## had ever asked is whether anybody ELSE decays — and the answer is structural:
## an AI club is a `power` INTEGER drawn from its tier's band
## (`league_world.gd`), not a squad of men. It has no kit, cannot wear it out,
## and cannot repair it.
##
## So the player is the only club on the ladder paying a tax that every opponent
## is exempt from, and paying it invisibly: there is no screen in the game that
## shows the squad's kit together, and the only repair is one man at a time,
## buried on the fighter card.
##
## This measures the size of the tax. Pete, item 15 of the 15 Sep playtest:
## *"Immediately feel outgunned by everyone in Backyard Circuit."*
func _initialize() -> void:
	for label in ["left alone", "repaired every event"]:
		var s := Season.new(MeleeRosters.starting_club(), 4242)
		s.office.credits = 3000
		print("\n--- %s ---" % label)
		print("  start: kit %.2f  power %d" % [_mean(s), s.club.power()])
		for ev in 24:
			if label != "left alone":
				for f in s.club.roster:
					s.office.repair_kit(f)
			s.skip_event()
			s.sync_power()
			if ev % 6 == 5:
				print("  after %2d events: kit %.2f  power %d  unfit %d"
					% [ev + 1, _mean(s), s.club.power(), _unfit(s)])
	quit(0)

func _mean(s: Season) -> float:
	var t := 0.0
	for f in s.club.roster:
		t += f.armor
	return 0.0 if s.club.roster.is_empty() else t / float(s.club.roster.size())

func _unfit(s: Season) -> int:
	var n := 0
	for f in s.club.roster:
		if not f.passes_inspection():
			n += 1
	return n
