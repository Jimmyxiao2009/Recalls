class_name UiFactory
extends RefCounted

static func label(text: String, size: int = 16, color: Color = ThemeFactory.COLORS.ink) -> Label:
    var node := Label.new()
    node.text = text
    node.add_theme_font_size_override("font_size", size)
    node.add_theme_color_override("font_color", color)
    node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
    node.add_theme_constant_override("shadow_offset_x", 1)
    node.add_theme_constant_override("shadow_offset_y", 1)
    return node

static func section_label(text: String) -> Label:
    var node := label(text.to_upper(), 11, ThemeFactory.COLORS.bright)
    node.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
    return node

static func button(text: String, min_size: Vector2 = Vector2(0, 40), accent: Color = ThemeFactory.COLORS.line) -> Button:
    var node := Button.new()
    node.text = text
    node.custom_minimum_size = min_size
    node.alignment = HORIZONTAL_ALIGNMENT_LEFT
    node.add_theme_stylebox_override("normal", ThemeFactory.button_style(ThemeFactory.COLORS.raised, accent))
    node.add_theme_stylebox_override("hover", ThemeFactory.button_style(Color("302219"), ThemeFactory.COLORS.gold))
    node.add_theme_stylebox_override("pressed", ThemeFactory.button_style(Color("3e2a1a"), ThemeFactory.COLORS.gold))
    node.add_theme_stylebox_override("disabled", ThemeFactory.button_style(Color("11100f"), Color("3b3329")))
    return node

static func panel(parent: Node, title: String = "", min_size: Vector2 = Vector2.ZERO) -> PanelContainer:
    var node := PanelContainer.new()
    node.custom_minimum_size = min_size
    node.add_theme_stylebox_override("panel", ThemeFactory.panel_style())
    parent.add_child(node)
    if not title.is_empty():
        var box := VBoxContainer.new()
        box.add_theme_constant_override("separation", 8)
        node.add_child(box)
        box.add_child(section_label(title))
    return node

static func backdrop(parent: Control, path: String, tint: Color = Color(0.72, 0.66, 0.56, 1.0)) -> TextureRect:
    var rect := TextureRect.new()
    rect.texture = load(path)
    rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    rect.modulate = tint
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    parent.add_child(rect)
    parent.move_child(rect, 0)
    return rect

static func margin_box(margin: int = 12) -> MarginContainer:
    var node := MarginContainer.new()
    node.add_theme_constant_override("margin_left", margin)
    node.add_theme_constant_override("margin_right", margin)
    node.add_theme_constant_override("margin_top", margin)
    node.add_theme_constant_override("margin_bottom", margin)
    return node

static func clear_children(node: Node) -> void:
    for child in node.get_children():
        child.queue_free()
