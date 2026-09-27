extends SceneTree
## THE COUNTER, AND THE THREE WAYS IT COULD COST SOMEBODY MONEY.
##
##   godot --headless --path . --script res://tests/test_store.gd
##
## Nothing in this suite can test Google Play Billing — it is an Android plugin
## that is not in the build. What CAN be tested is everything around it, and
## everything around it is where the expensive mistakes live: a purchase that
## lands in no career, a purchase that a release build mints for free, a wallet
## that a second club erases.
##
## The shape of every check here is "what would this cost a player", not "does
## the function return the right thing".

var failures: Array[String] = []
var checks: int = 0
var notes: Array[String] = []


func _initialize() -> void:
	print("\n=== 8-Bit Buhurt — the counter ===\n")
	## Its own wallet file: this test zeroes and rewrites the wallet.
	Store.wallet_prefix = "test_store_"
	_test_the_shelf_is_a_real_ladder()
	_test_a_purchase_is_not_attached_to_a_save()
	_test_the_wallet_survives_the_app()
	_test_a_release_build_cannot_mint_credits()
	_test_the_shop_says_why_it_is_shut()
	_cleanup()
	print("")
	for n in notes:
		print("   " + n)
	print("")
	if failures.is_empty():
		print("THE COUNTER HOLDS (%d checks)\n" % checks)
		quit(0)
	else:
		for f in failures:
			print("FAIL: " + f)
		print("\n%d FAILED\n" % failures.size())
		quit(1)


func _ok(cond: bool, label: String, detail: String) -> void:
	checks += 1
	print("  %s  %s — %s" % ["pass" if cond else "FAIL", label, detail])
	if not cond:
		failures.append("%s: %s" % [label, detail])


func _cleanup() -> void:
	Store.owed = 0
	Store.save_wallet()
	Store._stub_purchases.clear()


## ---------------------------------------------------------------- the shelf
func _test_the_shelf_is_a_real_ladder() -> void:
	_ok(Store.PRODUCTS.size() >= 3, "there is a shelf",
		"%d packs" % Store.PRODUCTS.size())

	## EVERY STEP IS BETTER VALUE THAN THE ONE ABOVE IT. Direction §8 on Retro
	## Bowl's own ladder: their 250 and 500 tiers are the same unit price —
	## *"a slightly weak ladder worth improving on"*. This is that improvement,
	## checked rather than asserted in a comment.
	var bad: Array[String] = []
	var line: Array[String] = []
	for i in Store.PRODUCTS.size():
		var p: Dictionary = Store.PRODUCTS[i]
		line.append("%d for %s (%.2f¢)" % [int(p["credits"]), String(p["price"]),
			Store.unit_cents(p)])
		if i == 0:
			continue
		var prev: Dictionary = Store.PRODUCTS[i - 1]
		if int(p["credits"]) <= int(prev["credits"]):
			bad.append("%s is not bigger than %s" % [p["id"], prev["id"]])
		if Store.unit_cents(p) >= Store.unit_cents(prev):
			bad.append("%s is not better value than %s" % [p["id"], prev["id"]])
	_ok(bad.is_empty(), "and every step down it is strictly better value",
		"; ".join(line) if bad.is_empty() else "; ".join(bad))

	## THE SMALLEST PACK DOES NOT END THE ECONOMY. A good season pays six to ten
	## credits in prize money; a pack that hands over five seasons at once stops
	## the club being the thing that earns. Held against the prize table itself
	## rather than against a number typed in here.
	## AGAINST THE BACKYARD CHAMPIONS' SHARE, which is the winning season a
	## player has at the point he would first be offered a pack. `CREDITS_BY_POSITION`
	## was a flat table of three and is now a per-division purse, so the figure is
	## asked for rather than indexed — `purse(1, field, 0)` is the same six
	## credits the table's first entry was.
	var season_prize: int = Season.purse(1, League.club_count(0), 0) \
		+ int(Season.CREDITS_PROMOTED)
	var small: int = int(Store.PRODUCTS[0]["credits"])
	_ok(small <= season_prize * 3,
		"and the smallest pack is worth about two good seasons, not ten",
		"%d credits against a winning season's %d" % [small, season_prize])
	notes.append("the shelf: %s" % ", ".join(line))


## -------------------------------------------------- money outlives a career
func _test_a_purchase_is_not_attached_to_a_save() -> void:
	Store.load_wallet()
	Store.owed = 0
	Store.save_wallet()

	## Bought with nothing loaded — the title screen case, which is the one a
	## store that writes into `season.office.credits` loses outright.
	Store.owed = 40
	Store.save_wallet()

	var a := Season.new(MeleeRosters.starting_club(), 11)
	var saved := func() -> bool: return true
	var failed := func() -> bool: return false

	## A CLAIM WHOSE SEASON DID NOT REACH DISK IS UNDONE. The office goes back to
	## what it was and the wallet still holds the money, so a failed save cannot
	## lose a purchase. And a claim with no save at all claims nothing.
	var before0: int = a.office.credits
	var none := Store.claim(a.office, failed)
	var unsaved := Store.claim(a.office)
	_ok(none == 0 and unsaved == 0 and a.office.credits == before0 and Store.owed == 40
		and int(a.office.books_in.get(ClubOffice.LINE_STORE, 0)) == 0,
		"a claim whose season was not saved is undone",
		"office %d -> %d, wallet still owes %d" % [before0, a.office.credits, Store.owed])

	var before: int = a.office.credits
	var moved := Store.claim(a.office, saved)
	_ok(moved == 40 and a.office.credits == before + 40,
		"credits bought with no career land in the next one opened",
		"%d moved, office went %d -> %d" % [moved, before, a.office.credits])

	## AND THEY DO NOT LAND TWICE. A claim empties the wallet; a second club
	## opened afterwards gets nothing, because nothing is owed.
	var b := Season.new(MeleeRosters.starting_club(), 12)
	var second := Store.claim(b.office, saved)
	_ok(second == 0, "and they are not paid out again to the next club",
		"second claim moved %d" % second)

	## AND A CLAIM WITH NOTHING OWED IS NOT AN ERROR — it is the normal case,
	## run every time a career is opened.
	_ok(Store.claim(a.office, saved) == 0 and Store.claim(null, saved) == 0,
		"claiming nothing, or claiming into nothing, is quiet",
		"both return 0 rather than throwing")


