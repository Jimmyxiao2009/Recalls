class_name MapOverlay
extends Control

var markers: Array = []
var progress := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func set_markers(value: Array) -> void:
    markers = value
    queue_redraw()

func set_progress(value: float) -> void:
    progress = value
    queue_redraw()

func _draw() -> void:
    if markers.is_empty():
        return
    for marker in markers:
        var position_data: Array = marker.get("position", [0.5, 0.5])
        var point := Vector2(float(position_data[0]) * size.x, float(position_data[1]) * size.y)
        var kind := str(marker.get("kind", "objective"))
        var color := ThemeFactory.COLORS.gold
        if kind == "enemy":
            color = ThemeFactory.COLORS.red
        elif kind == "ally":
            color = ThemeFactory.COLORS.teal
        draw_circle(point, 5.0, Color(0.05, 0.04, 0.03, 0.95))
        draw_circle(point, 3.0, color)
        draw_line(point, point + Vector2(18, -10), Color(color, 0.55), 1.0)
        draw_string(ThemeDB.fallback_font, point + Vector2(22, -8), str(marker.get("label", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
    if progress >= 80.0:
        draw_line(Vector2(size.x * 0.18, size.y * 0.34), Vector2(size.x * 0.72, size.y * 0.58), Color(0.65, 0.16, 0.10, 0.75), 4.0)
        draw_line(Vector2(size.x * 0.72, size.y * 0.58), Vector2(size.x * 0.68, size.y * 0.53), Color(0.65, 0.16, 0.10, 0.75), 4.0)
