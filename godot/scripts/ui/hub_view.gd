class_name HubView
extends Control

signal route_requested(route)

var hub_data: Dictionary = {}

func setup() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    hub_data = PackLoader.get_hub()
    UiFactory.backdrop(self, "res://assets/generated/hub_background.png", Color(0.72, 0.66, 0.56, 1.0))
    var tint := ColorRect.new()
    tint.color = Color(0.03, 0.025, 0.02, 0.38)
    tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(tint)
    var frame := UiFactory.margin_box(34)
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(frame)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 18)
    frame.add_child(column)
    column.add_child(_header())
    column.add_child(_main_content())
    column.add_child(_footer())

func _header() -> Control:
    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(0, 62)
    row.add_theme_constant_override("separation", 16)
    var title_box := VBoxContainer.new()
    var title := UiFactory.label("忘川", 30, ThemeFactory.COLORS.ink)
    var subtitle := UiFactory.label(str(hub_data.get("subtitle", "记忆停泊于水面，世界之门在雾中等待。")), 13, ThemeFactory.COLORS.muted)
    title_box.add_child(title)
    title_box.add_child(subtitle)
    row.add_child(title_box)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer)
    var status := UiFactory.label("HUB LAYER  ·  STABLE", 11, ThemeFactory.COLORS.gold)
    status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(status)
    return row

func _main_content() -> Control:
    var row := HBoxContainer.new()
    row.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_theme_constant_override("separation", 16)
    var left := _panel()
    left.custom_minimum_size = Vector2(235, 0)
    row.add_child(left)
    var left_box := VBoxContainer.new()
    left_box.add_theme_constant_override("separation", 10)
    left.add_child(left_box)
    left_box.add_child(UiFactory.section_label("世界门 / WORLD GATE"))
    var gate := UiFactory.button("壹  ·  终局前夕\n      明末 · 京师", Vector2(0, 76), ThemeFactory.COLORS.gold)
    gate.tooltip_text = "进入示例内容包 demo_chongzhen"
    gate.pressed.connect(func(): route_requested.emit("gate"))
    left_box.add_child(gate)
    var locked := UiFactory.button("贰  ·  尚未归还\n      条件未满足", Vector2(0, 76), ThemeFactory.COLORS.line)
    locked.disabled = true
    left_box.add_child(locked)
    var left_fill := Control.new()
    left_fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
    left_box.add_child(left_fill)
    var line := UiFactory.label("一扇门仍在等待。\n你不必改变历史，先听它说完。", 14, ThemeFactory.COLORS.muted)
    line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    left_box.add_child(line)

    var center := _panel()
    center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(center)
    var center_box := VBoxContainer.new()
    center_box.alignment = BoxContainer.ALIGNMENT_CENTER
    center_box.add_theme_constant_override("separation", 16)
    center.add_child(center_box)
    var mark := UiFactory.label("记忆之水", 18, ThemeFactory.COLORS.gold)
    mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    center_box.add_child(mark)
    var gate_icon := Label.new()
    gate_icon.text = "◇\n│\n◇"
    gate_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    gate_icon.add_theme_font_size_override("font_size", 56)
    gate_icon.add_theme_color_override("font_color", ThemeFactory.COLORS.gold)
    gate_icon.custom_minimum_size = Vector2(0, 190)
    center_box.add_child(gate_icon)
    var quote := UiFactory.label(str(hub_data.get("ambient_lines", ["水声已静。"])[0]), 16, ThemeFactory.COLORS.ink)
    quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    center_box.add_child(quote)

    var right := _panel()
    right.custom_minimum_size = Vector2(260, 0)
    row.add_child(right)
    var right_box := VBoxContainer.new()
    right_box.add_theme_constant_override("separation", 10)
    right.add_child(right_box)
    var memory_title := HBoxContainer.new()
    memory_title.add_child(UiFactory.section_label("MEMORY / 记忆"))
    var mspacer := Control.new()
    mspacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    memory_title.add_child(mspacer)
    memory_title.add_child(UiFactory.label("%d / 12" % AppState.get_unlocked_memories().size(), 11, ThemeFactory.COLORS.gold))
    right_box.add_child(memory_title)
    var memories := MemorySystem.get_unlocked_definitions()
    if memories.is_empty():
        right_box.add_child(UiFactory.label("记忆尚未点亮。\n进入一段历史，带回一枚回声。", 14, ThemeFactory.COLORS.muted))
    else:
        for memory in memories:
            var card := UiFactory.button("忆  %s\n    %s" % [str(memory.get("title", "未命名")), str(memory.get("subtitle", ""))], Vector2(0, 68), ThemeFactory.COLORS.gold)
            card.pressed.connect(func(): route_requested.emit("memory"))
            right_box.add_child(card)
    var rfill := Control.new()
    rfill.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right_box.add_child(rfill)
    var browse := UiFactory.button("查看完整 Memory", Vector2(0, 44), ThemeFactory.COLORS.line)
    browse.pressed.connect(func(): route_requested.emit("memory"))
    right_box.add_child(browse)
    return row

func _footer() -> Control:
    var row := HBoxContainer.new()
    row.custom_minimum_size = Vector2(0, 32)
    var label := UiFactory.label("HISTORY NARRATIVE ENGINE  /  PACKS ONLINE", 10, ThemeFactory.COLORS.faint)
    row.add_child(label)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer)
    var hint := UiFactory.label("ENTER 进入世界门    M 查看记忆", 10, ThemeFactory.COLORS.faint)
    row.add_child(hint)
    return row

func _panel() -> PanelContainer:
    var node := PanelContainer.new()
    node.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.07, 0.05, 0.04, 0.88), ThemeFactory.COLORS.line, 1, 3))
    return node
