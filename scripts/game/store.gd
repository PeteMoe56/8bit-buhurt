class_name Store
## THE COUNTER. Coaching credits, bought with money.
##
## Direction §8, superseded by Pete on 12 Sep 2026: *"It can be priced the same.
## $4.99. In app purchase for CC and whatever else is for sale."* So the game is
## **premium at $4.99** and the only thing sold inside it is credits. There is no
## unlock product and there never will be — nothing is locked, because the price
## of entry already happened.
##
## ---------------------------------------------------------------------------
## THREE THINGS THIS FILE IS CAREFUL ABOUT, in the order they will bite.
##
## 1. **A PURCHASE IS NOT ATTACHED TO A SAVE SLOT.** Money arrives from the
##    store, not from a career. A player can buy credits on the title screen with
##    nothing loaded, or buy them in slot 1 and then play slot 2, and a store that
##    writes straight into `season.office.credits` loses the purchase in both
##    cases. So bought credits land in a WALLET that lives outside every save
##    (`user://wallet.dat`) and are claimed into whichever career is open. A
##    purchase can never be lost by loading a different game.
##
## 2. **A PURCHASE CAN SURVIVE THE APP.** The store acknowledges a purchase and
##    then the phone is killed, or the network drops between the charge and the
##    grant. Play re-delivers unacknowledged purchases on the next connect, which
##    is the whole reason `Store.connect_backend()` runs at start-up rather than
##    when somebody opens the shop. The wallet is written before anything is
##    acknowledged, in that order, because the failure that matters is charging
##    somebody and not crediting them.
##
## 3. **A DEBUG BUILD MUST NOT BE ABLE TO MINT MONEY IN A RELEASE ONE.** The stub
##    backend below grants credits with no payment, which is exactly what a
##    developer needs and exactly what must never ship. `available()` is false
##    in a release build with no real backend, and `_grant` refuses outright.
##    `test_store.gd` holds that line.
## ---------------------------------------------------------------------------
##
## WHAT IS NOT HERE, and is not pretending to be: Google Play Billing itself.
## That is an Android plugin — a `.aar` in `android/plugins/`, a gradle build,
## and an Android build template — none of which can be built in this loop. The
## seam is `_backend()`: it looks for the plugin's singleton and uses it if it is
## there. Until it is, the shop says *"not available on this device"* rather than
## taking a tap and doing nothing, which is the honest failure.
##
## See `docs/EXPORTING.md`.

## ------------------------------------------------------------------ products
## CONSUMABLE, every one of them. Credits are spent, so a player buys the same
## pack twice, which is a different product type from an unlock and a different
## restore story — see `resolve_pending()`.
##
## SIZED AGAINST OUR ECONOMY, not against Retro Bowl's. A good season pays 6-10
## credits in prize money, a cap raise is 4 to 12, a night out is 4. Their packs
## start at fifty, which in this game would buy five seasons of everything at
## once and end the economy. Twenty is about two seasons of prize money: enough
## to feel like a decision and not enough to stop the club being the thing that
## earns.
##
## AND THE LADDER IMPROVES ALL THE WAY DOWN. Direction §8 notes their 250 and 500
## tiers are the same unit price — *"a slightly weak ladder worth improving on"*.
## Every step here is strictly cheaper per credit than the one above it, and
## `test_store.gd` checks that rather than trusting this comment.
const PRODUCTS: Array[Dictionary] = [
	{"id": "cc_small",  "credits": 20,  "price": "$1.99", "cents": 199},
	{"id": "cc_medium", "credits": 55,  "price": "$3.99", "cents": 399},
	{"id": "cc_large",  "credits": 150, "price": "$7.99", "cents": 799},
]

## The Android plugin's singleton name. Absent until the plugin is in the build.
const BILLING_SINGLETON := "GodotGooglePlayBilling"

const WALLET_PATH := "user://%swallet.dat"
## Tests set this so they never touch a developer's real wallet (same idea as
## SaveGame.set_namespace). Empty in the game.
static var wallet_prefix: String = ""


static func wallet_path() -> String:
	## Under the test runner (which exports RB_TIER) every file gets a test wallet
	## even if it forgot to ask for one.
	if wallet_prefix == "" and OS.get_environment("RB_TIER") != "":
		return WALLET_PATH % "test_"
	return WALLET_PATH % wallet_prefix
## Bumped if the wallet's shape ever changes. It is one integer today.
const WALLET_VERSION: int = 1


enum State { COLD, CONNECTING, READY, UNAVAILABLE }

