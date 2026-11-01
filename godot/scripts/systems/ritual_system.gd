extends Node

signal ritual_triggered(ritual_id, ritual)

var rituals: Dictionary = {}

func _ready() -> void:
    call_deferred("configure_from_pack")
    AppState.state_changed.connect(_on_state_changed)
    MemorySystem.memory_unlocked.connect(_on_memory_unlocked)
    CeremonyBus.ceremony_finished.connect(_on_ceremony_finished)

func configure_from_pack() -> void:
    rituals = PackLoader.get_all("rituals")

func _on_state_changed(key, value) -> void:
    evaluate({"type": "state_changed", "key": str(key), "value": value})

func _on_memory_unlocked(memory_id, _memory) -> void:
    evaluate({"type": "memory_unlocked", "id": str(memory_id)})

func _on_ceremony_finished(effect_id) -> void:
    evaluate({"type": "ceremony_finished", "id": str(effect_id)})

func evaluate(event: Dictionary) -> void:
    for ritual_id in rituals:
        var ritual: Dictionary = rituals[ritual_id]
        var flag_id := "ritual:" + str(ritual_id)
        if AppState.get_flag(flag_id):
            continue
        if _matches(ritual.get("condition", {}), event):
            AppState.set_flag(flag_id, true)
            ritual_triggered.emit(str(ritual_id), ritual)
            for action in ritual.get("actions", []):
                _execute_action(action)

func _matches(condition: Dictionary, event: Dictionary) -> bool:
    var condition_type := str(condition.get("type", ""))
    match condition_type:
        "memory_unlocked":
            return event.get("type", "") == "memory_unlocked" and str(event.get("id", "")) == str(condition.get("memory_id", ""))
        "progress_at_least":
            return AppState.get_progress() >= float(condition.get("value", 100.0))
        "ceremony_finished":
            return event.get("type", "") == "ceremony_finished" and str(event.get("id", "")) == str(condition.get("phenomenon_id", ""))
        "flag":
            return AppState.get_flag(str(condition.get("flag_id", "")), false) == bool(condition.get("value", true))
    return false

func _execute_action(action: Dictionary) -> void:
    match str(action.get("type", "")):
        "unlock_memory":
            MemorySystem.unlock(str(action.get("memory_id", "")))
        "play_phenomenon":
            AnomalyRuntime.play(str(action.get("phenomenon_id", "")))
        "set_flag":
            AppState.set_flag(str(action.get("flag_id", "")), bool(action.get("value", true)))
