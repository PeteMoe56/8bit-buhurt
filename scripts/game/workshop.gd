class_name Workshop
extends RefCounted
## CREATE-A-PLAYER and CREATE-A-TEAM.
##
## Pete, 10 Sep 2026: *"We'll have a Create-A-Player, Create-A-Team, and
## 'Chalkboard' to create formations and plays. You'll have to use credits to
## unlock up to 4 of each."*
##
## THE ROSTER IS THE TOP RUNG OF THE LADDER, which is exactly why this screen is
## the one that needs a governor. Roster beats thumb beats tactics: a player who
## can write his own fighters can write himself past everything the rest of the
## game is balanced around, and he would, because the screen invites it.
##
## So a created fighter is capped TWICE, and neither cap is a soft one:
##
##   RATING   he cannot rate above the top of your own division plus a little.
##            A created man is a good signing, not a different sport.
##   STAT     no single number may run far past that either, so the cap cannot be
##            dodged by building a 99-strength man who rates low on paper and
##            then bullrushes the whole league.
##
## And the salary cap still bites afterwards, because a created fighter draws a
## wage off his overall like everybody else. Creating him is one decision;
## affording him is the next one.
##
## CREATING IS THE PURCHASE. There is no unlock-then-fill: the credits buy the
## man. Four per club, ever, at a rising price — the fourth is a real decision
## rather than a formality, same as the Chalkboard's fourth slot.

const MAX_FIGHTERS: int = 4
const FIGHTER_COST := [3, 5, 7, 9]
## How far past your division's ceiling a made man may go. Small on purpose.
const RATING_HEADROOM: int = 6
## And how far past it any ONE number may go, which is what stops a lopsided
## build from smuggling an out-of-division stat past a rating cap.
const STAT_HEADROOM: int = 22

var made: int = 0

## THE ICON BANK'S LEDGER, and it is per SAVE FILE — Pete, 10 Sep 2026: *"Yes, 1
## Create-A-Team for each save file."* One club, one set of colors, one growing
## collection of marks, and a new save starts the collection again. Stored as ids
## rather than as indices into the bank, so an asset pack inserted anywhere does
## not repaint every club that ever bought a mark.
var owned: Array[int] = []


func _init() -> void:
	for id in IconBank.starter():
		owned.append(int(id))


## The mark a club is wearing when he arrives is his: the Saltire every career
## starts in costs 1 CC, and a new job inherits whatever the club wore.
func keep_worn(club: MeleeClub) -> void:
	if not owned.has(int(club.icon)):
		owned.append(int(club.icon))


func owns(id: int) -> bool:
	return IconBank.is_free(id) or owned.has(id)


## Buy a mark. The bank is the only thing that knows what it costs, so the price
## is asked rather than passed in — a caller that could name its own price is a
## caller that will eventually name the wrong one.
func buy_icon(office: ClubOffice, id: int) -> String:
	if owns(id):
		return UiKit.t("You already have the %s.") % IconBank.icon_name(id)
	var price := IconBank.cost(id)
	if office.credits < price:
		return UiKit.t("The %s costs %d CC and you have %d.") % [
			IconBank.icon_name(id), price, office.credits]
	office.spend(price, ClubOffice.LINE_CLUB)
	owned.append(id)
	return ""


## `wearable()` used to be here — the marks the club owns, in bank order — and
## it never had a caller because the screen that would have used it went the
## other way. The Create screen draws the WHOLE bank as a shelf, with the marks
## you do not own dimmed and priced, on the principle that **you cannot want a
## thing you cannot see**. A filtered list is the wrong answer to that screen's
## question, so it is gone rather than kept for a caller that would be a
## regression. Deleted 15 Sep 2026; `owns()` is what the shelf asks per mark.


func cost() -> int:
	return FIGHTER_COST[made] if made < MAX_FIGHTERS else 0


func left() -> int:
	return MAX_FIGHTERS - made


