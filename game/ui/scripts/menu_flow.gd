extends Node
class_name MenuFlow

func go_to_run(scene_tree: SceneTree) -> void:
    scene_tree.change_scene_to_file("res://scenes/run_game.tscn")
