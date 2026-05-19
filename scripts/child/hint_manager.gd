extends Node

const TIER_1_WRONG_MOVES     := 3
const TIER_1_INACTIVITY_SECS := 60.0
const TIER_2_WRONG_MOVES     := 3
const TIER_3_TOTAL_SECS      := 180.0
const GUIDANCE_WRONG_MOVES       := 5
const GUIDANCE_RETRY_WRONG_MOVES := 3

signal hint_triggered(text: String, tier: int, variant: String)
signal guidance_offer_made
signal guidance_started
signal guidance_ended(reason: String)
signal guided_move_offer_made

var _generic_hints: Dictionary = {}
var _hints: Dictionary = {}
var _current_tier: int = 0
var _total_wrong_moves: int = 0
var _wrong_moves_this_tier: int = 0
var _last_wrong_cell: int = -1
var _same_mistake_count: int = 0
var _last_move_category: String = ""
var _guidance_active: bool = false

var _inactivity_timer: Timer
var _session_timer: Timer

func _ready() -> void:
	_generic_hints = _load_json("res://data/dialogue/generic_hints.json")
	_setup_timers()

func connect_game(game: Node) -> void:
	if game.has_signal("move_made"):
		game.move_made.connect(_on_move_made)
	if game.has_signal("move_evaluated"):
		game.move_evaluated.connect(_on_move_evaluated)
	_build_hints(game.get("level_id") if game.get("level_id") else "")
	_inactivity_timer.start()
	_session_timer.start()

func _build_hints(p_level_id: String) -> void:
	_hints = _generic_hints.duplicate(true)
	if p_level_id.is_empty():
		return
	var path := "res://data/dialogue/%s_hints.json" % p_level_id
	if ResourceLoader.exists(path):
		_merge_into(_hints, _load_json(path))

func _merge_into(base: Dictionary, overlay: Dictionary) -> void:
	for key in overlay:
		if base.has(key):
			if base[key] is Dictionary and overlay[key] is Dictionary:
				_merge_into(base[key], overlay[key])
			elif base[key] is Array and overlay[key] is Array:
				base[key] = base[key] + overlay[key]
		else:
			base[key] = overlay[key]

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("HintManager: could not open %s" % path)
		return {}
	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if result is Dictionary:
		return result
	push_error("HintManager: failed to parse %s" % path)
	return {}

func _setup_timers() -> void:
	_inactivity_timer = Timer.new()
	_inactivity_timer.wait_time = TIER_1_INACTIVITY_SECS
	_inactivity_timer.one_shot = true
	_inactivity_timer.timeout.connect(_on_inactivity_timeout)
	add_child(_inactivity_timer)

	_session_timer = Timer.new()
	_session_timer.wait_time = TIER_3_TOTAL_SECS
	_session_timer.one_shot = true
	_session_timer.timeout.connect(_on_session_timeout)
	add_child(_session_timer)

func _on_move_made(_cell_index: int, player_type: int) -> void:
	if player_type == 1:
		_inactivity_timer.start()

func _on_move_evaluated(cell_index: int, category: String) -> void:
	_last_move_category = category

	if category == "game_complete":
		_reset()
		return

	if category in ["correct", "near_win", "correct_late"]:
		_reset_tier()
		return

	if category in ["wrong_move", "cool"]:
		_handle_failed_move(cell_index)
		return

	push_warning("HintManager: unrecognized move category '%s'" % category)

func _handle_failed_move(cell_index: int) -> void:
	if _guidance_active:
		return

	if cell_index == _last_wrong_cell:
		_same_mistake_count += 1
	else:
		_same_mistake_count = 1
		_last_wrong_cell = cell_index

	_total_wrong_moves += 1
	_wrong_moves_this_tier += 1

	if _current_tier < 3 and _total_wrong_moves >= GUIDANCE_WRONG_MOVES:
		_fire_tier_3()
		return

	if _same_mistake_count >= 2 and _current_tier >= 1:
		_fire_tier_2("same_mistake_twice")
		return

	match _current_tier:
		0:
			if _wrong_moves_this_tier >= TIER_1_WRONG_MOVES:
				_fire_tier_1("wrong_moves")
		1:
			if _wrong_moves_this_tier >= TIER_2_WRONG_MOVES:
				var variant := "cool" if _last_move_category == "cool" else "cold"
				_fire_tier_2(variant)

func _fire_tier_1(variant: String) -> void:
	_current_tier = 1
	_wrong_moves_this_tier = 0
	_emit_hint(["tier_1", variant], 1, variant)

func _fire_tier_2(variant: String) -> void:
	_current_tier = 2
	_wrong_moves_this_tier = 0
	_emit_hint(["tier_2", variant], 2, variant)

func _fire_tier_3() -> void:
	_current_tier = 3
	var offer_text := _get_line(["tier_3", "offer"])
	if offer_text:
		hint_triggered.emit(offer_text, 3, "offer")
	guidance_offer_made.emit()

func _on_inactivity_timeout() -> void:
	if _current_tier == 0 and not _guidance_active:
		_fire_tier_1("time")

func _on_session_timeout() -> void:
	if _current_tier < 3 and not _guidance_active:
		_fire_tier_3()

func make_guided_move_offer() -> void:
	_emit_hint(["guided_move", "offer"], 4, "guided_move_offer")
	guided_move_offer_made.emit()

func accept_guidance() -> void:
	_guidance_active = true
	guidance_started.emit()

func decline_guidance() -> void:
	_emit_hint(["tier_3", "declined"], 3, "declined")

func exit_guidance(was_correct: bool) -> void:
	_guidance_active = false
	_current_tier = 0
	_total_wrong_moves = GUIDANCE_WRONG_MOVES - GUIDANCE_RETRY_WRONG_MOVES
	_wrong_moves_this_tier = 0
	_last_wrong_cell = -1
	_same_mistake_count = 0
	var variant := "exit_early_right" if was_correct else "exit_early_wrong"
	_emit_hint(["tier_4", variant], 4, variant)
	guidance_ended.emit("exit_right" if was_correct else "exit_wrong")

func complete_guidance() -> void:
	_guidance_active = false
	_emit_hint(["tier_4", "completed"], 4, "completed")
	guidance_ended.emit("completed")

func reset_session() -> void:
	_inactivity_timer.stop()
	_session_timer.stop()
	_current_tier = 0
	_total_wrong_moves = 0
	_wrong_moves_this_tier = 0
	_last_wrong_cell = -1
	_same_mistake_count = 0
	_last_move_category = ""
	_guidance_active = false

func _reset() -> void:
	_total_wrong_moves = 0
	_reset_tier()

func _reset_tier() -> void:
	_current_tier = 0
	_wrong_moves_this_tier = 0
	_last_wrong_cell = -1
	_same_mistake_count = 0
	_inactivity_timer.start()

func _emit_hint(path: Array, tier: int, variant: String) -> void:
	var text := _get_line(path)
	if text:
		hint_triggered.emit(text, tier, variant)

func _get_line(path: Array) -> String:
	var data: Variant = _hints
	for key: String in path:
		if data is Dictionary and (data as Dictionary).has(key):
			data = (data as Dictionary)[key]
		else:
			return ""
	if data is Array and not (data as Array).is_empty():
		return (data as Array)[randi() % (data as Array).size()]
	return ""
