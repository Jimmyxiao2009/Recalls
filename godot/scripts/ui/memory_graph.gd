class_name MemoryGraph
extends Control

signal memory_selected(memory_id: String)

var memories: Dictionary = {}
var order: Array = []
var selected_id := ""
var hover_id := ""
var pulse := 0.0

func _ready() -> void:
    custom_minimum_size = Vector2(560, 420)
    mouse_filter = Control.MOUSE_FILTER_STOP
    mouse_default_cursor_shape = Control.CURSOR_ARROW
    set_process(true)

func set_memories(items: Array) -> void:
    memories.clear()
    order.clear()
    for item in items:
        if not item is Dictionary:
            continue
        var memory_id := str(item.get("id", ""))
        if memory_id.is_empty():
            continue
        memories[memory_id] = item
        order.append(memory_id)
    if selected_id.is_empty() or not memories.has(selected_id):
        selected_id = str(order[0]) if not order.is_empty() else ""
    queue_redraw()

func select(memory_id: String) -> void:
    if memories.has(memory_id):
        selected_id = memory_id
        queue_redraw()

func _process(delta: float) -> void:
    pulse = fmod(pulse + delta, TAU)
    queue_redraw()

func _gui_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        var next_hover := _hit_test(event.position)
        if next_hover != hover_id:
            hover_id = next_hover
            mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not hover_id.is_empty() else Control.CURSOR_ARROW
            queue_redraw()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        var hit := _hit_test(event.position)
        if not hit.is_empty():
            accept_event()
            selected_id = hit
            memory_selected.emit(hit)
            queue_redraw()

func _hit_test(point: Vector2) -> String:
    for index in range(order.size() - 1, -1, -1):
        var memory_id := str(order[index])
        var position := _node_position(memories[memory_id], index)
        if point.distance_to(position) <= 28.0:
            return memory_id
    return ""

func _node_position(memory: Dictionary, index: int) -> Vector2:
    var margin := Vector2(74, 62)
    var usable := Vector2(maxf(size.x - margin.x * 2.0, 1.0), maxf(size.y - margin.y * 2.0, 1.0))
    var data: Array = memory.get("graph_position", [])
    if data.size() >= 2:
        return margin + Vector2(clampf(float(data[0]), 0.0, 1.0) * usable.x, clampf(float(data[1]), 0.0, 1.0) * usable.y)
    var count := maxi(order.size(), 1)
    var angle := -PI * 0.5 + TAU * float(index) / float(count)
    return size * 0.5 + Vector2(cos(angle), sin(angle)) * minf(size.x, size.y) * 0.28

func _relation_color(kind: String) -> Color:
    match kind:
        "resonance": return ThemeFactory.COLORS.teal
        "terminal": return ThemeFactory.COLORS.red
        "evidence": return ThemeFactory.COLORS.gold
        _: return ThemeFactory.COLORS.line

func _memory_color(memory: Dictionary) -> Color:
    match str(memory.get("rarity", "record")):
        "anomaly": return ThemeFactory.COLORS.teal
        "trace": return ThemeFactory.COLORS.gold
        "rare": return ThemeFactory.COLORS.ember
        _: return ThemeFactory.COLORS.bright

func _draw() -> void:
    _draw_field()
    if order.is_empty():
        var center := size * 0.5
        draw_string(ThemeDB.fallback_font, center + Vector2(-130, -4), "NO ARCHIVED ECHOES", HORIZONTAL_ALIGNMENT_CENTER, 260, 13, Color(ThemeFactory.COLORS.faint, 0.72))
        draw_string(ThemeDB.fallback_font, center + Vector2(-150, 18), "历史现场中的未观测节点不会显示坐标", HORIZONTAL_ALIGNMENT_CENTER, 300, 9, Color(ThemeFactory.COLORS.faint, 0.48))
        return
    _draw_links()
    _draw_nodes()

