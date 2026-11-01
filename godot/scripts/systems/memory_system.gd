extends Node

signal memory_unlocked(memory_id, memory)

func unlock(memory_id: String) -> bool:
    var memory := PackLoader.find("memories", memory_id)
    if memory.is_empty():
        push_warning("Memory not found: " + memory_id)
        return false
    if not AppState.has_memory(memory_id):
        AppState.unlock_memory(memory_id)
        memory_unlocked.emit(memory_id, memory)
        AppState.save_state()
    return true

func get_unlocked_definitions() -> Array:
    var result: Array = []
    for memory_id in AppState.get_unlocked_memories():
        var memory := PackLoader.find("memories", str(memory_id))
        if not memory.is_empty():
            result.append(memory)
    return result
