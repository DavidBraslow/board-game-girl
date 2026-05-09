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

var board: Array[int] = []
var current_turn: int = PLAYER
var _cells: Array[Button] = []
var _last_placed_cell: int = -1
var _child_turn_timer: Timer
var _reset_timer: Timer

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

	get_tree().create_timer(0.5).timeout.connect(
		func(): ReactionManager.trigger("intro")
	)

func _on_cell_pressed(cell_index: int) -> void:
	if not game_active or current_turn != PLAYER:
		return
	if board[cell_index] != EMPTY:
		return

	_place_mark(cell_index, PLAYER)

	if check_win_condition():
		game_active = false
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
	HintManager.reset_session()
	var err := get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	if err != OK:
		push_error("TicTacToeBase: failed to load MainMenu (%d)" % err)

# --- Virtual methods — override in each level ---

func _get_level_id() -> String:
	return ""

func _get_player_cells() -> Array[int]:
	return []

func _get_child_cells() -> Array[int]:
	return []

func check_win_condition() -> bool:
	return false
