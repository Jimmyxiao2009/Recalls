extends Node

signal ceremony_started(effect_id, payload)
signal ceremony_step(step)
signal ceremony_finished(effect_id)

var is_playing := false
var active_effect_id := ""

func play(effect_id: String, payload: Dictionary = {}) -> void:
    if is_playing:
        return
    var phenomenon := PackLoader.find("phenomena", effect_id)
    if phenomenon.is_empty():
        push_warning("Phenomenon not found: " + effect_id)
        return
    is_playing = true
    active_effect_id = effect_id
    ceremony_started.emit(effect_id, payload)
    await _run_steps(phenomenon.get("steps", []))
    is_playing = false
    ceremony_finished.emit(effect_id)

func play_steps(effect_id: String, steps: Array, payload: Dictionary = {}) -> void:
    if is_playing:
        return
    is_playing = true
    active_effect_id = effect_id
    ceremony_started.emit(effect_id, payload)
    await _run_steps(steps)
    is_playing = false
    ceremony_finished.emit(effect_id)

func emit_step(step: Dictionary) -> void:
    ceremony_step.emit(step)

func _run_steps(steps: Array) -> void:
    for raw_step in steps:
        var step: Dictionary = raw_step if raw_step is Dictionary else {}
        ceremony_step.emit(step)
        var duration := maxf(float(step.get("duration", 0.2)), 0.0)
        if duration > 0.0:
            await get_tree().create_timer(duration).timeout
