extends SceneTree
var checks := 0
var failures: Array = []
const COMBAT = preload("res://tools/endgame_combat.gd")
func check(ok: bool, message: String) -> void:
 checks += 1
 if not ok:failures.append(message)
func canonical(s: Season) -> Dictionary:
 for key in s.custom_grade:s.set_custom(String(key),float(s.custom_grade[key]))
 var d := SaveGame.to_dict(s)
 d.erase("saved")
 return d
func make(seed_v: int) -> Season:
 var s := Season.new(MeleeRosters.starting_club_with_reserve(),seed_v)
 s.bid_offers.clear()
 s.world.clubs[0]["tier"] = League.Tier.NATIONAL
 s.office.tier = League.Tier.NATIONAL
 s.office.credits = 1000 # Constructed lifecycle fixture, not career evidence.
 s.world.calendar = [Calendar.week(Calendar.Kind.WORLDS)]
 s.world.week = 0
 s.world.worlds = Cup.new("Worlds",range(16),seed_v,0,true)
 s.world.worlds.set_meta("id","worlds")
 s.world.worlds.set_meta("season",s.world.season)
 s.sync_power()
 return s
func _initialize() -> void:
 Achievements._steam_tried = true
 Achievements._steam = null
 SaveGame.set_namespace("endgame_standalone")
 call_deferred("run")
func tied_rules() -> void:
 for sudden in [false,true]:
  for seed_v in [9001,5150,2718,6060,8123]:
   var c := Cup.new("Worlds",[0,1],seed_v,0)
   c.sudden_death = sudden
   c.tie_powers = {0:78,1:78}
   var loaded := Cup.from_dict(c.to_dict())
   var m := c.player_match()
   var lm := loaded.player_match()
   c.record(m,1,1,2,2)
   loaded.record(lm,1,1,2,2)
   check(m == lm,"Sudden death changed after save")
   if not sudden: check(int(m["winner"]) == 0,"Today's higher-seed rule changed")
 # The real career save retains the rule when the next native cup door primes it.
 for seed_v in [9001,5150,2718,6060,8123]:
  var s := make(seed_v)
  s.world.knockout_sudden_death = true
  var saved := canonical(s)
  var clone := SaveGame.from_dict(saved)
  check(clone.world.knockout_sudden_death,"Career reload lost chosen tie rule")
  var first := s.begin_cup_bout()
  var second := clone.begin_cup_bout()
  check(first != null and second != null,"Rule reload could not open native bout")
  check(s.world.worlds.sudden_death and clone.world.worlds.sudden_death,"Native cup door overrode saved rule")
  COMBAT._play(first,"auto")
  COMBAT._play(second,"auto")
  check(first.rounds_won==second.rounds_won and first.margin==second.margin and first.bout_winner()==second.bout_winner(),"Saved-rule native bout diverged")
  s.post_cup_bout(first)
  clone.post_cup_bout(second)
  check(canonical(s)==canonical(clone),"Saved-rule native rewards diverged")
 # Real engine's actual round-end branch: exactly tied, one extra decisive round.
 var sim := MeleeSim.new(MeleeRosters.player_club(),MeleeRosters.rival_club(),9001)
 sim.knockout_sudden_death = true
 sim.round_no = 3
 sim.rounds_won = [1,1]
 sim.margin = [2,2]
 sim.round_downs = [0,0]
 sim.round_t = Tuning.ROUND_TIME
 sim._check_round_end()
 check(sim.phase == MeleeSim.Phase.CORNER and sim.overtime_rounds == 1,"Real tied bout did not enter overtime")
 sim.leave_corner()
 COMBAT._play(sim,"auto")
 check(sim.is_over() and sim.overtime_winner in [0,1],"Real overtime did not decide")
 # Pathological no-action overtime is explicitly a neutral toss, not a seed win.
 var stalled := MeleeSim.new(MeleeRosters.player_club(),MeleeRosters.rival_club(),5150)
 stalled.knockout_sudden_death = true
 stalled.round_no = 19
 stalled.rounds_won = [1,1]
 stalled.margin = [2,2]
 stalled.overtime_rounds = MeleeSim.OVERTIME_CAP
 stalled.round_downs = [0,0]
 stalled.round_t = Tuning.ROUND_TIME
 stalled._check_round_end()
 check(stalled.is_over() and stalled.overtime_toss,"Pathological tie fallback not explicit")
func graded_sudden() -> void:
 var found := 0
 for seed_v in range(210001,210301):
  var s := make(seed_v)
  s.world.calendar = [Calendar.week(Calendar.Kind.WORLDS)]
  s.world.week = 0
  s.world.worlds = Cup.new("Worlds",[0,1],seed_v,0)
  s.world.worlds.set_meta("id","worlds")
  s.world.knockout_sudden_death = true
  s.set_grade(Grade.G.FRIENDLY)
  s.world.clubs[1]["power"] = 78
  var c := s.world.worlds
  var m := c.player_match()
  var expected_a: int = s.world.clubs[0]["power"]
  var expected_b := int(round(78.0*s.opposition_scale(1)))
  s.sim_cup_tie()
  if m.has("sudden_death"):
   found += 1
   check(m["sudden_death"]["powers"]==[expected_a,expected_b],"Quick overtime lost graded bout powers")
   if found>=3:break
 check(found>=3,"Graded fixture found too few actual exact ties")
func run() -> void:
 tied_rules()
 graded_sudden()
 # THE DEFAULT (Pete, 11 Oct 2026: "Sudden death"): a new world plays it.
 check(LeagueWorld.new().knockout_sudden_death, "Sudden death is not the default")
 print("  %s  sudden death settles tied knockout bouts, %d checks — %s" % [
  "pass" if failures.is_empty() else "FAIL", checks, "all hold" if failures.is_empty() else ", ".join(failures.slice(0, 6))])
 if failures.is_empty():
  print("\nSUDDEN DEATH HOLDS (%d checks)\n" % checks)
  quit(0)
 else:
  print("\nFAIL: sudden death\n\n1 FAILED\n")
  quit(1)
