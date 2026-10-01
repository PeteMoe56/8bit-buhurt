extends SceneTree
## WHY A MANAGER WHO RE-SIGNS EVERYBODY STILL LOSES HIS SQUAD.
##
## `probe_climb.gd`'s keeper extends or re-signs every man on the books every
## winter and his club still drains from thirteen to six and from 37 to 19. That
## can only be true if the re-signings are failing, and the probe threw away
## every return string — the same mistake that made the spending column identical
## to the walking one two probes ago. **An error you do not read is an error that
## did not happen.**
func _initialize() -> void:
	var s := Season.new(MeleeRosters.starting_club(), 90210)
	Session.season = s
	var why := {}
	for year in 10:
		var guard := 0
		while not s.season_complete() and guard < 40:
			guard += 1
			var q := 0
			while q < 8 and s.blocked_by() != "":
				q += 1
				match s.blocked_by():
					"bid": s.decline_bid()
					"sendoff": s.answer_send_off()
					"dilemma": s.answer_dilemma(s.dilemma_card()["options"].size() - 1)
					"cup": s.sim_cup_tie()
			s.skip_event()
		s.office.credits += 120
		var tried := 0
		var won := 0
		for f in s.club.roster:
			var err := ""
			## EXTEND IF HE CAN BE EXTENDED, RE-SIGN OTHERWISE — and "otherwise"
			## includes a man in the LAST YEAR of his deal, which the first cut of
			## this probe skipped. `can_extend` is false for him and his `years`
			## is still 1, so he fell down the gap between the two branches, ran
			## out at the summer, and walked the year after. The keeper was not
			## keeping anybody; he was watching.
			if Contracts.can_extend(f):
				err = s.extend(f)
			else:
				err = s.resign(f)
			tried += 1
			if err == "":
				won += 1
			else:
				## Keyed on the shape of the refusal, not the man's name.
				var key := err.replace(f.display_name, "<man>")
				why[key] = int(why.get(key, 0)) + 1
		print("S%d squad=%d power=%d  cap=%d bill=%d credits=%d  tried=%d kept=%d"
			% [s.world.season, s.club.roster.size(), s.club.power(),
				s.office.cap(), ClubOffice.wage_bill(s.club), s.office.credits,
				tried, won])
		s.roll_over()
	print("")
	for k in why:
		print("  x%d  %s" % [int(why[k]), k])
	quit()
