extends Node

signal reaction_triggered(text: String, category: String)

var _generic_lines: Dictionary = {}
var _lines: Dictionary = {}

func _ready() -> void:
	_generic_lines = _load_json("res://data/dialogue/generic_reactions.json")

func connect_game(game: Node) -> void:
	if game.has_signal("move_evaluated"):
		game.move_evaluated.connect(_on_move_evaluated)
	_build_lines(game.get("level_id") if game.get("level_id") else "")

func _build_lines(p_level_id: String) -> void:
	_lines = _generic_lines.duplicate(true)
	if p_level_id.is_empty():
		return
	var path := "res://data/dialogue/%s_reactions.json" % p_level_id
	if ResourceLoader.exists(path):
		_merge_into(_lines, _load_json(path))

func _merge_into(base: Dictionary, overlay: Dictionary) -> void:
	for key in overlay:
		if base.has(key) and base[key] is Array and overlay[key] is Array:
			base[key] = base[key] + overlay[key]
		else:
			base[key] = overlay[key]

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("ReactionManager: could not open %s" % path)
		return {}
	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if result is Dictionary:
		return result
	push_error("ReactionManager: failed to parse %s" % path)
	return {}

func _on_move_evaluated(_cell_index: int, category: String) -> void:
	trigger(category)

func trigger(category: String) -> void:
	if not _lines.has(category):
		return
	var pool: Array = _lines[category]
	if pool.is_empty():
		return
	var text: String = pool[randi() % pool.size()]
	reaction_triggered.emit(text, category)
