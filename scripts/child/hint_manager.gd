# HintManager — autoload singleton.
# 4-tier progressive hint system for the child character.
#
# Tier 1: fires after 3 wrong moves OR 60 s of player inactivity
# Tier 2: fires after 3 more wrong moves, or the same wrong move twice
# Tier 3: fires after 5 more failed moves OR 3 min total elapsed —
#          presents an offer to take over (UI handles accept/decline)
# Tier 4: activates on acceptance — guidance state, exposes exit/complete methods
#
# Any correct move resets the hint system back to tier 1.

extends Node

# ---------------------------------------------------------------------------
# Thresholds
# ---------------------------------------------------------------------------

const TIER_1_WRONG_MOVES     := 3
const TIER_1_INACTIVITY_SECS := 60.0
const TIER_2_WRONG_MOVES     := 3
const TIER_3_FAILED_MOVES    := 5
const TIER_3_TOTAL_SECS      := 180.0

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

# A hint line is ready to display.
signal hint_triggered(text: String, tier: int, variant: String)

# Tier 3 fired — the UI should show an accept/decline prompt,
# then call accept_guidance() or decline_guidance().
signal guidance_offer_made

# Player accepted; tier 4 is now active.
signal guidance_started

# Guidance ended. reason: "exit_right", "exit_wrong", or "completed"
signal guidance_ended(reason: String)

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

var _hints: Dictionary = {}
var _current_tier: int = 0
var _wrong_moves_this_tier: int = 0
var _last_wrong_cell: int = -1
var _same_mistake_count: int = 0
var _last_move_category: String = ""
var _guidance_active: bool = false

var _inactivity_timer: Timer
var _session_timer: Timer

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_load_hints()
	_setup_timers()

func _load_hints() -> void:
	var file := FileAccess.open("res://data/dialogue/tictactoe_hints.json", FileAccess.READ)
	if not file:
		push_error("HintManager: could not open tictactoe_hints.json")
		return
	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if result is Dictionary:
		_hints = result
	else:
		push_error("HintManager: failed to parse tictactoe_hints.json")

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

# ---------------------------------------------------------------------------
# Game connection
# ---------------------------------------------------------------------------

# Call this from a game scene's _ready() to start tracking.
func connect_game(game: Node) -> void:
	if game.has_signal("move_made"):
		game.move_made.connect(_on_move_made)
	if game.has_signal("move_evaluated"):
		game.move_evaluated.connect(_on_move_evaluated)
	_inactivity_timer.start()
	_session_timer.start()

# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_move_made(_cell_index: int, player_type: int) -> void:
	# Reset inactivity timer whenever the player places a mark (player_type == 1).
	if player_type == 1:
		_inactivity_timer.start()

func _on_move_evaluated(cell_index: int, category: String) -> void:
	_last_move_category = category

	if category in ["correct", "game_complete"]:
		_reset()
		return

	# Both "wrong_move" and "warm" count as failed for tier tracking purposes.
	if category in ["wrong_move", "warm"]:
		_handle_failed_move(cell_index)

# ---------------------------------------------------------------------------
# Tier progression
# ---------------------------------------------------------------------------

func _handle_failed_move(cell_index: int) -> void:
	if _guidance_active:
		return

	# Track whether the player is repeating the exact same cell.
	if cell_index == _last_wrong_cell:
		_same_mistake_count += 1
	else:
		_same_mistake_count = 1
		_last_wrong_cell = cell_index

	_wrong_moves_this_tier += 1

	# Same cell played wrong twice always triggers tier 2 (once past tier 1).
	if _same_mistake_count >= 2 and _current_tier >= 1:
		_fire_tier_2("same_mistake_twice")
		return

	match _current_tier:
		0:
			if _wrong_moves_this_tier >= TIER_1_WRONG_MOVES:
				_fire_tier_1("wrong_moves")
		1:
			if _wrong_moves_this_tier >= TIER_2_WRONG_MOVES:
				# Use "warm" variant if the last evaluated move was close.
				var variant := "warm" if _last_move_category == "warm" else "cold"
				_fire_tier_2(variant)
		2:
			if _wrong_moves_this_tier >= TIER_3_FAILED_MOVES:
				_fire_tier_3()

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

# ---------------------------------------------------------------------------
# Tier 4: Guidance
# ---------------------------------------------------------------------------

# Call when the player accepts the guidance offer.
func accept_guidance() -> void:
	_guidance_active = true
	guidance_started.emit()

# Call when the player declines the guidance offer.
func decline_guidance() -> void:
	_emit_hint(["tier_3", "declined"], 3, "declined")

# Call if the player exits guidance mid-way.
# was_correct: true if their very next independent move was correct.
func exit_guidance(was_correct: bool) -> void:
	_guidance_active = false
	var variant := "exit_early_right" if was_correct else "exit_early_wrong"
	_emit_hint(["tier_4", variant], 4, variant)
	guidance_ended.emit("exit_right" if was_correct else "exit_wrong")

# Call when the guided walkthrough finishes successfully.
func complete_guidance() -> void:
	_guidance_active = false
	_emit_hint(["tier_4", "completed"], 4, "completed")
	guidance_ended.emit("completed")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _reset() -> void:
	_current_tier = 0
	_wrong_moves_this_tier = 0
	_last_wrong_cell = -1
	_same_mistake_count = 0
	_inactivity_timer.start()

func _emit_hint(path: Array, tier: int, variant: String) -> void:
	var text := _get_line(path)
	if text:
		hint_triggered.emit(text, tier, variant)

# Walk a nested Dictionary path and return a random item from the final Array.
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