## The ceiling your division puts on a man you write yourself.
static func limits(tier: int) -> Dictionary:
	var t := clampi(tier, 0, League.TIERS.size() - 1)
	var band: Array = League.TIERS[t]["power"]
	var top := int(band[1])
	return {
		"rating": top + RATING_HEADROOM,
		"stat": mini(99, top + STAT_HEADROOM),
		"tier": String(League.TIERS[t]["name"]),
	}


## Everything wrong with a written fighter, in the order a player would fix it.
static func fighter_legal(card: FighterCard, tier: int) -> String:
	var lim := limits(tier)
	if card.display_name.strip_edges() == "":
		return UiKit.t("Give him a name.")
	## KEYED BY THE DISPLAYED NAME (3 Oct 2026): the keys are printed below, so
	## they go through the translator — German read "Strength 9 is over…".
	var stats := {
		UiKit.t("Strength"): card.strength, UiKit.t("Base"): card.base,
		UiKit.t("Skill"): card.skill, UiKit.t("Gas"): card.gas,
		UiKit.t("Aggression"): card.aggression,
	}
	for k in stats:
		if int(stats[k]) > int(lim["stat"]):
			return UiKit.t("%s %d is over what the %s allows a new man (%d).") % [
				k, int(stats[k]), UiKit.t(String(lim["tier"])), int(lim["stat"])]
	if card.rating() > float(lim["rating"]):
		return UiKit.t("He rates %d; the %s caps a made man at %d.") % [
			card.overall(), UiKit.t(String(lim["tier"])), int(lim["rating"])]
	return ""


## A blank to start editing from: an ordinary man, not a maximum one. Opening on
## the ceiling would make every created fighter identical.
static func blank(no: int = 0) -> FighterCard:
	var f := FighterCard.new()
	f.display_name = ""
	f.number = no
	f.pos = Tuning.Pos.CENTER
	f.strength = 40
	f.base = 40
	f.skill = 40
	f.gas = 40
	f.aggression = 40
	f.weight = 203
	f.armor = 1.0
	f.active = false
	return f


## Sign a written fighter. He goes onto the RESERVE, not the line — a made man
## takes the same walk onto the eight as a signed one, through the squad screen,
## so the depth chart still means something.
## A CLUB STARTS FULL. Thirteen men is the roster rule and the club you begin
## with already carries thirteen, so "write a fighter" is never an addition — it
## is always a replacement, and pretending otherwise would have shipped a
## feature that refuses itself on the first tap.
##
## So the man he replaces is part of the decision and is passed in with him.
## `replace` may be null only while the books have room.
func create(office: ClubOffice, club: MeleeClub, card: FighterCard,
		replace: FighterCard = null) -> String:
	if made >= MAX_FIGHTERS:
		return UiKit.t("You have written all %d men this club will ever get.") % MAX_FIGHTERS
	var bad := fighter_legal(card, office.tier)
	if bad != "":
		return bad
	## A CREATED MAN IS A SIGNING, so he goes on a deal like anybody else. Before
	## contracts existed this did not need saying; afterwards, a card built by
	## hand carried `wage_agreed` of zero, `ClubOffice.billed()` fell back to his
	## market rate, and he was the only fighter in the game whose wage moved every
	## time he improved. He also carried a default ceiling of 70, which on a man
	## written at 60 is fine and on one written at 74 means he arrives already
	## finished — so the ceiling is drawn from his age the same way the generator
	## draws everybody else's.
	##
	## Done before the cap is checked, deliberately: the figure the refusal quotes
	## has to be the figure he will actually be billed at.
	if card.potential < card.overall():
		card.potential = clampi(card.overall()
			+ Career.potential_room(card.age) / 2, 1, Career.POTENTIAL_CEILING)
	card.years = Contracts.YEARS_NEW
	card.wage_agreed = Contracts.offer(ClubOffice.wage(card), card.age)
	var price := cost()
	if office.credits < price:
		return UiKit.t("That costs %d CC and you have %d.") % [price, office.credits]
	if replace == null and club.roster.size() >= MeleeClub.SQUAD_MAX:
		return UiKit.t("The books are full at %d. Pick who he replaces.") % MeleeClub.SQUAD_MAX
	## Everything is checked BEFORE anybody is cut. A half-applied create that
	## released a man and then refused to sign his replacement would be the
	## worst bug this screen could have.
	if replace != null:
		if not club.roster.has(replace):
			return UiKit.t("%s is not on this club's books.") % replace.display_name
		if replace.active:
			return UiKit.t("%s is on the eight. Move him to the reserve first.") % replace.display_name
	## The wage he will draw is checked before he is signed rather than after,
	## because a club that is over the cap the moment a man walks in has been
	## handed a problem by a button that said nothing.
	var bill := ClubOffice.wage_bill(club) + ClubOffice.billed(card)
	if replace != null:
		bill -= ClubOffice.billed(replace)
	if bill > office.cap():
		return UiKit.t("He would take the bill to %s against a %s cap.") % [
			ClubOffice.money(bill), ClubOffice.money(office.cap())]
	if replace != null:
		var err := club.cut(replace)
		if err != "":
			return err
	card.active = false
	card.available = true
	card.injury = 0
	card.number = _free_number(club)
	club.roster.append(card)
	office.spend(price, ClubOffice.LINE_SQUAD)
	made += 1
	return ""


