class_name WorkbenchView
extends Control

signal story_requested(story_id)
signal route_requested(route)

var scenario: Dictionary = {}
var scenario_id := ""
var progress := 0.0
var progress_value_label: Label
var progress_bar: ProgressBar
var objective_detail_label: Label
var log_label: Label
var map_texture: TextureRect
var map_overlay: MapOverlay
var investigation_overlay: InvestigationOverlay
var investigation_card: PanelContainer
var investigation_title: Label
var investigation_status: Label
var investigation_meta: Label
var investigation_body: Label
var investigation_reward: Label
var investigation_story_button: Button
var active_investigation: Dictionary = {}
var memory_list_box: VBoxContainer
var final_box: PanelContainer
var command_buttons: Dictionary = {}

func setup(requested_scenario_id: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scenario_id = requested_scenario_id
	scenario = PackLoader.find("scenarios", requested_scenario_id)
	progress = AppState.get_progress()
	_build()
	_refresh()

func _build() -> void:
	var map_path := str(scenario.get("map_asset", "res://assets/generated/chongzhen_workbench_map.png"))
	UiFactory.backdrop(self, map_path, Color(0.72, 0.66, 0.56, 1.0))
	var veil := ColorRect.new()
	veil.color = Color(0.03, 0.025, 0.02, 0.40)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	var frame := UiFactory.margin_box(8)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	frame.add_child(root)
	root.add_child(_top_bar())
	root.add_child(_main_tabs())
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 6)
	body.add_child(_left_panel())
	var center := _map_panel()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(center)
	body.add_child(_right_panel())
	root.add_child(body)
	root.add_child(_bottom_command_bar())

func _top_bar() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 70)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color("0f0c0a"), Color("6f4d2d"), 1, 2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var brand := VBoxContainer.new()
	brand.custom_minimum_size = Vector2(170, 0)
	brand.add_child(UiFactory.label("大明 · 甲申", 21, ThemeFactory.COLORS.gold))
	brand.add_child(UiFactory.label(str(scenario.get("date", "明末 · 夜半")), 11, ThemeFactory.COLORS.muted))
	row.add_child(brand)
	for resource in scenario.get("resources", []):
		var stat := VBoxContainer.new()
		stat.custom_minimum_size = Vector2(98, 0)
		stat.alignment = BoxContainer.ALIGNMENT_CENTER
		stat.add_child(UiFactory.label(str(resource.get("label", "资源")), 10, ThemeFactory.COLORS.muted))
		var value_row := HBoxContainer.new()
		value_row.alignment = BoxContainer.ALIGNMENT_CENTER
		value_row.add_child(UiFactory.label(str(resource.get("value", "—")), 15, ThemeFactory.COLORS.ink))
		value_row.add_child(UiFactory.label("  " + str(resource.get("delta", "")), 10, ThemeFactory.COLORS.ember))
		stat.add_child(value_row)
		row.add_child(stat)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var pressure := VBoxContainer.new()
	pressure.custom_minimum_size = Vector2(130, 0)
	pressure.alignment = BoxContainer.ALIGNMENT_CENTER
	pressure.add_child(UiFactory.label("史实还原度", 10, ThemeFactory.COLORS.bright))
	progress_value_label = UiFactory.label("00%", 22, ThemeFactory.COLORS.gold)
	progress_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pressure.add_child(progress_value_label)
	row.add_child(pressure)
	var time_box := VBoxContainer.new()
	time_box.custom_minimum_size = Vector2(130, 0)
	time_box.alignment = BoxContainer.ALIGNMENT_CENTER
	time_box.add_child(UiFactory.label("三月 · 十九", 16, ThemeFactory.COLORS.ink))
	time_box.add_child(UiFactory.label("夜半 / 23:47", 10, ThemeFactory.COLORS.muted))
	row.add_child(time_box)
	var pause := UiFactory.button("Ⅱ", Vector2(42, 42), ThemeFactory.COLORS.line)
	pause.alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause.tooltip_text = "暂停 / 继续"
	row.add_child(pause)
	return panel

