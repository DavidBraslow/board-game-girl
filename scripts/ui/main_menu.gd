extends Control

const LEVELS := {
	"tictactoe": {
		"scene": "res://scenes/games/tictactoe/TicTacToe.tscn",
		"button": "VBoxContainer/GamesContainer/TicTacToeButton",
	},
}

func _ready() -> void:
	_refresh_buttons()

func _refresh_buttons() -> void:
	for level_name: String in LEVELS:
		var info: Dictionary = LEVELS[level_name]
		var button := get_node(info["button"]) as Button
		if button:
			button.disabled = not SaveSystem.is_level_unlocked(level_name)

func _on_game_button_pressed(level_name: String) -> void:
	get_tree().change_scene_to_file(LEVELS[level_name]["scene"])
