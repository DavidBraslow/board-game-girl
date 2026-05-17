# Controller for the child character's on-screen presence.
# Connects to ReactionManager and HintManager to display dialogue
# and play animations in response to game events.
#
# Replace the placeholder animations with real art when assets are ready.
# Animation names the script looks for:
#   "idle"            — default state
#   "react_wrong"     — wrong move
#   "react_cool"      — close but not right
#   "react_correct"   — correct move
#   "react_celebrate" — game complete / puzzle solved
#   "react_hint"      — any hint fires

extends Control

signal guided_move_accepted
signal guided_move_declined

const GIRL_TEXTURE_PATH := "res://assets/art/girl.png"

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _dialogue_label: Label = $DialogueLabel
@onready var _guidance_panel: HBoxContainer = $GuidanceOfferPanel
@onready var _character_sprite: TextureRect = $CharacterSprite

var _in_guided_play: bool = false

func _ready() -> void:
	ReactionManager.reaction_triggered.connect(_on_reaction_triggered)
	HintManager.hint_triggered.connect(_on_hint_triggered)
	HintManager.guidance_offer_made.connect(_on_guidance_offer_made)
	HintManager.guided_move_offer_made.connect(_on_guidance_offer_made)
	HintManager.guidance_started.connect(func(): _in_guided_play = true)
	HintManager.guidance_ended.connect(func(_r: String): _in_guided_play = false)
	if ResourceLoader.exists(GIRL_TEXTURE_PATH):
		_character_sprite.texture = load(GIRL_TEXTURE_PATH)

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
# Guidance offer (initial tier-3 offer and per-move offers during guided play)
# ---------------------------------------------------------------------------

func _on_guidance_offer_made() -> void:
	_guidance_panel.visible = true

func _on_accept_pressed() -> void:
	_guidance_panel.visible = false
	if _in_guided_play:
		guided_move_accepted.emit()
	else:
		HintManager.accept_guidance()

func _on_decline_pressed() -> void:
	_guidance_panel.visible = false
	if _in_guided_play:
		guided_move_declined.emit()
	else:
		HintManager.decline_guidance()

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _show_dialogue(text: String) -> void:
	_dialogue_label.text = text

func _play_animation(category: String) -> void:
	var anim_map: Dictionary = {
		"wrong_move":    "react_wrong",
		"cool":          "react_cool",
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
