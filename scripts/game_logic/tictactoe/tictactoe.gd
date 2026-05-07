extends BaseGame

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const EMPTY  := 0  # cell not yet played
const PLAYER := 1  # played by the human
const CHILD  := 2  # played by the child character

const PLAYER_MARK := "X"
const CHILD_MARK  := "O"

const MOUTH_CELLS: Array[int] = [6, 7, 8]
const EYE_CELLS:   Array[int] = [0, 2]
const WRONG_MOVE_PAUSE := 2.5

const PLAYER_TEXTURE_PATH := "res://assets/art/x_mark.png"
const CHILD_TEXTURE_PATH  := "res://assets/art/o_mark.png"

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------

# 9-element array — one slot per cell, left-to-right / top-to-bottom:
#   0 | 1 | 2
#   ---------
#   3 | 4 | 5
#   ---------
#   6 | 7 | 8
# Each value is EMPTY, PLAYER, or CHILD.
var board: Array[int] = []

# Whose turn it is right now.
var current_turn: int = PLAYER

# Holds a direct reference to each Button node, addressed by cell index.
var _cells: Array[Button] = []

# Index of the most recently placed cell — available inside check_win_condition().
var _last_placed_cell: int = -1

var _child_turn_timer: Timer
var _reset_timer: Timer

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	super._ready()
	board.resize(9)
	board.fill(EMPTY)

	# Collect the nine Cell buttons from the GridContainer into _cells.
	# They are named Cell0 through Cell8 in the scene.
	var grid: GridContainer = $GameBoard
	for i in range(9):
		var cell := grid.get_node("Cell%d" % i) as Button
		assert(cell != null, "Missing Cell%d in GameBoard — check TicTacToe.tscn" % i)
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

# ---------------------------------------------------------------------------
# Player input — _on_cell_pressed is connected via signal binds in the scene
# ---------------------------------------------------------------------------

func _on_cell_pressed(cell_index: int) -> void:
	if not game_active or current_turn != PLAYER:
		return
	if board[cell_index] != EMPTY:
		return

	_place_mark(cell_index, PLAYER)

	if check_win_condition():
		game_active = false
		return

	if cell_index not in MOUTH_CELLS:
		game_active = false
		_reset_timer.start()
		return

	current_turn = CHILD
	_child_turn_timer.start()

# ---------------------------------------------------------------------------
# Child character AI
# ---------------------------------------------------------------------------

func _child_take_turn() -> void:
	if not game_active:
		return

	# Secret rule: always try to place O in the eye corners first.
	for cell in EYE_CELLS:
		if board[cell] == EMPTY:
			_place_mark(cell, CHILD)
			if check_win_condition():
				game_active = false
			else:
				current_turn = PLAYER
			return

	# Both eye cells taken — fall back to a random empty cell.
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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# Navigation
# ---------------------------------------------------------------------------

func _on_back_pressed() -> void:
	game_active = false
	_child_turn_timer.stop()
	_reset_timer.stop()
	HintManager.reset_session()
	var err := get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
	if err != OK:
		push_error("TicTacToe: failed to load MainMenu (%d)" % err)

# ---------------------------------------------------------------------------
# Win condition — implement this yourself
# ---------------------------------------------------------------------------

func check_win_condition() -> bool:
	# Win: bored smiley face.
	#   O eyes in upper corners (0, 2) + X mouth across bottom row (6, 7, 8).
	var face_complete: bool = (
		board[0] == CHILD  and
		board[2] == CHILD  and
		board[6] == PLAYER and
		board[7] == PLAYER and
		board[8] == PLAYER
	)

	if face_complete:
		move_evaluated.emit(_last_placed_cell, "game_complete")
		return true

	# Evaluate player moves only — the child's rule is hers to know.
	if _last_placed_cell >= 0 and board[_last_placed_cell] == PLAYER:
		if _last_placed_cell in MOUTH_CELLS:
			move_evaluated.emit(_last_placed_cell, "correct")
		else:
			move_evaluated.emit(_last_placed_cell, "wrong_move")

	return false
