extends RefCounted

var _cancelled := false

func run(context: Dictionary, payload: Dictionary = {}) -> Dictionary:
    var runtime: Node = context["runtime"]
    var ceremony: Node = context["ceremony"]
    var tree: SceneTree = context["tree"]

    runtime.emit_command({"type": "ui_capture", "enabled": true})
    runtime.emit_command({
        "type": "timeline_echo",
        "text": "三月十九  →  三月十七  →  三月十九",
        "duration": 1.4
    })
    await ceremony.play_steps(context["anomaly_id"], [
        {"channel": "scene_overlay", "effect": "noise", "strength": 0.34, "duration": 0.28},
        {"channel": "scene_overlay", "effect": "aberration", "strength": 0.52, "duration": 0.46},
        {"channel": "text", "effect": "text_flash", "text": "封存日期无法成立", "duration": 0.78}
    ], payload)
    if _cancelled:
        runtime.emit_command({"type": "ui_capture", "enabled": false})
        return {"ok": false, "cancelled": true}

    runtime.emit_command({
        "type": "ghost_text",
        "text": "纸上今日，墨中前日。",
        "duration": 0.9,
        "strength": 0.88
    })
    await tree.create_timer(0.9).timeout
    runtime.emit_command({"type": "ui_capture", "enabled": false})
    context["app_state"].set_flag("anomaly:register_desync", true)
    return {"ok": true, "kind": "temporal_desync"}

func cancel() -> void:
    _cancelled = true
