extends Node

signal state_changed(key, value)

const SAVE_PATH := "user://history_narrative_save.json"

var data: Dictionary = {
    "active_scenario": "",
    "scenario_progress": 0.0,
    "scenario_flags": {},
    "unlocked_gates": ["gate_chongzhen"],
    "unlocked_memories": [],
    "visited_routes": ["hub"],
    "last_event": ""
}

func _ready() -> void:
    load_state()

func reset_runtime() -> void:
    data["active_scenario"] = ""
    data["scenario_progress"] = 0.0
    data["scenario_flags"] = {}
    data["last_event"] = ""
    state_changed.emit("runtime_reset", true)

func begin_scenario(scenario_id: String) -> void:
    data["active_scenario"] = scenario_id
    data["scenario_progress"] = 0.0
    data["scenario_flags"] = {}
    data["last_event"] = "scenario_started"
    state_changed.emit("active_scenario", scenario_id)
    state_changed.emit("scenario_progress", 0.0)
    save_state()

func set_progress(value: float) -> void:
    var clamped := clampf(value, 0.0, 100.0)
    data["scenario_progress"] = clamped
    data["last_event"] = "progress_changed"
    state_changed.emit("scenario_progress", clamped)

func get_progress() -> float:
    return float(data.get("scenario_progress", 0.0))

func set_flag(flag_id: String, value: bool = true) -> void:
    var flags: Dictionary = data.get("scenario_flags", {})
    flags[flag_id] = value
    data["scenario_flags"] = flags
    state_changed.emit("flag:" + flag_id, value)

func get_flag(flag_id: String, fallback: bool = false) -> bool:
    var flags: Dictionary = data.get("scenario_flags", {})
    return bool(flags.get(flag_id, fallback))

func unlock_gate(gate_id: String) -> void:
    var gates: Array = data.get("unlocked_gates", [])
    if gate_id not in gates:
        gates.append(gate_id)
        data["unlocked_gates"] = gates
        state_changed.emit("gate_unlocked", gate_id)

func is_gate_unlocked(gate_id: String) -> bool:
    return gate_id in data.get("unlocked_gates", [])

func unlock_memory(memory_id: String) -> void:
    var memories: Array = data.get("unlocked_memories", [])
    if memory_id not in memories:
        memories.append(memory_id)
        data["unlocked_memories"] = memories
        state_changed.emit("memory_unlocked", memory_id)

func has_memory(memory_id: String) -> bool:
    return memory_id in data.get("unlocked_memories", [])

func get_unlocked_memories() -> Array:
    return data.get("unlocked_memories", []).duplicate()

func mark_route(route: String) -> void:
    var routes: Array = data.get("visited_routes", [])
    if route not in routes:
        routes.append(route)
        data["visited_routes"] = routes

func save_state() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "  "))

func load_state() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        data.merge(parsed, true)
