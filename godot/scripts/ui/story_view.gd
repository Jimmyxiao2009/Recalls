class_name StoryView
extends Control

signal route_requested(route)

var story_id := ""
var story: Dictionary = {}
var speaker_label: Label
var text_label: Label
var choices_box: VBoxContainer
var continue_button: Button
var exit_button: Button
var node_hint: Label

func setup(requested_story_id: String) -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    story_id = requested_story_id
    story = PackLoader.find("stories", requested_story_id)
    UiFactory.backdrop(self, str(story.get("background_asset", "res://assets/generated/vn_palace_background.png")), Color(0.78, 0.68, 0.52, 1.0))
    var veil := ColorRect.new()
    veil.color = Color(0.02, 0.015, 0.012, 0.42)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(veil)
    _build_header()
    _build_story_box()
    StoryPlayer.node_changed.connect(_on_node_changed)
    StoryPlayer.choices_changed.connect(_on_choices_changed)
    StoryPlayer.story_finished.connect(_on_story_finished)
    StoryPlayer.start(story_id)

func _process(_delta: float) -> void:
    if continue_button and not continue_button.disabled:
        continue_button.disabled = StoryPlayer.busy or not (choices_box.get_child_count() == 0)

func _build_header() -> void:
    var header := PanelContainer.new()
    header.set_anchors_preset(Control.PRESET_TOP_WIDE)
    header.offset_left = 32
    header.offset_right = -32
    header.offset_top = 24
    header.offset_bottom = 76
    header.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.04, 0.025, 0.02, 0.88), ThemeFactory.COLORS.line, 1, 2))
    add_child(header)
    var row := HBoxContainer.new()
    row.add_child(UiFactory.label("STORY LAYER  /  " + str(story.get("title", "剧情")), 12, ThemeFactory.COLORS.gold))
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    row.add_child(spacer)
    node_hint = UiFactory.label("NODE 00", 11, ThemeFactory.COLORS.muted)
    row.add_child(node_hint)
    header.add_child(row)

func _build_story_box() -> void:
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
    panel.offset_left = 32
    panel.offset_right = -32
    panel.offset_top = -258
    panel.offset_bottom = -28
    panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.045, 0.028, 0.022, 0.95), ThemeFactory.COLORS.bright, 1, 3))
    add_child(panel)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 16)
    panel.add_child(row)
    var portrait := TextureRect.new()
    portrait.texture = load(str(story.get("portrait_asset", "res://assets/generated/portrait_chongzhen_placeholder.png")))
    portrait.custom_minimum_size = Vector2(170, 0)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.modulate = Color(0.74, 0.60, 0.42, 1.0)
    row.add_child(portrait)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 8)
    row.add_child(content)
    speaker_label = UiFactory.label("旁白 / NARRATOR", 12, ThemeFactory.COLORS.gold)
    content.add_child(speaker_label)
    text_label = UiFactory.label("", 20, ThemeFactory.COLORS.ink)
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(text_label)
    choices_box = VBoxContainer.new()
    choices_box.add_theme_constant_override("separation", 6)
    content.add_child(choices_box)
    var footer := HBoxContainer.new()
    var hint := UiFactory.label("点击继续，或选择一条留下的回声。", 11, ThemeFactory.COLORS.muted)
    footer.add_child(hint)
    var fill := Control.new()
    fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer.add_child(fill)
    continue_button = UiFactory.button("继续  →", Vector2(130, 42), ThemeFactory.COLORS.gold)
    continue_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
    continue_button.pressed.connect(_on_continue_pressed)
    footer.add_child(continue_button)
    exit_button = UiFactory.button(str(story.get("return_label", "返回忘川")), Vector2(150, 42), ThemeFactory.COLORS.line)
    exit_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
    exit_button.visible = false
    exit_button.pressed.connect(func(): route_requested.emit(str(story.get("return_route", "hub"))))
    footer.add_child(exit_button)
    content.add_child(footer)

func _on_node_changed(node: Dictionary) -> void:
    if speaker_label:
        speaker_label.text = str(node.get("speaker", "旁白")) + "  /  STORY"
    if text_label:
        text_label.text = str(node.get("text", ""))
    if node_hint:
        node_hint.text = "NODE  " + str(node.get("id", "00")).to_upper()
    if continue_button:
        continue_button.visible = true

func _on_choices_changed(choices: Array) -> void:
    UiFactory.clear_children(choices_box)
    for index in range(choices.size()):
        var choice: Dictionary = choices[index]
        var button := UiFactory.button("%d  ·  %s" % [index + 1, str(choice.get("label", "选择"))], Vector2(0, 40), ThemeFactory.COLORS.line)
        button.pressed.connect(StoryPlayer.choose.bind(index))
        choices_box.add_child(button)
    if continue_button:
        continue_button.visible = choices.is_empty()

func _on_continue_pressed() -> void:
    StoryPlayer.advance()

func _on_story_finished(_finished_story_id: String) -> void:
    if continue_button:
        continue_button.visible = false
    if exit_button:
        exit_button.visible = true
    if text_label:
        text_label.text = "记忆已收入忘川。你可以回去了。"
