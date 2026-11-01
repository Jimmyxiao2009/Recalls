class_name MemoryView
extends Control

signal route_requested(route)

var graph: MemoryGraph
var inspector_image: TextureRect
var inspector_status: Label
var inspector_title: Label
var inspector_meta: Label
var inspector_subtitle: Label
var inspector_quote: Label
var inspector_description: Label
var relation_label: Label
var memory_count_label: Label
var memories: Array = []

func setup() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    memories = MemorySystem.get_unlocked_definitions()
    UiFactory.backdrop(self, "res://assets/generated/hub_background.png", Color(0.48, 0.44, 0.38, 1.0))
    var tint := ColorRect.new()
    tint.color = Color(0.018, 0.015, 0.013, 0.67)
    tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(tint)

    var frame := UiFactory.margin_box(34)
    frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(frame)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 11)
    frame.add_child(column)
    column.add_child(_header())
    column.add_child(UiFactory.label("Memory 不是收藏品，而是历史现场留下的可验证关系。选择节点可查看其记录与回声链。", 11, ThemeFactory.COLORS.muted))

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 10)
    column.add_child(body)

    var graph_panel := PanelContainer.new()
    graph_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    graph_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    graph_panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.035, 0.027, 0.022, 0.88), Color(0.34, 0.26, 0.18, 0.82), 1, 2))
    body.add_child(graph_panel)
    var graph_box := VBoxContainer.new()
    graph_box.add_theme_constant_override("separation", 5)
    graph_panel.add_child(graph_box)
    var graph_header := HBoxContainer.new()
    graph_header.add_child(UiFactory.section_label("记忆星图 / CONSTELLATION"))
    var graph_spacer := Control.new()
    graph_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    graph_header.add_child(graph_spacer)
    graph_header.add_child(UiFactory.label("线 = 已观测关系    菱形 = 异象记录", 9, ThemeFactory.COLORS.faint))
    graph_box.add_child(graph_header)
    graph = MemoryGraph.new()
    graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
    graph.set_memories(memories)
    graph.memory_selected.connect(_on_memory_selected)
    graph_box.add_child(graph)

    body.add_child(_inspector())
    if memories.is_empty():
        _show_empty_inspector()
    else:
        var first_id := str(memories[0].get("id", ""))
        graph.select(first_id)
        _show_memory(first_id)

func _header() -> Control:
    var header := HBoxContainer.new()
    var title_box := VBoxContainer.new()
    title_box.add_theme_constant_override("separation", 0)
    title_box.add_child(UiFactory.label("Memory / 记忆星图", 27, ThemeFactory.COLORS.ink))
    memory_count_label = UiFactory.label("已归档 %d 条回声" % memories.size(), 10, ThemeFactory.COLORS.gold if not memories.is_empty() else ThemeFactory.COLORS.faint)
    title_box.add_child(memory_count_label)
    header.add_child(title_box)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(spacer)
    var return_route := str(AppState.data.get("memory_return_route", "hub"))
    var return_label := "返回工作台" if return_route == "workbench" else "返回忘川"
    var back := UiFactory.button(return_label, Vector2(130, 40), ThemeFactory.COLORS.line)
    back.alignment = HORIZONTAL_ALIGNMENT_CENTER
    back.pressed.connect(func(): route_requested.emit(return_route))
    header.add_child(back)
    return header

