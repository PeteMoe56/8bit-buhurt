extends RefCounted
## A STAND-IN FOR THE PLAY BILLING CLIENT (29 Sep 2026) — the same method names
## and signals as godot-google-play-billing's `BillingClient`, so `Store` can be
## driven through connect, prices, purchase, re-delivery and consume without a
## phone. It answers nothing on its own; the test emits what Play would.

signal connected
signal connect_error(response_code: int, debug_message: String)
signal disconnected
signal query_product_details_response(response: Dictionary)
signal on_purchase_updated(response: Dictionary)
signal query_purchases_response(response: Dictionary)
signal consume_purchase_response(response: Dictionary)
signal acknowledge_purchase_response(response: Dictionary)

var calls: Array[String] = []
var consumed: Array[String] = []


func start_connection() -> void:
	calls.append("start_connection")


func query_product_details(ids: PackedStringArray, _type: int) -> void:
	calls.append("query_product_details:" + ",".join(ids))


func query_purchases(_type: int, _subs: bool = false) -> void:
	calls.append("query_purchases")


func purchase(id: String, _opt := "", _offer := "", _pers := false) -> Dictionary:
	calls.append("purchase:" + id)
	return {"response_code": 0}


func consume_purchase(token: String) -> void:
	consumed.append(token)


func is_ready() -> bool:
	return true


## What Play sends for one purchase.
static func bought(id: String, token: String, state := 1) -> Dictionary:
	return {"purchase_token": token, "purchase_state": state, "product_ids": [id],
		"order_id": "GPA." + token, "is_acknowledged": false, "quantity": 1}