static var state: int = State.COLD
## Credits bought and not yet handed to a career. The only number that matters.
static var owed: int = 0
## What went wrong last, in the club's own words, for a screen to print.
static var last_error: String = ""
## Set by `_stub_buy` only, and only in a debug build. Read by the tests.
static var _stub_purchases: Array[String] = []


## ------------------------------------------------------------------- the shop
## IS THERE A COUNTER TO STAND AT? False on desktop, false on a phone without
## the billing plugin, false before `connect_backend()` has run.
##
## DESKTOP IS DELIBERATE AND IS AN OPEN QUESTION, not an oversight. Direction §8:
## *"Steam does not do IAP the way the stores do. A $4.99 Steam build selling
## coaching credits is a different conversation... This one needs a decision."*
## Until that decision exists, the desktop build sells nothing and says so, which
## is the only answer that cannot be wrong.
static func available() -> bool:
	return state == State.READY


## Why the shop is shut, for a player rather than for a log.
static func closed_word() -> String:
	match state:
		State.COLD:
			return UiKit.t("The shop has not opened yet.")
		State.CONNECTING:
			return UiKit.t("Reaching the store…")
		State.READY:
			return ""
		_:
			if OS.get_name() in ["Windows", "macOS", "Linux"]:
				return UiKit.t("Credits are earned on this version, not bought.")
			return UiKit.t("The store is not available on this device.")


static func product(id: String) -> Dictionary:
	for p in PRODUCTS:
		if String(p["id"]) == id:
			return p
	return {}


## Credits per cent, for ordering the shelf. Smaller is better value.
static func unit_cents(p: Dictionary) -> float:
	var n := int(p.get("credits", 0))
	return 0.0 if n <= 0 else float(p.get("cents", 0)) / float(n)


## ---------------------------------------------------------------- the backend
## The billing plugin, or null. One place asks, so one place has to change when
## a second platform arrives.
static func _backend():
	if Engine.has_singleton(BILLING_SINGLETON):
		return Engine.get_singleton(BILLING_SINGLETON)
	return null


## CALLED AT START-UP, not when the shop is opened.
##
## Play re-delivers purchases that were never acknowledged — the charge that
## landed while the phone was in a tunnel — and it delivers them on connect. A
## store that only connects when somebody browses is a store that loses those
## until somebody happens to browse.
static func connect_backend() -> void:
	load_wallet()
	if state == State.CONNECTING:
		return
	var b = _backend()
	if b == null:
		## No plugin. In a debug build that is a stub worth having; in a release
		## build it is a shop that must stay shut.
		state = State.READY if _debug() and _sellable_here() else State.UNAVAILABLE
		return
	state = State.CONNECTING
	## The plugin's own handshake. Left as the one line it is, because anything
	## more elaborate here would be invented rather than tested.
	if b.has_method("startConnection"):
		b.startConnection()
	state = State.READY


## Is this a platform we have decided to sell on at all?
static func _sellable_here() -> bool:
	return OS.get_name() in ["Android", "iOS"]


## ------------------------------------------------------------------ the wallet
## OUTSIDE EVERY SAVE, on purpose — see the note at the top. A wallet inside a
## save file is a wallet that disappears when the player starts a second club.
static func load_wallet() -> void:
	owed = 0
	## THREE DOORS, newest first (29 Sep 2026). `save_wallet` used to delete the
	## wallet and then rename the new one in, and a kill between the two left
	## no wallet at all — credits paid for and gone. The live file, then a
	## finished `.tmp` that never got renamed, then the one before it.
	for p in [wallet_path(), wallet_path() + ".tmp", wallet_path() + ".bak"]:
		var d = _read_wallet(p)
		if d is Dictionary:
			owed = maxi(0, int(d.get("owed", 0)))
			return


static func _read_wallet(path: String):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var d = f.get_var()
	f.close()
	if d is Dictionary and int(d.get("version", 0)) == WALLET_VERSION:
		return d
	return null


## Written to a temp file and moved into place, so a phone killed mid-write
## leaves the old wallet rather than a torn one (which read back as zero owed).
static func save_wallet() -> bool:
	var path := wallet_path()
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_var({"version": WALLET_VERSION, "owed": maxi(0, owed)}, false)
	var err := f.get_error()
	f.close()
	if err != OK:
		DirAccess.remove_absolute(tmp)
		return false
	## The old wallet steps aside to `.bak` rather than being deleted, so there
	## is no moment with no wallet on disk.
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(path + ".bak")
		DirAccess.rename_absolute(path, path + ".bak")
	return DirAccess.rename_absolute(tmp, path) == OK


