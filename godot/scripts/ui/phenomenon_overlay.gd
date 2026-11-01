class_name PhenomenonOverlay
extends Control

var flash_alpha := 0.0
var noise_alpha := 0.0
var vignette_alpha := 0.0
var aberration_alpha := 0.0
var text_flash := ""
var text_alpha := 0.0
var capture_alpha := 0.0
var ghost_text := ""
var ghost_alpha := 0.0

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    CeremonyBus.ceremony_started.connect(_on_ceremony_started)
    CeremonyBus.ceremony_step.connect(_on_ceremony_step)
    AnomalyRuntime.command_emitted.connect(_on_anomaly_command)
    AnomalyRuntime.anomaly_finished.connect(_on_anomaly_finished)

func _process(_delta: float) -> void:
    if flash_alpha > 0.0 or noise_alpha > 0.0 or vignette_alpha > 0.0 or aberration_alpha > 0.0 or text_alpha > 0.0 or capture_alpha > 0.0 or ghost_alpha > 0.0:
        queue_redraw()

func _on_ceremony_started(_effect_id, _payload) -> void:
    text_flash = ""
    text_alpha = 0.0
    queue_redraw()

func _on_ceremony_step(step: Dictionary) -> void:
    var effect := str(step.get("effect", ""))
    var duration := maxf(float(step.get("duration", 0.25)), 0.08)
    var strength := clampf(float(step.get("strength", 1.0)), 0.0, 1.0)
    if effect == "flash":
        flash_alpha = maxf(flash_alpha, strength)
        _fade_value("flash_alpha", 0.0, duration)
    elif effect == "noise":
        noise_alpha = maxf(noise_alpha, strength)
        _fade_value("noise_alpha", 0.0, duration)
    elif effect == "vignette":
        vignette_alpha = maxf(vignette_alpha, strength)
        _fade_value("vignette_alpha", 0.0, duration)
    elif effect == "aberration":
        aberration_alpha = maxf(aberration_alpha, strength)
        _fade_value("aberration_alpha", 0.0, duration)
    elif effect == "text_flash":
        text_flash = str(step.get("text", ""))
        text_alpha = 1.0
        _fade_value("text_alpha", 0.0, duration)
    queue_redraw()

func _on_anomaly_command(command: Dictionary) -> void:
    match str(command.get("type", "")):
        "ui_capture":
            var enabled := bool(command.get("enabled", false))
            mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
            capture_alpha = 0.32 if enabled else 0.0
            queue_redraw()
        "ghost_text":
            ghost_text = str(command.get("text", ""))
            ghost_alpha = clampf(float(command.get("strength", 1.0)), 0.0, 1.0)
            _fade_value("ghost_alpha", 0.0, maxf(float(command.get("duration", 0.9)), 0.1))
        "timeline_echo":
            ghost_text = str(command.get("text", "23:59  /  00:00  /  23:59"))
            ghost_alpha = 1.0
            aberration_alpha = maxf(aberration_alpha, 0.42)
            _fade_value("ghost_alpha", 0.0, maxf(float(command.get("duration", 1.2)), 0.1))
            _fade_value("aberration_alpha", 0.0, maxf(float(command.get("duration", 1.2)), 0.1))
    queue_redraw()

func _on_anomaly_finished(_anomaly_id: String, _result: Dictionary) -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    capture_alpha = 0.0
    queue_redraw()

func _fade_value(property_name: String, target: float, duration: float) -> void:
    var tween := create_tween()
    tween.tween_property(self, property_name, target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _draw() -> void:
    if capture_alpha > 0.0:
        draw_rect(Rect2(Vector2.ZERO, size), Color(0.015, 0.01, 0.008, capture_alpha))
        var border := Rect2(12, 12, maxf(size.x - 24.0, 0.0), maxf(size.y - 24.0, 0.0))
        draw_rect(border, Color(0.62, 0.20, 0.12, capture_alpha * 0.65), false, 2.0)
    if flash_alpha > 0.0:
        draw_rect(Rect2(Vector2.ZERO, size), Color(1.0, 0.92, 0.78, flash_alpha * 0.65))
    if aberration_alpha > 0.0:
        draw_rect(Rect2(-5, 0, size.x, size.y), Color(0.60, 0.14, 0.10, aberration_alpha * 0.12))
        draw_rect(Rect2(5, 0, size.x, size.y), Color(0.22, 0.42, 0.46, aberration_alpha * 0.08))
    if noise_alpha > 0.0:
        for index in range(80):
            var x := fmod(float(index * 83 + Time.get_ticks_msec() / 9), maxf(size.x, 1.0))
            var y := fmod(float(index * 47 + Time.get_ticks_msec() / 13), maxf(size.y, 1.0))
            draw_rect(Rect2(x, y, 1.0 + float(index % 3), 1.0), Color(0.84, 0.72, 0.55, noise_alpha * 0.22))
    if vignette_alpha > 0.0:
        var edge := 70.0 + 80.0 * vignette_alpha
        draw_rect(Rect2(0, 0, size.x, edge), Color(0.02, 0.01, 0.01, vignette_alpha * 0.38))
        draw_rect(Rect2(0, size.y - edge, size.x, edge), Color(0.02, 0.01, 0.01, vignette_alpha * 0.55))
        draw_rect(Rect2(0, 0, edge, size.y), Color(0.02, 0.01, 0.01, vignette_alpha * 0.3))
        draw_rect(Rect2(size.x - edge, 0, edge, size.y), Color(0.02, 0.01, 0.01, vignette_alpha * 0.3))
    if text_alpha > 0.0 and not text_flash.is_empty():
        var box := Rect2(32, 88, minf(size.x - 64.0, 420.0), 40)
        draw_rect(box, Color(0.05, 0.03, 0.02, text_alpha * 0.9))
        draw_line(box.position, box.position + Vector2(4, box.size.y), ThemeFactory.COLORS.red, 2.0)
        draw_string(ThemeDB.fallback_font, box.position + Vector2(20, 26), text_flash, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.92, 0.78, 0.58, text_alpha))
    if ghost_alpha > 0.0 and not ghost_text.is_empty():
        var center := Vector2(size.x * 0.5, size.y * 0.46)
        var width := minf(size.x * 0.72, 760.0)
        var ghost_box := Rect2(center.x - width * 0.5, center.y - 34.0, width, 68.0)
        draw_rect(ghost_box, Color(0.025, 0.015, 0.012, ghost_alpha * 0.72))
        draw_line(Vector2(ghost_box.position.x, center.y), Vector2(ghost_box.end.x, center.y), Color(0.72, 0.49, 0.26, ghost_alpha * 0.4), 1.0)
        draw_string(ThemeDB.fallback_font, Vector2(ghost_box.position.x + 24, center.y + 7), ghost_text, HORIZONTAL_ALIGNMENT_CENTER, ghost_box.size.x - 48.0, 22, Color(0.94, 0.79, 0.57, ghost_alpha))
