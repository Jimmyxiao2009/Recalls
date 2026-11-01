class_name BackgroundCanvas
extends Control

var mode := "hub"
var pressure := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    queue_redraw()

func set_mode(value: String) -> void:
    mode = value
    queue_redraw()

func set_pressure(value: float) -> void:
    pressure = clampf(value, 0.0, 100.0)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, size), Color("0b0908"))
    var center := size * Vector2(0.5, 0.47)
    if mode == "hub":
        for radius in [90.0, 150.0, 220.0, 300.0]:
            draw_arc(center, radius, 0.0, TAU, 96, Color(0.64, 0.49, 0.31, 0.08), 1.0)
        for index in range(12):
            var angle := float(index) * TAU / 12.0
            var point := center + Vector2(cos(angle), sin(angle)) * (130.0 + fmod(float(index * 47), 150.0))
            draw_circle(point, 2.5, Color(0.78, 0.60, 0.33, 0.55))
    elif mode == "gate":
        draw_circle(center, 260.0, Color(0.24, 0.18, 0.12, 0.25))
        draw_arc(center, 220.0, PI, TAU, 64, Color(0.78, 0.60, 0.33, 0.22), 2.0)
    elif mode == "workbench":
        var grid_color := Color(0.76, 0.60, 0.40, 0.08)
        for x in range(0, int(size.x), 48):
            draw_line(Vector2(x, 0), Vector2(x, size.y), grid_color, 1.0)
        for y in range(0, int(size.y), 48):
            draw_line(Vector2(0, y), Vector2(size.x, y), grid_color, 1.0)
        if pressure > 50.0:
            draw_circle(Vector2(size.x * 0.78, size.y * 0.35), 130.0, Color(0.55, 0.14, 0.07, 0.08))
