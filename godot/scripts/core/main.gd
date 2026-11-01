extends Node

var root_control: Control
var procedural_background: BackgroundCanvas
var backdrop: TextureRect
var backdrop_tint: ColorRect
var page_host: Control
var phenomenon_overlay: PhenomenonOverlay
var current_view: Control

func _ready() -> void:
    root_control = Control.new()
    root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.theme = ThemeFactory.build_theme()
    add_child(root_control)
    procedural_background = BackgroundCanvas.new()
    root_control.add_child(procedural_background)
    backdrop = TextureRect.new()
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.add_child(backdrop)
    backdrop_tint = ColorRect.new()
    backdrop_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    backdrop_tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.add_child(backdrop_tint)
    page_host = Control.new()
    page_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root_control.add_child(page_host)
    phenomenon_overlay = PhenomenonOverlay.new()
    root_control.add_child(phenomenon_overlay)
    SceneRouter.route_changed.connect(_show_route)
    PackLoader.packs_loaded.connect(_on_packs_loaded)
    CeremonyBus.ceremony_step.connect(_on_ceremony_step)
    if PackLoader.loaded:
        call_deferred("_on_packs_loaded")

func _on_packs_loaded() -> void:
    RitualSystem.configure_from_pack()
    _show_route(SceneRouter.current_route)

func _show_route(route: String) -> void:
    if not page_host:
        return
    UiFactory.clear_children(page_host)
    var image_path := "res://assets/generated/hub_background.png"
    var mode := "hub"
    var tint := Color(0.03, 0.025, 0.02, 0.34)
    match route:
        "hub":
            current_view = HubView.new()
            current_view.setup()
        "gate":
            current_view = GateView.new()
            current_view.setup()
            tint = Color(0.02, 0.018, 0.015, 0.52)
        "memory":
            current_view = MemoryView.new()
            current_view.setup()
            tint = Color(0.02, 0.018, 0.015, 0.54)
        "workbench":
            current_view = WorkbenchView.new()
            var scenario_id := str(AppState.data.get("active_scenario", "scenario_chongzhen_endgame"))
            var scenario := PackLoader.find("scenarios", scenario_id)
            image_path = str(scenario.get("map_asset", "res://assets/generated/chongzhen_workbench_map.png"))
            mode = "workbench"
            tint = Color(0.03, 0.025, 0.02, 0.18)
            current_view.setup(scenario_id)
        "story":
            current_view = StoryView.new()
            var requested_story := str(AppState.data.get("pending_story", "story_last_edict"))
            var story := PackLoader.find("stories", requested_story)
            image_path = str(story.get("background_asset", "res://assets/generated/vn_palace_background.png"))
            tint = Color(0.02, 0.015, 0.012, 0.42)
            current_view.setup(requested_story)
        _:
            current_view = HubView.new()
            current_view.setup()
    current_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    page_host.add_child(current_view)
    if current_view.has_signal("route_requested"):
        current_view.route_requested.connect(_on_route_requested)
    if current_view.has_signal("scenario_requested"):
        current_view.scenario_requested.connect(_on_scenario_requested)
    if current_view.has_signal("story_requested"):
        current_view.story_requested.connect(_on_story_requested)
    procedural_background.set_mode(mode)
    procedural_background.set_pressure(AppState.get_progress())
    backdrop.texture = load(image_path)
    backdrop.visible = backdrop.texture != null
    backdrop.modulate = Color(0.82, 0.74, 0.61, 1.0)
    backdrop_tint.color = tint

func _on_route_requested(route: String) -> void:
    SceneRouter.go(route)

func _on_scenario_requested(scenario_id: String) -> void:
    AppState.begin_scenario(scenario_id)
    RulePatchSystem.clear()
    SceneRouter.go("workbench")

func _on_story_requested(story_id: String) -> void:
    AppState.data["pending_story"] = story_id
    SceneRouter.go("story")

func _on_ceremony_step(step: Dictionary) -> void:
    if str(step.get("effect", "")) != "shake" or not page_host:
        return
    var strength := clampf(float(step.get("strength", 4.0)), 1.0, 12.0)
    var duration := maxf(float(step.get("duration", 0.3)), 0.1)
    var tween := create_tween()
    for index in range(4):
        var offset := Vector2(strength if index % 2 == 0 else -strength, -strength if index % 3 == 0 else strength)
        tween.tween_property(page_host, "position", offset, duration / 4.0)
    tween.tween_property(page_host, "position", Vector2.ZERO, duration / 4.0)

func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_ESCAPE:
        if SceneRouter.current_route != "hub":
            SceneRouter.go("hub")
    elif event.keycode == KEY_M:
        AppState.data["memory_return_route"] = SceneRouter.current_route if SceneRouter.current_route in ["hub", "workbench"] else "hub"
        SceneRouter.go("memory")
    elif event.keycode == KEY_ENTER and SceneRouter.current_route == "hub":
        SceneRouter.go("gate")