## HAND WHAT IS OWED TO THE CLUB THAT IS OPEN. Returns how many credits moved.
##
## ORDER: credit the office, WRITE THE SEASON (`persist`), and only then empty the
## wallet. It used to empty the wallet first, so an app killed between the two —
## or a season save that failed — lost credits somebody paid for. Now the worst
## case is the one that costs BonkWorks and not the customer: the season is on
## disk with the credits AND the wallet still holds them, and they land twice.
##
## `persist` must write the season and return true. If it returns false the
## credit is taken back out of the office and the wallet keeps it for next time.
## Without a `persist` nothing is claimed: a claim nobody saves is a claim that
## can be lost.
static func claim(office, persist: Callable = Callable()) -> int:
	if office == null or owed <= 0 or not persist.is_valid():
		return 0
	var moved := owed
	## THROUGH `take()`, not straight at the balance. Bought credits are the one
	## line on the finances page that is not the club earning.
	office.take(moved, UiKit.t("Credits bought"), "store", ClubOffice.LINE_STORE)
	office.bought += moved
	if not bool(persist.call()):
		office.credits -= moved
		office.bought -= moved
		office.books_in[ClubOffice.LINE_STORE] = int(office.books_in.get(ClubOffice.LINE_STORE, 0)) - moved
		if not office.purse_log.is_empty():
			office.purse_log.pop_front()
		return 0
	owed = 0
	save_wallet()
	return moved


## ---------------------------------------------------------------- buying
## Returns "" if the purchase was started, or a sentence saying why not — the
## same contract every other verb in this project has.
static func buy(id: String) -> String:
	last_error = ""
	var p := product(id)
	if p.is_empty():
		return UiKit.t("There is no such pack.")
	if not available():
		return closed_word()
	var b = _backend()
	if b == null:
		return _stub_buy(p)
	if b.has_method("purchase"):
		b.purchase(id)
		## The grant happens when the store calls back, not here. A store that
		## credits on the REQUEST is a store that credits a canceled purchase.
		return ""
	return UiKit.t("This device cannot take a payment.")


## THE ONLY PATH THAT CREATES CREDITS WITHOUT A PAYMENT, and it is fenced twice.
##
## A debug build needs to be able to walk the whole flow — buy, kill the app,
## reopen, claim — without a card. A release build must not have this path at
## all, and `OS.is_debug_build()` is the fence the exporter itself sets.
## THE FENCE, in one place. `OS.is_debug_build()` is set by the exporter and a
## debug test run cannot change it, so a test that wants to know how a RELEASE
## build behaves sets `release_rules` and asks the real functions — rather than
## reading this file for the words.
static var release_rules: bool = false


static func _debug() -> bool:
	return OS.is_debug_build() and not release_rules


static func _stub_buy(p: Dictionary) -> String:
	if not _debug():
		return UiKit.t("The store is not available on this device.")
	_stub_purchases.append(String(p["id"]))
	return grant(String(p["id"]))


## MONEY IN. Called by the backend's callback, or by the stub.
##
## The wallet is written BEFORE anything is acknowledged upstream, because the
## failure that matters is a player who paid and did not get credited. An
## unacknowledged purchase is re-delivered by the store and lands here twice,
## which credits twice; an acknowledged one that was never banked is gone.
static func grant(id: String) -> String:
	var p := product(id)
	if p.is_empty():
		return UiKit.t("There is no such pack.")
	if not _debug() and _backend() == null:
		## Nothing may create credits in a release build without a real store
		## behind it. This is the line `test_store.gd` exists to hold.
		return UiKit.t("The store is not available on this device.")
	owed += int(p["credits"])
	if not save_wallet():
		owed -= int(p["credits"])
		last_error = UiKit.t("The purchase could not be saved. Nothing was charged twice.")
		return last_error
	var b = _backend()
	if b != null and b.has_method("consumePurchase"):
		b.consumePurchase(id)
	return ""


## WHAT "RESTORE" MEANS FOR A CONSUMABLE, which is not what it means for an
## unlock. There is nothing to re-own — credits were spent. What there can be is
## a purchase the store took payment for and never finished delivering, and this
## asks for those.
##
## Called on connect and from the shop's own button, because a player whose
## credits went missing will look for a button.
static func resolve_pending() -> int:
	var b = _backend()
	if b == null:
		return 0
	if not b.has_method("queryPurchases"):
		return 0
	b.queryPurchases()
	## The plugin answers through its own signal; the count is not knowable here
	## and saying it is would be a number this file made up.
	return -1
