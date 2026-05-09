class_name BaseGame
extends Control

signal move_made(cell_index: int, player_type: int)
signal move_evaluated(cell_index: int, category: String)

var game_active: bool = true
var level_id: String = ""

func _ready() -> void:
	ReactionManager.connect_game(self)
	HintManager.connect_game(self)

# Stub — override in each game scene to detect win/loss/draw.
# Return true to end the game, false to keep playing.
func check_win_condition() -> bool:
	return false