func _test_the_wallet_survives_the_app() -> void:
	Store.owed = 0
	Store.save_wallet()
	Store.owed = 25
	Store.save_wallet()
	## The app dies here. `load_wallet()` is what the next launch runs.
	Store.owed = 0
	Store.load_wallet()
	_ok(Store.owed == 25, "a wallet written before the app died is still there",
		"reloaded %d" % Store.owed)

	## AND IT IS NOT IN THE SAVE FILE, which is the whole reason it exists. A
	## save round trip must not carry, restore, or clobber it.
	var s := Season.new(MeleeRosters.starting_club(), 13)
	var d := SaveGame.to_dict(s)
	var carried := JSON.stringify(d).contains("\"owed\"")
	_ok(not carried, "and it is not inside a save file",
		"a save that carried the wallet would duplicate it per slot")
	Store.owed = 0
	Store.save_wallet()


## ------------------------------------------------- the line that must hold
func _test_a_release_build_cannot_mint_credits() -> void:
	## THE STUB GRANTS CREDITS WITH NO PAYMENT. That is what a developer needs
	## and what must never ship, and `OS.is_debug_build()` is the fence — set by
	## the exporter, not by anything in this repo.
	##
	## This suite runs in a debug build, so the fence cannot be crossed from
	## here. What CAN be checked is that both doors ask: `buy` through the stub,
	## and `grant` directly, which is the one an over-helpful future caller would
	## reach for.
	var debug := OS.is_debug_build()
	var src := FileAccess.get_file_as_string("res://scripts/game/store.gd")
	var guards := src.count("OS.is_debug_build()")
	_ok(guards >= 2, "both doors into a free credit ask whether this is a debug build",
		"%d guards in store.gd (need the stub AND the grant)" % guards)

	## AND THE GRANT REFUSES WITHOUT A BACKEND when it is not a debug build.
	## The condition is read out of the source rather than simulated, because a
	## release build cannot be produced inside a debug one — stating that plainly
	## is better than a check that pretends otherwise.
	_ok(src.contains("if not OS.is_debug_build() and _backend() == null:"),
		"and the grant refuses outright with no store behind it",
		"the guard is in `grant`, where money is created")

	if debug:
		## In this build the stub works, which is what makes the flow walkable.
		Store.owed = 0
		Store.save_wallet()
		Store.state = Store.State.READY
		var err := Store.buy("cc_small")
		_ok(err == "" and Store.owed == 20,
			"a debug build can walk the whole purchase without a card",
			"bought cc_small, wallet holds %d" % Store.owed)
		Store.owed = 0
		Store.save_wallet()
		Store._stub_purchases.clear()

	## A PACK THAT DOES NOT EXIST IS REFUSED BY BOTH DOORS. An id typed into a
	## screen is an id that can be typed wrong.
	_ok(Store.buy("cc_enormous") != "" and Store.grant("cc_enormous") != "",
		"a pack that is not on the shelf cannot be bought or granted",
		"both refuse with a sentence")
	notes.append("the fence: %d debug guards, stub %s" % [guards,
		"live" if debug else "dead"])


func _test_the_shop_says_why_it_is_shut() -> void:
	## A SHUT SHOP THAT SAYS NOTHING IS A BUTTON THAT EATS A TAP. Every state
	## has to produce a sentence a player can read.
	var said: Array[String] = []
	var blank: Array[String] = []
	for st in [Store.State.COLD, Store.State.CONNECTING, Store.State.UNAVAILABLE]:
		Store.state = st
		var w := Store.closed_word()
		said.append(w)
		if w.strip_edges() == "":
			blank.append(str(st))
	_ok(blank.is_empty(), "every shut state explains itself",
		"; ".join(said) if blank.is_empty() else "blank for states " + ", ".join(blank))

	Store.state = Store.State.READY
	_ok(Store.closed_word() == "" and Store.available(),
		"and an open one says nothing at all",
		"READY is the only state with no sentence")

	## BUYING WHILE SHUT IS REFUSED WITH THAT SAME SENTENCE, so the screen and
	## the refusal cannot drift apart.
	Store.state = Store.State.UNAVAILABLE
	var err := Store.buy("cc_small")
	_ok(err == Store.closed_word() and err != "",
		"and a tap on a shut shop gets the same words the screen shows",
		"'%s'" % err)
	Store.state = Store.State.COLD
