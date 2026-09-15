extends SceneTree
func _initialize() -> void:
	print("GRIND=%.3f TD_BASE=%.2f TD_STAB=%.2f TD_MAX=%.2f TD_GANG=%.2f GAS_GRAPPLE=%.3f LIST_H=%.0f SPEED=%.0f"
		% [Tuning.GRAPPLE_GRIND, Tuning.TD_BASE, Tuning.TD_STABILITY_W, Tuning.TD_MAX,
		Tuning.TD_GANG, Tuning.GAS_GRAPPLE, Tuning.LIST_H, Tuning.SPEED_BASE])
	quit(0)
