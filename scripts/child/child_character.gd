# Controller for the child character's on-screen presence.
# Connects to ReactionManager and HintManager to display dialogue
# and play animations in response to game events.
#
# Replace the placeholder animations with real art when assets are ready.
# Animation names the script looks for:
#   "idle"            — default state
#   "react_wrong"     — wrong move
#   "react_warm"      — close but not right
#   "react_correct"   — correct move
#   "react_celebrate" — game complete / puzzle solved
#   "react_hint"      — any hint fires

extends Control

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _dialogue_label: Label = $DialogueLabel

func _ready() -> void:
	ReactionManager.reaction_triggered.connect(_on_reaction_triggered)
	HintManager.hint_triggered.connect(_on_hint_triggered)
	HintManager.guidance_offer_made.connect(_on_guidance_offer_made)

# ---------------------------------------------------------------------------
# Reaction handler
# ---------------------------------------------------------------------------

func _on_reaction_triggered(text: String, category: String) -> void:
	_show_dialogue(text)
	_play_animation(category)

# ---------------------------------------------------------------------------
# Hint handler
# ---------------------------------------------------------------------------

func _on_hint_triggered(text: String, _tier: int, _variant: String) -> void:
	_show_dialogue(text)
	_play_animation("hint")

# ---------------------------------------------------------------------------
# Guidance offer
# ---------------------------------------------------------------------------

func _on_guidance_offer_made() -> void:
	# TODO: show an accept/decline UI prompt here.
	# Call HintManager.accept_guidance() or HintManager.decline_guidance()
	# based on the player's choice.
	pass

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _show_dialogue(text: String) -> void:
	_dialogue_label.text = text

func _play_animation(category: String) -> void:
	var anim_map: Dictionary = {
		"wrong_move":    "react_wrong",
		"warm":          "react_warm",
		"correct":       "react_correct",
		"game_complete": "react_celebrate",
		"hint":          "react_hint",
	}
	var anim_name: String = anim_map.get(category, "idle")

	if _animation_player.has_animation(anim_name):
		_animation_player.play(anim_name)
	elif _animation_player.has_animation("idle"):
		_animation_player.play("idle")
	# If no animations are defined yet, do nothing — placeholders welcome.
