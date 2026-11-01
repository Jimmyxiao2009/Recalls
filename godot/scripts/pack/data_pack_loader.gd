extends Node

signal packs_loaded

const PACKS_ROOT := "res://packs"
const SECTIONS := ["gates", "scenarios", "stories", "memories", "phenomena", "rituals", "investigations"]

var packs: Dictionary = {}
var loaded := false

func _ready() -> void:
    call_deferred("load_all")

func load_all() -> void:
    packs.clear()
    var root := DirAccess.open(PACKS_ROOT)
    if root == null:
        loaded = true
        packs_loaded.emit()
        return
    root.list_dir_begin()
    var folder := root.get_next()
    while folder != "":
        if root.current_is_dir() and not folder.begins_with("."):
            _load_pack(PACKS_ROOT.path_join(folder))
        folder = root.get_next()
    root.list_dir_end()
    loaded = true
    packs_loaded.emit()

func _load_pack(pack_path: String) -> void:
    var manifest: Dictionary = _read_json(pack_path.path_join("manifest.json"))
    var pack_id := str(manifest.get("id", pack_path.get_file()))
    var pack: Dictionary = {"manifest": manifest}
    pack["hub"] = _read_json(pack_path.path_join("hub.json"))
    for section in SECTIONS:
        pack[section] = _load_collection(pack_path.path_join(section))
    packs[pack_id] = pack

func _load_collection(section_path: String) -> Dictionary:
    var result: Dictionary = {}
    var directory := DirAccess.open(section_path)
    if directory == null:
        return result
    directory.list_dir_begin()
    var filename := directory.get_next()
    while filename != "":
        if not directory.current_is_dir() and filename.to_lower().ends_with(".json"):
            var parsed = _read_json(section_path.path_join(filename))
            if parsed is Array:
                for item in parsed:
                    if item is Dictionary and item.has("id"):
                        result[str(item["id"])] = item
            elif parsed is Dictionary:
                if parsed.has("items") and parsed["items"] is Array:
                    for item in parsed["items"]:
                        if item is Dictionary and item.has("id"):
                            result[str(item["id"])] = item
                elif parsed.has("id"):
                    result[str(parsed["id"])] = parsed
        filename = directory.get_next()
    directory.list_dir_end()
    return result

func _read_json(path: String) -> Dictionary:
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if not file:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    return parsed if parsed is Dictionary else {}

func get_all(section: String) -> Dictionary:
    var result: Dictionary = {}
    for pack in packs.values():
        var entries: Dictionary = pack.get(section, {})
        result.merge(entries, true)
    return result

func find(section: String, entry_id: String) -> Dictionary:
    for pack in packs.values():
        var entries: Dictionary = pack.get(section, {})
        if entries.has(entry_id):
            return entries[entry_id]
    return {}

func get_hub() -> Dictionary:
    for pack in packs.values():
        var hub: Dictionary = pack.get("hub", {})
        if not hub.is_empty():
            return hub
    return {}

func get_manifest(pack_id: String) -> Dictionary:
    var pack: Dictionary = packs.get(pack_id, {})
    return pack.get("manifest", {})

func get_gate_list() -> Array:
    var gates: Array = []
    for pack in packs.values():
        for gate in pack.get("gates", {}).values():
            gates.append(gate)
    return gates
