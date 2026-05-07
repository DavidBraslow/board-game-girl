extends Node

const SAVE_PATH := "user://save.json"

var _data: Dictionary = {}

func _ready() -> void:
	load_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = _default_data()
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("SaveSystem: could not open %s for reading" % SAVE_PATH)
		_data = _default_data()
		return
	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if result is Dictionary:
		_data = result
	else:
		push_error("SaveSystem: failed to parse save file — resetting to defaults")
		_data = _default_data()

func save_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("SaveSystem: could not open %s for writing" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()

func is_level_complete(level_name: String) -> bool:
	return level_name in _get_array("completed")

func mark_level_complete(level_name: String) -> void:
	var completed: Array = _get_array("completed")
	if level_name not in completed:
		completed.append(level_name)
		_data["completed"] = completed
		save_game()

func is_level_unlocked(level_name: String) -> bool:
	return level_name in _get_array("unlocked")

func mark_level_unlocked(level_name: String) -> void:
	var unlocked: Array = _get_array("unlocked")
	if level_name not in unlocked:
		unlocked.append(level_name)
		_data["unlocked"] = unlocked
		save_game()

func _get_array(key: String) -> Array:
	if _data.has(key) and _data[key] is Array:
		return _data[key]
	return []

func _default_data() -> Dictionary:
	return {
		"completed": [],
		"unlocked": ["tictactoe"],
	}