func _main_tabs() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 38)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color("15110e"), Color("59432b"), 1, 2))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 3)
	panel.add_child(row)
	for index in range(scenario.get("tabs", []).size()):
		var tab_text := str(scenario.get("tabs", [])[index])
		var tab := UiFactory.button(tab_text, Vector2(102, 32), ThemeFactory.COLORS.line if index != 0 else ThemeFactory.COLORS.gold)
		tab.alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab.pressed.connect(_on_tab_pressed.bind(tab_text))
		row.add_child(tab)
	return panel

func _left_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(208, 0)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color("15110e"), Color("654a2f"), 1, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)
	box.add_child(UiFactory.section_label("朝廷诸司 / 行政"))
	for admin in scenario.get("administration", []):
		box.add_child(_admin_row(admin))
	box.add_child(UiFactory.section_label("在京重要人物"))
	for person in scenario.get("people", []):
		box.add_child(_person_row(person))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	var back := UiFactory.button("⌂  返回忘川", Vector2(0, 42), ThemeFactory.COLORS.line)
	back.alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.pressed.connect(func(): route_requested.emit("hub"))
	box.add_child(back)
	return panel

func _admin_row(admin: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 38)
	row.add_theme_constant_override("separation", 7)
	var portrait := Label.new()
	portrait.text = "●"
	portrait.custom_minimum_size = Vector2(22, 0)
	portrait.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.add_theme_color_override("font_color", ThemeFactory.COLORS.bright)
	row.add_child(portrait)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_child(UiFactory.label(str(admin.get("label", "机构")), 12, ThemeFactory.COLORS.ink))
	text_box.add_child(UiFactory.label(str(admin.get("role", "")), 9, ThemeFactory.COLORS.muted))
	row.add_child(text_box)
	var status := str(admin.get("status", "active"))
	var icon := UiFactory.label("!" if status == "warning" else "×" if status == "strained" else "·", 15, ThemeFactory.COLORS.ember if status in ["warning", "strained"] else ThemeFactory.COLORS.faint)
	row.add_child(icon)
	return row

func _person_row(person: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 34)
	row.add_theme_constant_override("separation", 7)
	var portrait := Label.new()
	portrait.text = "◉"
	portrait.custom_minimum_size = Vector2(22, 0)
	portrait.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait.add_theme_color_override("font_color", ThemeFactory.COLORS.muted)
	row.add_child(portrait)
	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_child(UiFactory.label(str(person.get("name", "人物")), 11, ThemeFactory.COLORS.ink))
	text_box.add_child(UiFactory.label(str(person.get("role", "")), 9, ThemeFactory.COLORS.muted))
	row.add_child(text_box)
	row.add_child(UiFactory.label("忠 %d" % int(person.get("loyalty", 0)), 10, ThemeFactory.COLORS.gold if int(person.get("loyalty", 0)) >= 50 else ThemeFactory.COLORS.ember))
	return row

func _map_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.08, 0.06, 0.045, 0.22), ThemeFactory.COLORS.bright, 1, 2))
	var map_root := Control.new()
	panel.add_child(map_root)
	map_texture = TextureRect.new()
	map_texture.texture = load(str(scenario.get("map_asset", "")))
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	map_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_root.add_child(map_texture)
	map_overlay = MapOverlay.new()
	map_overlay.set_markers(scenario.get("map_markers", []))
	map_root.add_child(map_overlay)
	investigation_overlay = InvestigationOverlay.new()
	investigation_overlay.set_hotspots(_get_investigations())
	investigation_overlay.investigation_requested.connect(_on_investigation_requested)
	map_root.add_child(investigation_overlay)
	var target := PanelContainer.new()
	target.position = Vector2(18, 18)
	target.custom_minimum_size = Vector2(270, 92)
	target.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.06, 0.04, 0.03, 0.92), ThemeFactory.COLORS.bright, 1, 2))
	map_root.add_child(target)
	var target_box := VBoxContainer.new()
	target_box.add_theme_constant_override("separation", 4)
	target.add_child(target_box)
	target_box.add_child(UiFactory.section_label("当前目标 / OBJECTIVE"))
	target_box.add_child(UiFactory.label(str(scenario.get("objective", {}).get("title", "守住内城至子时")), 16, ThemeFactory.COLORS.ink))
	objective_detail_label = UiFactory.label("□ %s    %s" % [str(scenario.get("objective", {}).get("detail", "调查异常")), str(scenario.get("objective", {}).get("days", "今夜"))], 10, ThemeFactory.COLORS.muted)
	target_box.add_child(objective_detail_label)
	investigation_card = _investigation_card()
	investigation_card.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	investigation_card.position = Vector2(-370, 18)
	investigation_card.visible = false
	map_root.add_child(investigation_card)
	final_box = _final_action_box()
	final_box.position = Vector2(18, 122)
	final_box.visible = false
	map_root.add_child(final_box)
	log_label = UiFactory.label("SYSTEM / 23:47    外城火线后移。", 11, ThemeFactory.COLORS.muted)
	log_label.position = Vector2(18, 0)
	log_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	log_label.position = Vector2(18, -34)
	map_root.add_child(log_label)
	return panel

