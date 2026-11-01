extends Node

signal anomaly_started(anomaly_id: String, takeover: String)
signal anomaly_finished(anomaly_id: String, result: Dictionary)
signal anomaly_failed(anomaly_id: String, reason: String)
signal command_emitted(command: Dictionary)

var active_id := ""
var active_takeover := "overlay"
var active_instance: Object = null
var active_payload: Dictionary = {}

func is_active() -> bool:
    return active_instance != null

func play(anomaly_id: String, payload: Dictionary = {}) -> Dictionary:
    if is_active():
        var reason := "another anomaly is already active: %s" % active_id
        anomaly_failed.emit(anomaly_id, reason)
        return {"ok": false, "reason": reason}

    var definition := PackLoader.find("phenomena", anomaly_id)
    if definition.is_empty():
        var reason := "anomaly definition not found"
        anomaly_failed.emit(anomaly_id, reason)
        return {"ok": false, "reason": reason}

    var module_path := str(definition.get("module", ""))
    if module_path.is_empty():
        # Backward-compatible data-only phenomenon.
        await CeremonyBus.play(anomaly_id, payload)
        return {"ok": true, "mode": "ceremony"}

    var script := load(module_path)
    if script == null:
        var reason := "failed to load anomaly module: %s" % module_path
        anomaly_failed.emit(anomaly_id, reason)
        return {"ok": false, "reason": reason}

    var instance = script.new()
    if instance == null:
        var reason := "failed to instantiate anomaly module"
        anomaly_failed.emit(anomaly_id, reason)
        return {"ok": false, "reason": reason}

    active_id = anomaly_id
    active_takeover = str(definition.get("takeover", "overlay"))
    active_payload = payload.duplicate(true)
    active_instance = instance
    anomaly_started.emit(active_id, active_takeover)

    var context := _build_context(definition)
    var result: Dictionary = {"ok": true}
    if instance.has_method("run"):
        var returned = await instance.run(context, payload)
        if returned is Dictionary:
            result = returned
    else:
        result = {"ok": false, "reason": "module has no run(context, payload) method"}

    _finish(result)
    return result

func cancel() -> void:
    if not is_active():
        return
    if active_instance.has_method("cancel"):
        active_instance.cancel()
    _finish({"ok": false, "cancelled": true})

func emit_command(command: Dictionary) -> void:
    command_emitted.emit(command)

func _build_context(definition: Dictionary) -> Dictionary:
    return {
        "runtime": self,
        "tree": get_tree(),
        "app_state": AppState,
        "pack_loader": PackLoader,
        "memory": MemorySystem,
        "ceremony": CeremonyBus,
        "ritual": RitualSystem,
        "rules": RulePatchSystem,
        "definition": definition,
        "takeover": active_takeover,
        "anomaly_id": active_id
    }

func _finish(result: Dictionary) -> void:
    var finished_id := active_id
    active_id = ""
    active_takeover = "overlay"
    active_payload.clear()
    active_instance = null
    anomaly_finished.emit(finished_id, result)
