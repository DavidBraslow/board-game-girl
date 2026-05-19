extends Control

const LEVELS := {
	"tictactoe_x": {
		"name": "Tic-Tac-Toe X",
		"scene": "res://scenes/games/tictactoe/TicTacToeX.tscn",
		"node": "TicTacToeX",
	},
	"tictactoe_meh": {
		"name": "Tic-Tac-Toe Face",
		"scene": "res://scenes/games/tictactoe/TicTacToe.tscn",
		"node": "TicTacToeMeh",
	},
}

var level_id := "hub"

func _ready() -> void:
	HintManager.reset_session()
	ReactionManager.connect_game(self)
	_refresh_tiles()
	get_tree().create_timer(0.5).timeout.connect(
		func(): ReactionManager.trigger("intro")
	)

func _refresh_tiles() -> void:
	for level_name: String in LEVELS:
		var info: Dictionary = LEVELS[level_name]
		var tile := $GamesContainer.get_node_or_null(info["node"]) as Button
		if not tile:
			push_warning("GameRoom: no tile node '%s' for level '%s'" % [info["node"], level_name])
			continue
		var unlocked := SaveSystem.is_level_unlocked(level_name)
		tile.disabled = not unlocked
		tile.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.3, 0.3, 0.3, 1)

func _on_tile_pressed(level_name: String) -> void:
	if not LEVELS.has(level_name):
		push_error("GameRoom: unknown level '%s'" % level_name)
		return
	var err := get_tree().change_scene_to_file(LEVELS[level_name]["scene"])
	if err != OK:
		push_error("GameRoom: failed to load scene for level '%s' (err %d)" % [level_name, err])
