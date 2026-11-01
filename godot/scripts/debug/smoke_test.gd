extends Node

var failures: Array = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    await get_tree().process_frame
    if not PackLoader.loaded:
        await PackLoader.packs_loaded

    _check(not PackLoader.get_gate_list().is_empty(), "gate list loaded")
    _check(not PackLoader.find("scenarios", "scenario_chongzhen_endgame").is_empty(), "scenario loaded")
    _check(not PackLoader.find("stories", "story_last_edict").is_empty(), "final story loaded")
    _check(not PackLoader.find("stories", "story_bell_echo").is_empty(), "investigation story loaded")
    _check(not PackLoader.find("phenomena", "phenomenon_final_intrusion").is_empty(), "final anomaly loaded")
    _check(not PackLoader.find("phenomena", "phenomenon_register_desync").is_empty(), "register anomaly loaded")
    _check(not PackLoader.find("phenomena", "phenomenon_bell_echo").is_empty(), "bell anomaly loaded")
    _check(not PackLoader.find("rituals", "ritual_echoed_memory").is_empty(), "ritual loaded")

    var investigation_ids := [
        "investigation_desk_memorial",
        "investigation_sealed_register",
        "investigation_bell_shadow"
    ]
    for investigation_id in investigation_ids:
        _check(not PackLoader.find("investigations", investigation_id).is_empty(), "investigation loaded: " + investigation_id)

    _reset_demo_save()
    AppState.begin_scenario("scenario_chongzhen_endgame")
    RulePatchSystem.clear()

    var workbench := WorkbenchView.new()
    add_child(workbench)
    workbench.setup("scenario_chongzhen_endgame")
    await get_tree().process_frame
    _check(workbench.investigation_overlay != null, "workbench creates investigation overlay")
    _check(workbench.investigation_overlay.buttons.size() == 3, "workbench exposes three investigation hotspots")
    _check(workbench.investigation_overlay.buttons["investigation_desk_memorial"] is AnomalyMarker, "hotspots use diegetic AnomalyMarker controls instead of debug buttons")
    var bell_marker: AnomalyMarker = workbench.investigation_overlay.buttons["investigation_bell_shadow"]
    _check(not bell_marker.available, "dependent bell hotspot begins locked")

    workbench._on_investigation_requested("investigation_desk_memorial")
    await get_tree().process_frame
    _check(AppState.has_memory("memory_unfinished_memorial"), "first investigation unlocks memorial memory")

    workbench._on_investigation_requested("investigation_sealed_register")
    if AnomalyRuntime.is_active():
        await AnomalyRuntime.anomaly_finished
    _check(AppState.has_memory("memory_sealed_register"), "second investigation unlocks register memory")
    _check(AppState.get_flag("anomaly:register_desync"), "register investigation executes custom anomaly module")
    _check(bell_marker.available, "bell hotspot unlocks after prerequisite Memories")

    workbench._on_investigation_requested("investigation_bell_shadow")
    if AnomalyRuntime.is_active():
        await AnomalyRuntime.anomaly_finished
    _check(AppState.has_memory("memory_bell_shadow"), "third investigation unlocks bell memory")
    _check(AppState.get_flag("anomaly:bell_echo"), "bell investigation executes custom anomaly module")
    _check(AppState.get_flag("objective_investigation_chain_complete"), "three investigations complete the data-driven objective")
    _check(bell_marker.completed, "investigated hotspot switches to completed visual state")
    _check(str(workbench.active_investigation.get("story_id", "")) == "story_bell_echo", "third investigation exposes story progression")
    _check(PackLoader.find("memories", "memory_unfinished_memorial").get("links", []).size() > 0, "memory relations are declared by pack data")

    AppState.data["memory_return_route"] = "workbench"
    var memory_view := MemoryView.new()
    add_child(memory_view)
    memory_view.setup()
    await get_tree().process_frame
    _check(memory_view.graph != null, "memory view creates constellation graph")
    _check(memory_view.graph.memories.size() == 3, "memory graph contains all unlocked investigation Memories")
    memory_view._show_memory("memory_sealed_register")
    _check(memory_view.inspector_title.text == "先于今日封存的名册", "memory inspector selects and renders pack metadata")
    _check(memory_view.relation_label.text.contains("已观测关联  2"), "memory inspector resolves incoming and outgoing visible relations")
    memory_view.queue_free()

    StoryPlayer.start("story_bell_echo")
    await get_tree().process_frame
    StoryPlayer.advance()
    await get_tree().process_frame
    StoryPlayer.advance()
    await get_tree().process_frame
    StoryPlayer.choose(0)
    await get_tree().process_frame
    StoryPlayer.advance()
    await get_tree().process_frame
    StoryPlayer.advance()
    await get_tree().process_frame
    _check(AppState.get_flag("story_bell_echo_complete"), "investigation story reaches completion flag")
    _check(StoryPlayer.story.is_empty(), "investigation story finishes cleanly")
    var bell_story := PackLoader.find("stories", "story_bell_echo")
    _check(str(bell_story.get("return_route", "")) == "workbench", "investigation story returns to workbench")

    var scenario: Dictionary = PackLoader.find("scenarios", "scenario_chongzhen_endgame")
    for event in scenario.get("progress_events", []):
        if event.has("patch_id"):
            RulePatchSystem.apply_from_pack(str(event.get("patch_id", "")))
        AppState.set_progress(float(event.get("at", 0.0)))
    _check(AppState.get_progress() == 100.0, "progress reaches final threshold")
    _check(RulePatchSystem.is_disabled("advance_history"), "final rule patch disables time control")
    _check(RulePatchSystem.is_disabled("treasury"), "threshold rule patch disables treasury")

    var final_result := await AnomalyRuntime.play("phenomenon_final_intrusion", {"smoke": true})
    _check(bool(final_result.get("ok", false)), "custom final anomaly runs through AnomalyRuntime")
    _check(not AnomalyRuntime.is_active(), "custom final anomaly releases runtime")

    _check(MemorySystem.unlock("memory_last_edict"), "final memory unlock succeeds")
    _check(AppState.has_memory("memory_last_edict"), "final memory persists in app state")

    workbench.queue_free()
    _reset_demo_save()

    if failures.is_empty():
        print("SMOKE PASS: pack -> three investigations -> memories -> custom anomalies -> story -> workbench return -> final takeover")
        get_tree().quit(0)
    else:
        for failure in failures:
            push_error("SMOKE FAIL: " + failure)
        get_tree().quit(1)

func _check(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)

func _reset_demo_save() -> void:
    AppState.data = {
        "active_scenario": "",
        "scenario_progress": 0.0,
        "scenario_flags": {},
        "unlocked_gates": ["gate_chongzhen"],
        "unlocked_memories": [],
        "visited_routes": ["hub"],
        "last_event": ""
    }
    RulePatchSystem.clear()
    AppState.save_state()
