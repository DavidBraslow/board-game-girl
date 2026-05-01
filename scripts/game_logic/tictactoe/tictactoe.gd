# Controller for the Tic-Tac-Toe game level.
# Attach this script to the root node of TicTacToe.tscn.
#
# TODO: When BaseGame is created, change "extends Control" to "extends BaseGame".

extends Control

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const EMPTY  := 0  # cell not yet played
const PLAYER := 1  # played by the human
const CHILD  := 2  # played by the child character

const PLAYER_MARK := "X"
const CHILD_MARK  := "O"

# ---------------------------------------------------------------------------
# Signals — names use past tense per project convention
# ---------------------------------------------------------------------------

# Emitted every time any mark is placed — player or child.
# Connect HintManager to this signal to observe all moves.
signal move_made(cell_index: int, player_type: int)

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

# Becomes false once the game ends; blocks further input.
var game_active: bool = true

# Holds a direct reference to each Button node, addressed by cell index.
var _cells: Array[Button] = []

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	board.resize(9)
	board.fill(EMPTY)

	# Collect the nine Cell buttons from the GridContainer into _cells.
	# They are named Cell0 through Cell8 in the scene.
	var grid: GridContainer = $GameBoard
	for i in range(9):
		var cell := grid.get_node("Cell%d" % i) as Button
		assert(cell != null, "Missing Cell%d in GameBoard — check TicTacToe.tscn" % i)
		_cells.append(cell)

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

	current_turn = CHILD
	# call_deferred waits until the next frame so the player's mark renders
	# before the child responds.
	call_deferred("_child_take_turn")

# ---------------------------------------------------------------------------
# Child character AI
# ---------------------------------------------------------------------------

func _child_take_turn() -> void:
	# Guard against the deferred call arriving after the game has already ended.
	if not game_active:
		return

	var empty_cells: Array[int] = []
	for i in range(9):
		if board[i] == EMPTY:
			empty_cells.append(i)

	if empty_cells.is_empty():
		game_active = false
		return

	# Placeholder: random empty cell.
	# Replace this with the child's secret rule logic once you've defined it.
	var chosen: int = empty_cells[randi() % empty_cells.size()]
	_place_mark(chosen, CHILD)

	if check_win_condition():
		game_active = false
		return

	current_turn = PLAYER

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _place_mark(cell_index: int, player_type: int) -> void:
	board[cell_index] = player_type
	_cells[cell_index].text = PLAYER_MARK if player_type == PLAYER else CHILD_MARK
	_cells[cell_index].disabled = true  # prevents the cell from being clicked again
	move_made.emit(cell_index, player_type)

# ---------------------------------------------------------------------------
# Win condition — implement this yourself
# ---------------------------------------------------------------------------

func check_win_condition() -> bool:
	# TODO: implement win/loss/draw detection here.
	#
	# board[i] is EMPTY (0), PLAYER (1), or CHILD (2).
	# Cell layout:
	#   0 | 1 | 2
	#   ---------
	#   3 | 4 | 5
	#   ---------
	#   6 | 7 | 8
	#
	# Return true to end the game, false to keep playing.
	return false