func _draw_field() -> void:
    var field_color := Color(ThemeFactory.COLORS.line, 0.10)
    for x in range(1, 6):
        var px := size.x * float(x) / 6.0
        draw_line(Vector2(px, 18), Vector2(px, size.y - 18), field_color, 1.0)
    for y in range(1, 4):
        var py := size.y * float(y) / 4.0
        draw_line(Vector2(18, py), Vector2(size.x - 18, py), field_color, 1.0)
    var center := size * 0.5
    draw_circle(center, minf(size.x, size.y) * 0.32, Color(ThemeFactory.COLORS.line, 0.08), false, 1.0)
    draw_circle(center, minf(size.x, size.y) * 0.18, Color(ThemeFactory.COLORS.line, 0.06), false, 1.0)

func _draw_links() -> void:
    var drawn: Dictionary = {}
    for source_id in order:
        var source: Dictionary = memories[source_id]
        var source_pos := _node_position(source, order.find(source_id))
        for raw_link in source.get("links", []):
            if not raw_link is Dictionary:
                continue
            var target_id := str(raw_link.get("to", ""))
            if not memories.has(target_id):
                continue
            var pair := [str(source_id), target_id]
            pair.sort()
            var key: String = str(pair[0]) + "|" + str(pair[1])
            if drawn.has(key):
                continue
            drawn[key] = true
            var target: Dictionary = memories[target_id]
            var target_pos := _node_position(target, order.find(target_id))
            var kind := str(raw_link.get("kind", "relation"))
            var color := _relation_color(kind)
            var emphasized := selected_id in [str(source_id), target_id] or hover_id in [str(source_id), target_id]
            var alpha := 0.68 if emphasized else 0.30
            var width := 2.0 if emphasized else 1.0
            draw_line(source_pos, target_pos, Color(color, alpha), width, true)
            var direction := (target_pos - source_pos).normalized()
            var midpoint := source_pos.lerp(target_pos, 0.5)
            var normal := Vector2(-direction.y, direction.x)
            draw_circle(midpoint, 2.0, Color(color, alpha * 0.9))
            if emphasized:
                var relation_label := str(raw_link.get("label", ""))
                if not relation_label.is_empty():
                    draw_string(ThemeDB.fallback_font, midpoint + normal * 13.0 + Vector2(-58, 4), relation_label, HORIZONTAL_ALIGNMENT_CENTER, 116, 9, Color(color, 0.82))

func _draw_nodes() -> void:
    var breath := (sin(pulse * 1.8) + 1.0) * 0.5
    for index in range(order.size()):
        var memory_id := str(order[index])
        var memory: Dictionary = memories[memory_id]
        var point := _node_position(memory, index)
        var color := _memory_color(memory)
        var selected := memory_id == selected_id
        var hovered := memory_id == hover_id
        if selected:
            draw_circle(point, 29.0 + breath * 3.0, Color(color, 0.08 + breath * 0.05), false, 1.0)
            draw_circle(point, 22.0, Color(color, 0.28), false, 1.0)
        elif hovered:
            draw_circle(point, 24.0, Color(color, 0.16), false, 1.0)
        else:
            draw_circle(point, 19.0, Color(color, 0.11), false, 1.0)

        var radius := 8.0 if selected else 7.0
        if str(memory.get("rarity", "record")) == "anomaly":
            var diamond := PackedVector2Array([
                point + Vector2(0, -radius),
                point + Vector2(radius, 0),
                point + Vector2(0, radius),
                point + Vector2(-radius, 0)
            ])
            draw_colored_polygon(diamond, Color(color, 0.88 if selected or hovered else 0.64))
            draw_circle(point, 2.0, Color(0.035, 0.025, 0.02, 0.95))
        else:
            draw_circle(point, radius, Color(color, 0.82 if selected or hovered else 0.58))
            draw_circle(point, radius - 3.0, Color(0.035, 0.025, 0.02, 0.95))

        var title := str(memory.get("title", "Memory"))
        draw_string(ThemeDB.fallback_font, point + Vector2(-72, 31), title, HORIZONTAL_ALIGNMENT_CENTER, 144, 11 if selected or hovered else 10, Color(ThemeFactory.COLORS.ink, 0.92 if selected or hovered else 0.56))
        if selected:
            draw_string(ThemeDB.fallback_font, point + Vector2(-72, 46), str(memory.get("date", "")), HORIZONTAL_ALIGNMENT_CENTER, 144, 8, Color(ThemeFactory.COLORS.muted, 0.72))
