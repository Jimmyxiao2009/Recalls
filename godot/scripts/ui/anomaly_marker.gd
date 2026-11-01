class_name AnomalyMarker
extends Control

signal activated(investigation_id: String)

var investigation_id := ""
var label_text := "异常"
var completed := false
var available := true
var hovered := false
var pulse := 0.0
var hover_mix := 0.0

func _ready() -> void:
    custom_minimum_size = Vector2(190, 72)
    size = custom_minimum_size
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    set_process(true)

func configure(definition: Dictionary, is_completed: bool, is_available: bool) -> void:
    investigation_id = str(definition.get("id", ""))
    label_text = str(definition.get("label", definition.get("title", "异常")))
    tooltip_text = str(definition.get("hint", definition.get("description", "调查此处")))
    completed = is_completed
    available = is_available or completed
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_FORBIDDEN
    queue_redraw()

func update_state(is_completed: bool, is_available: bool) -> void:
    completed = is_completed
    available = is_available or completed
    mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if available else Control.CURSOR_FORBIDDEN
    queue_redraw()

func _process(delta: float) -> void:
    pulse = fmod(pulse + delta, TAU)
    var target := 1.0 if hovered else 0.0
    hover_mix = move_toward(hover_mix, target, delta * 6.0)
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        accept_event()
        if available:
            activated.emit(investigation_id)

func _on_mouse_entered() -> void:
    hovered = true

func _on_mouse_exited() -> void:
    hovered = false

func _draw() -> void:
    var center := Vector2(31, 36)
    var breath := (sin(pulse * 2.1) + 1.0) * 0.5
    var accent := ThemeFactory.COLORS.gold
    if completed:
        accent = ThemeFactory.COLORS.teal
    elif not available:
        accent = ThemeFactory.COLORS.faint

    # No rectangular button chrome: the clickable object is a map glyph with
    # restrained rings and a label that materializes only as the player nears it.
    if available and not completed:
        draw_circle(center, 15.0 + breath * 5.0, Color(accent, 0.055 + breath * 0.055), false, 1.0)
        draw_circle(center, 9.0 + breath * 2.0, Color(accent, 0.18 + breath * 0.12), false, 1.0)
    elif completed:
        draw_circle(center, 10.0, Color(accent, 0.18), false, 1.0)
    else:
        draw_circle(center, 9.0, Color(accent, 0.10), false, 1.0)

    var radius := 6.0 + (1.2 * breath if available and not completed else 0.0)
    var diamond := PackedVector2Array([
        center + Vector2(0, -radius),
        center + Vector2(radius, 0),
        center + Vector2(0, radius),
        center + Vector2(-radius, 0),
        center + Vector2(0, -radius)
    ])
    if completed:
        draw_polyline(diamond, Color(accent, 0.92), 1.6, true)
        draw_circle(center, 1.5, Color(accent, 0.55))
    elif available:
        draw_colored_polygon(PackedVector2Array(diamond.slice(0, 4)), Color(accent, 0.88))
        draw_circle(center, 2.0, Color(0.08, 0.045, 0.025, 0.9))
    else:
        draw_polyline(diamond, Color(accent, 0.48), 1.2, true)
        draw_line(center + Vector2(-4, -4), center + Vector2(4, 4), Color(accent, 0.46), 1.0)

    var reveal := maxf(hover_mix, 0.24 if completed else 0.06)
    if reveal <= 0.02:
        return
    var label_pos := Vector2(53, 18)
    var label_width := 130.0
    var panel_alpha := (0.50 + hover_mix * 0.35) * reveal
    if hovered or completed:
        draw_rect(Rect2(48, 10, 137, 50), Color(0.035, 0.024, 0.017, panel_alpha))
        draw_line(Vector2(48, 10), Vector2(48, 60), Color(accent, 0.34 + hover_mix * 0.35), 1.0)
    draw_string(ThemeDB.fallback_font, label_pos, label_text, HORIZONTAL_ALIGNMENT_LEFT, label_width, 13, Color(ThemeFactory.COLORS.ink, 0.45 + reveal * 0.55))
    var state_text := "已记录" if completed else "调查" if available else "线索不足"
    draw_string(ThemeDB.fallback_font, label_pos + Vector2(0, 22), state_text, HORIZONTAL_ALIGNMENT_LEFT, label_width, 10, Color(accent, 0.34 + reveal * 0.56))
