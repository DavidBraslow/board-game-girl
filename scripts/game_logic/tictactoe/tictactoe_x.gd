extends TicTacToeBase

const DIAGONAL_CELLS: Array[int] = [0, 2, 4, 6, 8]
const EDGE_CELLS:     Array[int] = [1, 3, 5, 7]

func _get_level_id() -> String:
	return "tictactoe_x"

func _get_player_cells() -> Array[int]:
	return DIAGONAL_CELLS

func _get_child_cells() -> Array[int]:
	return EDGE_CELLS

func check_win_condition() -> bool:
	var x_complete: bool = (
		board[0] == PLAYER and
		board[2] == PLAYER and
		board[4] == PLAYER and
		board[6] == PLAYER and
		board[8] == PLAYER
	)

	if x_complete:
		move_evaluated.emit(_last_placed_cell, "game_complete")
		return true

	if _last_placed_cell >= 0 and board[_last_placed_cell] == PLAYER:
		if _last_placed_cell in DIAGONAL_CELLS:
			move_evaluated.emit(_last_placed_cell, "correct")
		else:
			move_evaluated.emit(_last_placed_cell, "wrong_move")

	return false
