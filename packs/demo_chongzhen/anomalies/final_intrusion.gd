extends RefCounted

var _cancelled := false

func run(context: Dictionary, payload: Dictionary = {}) -> Dictionary:
    var ceremony: Node = context["ceremony"]
    var rules: Node = context["rules"]
    var runtime: Node = context["runtime"]

    # This anomaly deliberately violates the normal workbench contract:
    # first capture ordinary UI, then progressively corrupt presentation.
    rules.apply({
        "id": "anomaly.final_intrusion.capture_ui",
        "kind": "capture_ui",
        "source": context["anomaly_id"]
    })

    runtime.emit_command({"type": "ui_capture", "enabled": true})
    await ceremony.play_steps(context["anomaly_id"], [
        {"channel": "audio", "effect": "lowpass", "strength": 0.82, "duration": 0.35},
        {"channel": "camera", "effect": "shake", "strength": 5.0, "duration": 0.32},
        {"channel": "scene_overlay", "effect": "flash", "strength": 0.72, "duration": 0.18},
        {"channel": "shader", "effect": "desaturate", "strength": 0.72, "duration": 0.6},
        {"channel": "scene_overlay", "effect": "vignette", "strength": 0.78, "duration": 0.72},
        {"channel": "scene_overlay", "effect": "aberration", "strength": 0.55, "duration": 0.42},
        {"channel": "text", "effect": "text_flash", "text": "城已破 · 不可撤回", "duration": 1.1}
    ], payload)

    if _cancelled:
        return {"ok": false, "cancelled": true}

    runtime.emit_command({
        "type": "world_rule_override",
        "name": "history_is_now_irreversible",
        "value": true
    })

    return {
        "ok": true,
        "irreversible": true,
        "tag": "history_intrusion"
    }

func cancel() -> void:
    _cancelled = true
