extends Node

signal story_started(story)
signal node_changed(node)
signal choices_changed(choices)
signal story_finished(story_id)

var story: Dictionary = {}
var nodes: Dictionary = {}
var story_id := ""
var current_node_id := ""
var busy := false
var choice_active := false
var ending := false

func start(requested_story_id: String) -> void:
    var loaded_story := PackLoader.find("stories", requested_story_id)
    if loaded_story.is_empty():
        push_warning("Story not found: " + requested_story_id)
        return
    story = loaded_story
    story_id = requested_story_id
    nodes.clear()
    for raw_node in story.get("nodes", []):
        if raw_node is Dictionary and raw_node.has("id"):
            nodes[str(raw_node["id"])] = raw_node
    current_node_id = str(story.get("start", ""))
    ending = false
    choice_active = false
    story_started.emit(story)
    _enter_node()

func advance() -> void:
    if busy or choice_active or current_node_id == "":
        return
    if ending:
        finish()
        return
    var current: Dictionary = nodes.get(current_node_id, {})
    var next_id := str(current.get("next", ""))
    if next_id.is_empty():
        finish()
    else:
        current_node_id = next_id
        _enter_node()

func choose(choice_index: int) -> void:
    if busy or not choice_active:
        return
    var current: Dictionary = nodes.get(current_node_id, {})
    var choices: Array = current.get("choices", [])
    if choice_index < 0 or choice_index >= choices.size():
        return
    var choice: Dictionary = choices[choice_index]
    choice_active = false
    choices_changed.emit([])
    var next_id := str(choice.get("next", current.get("next", "")))
    if next_id.is_empty():
        finish()
    else:
        current_node_id = next_id
        _enter_node()

func finish() -> void:
    if story_id.is_empty():
        return
    var finished_id := story_id
    story = {}
    nodes.clear()
    story_id = ""
    current_node_id = ""
    ending = false
    choice_active = false
    choices_changed.emit([])
    story_finished.emit(finished_id)

func _enter_node() -> void:
    var node: Dictionary = nodes.get(current_node_id, {})
    if node.is_empty():
        finish()
        return
    choice_active = false
    choices_changed.emit([])
    node_changed.emit(node)
    _run_commands(node.get("commands", []))

func _run_commands(commands: Array) -> void:
    busy = true
    for raw_command in commands:
        if raw_command is Dictionary:
            await _execute_command(raw_command)
    busy = false
    var node: Dictionary = nodes.get(current_node_id, {})
    var choices: Array = node.get("choices", [])
    if not choices.is_empty():
        choice_active = true
        choices_changed.emit(choices)
    if bool(node.get("end", false)):
        ending = true

func _execute_command(command: Dictionary) -> void:
    match str(command.get("type", "")):
        "show", "hide", "fade", "flash", "shake", "text_flash", "camera", "audio":
            CeremonyBus.emit_step(command)
        "phenomenon":
            await AnomalyRuntime.play(str(command.get("id", "")))
        "wait":
            await get_tree().create_timer(maxf(float(command.get("duration", 0.3)), 0.0)).timeout
        "award_memory":
            MemorySystem.unlock(str(command.get("memory_id", "")))
        "set_progress":
            AppState.set_progress(float(command.get("value", AppState.get_progress())))
        "set_flag":
            AppState.set_flag(str(command.get("flag_id", "")), bool(command.get("value", true)))
        "rule_patch":
            RulePatchSystem.apply_from_pack(str(command.get("patch_id", "")))
        "jump":
            current_node_id = str(command.get("node_id", current_node_id))
        "end":
            ending = true
