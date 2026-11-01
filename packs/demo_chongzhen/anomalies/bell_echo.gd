extends RefCounted

var _cancelled := false

func run(context: Dictionary, payload: Dictionary = {}) -> Dictionary:
    var runtime: Node = context["runtime"]
    var ceremony: Node = context["ceremony"]
    var tree: SceneTree = context["tree"]

    runtime.emit_command({"type": "ui_capture", "enabled": true})
    var echoes := [
        {"text": "第一声钟鸣", "strength": 0.24},
        {"text": "同一声钟鸣 · 更远", "strength": 0.42},
        {"text": "同一声钟鸣 · 尚未发生", "strength": 0.62}
    ]
    for echo in echoes:
        if _cancelled:
            runtime.emit_command({"type": "ui_capture", "enabled": false})
            return {"ok": false, "cancelled": true}
        runtime.emit_command({
            "type": "ghost_text",
            "text": str(echo["text"]),
            "duration": 0.62,
            "strength": 0.9
        })
        await ceremony.play_steps(context["anomaly_id"], [
            {"channel": "scene_overlay", "effect": "vignette", "strength": float(echo["strength"]), "duration": 0.34},
            {"channel": "camera", "effect": "shake", "strength": 2.2 + float(echo["strength"]) * 4.0, "duration": 0.18}
        ], payload)
        await tree.create_timer(0.20).timeout

    runtime.emit_command({
        "type": "timeline_echo",
        "text": "23:59:59  →  00:00:00  →  23:59:59",
        "duration": 1.6
    })
    await ceremony.play_steps(context["anomaly_id"], [
        {"channel": "scene_overlay", "effect": "flash", "strength": 0.44, "duration": 0.14},
        {"channel": "scene_overlay", "effect": "aberration", "strength": 0.56, "duration": 0.72},
        {"channel": "text", "effect": "text_flash", "text": "历史正在重新播放", "duration": 1.0}
    ], payload)
    await tree.create_timer(0.4).timeout
    runtime.emit_command({"type": "ui_capture", "enabled": false})
    context["app_state"].set_flag("anomaly:bell_echo", true)
    return {"ok": true, "kind": "recursive_echo"}

func cancel() -> void:
    _cancelled = true
