class_name TicTacToeBase
extends BaseGame

const EMPTY  := 0
const PLAYER := 1
const CHILD  := 2

const PLAYER_MARK := "X"
const CHILD_MARK  := "O"
const PLAYER_TEXTURE_PATH := "res://assets/art/x_mark.png"
const CHILD_TEXTURE_PATH  := "res://assets/art/o_mark.png"
const WRONG_MOVE_PAUSE    := 2.5
const GUIDANCE_MOVE_PAUSE := 1.2

var board: Array[int] = []
var current_turn: int = PLAYER
var _cells: Array[Button] = []
var _last_placed_cell: int = -1
var _guidance_active: bool = false
var _pending_guided_cell: int = -1
var _child_turn_timer: Timer
var _reset_timer: Timer
var _guidance_timer: Timer

func _ready() -> void:
	level_id = _get_level_id()
	super._ready()
	board.resize(9)
	board.fill(EMPTY)

	var grid: GridContainer = $GameBoard
	for i in range(9):
		var cell := grid.get_node("Cell%d" % i) as Button
		assert(cell != null, "Missing Cell%d in GameBoard" % i)
		_cells.append(cell)

	_child_turn_timer = Timer.new()
	_child_turn_timer.wait_time = 0.8
	_child_turn_timer.one_shot = true
	_child_turn_timer.timeout.connect(_child_take_turn)
	add_child(_child_turn_timer)

	_reset_timer = Timer.new()
	_reset_timer.wait_time = WRONG_MOVE_PAUSE
	_reset_timer.one_shot = true
	_reset_timer.timeout.connect(_reset_board)
	add_child(_reset_timer)

	_guidance_timer = Timer.new()
	_guidance_timer.wait_time = GUIDANCE_MOVE_PAUSE
	_guidance_timer.one_shot = true
	_guidance_timer.timeout.connect(_make_guided_player_move)
	add_child(_guidance_timer)

	HintManager.guidance_started.connect(_on_guidance_started)
	HintManager.guidance_ended.connect(_on_guidance_ended)
	$ChildCharacter.guided_move_accepted.connect(_on_guided_move_accepted)
	$ChildCharacter.guided_move_declined.connect(_on_guided_move_declined)

	get_tree().create_timer(0.5).timeout.connect(
		func(): ReactionManager.trigger("intro")
	)

func _on_cell_pressed(cell_index: int) -> void:
	if not game_active or current_turn != PLAYER or _guidance_active:
		return
	if board[cell_index] != EMPTY:
		return

	_place_mark(cell_index, PLAYER)

	if check_win_condition():
		game_active = false
		_handle_win()
		return

	if cell_index not in _get_player_cells():
		game_active = false
		_reset_timer.start()
		return

	current_turn = CHILD
	_child_turn_timer.start()

func _child_take_turn() -> void:
	if not game_active:
		return

	for cell in _get_child_cells():
		if board[cell] == EMPTY:
			_place_mark(cell, CHILD)
			if check_win_condition():
				game_active = false
			else:
				current_turn = PLAYER
				if _guidance_active:
					_guidance_timer.start()
			return

	var empty_cells: Array[int] = []
	for i in range(9):
		if board[i] == EMPTY:
			empty_cells.append(i)

	if empty_cells.is_empty():
		game_active = false
		return

	var chosen: int = empty_cells[randi() % empty_cells.size()]
	_place_mark(chosen, CHILD)

	if check_win_condition():
		game_active = false
		return

	current_turn = PLAYER
	if _guidance_active:
		_guidance_timer.start()

func _make_guided_player_move() -> void:
	if not game_active or not _guidance_active:
		return

	var available: Array[int] = []
	for cell in _get_player_cells():
		if board[cell] == EMPTY:
			available.append(cell)

	if available.is_empty():
		return

	_pending_guided_cell = available[randi() % available.size()]
	HintManager.make_guided_move_offer()

func _place_first_guided_move() -> void:
	if not game_active or not _guidance_active:
		return
	var available: Array[int] = []
	for cell in _get_player_cells():
		if board[cell] == EMPTY:
			available.append(cell)
	if available.is_empty():
		return
	_place_guided_move(available[randi() % available.size()])

func _on_guided_move_accepted() -> void:
	if not game_active or not _guidance_active or _pending_guided_cell < 0:
		return
	var cell := _pending_guided_cell
	_pending_guided_cell = -1
	_place_guided_move(cell)

func _place_guided_move(cell: int) -> void:
	_place_mark(cell, PLAYER)
	if check_win_condition():
		game_active = false
		_handle_win()
		HintManager.complete_guidance()
		return
	current_turn = CHILD
	_child_turn_timer.start()

func _on_guided_move_declined() -> void:
	_pending_guided_cell = -1
	HintManager.exit_guidance(false)

func _on_guidance_started() -> void:
	_guidance_active = true
	if game_active and current_turn == PLAYER:
		get_tree().create_timer(GUIDANCE_MOVE_PAUSE).timeout.connect(_place_first_guided_move)

func _on_guidance_ended(_reason: String) -> void:
	_guidance_active = false
	_pending_guided_cell = -1
	_guidance_timer.stop()

func _reset_board() -> void:
	board.fill(EMPTY)
	_last_placed_cell = -1
	for cell in _cells:
		cell.text = ""
		cell.icon = null
		cell.disabled = false
	current_turn = PLAYER
	game_active = true

func _place_mark(cell_index: int, player_type: int) -> void:
	board[cell_index] = player_type
	_last_placed_cell = cell_index
	var texture_path := PLAYER_TEXTURE_PATH if player_type == PLAYER else CHILD_TEXTURE_PATH
	if ResourceLoader.exists(texture_path):
		_cells[cell_index].icon = load(texture_path)
		_cells[cell_index].text = ""
	else:
		_cells[cell_index].text = PLAYER_MARK if player_type == PLAYER else CHILD_MARK
	_cells[cell_index].disabled = true
	move_made.emit(cell_index, player_type)

func _on_back_pressed() -> void:
	game_active = false
	_child_turn_timer.stop()
	_reset_timer.stop()
	_guidance_timer.stop()
	HintManager.reset_session()
	var err := get_tree().change_scene_to_file("res://scenes/ui/GameRoom.tscn")
	if err != OK:
		push_error("TicTacToeBase: failed to load GameRoom (%d)" % err)

func _handle_win() -> void:
	if level_id.is_empty():
		push_error("TicTacToeBase: level_id is empty — did you override _get_level_id()?")
		return
	SaveSystem.mark_level_complete(level_id)
	if level_id == "tictactoe_x":
		SaveSystem.mark_level_unlocked("tictactoe_meh")

# --- Shared helpers ---

func _get_correct_category() -> String:
	var player_cells := _get_player_cells()
	var correct_count := player_cells.filter(func(c): return board[c] == PLAYER).size()
	if correct_count >= player_cells.size() - 1:
		return "near_win"
	return "correct"

# --- Virtual methods — override in each level ---

func _get_level_id() -> String:
	return ""

func _get_player_cells() -> Array[int]:
	return []

func _get_child_cells() -> Array[int]:
	return []

func check_win_condition() -> bool:
	return false