func _inspector() -> Control:
    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(340, 0)
    panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.055, 0.040, 0.030, 0.94), Color(0.42, 0.31, 0.20, 0.86), 1, 2))
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 8)
    panel.add_child(box)
    inspector_status = UiFactory.section_label("MEMORY INSPECTOR")
    box.add_child(inspector_status)
    inspector_image = TextureRect.new()
    inspector_image.custom_minimum_size = Vector2(0, 142)
    inspector_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    inspector_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    inspector_image.modulate = Color(0.72, 0.62, 0.49, 1.0)
    box.add_child(inspector_image)
    inspector_title = UiFactory.label("", 21, ThemeFactory.COLORS.gold)
    inspector_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(inspector_title)
    inspector_meta = UiFactory.label("", 9, ThemeFactory.COLORS.faint)
    box.add_child(inspector_meta)
    inspector_subtitle = UiFactory.label("", 11, ThemeFactory.COLORS.muted)
    inspector_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(inspector_subtitle)
    var separator := HSeparator.new()
    separator.add_theme_stylebox_override("separator", ThemeFactory.panel_style(Color(0, 0, 0, 0), Color(0.34, 0.25, 0.17, 0.7), 0, 0))
    box.add_child(separator)
    inspector_quote = UiFactory.label("", 13, ThemeFactory.COLORS.ink)
    inspector_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(inspector_quote)
    inspector_description = UiFactory.label("", 11, ThemeFactory.COLORS.muted)
    inspector_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    inspector_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
    box.add_child(inspector_description)
    relation_label = UiFactory.label("", 9, ThemeFactory.COLORS.faint)
    relation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    box.add_child(relation_label)
    return panel

func _on_memory_selected(memory_id: String) -> void:
    _show_memory(memory_id)

func _show_memory(memory_id: String) -> void:
    var memory := PackLoader.find("memories", memory_id)
    if memory.is_empty():
        _show_empty_inspector()
        return
    var rarity := str(memory.get("rarity", "record"))
    inspector_status.text = "MEMORY / " + _rarity_label(rarity).to_upper()
    inspector_status.add_theme_color_override("font_color", _rarity_color(rarity))
    inspector_title.text = str(memory.get("title", "未命名记忆"))
    inspector_meta.text = "%s  ·  %s" % [str(memory.get("date", "时间不明")), _rarity_label(rarity)]
    inspector_subtitle.text = str(memory.get("subtitle", ""))
    var quote := str(memory.get("quote", ""))
    inspector_quote.text = "“%s”" % quote if not quote.is_empty() else ""
    inspector_description.text = str(memory.get("description", ""))
    var asset_path := str(memory.get("asset", ""))
    inspector_image.texture = load(asset_path) if not asset_path.is_empty() else null
    inspector_image.visible = inspector_image.texture != null

    var visible_relations: Array = []
    for raw_link in memory.get("links", []):
        if not raw_link is Dictionary:
            continue
        var target_id := str(raw_link.get("to", ""))
        if not AppState.has_memory(target_id):
            continue
        var target := PackLoader.find("memories", target_id)
        visible_relations.append("%s  →  %s" % [str(raw_link.get("label", "关联")), str(target.get("title", target_id))])
    for source in memories:
        if not source is Dictionary or str(source.get("id", "")) == memory_id:
            continue
        for raw_link in source.get("links", []):
            if raw_link is Dictionary and str(raw_link.get("to", "")) == memory_id:
                visible_relations.append("%s  ←  %s" % [str(raw_link.get("label", "关联")), str(source.get("title", "Memory"))])
    relation_label.text = "已观测关联  %d%s" % [visible_relations.size(), "\n" + "\n".join(visible_relations) if not visible_relations.is_empty() else ""]

func _show_empty_inspector() -> void:
    inspector_status.text = "MEMORY / UNOBSERVED"
    inspector_status.add_theme_color_override("font_color", ThemeFactory.COLORS.faint)
    inspector_image.visible = false
    inspector_title.text = "尚无可归档回声"
    inspector_meta.text = "0 ARCHIVED NODES"
    inspector_subtitle.text = "先进入历史现场。"
    inspector_quote.text = ""
    inspector_description.text = "调查地图上的异常物件与历史残留后，Memory 会在这里形成节点。只有同时被观测到的两端，关联线才会显现。"
    relation_label.text = "未观测关系不会提前暴露。"

func _rarity_label(rarity: String) -> String:
    match rarity:
        "anomaly": return "异象记录"
        "trace": return "历史残片"
        "record": return "史实记录"
        "rare": return "稀有记忆"
        _: return rarity

func _rarity_color(rarity: String) -> Color:
    match rarity:
        "anomaly": return ThemeFactory.COLORS.teal
        "trace": return ThemeFactory.COLORS.gold
        "rare": return ThemeFactory.COLORS.ember
        _: return ThemeFactory.COLORS.bright
