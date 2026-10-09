from pathlib import Path
import subprocess, sys

MAIN=Path('C:/Dev/RetroBuhurt')
ROOT=Path('C:/Users/PeterM/Documents/Codex/work/harness-2-r2')
NAMES=['control','sponsor','turnout','gas','reuse','resale']

def edit(root, name, old, new):
    p=root/name
    s=p.read_text(encoding='utf-8')
    assert s.count(old)==1, (name,old,s.count(old))
    p.write_text(s.replace(old,new),encoding='utf-8',newline='\n')

for name in NAMES:
    root=ROOT/name
    assert not root.exists(), root
    subprocess.run(['git','worktree','add','--detach',str(root),'7c79a7f'],cwd=MAIN,check=True)
    subprocess.run(['git','apply',str(MAIN/'docs/harness-2/codex/value.patch')],cwd=root,check=True)
    if name=='sponsor':
        edit(root,'scripts/league/club_office.gd','var credits: int = 8','var credits: int = 8\n## Fractional earned kit sponsorship; paid only after an actual appearance.\nvar harness_receipts: float = 0.0')
        edit(root,'scripts/league/club_office.gd','"credits": credits, "cap_level": cap_level','"harness_receipts": harness_receipts,\n\t\t"credits": credits, "cap_level": cap_level')
        edit(root,'scripts/league/club_office.gd','o.credits = int(d.get("credits", 0))','o.credits = int(d.get("credits", 0))\n\to.harness_receipts = clampf(float(d.get("harness_receipts", 0.0)), 0.0, .999999999)')
        edit(root,'scripts/league/season_bouts.gd','\t\tbout_wear(s)','\t\tQuartermaster.appearance(s.office, s.club.starting_five())\n\t\tbout_wear(s)')
        edit(root,'scripts/league/season_cups.gd','static func _finish_cup_round(s: Season, c: Cup, won: bool, drew: bool = false) -> void:', 'static func _finish_cup_round(s: Season, c: Cup, won: bool, drew: bool = false, played: bool = true) -> void:\n\tif played:\n\t\tQuartermaster.appearance(s.office, s.club.starting_five())')
        edit(root,'scripts/league/season_cups.gd','s._finish_cup_round(c, false)','_finish_cup_round(s, c, false, false, false)')
        with (root/'scripts/league/quartermaster.gd').open('a',encoding='utf-8') as f:
            f.write('''

## Experiment: a sponsor pays for maintained equipment actually appearing.
const APPEARANCE_CC := [0.0, .08, .20, .40, .65]
static func appearance(o: ClubOffice, line: Array) -> void:
	for f in line:
		o.harness_receipts += float(APPEARANCE_CC[grade_of(f)]) * clampf(f.armor, 0.0, 1.0)
	var paid := int(floor(o.harness_receipts + 0.000000001))
	o.harness_receipts = maxf(0.0, o.harness_receipts - float(paid))
	if paid > 0:
		o.take(paid, "Maintained kit sponsorship", "event", "Harness sponsorship")
''')
    if name=='turnout':
        edit(root,'scripts/league/office_crowd.gd','static func set_draws(o: ClubOffice, eight: Array) -> void:', 'const HARNESS_DRAW := [0.0, .01, .025, .04, .06]\n\nstatic func set_draws(o: ClubOffice, eight: Array) -> void:')
        edit(root,'scripts/league/office_crowd.gd','var d := FighterTrait.mod(f.trait_id, "turnout", 0.0)', 'var d := FighterTrait.mod(f.trait_id, "turnout", 0.0)\n\t\td += float(HARNESS_DRAW[Quartermaster.grade_of(f)]) * clampf(f.armor, 0.0, 1.0)')
    if name=='gas':
        edit(root,'scripts/melee/fighter_card.gd','return clampi(gas + (CHIP_GAS if toxic() else 0), 1, 99)','return clampi(int(round(effective_gas())) + (CHIP_GAS if toxic() else 0), 1, 99)')
        edit(root,'scripts/melee/fighter_card.gd','+ float(gas) * 0.22 + float(aggression) * 0.08\n\n\n## The size', '+ effective_gas() * 0.22 + float(aggression) * 0.08\n\n\n## The size')
        edit(root,'scripts/melee/fighter_card.gd','func effective_base() -> float:', '''const HARNESS_GAS_BONUS := [0.0, .01, .03, .05, .07]

func effective_gas() -> float:
	return minf(99.0, float(gas) * (1.0 + float(HARNESS_GAS_BONUS[Quartermaster.grade_of(self)]) * clampf(armor, 0.0, 1.0)))


func effective_base() -> float:''')
    if name in ('reuse','resale'):
        helper='Quartermaster.hand_down(f, s.club)' if name=='reuse' else 'Quartermaster.dispose_harness(s.office, f)'
        edit(root,'scripts/league/season_desk.gd','\t## A man let go is nobody\'s prospect:', '\t'+helper+'\n'+ ('\tpaid = s.trade_value(f)\n' if name=='reuse' else '')+'\t## A man let go is nobody\'s prospect:')
        edit(root,'scripts/league/season_winter.gd','\t\t\tretired.append("%s (%d)" % [f.display_name, f.age])\n\t\t\ts.club.roster.erase(f)', '\t\t\tretired.append("%s (%d)" % [f.display_name, f.age])\n\t\t\t'+helper+'\n\t\t\ts.club.roster.erase(f)')
        edit(root,'scripts/league/season_winter.gd','\t\t\twalked.append("%s (%d)" % [f.display_name, f.overall()])\n\t\t\ts.club.roster.erase(f)', '\t\t\twalked.append("%s (%d)" % [f.display_name, f.overall()])\n\t\t\t'+helper+'\n\t\t\ts.club.roster.erase(f)')
        with (root/'scripts/league/quartermaster.gd').open('a',encoding='utf-8') as f:
            if name=='reuse':
                f.write('''

## Experiment: the club retains a departing man's equipment, without refilling it.
static func hand_down(leaver: FighterCard, club: MeleeClub) -> void:
	if grade_of(leaver) == Grade.BORROWED or leaver.armor < .40:
		return
	var candidates: Array[FighterCard] = []
	for other in club.roster:
		if other != leaver and other.age <= 30 and grade_of(other) < grade_of(leaver):
			candidates.append(other)
	candidates.sort_custom(func(a, b):
		if a.active != b.active: return a.active
		if grade_of(a) != grade_of(b): return grade_of(a) < grade_of(b)
		return a.age < b.age)
	if candidates.is_empty(): return
	var recipient := candidates[0]
	var old_grade := recipient.harness
	var old_condition := recipient.armor
	recipient.harness = leaver.harness
	recipient.armor = leaver.armor
	leaver.harness = old_grade
	leaver.armor = old_condition
''')
            else:
                f.write('''

const RESALE_FRACTION: float = .50
static func salvage_value(card: FighterCard) -> int:
	var paid := 0
	for g in range(1, grade_of(card) + 1): paid += int(COST[g])
	return int(floor(RESALE_FRACTION * clampf(card.armor, 0.0, 1.0) * float(paid)))

## Experiment: a departing man's kit is sold once, separately from the fighter.
static func dispose_harness(o: ClubOffice, card: FighterCard) -> void:
	var paid := salvage_value(card)
	card.harness = Grade.BORROWED
	card.armor = minf(card.armor, float(TOP[Grade.BORROWED]))
	if paid > 0: o.take(paid, "Used harness sold", "season", "Harness resale")
''')
    diff=subprocess.run(['git','diff','--','scripts/'],cwd=root,check=True,capture_output=True).stdout
    (MAIN/f'docs/harness-2/codex/r2-{name}.patch').write_bytes(diff)
    subprocess.run(['git','diff','--check'],cwd=root,check=True)
    print(name, len(diff),flush=True)
