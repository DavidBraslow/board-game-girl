extends Control

func _on_play_pressed() -> void:
	var err := get_tree().change_scene_to_file("res://scenes/ui/GameRoom.tscn")
	if err != OK:
		push_error("MainMenu: failed to load GameRoom.tscn (err %d)" % err)
