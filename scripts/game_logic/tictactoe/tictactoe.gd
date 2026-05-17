extends TicTacToeBase

const MOUTH_CELLS: Array[int] = [6, 7, 8]
const EYE_CELLS:   Array[int] = [0, 2]

func _get_level_id() -> String:
	return "tictactoe_meh"

func _get_player_cells() -> Array[int]:
	return MOUTH_CELLS

func _get_child_cells() -> Array[int]:
	return EYE_CELLS

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

	if _last_placed_cell >= 0 and board[_last_placed_cell] == PLAYER:
		if _last_placed_cell in MOUTH_CELLS:
			move_evaluated.emit(_last_placed_cell, _get_correct_category())
		else:
			move_evaluated.emit(_last_placed_cell, "wrong_move")

	return false