func _investigation_card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(352, 226)
	var card_style := ThemeFactory.panel_style(Color(0.042, 0.029, 0.021, 0.965), Color(0.49, 0.34, 0.20, 0.92), 1, 2)
	card_style.content_margin_left = 18
	card_style.content_margin_right = 18
	card_style.content_margin_top = 15
	card_style.content_margin_bottom = 15
	panel.add_theme_stylebox_override("panel", card_style)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)

	var header := HBoxContainer.new()
	investigation_status = UiFactory.label("TRACE / 未记录", 10, ThemeFactory.COLORS.muted)
	header.add_child(investigation_status)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close := UiFactory.button("收起", Vector2(54, 26), ThemeFactory.COLORS.line)
	close.alignment = HORIZONTAL_ALIGNMENT_CENTER
	close.add_theme_font_size_override("font_size", 10)
	close.pressed.connect(func(): panel.visible = false)
	header.add_child(close)
	box.add_child(header)

	investigation_title = UiFactory.label("", 20, ThemeFactory.COLORS.gold)
	investigation_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	box.add_child(investigation_title)
	investigation_meta = UiFactory.label("", 9, ThemeFactory.COLORS.faint)
	box.add_child(investigation_meta)

	var rule := HSeparator.new()
	rule.add_theme_stylebox_override("separator", ThemeFactory.panel_style(Color(0, 0, 0, 0), Color(0.37, 0.27, 0.18, 0.7), 0, 0))
	box.add_child(rule)

	investigation_body = UiFactory.label("", 11, ThemeFactory.COLORS.ink)
	investigation_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	investigation_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(investigation_body)

	investigation_reward = UiFactory.label("", 10, ThemeFactory.COLORS.muted)
	investigation_reward.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(investigation_reward)
	investigation_story_button = UiFactory.button("追入回声  →", Vector2(0, 36), ThemeFactory.COLORS.gold)
	investigation_story_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	investigation_story_button.visible = false
	investigation_story_button.pressed.connect(_on_investigation_story_pressed)
	box.add_child(investigation_story_button)
	return panel

