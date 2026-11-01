extends Node

signal rule_patch_changed(patch, active)

var active_patches: Dictionary = {}

func clear() -> void:
    active_patches.clear()

func apply(patch: Dictionary) -> void:
    var patch_id := str(patch.get("id", "anonymous_patch"))
    active_patches[patch_id] = patch
    rule_patch_changed.emit(patch, true)

func apply_from_pack(patch_id: String) -> void:
    var scenario := PackLoader.find("scenarios", AppState.data.get("active_scenario", ""))
    var patches: Array = scenario.get("rule_patches", [])
    for patch in patches:
        if str(patch.get("id", "")) == patch_id:
            apply(patch)
            return

func is_disabled(target_id: String) -> bool:
    for patch in active_patches.values():
        if str(patch.get("kind", "")) == "disable_target" and str(patch.get("target", "")) == target_id:
            return true
    return false

func is_ui_captured() -> bool:
    for patch in active_patches.values():
        if str(patch.get("kind", "")) == "capture_ui":
            return true
    return false

func get_active() -> Array:
    return active_patches.values()
