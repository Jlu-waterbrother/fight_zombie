extends Node

func _ready() -> void:
	GameState.load_persistent_state()
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn")
