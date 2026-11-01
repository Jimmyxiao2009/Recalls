class_name GateView
extends Control

signal scenario_requested(scenario_id)
signal route_requested(route)

var gates: Array = []

func setup() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    UiFactory.backdrop(self, "res://assets/generated/hub_background.png", Color(0.60, 0.55, 0.48, 1.0))
    var tint := ColorRect.new()
    tint.color = Color(0.02, 0.018, 0.015, 0.52)
    tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(tint)
    var frame := UiFactory.margin_box(52)
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(frame)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 18)
    frame.add_child(column)
    var header := HBoxContainer.new()
    header.add_child(UiFactory.label("世界之门", 28, ThemeFactory.COLORS.ink))
    var hs := Control.new()
    hs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(hs)
    var back := UiFactory.button("返回忘川", Vector2(126, 40), ThemeFactory.COLORS.line)
    back.alignment = HORIZONTAL_ALIGNMENT_CENTER
    back.pressed.connect(func(): route_requested.emit("hub"))
    header.add_child(back)
    column.add_child(header)
    column.add_child(UiFactory.label("按朝代与事件进入历史现场。门不会告诉你结局，但会保留你带回的记忆。", 14, ThemeFactory.COLORS.muted))
    var gate_row := HBoxContainer.new()
    gate_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    gate_row.add_theme_constant_override("separation", 16)
    column.add_child(gate_row)
    gates = PackLoader.get_gate_list()
    for gate in gates:
        gate_row.add_child(_gate_card(gate))
    if gates.is_empty():
        gate_row.add_child(UiFactory.label("没有可进入的世界门。", 16, ThemeFactory.COLORS.muted))

func _gate_card(gate: Dictionary) -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(360, 0)
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.08, 0.06, 0.045, 0.94), ThemeFactory.COLORS.bright, 1, 3))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)
    var texture := TextureRect.new()
    texture.texture = load(str(gate.get("thumbnail", "")))
    texture.custom_minimum_size = Vector2(0, 250)
    texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    texture.modulate = Color(0.72, 0.60, 0.42, 1.0)
    box.add_child(texture)
    var title := UiFactory.label(str(gate.get("era", "未知年代")) + "  ·  " + str(gate.get("title", "未命名")), 22, ThemeFactory.COLORS.gold)
    box.add_child(title)
    box.add_child(UiFactory.label(str(gate.get("date", "")), 12, ThemeFactory.COLORS.bright))
    var desc := UiFactory.label(str(gate.get("description", "")), 14, ThemeFactory.COLORS.muted)
    desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(desc)
    var open := UiFactory.button("进入工作台", Vector2(0, 46), ThemeFactory.COLORS.gold)
    open.alignment = HORIZONTAL_ALIGNMENT_CENTER
    open.pressed.connect(func(): scenario_requested.emit(str(gate.get("scenario_id", ""))))
    box.add_child(open)
    return panel