func _final_action_box() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 128)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.07, 0.035, 0.025, 0.96), ThemeFactory.COLORS.red, 1, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	box.add_child(UiFactory.section_label("终局入口 / FINAL PATHS"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	for action in scenario.get("final_actions", []):
		var button := UiFactory.button(str(action.get("label", "入口")) + "\n" + str(action.get("description", "")), Vector2(136, 62), ThemeFactory.COLORS.red)
		button.pressed.connect(_on_final_action.bind(action))
		row.add_child(button)
	box.add_child(row)
	return panel

func _right_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(250, 0)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color("15110e"), Color("654a2f"), 1, 2))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var tabs := HBoxContainer.new()
	tabs.add_child(UiFactory.label("事件", 12, ThemeFactory.COLORS.gold))
	tabs.add_child(UiFactory.label("    奏疏    记忆", 12, ThemeFactory.COLORS.muted))
	box.add_child(tabs)
	var report: Dictionary = scenario.get("initial_report", {}) as Dictionary
	var image := TextureRect.new()
	image.texture = load(str(scenario.get("vn_background", "")))
	image.custom_minimum_size = Vector2(0, 104)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate = Color(0.65, 0.48, 0.32, 1.0)
	box.add_child(image)
	box.add_child(UiFactory.label(str(report.get("title", "最新军报")), 17, ThemeFactory.COLORS.gold))
	var body := UiFactory.label(str(report.get("body", "暂无奏报。")), 12, ThemeFactory.COLORS.muted)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	for action in scenario.get("report_actions", []):
		var choice := UiFactory.button("%s\n%s" % [str(action.get("label", "行动")), str(action.get("cost", ""))], Vector2(0, 45), ThemeFactory.COLORS.line)
		choice.pressed.connect(_on_report_action.bind(action))
		box.add_child(choice)
	var companion_title := UiFactory.section_label("随行记录 / COMPANION")
	box.add_child(companion_title)
	box.add_child(UiFactory.label("执笔者\n朕只是，做错了一个选择。", 12, ThemeFactory.COLORS.ink))
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)
	box.add_child(UiFactory.section_label("记忆星图 / MEMORY"))
	memory_list_box = VBoxContainer.new()
	memory_list_box.add_theme_constant_override("separation", 3)
	box.add_child(memory_list_box)
	_refresh_memory_list()
	var open_memory := UiFactory.button("记忆星图  /  CONSTELLATION  →", Vector2(0, 34), ThemeFactory.COLORS.line)
	open_memory.alignment = HORIZONTAL_ALIGNMENT_CENTER
	open_memory.add_theme_font_size_override("font_size", 10)
	open_memory.pressed.connect(_open_memory_view)
	box.add_child(open_memory)
	return panel