static func _free_number(club: MeleeClub) -> int:
	var taken := {}
	for f in club.roster:
		taken[f.number] = true
	for n in range(1, 100):
		if not taken.has(n):
			return n
	return 99


# ------------------------------------------------------------- create-a-team
## YOUR CLUB'S IDENTITY, and it is free and always editable, because it is your
## club. The credits govern how many FIGHTERS you may write, not what your own
## colors are.
##
## The contrast rule is the only thing standing between the player and a black
## mark on a black kit. It already exists — IconBank measures it and MeleeClub
## enforces it on every club in the world — so it is asked, not reimplemented,
## and it is a measurement rather than a taxonomy so it stays right when a pack
## adds a color.
static func identity_legal(nm: String, short: String, kit: Color, icon_col: Color) -> String:
	if nm.strip_edges().length() < 3:
		return UiKit.t("A club needs a name.")
	if short.strip_edges().length() < 2 or short.strip_edges().length() > 4:
		return UiKit.t("The short name is two to four letters.")
	if not IconBank.contrast_ok(kit, icon_col):
		return UiKit.t("That mark will not read on that kit. Take one light and one dark.")
	return ""


## NOT static any more: a club cannot wear a mark this save has not bought, and
## only an instance knows what it owns. That check has to live down here rather
## than on the screen, because the screen is not the only thing that can set a
## club's identity and a rule enforced at one call site is a rule with a hole.
func rename(club: MeleeClub, nm: String, short: String,
		kit: Color, icon_col: Color, mark: int) -> String:
	var bad := identity_legal(nm, short, kit, icon_col)
	if bad != "":
		return bad
	## THE MARK ON THE SHIRT ALREADY IS HIS. Every new career starts in the
	## Saltire, which is a 1 CC mark, and a new job inherits whatever the club
	## wore — so renaming the club without touching the badge was refused until
	## he bought the mark he was already wearing. Found by tests/test_flows.gd.
	if not owns(mark) and mark != club.icon:
		return UiKit.t("You do not own the %s yet.") % IconBank.icon_name(mark)
	club.display_name = nm.strip_edges()
	club.short_name = short.strip_edges().to_upper()
	club.kit = kit
	club.icon_color = icon_col
	club.icon = mark
	return ""


# -------------------------------------------------------------------- saving
func to_dict() -> Dictionary:
	return {"made": made, "owned": owned.duplicate()}


static func from_dict(d: Dictionary) -> Workshop:
	var w := Workshop.new()
	w.made = int(d.get("made", 0))
	for id in d.get("owned", []):
		if not w.owned.has(int(id)):
			w.owned.append(int(id))
	## The starter set is free forever, including in a save written before an
	## icon was moved into it. `_init` already put it there; this only guards
	## against a save that somehow carries fewer.
	for id in IconBank.starter():
		if not w.owned.has(int(id)):
			w.owned.append(int(id))
	return w
