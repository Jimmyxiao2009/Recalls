class_name InvestigationOverlay
extends Control

signal investigation_requested(investigation_id: String)

var hotspots: Array = []
# Kept as `buttons` for smoke-test/API compatibility, but values are now
# AnomalyMarker controls rather than rectangular Button widgets.
var buttons: Dictionary = {}

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    resized.connect(_layout_markers)

func set_hotspots(value: Array) -> void:
    hotspots = value.duplicate(true)
    _rebuild()

func refresh_states() -> void:
    for hotspot in hotspots:
        if not hotspot is Dictionary:
            continue
        var hotspot_id := str(hotspot.get("id", ""))
        if not buttons.has(hotspot_id):
            continue
        _apply_state(buttons[hotspot_id], hotspot)

func _rebuild() -> void:
    for child in get_children():
        child.queue_free()
    buttons.clear()
    for hotspot in hotspots:
        if not hotspot is Dictionary:
            continue
        var hotspot_id := str(hotspot.get("id", ""))
        if hotspot_id.is_empty():
            continue
        var marker := AnomalyMarker.new()
        marker.name = "Investigation_" + hotspot_id
        add_child(marker)
        marker.configure(hotspot, _is_completed(hotspot), _requirements_met(hotspot))
        marker.activated.connect(_on_marker_activated)
        buttons[hotspot_id] = marker
    call_deferred("_layout_markers")

func _layout_markers() -> void:
    if size.x <= 1.0 or size.y <= 1.0:
        return
    for hotspot in hotspots:
        if not hotspot is Dictionary:
            continue
        var hotspot_id := str(hotspot.get("id", ""))
        if not buttons.has(hotspot_id):
            continue
        var position_data: Array = hotspot.get("position", [0.5, 0.5])
        if position_data.size() < 2:
            continue
        var marker: AnomalyMarker = buttons[hotspot_id]
        var point := Vector2(float(position_data[0]) * size.x, float(position_data[1]) * size.y)
        # The glyph center inside AnomalyMarker is (31, 36); keep the data-pack
        # coordinate pinned exactly to that glyph rather than the whole label area.
        marker.position = point - Vector2(31, 36)

func _apply_state(marker: AnomalyMarker, hotspot: Dictionary) -> void:
    marker.update_state(_is_completed(hotspot), _requirements_met(hotspot))

func _is_completed(hotspot: Dictionary) -> bool:
    var hotspot_id := str(hotspot.get("id", ""))
    var memory_id := str(hotspot.get("memory_id", ""))
    return AppState.get_flag("investigation:" + hotspot_id) or (not memory_id.is_empty() and AppState.has_memory(memory_id))

func _requirements_met(hotspot: Dictionary) -> bool:
    for memory_id in hotspot.get("requires_memories", []):
        if not AppState.has_memory(str(memory_id)):
            return false
    for flag_id in hotspot.get("requires_flags", []):
        if not AppState.get_flag(str(flag_id)):
            return false
    return true

func _on_marker_activated(investigation_id: String) -> void:
    investigation_requested.emit(investigation_id)
