# ReactionManager — autoload singleton.
# Loads tictactoe_reactions.json and emits a dialogue line whenever
# the game evaluates a move. The child character scene listens to
# reaction_triggered to display the line and play an animation.

extends Node

# Emitted with the selected line and its category.
# The UI (child_character.tscn) connects to this.
signal reaction_triggered(text: String, category: String)

var _lines: Dictionary = {}

func _ready() -> void:
	_load_dialogue()

func _load_dialogue() -> void:
	var file := FileAccess.open("res://data/dialogue/tictactoe_reactions.json", FileAccess.READ)
	if not file:
		push_error("ReactionManager: could not open tictactoe_reactions.json")
		return
	var result: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if result is Dictionary:
		_lines = result
	else:
		push_error("ReactionManager: failed to parse tictactoe_reactions.json")

# Call this from a game scene's _ready() to wire up the reaction system.
# ReactionManager will connect to the game's move_evaluated signal.
func connect_game(game: Node) -> void:
	if game.has_signal("move_evaluated"):
		game.move_evaluated.connect(_on_move_evaluated)

func _on_move_evaluated(_cell_index: int, category: String) -> void:
	trigger(category)

# Manually trigger a reaction by category name.
# Valid categories: "wrong_move", "warm", "correct", "game_complete"
func trigger(category: String) -> void:
	if not _lines.has(category):
		return
	var pool: Array = _lines[category]
	if pool.is_empty():
		return
	var text: String = pool[randi() % pool.size()]
	reaction_triggered.emit(text, category)