func _bottom_command_bar() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 104)
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color("100c09"), Color("6f4d2d"), 1, 2))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	panel.add_child(row)
	for module in scenario.get("modules", []):
		var module_id := str(module.get("id", ""))
		var button := UiFactory.button("%s\n%s" % [str(module.get("icon", "·")), str(module.get("label", "模块"))], Vector2(94, 78), ThemeFactory.COLORS.line)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.tooltip_text = str(module.get("description", ""))
		button.pressed.connect(_on_module_pressed.bind(module_id))
		command_buttons[module_id] = button
		row.add_child(button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var advance := UiFactory.button("⌛  推进时间", Vector2(188, 78), ThemeFactory.COLORS.bright)
	advance.alignment = HORIZONTAL_ALIGNMENT_CENTER
	advance.name = "TimeControl"
	advance.pressed.connect(_on_advance_time)
	command_buttons["advance_history"] = advance
	row.add_child(advance)
	return panel

func _status_for(module: Dictionary) -> String:
	var result := "active"
	for rule in module.get("status_rules", []):
		if progress >= float(rule.get("at", 0)):
			result = str(rule.get("status", result))
	if RulePatchSystem.is_disabled(str(module.get("id", ""))):
		result = "disabled"
	return result

func _refresh() -> void:
	progress = AppState.get_progress()
	if progress_value_label:
		progress_value_label.text = "%02d%%" % int(progress)
	if map_texture:
		var shade := 1.0 - progress * 0.002
		map_texture.modulate = Color(shade, shade * 0.96, shade * 0.90, 1.0)
	if map_overlay:
		map_overlay.set_progress(progress)
	if investigation_overlay:
		investigation_overlay.refresh_states()
	_refresh_memory_list()
	_refresh_objective()
	for module in scenario.get("modules", []):
		var module_id := str(module.get("id", ""))
		if not command_buttons.has(module_id):
			continue
		var status := _status_for(module)
		var button: Button = command_buttons[module_id]
		button.disabled = status in ["disabled", "locked"]
		button.text = "%s\n%s\n%s" % [str(module.get("icon", "·")), str(module.get("label", "模块")), _status_text(status)]
		button.add_theme_stylebox_override("normal", ThemeFactory.button_style(ThemeFactory.COLORS.raised, ThemeFactory.COLORS.red if status == "warning" else ThemeFactory.COLORS.gold if status == "active" else ThemeFactory.COLORS.line))
	if command_buttons.has("advance_history"):
		command_buttons["advance_history"].disabled = RulePatchSystem.is_disabled("advance_history")
	if final_box:
		final_box.visible = progress >= 100.0

func _status_text(status: String) -> String:
	match status:
		"active": return "可用"
		"warning": return "警戒"
		"disabled": return "熄灭"
		"locked": return "锁定"
	return status

func _on_tab_pressed(tab_text: String) -> void:
	_show_log("SYSTEM / TAB    当前查看：" + tab_text)

func _on_module_pressed(module_id: String) -> void:
	var module := _find_module(module_id)
	if module.is_empty():
		return
	if _status_for(module) in ["disabled", "locked"]:
		_show_log("SYSTEM / RULE PATCH    模块「%s」已不再回应。" % str(module.get("label", module_id)))
		return
	AppState.set_flag("module_seen:" + module_id, true)
	_show_log("SYSTEM / MODULE    %s：%s" % [str(module.get("label", module_id)), str(module.get("action", "已查看"))])
	var phenomenon_id := str(module.get("phenomenon_id", ""))
	if not phenomenon_id.is_empty():
		AnomalyRuntime.play(phenomenon_id, {"module_id": module_id})

func _on_report_action(action: Dictionary) -> void:
	_show_log("REPORT / ACTION    %s" % str(action.get("label", "行动已记录")))
	var phenomenon_id := str(action.get("phenomenon_id", ""))
	if not phenomenon_id.is_empty():
		AnomalyRuntime.play(phenomenon_id, {"report_action_id": str(action.get("id", ""))})

func _on_advance_time() -> void:
	if RulePatchSystem.is_disabled("advance_history"):
		_show_log("SYSTEM / HISTORY    时间不再接受推进。")
		return
	var old_progress := progress
	var next_progress := minf(progress + 20.0, 100.0)
	AppState.set_progress(next_progress)
	for event in scenario.get("progress_events", []):
		var threshold := float(event.get("at", 100.0))
		if threshold > old_progress and threshold <= next_progress:
			if event.has("patch_id"):
				RulePatchSystem.apply_from_pack(str(event.get("patch_id", "")))
			if event.has("phenomenon"):
				AnomalyRuntime.play(str(event.get("phenomenon", "")))
			_show_log("HISTORY / %s" % str(event.get("message", "阶段推进")))
	_refresh()

func _on_final_action(action: Dictionary) -> void:
	AppState.set_flag("final_action:" + str(action.get("id", "")), true)
	story_requested.emit(str(action.get("story_id", "story_last_edict")))

func _get_investigations() -> Array:
	var result: Array = []
	for investigation_id in scenario.get("investigation_ids", []):
		var definition := PackLoader.find("investigations", str(investigation_id))
		if not definition.is_empty():
			result.append(definition)
	for local_definition in scenario.get("investigations", []):
		if local_definition is Dictionary:
			result.append(local_definition)
	return result

func _find_investigation(investigation_id: String) -> Dictionary:
	var from_pack := PackLoader.find("investigations", investigation_id)
	if not from_pack.is_empty():
		return from_pack
	for definition in scenario.get("investigations", []):
		if definition is Dictionary and str(definition.get("id", "")) == investigation_id:
			return definition
	return {}

func _investigation_requirements_met(definition: Dictionary) -> bool:
	for memory_id in definition.get("requires_memories", []):
		if not AppState.has_memory(str(memory_id)):
			return false
	for flag_id in definition.get("requires_flags", []):
		if not AppState.get_flag(str(flag_id)):
			return false
	return true

func _on_investigation_requested(investigation_id: String) -> void:
	var definition := _find_investigation(investigation_id)
	if definition.is_empty():
		_show_log("INVESTIGATION / ERROR    未找到调查定义：" + investigation_id)
		return
	if not _investigation_requirements_met(definition):
		_show_log("INVESTIGATION / LOCKED    线索尚未闭合。先调查其他异常点。")
		return

	active_investigation = definition
	var flag_id := "investigation:" + investigation_id
	var first_visit := not AppState.get_flag(flag_id)
	if first_visit:
		AppState.set_flag(flag_id, true)
		var memory_id := str(definition.get("memory_id", ""))
		if not memory_id.is_empty():
			MemorySystem.unlock(memory_id)
			var memory := PackLoader.find("memories", memory_id)
			CeremonyBus.emit_step({
				"channel": "text",
				"effect": "text_flash",
				"text": "MEMORY RECORDED · " + str(memory.get("title", memory_id)),
				"duration": 0.92
			})
			CeremonyBus.emit_step({"channel": "scene_overlay", "effect": "flash", "strength": 0.12, "duration": 0.18})
		AppState.save_state()
		var phenomenon_id := str(definition.get("phenomenon_id", ""))
		if not phenomenon_id.is_empty():
			AnomalyRuntime.play(phenomenon_id, {"investigation_id": investigation_id})
		_show_log("INVESTIGATION / RECORDED    %s" % str(definition.get("label", definition.get("title", investigation_id))))
	else:
		_show_log("INVESTIGATION / REVISIT    已记录：%s" % str(definition.get("label", definition.get("title", investigation_id))))

	_present_investigation(definition, first_visit)
	_refresh()
	_check_objective_completion()

func _present_investigation(definition: Dictionary, first_visit: bool) -> void:
	if not investigation_card:
		return
	investigation_card.visible = true
	investigation_title.text = str(definition.get("title", definition.get("label", "调查")))
	investigation_body.text = str(definition.get("description", "没有留下可辨认的记录。"))

	var memory_id := str(definition.get("memory_id", ""))
	var memory := PackLoader.find("memories", memory_id) if not memory_id.is_empty() else {}
	var is_anomaly := not str(definition.get("phenomenon_id", "")).is_empty()
	var trace_kind := "ANOMALY TRACE" if is_anomaly else "HISTORICAL TRACE"
	investigation_status.text = "%s / %s" % [trace_kind, "NEW" if first_visit else "ARCHIVED"]
	investigation_status.add_theme_color_override("font_color", ThemeFactory.COLORS.ember if is_anomaly and first_visit else ThemeFactory.COLORS.gold if first_visit else ThemeFactory.COLORS.teal)

	if memory.is_empty():
		investigation_meta.text = "记录状态 · %s" % ("首次观测" if first_visit else "已归档")
		investigation_reward.text = "没有可独立归档的 Memory。"
	else:
		var rarity := _memory_rarity_label(str(memory.get("rarity", "record")))
		investigation_meta.text = "%s  ·  %s  ·  %s" % [str(memory.get("date", "时间不明")), rarity, "RESONANCE" if is_anomaly else "RECORD"]
		var prefix := "新 Memory 已写入忘川" if first_visit else "Memory 已收录"
		var quote := str(memory.get("quote", ""))
		investigation_reward.text = "%s  /  %s%s" % [prefix, str(memory.get("title", memory_id)), "\n“%s”" % quote if not quote.is_empty() else ""]
		investigation_reward.add_theme_color_override("font_color", ThemeFactory.COLORS.gold if first_visit else ThemeFactory.COLORS.muted)

	var story_id := str(definition.get("story_id", ""))
	investigation_story_button.visible = not story_id.is_empty()
	if investigation_story_button.visible:
		investigation_story_button.text = str(definition.get("story_label", "进入回声")) + "  →"

	investigation_card.pivot_offset = Vector2(investigation_card.custom_minimum_size.x, 0)
	investigation_card.scale = Vector2(0.985, 0.985)
	investigation_card.modulate = Color(1, 1, 1, 0.0)
	var reveal := create_tween().set_parallel(true)
	reveal.tween_property(investigation_card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	reveal.tween_property(investigation_card, "modulate", Color.WHITE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_investigation_story_pressed() -> void:
	if active_investigation.is_empty():
		return
	var story_id := str(active_investigation.get("story_id", ""))
	if not story_id.is_empty():
		story_requested.emit(story_id)

func _refresh_memory_list() -> void:
	if not memory_list_box:
		return
	UiFactory.clear_children(memory_list_box)
	var memories := MemorySystem.get_unlocked_definitions()
	if memories.is_empty():
		memory_list_box.add_child(UiFactory.label("◇  尚无历史回声", 11, ThemeFactory.COLORS.faint))
		memory_list_box.add_child(UiFactory.label("地图上的微光并非普通地标。", 9, ThemeFactory.COLORS.muted))
		return
	var start_index := maxi(memories.size() - 4, 0)
	for index in range(start_index, memories.size()):
		var memory: Dictionary = memories[index]
		memory_list_box.add_child(_memory_row(memory))

func _memory_row(memory: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", ThemeFactory.panel_style(Color(0.065, 0.048, 0.036, 0.72), Color(0.30, 0.23, 0.16, 0.62), 1, 1))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 7)
	panel.add_child(row)
	var glyph := UiFactory.label("◇" if str(memory.get("rarity", "record")) == "anomaly" else "▣", 13, ThemeFactory.COLORS.teal if str(memory.get("rarity", "record")) == "anomaly" else ThemeFactory.COLORS.gold)
	glyph.custom_minimum_size = Vector2(18, 0)
	row.add_child(glyph)
	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 0)
	text.add_child(UiFactory.label(str(memory.get("title", "记忆")), 10, ThemeFactory.COLORS.ink))
	text.add_child(UiFactory.label(_memory_rarity_label(str(memory.get("rarity", "record"))) + " · " + str(memory.get("date", "时间不明")), 8, ThemeFactory.COLORS.faint))
	row.add_child(text)
	return panel

func _memory_rarity_label(rarity: String) -> String:
	match rarity:
		"anomaly": return "异象记录"
		"trace": return "历史残片"
		"record": return "史实记录"
		"rare": return "稀有记忆"
		_: return rarity.to_upper()

func _refresh_objective() -> void:
	if not objective_detail_label:
		return
	var objective: Dictionary = scenario.get("objective", {})
	if str(objective.get("mode", "")) != "investigation":
		objective_detail_label.text = "□ %s    %s" % [str(objective.get("detail", "")), str(objective.get("days", ""))]
		return
	var investigations := _get_investigations()
	var completed := 0
	for definition in investigations:
		if definition is Dictionary and AppState.get_flag("investigation:" + str(definition.get("id", ""))):
			completed += 1
	var target_count := int(objective.get("target_count", investigations.size()))
	var marker := "▣" if completed >= target_count else "□"
	if completed >= target_count and not str(objective.get("complete_text", "")).is_empty():
		objective_detail_label.text = marker + " " + str(objective.get("complete_text", ""))
	else:
		objective_detail_label.text = "%s 调查进度 %d / %d    %s" % [marker, completed, target_count, str(objective.get("days", "今夜"))]
	objective_detail_label.add_theme_color_override("font_color", ThemeFactory.COLORS.gold if completed >= target_count else ThemeFactory.COLORS.muted)

func _check_objective_completion() -> void:
	var objective: Dictionary = scenario.get("objective", {})
	if str(objective.get("mode", "")) != "investigation":
		return
	var investigations := _get_investigations()
	var target_count := int(objective.get("target_count", investigations.size()))
	var completed := 0
	for definition in investigations:
		if definition is Dictionary and AppState.get_flag("investigation:" + str(definition.get("id", ""))):
			completed += 1
	if completed < target_count:
		return
	var completion: Dictionary = objective.get("completion", {})
	var flag_id := str(completion.get("flag_id", "objective:" + scenario_id + ":complete"))
	if AppState.get_flag(flag_id):
		return
	AppState.set_flag(flag_id, true)
	AppState.save_state()
	var flash_text := str(completion.get("flash_text", "OBJECTIVE COMPLETE"))
	if not flash_text.is_empty():
		CeremonyBus.emit_step({"channel": "text", "effect": "text_flash", "text": flash_text, "duration": 1.15})
	var message := str(completion.get("message", "调查链已闭合。"))
	if not message.is_empty():
		_show_log("OBJECTIVE / COMPLETE    " + message)

func _open_memory_view() -> void:
	AppState.data["memory_return_route"] = "workbench"
	route_requested.emit("memory")

func _find_module(module_id: String) -> Dictionary:
	for module in scenario.get("modules", []):
		if str(module.get("id", "")) == module_id:
			return module
	return {}

func _show_log(text: String) -> void:
	if log_label:
		log_label.text = text
